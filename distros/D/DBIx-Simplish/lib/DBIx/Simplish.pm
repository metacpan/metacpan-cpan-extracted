package DBIx::Simplish;

# ABSTRACT: L<DBIx::Simple> + L<DBIx::Connector> + extras.

use Moo;
use MooX::LazyRequire;
use Types::Standard qw/Str HashRef InstanceOf Int Bool/;
use Type::Tiny::Enum;
use DBIx::Connector;
use SQL::Abstract::Limit;
use SQL::Interp qw/sql_interp/;
use Tie::Cache::LRU;
use Carp qw/croak/;
use DBIx::Simplish::Result;
use Regexp::Common;

our $VERSION = '1.002001'; # VERSION

my $connection_mode = Type::Tiny::Enum->new(values => [qw/ping fixup no_ping/]);

has dsn => (
    is            => 'ro',
    isa           => Str,
    lazy_required => 1,
);

has [qw/user password/] => (
    is  => 'ro',
    isa => Str,
);

has options => (
    is      => 'ro',
    isa     => HashRef,
    default => sub {{}},
);

has connector => (
    is        => 'lazy',
    isa       => InstanceOf['DBIx::Connector'],
    predicate => 1,
    handles   => {
        dbh        => 'dbh',
        disconnect => 'disconnect',
        _run       => 'run',
    },
);

has keep_statements => (
    is      => 'ro',
    isa     => Int,
    default => 16,
);

has lc_columns => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has abstract => (
    is      => 'lazy',
    isa     => InstanceOf['SQL::Abstract'],
    handles => [qw/select insert update delete/],
);

has connection_mode => (
    is => 'ro',
    isa => $connection_mode,
    default => sub {'fixup'},
);

has _cache => (
    is       => 'lazy',
    init_arg => undef,
);

has _is_sqlite => (
    is       => 'lazy',
    init_arg => undef,
);

has _is_mysql => (
    is       => 'lazy',
    init_arg => undef,
);

has sql_quote_char => (
    is        => 'ro',
    predicate => 1,
);

has sql_name_sep => (
    is        => 'ro',
    predicate => 1,
);

sub _build_connector {
    my $self = shift;
    my $options = $self->options;
    $options->{PrintError} = 0 unless exists $options->{PrintError};
    $options->{RaiseError} = 1 unless exists $options->{RaiseError};
    if ($self->_is_mysql) {
        $options->{mysql_enable_utf8}    = 1 unless exists $options->{mysql_enable_utf8};
        $options->{mysql_enable_utf8mb4} = 1 unless exists $options->{mysql_enable_utf8mb4};
    } elsif ($self->_is_sqlite) {
        $options->{sqlite_use_immediate_transaction} = 1 unless exists $options->{sqlite_use_immediate_transaction};
        $options->{sqlite_unicode}                   = 1 unless exists $options->{sqlite_unicode};
    }
    my $connector = DBIx::Connector->new(
        $self->dsn,
        $self->user,
        $self->password,
        $options,
    );
    $connector->mode($self->connection_mode);
    return $connector;
}

sub _build_abstract {
    my $self = shift;
    my %args = (limit_dialect => $self->dbh);
    $args{quote_char} = $self->sql_quote_char if $self->has_sql_quote_char;
    $args{name_sep}   = $self->sql_name_sep   if $self->has_sql_name_sep;
    if ($self->_is_mysql) {
        $args{quote_char} = '`' unless $self->has_sql_quote_char;
        $args{name_sep}   = '.' unless $self->has_sql_name_sep;
    } elsif ($self->_is_sqlite) {
        $args{quote_char} = '"' unless $self->has_sql_quote_char;
        $args{name_sep}   = '.' unless $self->has_sql_name_sep;
    }
    return SQL::Abstract::Limit->new(%args);
}

sub _build__cache {
    my $self = shift;
    my $cache;
    tie %{$cache}, 'Tie::Cache::LRU', $self->keep_statements; ## no critic (ProhibitTies)
    return $cache
}

sub _build__is_mysql {
    my $self = shift;
    if ($self->has_connector) {
        return $self->dbh->{Driver}{Name} eq 'mysql';
    } else {
        return $self->dsn =~ /^(?i:dbi):mysql:/;
    }
}

sub _build__is_sqlite {
    my $self = shift;
    if ($self->has_connector) {
        return $self->dbh->{Driver}{Name} eq 'SQLite';
    } else {
        return $self->dsn =~ /^(?i:dbi):SQLite:/;
    }
}

sub DEMOLISH {
    my $self = shift;
    $_->finish for values %{$self->_cache};
}

sub connect { ## no critic (ProhibitBuiltinHomonyms)
    my ($self, $dsn, $user, $password, $options) = @_;
    my %opts = (dsn => $dsn);
    $opts{user}     = $user     if defined $user;
    $opts{password} = $password if defined $password;
    $opts{options}  = $options  if defined $options;
    return $self->new(%opts);
}

my $omniholder_re = qr/[(][?][?][)]/;

sub _omniholder {
    my ($self, $query, @binds) = @_;
    my ($ordinary_binds, $omniholder_binds) = (0, 0);
    (my $dummy = $query) =~ s/($RE{quoted}|$omniholder_re|[?])/
        if ($1 eq '(??)') {
            $omniholder_binds++;
        } elsif ($1 eq '?') {
            $ordinary_binds++;
        }
    /ge;
    return $query if $omniholder_binds == 0;
    croak('There can be only one omniholder') if $omniholder_binds > 1;
    croak('Not enough binds') if (@binds - $ordinary_binds) < 1;
    my $replacement = '(' . join(',', ('?') x (@binds - $ordinary_binds)) . ')';
    $query =~ s/($RE{quoted}|$omniholder_re)/
        if ($1 eq '(??)') {
            $replacement;
        } else {
            $1;
        }
    /ge;
    return $query;
}

sub query {
    my ($self, $query, @binds) = @_;
    $query = $self->_omniholder($query, @binds) if $query =~ /$omniholder_re/;
    my $s = $self->_run(sub {
        my $dbh = shift;
        $dbh->{CachedKids} = $self->_cache;
        my $sth = $dbh->prepare_cached($query, undef, 3); ## no critic (ProhibitMagicNumbers)
        $sth->execute(@binds);
        return $sth;
    });
    return DBIx::Simplish::Result->new(sth => $s, lc_columns => $self->lc_columns);
}

before disconnect => sub {
    goto &DEMOLISH;
};

around [qw/select insert update delete iquery/] => sub {
    my ($method, $self, @args) = @_;
    my ($query, @binds) = $self->$method(@args);
    return $self->query($query, @binds);
};

sub iquery {
    my ($self, @args) = @_;
    sql_interp(@args);
}

sub call {
    my ($self, $procedure, @args) = @_;
    return $self->query("CALL $procedure(??)", @args);
}

sub func {
    my ($self, @args) = @_;
    return $self->_run(sub {$_->func(@args)});
}

sub last_insert_id {
    my ($self, @args) = @_;
    if ($self->_is_mysql) {
        return $self->_run(sub {$_->{mysql_insertid}});
    } elsif ($self->_is_sqlite) {
        return $self->func('last_insert_rowid');
    } else {
        return $self->_run(sub {$_->last_insert_id(@args)});
    }
}

sub begin_work {
    my $self = shift;
    return $self->_run(sub {$_->begin_work});
}

sub begin {
    goto &begin_work;
}

sub commit {
    my $self = shift;
    return $self->_run(sub {$_->commit});
}

sub rollback {
    my $self = shift;
    return $self->_run(sub {$_->rollback});
}

sub error {
    my $self = shift;
    return $self->_run(sub {$_->errstr});
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Simplish - L<DBIx::Simple> + L<DBIx::Connector> + extras.

=head1 VERSION

version 1.002001

=head1 SYNOPSIS

=head2 DBIx::Simplish

    $db = DBIx::Simplish->new(dsn => ..., user => ..., password => ..., ...)
    $db = DBIx::Simplish->connect(...)

    $db->keep_statements = 16
    $db->lc_columns = 1

    $db->begin_work         $db->commit
    $db->rollback           $db->disconnect
    $db->func(...)          $db->last_insert_id

    $result = $db->query(...)

    $result = $db->iquery('INSERT INTO table', \%item)
    $result = $db->iquery('UPDATE table SET',  \%item, 'WHERE y <> ', \2)
    $result = $db->iquery('DELETE FROM table WHERE y = ', \2)
    $result = $db->iquery('SELECT * FROM table WHERE x = ', \$s, 'AND y IN', \@v)
    $result = $db->iquery('SELECT * FROM table WHERE', {x => $s, y => \@v})

    $result = $db->select($table, \@fields, \%where, \@order)
    $result = $db->insert($table, \%fieldvals || \@values)
    $result = $db->update($table, \%fieldvals, \%where)
    $result = $db->delete($table, \%where)

    # Only for MySQL
    $result = $db->call($procedure, @args)

=head2 DBIx::Simplish::Result

    @columns = $result->columns

    $result->into($foo, $bar, $baz)
    $row = $result->fetch

    @row = $result->list      @rows = $result->flat
    $row = $result->array     @rows = $result->arrays
    $row = $result->hash      @rows = $result->hashes
    @row = $result->kv_list   @rows = $result->kv_flat
    $row = $result->kv_array  @rows = $result->kv_arrays

    %map = $result->map_arrays(...)
    %map = $result->map_hashes(...)
    %map = $result->map

    $rows = $result->rows

    $dump = $result->text

    $result->finish

=head1 DESCRIPTION

DBIx::Simplish has (mostly) the same interface as L<DBIx::Simple>. It's a rewrite to add little bits I wanted, and
remove some bits I never used. Maybe you'll find it useful too.

DBIx::Simplish is backed by L<DBIx::Connector>, L<SQL::Abstract> and L<SQL::Interp>.

=head2 Differences from DBIx::Simple

=over

=item * Automatically enables UTF-8 when using MySQL or SQLite.

=item * Automatically sets proper quotes and limit dialect on L<SQL::Abstract::Limit>
        methods when using MySQL or SQLite

=item * Uses L<SQL::Abstract::Limit> instead of L<SQL::Abstract>.

=item * Can call C<last_insert_id> without parameter when using MySQL or SQLite.

=item * The omniholder C<(??)> is a bit smarter.

=item * Can't set result class. It's always L<DBIx::Simplish::Result>.

=item * No fancy error handling returning dummy objects.

=item * L<SQL::Abstract::Limit> and L<SQL::Interp> are now dependencies. Not recommendations.

=item * C<xto>, C<html> and C<text> methods removed.

=item * C<object> and C<objects> methods of result class no longer has a default implementation.
        You must always provide a class name.

=back

=head1 ATTRIBUTES

=head2 dsn

Sets the connection DSN. See L<DBI>.

=head2 user

Sets the connection user naem.

=head2 password

Sets the connecton password.

=head2 options

Set the DBI options. See L<DBI|DBI/connect>.

=head2 connector

Sets the L<DBIx::Connector> instance to use for connections.
If not set, a new instance will be created.
If set dsn, user, password and options attributes will be ignored.

=head2 keep_statements

Sets the number of statements to keep in cache.
See also L<keep_statements in DBIx::Simple|DBIx::Simple/keep_statements-integer>.

=head2 lc_columns

Set to true to use lower case column names.
See also L<lc_columns in DBIx::Simple|DBIx::Simple/lc_columns-bool>

=head2 abstract

Sets the L<SQL::Abstract> instance to use for SQL generation.
If not set, a new instance will be created.

=head2 connection_mode

Sets the L<DBIx::Connecter> connection mode.
Valid values are 'ping', 'fixup' and 'no_ping'.
Default value 'fixup'.

=head2 sql_quote_char

Set the SQL quote char to use.
See also L<quote_char in SQL::Abstract|SQL::Abstract/quote_char>
Default value is ` for MySQL and " for SQLite.

=head2 sql_name_sep

Sets the SQL name seperator char to use
See also L<name_sep in SQL::Abstract|SQL::Abstract/name_sep>.
Default value is . for MySQL and SQLite.

=head1 METHODS

=head2 connect($dsn, $user, $pass, \%options)

Constructor. Same arguments as for DBI connect.
See L<DBI> for details.
Same as

    DBIx::Simplish->new(dsn => $dsn, user => $user, password => $pass, options => \%options);

=head2 query($query, @binds)

Prepares and executes the query and returns a result object.

If the string (??) is present in the query, it is replaced with a list of as many question marks as
@binds minus number of ordinary ? binds.

The database drivers substitute placeholders (question marks that do not appear in quoted literals)
in the query with the given @binds, after them escaping them. You should always use placeholders,
and never use raw user input in database queries.

On success, returns a L<DBIx::Simplish::Result> object.

=head2 select, insert, update, query

Calls the corresponding L<SQL::Abstract::Limit> method.
The resulting query and binds is then passed to the C<query> method.

See also: L<SQL::Abstract> and L<SQL::Abstract::Limit>.

=head2 iquery

Calls L<SQL::Interp's C<sql_interp> method|SQL::Interp/sql_interp>. Sends the resulting query and
binds to the C<query> method.

See also: L<SQL::Interp>.

=head2 call

Shortcut for calling a MySQL procedure.
C<< $db->call($procedure_name, @args) >> is equivalent to
C<< $db->query("CALL $procedure_name(??)", @args) >>.

=head2 func

Proxy for L<C<func> method of DBI|DBI/func>

=head2 last_insert_id

Calls the L<C<last_insert_id> method of DBI|DBI/last_insert_id>

Can be called without parameters for MySQL and SQLite (no more C<last_insert_id(undef, undef, undef, undef)>).

=head2 begin_work

Proxy for L<C<begin_work> method of DBI|DBI/begin_work>.

=head2 begin

Alias for C<begin_work>.

=head2 commit

Proxy for L<C<commit> method of DBI|DBI/commit>.

=head2 rollback

Proxy for L<C<rollback> method of DBI|DBI/rollback>.

=head2 error

Proxy for L<C<errstr> method of DBI|DBI/errstr>.

=head1 TODO

Add more - and better - documentation.

=head1 SEE ALSO

L<DBIx::Simple>, L<DBIx::Connector>, L<SQL::Abstract> and L<SQL::Interp>.

=head1 AUTHOR

Hans Staugaard <staugaard@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Hans Staugaard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

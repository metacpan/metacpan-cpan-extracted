package Acrux::DBI;
use strict;
use utf8;

=encoding utf8

=head1 NAME

Acrux::DBI - Database independent interface for Acrux applications

=head1 SYNOPSIS

    use Acrux::DBI;

=head1 DESCRIPTION

Database independent interface for Acrux applications

=head2 new

    my $dbi = Acrux::DBI->new( $db_url );
    my $dbi = Acrux::DBI->new( $db_url, { ... options ... });
    my $dbi = Acrux::DBI->new( $db_url, ... options ...);

Build new Acrux::DBI object

Options:

=over 8

=item autoclean

This options turns on auto disconnecting on DESTROY phase

=back

See also list of default options in L</options>

=head1 METHODS

This class implements the following methods

=head2 begin

    $dbi->begin;
    # ...
    $dbi->commit; # ..or $dbi->rollback

This is a transaction method!

This method marks the starting point for the start of a transaction

    eval {
      $dbi->begin;
      $db->query('insert into test values (?)', 'Foo');
      $db->query('insert into test values (?)', 'Bar');
      $dbi->commit;
    };
    die $@ if $@;

See slso L</commit>, L</rollback>

=head2 cache

    my $cache = $dbi->cache;

Returns the L<Mojo::Cache> object

=head2 cachekey

    my $cachekey = $dbi->cachekey;

Returns the key name of the cached connect (See L</connect_cached>)

=head2 cleanup

    $dbi = $dbi->cleanup;

This internal method to cleanup database handler

=head2 commit

    $dbi->begin;
    # ...
    $dbi->commit;

This is a transaction method!

This method accepts all changes to the database and marks the end
point for the transaction to complete

See also L</begin>, L</rollback>

=head2 connect

    my $dbi = $dbi->connect;
    die $dbi->error if $dbi->error;

This method makes a connection to the database

=head2 connect_cached

    my $dbi = $dbi->connect_cached;
    die $dbi->error if $dbi->error;

This method makes a cached connection to the database. See L<DBI/connect_cached> for details

=head2 database

    my $database = $dbi->database;

This method returns the database that will be used for generating the connection DSN
This will be used as L<Mojo::URL/path>

Default: none

=head2 dbh

    my $dbh = $dbi->dbh;

Returns database handle used for all queries

=head2 disconnect

    my $dbi = $dbi->disconnect;

This method disconnects from the database

=head2 driver

    my $driver = $dbi->driver;

This is the L<Mojo::URL/scheme> that will be used for generating the connection DSN

Default: C<sponge>

=head2 dsn

    my $dsn = $dbi->dsn;

This method generates the connection DSN and returns it or
returns already generated earley.

=head2 err

    my $err = $dbi->err;

This method just returns C<$DBI::err> value

=head2 errstr

    my $errstr = $dbi->errstr;

This method just returns C<$DBI::errstr> value

=head2 error

    my $error = $dbi->error;

Returns error string if occurred any errors while working with database

    $dbi = $dbi->error( "error text" );

Sets new error message and returns object

=head2 host

    my $host = $dbi->host;

This is the L<Mojo::URL/host> that will be used for generating the connection DSN

Default: C<localhost>

=head2 options

    my $options = $dbi->options;

This method returns options that will be used for generating the connection DSN

Default: all passed options to constructor merged with system defaults:

    RaiseError  => 0,
    PrintError  => 0,
    PrintWarn   => 0,

=head2 password

    my $password = $dbi->password;

This is the L<Mojo::URL/password> that will be used for generating the connection DSN

default: none

=head2 ping

    $dbi->ping ? 'OK' : 'Database session is expired';

Checks the connection to database

=head2 port

    my $port = $dbi->port;

This is the L<Mojo::URL/port> that will be used for generating the connection DSN

Default: none

=head2 query

    my $res = $dbi->query('select * from test');
    my $res = $dbi->query('insert into test values (?, ?)', @values);

Execute a blocking statement and return a L<Acrux::DBI::Res> object with the results.
You can also append a 'bind_callback' to perform binding value manually:

    my $res = $dbi->query('insert into test values (?, ?)', {
        bind_callback => sub {
            my $sth = shift;
            $sth->bind_param( ... );
          }
      });

=head2 reconnect

    $dbi = $dbi->reconnect;

This method performs reconnecting to database and returns this object

=head2 rollback

    $dbi->begin;
    # ...
    $dbi->rollback;

This is a transaction method!

This method discards all changes to the database and marks the end
point for the transaction to complete

See also L</begin>, L</commit>

=head2 url

    $dbi = $dbi->url('sqlite:///tmp/test.db?sqlite_unicode=1');
    $dbi = $dbi->url('postgres://foo:pass@localhost/mydb?PrintError=1');
    my $url = $dbi->url;

Database connect ur

The database connection URL from which all other attributes can be derived.
C<"url"> must be specified before the first call to C<"connect"> is made,
otherwise it will have no effect on setting the defaults.

Default: C<"sponge://">

=head2 transaction

    my $tx = $dbi->transaction;

Begin transaction and return L<Acrux::DBI::Tx> object, which will automatically
roll back the transaction unless L<Acrux::DBI::Tx/commit> has been called before
it is destroyed

    # Insert rows in a transaction
    eval {
      my $tx = $dbi->transaction;
      $dbi->query( ... );
      $dbi->query( ... );
      $tx->commit;
    };
    say $@ if $@;

=head2 username

    my $username = $dbi->username;

This is the L<Mojo::URL/username> that will be used for generating the connection DSN

default: none

=head2 userinfo

    my $userinfo = $dbi->userinfo;

This is the L<Mojo::URL/userinfo> that will be used for generating the connection DSN

default: none

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojo::mysql>, L<Mojo::Pg>, L<Mojo::DB::Connector>, L<CTK::DBI>, L<DBI>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2024 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

our $VERSION = '0.01';

use Carp qw/carp croak/;
use Scalar::Util 'weaken';
use DBI qw//;
use Mojo::Util qw/monkey_patch md5_sum/;
use Mojo::URL qw//;
use Mojo::Cache;
use Acrux::Util qw//;
use Acrux::RefUtil qw/is_array_ref is_code_ref/;
use Acrux::DBI::Res;
use Acrux::DBI::Tx;

use constant {
    DEBUG            => $ENV{ACRUX_DBI_DEBUG} || 0,
    DEFAULT_DBI_URL  => 'sponge://',
    DEFAULT_DBI_DSN  => 'DBI:Sponge:',
    DEFAULT_DBI_OPTS => {
            RaiseError  => 0,
            PrintError  => 0,
            PrintWarn   => 0,
        },
};

# Set method ping to DBD::Sponge
monkey_patch 'DBD::Sponge::db', ping => sub { 1 };

sub new {
    my $class = shift;
    my $url = shift || DEFAULT_DBI_URL;
       croak 'Invalid DBI URL' unless $url;
    my $opts = scalar(@_) ? scalar(@_) > 1 ? {@_} : {%{$_[0]}} : {};
    my $uri = Mojo::URL->new($url);

    # Default attributes
    my %_opts = (%{(DEFAULT_DBI_OPTS)}, %$opts);
    my $autoclean = delete $_opts{autoclean};

    my $self  = bless {
            url     => $url,
            uri     => $uri,
            dsn     => '',
            cachekey=> '',
            driver  => '',
            dbh     => undef,
            error   => "", # Ok
            autoclean => $autoclean ? 1 : 0,
            opts    => {%_opts},
            cache   => Mojo::Cache->new,
        }, $class;
    return $self;
}

# Attributes
sub url {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{url} = shift;
        $self->{uri}->parse($self->{url});
        $self->{dsn} = '';
        $self->{cachekey} = '';
        $self->{driver} = '';
        return $self;
    }
    return $self->{url};
}
sub driver { # scheme
    my $self = shift;
    $self->{driver} ||= $self->{uri}->protocol;
}
sub host {
    my $self = shift;
    return $self->{uri}->host || 'localhost';
}
sub port {
    my $self = shift;
    return $self->{uri}->port // '';
}
sub options {
    my $self = shift;
    my $opts = $self->{opts}; # defaults
    my $query = $self->{uri}->query;
    my %params = ();
       $params{$_} = $query->param($_) for @{$query->names};
    return { (%$opts, %params) } ; # merge defaults and URL params
}
sub username {
    my $self = shift;
    return $self->{uri}->username // '';
}
sub password {
    my $self = shift;
    return $self->{uri}->password // '';
}
sub userinfo {
    my $self = shift;
    return $self->{uri}->userinfo // '';
}
sub database {
    my $self = shift;
    my $u = $self->{uri};
    my $dr = $self->driver;
    my $db = '';
    if ($dr eq 'sqlite' or $dr eq 'file') {
        $db = $u->path->leading_slash(1)->trailing_slash(0)->to_string // '';
    } else {
        $db = $u->path->leading_slash(0)->trailing_slash(0)->to_string // '';
    }
    return $db;
}
sub dsn {
    my $self = shift;
    return $self->{dsn} if $self->{dsn};
    my $dr = $self->driver;

    # Set DSN
    my @params = ();
    my $dsn = '';
    my $db = $self->database;
    if ($dr eq 'sqlite' or $dr eq 'file') {
        $dsn = sprintf('DBI:SQLite:dbname=%s', $db);
    } elsif ($dr eq 'mysql') {
        push @params, sprintf("%s=%s", "database", $db) if length $db;
        push @params, sprintf("%s=%s", "host", $self->host);
        push @params, sprintf("%s=%s", "port", $self->port) if $self->port;
        $dsn = sprintf('DBI:mysql:%s', join(";", @params) || '');
    } elsif ($dr eq 'maria' or $dr eq 'mariadb') {
        push @params, sprintf("%s=%s", "database", $db) if length $db;
        push @params, sprintf("%s=%s", "host", $self->host);
        push @params, sprintf("%s=%s", "port", $self->port) if $self->port;
        $dsn = sprintf('DBI:MariaDB:%s', join(";", @params) || '');
    } elsif ($dr eq 'pg' or $dr eq 'pgsql' or $dr eq 'postgres' or $dr eq 'postgresql') {
        push @params, sprintf("%s=%s", "dbname", $db) if length $db;
        push @params, sprintf("%s=%s", "host", $self->host);
        push @params, sprintf("%s=%s", "port", $self->port) if $self->port;
        $dsn = sprintf('DBI:Pg:%s', join(";", @params) || '');
    } elsif ($dr eq 'oracle') {
        push @params, sprintf("%s=%s", "host", $self->host);
        push @params, sprintf("%s=%s", "sid", $db) if length $db;
        push @params, sprintf("%s=%s", "port", $self->port) if $self->port;
        $dsn = sprintf('DBI:Oracle:%s', join(";", @params) || '');
    } else {
        $dsn = DEFAULT_DBI_DSN;
    }

    $self->{dsn} = $dsn;
}
sub cache { shift->{cache} }
sub cachekey {
    my $self = shift;
    return $self->{cachekey} if $self->{cachekey};

    # Generate cachekey data
    my $opts = $self->{opts}; # defaults
    my @pairs = ();
    foreach my $k (sort { $a cmp $b } keys %$opts) {
        push @pairs, "$k=" . ($opts->{$k} // '');
    }
    my $sfx = join ";", @pairs;
    $self->{cachekey} = md5_sum($self->{url} . $sfx);
}
sub dbh { shift->{dbh} }

# Methods
sub error {
    my $self = shift;
    if (scalar(@_) >= 1) {
        $self->{error} = shift;
        return $self;
    }
    return $self->{error};
}
sub err {
    my $self = shift;
    return $self->dbh->err // $DBI::err if $self->dbh->can('err');
    return $DBI::err
}
sub errstr {
    my $self = shift;
    return $self->dbh->errstr // $DBI::errstr if $self->dbh->can('errstr');
    return $DBI::errstr;
}

# Database methods
sub connect {
    my $self = shift;
    $self->{error} = '';
    my $dbh = DBI->connect($self->dsn, $self->username, $self->password, $self->options);
    if ($dbh) {
        $self->{dbh} = $dbh;
        printf STDERR "Connected to '%s'\n", $self->dsn if DEBUG;
    } else {
        $self->{error} = $DBI::errstr || "DBI->connect failed";
        $self->{dbh} = undef;
    }
    return $self;
}
sub connect_cached {
    my $self = shift;
    $self->{error} = '';
    my %opts = %{($self->options)};
       $opts{private_cachekey} = $self->cachekey;
    my $dbh = DBI->connect_cached($self->dsn, $self->username, $self->password, {%opts});
    if ($dbh) {
        $self->{dbh} = $dbh;
        printf STDERR "Connected (cached) to '%s'\n", $self->dsn if DEBUG;
    } else {
        $self->{error} = $DBI::errstr || "DBI->connect failed";
        $self->{dbh} = undef;
    }
    return $self;
}
sub disconnect {
    my $self = shift;
    return unless my $dbh = $self->dbh;
    $dbh->disconnect;
    printf STDERR "Disconnected from '%s'\n", $self->dsn if DEBUG;
    $self->cleanup;
}
sub ping {
    my $self = shift;
    return 0 unless $self->{dsn};
    return 0 unless my $dbh = $self->dbh;
    return 0 unless $dbh->can('ping');
    return $dbh->ping();
}

# Transaction methods
sub transaction {
    my $tx = Acrux::DBI::Tx->new(dbi => shift);
    weaken $tx->{dbi};
    return $tx;
}
sub begin {
    my $self = shift;
    return unless my $dbh = $self->dbh;
    $dbh->begin_work;
    return $self;
}
sub commit {
    my $self = shift;
    return unless my $dbh = $self->dbh;
    $dbh->commit;
    return $self;
}
sub rollback {
    my $self = shift;
    return unless my $dbh = $self->dbh;
    $dbh->rollback;
    return $self;
}

# Request methods
sub query { # SQL, { args }
    my $self = shift;
    my $sql = shift // '';
    my $args = @_
      ? @_ > 1
        ? {bind_values => [@_]}
        : ref($_[0]) eq 'HASH'
          ? {%{$_[0]}}
          : {bind_values => [@_]}
      : {};
    $self->{error} = '';
    return unless my $dbh = $self->dbh;
    unless (length($sql)) {
        $self->error("No statement specified");
        return;
    }

    # Prepare
    my $sth = $dbh->prepare($sql);
    unless ($sth) {
        $self->error(sprintf("Can't prepare statement \"%s\": %s", $sql,
            $dbh->errstr || $DBI::errstr || 'unknown error'));
        return;
    }

    # HandleError
    local $sth->{HandleError} = sub { $_[0] = Carp::shortmess($_[0]); 0 };

    # Binding params and execute
    my $bind_values = $args->{bind_values} || [];
    unless (is_array_ref($bind_values)) {
        $self->error("Invalid list of binding values. Array ref expected");
        return;
    }
    my $rv;
    my $argb = '';
    if (scalar @$bind_values) {
        $argb = sprintf(" with bind values: %s",
            join(", ", map {defined($_) ? sprintf("'%s\'", $_) : 'undef'} @$bind_values));

        $rv  = $sth->execute(@$bind_values);
    } elsif (my $cb = $args->{bind_callback} || $args->{bind_cb}) {
        unless (is_code_ref($cb)) {
            $self->error("Invalid binding callback function. Code ref expected");
            return;
        }
        $cb->($sth); # Callback! bind params
        $rv = $sth->execute;
    } else {
        $rv = $sth->execute; # Without bindings
    }
    unless (defined $rv) {
        $self->error(sprintf("Can't execute statement \"%s\"%s: %s", $sql, $argb,
            $sth->errstr || $dbh->errstr || $DBI::errstr || 'unknown error'));
        return;
    }

    # Result
    return Acrux::DBI::Res->new(
        dbi => $self,
        sth => $sth,
        affected_rows => $rv >= 0 ? 0 + $rv : -1,
    );
}

sub cleanup {
    my $self = shift;
    undef $self->{dbh};
    return $self;
}
sub DESTROY {
    my $self = shift;
    printf STDERR "DESTROY on phase %s\n", ${^GLOBAL_PHASE} if DEBUG;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    return unless $self->{autoclean};
    $self->disconnect;
    printf STDERR "Auto cleanup on DESTROY completed\n" if DEBUG;
}


1;

__END__


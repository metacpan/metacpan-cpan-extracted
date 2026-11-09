use v5.36;

package DBIx::Squirrel;

use Carp                    qw(croak);
use DBI                     qw();
use DBI::Const::GetInfoType qw(%GetInfoType);
use Ref::Util               qw(is_hashref);

use DBIx::Squirrel::Stop qw();
use DBIx::Squirrel::Util qw(canonical split_attrs);
use DBIx::Squirrel::db   qw();
use DBIx::Squirrel::st   qw();

use namespace::clean;

our @ISA     = 'DBI';
our $VERSION = 'v2.0.5';

# Export what the DBI exports, such as :sql_types, to the package using
# DBIx::Squirrel. The names are the DBI's, so the DBI's import exports
# them: goto leaves no frame of this sub's, so it exports them to the
# package that used DBIx::Squirrel, and reports a mistake at its line.
# It's a sub without a signature, as goto passes @_.
sub import {    ## no critic (Subroutines::RequireArgUnpacking)
    return if @_ < 2;
    @_ = ('DBI', @_[1 .. $#_]);
    goto &{ DBI->can('import') };
}

# Return the handle of the connection to the requested data source.
sub connect ($class, $source, @args) {
    return _connect_dbh($class, $source, @args)
        if $source isa 'DBI::db';
    my $username = is_hashref($args[0]) ? undef       : shift @args;
    my $password = is_hashref($args[0]) ? undef       : shift @args;
    my $attrs    = is_hashref($args[0]) ? shift @args : {};
    my($dbi_attrs, $options) = _split_attrs($class, $attrs);

    # The options go to the DBI as a string, so connect_cached, which keys
    # its cache on every attribute's value, finds a handle made with the
    # same ones. A handle it finds has them already.
    $dbi_attrs->{private_ekorn_options} = canonical($options) if %$options;
    my $dbh = $class->SUPER::connect($source, $username, $password, $dbi_attrs);
    croak _connect_failed($class, $source, $attrs->{Username} // $username)
        unless $dbh;
    $dbh->{private_ekorn} //= {Options => $options};
    return _discern_dialect($dbh);
}

# Return the handle of a new connection using the same parameters as
# another connection.
sub _connect_dbh ($class, $dbh, @args) {
    my $attrs = @args && is_hashref($args[0]) ? shift @args : {};
    my $clone = $dbh->clone(_connect_attrs($class, $attrs, $dbh->{private_ekorn}))
        or croak _connect_failed($class, $dbh->{Name}, $dbh->{Username});
    return _discern_dialect($clone);
}

# Return the message the DBI raises under RaiseError when it can't
# connect, without the dbi:Driver: prefix of the data source, as the
# DBI's message has none.
sub _connect_failed ($class, $source, $username) {
    my $dsn = $source =~ s( \A dbi: \w*? (?: \( .*? \) )? : )()xir;
    return "$class connect('$dsn','@{[ $username // '' ]}',...) failed: "
        . ($DBI::errstr // '(no error string)');
}

# Return the attributes to connect with, for the DBI, and DBIx::Squirrel's
# own, those starting "ekorn_", the defaults for the statements the handle
# prepares, over any a cloned handle already had.
sub _split_attrs ($class, $attrs, $state = undef) {
    my($dbi_attrs, $ekorn) = split_attrs($attrs);
    $dbi_attrs->{RootClass} = ref($class) || $class;
    my %options = (%{ $state && $state->{Options} // {} }, %$ekorn);
    return $dbi_attrs, \%options;
}

# Return the attributes to clone a handle with, DBIx::Squirrel's own kept
# in the private_ekorn attribute.
sub _connect_attrs ($class, $attrs, $state = undef) {
    my($dbi_attrs, $options) = _split_attrs($class, $attrs, $state);
    $dbi_attrs->{private_ekorn} = {Options => $options} if %$options;
    return $dbi_attrs;
}

# Give a handle the dialect its statements are read by, unless it was
# given one, and return it.
sub _discern_dialect ($dbh) {
    my $state   = $dbh->{private_ekorn} // {};
    my $options = $state->{Options}     // {};
    return $dbh
        if defined $options->{ekorn_dialect};
    $dbh->{private_ekorn} = {
        %$state,
        Options => {%$options, ekorn_dialect => _dialect($dbh)},
    };
    return $dbh;
}

# Return the dialect a handle's statements are read by: its driver's name,
# or, for a driver that passes the connection on to another, such as
# DBD::ODBC or DBD::Proxy, the name of the driver for the database behind
# it, if the database says what it is and it's one with rules of its own.
sub _dialect ($dbh) {
    state %PASSES_ON = map { ($_ => 1) } qw(ADO Gofer JDBC ODBC Proxy);
    state @DIALECTS  = (
        [qr( mariadb )xi  => 'MariaDB'],
        [qr( mysql )xi    => 'mysql'],
        [qr( postgres )xi => 'Pg'],
        [qr( sqlite )xi   => 'SQLite'],
    );
    my $driver = $dbh->{Driver}{Name};
    return $driver
        unless $PASSES_ON{$driver};
    local $dbh->{RaiseError} = 0;
    local $dbh->{PrintError} = 0;
    my $dbms = $dbh->get_info($GetInfoType{SQL_DBMS_NAME}) // '';
    for my $dialect (@DIALECTS) {
        return $dialect->[1] if $dbms =~ $dialect->[0];
    }
    return $driver;
}

1;

__END__

=encoding utf8

=for stopwords MariaDB PostgreSQL

=head1 NAME

DBIx::Squirrel - DBI, minus the boilerplate, plus a pipeline

=head1 SYNOPSIS

    use DBIx::Squirrel;

    my $dbh = DBIx::Squirrel->connect($data_source, $username, $password, \%attr);

    # Placeholders in the style you like: ?, ?1, :1, $1 or :name
    my $sth = $dbh->prepare('SELECT * FROM artist WHERE id = :id OR name = :name');

    # Named placeholders bound by name, as pairs or in a hash reference
    $sth->execute(id => 1, name => 'AC/DC');

    # A numbered placeholder takes one value, wherever it appears
    my $row = $dbh->selectrow_hashref(
        'SELECT * FROM artist WHERE id = $1 OR parent_id = $1', undef, 2,
    );

    # A placeholder with "..." takes a list: a "?" for each of its values
    my $rows = $dbh->selectall_arrayref(
        'SELECT * FROM artist WHERE id IN (...:ids)', ids => [1, 2, 3],
    );

    # Iterate over the results, each run through a pipeline of stages
    my $names = $dbh->iterate(
        'SELECT name FROM artist WHERE name LIKE ?', 'A%',
        sub ($row) { $row->[0] },
    );
    while (my($name) = $names->next) {
        say $name;
    }

    # Or have each row as an object, with a method for each column
    my $artist = $dbh->results('SELECT * FROM artist WHERE id = :id', id => 1)->single;
    say $artist->name;

    # A new connection with the same parameters as an existing one
    my $other = DBIx::Squirrel->connect($dbh, \%attr);

    # Run the database handle through a pipeline of stages
    my @results = $dbh->pipe(
        sub ($dbh)   { ... },
        sub ($value) { ... },
    );

    # The same, as a branch off to the side: get the handle back
    $dbh = $dbh->tap(
        sub ($dbh)   { ... },
        sub ($value) { ... },
    );

=head1 DESCRIPTION

DBIx::Squirrel keeps you writing SQL, as the L<DBI> does, and takes away
the friction around it: placeholders in whatever style you like,
iterators over results, and a pipeline of transformations declared
beside the query.

It subclasses the DBI, so everything the DBI does still works, and
where the two do the same thing they give the same result. This page
notes where they differ.

This is version 2, a rewrite of DBIx::Squirrel 1.x for Perl 5.36 or
later, and code written for 1.x needs changes to run: the reference's
"Upgrading from 1.x" lists them. To stay on 1.x, install its last
version, C<cpanm DBIx::Squirrel@1.6.5>.

The database handle's own methods are in L<DBIx::Squirrel::db>, and the
statement handle's in L<DBIx::Squirrel::st>. L<DBIx::Squirrel::Iterator>
and L<DBIx::Squirrel::Results> describe what C<iterate> and C<results>
return. L<DBIx::Squirrel::Sugar> gives each database a function of its
own name.

=head2 Importing

C<use DBIx::Squirrel> takes the names the DBI exports, as C<use DBI>
does, and the DBI exports them:

    use DBIx::Squirrel qw(:sql_types neat);

=head1 METHODS

=head2 connect

    $dbh = DBIx::Squirrel->connect($data_source, $username, $password);
    $dbh = DBIx::Squirrel->connect($data_source, $username, $password, \%attr);
    $dbh = DBIx::Squirrel->connect($dbh, \%attr);

Connects to a data source, as the DBI's C<connect> does, and returns a
database handle, a L<DBIx::Squirrel::db>. Its statement handles are
L<DBIx::Squirrel::st>s. Both are subclasses of the DBI's own, so they
do everything the DBI's handles do.

Unlike the DBI's C<connect>, it B<always croaks> if the connection
fails, whatever C<RaiseError> is set to, with the message the DBI
raises under C<RaiseError>, such as
C<DBIx::Squirrel connect('dbname=music.db','',...) failed: ...>,
reported at the line that called C<connect>. The DBI returns C<undef>
unless C<RaiseError> is set.

Called on a subclass of DBIx::Squirrel, it uses that subclass's database
and statement handle classes in place of DBIx::Squirrel's. The subclass
needs both, as the DBI requires, each a subclass of DBIx::Squirrel's:

    package My::Squirrel     { our @ISA = 'DBIx::Squirrel' }
    package My::Squirrel::db { our @ISA = 'DBIx::Squirrel::db' }
    package My::Squirrel::st { our @ISA = 'DBIx::Squirrel::st' }

Without them, the DBI warns that the subclass isn't set up, and returns
its own handles.

Attributes starting C<ekorn_> are DBIx::Squirrel's own. They aren't
passed on to the DBI, but kept in the database handle's C<private_ekorn>
attribute, as the defaults for each statement it prepares. Attributes
passed to L<DBIx::Squirrel::db/prepare> override them, for that
statement. There are four:

=over

=item C<ekorn_dialect>

The driver whose rules statements are read by, described below.

=item C<ekorn_finish_active>

Finish a statement still active before executing it again, as
L<DBIx::Squirrel::st/execute> describes.

=item C<ekorn_slice>

The shape an iterator fetches rows in, as
L<DBIx::Squirrel::Iterator> describes.

=item C<ekorn_result_class>

The base class of the rows a result set hands out, as
L<DBIx::Squirrel::Result> describes.

=back

C<ekorn_dialect> names the driver whose rules statements are read by,
and C<connect> works it out when it isn't given: it's the driver's own
name, such as C<mysql> or C<Pg>. A driver that passes the connection on
to another database (DBD::ADO, DBD::Gofer, DBD::JDBC, DBD::ODBC or
DBD::Proxy) is asked, through the DBI's
C<get_info>, what the database is, and MariaDB, MySQL, PostgreSQL and
SQLite are recognised. Any other database, or one that doesn't say, is
read by the standard rules. Name the dialect when C<connect> can't tell:

    # MySQL, through a driver that doesn't say what's behind it
    $dbh = DBIx::Squirrel->connect($data_source, $username, $password, {
        ekorn_dialect => 'mysql',
    });

=head3 Connecting with an existing handle

Given a database handle in place of a data source, C<connect> makes a
new connection with the same parameters, using the DBI's C<clone>. Any
attributes passed are applied to the new connection. The handle can
come from the DBI itself, or from code that made its own connection.
The new handle keeps the first one's C<ekorn_> defaults, with any passed
in their place.

The new handle is a separate connection, not a second name for the
first: it doesn't share the first one's transaction, temporary tables
or session settings. An in-memory SQLite database, for example, gives
a new, empty database.

=head3 connect_cached

C<connect_cached> is the DBI's own, unchanged. The DBI's C<connect_cached>
calls C<connect> when it needs a new connection, so it croaks on failure
too.

=head1 HANDLE METHODS

Database and statement handles both have these methods, inherited from
L<DBIx::Squirrel::Pipes>. The examples use a database handle; on a
statement handle, the statement handle goes through the stages instead.

=head2 pipe

    @results = $dbh->pipe(@stages);
    $result  = $dbh->pipe(@stages);

Runs the database handle through a pipeline of stages, and returns what
comes out of the last one.

Each stage is a code reference, called with one value, as its argument
and in C<$_>, so it can name the value with a signature, or leave the
signature out and use C<$_>:

    sub ($row) { $row->[1] }    # the value, named
    sub { $_->[1] }             # the same, in $_

C<$_> is localised for each call, so the caller's is left as it was.
The first stage is called with the database handle. A stage
returns nothing to drop the value, one value to pass it on, or several,
each of which goes through the rest of the stages on its own:

    my @odd_doubled = $dbh->pipe(
        sub ($dbh) { (3, 4, 5) },
        sub { $_ % 2 ? $_ : () },
        sub { $_ * 2 },
    );    # (6, 10)

To end the pipeline early, call L</Stop>. With no stages, C<pipe>
returns the database handle.

Called in list context, C<pipe> returns all the values. In scalar
context, it returns the first, or C<undef> if there are none. To count
the values instead, assign them to an empty list, and take that in
scalar context:

    my $count = () = $dbh->pipe(@stages);

If a stage dies, C<pipe> croaks at the line that called it, naming the
stage by its position, from C<#1>:

    Pipeline stage #2 failed at script.pl line 12:
        ...

L<DBIx::Squirrel::Pipeline> says more about stages.

=head2 tap

    $dbh = $dbh->tap(@stages);

Runs the database handle through a pipeline of stages, as a branch off
to the side for their side effects, and returns the handle, so that a
chain of method calls can carry on after it.

    $dbh ───┬───▶ $dbh
            │
            └───▶ stage #1 ───▶ stage #2 ───▶ ...

The stages work as they do in L</pipe>; what comes out of the last one
is dropped. For example, to log how many rows a table has, then carry
on with the handle:

    $dbh->tap(
        sub ($dbh)   { $dbh->selectrow_array('SELECT COUNT(*) FROM artist') },
        sub ($count) { log_count($count) },
    )->do('DELETE FROM artist WHERE id = ?', undef, $id);

A stage passes on whatever its last statement gives, even one run for
its side effects, so each stage except the last should return what the
next one needs.

C<tap> returns the handle however the stages end: having run out of
values, been stopped with L</Stop>, or with no stages at all. If a
stage dies, C<tap> croaks at the line that called it, as L</pipe> does.

=head1 FUNCTIONS

=head2 Stop

    use DBIx::Squirrel::Stop;
    Stop();
    Stop(@values);

    DBIx::Squirrel::Stop->throw(@values);

Called from a stage of a pipeline, ends the pipeline quietly. The rest
of that stage doesn't run. The values already out of the pipeline are
kept, C<@values> go on through the stages after it, and nothing else is
processed. C<Stop> is exported automatically by
L<DBIx::Squirrel::Stop>; C<< DBIx::Squirrel::Stop->throw >> does the same
without importing it.

Stop works by throwing an exception, which the pipeline catches. So a
stage that catches errors itself, with C<eval> or C<try>, should throw a
stop on again. Check for Ekorn::Pipeline::Stop, which every stop is,
including those the canned stages throw, such as C<take>'s:

    sub ($row) {
        try { ... }
        catch ($e) {
            die $e if $e isa 'Ekorn::Pipeline::Stop';
            ...
        }
    }

Called outside a stage, it dies with "Stop used outside a pipeline".
L<DBIx::Squirrel::Stop> says more, including what a stop carries.

=head2 gather

    use DBIx::Squirrel::Gather;

    my $joined = gather {
        my @names;    # fresh on each run
        return (
            sub ($name) { push @names, $name; () },
            sub ()      { join ', ', @names },    # once the values run out
        );
    };

Returns a stage that a pipeline makes afresh for each run, by calling
the block. The block returns the stage, and optionally a function
called once the values run out, whose values go through the rest of
the stages. A stage that gathers values, to give them in batches or as
one, or that keeps state of any kind, is made this way. C<gather> is
exported automatically by L<DBIx::Squirrel::Gather>, which says more,
including what happens after a stop.

=head1 CANNED STAGES

Four modules of ready-made stages ship with DBIx::Squirrel, each
exporting the stages it's usually used for:

=over

=item * L<DBIx::Squirrel::Stages::Flow>: C<take> and C<drop>, with
C<take_while> and C<drop_while> on request;

=item * L<DBIx::Squirrel::Stages::Rows>: C<pluck> and C<as_hash>, for
rows of any shape;

=item * L<DBIx::Squirrel::Stages::Batch>: C<batch> and C<collect>;

=item * L<DBIx::Squirrel::Stages::Taps>: C<peek> and C<count_into>,
with C<dump_to> on request.

=back

    use DBIx::Squirrel::Stages::Flow;
    use DBIx::Squirrel::Stages::Rows;

    my @names = $dbh->iterate('SELECT name FROM artist', pluck('name'), take(10))->all;

The reference's "Writing stages" says how to write stages of your own
that work alongside them.

=head1 DIAGNOSTICS

Errors are reported at the line of your code that called DBIx::Squirrel,
never at a line inside it or the DBI. That includes the DBI's own errors
under C<RaiseError>, such as
C<DBD::SQLite::db prepare failed: near "SELEC": syntax error>, which keep
the DBI's message. An error DBIx::Squirrel raises in the DBI's place,
where it croaks and the DBI would return C<undef>, has the message the
DBI raises under C<RaiseError>, so an error reads the same whatever
C<RaiseError> is set to. Each names the method you called, as plain DBI
does: C<do> and the select methods, not the C<prepare> or C<execute>
they call. An error from a C<HandleError> callback, or one that isn't a
string, is passed on as it was raised. The DBI's warnings, under
C<PrintError>, are reported the same way, as plain DBI reports them:
at your line, naming the method you called.

=over

=item Pipeline stage #%d failed at %s line %d:

A stage passed to L</pipe> or L</tap>, or its end function, died. The
message it died with follows, indented.

=item Expected stage #%d to be a code reference

Something passed to L</pipe> or L</tap> wasn't a code reference. No
stage runs.

=item Expected stage #%d, made with gather, to return one or two code references

The block given to L</gather> for that stage returned something other
than a stage, or a stage and an end function.

=item Stop used outside a pipeline

L</Stop> was called where no pipeline was running to catch it.

=back

=head1 SEE ALSO

L<DBI>, L<DBIx::Squirrel::db>, L<DBIx::Squirrel::st>,
L<DBIx::Squirrel::Iterator>, L<DBIx::Squirrel::Results>,
L<DBIx::Squirrel::Result>, L<DBIx::Squirrel::Context>,
L<DBIx::Squirrel::Sugar>,
L<DBIx::Squirrel::Pipes>, L<DBIx::Squirrel::Pipeline>,
L<DBIx::Squirrel::Stop>, L<DBIx::Squirrel::Gather>,
L<DBIx::Squirrel::Stages::Flow>, L<DBIx::Squirrel::Stages::Rows>,
L<DBIx::Squirrel::Stages::Batch>, L<DBIx::Squirrel::Stages::Taps>

L<DBIx::Squirrel::Manual::Reference> describes every feature in detail,
with examples, and L<DBIx::Squirrel::Manual::HowTo> shows how to do
common tasks with them.

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut

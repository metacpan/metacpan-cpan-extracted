use v5.36;

package DBIx::Squirrel::Sugar;

use Ref::Util qw(is_arrayref is_hashref is_plain_hashref is_ref);

use Ekorn::Pipeline        qw(is_stage);
use Ekorn::Pipeline::Sugar qw();

use DBIx::Squirrel         qw();
use DBIx::Squirrel::Errors qw(at_caller   croakf);
use DBIx::Squirrel::Util   qw(install_sub is_name shift_attrs split_stages);

use namespace::clean;

our $VERSION = 'v4.1.1';

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# Each database defined, by name: the arguments to connect with, and the
# handle, once it's connected.
my %connect_args;
my %handle;

# Give the calling package database or statement, and define the
# databases or statements named in a hash reference after each, with
# their arguments in an array reference. The pipelines after each
# pipeline go to Ekorn::Pipeline::Sugar first, wherever they're given,
# so a statement can name one (roadmap 2026-0027).
sub import ($class, @args) {
    state %define = (database => \&_define, statement => \&_define_statement);
    state %what = (database => 'arguments to connect to', statement => 'statement');
    my $package = caller;
    my(@pipelines, @rest);
    while (@args) {
        my $arg = shift @args;
        if (defined $arg && $arg eq 'pipeline') {
            push @pipelines, $arg, shift @args;
            next;
        }
        push @rest, $arg;
    }
    at_caller { Ekorn::Pipeline::Sugar->import_into($package, @pipelines) }
    if @pipelines;
    @args = @rest;
    while (@args) {
        my $arg = shift @args;
        croakf 'Expected database, pipeline or statement, not %s', $arg
            unless $define{$arg};
        _install($package, $arg => $class->can($arg));
        next unless @args && is_hashref($args[0]);
        my $definitions = shift @args;
        for my $name (sort keys %$definitions) {
            croakf 'Expected the %s %s in an ARRAY', $what{$arg}, $name
                unless is_arrayref($definitions->{$name});
            $define{$arg}->($package, $name, @{ $definitions->{$name} });
        }
    }
    return;
}

# Return the handle of the database named, or, given the arguments to
# connect with, define it, give the calling package a function of its
# name, and return that.
#
# The handle is kept, and given again without asking the database, which
# would cost a round trip each time, unless it's been disconnected, or its
# last call failed, when it's pinged, and replaced if it doesn't answer.
# Neither DBD::mysql nor DBD::Pg turns Active off when the server drops
# the connection, but each leaves the failure in err.
sub database ($name, @connect) {
    return _define(scalar caller, $name, @connect) if @connect;
    croakf 'Expected a database named %s', $name
        unless $connect_args{$name};
    my $dbh = $handle{$name};
    return $dbh
        if $dbh && $dbh->{Active} && (!$dbh->err || _answers($dbh));
    my($source, @rest) = @{ $connect_args{$name} };
    my $method = $source isa 'DBI::db' ? 'connect' : 'connect_cached';
    return $handle{$name} = DBIx::Squirrel->$method($source, @rest);
}

# Return true if a database answers a ping. A ping that dies, as the DBI
# allows, is no answer.
sub _answers ($dbh) {
    my $answered = eval { $dbh->ping };
    return $answered;
}

# Define a statement on a database, with the attributes to prepare it
# with and stages, if given, give the calling package a function of its
# name, and return that.
sub statement ($name, $database, $statement, @rest) {
    return _define_statement(scalar caller, $name, $database, $statement, @rest);
}

# Define a database, and give a package a function of its name, returning
# the function.
sub _define ($package, $name, @connect) {
    croakf 'Expected a name for a database (%s)', $name
        unless is_name($name);
    croakf 'Expected a database defined once (%s)', $name
        if $connect_args{$name};
    my $function = sub (@args) { _run($name, @args) };
    _install($package, $name, $function);
    $connect_args{$name} = \@connect;
    return $function;
}

# Define a statement, and give a package a function of its name, returning
# the function.
sub _define_statement ($package, $name, @definition) {
    my($database, $statement, @rest) = @definition;
    croakf 'Expected a name for a statement (%s)', $name
        unless is_name($name);
    croakf 'Expected a database and a statement for %s', $name
        unless defined $database && defined $statement;
    # Only a plain hash is the attributes: a pipeline, or any other
    # object, straight after the statement is a stage, or a mistake.
    my $attrs
        = @rest && (!defined $rest[0] || is_plain_hashref($rest[0]))
        ? shift @rest
        : undef;
    croakf
        "Expected only stages after the statement for %s: code references, pipelines or their names, or objects offering a stage's role method",
        $name
        if grep { !is_stage($_) && !_is_pipeline_name($_) } @rest;
    @rest = map { _resolved($package, $_) } @rest;
    my %definition = (
        database  => $database,
        statement => $statement,
        attrs     => $attrs,
        stages    => \@rest,
    );
    my $function = sub (@args) { _run_statement(\%definition, @args) };
    _install($package, $name, $function);
    return $function;
}

# Return true if a stage given in a definition is a pipeline's name:
# words joined by ::, as Ekorn::Pipeline names them.
sub _is_pipeline_name ($stage) {
    return
           defined $stage
        && !is_ref($stage)
        && $stage =~ m( \A [^\W\d]\w* (?: :: [^\W\d]\w* )* \z )xa;
}

# Return a stage given in a definition: a pipeline's name resolved now, in
# the package making the definition, as Ekorn::Pipeline's pipeline word
# resolves one in its caller's, each on its own, so the other stages keep
# their places; anything else as it is.
sub _resolved ($package, $stage) {
    return $stage unless _is_pipeline_name($stage);
    return at_caller { Ekorn::Pipeline->pipeline_in($package, $stage) };
}

# Run a statement's function: execute the statement with the bind values
# given, and return its handle, or, with stages, its own or those given
# after the bind values, return an iterator over the results, or, if the
# last stage is a sink, its result. The statement is prepared once for
# each handle, with prepare_cached, which makes a new one, cached in its
# place, when the one prepared is in use; one taking a list is prepared
# for the values given, and not cached.
sub _run_statement ($definition, @args) {
    my $dbh       = database($definition->{database});
    my @statement = @$definition{qw(statement attrs)};
    my @stages    = (@{ $definition->{stages} }, split_stages(\@args));

    my $sth = DBIx::Squirrel::db::_prepare_as(    ## no critic (Subroutines::ProtectPrivateSubs)
        $dbh, prepare_cached => @statement, 3, @args,
    );
    return _execute($sth, @args, @stages);
}

# Run what a database's function is given: nothing, for the handle; a
# statement and its bind values, for the statement handle, executed; or
# those and stages after them, for an iterator, or a sink's result.
sub _run ($name, @args) {
    my $dbh = database($name);
    return $dbh unless @args;
    my $statement = shift @args;
    return _execute($statement, @args)      if $statement isa 'DBI::st';
    return $dbh->iterate($statement, @args) if _ends_in_stages(\@args);
    my $attrs = shift_attrs(\@args);

    my $sth = DBIx::Squirrel::db::_prepare_as(    ## no critic (Subroutines::ProtectPrivateSubs)
        $dbh, prepare => $statement, $attrs, undef, @args,
    );
    return _execute($sth, @args);
}

# Execute a statement handle with the bind values given, and return it,
# or nothing if it couldn't be executed; or, with stages after the bind
# values, return an iterator over the results, or, if the last stage is a
# sink, its result.
sub _execute ($sth, @args) {
    return $sth->iterate(@args) if _ends_in_stages(\@args);
    defined $sth->execute(@args) or return;
    return $sth;
}

# Return true if a list of arguments ends in a stage.
sub _ends_in_stages ($args) {
    return @$args && is_stage($args->[-1]);
}

# Give a package a named function, croaking if it has one of that name,
# unless it's the same.
sub _install ($package, $name, $code) {
    my $have = $package->can($name);
    return if $have && $have == $code;
    croakf 'Expected no function of the name in %s already (%s)', $package, $name
        if $have;
    install_sub("${package}::$name", $code);
    return;
}

1;
__END__

=encoding utf8

=head1 NAME

DBIx::Squirrel::Sugar - a function for each database, and each statement

=head1 SYNOPSIS

    use DBIx::Squirrel::Sugar database => {
        music => [$ENV{MUSIC_DSN}, $ENV{MUSIC_USER}, $ENV{MUSIC_PASS}],
    };

    my $dbh = music;                                   # the handle

    my $sth = music 'SELECT * FROM artist WHERE id = ?', 1;   # executed
    say $sth->fetchrow_hashref->{name};

    use DBIx::Squirrel::Tooling qw(pluck keep_all);

    my $it = music 'SELECT name FROM artist',          # an iterator
        pluck;
    my @names = music 'SELECT name FROM artist',       # a sink's result
        pluck, keep_all;

    # Anywhere in the program
    my $handle = database('music');

    # Statements, with stages of their own
    use DBIx::Squirrel::Sugar statement => {
        artist_names => [music => 'SELECT name FROM artist', pluck],
        artist       => [music => 'SELECT * FROM artist WHERE id = :id'],
    };

    my $names = artist_names;                                       # an iterator
    my @all   = artist_names keep_all;                              # the results
    my @upper = artist_names sub ($name) { uc $name }, keep_all;    # more stages
    my $found = artist id => 1;                           # executed

    # Pipelines, which a statement can name
    use DBIx::Squirrel::Sugar
        statement => {loud_names => [music => 'SELECT name FROM artist', 'loud']},
        pipeline  => {loud => [pluck, sub { uc }]};

    # Or defined as the program runs
    use DBIx::Squirrel::Sugar qw(database statement);
    database(archive => 'dbi:SQLite:dbname=archive.db', '', '', \%attr);
    statement(albums => archive => 'SELECT * FROM album');

=head1 DESCRIPTION

DBIx::Squirrel::Sugar gives each database a name. The package that
names it gets a function of that name, which returns the database
handle, or runs a statement on it. A statement gets a function too,
which runs it, with the bind values and any stages given.

A database is connected to when it's first used, not when it's
defined, with L<DBIx::Squirrel/connect_cached>. So two databases
defined with the same arguments share a handle, as C<connect_cached>
shares it.

The handle is kept, and each use has the same one, without a ping to
the database each time. It's pinged only while its last call has
failed, which leaves the error to be read. It's made again if the
connection has gone, or if the handle has been disconnected. So the
call after a connection drops fails, as it would with plain DBI, and
the call after that has a new connection.

=head1 IMPORTING

    use DBIx::Squirrel::Sugar qw(database statement);
    use DBIx::Squirrel::Sugar database => {$name => [@connect_args], ...};
    use DBIx::Squirrel::Sugar statement => {
        $name => [$database, $statement, \%attr, @stages], ...
    };
    use DBIx::Squirrel::Sugar pipeline => {$name => [@stages], ...};

Gives the package L</database>, or L</statement>, or both. Given a
hash reference after either, it also defines each database or
statement named in it, with the arguments it takes, in an array
reference. It gives the package each function while the package is
compiled, so the function can be called without parentheses.

After C<pipeline>, it takes what L<Ekorn::Pipeline::Sugar> takes, a
hash reference, or an array reference of names and stages in turn, and
names each pipeline in the package, with a function of its name, as
that module does. It defines them first, wherever they're given, so a
statement given with them can name one. It doesn't give the word
C<pipeline>, which L<Ekorn::Pipeline::Factories> exports, and
L<DBIx::Squirrel::Tooling> too. L</Pipelines> says how to use them.

The arguments are worked out then too. The environment, literals, and
what a C<BEGIN> block has set are there, but a variable the program
sets as it runs is not yet.

=head1 FUNCTIONS

=head2 database

    $dbh      = database($name);
    $function = database($name, @connect_args);

Given a name, returns the handle of the database defined by that name,
anywhere in the program. It connects to the database if it isn't
connected.

Given a name and the arguments L<DBIx::Squirrel/connect> takes, it
defines a database by that name. It gives the calling package a
function of that name, and returns the function.

A database defined with a database handle, in place of a data source,
is a clone of it, as L<DBIx::Squirrel/connect> makes. The clone is
made when the database is first used. The DBI makes a clone the way
the handle was made. So a clone of a handle from C<connect_cached>,
such as another database's, is that same handle.

A database is defined once in a program, by a name that can be a
function's. The package can't have a function of that name already.

=head2 statement

    $function = statement($name, $database, $statement, @stages);
    $function = statement($name, $database, $statement, \%attr, @stages);

Defines a statement by that name, on the database of that name. The
attributes are those to prepare it with, and the stages are its own.
It gives the calling package a function of that name, and returns the
function. The database is found when the function runs, so it can be
defined after the statement.

A stage in a definition can be a pipeline's name, as
L<Ekorn::Pipeline/named> names them. A name is looked up as the
statement is defined, in the package defining it, unless it's
qualified, as C<My::Module::clean>, so it must be defined first. One
that isn't croaks then, "No pipeline named main::clean". Each name
stands in its place among the stages. When the statement's function is
called, a string given is a bind value, never a name. On C<use>, name
the pipeline after C<pipeline>, in the same C<use> or one before it,
or with C<named> in a C<BEGIN> block above it.

    use DBIx::Squirrel::Sugar
        statement => {titles => [music => 'SELECT title FROM album', pluck, 'trimmed']},
        pipeline  => {trimmed => [sub { s( \A \s+ | \s+ \z )()xgr }]};

=head2 The function a database is given

    $dbh     = music();
    $sth     = music($statement, @bind_values);
    $sth     = music($statement, \%attr, @bind_values);
    $it      = music($statement, @bind_values, @stages);
    @results = music($statement, @bind_values, @stages, keep_all);
    $count   = music($statement, @bind_values, @stages, count_items);

Called with nothing, returns the database handle.

Called with a statement, prepares it and executes it with the bind
values, in any form L<DBIx::Squirrel::st/execute> takes. It returns
the statement handle, or nothing if it couldn't be executed. An
unblessed hash reference, or C<undef>, straight after the statement is
the attributes to prepare it with, as with L<DBIx::Squirrel::db/do>.

With stages at the end, it does what L<DBIx::Squirrel::db/iterate>
does: it returns an iterator over the results, or, if the last stage
is a sink, such as L<Ekorn::Pipeline::Sinks>' C<keep_all> or
C<count_items>, the sink's result. What it returns doesn't depend on
the calling context, but for a sink of many, such as C<keep_all>,
which gives a list, or, where one value is asked for, an array
reference.

The statement can be a statement handle, which is itself executed, or
iterated over.

=head2 The function a statement is given

    $sth     = artist(@bind_values);
    $it      = artist(@bind_values, @stages);
    @results = artist(@bind_values, @stages, keep_all);
    $count   = artist(@bind_values, @stages, count_items);

Executes the statement with the bind values, and returns the statement
handle, or nothing if it couldn't be executed.

With stages, its own or those given after the bind values, it returns
an iterator over the results, or, if the last stage is a sink, the
sink's result, as the function a database is given does. The results
go through its own stages, then those given. Stages given are for that
call only.

A sink is a function in the package that imports it, so a statement
can't take its name. Define C<count_items> as a statement where
C<count_items> is imported, and the definition croaks, as for any
function the package has. Import sinks by name, or call one by its
full name, C<Ekorn::Pipeline::Sinks::count_items()>.

The statement is prepared once for each database handle, with
L<DBIx::Squirrel::db/prepare_cached>. Its handle may be in use: by a
statement handle not read to the end, or by a stage calling the same
function. A call then prepares one of its own. A statement taking a
list (see L<DBIx::Squirrel::st/Lists>) is prepared for each call's
values instead, and isn't cached.

=head2 Pipelines

    use DBIx::Squirrel::Sugar pipeline => {$name => [@stages], ...};

    @results = loud(@values);
    @results = loud(@values, $pipeline);
    $it      = music($statement, @bind_values, pipeline('loud'));
    $it      = artist(@bind_values, pipeline('loud'));

Each pipeline after C<pipeline> is named in the package using
DBIx::Squirrel::Sugar, as L<Ekorn::Pipeline/named> names one. The
package gets a function of its name, which runs the values it's given
through the pipeline and returns what comes out, as
L<Ekorn::Pipeline::Sugar> describes: a list in list context, and in
scalar context a sink's result, or how many values came out. A
pipeline given last adds its stages to that call.

    use DBIx::Squirrel::Sugar pipeline => {
        first => [sub ($row) { $row->[0] }],
        loud  => ['first', sub { uc }],
    };

    my @loud = loud(['abba'], ['blondie']);    # ('ABBA', 'BLONDIE')

A statement's definition can name a pipeline among its stages, as
L</statement> says:

    use DBIx::Squirrel::Sugar statement => {
        artist_names => [music => 'SELECT name FROM artist', 'first'],
    };

When a statement runs, a string given to it is a bind value, never a
name. To use a named pipeline's stages for one call, give the pipeline
itself, which the word C<pipeline> returns for its name. Import
C<pipeline> from L<DBIx::Squirrel::Tooling> or
L<Ekorn::Pipeline::Factories>:

    use DBIx::Squirrel::Tooling qw(pipeline);

    my @names = music 'SELECT name FROM artist', pipeline('loud'), keep_all;

=head1 DIAGNOSTICS

=over

=item Expected database, pipeline or statement, not %s

C<use DBIx::Squirrel::Sugar> was given something other than
C<database>, C<pipeline> or C<statement> and their definitions.

=item Expected the pipelines after pipeline in a HASH or an ARRAY of pairs

=item Expected the pipelines after pipeline in pairs of a name and an ARRAY

What came after C<pipeline> wasn't a hash reference, or an array
reference of names and stages in turn. These, and the other errors in
the pipelines' definitions, are L<Ekorn::Pipeline::Sugar>'s messages.

=item Expected the arguments to connect to %s in an ARRAY

=item Expected the statement %s in an ARRAY

A definition given to C<use> wasn't an array reference.

=item Expected a name for a statement (%s)

A name can't be a function's.

=item Expected a database and a statement for %s

A statement given to C<use> didn't name its database, or have its SQL.

=item Expected only stages after the statement for %s: code references, pipelines or their names, or objects offering a stage's role method

A statement's definition had something after the statement and its
attributes that's neither a stage nor a pipeline's name.

=item No pipeline named %s

A statement's definition named a pipeline that wasn't defined. This is
Ekorn::Pipeline's message.

=item Expected a name for a database (%s)

A name can't be a function's.

=item Expected a database defined once (%s)

The name was given to another database already.

=item Expected no function of the name in %s already (%s)

The package has a function of that name already.

=item Expected a database named %s

L</database> was given a name no database has.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBIx::Squirrel::Iterator>, L<Ekorn::Pipeline::Sugar>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use v5.36;

package DBIx::Squirrel::Sugar;

use Ref::Util qw(is_arrayref is_coderef is_hashref);

use DBIx::Squirrel         qw();
use DBIx::Squirrel::Errors qw(croakf);
use DBIx::Squirrel::Util   qw(install_sub is_name shift_attrs split_stages);

use namespace::clean;

# Croak at the line that called DBIx::Squirrel.
our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;

# Each database defined, by name: the arguments to connect with, and the
# handle, once it's connected.
my %connect_args;
my %handle;

# Give the calling package database or statement, and define the
# databases or statements named in a hash reference after each, with
# their arguments in an array reference.
sub import ($class, @args) {
    state %define = (database => \&_define, statement => \&_define_statement);
    state %what = (database => 'arguments to connect to', statement => 'statement');
    my $package = caller;
    while (@args) {
        my $arg = shift @args;
        croakf 'Expected database or statement, not %s', $arg
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
    croakf 'Expected a database defined as %s', $name
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
    my $attrs = @rest
        && (!defined $rest[0] || is_hashref($rest[0])) ? shift @rest : undef;
    croakf 'Expected only stages after the statement for %s', $name
        if grep { !is_coderef($_) } @rest;
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

# Run a statement's function: execute the statement with the bind values
# given, and return its handle, or, with stages, its own or those given
# after the bind values, return the results. The statement is prepared
# once for each handle, with prepare_cached, which makes a new one,
# cached in its place, when the one prepared is in use; one taking a list
# is prepared for the values given, and not cached.
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
# those and stages after them, for the results.
sub _run ($name, @args) {
    my $dbh = database($name);
    return $dbh unless @args;
    my $statement = shift @args;
    return _execute($statement, @args)           if $statement isa 'DBI::st';
    return $dbh->iterate($statement, @args)->all if _ends_in_stages(\@args);
    my $attrs = shift_attrs(\@args);

    my $sth = DBIx::Squirrel::db::_prepare_as(    ## no critic (Subroutines::ProtectPrivateSubs)
        $dbh, prepare => $statement, $attrs, undef, @args,
    );
    return _execute($sth, @args);
}

# Execute a statement handle with the bind values given, and return it,
# or nothing if it couldn't be executed; or, with stages after the bind
# values, return the results.
sub _execute ($sth, @args) {
    return $sth->iterate(@args)->all if _ends_in_stages(\@args);
    defined $sth->execute(@args) or return;
    return $sth;
}

# Return true if a list of arguments ends in a stage.
sub _ends_in_stages ($args) {
    return @$args && is_coderef($args->[-1]);
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

    my @names = music 'SELECT name FROM artist',       # through stages
        sub ($row) { $row->[0] };

    # Anywhere in the program
    my $handle = database('music');

    # Statements, with stages of their own
    use DBIx::Squirrel::Sugar statement => {
        artist_names => [music => 'SELECT name FROM artist', sub ($row) { $row->[0] }],
        artist       => [music => 'SELECT * FROM artist WHERE id = :id'],
    };

    my @all   = artist_names;                             # the results
    my @upper = artist_names sub ($name) { uc $name };    # with more stages
    my $found = artist id => 1;                           # executed

    # Or defined as the program runs
    use DBIx::Squirrel::Sugar qw(database statement);
    database(archive => 'dbi:SQLite:dbname=archive.db', '', '', \%attr);
    statement(albums => archive => 'SELECT * FROM album');

=head1 DESCRIPTION

DBIx::Squirrel::Sugar gives each database a name, and the package that
names it a function of that name, which returns the database handle, or
runs a statement on it. It gives a statement a function too, which runs
it, with the bind values and any stages given.

A database is connected to when it's first used, not when it's defined,
with L<DBIx::Squirrel/connect_cached>, so two databases defined with the
same arguments share a handle, as C<connect_cached> shares it.

The handle is kept, and each use has the same one, without a ping to the
database each time. It's pinged only while its last call has failed,
which leaves the error to be read, and made again if the connection has
gone, or if the handle has been disconnected. So a connection that drops between uses is noticed by the
call after it, which fails, as it would with plain DBI, and the call
after that has a new connection.

=head1 IMPORTING

    use DBIx::Squirrel::Sugar qw(database statement);
    use DBIx::Squirrel::Sugar database => {$name => [@connect_args], ...};
    use DBIx::Squirrel::Sugar statement => {
        $name => [$database, $statement, \%attr, @stages], ...
    };

Gives the package L</database>, or L</statement>, or both. Given a hash
reference after either, it also defines each database or statement named
in it, with the arguments it takes, in an array reference, and gives the
package its function, while the package is compiled, so it can be
called without parentheses. The arguments are worked out then too: the
environment, literals, and what a C<BEGIN> block has set are there, but
a variable the program sets as it runs is not yet.

=head1 FUNCTIONS

=head2 database

    $dbh      = database($name);
    $function = database($name, @connect_args);

Given a name, returns the handle of the database defined by that name,
anywhere in the program, connecting to it if it isn't connected.

Given a name and the arguments L<DBIx::Squirrel/connect> takes, defines
a database by that name, gives the calling package a function of that
name, and returns the function. A database defined with a database
handle, in place of a data source, is a clone of it, as
L<DBIx::Squirrel/connect> makes, made when it's first used. The DBI
makes a clone the way the handle was made, so a clone of a handle from
C<connect_cached>, such as another database's, is that same handle.

A database is defined once in a program, by a name that can be a
function's, and the package can't have a function of that name already.

=head2 statement

    $function = statement($name, $database, $statement, @stages);
    $function = statement($name, $database, $statement, \%attr, @stages);

Defines a statement by that name, on the database of that name, with the
attributes to prepare it with, and stages, if given, gives the calling
package a function of that name, and returns the function. The database
is found when the function runs, so it can be defined after the
statement.

=head2 The function a database is given

    $dbh     = music();
    $sth     = music($statement, @bind_values);
    $sth     = music($statement, \%attr, @bind_values);
    @results = music($statement, @bind_values, @stages);
    $count   = music($statement, @bind_values, @stages);

Called with nothing, returns the database handle.

Called with a statement, prepares it, executes it with the bind values,
in any form L<DBIx::Squirrel::st/execute> takes, and returns the
statement handle, or nothing if it couldn't be executed. A hash
reference, or C<undef>, straight after the statement is the attributes
to prepare it with, as with L<DBIx::Squirrel::db/do>.

With stages, the code references at the end, it iterates over the
results, as L<DBIx::Squirrel::db/iterate> does, and returns them all, or
how many there were in scalar context.

The statement can be a statement handle, which is executed, or iterated
over, itself.

=head2 The function a statement is given

    $sth     = artist(@bind_values);
    @results = artist(@bind_values, @stages);
    $count   = artist(@bind_values, @stages);

Executes the statement with the bind values, and returns the statement
handle, or nothing if it couldn't be executed. With stages, its own or
those given after the bind values, it iterates over the results, through
its own stages and then those given, and returns them all, or how many
there were in scalar context. Stages given are for that call only.

The statement is prepared once for each database handle, with
L<DBIx::Squirrel::db/prepare_cached>. While its handle is in use, by a
statement handle not read to the end, or by a stage calling the same
function, a call prepares one of its own. A statement taking a list, as
L<DBIx::Squirrel::st/Lists> describes, is prepared for each call's
values instead, and isn't cached.

=head1 DIAGNOSTICS

=over

=item Expected database or statement, not %s

C<use DBIx::Squirrel::Sugar> was given something other than C<database>
or C<statement> and their definitions.

=item Expected the arguments to connect to %s in an ARRAY

=item Expected the statement %s in an ARRAY

A definition given to C<use> wasn't an array reference.

=item Expected a name for a statement (%s)

A name can't be a function's.

=item Expected a database and a statement for %s

A statement given to C<use> didn't name its database, or have its SQL.

=item Expected only stages after the statement for %s

A statement's definition had something other than code references after
the statement and its attributes.

=item Expected a name for a database (%s)

A name can't be a function's.

=item Expected a database defined once (%s)

The name was given to another database already.

=item Expected no function of the name in %s already (%s)

The package has a function of that name already.

=item Expected a database defined as %s

L</database> was given a name no database has.

=back

=head1 SEE ALSO

L<DBIx::Squirrel>, L<DBIx::Squirrel::Iterator>

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2024-2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut

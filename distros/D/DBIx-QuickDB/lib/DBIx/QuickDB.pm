package DBIx::QuickDB;
use strict;
use warnings;

our $VERSION = '0.000016';

use Carp;
use List::Util qw/first/;
use File::Temp qw/tempdir/;
use Module::Pluggable search_path => 'DBIx::QuickDB::Driver', max_depth => 4, require => 0;

my %CACHE;

END { local $?; %CACHE = () }

sub import {
    my $class = shift;
    my ($name, @args) = @_;

    return unless defined $name;

    my $spec = @args > 1 ? {@args} : $args[0];

    my $db = $class->build_db($name, $spec);

    my $caller = caller;
    no strict 'refs';
    *{"$caller\::$name"} = sub() { $db };
}

sub build_db {
    my $class = shift;
    my $name = ref($_[0]) ? undef : shift(@_);
    my $spec = shift(@_) || {};

    return $CACHE{$name}->{inst}
        if $name && $CACHE{$name} && !$spec->{nocache};

    unless ($spec->{dir}) {
        $spec->{dir}       = tempdir('DB-QUICK-XXXXXXXX', CLEANUP => 0, TMPDIR => 1);
        $spec->{cleanup}   = 1 unless defined $spec->{cleanup};
        $spec->{bootstrap} = 1 unless defined $spec->{bootstrap};
    }

    $spec->{autostart} = 1 unless defined $spec->{autostart};
    $spec->{autostop} = $spec->{autostart} unless defined $spec->{autostop};

    my $driver;
    my $drivers = $spec->{driver} ? [$spec->{driver}] : delete $spec->{drivers} || [$class->plugins];
    my %nope;
    for my $d (@$drivers) {
        my ($v, $fqn, $why) = $class->check_driver($d, $spec);
        if ($v) {
            $driver = $fqn;
            last;
        }
        $nope{$d} = $why;
    }

    unless ($driver) {
        my @err = "== Could not find a viable driver from the following ==";
        for my $d (keys %nope) {
            push @err => "\n=== $d ===", $nope{$d};
        }

        confess join "\n" => @err, "", "====================", "", "Aborting";
    }

    my $inst = $driver->new(%$spec);

    $CACHE{$name} = {spec => $spec, inst => $inst} if $name && !$spec->{nocache};

    $inst->bootstrap if $spec->{bootstrap};
    $inst->start     if $spec->{autostart};

    if (my $sql = $spec->{load_sql}) {
        $sql = $sql->{$driver->name} if ref($sql) eq 'HASH';
        $sql = [$sql] unless ref($sql) eq 'ARRAY';

        for (my $i = 0; $i < @$sql; $i += 2) {
            my ($db, $file) = @{$sql}[$i, $i + 1];
            $inst->load_sql($db => $file);
        }
    }

    return $inst;
}

sub check_driver {
    my $class = shift;
    my ($d, $spec) = @_;

    $d = "DBIx::QuickDB::Driver::$d" unless $d =~ s/^\+// || $d =~ m/^DBIx::QuickDB::Driver::/;

    my $f = $d;
    $f =~ s{::}{/}g;
    $f .= ".pm";

    my ($v, $why);
    if (eval { require $f }) {
        ($v, $why) = $d->viable($spec);
    }
    else {
        ($v, $why) = (0, "Could not load $d: $@");
    }

    return ($v, $d, $why);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickDB - Quickly start a db server.

=head1 DESCRIPTION

This library makes it easy to spin up a temporary database server for any
supported driver. PostgreSQL and MySQL are the initially supported drivers.

=head1 SYNOPSIS

These are nearly identical, creating databases that can be retrieved by name
globally. The difference is that the first will build them at compile-time and
will provide constants for accessing them. The second will build them at
run-time and you have to store them in variables.

=head2 DB CONSTANTS

    use DBIx::QuickDB MYSQL_DB => {driver => 'MySQL'};
    use DBIx::QuickDB PSQL_DB  => {driver => 'PostgreSQL'};

    my $m_dbh = MYSQL_DB->connect;
    my $p_dbh = PSQL_DB->connect;

    ...

=head2 DB ON THE FLY

    use DBIx::QuickDB;

    my $msql = DBIx::QuickDB->build_db(mysql_db => {driver => 'MySQL'});
    my $psql = DBIx::QuickDB->build_db(mysql_db => {driver => 'PostgreSQL'});

    my $m_dbh = $msql->connect;
    my $p_dbh = $psql->connect;

    ...

=head1 METHODS

=over 4

=item $db = DBIx::QuickDB->build_db();

=item $db = DBIx::QuickDB->build_db($name);

=item $db = DBIx::QuickDB->build_db(\%spec);

=item $db = DBIx::QuickDB->build_db($name => \%spec);


If a C<$name> is provided then the database will be named. If the named
database has already been created it will be returned ignoring any other
arguments. If the named db does not yet exist it will be created.

If a C<%spec> hashref is provided it will be used to construct the database.
See L</"SPEC HASH"> for what is supported in C<%spec>.

=item ($bool, $fqd, $why ) = DBIx::QuickDB->check_driver($driver => \%spec);

The first argument must be a driver name. The name may be shorthand IE
C<"PostgreSQL"> or it can be a fully qualified module name like
C<"DBIx::QuickDB::Driver::PostgreSQL">.

The second argument is option, but when present must be a spec hash. See
L</"SPEC HASH"> for what is supported in C<%spec>.

This method returns a sequence of 3 values:

=over 4

=item $bool

True if the driver is viable for the specifications. False if the driver cannot
be used.

=item $fqd

The full package name for the driver.

=item $why

If C<$bool> is false then this will have an explanation for why the driver is
not viable.

=back

=back

=head1 SPEC HASH

Here is an overview of all options allowed:

    my %spec = (
        autostart => BOOL,
        autostop  => BOOL,
        bootstrap => BOOL,
        cleanup   => BOOL,
        dir       => PATH,
        driver    => DRIVER_NAME,
        drivers   => ARRAYREF,
        load_sql  => FILE_OR_HASH,
        nocache   => BOOL,
    );

=over 4

=item autostart => BOOL

Defaults to true. When true the DB server will be started automatically. If
this is false then you will need to call C<< $DB->start >> yourself.

=item autostop  => BOOL

Defaults to be the same as the C<'autostart'> key.

When true, the server will automatically be stopped when the program ends.

=item bootstrap => BOOL

This defaults to true unless the C<'dir'> key is also provided, in which case
it will default to false.

When true this will cause the database to be bootstrapped into existance in the
specified (or generated) directory (IE the C<'dir'> key).

=item cleanup => BOOL

This defaults to true unless the C<'dir'> key is also provided, in which case
it will default to false.

When true the databse directory will be completely deleted when the program is
finished. B<DO NOT USE THIS ON ANY IMPORTANT DATABASES>.

=item dir => PATH

Use this key to point at an existing database directory. If not provided a
tempdir will be generated.

=item driver => DRIVER_NAME

This key lets you specify a driver to use. This must be a string, and can
either be the shorthand name IE 'PostgreSQL', or the full name IE
'DBIx::QuickDB::Driver::PostgreSQL'.

If this key is present then no other drivers will be tried or used.

If this key is missing then the C<'drivers'> key will be used. If both keys are
empty than any installed driver may be used.

=item drivers => ARRAYREF

If you are only a little picky about driver choice then you can use this to
list several drivers that are acceptible, the first one that works will be
used.

This key is ignored if the C<'driver'> key is specified. If both keys are empty
than any installed driver may be used.

=item load_sql => FILE_OR_HASH

This can be a path to an SQL file to load, an arrayref of several files to
load, or a structure with driver specific files to load.

    load_sql => '/path/to/my/schema.sql'

    load_sql => ['schema1.sql', 'schema2.sql']

    load_sql => {
        PostgreSQL => 'path/to/postgre.sql',
        MySQL      => 'path/to/my.sql',
        SQLite     => ['sqlite1.sql', 'sqlite2.sql'],
    }

=item nocache => BOOL

Defaults to false. When set to true the database will not be available globally
by the name passed into C<build_db()>.

=back

=head1 SOURCE

The source code repository for DBIx-QuickDB can be found at
F<https://github.com/exodist/DBIx-QuickDB/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut

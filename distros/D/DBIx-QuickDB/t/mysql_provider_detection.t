use Test2::V0;
use File::Temp qw/tempdir/;

use DBIx::QuickDB::Driver::MySQLCom;
use DBIx::QuickDB::Driver::Percona;
use DBIx::QuickDB::Driver::MariaDB;

# Stub "servers" that only answer -V, so no real MySQL is needed.
skip_all "stub servers require a POSIX shell (#!/bin/sh), unavailable on $^O"
    if $^O eq 'MSWin32';

my $dir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);

sub stub_bin {
    my ($name, $version_line) = @_;
    my $path = "$dir/$name";
    open(my $fh, '>', $path) or die "Could not write stub: $!";
    print $fh "#!/bin/sh\necho \"$version_line\"\n";
    close($fh);
    chmod(0755, $path);
    return $path;
}

my %stubs = (
    oracle   => 'mysqld  Ver 8.4.11 for Linux on x86_64 (MySQL Community Server - GPL)',
    ubuntu   => 'mysqld  Ver 8.4.11-0ubuntu0.26.04.1 for Linux on x86_64 ((Ubuntu))',
    homebrew => 'mysqld  Ver 9.4.0 for macos15.4 on arm64 (Homebrew)',
    ports    => 'mysqld  Ver 8.0.43 for FreeBSD14.3 on amd64 (Source distribution)',
    percona  => 'mysqld  Ver 8.0.42-33 for Linux on x86_64 (Percona Server (GPL), Release 33, Revision 9dc49998)',
    mariadb  => 'mariadbd  Ver 11.8.9-MariaDB for Linux on x86_64 (MariaDB Server)',
    garbage  => 'not a database server',
);
my %bin = map { $_ => stub_bin($_, $stubs{$_}) } keys %stubs;

my %expect = (
    'DBIx::QuickDB::Driver::MySQLCom' => {oracle => 1, ubuntu => 1, homebrew => 1, ports => 1, percona => 0, mariadb => 0, garbage => 0},
    'DBIx::QuickDB::Driver::Percona'  => {oracle => 0, ubuntu => 0, homebrew => 0, ports => 0, percona => 1, mariadb => 0, garbage => 0},
    'DBIx::QuickDB::Driver::MariaDB'  => {oracle => 0, ubuntu => 0, homebrew => 0, ports => 0, percona => 0, mariadb => 1, garbage => 0},
);

for my $class (sort keys %expect) {
    subtest $class => sub {
        for my $stub (sort keys %stubs) {
            is($class->verify_provider($bin{$stub}), $expect{$class}{$stub}, "$stub: $stubs{$stub}");
        }
    };
}

done_testing;

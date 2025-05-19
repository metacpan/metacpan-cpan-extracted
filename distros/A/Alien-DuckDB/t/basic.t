use strict;
use warnings;
use Test2::V0;
use Test::Alien;
use Alien::DuckDB;
use Path::Tiny qw(path);
use Config;
use File::Spec;

# Basic Alien module test
alien_ok 'Alien::DuckDB';

# Basic module loading test (replacing require_ok)
ok(eval { require Alien::DuckDB; 1 }, "Can load Alien::DuckDB");

# Instantiate DuckDB
my $duckdb = Alien::DuckDB->new;

# Core property tests
my $version = Alien::DuckDB->version;
ok(defined $version, "Version is defined: $version");

my $install_type = Alien::DuckDB->install_type;
ok(defined $install_type, "Install type is defined: $install_type");
note("Installation type: $install_type");

my $cflags = Alien::DuckDB->cflags;
ok(defined $cflags, "Can retrieve cflags: $cflags");

my $libs = Alien::DuckDB->libs;
ok(defined $libs, "Can retrieve libs: $libs");

# Library file tests
my @dynamic_libs = Alien::DuckDB->dynamic_libs;
ok(@dynamic_libs > 0, "Dynamic libraries found: " . join(", ", @dynamic_libs));
ok -f $_, "Library file exists: $_" for @dynamic_libs;

# Header file tests
my $inc = path($duckdb->dist_dir, 'include');
ok -f $inc->child('duckdb.h'), "Found duckdb.h";
ok -f $inc->child('duckdb.hpp'), "Found duckdb.hpp" if -f $inc->child('duckdb.hpp');

# Advanced FFI tests
my $xs = do {
  local $@ = '';
  eval { require FFI::Platypus };
  !$@;
};

SKIP: {
    skip "FFI tests require FFI::Platypus", 2 unless $xs;

    ffi_ok { symbols => ['duckdb_library_version'] },
        with_subtest {
            my($ffi) = @_;

            # Test version function
            $ffi->attach('duckdb_library_version' => [] => 'string');
            like duckdb_library_version(), qr/^v?1\.2\.2/, 'Got correct version via FFI';
        };
}

# Additional debugging information
note("Dynamic libraries: " . join(", ", @dynamic_libs));
note("Install prefix: " . Alien::DuckDB->dist_dir);

done_testing();

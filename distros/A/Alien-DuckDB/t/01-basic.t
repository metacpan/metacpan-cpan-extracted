use Test2::V0;
use Test::Alien;
use blib;
use Alien::DuckDB;
use Path::Tiny qw(path);

alien_ok 'Alien::DuckDB';
my $xs = do {
  local $@ = '';
  eval { require FFI::Platypus };
  !$@;
};

my $duckdb = Alien::DuckDB->new;

# Test library files
my @libs = $duckdb->dynamic_libs;
ok @libs, "found dynamic libraries";
ok -f $_, "library exists: $_" for @libs;

# Test header files
my $inc = path($duckdb->dist_dir, 'include');
ok -f $inc->child('duckdb.h'), "found duckdb.h";
ok -f $inc->child('duckdb.hpp'), "found duckdb.hpp" if -f $inc->child('duckdb.hpp');

SKIP: {
    skip "FFI tests require FFI::Platypus", 2 unless $xs;

    ffi_ok { symbols => ['duckdb_library_version'] }, 
        with_subtest {
            my($ffi) = @_;
            
            # Test version function
            $ffi->attach('duckdb_library_version' => [] => 'string');
            like duckdb_library_version(), qr/^v?1\.1\.3/, 'got correct version via FFI';
        };
}

done_testing;

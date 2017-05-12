use strict;
use warnings;

use Test::More tests => 2;
use Asset::Pack qw( write_index );
use Test::TempDir::Tiny;
use Test::Fatal qw( exception );
use Path::Tiny qw( path );
use Cwd;

my $temp   = tempdir();
my $sample = {
  a => 1,
  b => 2,
  d => path('.'),
};
my $code = write_index( $sample, 'Test::X::Index', "$temp/lib" );

unshift @INC, "$temp/lib";
use_ok("Test::X::Index");
is_deeply( $sample, do { no warnings 'once'; $Test::X::Index::index }, "Stored index resurrected from disk intact" );

use strict;
use warnings;

use Test::More;

BEGIN {
  my %required = (
    'App::FatPacker' => '0.009017'    # Minimum required for fatpack_file
  );
  for my $key ( keys %required ) {
    next if eval "require $key; $key->VERSION( $required{$key} ); 1";
    next if $ENV{RELEASE_TESTING};
    plan skip_all => "$key version >= $required{$key} required for this test";
    exit 0;
  }
  plan tests => 3
}

use Test::TempDir::Tiny qw( tempdir );
use Path::Tiny qw( path cwd );
use Asset::Pack qw( find_and_pack );

# ABSTRACT: Test interop with App::FatPacker

my $temp = tempdir('source_tree');
my $cwd  = cwd();
END { chdir $cwd }

path( $temp, 'assets' )->mkpath;
path( $temp, 'lib' )->mkpath;
path( $temp, 'bin' )->mkpath;

path( $temp, 'bin', 'myscript.pl' )->spew_raw(<<'EOF');
use strict;
use warnings;

package myscript;

use Test::X::FindAndPack::examplejs;

sub value {
  return $Test::X::FindAndPack::examplejs::content;
}
1;
EOF

path( $temp, 'assets', 'example.js' )->spew_raw(<<'EOF');
( function() {
  alert("this is javascript!");
} )();
EOF

my $layout = find_and_pack( path( $temp, 'assets' ), 'Test::X::FindAndPack', path( $temp, 'lib' ), );

my $packer = App::FatPacker->new();

chdir $temp;

my $content = $packer->fatpack_file( path( $temp, 'bin', 'myscript.pl' ) );
my $target = path( $temp, 'bin', 'myscript.fatpacked.pl' );

$target->spew_raw($content);

ok( do "$target", "Sourcing fatpacked script works" );

can_ok( 'myscript', 'value' );

is( myscript->value, path( $temp, 'assets', 'example.js' )->slurp_raw(), "Content from fatpacked script ok" );

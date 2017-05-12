use strict;
use warnings;

use Test::More tests => 3 * 2;

use 5.006;
use Path::Tiny;
use Test::TempDir::Tiny qw(tempdir);
use Asset::Pack qw(write_module);
use Test::Differences qw( eq_or_diff );

my $tmpdir = tempdir;
unshift @INC, $tmpdir;
my %paths = (
  't/write_module.t'  => 'Test::PackT',
  'LICENSE'           => 'Test::LICENSE',
  'lib/Asset/Pack.pm' => 'Test::AssetPack',
);
foreach my $p ( keys %paths ) {
  my $content = path($p)->slurp_raw;
  write_module( $p, $paths{$p}, $tmpdir );
  use_ok( $paths{$p} );
  {
    no strict 'refs';
    eq_or_diff( ${"$paths{$p}::content"}, $content, "Loaded and decoded copy of $p" );
  }
}

use strict;
use warnings;

use Test::More tests => 1;

# ABSTRACT: Test _pack_metadata

use Asset::Pack;
use Test::TempDir::Tiny qw( tempdir );
use Path::Tiny qw( path );
use Test::Differences qw( eq_or_diff );

*pack_asset = \&Asset::Pack::_pack_asset;

sub mk_pack {
  my ( $file, $packed_class ) = @_;
  local $@;
  do $file or die "Did not get true return, $@";
  my $stash_contents = {};
  no strict 'refs';
  my $stash = \%{ $packed_class . '::' };

  for my $key ( keys %{$stash} ) {
    local $@;
    eval {
      my $value = ${ $stash->{$key} };
      $stash_contents->{$key} = $value;
      1;
    } and next;
    warn "$@ while scalarizing $key";
  }
  return $stash_contents;
}

my $tempdir = tempdir();
my $binfile = path( $tempdir, 'binary_ranges.bin' );

my $fh = $binfile->openw_raw;
print {$fh} "Single\n";

for ( 0 .. 255 ) {
  print {$fh} chr;
  if ( $_ % 10 == 0 ) {
    print {$fh} "\n";
  }
}

close $fh;

my $packed_data = pack_asset( 'Test::X::BinaryRanges', "$binfile" );
my $content_file = path( $tempdir, "TestXBinaryRanges.pm" );
$content_file->spew_raw($packed_data);

my $unpack = mk_pack( "$content_file", 'Test::X::BinaryRanges' );

eq_or_diff( $binfile->slurp_raw, $unpack->{content}, 'Class contains binary data un-damaged', );

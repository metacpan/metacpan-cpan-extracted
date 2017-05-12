package Test::Util;

use warnings;
use strict;
use File::Spec;
use Test::Builder;

use 5.010;

use base 'Exporter';
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

@EXPORT_OK = qw(rewrite_shebang);
my $Test = Test::Builder->new;

# reads in perl script and replaced the shebang line with current perl executable
sub rewrite_shebang {
  my ( $script, $new_script ) = @_;

  $new_script = File::Spec->rel2abs($new_script);
  my $found_shebang;
  open my $fh,  '<', $script     or die "Can't open filehandle: $!";
  open my $ofh, '>', $new_script or die "Can't open filehandle: $!";
  while (<$fh>) {
    if ( !$found_shebang && /^#!.*perl/ ) {
      print $ofh "#!$^X\n";
      $found_shebang++;
    } else {
      print $ofh $_;
    }
  }
  $ofh->close;
  $fh->close;
  chmod 0700, $new_script;
  return $new_script;
}

1;

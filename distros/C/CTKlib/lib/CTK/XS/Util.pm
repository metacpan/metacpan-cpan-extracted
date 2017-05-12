package CTK::XS::Util;
use strict;

use vars qw($VERSION);
our $VERSION = '1.00';

use base qw/ Exporter /;
our @EXPORT = qw/ shred /;
our @EXPORT_OK = @EXPORT;

use XSLoader;
XSLoader::load( __PACKAGE__, $VERSION ? $VERSION : '1.00' );

use Carp;
use File::Spec::Functions qw/ splitpath catpath /;
use File::Copy qw/ move /;

sub test { return xstest() }

sub shred($) {
  my $fn = shift || '';
  my $sz = ($fn && -e $fn) ? (-s _) : 0;
  return 0 unless wipef($fn, $sz);

  my ($vol,$dir,$file) = splitpath( $fn );

  my $nn = '';
  for (my $i = 0; $i < 5; $i++) {
    $nn = catpath($vol,$dir,_sr(8).'.'._sr(3));
    last unless -e $nn;
    $nn = '';
  }
  unless ($nn) {
    carp("Can't rename file \"$file\". Undefined new file");
    return 0;
  }

  move($fn,$nn) or (carp("Can't move file \"$file\"") && return 0);
  unlink $nn or (carp("Could not unlink $nn: $!") && return 0);
  return 1;
}

sub _sr {
  my $l = shift || return '';
  my @as = ('a'..'z','A'..'Z');
  my $rst = '';
  $rst .= $as[(int(rand($#as+1)))] for (1..$l);
  return $rst;
}

1;


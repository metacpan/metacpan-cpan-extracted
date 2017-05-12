
use strict;
use warnings;

use Test::More skip_all => 'Example alternative technique that doesn\'t work';

use lib "t/lib/";
use Data;

{

  package Dh;

  use strict;
  use warnings;

  use Carp;

  our %offsets;

  sub new {

    my ( $class, $package ) = @_;
    unless ( defined $package ) {
      $package = "main";    #FIXME: maybe this should use caller
    }
    my $dh_name = "${package}::DATA";
    my $orig_dh = do { no strict 'refs'; \*{$dh_name} };
    open my $dh, "<&", $orig_dh
      or croak "could not dup $dh_name: $!";
    if ( exists $offsets{$dh_name} ) {
      seek $dh, $offsets{$dh_name}, 0;
    }
    else {
      $offsets{$dh_name} = tell $orig_dh;
    }

    return $dh;
  }
}

my $x = Dh->new('Data');
my $y = Dh->new('Data');

use Data::Dumper;
use Scalar::Util qw( refaddr );

for ( 1 .. 5 ) {
  for ( $x, $y ) {
    print "refaddr: " . refaddr($_) . "\n";
    print "getc:  " . getc($_) . "\n";
    print "tell:  " . tell($_) . "\n";
  }
}


use strict;
use warnings;

use Test::More skip_all => 'Example alternative technique that doesn\'t work';

use lib "t/lib/";
use Data;

sub getfd {
  my $handle = do {
    no strict 'refs';
    \*{"Data::DATA"};
  };
  open my $dh, "<&", $handle or die "Cant fdup";
  return $dh;
}

my $x = getfd();
my $y = getfd();

local $/ = undef;

my $x_data = <$x>;
my $y_data = <$y>;

is( $x_data, $y_data, "Values are the same" );

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


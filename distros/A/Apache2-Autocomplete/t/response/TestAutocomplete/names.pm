package TestAutocomplete::names;
use strict;
use warnings;
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();

use base qw(Apache2::Autocomplete);
my @NAMES = qw(alice bob charlie tom dick jane janice allen diane);

sub expand {
  my ($self, $query) = @_;
  my $re = qr/^\Q$query\E/i;
  my @names = grep /$re/, @NAMES;
  my @desc = map {"42 is the answer"} @names;
  (lc $query, \@names, \@desc, [""]);
}

sub handler {
  my $r = shift;
  my $ac = __PACKAGE__->new($r);
  $ac->run();
  return Apache2::Const::OK;
}

1;

__END__

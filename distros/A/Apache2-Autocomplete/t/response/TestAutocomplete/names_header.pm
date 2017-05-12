package TestAutocomplete::names_header;
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
  my $header = {'Content-Type' => 'text/html; charset=utf-8',
		'X-err_header_out' => 'err_headers_out',
	       };
  my $ac = __PACKAGE__->new($r);
  $ac->run($header);
  return Apache2::Const::OK;
}

1;

__END__

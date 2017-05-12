package TestCGI::param;

use strict;
use warnings FATAL => 'all';
use CGI::Apache2::Wrapper;
use Apache2::RequestIO;
use Apache2::RequestRec;
use Apache2::Const -compile => qw(OK SERVER_ERROR);

sub handler {
  my $r = shift;
  my $cgi = CGI::Apache2::Wrapper->new($r);
  my $len = 0;

  for ($cgi->param) {
    my $val = $cgi->param($_) || '';
    $len += length($_) + length($val) + 2; # +2 ('=' and '&')
  }
  $len--; # the stick with two ends one '&' char off

  $r->content_type('text/plain');
  $r->print($len);

  return Apache2::Const::OK;
}

1;

__END__

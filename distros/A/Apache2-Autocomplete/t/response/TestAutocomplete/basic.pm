package TestAutocomplete::basic;
use strict;
use warnings;
use Apache::Test qw(-withtestmore);
use Apache::TestUtil;
use Apache2::Const -compile => qw(OK SERVER_ERROR);
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();

use base qw(Apache2::Autocomplete);
my $i = 0;
my @NAMES = qw(alice bob charlie tom dick jane janice allen diane);
my %NAMES = map {$_ => $i++} @NAMES;

sub expand {
  my ($self, $query) = @_;
  my $re = qr/^\Q$query\E/i;
  my @names = grep /$re/, @NAMES;
  my @desc = map {$NAMES{$_}} @names;
  (lc $query, \@names, \@desc, [""]);
}


sub handler {
  my ($r) = @_;
  plan $r, tests => 12;
  my $ac = __PACKAGE__->new($r);
  isa_ok($ac, __PACKAGE__);
  for my $method(qw(expand run header no_js param query)) {
    can_ok($ac, $method);
  }
  my $cgi = $ac->cgi;
  like(ref($cgi), qr{^CGI});
  my $self_r = $ac->r;
  isa_ok($self_r, 'Apache2::RequestRec');

 SKIP: {
    eval {require CGI::Apache2::Wrapper;};
    skip "CGI::Apache2::Wrapper not installed", 3 if $@;
    isa_ok($cgi, 'CGI::Apache2::Wrapper');
    my $cgi_r = $cgi->r;
    isa_ok($cgi_r, 'Apache2::RequestRec');
    my $cgi_req = $cgi->req;
    isa_ok($cgi_req, 'Apache2::Request');
  }

  return Apache2::Const::OK;
}


1;

__END__

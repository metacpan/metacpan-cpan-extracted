package TestsFor::Cikl::DataTypes::Url;
use lib 'testlib';
use base qw(Cikl::DataTypes::TestClass);
use strict;
use warnings;
use Test::More;
use URI;

use Cikl::DataTypes::Url;

sub testing_class { "Cikl::DataTypes::Url"; }

use constant GOOD_URLS => qw(
  http://www.foo.com/
  https://www.foo.com/
  ftp://foo.com/asdf
);

use constant BAD_SCHEMES => qw(
  file:/asdf/laksdjf/asdlkfj.txt
  asdf/laksdjf/asdlkfj.txt
  data:1234
  rtsp://foobar.com/
);

sub required_to_be_string : Test(2) {
  my $self = shift;
  my $type = $self->get_constraint();
  my $url_text = "http://foobar.com/";
  my $url = URI->new($url_text);
  ok(! $type->check($url), "reject a URI object");
  ok($type->check($url_text), "accept a string");
}

sub required_to_have_scheme : Test(2) {
  my $self = shift;
  my $type = $self->get_constraint();
  my $url = "foo.com/bar";
  ok(! $type->check($url), "fail to validate without scheme");
  $url = 'http://' . $url;
  ok($type->check($url), "validates with a scheme");
}

sub required_to_have_a_host : Test(1) {
  my $self = shift;
  my $type = $self->get_constraint();
  my $url = "file://foo/bar.txt";
  ok(! $type->check($url), "fail to validate without a host");
}

sub test_good_urls : Tests {
  my $self = shift;
  my $type = $self->get_constraint();

  foreach my $url (GOOD_URLS) {
    ok($type->check($url), "'$url' is a valid URL");
  }
}

sub test_bad_schemes : Tests {
  my $self = shift;
  my $type = $self->get_constraint();

  foreach my $url (BAD_SCHEMES) {
    ok(! $type->check($url), "reject invalid/missing scheme '$url'");
  }
}
1;

Test::Class->runtests;

package TestCGI::cookie3;

# tests from CGI.pm's cookie.t
use strict;
use warnings FATAL => 'all';

use Apache::Test qw(-withtestmore);
use Apache::TestUtil;

use Apache2::RequestRec ();
use Apache2::Const -compile => qw(OK);

use CGI::Apache2::Wrapper ();

sub handler {
  my $r = shift;
  my $cgi = CGI::Apache2::Wrapper->new($r);
  plan $r, tests => 22;

  {
    # Try new with full information provided
    my $c = $cgi->cookie(-name    => 'foo',
			 -value   => 'bar',
			 -expires => '+3M',
			 -domain  => '.capricorn.com',
			 -path    => '/cgi-bin/database',
			 -secure  => 1
			);
    is(ref($c), 'CGI::Apache2::Wrapper::Cookie', 
       'new returns objects of correct type');
    is($c->name   , 'foo',               'name is correct');
    is($c->value  , 'bar',               'value is correct');
    #    like($c->expires, 
    #    '/^[a-z]{3},\s*\d{2}-[a-z]{3}-\d{4}/i', 'expires in correct format');
    is($c->domain , '.capricorn.com',    'domain is correct');
    is($c->path   , '/cgi-bin/database', 'path is correct');
    ok($c->secure , 'secure attribute is set');
  }
  #------------------------------------------------------------------------
  # Test as_string
  #-----------------------------------------------------------------------
  {
    my $c = $cgi->cookie(-name    => 'Jam',
			 -value   => 'Hamster',
			 -expires => '+3M',
			 -domain  => '.pie-shop.com',
			 -path    => '/',
			 -secure  => 1
			);
    my $name = $c->name;
    like($c->as_string, "/$name/", "Stringified cookie contains name");
    my $value = $c->value;
    like($c->as_string, "/$value/", "Stringified cookie contains value");
    #    my $expires = $c->expires;
    #    like($c->as_string, "/$expires/", 
    #    "Stringified cookie contains expires");
    my $domain = $c->domain;
    like($c->as_string, "/$domain/", "Stringified cookie contains domain");
    my $path = $c->path;
    like($c->as_string, "/$path/", "Stringified cookie contains path");
    like($c->as_string, '/secure/', "Stringified cookie contains secure");
  }
  #-------------------------------------------------------------------
  # Test name, value, domain, secure, expires and path
  #--------------------------------------------------------------------
  {
    my $c = $cgi->cookie(-name    => 'Jam',
			 -value   => 'Hamster',
			 -expires => '+3M',
			 -domain  => '.pie-shop.com',
			 -secure  => 1
			);
    is($c->name,          'Jam',   'name is correct');
    is($c->value,         'Hamster', 'value is correct');
    is($c->domain,        '.pie-shop.com', 'domain is correct');
    is($c->domain('.wibble.co.uk'), '.wibble.co.uk',
       'domain is set correctly');
    is($c->domain,                  '.wibble.co.uk',
       'domain now returns updated value');
    is($c->path,             '/',        'path is correct default');
    is($c->path('/basket/'), '/basket/',        'path is set correctly');
    is($c->path,             '/basket/', 'path now returns updated value');
    ok($c->secure,     'secure attribute is set');
    ok(! $c->secure(0),  'secure attribute is cleared');
    ok(!$c->secure,    'secure attribute is cleared');
  }
  return Apache2::Const::OK;
}

1;

__END__

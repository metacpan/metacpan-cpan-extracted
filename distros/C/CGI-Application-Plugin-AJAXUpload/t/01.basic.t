use strict;
use warnings;
use Carp;
use Test::More tests => 2;
use Test::NoWarnings;
use lib qw(t/lib);
use CGI;
use TestWebApp;

subtest 'create a webapp object' => sub{
    plan tests => 1;
    my $app = TestWebApp->new;
    isa_ok($app, 'CGI::Application');
}



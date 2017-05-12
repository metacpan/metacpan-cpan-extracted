use Test::More tests => 2;
BEGIN { use_ok('CGI::Application::Plugin::HTMLPrototype') };

use strict;

{
    package TestAppBasic;

    use base qw(CGI::Application);
    use CGI::Application::Plugin::HTMLPrototype;

    1;
};

use CGI;
my $t1_obj = TestAppBasic->new();
my $prototype = $t1_obj->prototype();

isa_ok($prototype, 'HTML::Prototype');


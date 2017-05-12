#!perl

use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

BEGIN{ use_ok('CGI::Application'); }

# bring in testing hierarchy
use lib './test';
use CGIAPP_TestApp2;

$ENV{CGI_APP_RETURN_ONLY} = 1;

LOAD_TMPL_TESTING:
{
    my $app = CGIAPP_TestApp2->new( TMPL_PATH => [ qw(test/templates) ]);
    ok(my $tmpl = $app->load_tmpl('test.tmpl'), "Created new page template");
    isa_ok($tmpl, "HTML::Template::Compiled");

    # Make sure setting a bad <tmpl_var> doesn't die
    lives_ok { $tmpl->param( invalid => "BLAH" ) } "load_tmpl() overridden successfully";
}


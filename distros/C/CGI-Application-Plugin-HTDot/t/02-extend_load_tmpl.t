#!/usr/bin/env perl -T

use strict;
use warnings;
use Test::More tests => 7;
use Test::Exception;
use lib './t';

BEGIN{ use_ok('CGI::Application::Plugin::HTDot'); }
$ENV{CGI_APP_RETURN_ONLY} = 1;

LOAD_TMPL_TESTING: {
    use TestApp2;

    my $app = TestApp2->new( TMPL_PATH => [ qw( ./t/templates ) ]);
    ok( my $tmpl = $app->load_tmpl( 'test.tmpl' ), "Created new page template" );
    isa_ok( $tmpl, "HTML::Template::Pluggable" );

    # Make sure setting a bad <tmpl_var> doesn't die
    lives_ok { $tmpl->param( invalid => "BLAH" ) } "load_tmpl() overridden successfully";
}

MY_LOAD_TMPL_TESTING: {
    use TestApp3;

    my $app = TestApp3->new( TMPL_PATH => [ qw( ./t/templates ) ]);
    ok( my $tmpl = $app->load_tmpl( 'test.tmpl' ), "Created new page template" );
    isa_ok( $tmpl, "HTML::Template::Pluggable" );

    # Make sure setting a bad <tmpl_var> doesn't die
    lives_ok { $tmpl->param( invalid => "BLAH" ) } "Callback implemented successfully";
}

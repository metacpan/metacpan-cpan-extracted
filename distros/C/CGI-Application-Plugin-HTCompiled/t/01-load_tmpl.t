#!perl 

package CGIAPP_TestApp2;
use strict;
use warnings;
use Test::More qw/no_plan/;
use base ("CGI::Application::Plugin::HTCompiled", "CGI::Application");

{
    use HTML::Template::Compiled;
    my $t = HTML::Template::Compiled->new( 
        filename           => 'test.tmpl',
        path           => [ qw{test/templates} ],
        case_sensitive => 0,
    );
    isa_ok($t, "HTML::Template::Compiled");
}

$ENV{CGI_APP_RETURN_ONLY} = 1;

    my $app = CGIAPP_TestApp2->new( TMPL_PATH => [ qw(test/templates) ]);
    ok(my $tmpl = $app->load_tmpl('test.tmpl', case_sensitive => 0 ), "Created new page template");
    isa_ok($tmpl, "HTML::Template::Compiled");

    {
        $tmpl->param('test','basic tmpl_var test');
        like($tmpl->output,qr/basic tmpl_var test/, "basic tmpl_var is working");
    }

    {
        $tmpl->param( foo => { zoo => 'Working' } );    
        like($tmpl->output,qr/Working/, "c dot notation is working");
    }



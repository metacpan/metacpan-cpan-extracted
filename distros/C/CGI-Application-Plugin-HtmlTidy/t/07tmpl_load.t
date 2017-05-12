#!/usr/bin/perl

# Test for the bug reported by Alexander Becker:
# when the user overrides CA::load_tmpl to set die_on_bad_params=>1, this plugin crashes.
# The suggested fix is to load our template directly using HTML::Template.

use strict;

use Test::More tests => 1;

use lib './t';

eval "require CGI::Application::Plugin::DevPopup";

SKIP: {
    skip "This test is only relevant in combination with CGI::Application::Plugin::DevPopup", 1 if $@;


    $ENV{CGI_APP_RETURN_ONLY} = 1;
    $ENV{REQUEST_METHOD} = 'GET';
    $ENV{CAP_DEVPOPUP_EXEC} = 1;
    require TemplateApp;
    my $app = TemplateApp->new(PARAMS=> {
                    htmltidy_config => {
                        config_file => './t/tidy.conf',
                    }
            });
    $app->start_mode('non_html');
    my $out = eval { return $app->run; };

    unlike($@, qr/Error executing class callback in devpopup_report stage: HTML::Template/, 'template loaded ok');
}

__END__
t/07tmpl_load....1..1
ok 1 - template loaded ok
ok
All tests successful.
Files=1, Tests=1,  0 wallclock secs ( 0.09 cusr +  0.00 csys =  0.09 CPU)

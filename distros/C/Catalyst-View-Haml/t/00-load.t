#!perl

use Test::More tests => 2;

BEGIN {
    use_ok( 'Catalyst::View::Haml' ) || print "Bail out!
";
}

diag( "Testing Catalyst::View::Haml $Catalyst::View::Haml::VERSION, Perl $], $^X" );

can_ok 'Catalyst::View::Haml', qw(haml catalyst_var template_extension 
                                  path charset format vars_as_subs 
                                  escape_html ACCEPT_CONTEXT process render
                               );
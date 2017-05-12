#!/usr/bin/perl

use strict;
use Test::More tests => 14;

BEGIN {
	# for compat with 5.6.1, load libraries before chdir. 
	# Old MakeMaker passes relative paths to -I which break after chdir.
    eval {require './TestApp.pm'} || require './t/TestApp.pm';
    chdir   './t';
}

# The simplest App that does nothing...
{
    my $app = TestApp1->new();
    my $out = $app->capture( 'process' );
    like( $$out, qr/Hello, World!/, "Empty App (1)" );
}

# The simplest App that does nothing...
{
    my $app = TestApp2->new( cgi => CGI->new({ p => 'testapp2'}) );
    my $out = $app->capture( 'process' );
    like( $$out, qr/Republic of Perl/, "Manually adding vars" );
}

# Lookups
{
    my $app = TestApp3->new( cgi => CGI->new({ p => 'testapp3'}) );
    my $out = $app->capture( 'process' );
    like( $$out, qr/Republic of Perl/, "Set scalar in default Lookups package" );
}

{
    my $app = TestApp4->new( cgi => CGI->new({ p => 'testapp4'}) );
    my $out = $app->capture( 'process' );
    like( $$out, qr/Earth/, "Set array in default Lookups package" );
}

{
    my $app = TestApp5->new( cgi => CGI->new({ p => 'testapp5'}) );
    my $out = $app->capture( 'process' );
    like( $$out, qr/A short string that's easy to test/, "Set sub in default Lookups package" );
}

{
    my $app = TestApp6->new( cgi => CGI->new({ p => 'testapp6'}) );
    $app->tt_vars( 
        test_sub => sub {
            my $app   = shift;
            my $param = shift;

            is( caller(), 'Template::Document', "The goto &func trick" );

            isa_ok( $app, 'CGI::Builder' );
            isa_ok( $app, 'TestApp6' );

            is( $param, 'foobar', 'Parameter passed to sub' );

            return "subroutine";
        }
    );
    my $out = $app->capture( 'process' );
    like( $$out, qr/subroutine/, 'Anonymous sub in tt_vars w/make_wrapper' );

}

{
    sub TestApp7::DESTROY 
    {
        $Foo::_msg .= "Object destroyed\n";
    }
    
    package Foo;
    {
        $Foo::_msg = '';
        my $app = TestApp7->new( cgi => CGI->new({ p => 'testapp7' }));
        sub foo 
        {
            my $app = shift;

            Test::More::isa_ok( $app, 'CGI::Builder' );
            Test::More::isa_ok( $app, 'TestApp7' );
			return 'test7';
        }
        $app->tt_vars( test_sub => \&foo );
        my $out = $app->capture( 'process' );
    }

    package main;
    $Foo::_msg .= "This should be print after the DESTROY phase\n";
    like( $Foo::_msg, qr/destroyed.*after/s , 'Object destroyed correctly' );
}

{
    my $app = TestApp7->new( cgi => CGI->new({ p   => 'testapp8' ,
                                               foo => 'bar'
                                             } ));
    my $out = $app->capture( 'process' );
    like( $$out, qr/bar/, 'CBF object available in the template' );
}

#!/usr/bin/perl

use strict;
use warnings;
use File::Temp 'tempdir';

use Test::More tests => 4;

eval 'use App::HTTP_Proxy_IMP';
cmp_ok( $@,'eq','', 'loading App::HTTP_Proxy_IMP' );

# check, that the plugins we ship can be loaded
check_load('Example::changeTarget');

my $docroot = tempdir( CLEANUP => 1 );
check_load("FakeResponse=root=$docroot" );

# CSRFprotect needs additional modules, so first try to load it
SKIP: {
    skip "prerequisites missing for App::HTTP_Proxy_IMP::IMP::CSRFprotect",1
	if ! eval { require App::HTTP_Proxy_IMP::IMP::CSRFprotect };
    check_load('CSRFprotect');
}

sub check_load {
    my $mod = shift;
    eval {
	my $app = App::HTTP_Proxy_IMP->start({
	    impns => ['App::HTTP_Proxy_IMP::IMP'],
	    filter => [$mod],
	    addr => '127.0.0.1:0', # pick any port
	});
    };
    cmp_ok( $@,'eq','', "setting up proxy with $mod" );
}

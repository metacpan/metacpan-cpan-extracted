#!/usr/bin/env perl -w

use strict;
use Test::More;
use lib::abs '../lib';
BEGIN {
	my $w = 0;
	eval {require Test::NoWarnings;Test::NoWarnings->import; 1} and $w = 1;
	plan tests => 2+$w;
	use_ok( 'Catalyst::Action::Deserialize::XML::Hash::LX' );
	use_ok( 'Catalyst::Action::Serialize::XML::Hash::LX' );
};
diag( "Testing Catalyst::Action::Serialize::XML::Hash::LX $Catalyst::Action::Serialize::XML::Hash::LX::VERSION, Perl $], $^X" );

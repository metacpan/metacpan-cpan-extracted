#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Crypt::Random::Source::Weak::SSLeay';
use ok 'Crypt::Random::Source::Strong::SSLeay';

{
	my $p = Crypt::Random::Source::Weak::SSLeay->new;

	my $buf = $p->get(10);

	is( length($buf), 10, "got 10 bytes" );

	$p->seed( "bollocks" );

	is( length($buf), 10, "got 10 bytes" );

	ok( !$p->is_strong, "not strong" );
}

{
	my $p = Crypt::Random::Source::Strong::SSLeay->new;

	my $buf = $p->get(10);

	is( length($buf), 10, "got 10 bytes" );

	ok( $p->is_strong, "strong" );
}

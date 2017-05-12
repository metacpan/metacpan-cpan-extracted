#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan';
use Data::Dumper;

BEGIN {
	use_ok('Bio::BioVeL::Service');
}

@ARGV = ( '-foo' => 'bar' );
my $srv = Bio::BioVeL::Service->new( 'parameters' => [ 'foo' ] );
ok( $srv->foo eq 'bar' );

my $clone = Bio::BioVeL::Service->from_string($srv->to_string);
ok( $clone->foo eq $srv->foo );
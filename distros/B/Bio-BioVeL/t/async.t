#!/usr/bin/perl
use strict;
use warnings;
use File::Temp 'tempdir';
use Test::More 'no_plan';
use Scalar::Util 'looks_like_number';

BEGIN { use_ok('Bio::BioVeL::AsynchronousService::Mock') }

$ENV{'BIOVEL_HOME'} = tempdir( 'CLEANUP' => 1 );

# $TEMP/Bio/BioVeL/AsynchronousService/Mock
ok( -d Bio::BioVeL::AsynchronousService::Mock->workdir );

my $new = Bio::BioVeL::AsynchronousService::Mock->new( 'seconds' => 1 );
isa_ok( $new, 'Bio::BioVeL::AsynchronousService' );

ok( looks_like_number $new->timestamp );

ok( $new->status eq Bio::BioVeL::AsynchronousService::RUNNING );
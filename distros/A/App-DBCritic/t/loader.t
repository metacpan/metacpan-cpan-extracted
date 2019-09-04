#!/usr/bin/env perl

use Modern::Perl '2011';    ## no critic (Modules::ProhibitUseQuotedVersion)
use Test::Most tests => 1;
use Path::Class;
use FindBin;
use local::lib dir( $FindBin::Bin, 'schema' )->stringify();
use DBICx::TestDatabase;
use App::DBCritic;

my $schema = DBICx::TestDatabase->new('MySchema');
my $critic = new_ok( 'App::DBCritic' => [ schema => $schema ] );

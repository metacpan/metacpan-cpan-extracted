#!/usr/bin/env perl

use Modern::Perl '2011';    ## no critic (Modules::ProhibitUseQuotedVersion)
use Test::Most tests => 1;
use English '-no_match_vars';
use Path::Class;
use FindBin;
use local::lib dir( $FindBin::Bin, 'no_primary_key' )->stringify();
use DBICx::TestDatabase;
use App::DBCritic;

my $schema = DBICx::TestDatabase->new('MySchema');
my $critic = App::DBCritic->new( schema => $schema );
cmp_bag( [ map { $_->element->name } @{ $critic->violations } ],
    ['no_primary_key'] );

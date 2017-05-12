#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

require Catmandu::Importer::Solr;

my $solr_url = $ENV{T_SOLR_URL};
my $solr_bag = $ENV{T_SOLR_BAG} || "data";
my $solr_id_field = $ENV{T_SOLR_ID_FIELD} || "_id";
my $solr_bag_field = $ENV{T_SOLR_BAG_FIELD} || "_bag";

unless(defined($solr_url) && $solr_url ne ""){

    plan skip_all => "no environment variable T_SOLR_URL found";

}else{

    my $importer;

    lives_ok(sub {

        $importer = Catmandu::Importer::Solr->new( url => $solr_url, id_field => $solr_id_field, bag_field => $solr_bag_field, bag => $solr_bag );

    },"importer created");

    lives_ok(sub {

        my $c = $importer->count();

    },"importer count");

    done_testing 2;

}

#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Clean::FromJSON::Pregen qw(clean_from_json_in_place clone_and_clean_from_json);
use Scalar::Util qw(blessed);

unless (defined &Data::Clean::FromJSON::Pregen::clean_from_json_in_place) {
    plan skip_all => 'clean_from_json_in_place() not yet generated';
}

my $data;
my $cdata;

subtest clean_from_json_in_place => sub {
    my $cdata = clean_from_json_in_place([bless(do{\(my $o=0)},"JSON::PP::Boolean"), bless(do{\(my $o=1)},"JSON::PP::Boolean")]);
    is_deeply($cdata, [0, 1]);
};

done_testing;

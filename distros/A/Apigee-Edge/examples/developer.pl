#!/usr/bin/perl

use strict;
# use warnings;
use v5.10;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Apigee::Edge;
use Data::Dumper;

die "ENV APIGEE_ORG/APIGEE_USR/APIGEE_PWD is required." unless $ENV{APIGEE_ORG} and $ENV{APIGEE_USR} and $ENV{APIGEE_PWD};
my $apigee = Apigee::Edge->new(
    org => $ENV{APIGEE_ORG},
    usr => $ENV{APIGEE_USR},
    pwd => $ENV{APIGEE_PWD}
);

say "Create Developer...";
my $developer = $apigee->create_developer(
    "email" => 'fayland@binary.com',
    "firstName" => "Fayland",
    "lastName" => "Lam",
    "userName" => "fayland.binary",
    "attributes" => [
        {
            "name" => "Attr1",
            "value" => "V1"
        },
        {
            "name" => "A2",
            "value" => "V2.v2"
        }
    ]
) or die $apigee->errstr;
say Dumper(\$developer);

sleep 2;
say "Get Developer...";
my $developer = $apigee->get_developer('fayland@binary.com') or die $apigee->errstr;
say Dumper(\$developer);

sleep 1;
say "Get Developers...";
my $developers = $apigee->get_developers() or die $apigee->errstr;
say Dumper(\$developers);

sleep 1;
say "Delete Developer...";
my $developer = $apigee->delete_developer('fayland@binary.com') or die $apigee->errstr;
print Dumper(\$developer);

1;
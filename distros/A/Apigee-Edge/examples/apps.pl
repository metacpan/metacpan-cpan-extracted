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

say "Get Apps...";
my $apps = $apigee->get_apps(expand => 'true', includeCred => 'true');
say Dumper(\$apps);


1;
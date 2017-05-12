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

my $email = 'fayland@binary.com';

say "Create Apps...";
my $app = $apigee->create_developer_app(
    $email,
    {
        "name" => "Test App",
        # "apiProducts" => [ "{apiproduct1}", "{apiproduct2}" ],
        "keyExpiresIn" => "3600000",
        "attributes" => [
            {
                "name" => "DisplayName",
                "value" => "{display_name_value}"
            },
            {
                "name" => "Notes",
                "value" => "{notes_for_developer_app}"
            },
            {
                "name" => "{custom_attribute_name}",
                "value" => "{custom_attribute_value}"
            }
        ],
        # "callbackUrl" : "{url}",
    }
);
say Dumper(\$app);

say "Get Apps...";
my $apps = $apigee->get_developer_apps($email);
say Dumper(\$apps);


1;
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

# say "Create API Product...";
# my $product = $apigee->create_api_product(
#     "approvalType" => "manual",
#     "attributes" => [
#         {
#           "name" => "access",
#           "value" => "private"
#         },
#         {
#           "name" => "ATTR2",
#           "value" => "V2"
#         }
#     ],
#     "description" => "DESC",
#     "displayName" => "TEST PRODUCT NAME",
#     "name"  => "test-product-name",
#     "apiResources" => [ "/resource1", "/resource2"],
#     "environments" => [ "test", "prod"],
#     # "proxies" => ["{proxy1}", "{proxy2}", ...],
#     # "quota" => "{quota}",
#     # "quotaInterval" => "{quota_interval}",
#     # "quotaTimeUnit" => "{quota_unit}",
#     "scopes" => ["user", "repos"]
# );
# say Dumper(\$product);

# say "Get API Products...";
# my $products = $apigee->get_api_products(expand => 'true');
# say Dumper(\$products);

# say "Search API Products...";
# my $products = $apigee->search_api_products('attributename' => 'access', 'attributevalue' => 'public', expand => 'true');
# say Dumper(\$products);

# say "Update API Product...";
# my $product = $apigee->update_api_product(
#     "test-product-name",
#     {
#         "approvalType" => "auto",
#         "displayName" => "TEST PRODUCT NAME 4",
#     }
# );
# say Dumper(\$product);

# say "Get API Product...";
# my $product = $apigee->get_api_product("test-product-name");
# say Dumper(\$product);

say "Get API Product Apps...";
my $apps = $apigee->get_api_product_details(
    'test-product-name',
    query => 'list', entity => 'apps' # or query => 'count', entity => 'keys, apps, developers, or companies'
);
say Dumper(\$apps);

1;
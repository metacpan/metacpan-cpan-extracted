#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use CloudHealth::API;
use CloudHealth::API::Credentials;

my $ch = CloudHealth::API->new(
  credentials => CloudHealth::API::Credentials->new(api_key => 'stub')
);

my $classified_methods = {};
# See that all the methods in method_classification are effectively declared
# fill in classified_methods so we can later detect if there are methods in 
# the API that have not been classified
foreach my $kind (keys %{ $ch->method_classification }) {
  foreach my $method (@{ $ch->method_classification->{ $kind } }) {
    ok($ch->can($method), "Method $method is declared");
    $classified_methods->{ $method } = 1;
  }
}

# 
{
  no strict 'refs';
  # Get the subroutines in the CloudHealth::API package 
  # https://stackoverflow.com/questions/12504744/perl-list-subs-in-a-package-excluding-imported-subs-from-other-packages
  my @all_methods = grep { defined &{"CloudHealth::API\::$_"} } keys %{"CloudHealth::API\::"};
  my @api_methods = grep { $_ ne 'HasMethods' } grep { $_ =~ m/^[A-Z]/ } @all_methods;

  foreach my $method (sort @api_methods) {
    ok(defined($classified_methods->{ $method }), "Found $method in the classification");
  }
}

done_testing;

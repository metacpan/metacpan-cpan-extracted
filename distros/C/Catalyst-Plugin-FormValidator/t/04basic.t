#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use FindBin;
use lib "$FindBin::Bin/TestPDV/lib";
use HTTP::Request::Common;
BEGIN { use_ok 'Catalyst::Test', 'TestPDV' }

my $response = request GET "/form_test";
ok( $response->is_success, "got initial url" );

my $response2 = request POST '/form_test',
  Content_Type => 'form-data',
  Content      => [
    testinput => "test",
    press     => ""
  ];

like( $response2->content, qr/test/, "successful post is proper" );

my $response3 = request POST '/form_test',
  Content_Type => 'form-data',
  Content      => [
    testinput => "",
    press     => ""
  ];

like( $response3->content, qr//, "unsuccessful post is proper" );

done_testing;

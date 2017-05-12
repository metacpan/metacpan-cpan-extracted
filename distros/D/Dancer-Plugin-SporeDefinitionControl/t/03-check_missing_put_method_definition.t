#!perl

use FindBin;
BEGIN { $ENV{DANCER_APPDIR} = $FindBin::Bin }

use Test::More tests => 3, import => ["!pass"];

use Dancer;
use Dancer::Test;

BEGIN {
  set environment => 'test';
  set plugins => {
    SporeDefinitionControl => {
      spore_spec_path => "sample_route_no_put.yaml",
    },
  };
}

use t::lib::WebService;

my $params1  = { params => {name_object => 'test_result'} };
my $params2  = { params => {name_object => 'test_result', created_at => '2010-10-10'} };
my $params3  = { params => {name_object => 'test_result', created_at => '2010-10-10', test => 'test_result'} };

# check if GET method works
response_status_is ['GET' => '/object/12', $params1], 200, "GET method is OK";
# No PUT spore specification
response_status_is ['PUT' => '/object/12', $params1], 404, "PUT method is missing in spore specification";
response_content_is ['PUT' => '/object/12', $params1], '{"error":"no route define with method `PUT\'"}', "PUT method is missing in spore specification";


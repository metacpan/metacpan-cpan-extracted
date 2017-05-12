#!perl

use FindBin;
BEGIN { $ENV{DANCER_APPDIR} = $FindBin::Bin }

use Test::More tests => 36, import => ["!pass"];

use Dancer;
use Dancer::Test;

BEGIN {
  set environment => 'test';
  set plugins => {
    SporeDefinitionControl => {
      spore_spec_path => "sample_route.yaml",
    },
  };
}

use t::lib::WebService;

my $params1  = { params => {name_object => 'test_result'} };
my $params2  = { params => {name_object => 'test_result', created_at => '2010-10-10'} };
my $params3  = { params => {name_object => 'test_result', created_at => '2010-10-10', test => 'test_result'} };
my $params4  = { params => {name_object => 'test_result', params_sup => 1 } };
my $params5  = { params => {name_object => 'test_result', my_file =>  {filename => "test.png", name => "my_file" } } };

response_status_is ['GET' => '/object/12'], 400, "GET required param is missing";
response_content_is ['GET' => '/object/12'], '{"error":"required params `name_object\' is not defined"}', "GET required param is missing";
response_status_is ['GET' => '/object/12', $params1], 200, "GET only required params";
response_status_is ['GET' => '/object/12', $params2], 200, "GET required and optional params";
response_status_is ['GET' => '/object/12', $params3], 400, "GET unknown params";
response_content_is ['GET' => '/object/12', $params3], '{"error":"parameter `test\' is unknown"}', "GET param is unknown";
response_status_is ['GET' => '/nimportequoi/12', $params1], 404, "GET route pattern is not defined";
response_content_is ['GET' => '/nimportequoi/12', $params1], '{"error":"route pattern `/nimportequoi/:id\' is not defined"}', "GET required param is missing";

response_status_is ['POST' => '/object'], 400, "POST required param is missing";
response_content_is ['POST' => '/object'], '{"error":"required params `name_object\' is not defined"}', "GET required param is missing";
response_status_is ['POST' => '/object', $params1 ], 200, "POST required param is set";
response_status_is ['POST' => '/object', $params5 ], 400, "POST an unknown param is set : my_file";
response_status_is ['POST' => '/anotherobject', $params1 ], 200, "POST required param is set";
response_status_is ['POST' => '/anotherobject', $params5 ], 200, "POST required param is set";

response_status_is ['POST' => '/object', $params2 ], 200, "POST required and optional params";
response_status_is ['POST' => '/object', $params4 ], 200, "POST required and optional params in path";
response_status_is ['POST' => '/object', $params3], 400, "POST unknown params";
response_content_is ['POST' => '/object', $params3], '{"error":"parameter `test\' is unknown"}', "POST param is unknown";
response_status_is ['POST' => '/nimportequoi', $params1], 404, "POST route pattern is not defined";
response_content_is ['POST' => '/nimportequoi', $params1], '{"error":"route pattern `/nimportequoi\' is not defined"}', "POST route is not defined";

response_status_is ['PUT' => '/object/12'], 400, "PUT required param is missing";
response_content_is ['PUT' => '/object/12'], '{"error":"required params `name_object\' is not defined"}', "PUT required param is missing";
response_status_is ['PUT' => '/object/12', $params1], 200, "PUT only required params";
response_status_is ['PUT' => '/object/12', $params2], 200, "PUT required and optional params";
response_status_is ['PUT' => '/object/12', $params3], 400, "PUT unknown params";
response_content_is ['PUT' => '/object/12', $params3], '{"error":"parameter `test\' is unknown"}', "PUT param is unknown";
response_status_is ['PUT' => '/nimportequoi/12', $params1], 404, "PUT route pattern is not defined";
response_content_is ['PUT' => '/nimportequoi/12', $params1], '{"error":"route pattern `/nimportequoi/:id\' is not defined"}', "PUT required param is missing";

response_status_is ['DELETE' => '/object/12'], 400, "DELETE required param is missing";
response_content_is ['DELETE' => '/object/12'], '{"error":"required params `name_object\' is not defined"}', "DELETE required param is missing";
response_status_is ['DELETE' => '/object/12', $params1], 200, "DELETE only required params";
response_status_is ['DELETE' => '/object/12', $params2], 200, "DELETE required and optional params";
response_status_is ['DELETE' => '/object/12', $params3], 400, "DELETE unknown params";
response_content_is ['DELETE' => '/object/12', $params3], '{"error":"parameter `test\' is unknown"}', "DELETE param is unknown";
response_status_is ['DELETE' => '/nimportequoi/12', $params1], 404, "DELETE route pattern is not defined";
response_content_is ['DELETE' => '/nimportequoi/12', $params1], '{"error":"route pattern `/nimportequoi/:id\' is not defined"}', "DELETE required param is missing";

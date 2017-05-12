#!perl

use Test::More tests => 12, import => ["!pass"];

use Dancer;
use Dancer::Test;

BEGIN {
  set environment => 'test';
  set plugins => {
    "Fake::Response" => 
    {
      GET => {
        "/rewrite_fake_route/:id.:format" =>
        {
          response =>
            {
              id => 1,
              asked_id => ':id',
              fake_params => ':fake',
              test => "get test"
            },
        }
      },
      PUT => {
        "/rewrite_fake_route/:id.:format" =>
        {
          response =>
            {
              id => 2,
              asked_id => ':id',
              fake_params => ':fake',
              test => "put test"
            },
        }
      },
      POST => {
        "/rewrite_fake_route/:format" =>
        {
          response =>
            {
              id => 3,
              asked_id => ':format',
              fake_params => ':fake',
              test => "post test"
            },
        }
      },
      DELETE => {
        "/rewrite_fake_route/:id.:format" =>
        {
          response =>
            {
              id => 4,
              asked_id => ':id',
              fake_params => ':fake',
              test => "delete test"
            },
        }
      },
    },
  };
}

use t::lib::WebService;

response_status_is ['GET' => '/object/12.json'], 200, "GET object/:id.:format match";
response_status_is ['GET' => '/rewrite_fake_route/12.json'], 200, "GET /rewrite_fake_route/:id.:format return code 200";
response_content_is ['GET' => '/rewrite_fake_route/12.json'], '{"test":"get test","asked_id":"12","fake_params":":fake","id":"1"}', "/rewrite_fake_route/:id.:format return data configured in plugin setting";

response_status_is ['PUT' => '/object/12.json'], 200, "PUT object/:id.:format match";
response_status_is ['PUT' => '/rewrite_fake_route/12.json'], 202, "PUT /rewrite_fake_route/:id.:format return code 202";
response_content_is ['PUT' => '/rewrite_fake_route/12.json'], '{"test":"put test","asked_id":"12","fake_params":":fake","id":"2"}', "/rewrite_fake_route/:id.:format return data configured in plugin setting";

response_status_is ['POST' => '/object/12.json'], 200, "POST object/:id.:format match";
response_status_is ['POST' => '/rewrite_fake_route/json'], 201, "POST /rewrite_fake_route/:id.:format return code 201";
response_content_is ['POST' => '/rewrite_fake_route/json'], '{"test":"post test","asked_id":"json","fake_params":":fake","id":"3"}', "/rewrite_fake_route/:id.:format return data configured in plugin setting";

response_status_is ['DELETE' => '/object/12.json'], 200, "DELETE object/:id.:format match";
response_status_is ['DELETE' => '/rewrite_fake_route/12.json'], 202, "DELETE /rewrite_fake_route/:id.:format return code 202";
response_content_is ['DELETE' => '/rewrite_fake_route/12.json'], '{"test":"delete test","asked_id":"12","fake_params":":fake","id":"4"}', "/rewrite_fake_route/:id.:format return data configured in plugin setting";


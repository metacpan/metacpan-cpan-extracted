#!/usr/bin/env perl
use strict;
use Dancer;

set serializer => 'JSON';

post '/api/station' => sub {
  return {
    settings => {
      nickname => "controller_test",
      room => "control_room",
      record_path => "/tmp/control",
      run => "1",
    },
  };
};

post '/api/station/:macaddress' => sub {
  status 201;
};

get '/internal/settings' => sub {
  return {
    config => {
      nickname => "internal_test",
      room => "internal_room",
      record_path => "/tmp/internal",
      run => "2",
    },
  };
};

# These are just dummy routes for future testing.
post '/api/station/:macaddress/partial' => sub {
  return request->body;
};

post '/internal/settings' => sub {
};

dance;


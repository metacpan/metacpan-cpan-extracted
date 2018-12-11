#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use CloudHealth::API;
use CloudHealth::API::ResultParser;
use CloudHealth::API::HTTPResponse;

my $res_processor = CloudHealth::API::ResultParser->new;

{
  my $res = $res_processor->result2return(
    CloudHealth::API::HTTPResponse->new(
      status => 200,
      content => '{}'
    )
  );

  ok(ref($res) eq 'HASH');
}

{
  my $res = $res_processor->result2return(
    CloudHealth::API::HTTPResponse->new(
      status => 204,
    )
  );

  ok($res, 'An 204 HTTP response doesn\'t die');
}

{
  throws_ok(sub{
    $res_processor->result2return(
      CloudHealth::API::HTTPResponse->new(
        status => 200,
        content => '{"malformed_json":}'
      )
    );
  }, 'CloudHealth::API::Error');
  cmp_ok($@->type, 'eq', 'UnparseableResponse');
  like($@->message, qr|Can't parse response|);
  like($@->message, qr|malformed JSON string|);
}

{
  throws_ok(sub{
    $res_processor->result2return(
      CloudHealth::API::HTTPResponse->new(
        status => 401,
        content => '{"error":"You need to sign in or sign up before continuing"}'
      )
    );
  }, 'CloudHealth::API::RemoteError');
  cmp_ok($@->type, 'eq', 'Remote');
  cmp_ok($@->message, 'eq', 'You need to sign in or sign up before continuing');
}

{
  throws_ok(sub{
    $res_processor->result2return(
      CloudHealth::API::HTTPResponse->new(
        status => 401,
        content => '{"error":"You need to sign in or sign up before continuing"}'
      )
    );
  }, 'CloudHealth::API::RemoteError');
  cmp_ok($@->type, 'eq', 'Remote');
  cmp_ok($@->message, 'eq', 'You need to sign in or sign up before continuing');
}


{
  throws_ok(sub{
    $res_processor->result2return(
      CloudHealth::API::HTTPResponse->new(
        status => 403,
        content => '{}'
      )
    );
  }, 'CloudHealth::API::RemoteError');
  cmp_ok($@->type, 'eq', 'Remote');
  cmp_ok($@->message, 'eq', 'No message');
}

{
  throws_ok(sub{
    $res_processor->result2return(
      CloudHealth::API::HTTPResponse->new(
        status => 422,
        content => '{"errors":["Name can\'t be blank"," access key can\'t be blank"," secret key can\'t be blank"]}'
      )
    );
  }, 'CloudHealth::API::RemoteError');
  cmp_ok($@->type, 'eq', 'Remote');
  like($@->message, qr|Name can't be blank|);
  like($@->message, qr|access key can't be blank|);
  like($@->message, qr|secret key can't be blank|);
}



done_testing;

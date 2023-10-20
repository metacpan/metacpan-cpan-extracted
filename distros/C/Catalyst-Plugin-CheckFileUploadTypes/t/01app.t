#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use HTTP::Request::Common;
use HTTP::Status;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'TestApp';


ok( request('/')->is_success, 'Request with no uploads is fine' );


my $image_filename = 't/data/implementation.png';
my $text_filename = 't/data/test.txt';

# Upload of a file to an action that expects uploads but doesn't care what types
my ($res, $c) = ctx_request(
    POST '/expect_any', [
        upload1 => [
            $image_filename,
            "not_really_a_text_file.jpg",
            'Content-Type' => 'text/fake',
        ],
    ]
);

is($res->code, RC_OK, 'Uploaded image to route that expects any old uploads');
is($res->content, 'Hit expect_any', 'Expected response from action');


# Upload of an expected type is fine
($res, $c) = ctx_request(
    POST '/expect_image',
        Content_Type => 'form-data',
        Content      => [
            upload1 => [
                $image_filename,
                "not_really_a_text_file.jpg",  # extension intentionally fake
                'Content-Type' => 'text/fake', # Faked content type
            ],
        ]
);

is($res->code, RC_OK, 'Accepted image to route that expects image/png');
is($res->content, 'Hit expect_image', 'Expected response from action');

# Upload of unexpected type rejected
($res, $c) = ctx_request(
    POST '/expect_image',
        Content_Type => 'form-data',
        Content      => [
            upload1 => [
                $text_filename,
                "pretty-picture.png",  # extension intentionally fake
                #'Content-Type' => 'image/png', # Faked content type
            ],
        ]
);

is($res->code, RC_BAD_REQUEST, 'Rejected plain text upload to route that expects image/png');
is(
    $res->content,
    'Unsupported file content type uploaded',
    'Got rejection error message',
);


# Multiple uploads - one of an expected type, one of an unexpected type
($res, $c) = ctx_request(
    POST '/expect_image',
        Content_Type => 'form-data',
        Content      => [
            upload1 => [
                $image_filename,
                "pretty-picture.png",  # extension intentionally fake
            ],
            # This upload pretends to be an image, but is a text file
            upload2 => [
                $text_filename,
                "pretty-picture-honestly-guv.png", # extension fake
                'Content-Type' => 'image/png',     # Faked content type
            ],
        ]
);


is(
    $res->code,
    RC_BAD_REQUEST,
    'Two uploads, one expected type and one not',
);
is(
    $res->content,
    'Unsupported file content type uploaded',
    'Correct error message for action which does not expect uploads',
);



# Upload to an action which doesn't expect uploads at all is rejected
($res, $c) = ctx_request(
    POST '/',
        Content_Type => 'form-data',
        Content      => [
            upload1 => [
                $text_filename,
                "pretty-picture.png",  # extension intentionally fake
                #'Content-Type' => 'image/png', # Faked content type
            ],
        ]
);


is(
    $res->code,
    RC_BAD_REQUEST,
    'Rejected upload to action that does not expect uploads',
);
is(
    $res->content,
    'File upload not expected',
    'Correct error message for action which does not expect uploads',
);


done_testing();

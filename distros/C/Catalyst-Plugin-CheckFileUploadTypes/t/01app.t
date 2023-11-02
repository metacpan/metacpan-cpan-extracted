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
my $xml_filename = 't/data/test.xml';
my $script_filename = 't/data/shell.sh';
my $notscript_filename = 't/data/notshell.txt';

# Upload of a file to an action that expects uploads but doesn't care what types
my ($res, $c) = ctx_request(
    POST '/expect_any',
        Content_Type => 'form-data',
        Content      => [
            upload1 => [
                $image_filename,
                "not_really_a_text_file.jpg",
                'Content-Type' => 'text/fake',
            ],
        ],
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


# Uploading our XML file to action which expects text/plain - without
# extra heuristics, File::MMagic would treat an XML file as text/plain,
# so here we're testing that the extra checks we add actually work and that
# we realise it's actually an XML file and thus refuse it
($res, $c) = ctx_request(
    POST '/expect_text',
        Content_Type => 'form-data',
        Content      => [
            upload1 => [
                $xml_filename,
                "a-text-file-but-really-xml.txt",
                'Content-Type' => 'text/plain', # Filthy lies
            ],
        ],
);

is($res->code, RC_BAD_REQUEST, 'Rejected XML upload to route that expects text/plain');
is(
    $res->content,
    'Unsupported file content type uploaded',
    'Got rejection error message',
);



# Similarly, upload our shell script to action which expects text/plain and
# make sure we detect it as a shell script and reject it
($res, $c) = ctx_request(
    POST '/expect_text',
        Content_Type => 'form-data',
        Content      => [
            upload1 => [
                $script_filename,
                "this-could-be-evil.sh",
                'Content-Type' => 'text/plain', # Filthy lies
            ],
        ],
);

is($res->code, RC_BAD_REQUEST, 'Rejected shell script upload to route that expects text/plain');
is(
    $res->content,
    'Unsupported file content type uploaded',
    'Got rejection error message for shell script',
);


# Ensure we don't fall victim to Scunthorpe Syndrome from our custom patterns
# though - upload a plain text file which contains an example of a shell script
# (with shebang) in the middle - this should *not* be treated as a shell
# script...
($res, $c) = ctx_request(
    POST '/expect_text',
        Content_Type => 'form-data',
        Content      => [
            upload1 => [
                $notscript_filename,
                "script-writing-for-dummies.txt",
                'Content-Type' => 'text/plain', # Truthful
            ],
        ],
);
is($res->code, RC_OK, 'Accepted text file with shebang in middle');
is(
    $res->content, 
    'Hit expect_text',
    "Expected response from action for $notscript_filename",
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

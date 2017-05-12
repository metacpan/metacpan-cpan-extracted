#!/usr/bin/perl -w -I../../../lib

use strict;
use warnings;

use lib 'lib';
use Test::More (tests => 14);
use Test::NoWarnings;
use Test::Exception;
use Command::Interactive;

my $default = Command::Interactive::Interaction->new({expected_string => 'foo',});

is($default->expected_string,            'foo',    'Expected string is copied correctly');
is($default->response,                   undef,    'Default response is undef');
is($default->expected_string_is_regex,   0,        'Default behavior is string match rather than regex');
is($default->send_newline_with_response, 1,        'Default behavior is to send newline with response');
is($default->is_error,                   0,        'By default interactions are not considered errors');
is($default->is_required,                0,        'By default interactions are not required');
is($default->max_allowed_occurrences,    1,        'By default each interaction is allowed only once');
is($default->type,                       'string', "By default interactions are typed as 'string'");
is($default->actual_response_to_send,    undef,    'If response is undef, actual_response_to_send should be too');

$default->response('bar');
is($default->actual_response_to_send, "bar\n", "By default responses include newlines");

throws_ok(
    sub { Command::Interactive::Interaction->new; },
    qr/Attribute \(expected_string\) is required/,
    "Cannot be created without an expected_string argument",
);

my $wopr = Command::Interactive::Interaction->new({
        expected_string            => 'Would you like to play a (game|match)\?',
        expected_string_is_regex   => 1,
        response                   => 'yes',
        send_newline_with_response => 0,
});

is($wopr->type,                    'regex', 'Correct type for expected_string_is_regex');
is($wopr->actual_response_to_send, "yes",   "Responses don't include newlines if requested");

1;

#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Class::ConfigHash;

# If you're thinking "Hey, you just copy-pasted this from the SYNOPSIS", then
# you are RIGHT! Award yourself one gold sticker.

my $config = Class::ConfigHash->_new({
    database => {
        user => 'rodion',
        pass => 'bonaparte',
        options => {
            city => 'St Petersburg'
        },
    },
});

is( $config->database->options->city, "St Petersburg", "Normal lookup working");

throws_ok( sub { $config->database->flags },
	qr!Can't find 'flags' at \[/->database\]. Options: \[options; pass; user\].*!,
	"Throws with not-found value"
);

is( $config->database->flags({ allow_undef => 1 }), undef,
	"allow_undef works" );


is( $config->database->flags({ default => 'foo' }), 'foo',
	"default works" );

$config->database({ raw => 1 })->{'user'} = 'raskolnikov';
is( $config->database->user, 'raskolnikov',
	"raw works"
);

done_testing();
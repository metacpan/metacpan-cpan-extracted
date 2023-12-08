package Test::Credentials;

use strict;
use warnings;

use Moose;

use FindBin qw/ $Bin /;
use File::Slurper qw/ read_text /;
use JSON qw/ decode_json /;

sub TO_JSON {

    return decode_json(
        read_text( $ENV{TRUELAYER_CREDENTIALS} )
    );
}

1;

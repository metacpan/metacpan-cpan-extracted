use strict;
use warnings;
use Test::More;

use Config::INI::Reader::Multiline;

plan tests => 2;

{
    my $input = 'bloop bap bang_eth';
    eval { Config::INI::Reader::Multiline->read_string($input); };
    like( $@, qr/Syntax error at line 1: '$input'/i, 'syntax error' );
}

{
    my @input = ( "[ flrbbbbb\\", ' thunk]', "whap = z_zwap   glipp" );
    eval { Config::INI::Reader::Multiline->read_string( join "\n", @input ); };
    like( $@, qr/Syntax error at line 2: '$input[1]\n'/i, 'syntax error' );
}

#!/usr/bin/perl
use strict;
use warnings;
use diagnostics;
use Test::More tests => 8;

use Config::Strict;

# No params
eval { Config::Strict->new( {} ) };
like( $@ => qr/'params' key/, _error( $@ ) );

# Bad key
eval { Config::Strict->new( { meh => 1 } ); };
like( $@ => qr/key/, 'bad key' );

# Bad param hash
eval { Config::Strict->new( { params => { Bool => { 'b1' => 'b2' } } } ); };
like( $@ => qr/Not a valid parameter ref/, _error( $@ ) );
eval { Config::Strict->new( { params => { Enum => [ 'e' ] } } ); };
like( $@ => qr/Not a HashRef/, _error( $@ ) );

# Bad required
eval {
    Config::Strict->new( { params => { Bool => 'b' }, required => [ 'B' ] } );
};
like( $@ => qr/Required parameter 'B'/, _error( $@ ) );

# Missing required params
eval {
    Config::Strict->new( {
            params   => { Bool => 'b1' },
            required => [ 'b1' ],
        }
    );
};
like( $@ => qr/b1 is a required parameter/, _error( $@ ) );
eval {
    Config::Strict->new( {
            params   => { Bool => [ qw( b1 b2 ) ] },
            required => '*',
            defaults => { b1   => 1 },
        }
    );
};
like( $@ => qr/b2 is a required parameter/, _error( $@ ) );

# Invalid default value
eval {
    Config::Strict->new( {
            params   => { Bool => 'b1' },
            required => [ 'b1' ],
            defaults => { b1   => 2 },
        }
    );
};
like( $@ => qr/no value matches/i, _error( $@ ) );

# Anon subs
#eval {
#    Config::Strict->new( {
#            params => {
#                Anon => {
#                    s => sub { $_[ 0 ] == 1 }
#                },
#            }
#        }
#    )
#};
#like(
#    $@ => qr/must be a Declare::/i,
#    _error( $@ )
#);



sub _error {
    local $_ = shift;
    s/\s+at.+$//sg;
    s/\W+\$VAR.+$//sg;
    'error: ' . $_;
}

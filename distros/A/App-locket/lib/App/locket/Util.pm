package App::locket::Util;

use strict;
use warnings;

use vars qw/ %COPY %PASTE /;

%COPY = (
    'pbcopy' => sub {
        my ( $locket, $prgm, $value ) = @_;
        $locket->_pipe_into( $prgm => $value );
    },

    'xsel' => sub {
        my ( $locket, $prgm, $value ) = @_;
        $locket->_pipe_into( $prgm => $value );
    },

    'xclip' => sub {
        my ( $locket, $prgm, $value ) = @_;
        $locket->_pipe_into( "$prgm -i" => $value );
    },
);

%PASTE = (
    'pbpaste' => sub {
        my ( $locket, $prgm ) = @_;
        return $locket->_pipe_outfrom( $prgm );
    },

    'xsel' => sub {
        my ( $locket, $prgm ) = @_;
        return $locket->_pipe_outfrom( $prgm );
    },

    'xclip' => sub {
        my ( $locket, $prgm ) = @_;
        return $locket->_pipe_outfrom( "$prgm -o" );
    },
);


1;

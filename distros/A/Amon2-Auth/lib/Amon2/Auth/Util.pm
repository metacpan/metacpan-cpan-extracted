use strict;
use warnings;
use utf8;

package Amon2::Auth::Util;
use parent qw(Exporter);

our @EXPORT_OK = qw(parse_content);

# taken from OAuth::Lite2::Util
use Hash::MultiValue;
use URI::Escape qw(uri_unescape);
sub parse_content {
    my $content = shift;
    my $params  = Hash::MultiValue->new;
    for my $pair ( split /\&/, $content ) {
        my ( $key, $value ) = split /\=/, $pair;
        $key   = uri_unescape( $key   || '' );
        $value = uri_unescape( $value || '' );
        $params->add( $key, $value );
    }
    return $params;
}

1;

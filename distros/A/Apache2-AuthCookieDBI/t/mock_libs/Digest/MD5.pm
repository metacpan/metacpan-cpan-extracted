package Digest::MD5;
use strict;
use warnings;

require Exporter;
*import = \&Exporter::import;
our @EXPORT_OK = qw( md5_hex );

sub md5_hex {
    my $string = shift;
    return '0123456789abcdef' x 2;
    return $string;
}

1;
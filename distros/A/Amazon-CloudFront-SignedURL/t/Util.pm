package t::Util;
use strict;
use warnings;
use utf8;
use Exporter 'import';

our @EXPORT = qw/slurp/;

sub slurp {
    my $filename = shift;
    open my $fh, '<', $filename or die "$filename: $!";
    do { local $/; <$fh> };
}

1;


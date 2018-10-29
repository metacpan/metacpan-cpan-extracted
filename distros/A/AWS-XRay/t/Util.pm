package t::Util;

use strict;
use warnings;

use IO::Scalar;
use JSON::XS;
use Exporter 'import';
our @EXPORT_OK = qw/ reset segments /;

my $buf;
no warnings 'redefine';

*AWS::XRay::sock = sub {
    IO::Scalar->new(\$buf);
};
1;

sub reset {
    undef $buf;
}

sub segments {
    return unless $buf;
    $buf =~ s/{"format":"json","version":1}//g;
    my @seg = split /\n/, $buf;
    shift @seg; # despose first ""
    return map { decode_json($_) } @seg;
}

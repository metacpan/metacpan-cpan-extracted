#!/usr/bin/perl

use 5.014;

use strict;
use warnings;

use File::Spec;
use Test::More tests => 2;

sub _slurp
{
    my $filename = shift;

    open my $in, '<', $filename
        or die "Cannot open '$filename' for slurping - $!";

    local $/;
    my $contents = <$in>;

    close($in);

    return $contents;
}

{
    my $fn = File::Spec->catfile(
        File::Spec->curdir(), "lib", "App", "Timestamper.pm"
    );

    my $contents = _slurp($fn);

    # TEST
    like ($contents, qr/^=head1 COMMON REQUESTS$/ms,
        "Common requests is found.");

    # TEST
    like ($contents, qr/pony/i,
        "Pony was found.");
}


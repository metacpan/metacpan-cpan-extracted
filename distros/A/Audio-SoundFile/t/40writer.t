#!/usr/bin/perl -Iblib/arch -Iblib/lib
# -*- mode: perl -*-
#
# $Id: 40writer.t,v 1.2 2001/01/07 04:08:13 tai Exp $
#

use Test;

use IO::Seekable;
use Audio::SoundFile;

$DEBUG = 0;

BEGIN { plan tests => 18 };

print STDERR "PWD: ", `pwd` if $DEBUG;

ok(1);

##
ok($reader = new Audio::SoundFile::Reader("tmp/tt0.au", \$header));
ok($header);
ok($writer = new Audio::SoundFile::Writer("tmp/foo.au",  $header));
while ($reader->bread_raw(\$buffer, 1024) > 0) {
    $writer->bwrite_raw($buffer);
}
ok($reader->close == 0);
ok($writer->close == 0);

##
ok($reader = new Audio::SoundFile::Reader("tmp/foo.au", \$header));
ok($header);
ok($writer = new Audio::SoundFile::Writer("tmp/bar.au",  $header));
while ($reader->bread_raw(\$buffer, 1024) > 0) {
    $writer->bwrite_raw($buffer);
}
ok($reader->close == 0);
ok($writer->close == 0);

##
ok(&compare("tmp/foo.au", "tmp/bar.au"));

##
ok($reader = new Audio::SoundFile::Reader("tmp/foo.au", \$header));
ok($header);
ok($writer = new Audio::SoundFile::Writer("tmp/bar.au",  $header));
while ($reader->bread_pdl(\$buffer, 1024) > 0) {
    $writer->bwrite_pdl($buffer);
}
ok($reader->close == 0);
ok($writer->close == 0);

##
ok(&compare("tmp/foo.au", "tmp/bar.au"));

exit(0);

sub compare {
    my $anam = shift;
    my $bnam = shift;
    my $abuf;
    my $bbuf;

    local(*A, *B);

    open(A, $anam) || return 0;
    open(B, $anam) || return 0;

    while (1) {
        my $alen = read(A, $abuf, 1);
        my $blen = read(B, $bbuf, 1);

        return 0 if $alen != $blen;
        last     if $alen <= 0;
    }

    close(A);
    close(B);

    return 1;
}

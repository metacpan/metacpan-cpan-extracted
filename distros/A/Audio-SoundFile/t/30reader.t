#!/usr/bin/perl -Iblib/arch -Iblib/lib
# -*- mode: perl -*-
#
# $Id: 30reader.t,v 1.2 2001/01/07 04:08:55 tai Exp $
#

use Test;

use IO::Seekable;
use Audio::SoundFile;

$DEBUG = 0;

BEGIN { plan tests => 28 };

print STDERR "PWD: ", `pwd` if $DEBUG;

ok(1);

foreach (qw(tmp/tt0.au tmp/tt0.wav tmp/tt0.aiff)) {
    &testfile($_);
}

exit(0);

sub testfile {
    my $file = shift;

    ok($reader = new Audio::SoundFile::Reader($file, \$header)) or die $@;
    ok($header);

    while (my($k, $v) = each %{$header}) {
        print STDERR "$k: $v\n" if $DEBUG;
    }

    ok($reader->fseek( 0, SEEK_SET) ==  0);
    ok($reader->fseek(10, SEEK_SET) == 10);

    ## seek-and-bread_raw
    ok($reader->fseek(0, SEEK_SET) == 0);
    for ($pass = 0; $length = $reader->bread_raw(\$buffer, 1024); $pass = 1) {
        print STDERR $buffer if $DEBUG;
    }
    ok($pass);

    ## seek-and-bread_pdl
    ok($reader->fseek(0, SEEK_SET) == 0);
    for ($pass = 0; $length = $reader->bread_pdl(\$buffer, 1024); $pass = 1) {
        print STDERR $buffer if $DEBUG;
    }
    ok($pass);

    ## seek-and-fread_raw
    #ok($reader->fseek(0, SEEK_SET) == 0);
    #for ($pass = 0; $length = $reader->fread_raw(\$buffer, 1024); $pass = 1) {
    #    print STDERR $buffer if $DEBUG;
    #}
    #ok($pass);

    ## seek-and-fread_pdl
    #ok($reader->fseek(0, SEEK_SET) == 0);
    #for ($pass = 0; $length = $reader->fread_pdl(\$buffer, 1024); $pass = 1) {
    #    print STDERR $buffer if $DEBUG;
    #}
    #ok($pass);

    ok($reader->close == 0);
}

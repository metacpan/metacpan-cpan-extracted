#!/usr/bin/perl -Iblib/arch -Iblib/lib
# -*- mode: perl -*-
#
# $Id: 20header.t,v 1.1 2001/01/06 18:39:17 tai Exp $
#

use Test;

use Audio::SoundFile;
use Audio::SoundFile::Header;

$DEBUG = 0;

BEGIN { plan tests => 7 };

print STDERR "PWD: ", `pwd` if $DEBUG;

ok(1);

$format = {
    samplerate  => 44100,
    channels    => 2,
    format      => SF_FORMAT_WAV | SF_FORMAT_PCM_16,
};

ok($header = new Audio::SoundFile::Header(%{$format})) or die $@;
ok($header->format_check);
ok($header->get("channels") == 2);

while (my($k, $v) = each %{$header}) {
    print STDERR "$k: $v\n" if $DEBUG;
}

ok($header->set("channels"  => 1, "samplerate" => 44100));
ok($header->get("channels") == 1);
ok($header->format_check);

while (my($k, $v) = each %{$header}) {
    print STDERR "$k: $v\n" if $DEBUG;
}

exit(0);

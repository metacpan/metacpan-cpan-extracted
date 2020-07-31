#!/usr/bin/perl -T
# Yes, we want the -T above there to make sure things work in taint mode.

use v5.22;

#
# Copyright (C) 2015 Joelle Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;
use autodie;

use Carp;

use Acme::Unicodify;
use Encode qw(encode);
use File::Temp qw{tempdir};
use File::Slurper qw(read_text write_text);
use Test::More tests => 10;

binmode( STDOUT, ':encoding(UTF-8)' );

my $dir = tempdir( CLEANUP => 1 );
ok( defined $dir, 'Temp directory created' );

my $unify = Acme::Unicodify->new();
ok( defined $unify, 'Can create object' );

is(
    $unify->back_to_ascii('AaaaBbbbCcccDdddEeee\n A'),
    'AaaaBbbbCcccDdddEeee\n A',
    'No change when converting ASCII to ASCII'
);

isnt(
    $unify->to_unicode('AaaaBbbbCcccDdddEeee\n A'),
    'AaaaBbbbCcccDdddEeee\n A',
    'String changes when ASCII letters passed to to_unicode'
);

is(
    $unify->back_to_ascii($unify->to_unicode( 'AaaaBbbbCcccDdddEeee\n A' )),
    'AaaaBbbbCcccDdddEeee\n A',
    'Conversion to/from Unicode is lossless'
);

is(
    $unify->to_unicode(undef),
    undef,
    'to_unicode() handles undef'
);

is(
    $unify->back_to_ascii(undef),
    undef,
    'back_to_ascii() handles undef'
);

my $text = <<'END_FILE';
This is a test.  I want to throw in a bogus Unicode character just to validate that it is preserved.
This is line 2
This is a camel: \x{1F42A}
It should stay a camel.
END_FILE

$text = "
This is a test.  I want to throw in a bogus Unicode character just to validate that it is preserved.
This is line 2
This is a camel: \x{1F42A}
It should stay a camel.";

write_text($dir . '/infile.txt', $text);
$unify->file_to_unicode($dir . '/infile.txt', $dir . '/unifile.txt');
my $textin = read_text($dir . '/infile.txt');
my $text1 = read_text($dir . '/unifile.txt');

isnt($text, $text1, 'Unicoded file does not match non-unicoded file');
is(
    scalar(split /\b{gcb}/, $text1),
    scalar(split /\b{gcb}/, $textin),
    'File length is unchanged'
);

$unify->file_back_to_ascii($dir . '/unifile.txt', $dir . '/output.txt');
my $text2 = read_text($dir . '/output.txt');

is($text2, $text, 'Text files are lossless-ly processed');


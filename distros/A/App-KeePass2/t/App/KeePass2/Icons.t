#!perl
#
# This file is part of App-KeePass2
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;
use utf8::all;
use Test::More;
use App::KeePass2;

my @tests
    = qw( key internet warning network note talk cube note2 internet2 card note3 camera wifi key2 wire scan internet3 disk computer email setting note4 server screen wire2 email2 disk2 network2 video key3 terminal printer cube2 cube3 key4 network3 zip pourcentage smb time search dress memory bin sticker forbid help pack folder folder2 zip2 unlock lock valid ink picture note5 card2 key5 tools home star linux ink2 apple word dollar card3 phone );

my $kp2 = App::KeePass2->new( file => "test" );

my $idx = 0;
for my $t (@tests) {
    my $id   = $kp2->get_icon_id_from_key($t);
    my $char = $kp2->get_icon_char_from_key($t);
    my $key  = $kp2->get_icon_key_from_id($idx);
    ok $char, "the $t char ( $char  ) is defined";
    is $id,   $idx, "... and " . $char . "  has the id $id";
    is $t,    $key, "... and the id $idx correspond to $char";

    $idx++;
}

done_testing;

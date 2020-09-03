#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2020 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 24-digest.t 294 2020-09-02 06:36:52Z minus $
#
#########################################################################
use strict;
use warnings;
use Test::More tests => 5;

use CTK::Digest::M11R;
use CTK::Digest::FNV32a;

# Test M11R class
{
    my $m11r = CTK::Digest::M11R->new();
    $m11r->add("123456789"); # 5
    #$empty->addfile("t.txt");

    #print ">", $m11r->digest, "<\n";
    is($m11r->digest, 5, "M11R Check Digit for 123456789 is 5");
}

# Test FNV32a class
{
    my $fnv32a = CTK::Digest::FNV32a->new();
    $fnv32a->add("123456789");
    is($fnv32a->digest, 0xbb86b11c, "FNV32a for 123456789 is 3146166556");
    is($fnv32a->hexdigest, 'bb86b11c', "FNV32a (hex) for 123456789 is 0xbb86b11c");

    $fnv32a->reset->add("abc123");
    is($fnv32a->digest, 951228933, "FNV32a for abc123 is 951228933");

    $fnv32a->reset->add("http://www.google.com/");
    is($fnv32a->digest, 912201313, "FNV32a for http://www.google.com/ is 912201313");
}


1;

__END__

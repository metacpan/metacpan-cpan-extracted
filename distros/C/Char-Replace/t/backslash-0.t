#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Char::Replace;

test("abcd");
test("abcd\txyz");

# hit the first growth
my $str = "VWXYZ\t<----------------------------------------------------------------------------";    # > 64
test($str);

# hit the second growth
$str .= "x" x 128;                                                                                   # > 128
test($str);

sub test {
    my ($str) = @_;
    my $v1 = $str;
    $v1 =~ tr|\t|\0|;

    my $M1 = Char::Replace::identity_map();
    $M1->[ ord("\t") ] = "\0";
    my $v2 = Char::Replace::replace( $str, $M1 );

    is $v2, $v1, "string match" or do {
        require Devel::Peek;
        note "Expect: ";
        Devel::Peek::Dump($v1);
        note "Got: ";
        Devel::Peek::Dump($v2);
    };

    return;
}

done_testing;

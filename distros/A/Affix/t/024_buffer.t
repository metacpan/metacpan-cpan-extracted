use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
#
$|++;
#
my $lib = compile_ok(<<~'');
    #include "std.h"
    //ext: .c
    #include <string.h>
    #include <stdio.h>
    DLLEXPORT void fill_buffer(char* buf, int size, const char* src) {
        if (buf && size > 0) {
            strncpy(buf, src, size - 1);
            buf[size - 1] = '\0';
        }
    }

affix $lib, 'fill_buffer', [ Buffer, Int, String ] => Void;
subtest 'Mutable Buffer' => sub {
    my $buf = "\0" x 128;
    fill_buffer( $buf, 128, "Zero Copy Write" );
    my $str = unpack( 'Z*', $buf );
    is $str, "Zero Copy Write", "Buffer modified in place";
};
#
done_testing;

use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
$|++;
my $C_CODE = <<'END_C';
#include "std.h"
//ext: .c

#include <string.h>
#include <stdlib.h>

// Take a StringList and return the count
DLLEXPORT int count_args(char** argv) {
    int i = 0;
    if (!argv) return -1;
    while(argv[i]) i++;
    return i;
}

// Take a StringList and concat them
DLLEXPORT void concat_args(char** argv, char* buffer) {
    buffer[0] = 0;
    if(!argv) return;
    int i = 0;
    while(argv[i]) {
        strcat(buffer, argv[i]);
        i++;
    }
}

// Return a static StringList
DLLEXPORT char** get_static_list() {
    static char* list[] = { "Foo", "Bar", "Baz", NULL };
    return list;
}
END_C
my $lib = compile_ok($C_CODE);
affix $lib, 'count_args',      [StringList]                   => Int;
affix $lib, 'concat_args',     [ StringList, Pointer [Char] ] => Void;
affix $lib, 'get_static_list', []                             => StringList;
subtest Roundtrip => sub {
    my $list = [qw[Hello World from Affix]];
    is count_args($list), 4, 'Correctly counted 3 elements';
    my $buf = pack('x1024');    # Allocate buffer
    concat_args( $list, $buf );

    # Strip nulls for comparison
    $buf =~ s/\0.*$//;
    is $buf, 'HelloWorldfromAffix', 'Strings concatenated correctly';
};
subtest 'Return Value' => sub {
    my $ret = get_static_list();
    is $ret, [qw[Foo Bar Baz]], 'Received StringList from C';
};
subtest 'Edge Cases' => sub {
    is count_args(undef), -1, 'Undef passed as NULL';
    is count_args( [] ),   0, 'Empty array passed as empty list (only NULL terminator)';
};
done_testing;

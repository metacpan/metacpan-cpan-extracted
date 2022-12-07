use strict;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Dyn::Call qw[:memory];
$|++;
#
plan skip_all => q[You use *BSD. You don't like nice things.] if $^O =~ /bsd/i;
#
subtest 'memchr' => sub {
    my $str = malloc(7);
    memcpy( $str, 'ABCDEFG', 7 );
    my @chars = qw[D d];
    is memchr( $str, 'D', 7 )->raw(4), 'DEFG', 'D (68) found';
    is memchr( $str, 'd', 7 ),         undef,  'd (100) not found';
    free $str;
};
subtest 'memcmp' => sub {
    my $a1 = malloc(3);
    memcpy( $a1, 'abc', 3 );
    my $a2 = malloc(3);
    memcpy( $a2, 'abd', 3 );
    is memcmp( $a1, $a2, 3 ), -1, 'abc precedes abd in lexicographical order';
    is memcmp( $a2, $a1, 3 ), 1,  'abd follows abc in lexicographical order';
    is memcmp( $a1, $a1, 3 ), 0,  'abc compares equal to abc in lexicographical order';
    free $a1;
    free $a2;
};
subtest 'memset' => sub {
    my $str = malloc(22);
    memcpy( $str, 'ghghghghghghghghghghgh', 22 );
    memset( $str, 'a', 5 );
    is $str->raw(22), 'aaaaahghghghghghghghgh', free $str;
};
subtest 'memcpy' => sub {
    my $source = calloc( 30, 1 );
    isa_ok $source, 'Dyn::Call::Pointer', '$source';
    memcpy( $source, 'once upon a midnight dreary...', 30 );
    my $dest = calloc( 4, 1 );
    isa_ok $dest, 'Dyn::Call::Pointer', '$dest';
    memcpy( $dest, $source, 4 );
    my @expectations = qw[o n c e];
    for my $n ( 0 .. 3 ) {
        is Dyn::Call::Pointer::raw( $dest + $n, 1 ), $expectations[$n], $expectations[$n];
    }
    free $dest;
    is $dest, undef, 'freed $dest';
    free $source;
    is $dest, undef, 'freed $source';
};
subtest 'memmove' => sub {
    my $mem = calloc( 10, 1 );
    isa_ok $mem, 'Dyn::Call::Pointer', '$mem = calloc( 10, 1 )';
    is $mem->raw(10), "\0" x 10, 'new pointer is NULL filled';
    diag 'memcpy( $mem, "1234567890", 10 );';
    memcpy( $mem, "1234567890", 10 );
    is $mem->raw(10), '1234567890', 'pointer is filled with 1234567890';
    diag 'memmove( $mem + 4, $mem + 3, 3 );';
    memmove( $mem + 4, $mem + 3, 3 );    # copy from [4,5,6] to [5,6,7]
    is $mem->raw(10), '1234456890', 'pointer is filled with 1234456890';
    free $mem;
    is $mem, undef, 'freed $mem';
};
subtest 'stringify' => sub {
    my $mem = calloc( 12, 1 );
    isa_ok $mem, 'Dyn::Call::Pointer', '$mem = calloc( 12, 1 )';
    is $mem->raw(10), "\0" x 10, 'new pointer is NULL filled';
    diag 'memcpy( $mem, "1234567890", 10 );';
    memcpy( $mem, "1234567890", 10 );
    is $mem, '1234567890', 'stringified version of pointer is 1234567890';
    free $mem;
    is $mem, undef, 'freed $mem';
};
subtest 'offsets' => sub {
    my $mem = calloc( 12, 1 );
    isa_ok $mem, 'Dyn::Call::Pointer', '$mem = calloc( 12, 1 )';
    is $mem->raw(10), "\0" x 10, 'new pointer is NULL filled';
    diag 'memcpy( $mem, "1234567890", 10 );';
    memcpy( $mem,     "1234567890", 10 );
    memcpy( $mem + 4, "123",        3 );
    is $mem, '1234123890', 'stringified version of offset modified pointer is 1234123890';
    free $mem;
    is $mem, undef, 'freed $mem';
};
#
done_testing;

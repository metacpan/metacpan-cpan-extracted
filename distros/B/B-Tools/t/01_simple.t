use strict;
use warnings;
use utf8;
use Test::More;

use B qw(class);
use B::Tools qw(op_walk op_grep op_descendants);

my $code = sub { 5963 };
my $cv = B::svref_2object($code);
my ($const) = op_grep { $_->name eq 'const' } $cv->ROOT;
ok $const;
cmp_ok 0+op_descendants($cv->ROOT), '>', 1;

{
    my $ok;
    op_walk {
        $ok++ if $_->name eq 'const';
    } $cv->ROOT;
    ok $ok;
}

done_testing;


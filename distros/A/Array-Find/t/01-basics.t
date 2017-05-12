#!perl -T

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use Array::Find qw(find_in_array);

test_find(
    name   => 'exact find',
    args   => {item=>"a", array=>[qw/a aa b ba c a cb/]},
    result => [qw/a a/],
);
test_find(
    name   => 'unique 1 (exact find)',
    args   => {item=>"a", array=>[qw/a aa b ba c a cb/], unique=>1},
    result => [qw/a/],
);
test_find(
    name   => 'max_result',
    args   => {item=>"a", max_result=>1, array=>[qw/a aa b ba c a a cb/]},
    result => [qw/a/],
);
test_find(
    name   => 'unique 2 (max_result)',
    args   => {items=>["a", "b"], unique=>1, max_result=>1,
               array=>[qw/a aa b ba c a b/]},
    result => [qw/a/],
);
test_find(
    name   => 'negative max_result',
    args   => {items=>[qw/a b c/], max_result=>-2, array=>[qw/a a d b a b c/]},
    result => [qw/a a a b/],
);
test_find(
    name   => 'unique 3 (negative max_result)',
    args   => {items=>[qw/a b c/], unique=>1, max_result=>-2,
               array=>[qw/a a d b a b c/]},
    result => [qw/a b/],
);
test_find(
    name   => 'max_compare',
    args   => {item=>"a", max_compare=>6, array=>[qw/a aa b ba c a a cb/]},
    result => [qw/a a/],
);
test_find(
    name   => 'unique 4 (max_compare)',
    args   => {item=>"a", unique=>1, max_compare=>6,
               array=>[qw/a aa b ba c a a cb/]},
    result => [qw/a/],
);

test_find(
    name   => 'prefix mode',
    args   => {item=>"a", mode=>"prefix", array=>[qw/a aa b ba c a a cb/]},
    result => [qw/a aa a a/],
);
test_find(
    name   => 'unique 5 (prefix mode)',
    args   => {item=>"a", unique=>1, mode=>"prefix",
               array=>[qw/a aa b ba c a a cb/]},
    result => [qw/a aa/],
);
test_find(
    name   => 'suffix mode',
    args   => {item=>"a", mode=>"suffix", array=>[qw/a aa b ba c a a cb/]},
    result => [qw/a aa ba a a/],
);
test_find( # bug in v0.02, didn't check index() > -1 first
    name   => 'suffix mode (long item)',
    args   => {item=>"aa", mode=>"suffix", array=>[qw/a aa aaa aaaa/]},
    result => [qw/aa aaa aaaa/],
);
test_find(
    name   => 'prefix|suffix mode',
    args   => {item=>"a", mode=>"prefix|suffix", array=>[qw/a b ba ab bab/]},
    result => [qw/a ba ab/],
);
test_find(
    name   => 'infix mode',
    args   => {item=>"a", mode=>"infix", array=>[qw/a b ba ab bab/]},
    result => [qw/bab/],
);
test_find( # bug in v0.02, we need to do index() + rindex()
    name   => 'infix mode (item matches at the start/end)',
    args   => {item=>"aa", mode=>"infix", array=>[qw/a aa aaa aaaa/]},
    result => [qw/aaaa/],
);

test_find(
    name   => 'ci',
    args   => {item=>"a", ci=>1, array=>[qw/A/]},
    result => [qw/A/],
);
test_find(
    name   => 'ci, prefix',
    args   => {item=>"a", mode=>"prefix", ci=>1, array=>[qw/a Ab ba bAb/]},
    result => [qw/a Ab/],
);
test_find(
    name   => 'ci, suffix',
    args   => {item=>"a", mode=>"suffix", ci=>1, array=>[qw/a ab Ba bAb/]},
    result => [qw/a Ba/],
);
test_find(
    name   => 'ci, prefix|suffix',
    args   => {item=>"a", mode=>"prefix|suffix", ci=>1,
               array=>[qw/A Ab bA bAb/]},
    result => [qw/A Ab bA/],
);
test_find(
    name   => 'ci, infix',
    args   => {item=>"a", mode=>"infix", ci=>1, array=>[qw/a ab ba bAb/]},
    result => [qw/bAb/],
);
test_find(
    name   => 'ci, regex',
    args   => {item=>qr/^a/, ci=>1, mode=>"regex", array=>[qw/Ab/]},
    result => [qw/Ab/],
);

test_find(
    name   => 'regex mode',
    args   => {item=>qr/^[B][ab]$/i, mode=>"regex",
               array=>[qw/a b ba ab bab/]},
    result => [qw/ba/],
);

my $awords = ["",
              qw/.
                 a     a.     .a     .a.
                 b     b.     .b     .b.
                 c     c.     .c     .c.
                 a.b   .a.b   a.b.   .a.b.
                 a.bc  .a.bc  a.b.c  .a.b.c
                 ca.b  c.a.b  ca.b.  c.a.b.
                 ca.bc c.a.bc ca.b.c c.a.b.c
                /];
test_find(
    name   => 'word_sep, prefix',
    args   => {item=>"a.b", mode=>"prefix", word_sep=>'.',
               array=>$awords},
    result => [qw/a.b a.b. a.b.c/],
);
test_find(
    name   => 'word_sep, infix',
    args   => {item=>"a.b", mode=>"infix", word_sep=>'.',
               array=>$awords},
    result => [qw/.a.b. .a.b.c c.a.b. c.a.b.c/],
);
test_find(
    name   => 'word_sep, suffix',
    args   => {item=>"a.b", mode=>"suffix", word_sep=>'.',
               array=>$awords},
    result => [qw/a.b .a.b c.a.b/],
);
test_find(
    name   => 'word_sep, prefix|infix',
    args   => {item=>"a.b", mode=>"prefix|infix", word_sep=>'.',
               array=>$awords},
    result => [qw/a.b a.b. .a.b. a.b.c .a.b.c c.a.b. c.a.b.c/],
);
test_find(
    name   => 'word_sep, prefix|suffix',
    args   => {item=>"a.b", mode=>"prefix|suffix", word_sep=>'.',
               array=>$awords},
    result => [qw/a.b .a.b a.b. a.b.c c.a.b/],
);
test_find(
    name   => 'word_sep, prefix|infix|suffix',
    args   => {item=>"a.b", mode=>"prefix|infix|suffix", word_sep=>'.',
               array=>$awords},
    result => [qw/a.b .a.b a.b. .a.b. a.b.c .a.b.c c.a.b c.a.b.
                  c.a.b.c/],
);
test_find(
    name   => 'word_sep, infix|suffix',
    args   => {item=>"a.b", mode=>"infix|suffix", word_sep=>'.',
               array=>$awords},
    result => [qw/a.b .a.b .a.b. .a.b.c c.a.b c.a.b. c.a.b.c/],
);

test_find(
    name   => 'ci, word_sep, prefix',
    args   => {item=>"A.B", mode=>"prefix", word_sep=>'.',
               array=>$awords, ci=>1},
    result => [qw/a.b a.b. a.b.c/],
);
test_find(
    name   => 'ci, word_sep, suffix',
    args   => {item=>"A.B", mode=>"suffix", word_sep=>'.',
               array=>$awords, ci=>1},
    result => [qw/a.b .a.b c.a.b/],
);
test_find(
    name   => 'ci, word_sep, prefix|suffix',
    args   => {item=>"A.B", mode=>"prefix|suffix", word_sep=>'.',
               array=>$awords, ci=>1},
    result => [qw/a.b .a.b a.b. a.b.c c.a.b/],
);
test_find(
    name   => 'ci, word_sep, infix',
    args   => {item=>"A.B", mode=>"infix", word_sep=>'.',
               array=>$awords, ci=>1},
    result => [qw/.a.b. .a.b.c c.a.b. c.a.b.c/],
);

test_find(
    name   => 'shuffle',
    args   => {item=>"a", mode=>"prefix", shuffle=>1,
               array=>[qw/a aa ab ac ad ae af ag ah ai aj ak al am an ao/]},
    result_shuffled => 1,
);

test_find(
    name   => 'multi arrays',
    args   => {item=>"a",
               arrays=>[
                   [qw/a/], [qw/b a/], [qw/a c a/],
               ]},
    result => [qw/a a a a/],
);
test_find(
    name   => 'multi items',
    args   => {items=>[qw/a b/],
               array=>[qw/b a c a/]},
    result => [qw/a a b/],
);
test_find(
    name   => 'multi arrays + multi items',
    args   => {items=>[qw/a b/],
               arrays=>[
                   [qw/a/], [qw/b a/], [qw/a c a/],
               ]},
    result => [qw/a a a a b/],
);

test_find(
    name   => 'handling undef in array',
    args   => {item=>"", array=>["", "a", undef]},
    result => [""],
);
test_find(
    name   => 'handling undef in item',
    args   => {items=>[undef], array=>["", "a", undef]},
    result => [undef],
);

done_testing();

sub test_find {
    my %args = @_;
    my $name = $args{name};
    my $find_args = $args{args};

    subtest $name => sub {
        my $res = find_in_array(%$find_args);
        if ($args{result}) {
            is_deeply($res, $args{result}, "result") or diag(explain($res));
        }
        if ($args{result_shuffled}) {
            die "Can't test shuffle if result < 2 items" if @$res < 2;
            # repeat so statistically guaranteed to succeed
            my $num_repeat = int(20/@$res);
            $num_repeat    = 5 if $num_repeat < 5;
            my $seen_shuffled;
          R:
            for (1..$num_repeat) {
                my $res2 = find_in_array(%$find_args);
                for (0..@$res2-1) {
                    if ($res->[$_] ne $res2->[$_]) {
                        $seen_shuffled++;
                        last R;
                    }
                }
            }
            ok($seen_shuffled, "result is shuffled") or
                diag("not seeing result shuffled after $num_repeat iterations");
        }
    };
}

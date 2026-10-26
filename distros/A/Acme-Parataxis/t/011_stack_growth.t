use v5.40;
use blib;
use Acme::Parataxis qw[async yield fiber];
use Test2::V1 -ipP;
$|++;
#
no warnings 'recursion';
subtest 'Deep plain recursion grows the Perl control stacks' => sub {
    async {
        my $f = fiber {
            my $recur;
            $recur = sub {
                my ($n) = @_;
                return 0 if $n <= 1;
                return 1 + $recur->( $n - 1 );
            };
            $recur->(20000);
        };
        my $r = $f->await();
        is $r, 19999, 'depth-20000 recursion returned the expected result';
    };
};
subtest 'Nested sort comparators recurse through C' => sub {

    # Each nested sort re-enters perl from C (S_sortcv -> CALLRUNOPS), which
    # consumes real C stack; this used to corrupt the heap in DEBUGGING perls
    # because the fiber did not own PL_scopestack_name.
    async {
        my $f = fiber {
            my $recur;
            $recur = sub {
                my ($n) = @_;
                return 0 if $n <= 1;
                my @out = sort { my $x = $recur->( $n - 1 ) } ( 0, 1 );
                return $out[0];
            };
            $recur->(500);
        };
        my $r = $f->await();
        is $r, 0, 'depth-500 sort-comparator recursion completed';
    };
};
subtest 'Recursion interleaved with yields' => sub {
    my @log;
    async {
        my $f = fiber {
            my $recur;
            $recur = sub {
                my ($n) = @_;
                return 0 if $n <= 1;
                push @log, "d$n";
                yield;
                return 1 + $recur->( $n - 1 );
            };
            $recur->(50);
        };
        yield;
        my $r = $f->await();
        is $r, 49, 'recursing fiber that yields still completes';
    };
    ok @log >= 49, 'fiber yielded during recursion';
};
done_testing();

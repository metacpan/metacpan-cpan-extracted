use strict;
use warnings;
use Test::More;
use Data::Path::XS qw(path_get path_set patha_get pathc_get path_compile);
use Data::Path::XS ':keywords';

# path_get / patha_get / pathc_get / pathget all return rvalues.
# Trying to use them as lvalues must fail at compile time, and assigning
# to a returned ref must NOT silently cascade into the original structure.

subtest 'path_get is not lvalue' => sub {
    eval q{ my $d = { x => 1 }; path_get($d, '/x') = 99 };
    ok($@, 'path_get(...) = ... is rejected') or diag "no error";
    like($@, qr/lvalue|modify|read.?only|left side/i,
         'compile-time rejection mentions lvalue/readonly')
        or diag "got: $@";
};

subtest 'pathget keyword is not lvalue' => sub {
    # Keyword form is also a value-yielding expression; assignment should
    # fail at compile time the same way.
    eval q{
        use Data::Path::XS ':keywords';
        my $d = { x => 1 };
        (pathget $d, "/x") = 99;
    };
    ok($@, 'pathget = ... rejected') or diag "no error";
};

subtest 'returned ref shares storage with original' => sub {
    # Assigning into a *returned ref* mutates the original — that is normal
    # Perl ref semantics, not an lvalue extension of path_get itself.
    my $d = { items => [1,2,3] };
    my $arr = path_get($d, '/items');
    push @$arr, 4;
    is_deeply($d->{items}, [1,2,3,4], 'mutating returned ref affects original');
};

subtest 'assigning to my var does not aliasing-leak through the ref' => sub {
    my $d = { val => 'original' };
    my $copy = path_get($d, '/val');     # SCALAR is copied via SvREFCNT_inc + sv_2mortal
    $copy = 'mutated';                   # rebinds my var, doesn't touch $d->{val}
    is($d->{val}, 'original', 'rebinding $copy does not affect $d->{val}');
};

done_testing;

use strict;
use warnings;
use Test::More;

# Pin the import contract documented in lib/Data/Path/XS.pm IMPORTING.

subtest 'default use exports nothing' => sub {
    package T1;
    use Data::Path::XS;
    ::ok(!T1->can('path_get'),  'path_get not imported by default');
    ::ok(!T1->can('pathc_get'), 'pathc_get not imported by default');
};

subtest 'function exports' => sub {
    package T2;
    use Data::Path::XS qw(path_get path_set);
    ::ok( T2->can('path_get'), 'path_get imported');
    ::ok( T2->can('path_set'), 'path_set imported');
    ::ok(!T2->can('path_delete'), 'unrequested function not imported');
};

subtest ':keywords lexical scope' => sub {
    my $got;
    {
        use Data::Path::XS ':keywords';
        my $d = { a => { b => 'value' } };
        $got = pathget $d, "/a/b";
    }
    is($got, 'value', 'pathget visible inside :keywords block');

    # Outside the block, `pathget` is no longer in scope. The eval-q below
    # is compiled in this outer scope, so the hint is gone and `pathget`
    # falls back to bareword/method semantics — not our keyword.
    my $out = eval q{ my $x = { a => { b => 'value' } }; pathget $x, "/a/b" };
    isnt($out, 'value', 'pathget does not work outside :keywords scope');
};

subtest ':keywords + function exports together' => sub {
    package T4;
    use Data::Path::XS ':keywords', qw(path_get);
    ::ok(T4->can('path_get'), 'function exported');
    my $d = { x => 1 };
    ::is(T4::path_get($d, '/x'), 1, 'function works');
    ::is((pathget $d, "/x"), 1, 'keyword works');
};

subtest 'unimport removes keywords' => sub {
    my ($visible, $removed);
    {
        use Data::Path::XS ':keywords';
        my $d = { a => 1 };
        $visible = pathget $d, "/a";
        {
            no Data::Path::XS;
            $removed = eval q{ my $x = { a => 1 }; pathget $x, "/a" };
        }
    }
    is($visible, 1, 'keyword visible after :keywords');
    isnt($removed, 1, 'keyword removed by unimport');
};

done_testing;

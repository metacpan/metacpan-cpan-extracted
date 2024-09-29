#!perl
# 999-extras-for-coverage.t: random tests for things that aren't covered
# elsewhere.
use rlib 'lib';
use HopenTest;

ok($Data::Hopen::VERSION, 'has a VERSION');

# Fake package, used for testing hnew
package MY::ReturnsFalsyInstance {
    sub new {
        return undef
    }
}
BEGIN { $INC{'MY/ReturnsFalsyInstance.pm'} = 1; }

package TestDataHopen {
    use Data::Hopen ':all';
    use HopenTest;
    use Capture::Tiny qw(capture_stderr);
    use Test::Fatal;

    use List::AutoNumbered;
    use Quote::Code;

    sub test_hnew {
        like exception { hnew(); }, qr/Need a class/, 'hnew() throws';
        like exception { hnew('Data::Hopen::DOES_NOT_EXIST_TEST_ONLY'); },
            qr/Could not find class/, 'hnew(<nonexistent>) throws';
        like exception { hnew('MY::ReturnsFalsyInstance') },
            qr/Could not create instance/, 'hnew(<existent but falsy>) throws';

        my $dag = hnew(DAG => 'foo');
        ok $dag, 'hnew DAG works';
        like exception { $dag->connect() }, qr/argument/, 'DAG::connect() throws with 0 args';
        like exception { $dag->connect(1) }, qr/argument/, 'DAG::connect() throws with 1 arg';
        like exception { $dag->connect(1..5) }, qr/argument/, 'DAG::connect() throws with 5 args';
    }

    sub test_loadfrom {
        my ($pkgname, $msg, $retval);

        $pkgname = loadfrom('Data::Hopen::Scope');
        is $pkgname, 'Data::Hopen::Scope', 'loadfrom finds literal name';

        $pkgname = loadfrom('Entity','Data::Hopen::G::');
        is $pkgname, 'Data::Hopen::G::Entity', 'loadfrom finds name with stem';

        # Nonexistent
        $pkgname = loadfrom('Data::Hopen::DOES_NOT_EXIST_TEST_ONLY');
        ok(!defined $pkgname, 'loadfrom(nonexistent) returns undef');

        # Invalid invocations
        like exception { loadfrom(); }, qr/Need a class/,
            'loadfrom dies without a class name';

        # Verbose output, unsuccessful
        $msg = capture_stderr {
            local $QUIET = false;
            local $VERBOSE = 3;
            loadfrom('MY::NONEXISTENT');
        };
        like $msg, qr/loadfrom\s+MY::NONEXISTENT/, 'loadfrom verbose: Name logged';
        like $msg, qr/Can't locate\s+MY[\/\\]NONEXISTENT\b/, 'loadfrom verbose: Error message logged';

        # Verbose output, successful
        $msg = capture_stderr {
            $QUIET = false;
            $VERBOSE = 3;
            $retval = loadfrom('Data::Hopen');
        };
        like $msg, qr/loadfrom\s+Data::Hopen/, 'loadfrom verbose ok: Name logged';
        unlike $msg, qr/Can't locate/, 'loadfrom verbose ok: No error message';
        is $retval, 'Data::Hopen', 'loadfrom verbose ok: return value';
    }

    sub test_hlog {
            # (line,) name, VERBOSE, QUIET, expected, [hlog level]
        my $tests = List::AutoNumbered->new(__LINE__);
        $tests->load('quiet', 0, true, qr/^$/)->
            ('quiet beats verbose 1', 1, true, qr/^$/)
            ('quiet beats verbose 2', 2, true, qr/^$/)
            ('normal', 1, false, qr/\b42\b/)
            ('normal level 2 verbose 1', 1, false, qr/^$/, 2)
            ('normal level 2 verbose 2', 2, false, qr/\b42\b/, 2)
            ('normal level 3 verbose 3', 3, false, qr/\b42\b.+\(at/, 3)
            ('normal level 4 verbose 3', 3, false, qr//, 4)
        ;

        for my $lrTest (@{ $tests->arr }) {
            my $msg = capture_stderr {
                $QUIET = ($lrTest->[3] // false);
                $VERBOSE = ($lrTest->[2] // 0);

                if($lrTest->[5]) {
                    hlog { 42 } $lrTest->[5];
                } else {
                    hlog { 42 };
                }

                $QUIET = false;
                $VERBOSE = 0;
            };
            like $msg, $lrTest->[4],
                qc"hlog {$lrTest->[1]} (line {$lrTest->[0]})";
        }

        $VERBOSE = 1;   # So hlog will actually get to running the sub
        is capture_stderr { hlog(sub {}) }, '', 'No hlog output';
        like capture_stderr { hlog(sub { "" }) }, qr/^# $/m,
            'Empty-string hlog output';
            # coverage for the "chomp if"
        $VERBOSE = 0;
    } #test_hlog()

    sub run {
        test_hnew;
        test_loadfrom;
        test_hlog;
    }
} #package DH

package TestDataHopenScope {
    use Data::Hopen ':all';
    use Data::Hopen::Scope;
    use HopenTest;
    use Capture::Tiny qw(capture_stderr);
    use Test::Fatal;

    sub run {
        my $dut = Data::Hopen::Scope->new;
        foreach my $method (qw(put merge _names_here _find_here)) {
            like exception { $dut->$method; }, qr/Unimplemented/,
                "abstract $method dies";
       }
    }
} #package DHScope

package TestDataHopenGOutputOp {
    use HopenTest;
    use Capture::Tiny;
    use Test::Fatal;

    use Data::Hopen 'hnew';
    use Data::Hopen::G::OutputOp;

    sub run {
        like exception { Data::Hopen::G::OutputOp::_run() },
            qr/Need an instance/, '_run() croaks absent instance';

        my $e = hnew OutputOp => 'a name', output => [];
        isa_ok($e, 'Data::Hopen::G::OutputOp');
        like exception { $e->run },
            qr/output is not a hashref/,
            'D::H::G::OutputOp requires a hashref';
    }
} #package DHGOO

package TestDataHopenGNode {
    use HopenTest;
    use Capture::Tiny;
    use Test::Fatal;

    use Data::Hopen 'hnew';
    use Data::Hopen::G::Node;

    sub run {
        # Invalid invocations
        like(exception { Data::Hopen::G::Node::outputs() },
            qr/Need an instance/,
            'outputs() dies without $self');

        # outputs()
        my $n = hnew 'Node' => 'some name';
        isa_ok($n, 'Data::Hopen::G::Node');

        like exception { $n->outputs([]) },
            qr/set\b.*non-hashref/,
            'Node outputs(non-hashref) throws';
        like exception { $n->outputs(undef) },
            qr/set\b.*non-hashref.*undef/,
            'Node outputs(undef) throws';

        delete $n->{outputs} if exists $n->{outputs};
        is_deeply $n->outputs, {}, 'Node->outputs defaults to {}';
    }
} #package DHGN

package TestDataHopenUtilData {
    use HopenTest;
    use Data::Hopen::Util::Data qw(boolify clone dedent forward_opts);
    use List::AutoNumbered;
    use Scalar::Util qw(refaddr);
    use Test::Fatal;

    my @TESTS;
    push @TESTS, sub {  # boolify
        ok(boolify($_), "$_ -> truthy") foreach qw(1 true yes on);
        ok(!boolify($_), ($_//'<undef>') . " -> falsy")
            foreach (qw(false off no), 0, undef);
    };

    push @TESTS, sub {  # clone
        cmp_ok(clone(42), '==', 42, 'Clone ==');
        is(clone('foo'), 'foo', 'Clone eq');
        my $x = [1, 'foo', {bar => 'bat'}];
        my $clone_x = clone($x);
        is_deeply($clone_x, $x, 'Clone deeply');
        cmp_ok(refaddr($x), '!=', refaddr($clone_x), "Clone isn't original");
    };

    push @TESTS, sub {  # dedent
        my $tests = List::AutoNumbered->new(__LINE__);
        $tests->load([" some\n multiline string"], "some\nmultiline string")->
        (["no NL"], "no NL")
        (["  leading WS"],"leading WS")
        (["trailing WS  "], "trailing WS  ")
        ([ [], q(
        very indented
    ) ], "very indented\n")
        (["not\nindented\nat all"], "not\nindented\nat all")
        (["\ninitial newline\n  and some more"], "\ninitial newline\n  and some more")
        (["    \nleading WS on nonblank line not stripped"], "    \nleading WS on nonblank line not stripped")
        ;

        for my $test (@$tests) {
            my @args = @{$test->[1]};
            my $got = dedent @args;
            is($got, $test->[2], 'dedent (line ' . $test->[0] . ')');

            # Test $_
            local $_ = pop @args;
            $got = dedent @args;
            is($got, $test->[2], 'dedent $_ (line ' . $test->[0] . ')');
        }
    };

    push @TESTS, sub {
        like(exception { forward_opts; }, qr/Need/, 'forward_opts requires arg');
        like(exception { forward_opts [] }, qr/hashref/, 'forward_opts requires hashref');
        is_deeply(+{forward_opts({foo=>42}, 'foo')}, {foo=>42}, 'forward_opts: plain');
        is_deeply(+{forward_opts({foo=>42}, {}, 'foo')}, {foo=>42}, 'forward_opts: empty opts');
        is_deeply(+{forward_opts({FOO=>42}, {lc=>1}, 'FOO')}, {foo=>42}, 'forward_opts: lc');
        is_deeply(+{forward_opts({foo=>42}, {'-'=>1}, 'foo')}, {-foo=>42}, 'forward_opts: -');
    };

    sub run { &$_ foreach @TESTS; }
} #package DHUD

use PackagesInThisFile 'run';   # every package above that has a sub run()
(diag($_), $_->run) foreach @PIF;

done_testing();

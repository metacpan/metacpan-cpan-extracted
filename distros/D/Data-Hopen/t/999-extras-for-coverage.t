#!perl
# 999-extras-for-coverage.t: random tests for things that aren't covered
# elsewhere.
use rlib 'lib';
use HopenTest;

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

        ok hnew(DAG => 'foo'), 'hnew DAG works';
    }

    sub test_loadfrom {
        my $pkgname;

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

    sub test_isMYH {
        ok isMYH('MY.hopen.pl'), 'MY.hopen.pl is MYH';
        ok !isMYH('foo'), 'foo is not MYH';

        ok(isMYH, 'MY.hopen.pl is MYH ($_)') for 'MY.hopen.pl';
        ok(!isMYH, 'foo is not MYH ($_)') for 'foo';
    }

    sub run {
        test_hnew;
        test_loadfrom;
        test_hlog;
        test_isMYH;
    }
} #package DH

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

use PackagesInThisFile 'run';   # every package above that has a sub run()
(diag($_), $_->run) foreach @PIF;

done_testing();

#!perl -w
use strict;

use Test::More;
plan tests => 6;

use CPAN::FindDependencies 'finddeps';
use Capture::Tiny qw(capture);

my($stdout, $stderr) = capture {
    my $result = {
        map {
            $_->name() => [$_->depth(), $_->distribution(), $_->warning()]
        } finddeps(
            'Tie::Scalar::Decay',
            '02packages'  => 't/cache/Tie-Scalar-Decay-1.1.1/02packages.details.txt.gz',
            cachedir      => 't/cache/Tie-Scalar-Decay-1.1.1',
            nowarnings    => 1,
            usemakefilepl => 1
        )
    };
    SKIP: {
        skip("Makefile.PL timed out", 1) if($result->{'Tie::Scalar::Decay'}->[2]);
        is_deeply(
            $result,
            {
                'Tie::Scalar::Decay' => [0, 'D/DC/DCANTRELL/Tie-Scalar-Decay-1.1.1.tar.gz',undef],
                'Time::HiRes' => [1, 'J/JH/JHI/Time-HiRes-1.9719.tar.gz',undef],
            },
            "Dependencies calculated OK using Makefile.PL"
        );
    }
};

ok($stdout eq '', "Spew to STDOUT was suppressed: $stdout");
ok($stderr eq '', "Spew to STDERR was suppressed: $stderr");

($stdout, $stderr) = capture {
    is_deeply(
        {
            map {
                $_->name() => [$_->depth(), $_->distribution(), $_->warning()]
            } finddeps(
                'Tie::Scalar::Decay',
                '02packages'  => 't/cache/Tie-Scalar-Decay-1.1.1-malicious/02packages.details.txt.gz',
                cachedir      => 't/cache/Tie-Scalar-Decay-1.1.1-malicious',
                nowarnings    => 1,
                usemakefilepl => 1
            )
        },
        {
            'Tie::Scalar::Decay' => [0, 'D/DC/DCANTRELL/Tie-Scalar-Decay-1.1.1.tar.gz',"Makefile.PL didn't finish in a reasonable time\n"],
        },
        "Makefile.PL that spins times out OK"
    );
};

ok($stdout eq '', "Spew to STDOUT was suppressed: $stdout");
ok($stderr eq '', "Spew to STDERR was suppressed: $stderr");

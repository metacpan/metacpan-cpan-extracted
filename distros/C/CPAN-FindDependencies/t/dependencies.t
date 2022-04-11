use strict;
use warnings;

use Test::More;
use Test::Exception;

use Capture::Tiny qw(capture);

use CPAN::FindDependencies 'finddeps';

throws_ok { finddeps(qw(CPAN::FindDependencies I::Like::Pickles)) }
    qr/already looking for deps for 'CPAN::FindDependencies/,
    "exception thrown when told to look for deps for two modules at once";

is_deeply(
    [
        map {
            $_->name() => [$_->depth(), $_->distribution(), $_->warning()?1:0]
        } finddeps(
            'CPAN::FindDependencies',
            'mirror' => 'DEFAULT,t/cache/CPAN-FindDependencies-1.1/02packages.details.txt.gz',
            cachedir     => 't/cache/CPAN-FindDependencies-1.1',
            nowarnings   => 1
        )
    ],
    [
        'CPAN::FindDependencies' => [0, 'D/DC/DCANTRELL/CPAN-FindDependencies-1.1.tar.gz',0],
        'CPAN' => [1, 'A/AN/ANDK/CPAN-1.9205.tar.gz',0],
        'File::Temp' => [2, 'T/TJ/TJENNESS/File-Temp-0.19.tar.gz',0],
        'File::Spec' => [3, 'K/KW/KWILLIAMS/PathTools-3.25.tar.gz',0],
        'ExtUtils::CBuilder' => [4, 'K/KW/KWILLIAMS/ExtUtils-CBuilder-0.21.tar.gz',0],
        'Module::Build' => [4, 'K/KW/KWILLIAMS/Module-Build-0.2808.tar.gz',0],
        'Scalar::Util' => [4, 'G/GB/GBARR/Scalar-List-Utils-1.19.tar.gz',0],
        'Test::More' => [3, 'M/MS/MSCHWERN/Test-Simple-0.72.tar.gz',0],
        'Test::Harness' => [4, 'A/AN/ANDYA/Test-Harness-3.03.tar.gz',0],
        'LWP::UserAgent' => [1, 'G/GA/GAAS/libwww-perl-5.808.tar.gz', 1],
        'YAML' => [1, 'I/IN/INGY/YAML-0.66.tar.gz',0],
    ],
    "Dependencies calculated OK with default perl and no maxdepth"
);

# CPAN::Meta::YAML seems to only yell on 5.24 and higher
if($] >= 5.024) {
    my($stdout, $stderr) = capture {
        finddeps(
            'CPAN::FindDependencies',
            'mirror' => 'DEFAULT,t/cache/CPAN-FindDependencies-1.1-no_index-twice/02packages.details.txt.gz',
            cachedir     => 't/cache/CPAN-FindDependencies-1.1-no_index-twice',
            nowarnings   => 1,
            perl         => 5.008008
        );
    };
    like $stderr, qr/In CPAN-FindDependencies-1.1.tar.gz/, "... we warn appropriately on dodgy metadata";
}

is_deeply(
    {
        map {
            $_->name() => [$_->depth(), $_->distribution(), $_->warning()?1:0, $_->version()]
        } finddeps(
            'CPAN::FindDependencies',
            'mirror' => 'DEFAULT,t/cache/CPAN-FindDependencies-1.1/02packages.details.txt.gz',
            cachedir     => 't/cache/CPAN-FindDependencies-1.1',
            nowarnings   => 1,
            perl         => 5.008008
        )
    },
    {
        'CPAN::FindDependencies' => [0, 'D/DC/DCANTRELL/CPAN-FindDependencies-1.1.tar.gz',0, 1.1],
        'LWP::UserAgent' => [1, 'G/GA/GAAS/libwww-perl-5.808.tar.gz', 1, 2.032],
        'YAML' => [1, 'I/IN/INGY/YAML-0.66.tar.gz',0, 0.61],
        'CPAN' => [1, 'A/AN/ANDK/CPAN-1.9205.tar.gz',0, 1.9102],
        'Test::Harness' => [2, 'A/AN/ANDYA/Test-Harness-3.03.tar.gz',0, 2.62],
    },
    "Dependencies calculated OK for perl 5.8.8"
);

# same as previous test, but with args in different order
# see https://github.com/DrHyde/perl-modules-CPAN-FindDependencies/issues/13
is_deeply(
    {
        map {
            $_->name() => [$_->depth(), $_->distribution(), $_->warning()?1:0, $_->version()]
        } finddeps(
            'mirror' => 'DEFAULT,t/cache/CPAN-FindDependencies-1.1/02packages.details.txt.gz',
            cachedir     => 't/cache/CPAN-FindDependencies-1.1',
            'CPAN::FindDependencies',
            nowarnings   => 1,
            perl         => 5.008008
        )
    },
    {
        'CPAN::FindDependencies' => [0, 'D/DC/DCANTRELL/CPAN-FindDependencies-1.1.tar.gz',0, 1.1],
        'LWP::UserAgent' => [1, 'G/GA/GAAS/libwww-perl-5.808.tar.gz', 1, 2.032],
        'YAML' => [1, 'I/IN/INGY/YAML-0.66.tar.gz',0, 0.61],
        'CPAN' => [1, 'A/AN/ANDK/CPAN-1.9205.tar.gz',0, 1.9102],
        'Test::Harness' => [2, 'A/AN/ANDYA/Test-Harness-3.03.tar.gz',0, 2.62],
    },
    "... and order of arguments doesn't matter"
);

done_testing;

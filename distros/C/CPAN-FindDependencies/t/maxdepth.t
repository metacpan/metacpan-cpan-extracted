use strict;
use warnings;

use Test::More;
use Test::Differences;

use CPAN::FindDependencies 'finddeps';

eq_or_diff(
    [
        map {
            $_->name() => [$_->depth(), $_->distribution(), $_->warning()?1:0]
        } finddeps(
            'CPAN::FindDependencies',
            'mirror' => 'DEFAULT,t/cache/CPAN-FindDependencies-1.1/02packages.details.txt.gz',
            cachedir     => 't/cache/CPAN-FindDependencies-1.1',
            nowarnings   => 1,
            maxdepth     => 2
        )
    ],
    [
        'CPAN::FindDependencies' => [0, 'D/DC/DCANTRELL/CPAN-FindDependencies-1.1.tar.gz',0],
        'CPAN' => [1, 'A/AN/ANDK/CPAN-1.9205.tar.gz',0],
        'File::Temp' => [2, 'T/TJ/TJENNESS/File-Temp-0.19.tar.gz',0],
        'Scalar::Util' => [2, 'G/GB/GBARR/Scalar-List-Utils-1.19.tar.gz',0],
        'Test::Harness' => [2, 'A/AN/ANDYA/Test-Harness-3.03.tar.gz',0],
        'Test::More' => [2, 'M/MS/MSCHWERN/Test-Simple-0.72.tar.gz',0],
        'LWP::UserAgent' => [1, 'G/GA/GAAS/libwww-perl-5.808.tar.gz', 1],
        'YAML' => [1, 'I/IN/INGY/YAML-0.66.tar.gz',0],
    ],
    "Maxdepth cuts off correctly for a non-zero value"
);

eq_or_diff(
    [
        map {
            $_->name() => [$_->depth(), $_->distribution(), $_->warning()?1:0]
        } finddeps(
            'CPAN::FindDependencies',
            'mirror' => 'DEFAULT,t/cache/CPAN-FindDependencies-1.1/02packages.details.txt.gz',
            cachedir     => 't/cache/CPAN-FindDependencies-1.1',
            nowarnings   => 1,
            maxdepth     => 0
        )
    ],
    [
        'CPAN::FindDependencies' => [0, 'D/DC/DCANTRELL/CPAN-FindDependencies-1.1.tar.gz',0],
    ],
    "Maxdepth cuts off correctly with zero value"
);

done_testing();

use strict;
use warnings;


use Test::More;
use Test::Differences;

plan tests => 1;

use CPAN::FindDependencies 'finddeps';

eq_or_diff(
    {
     map {
         $_->name() => [$_->depth(), $_->distribution(), $_->warning() ? 1 : 0]
       }
       finddeps(
           'HTML::Parser',
           'mirror' => 'DEFAULT,t/cache/CPAN-FindDependencies-1.1/02packages.details.txt.gz',
           cachedir    => 't/cache/CPAN-FindDependencies-1.1',
           nowarnings  => 1,
           perl        => 5.008008,
           maxdepth    => 1,
           recommended => 1
       )
    },
    {
            'HTTP::Headers' => [1, 'G/GA/GAAS/libwww-perl-5.808.tar.gz',    1],
            'HTML::Tagset'  => [1, 'P/PE/PETDANCE/HTML-Tagset-3.20.tar.gz', 0],
            'HTML::Parser'  => [0, 'G/GA/GAAS/HTML-Parser-3.60.tar.gz',     0],
            'Module::Build' => [1, 'K/KW/KWILLIAMS/Module-Build-0.2808.tar.gz', 0]
    },
    "recommended flag works"
);


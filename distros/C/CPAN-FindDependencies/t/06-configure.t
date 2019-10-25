#!perl -w
# $Id$
use strict;

use Test::More;
plan tests => 1;

use CPAN::FindDependencies 'finddeps';

is_deeply(
    {
     map {
         $_->name() => [$_->depth(), $_->distribution(), $_->warning() ? 1 : 0]
       }
       finddeps(
               'HTML::Parser',
               '02packages' =>
                 't/cache/CPAN-FindDependencies-1.1/02packages.details.txt.gz',
               cachedir    => 't/cache/CPAN-FindDependencies-1.1',
               nowarnings  => 1,
               perl        => 5.008008,
               maxdepth    => 1,
               configreqs   => 1
       )
    },
    {
            'HTML::Tagset'  => [1, 'P/PE/PETDANCE/HTML-Tagset-3.20.tar.gz', 0],
            'HTML::Parser'  => [0, 'G/GA/GAAS/HTML-Parser-3.60.tar.gz',     0],
            'Module::Build' => [1, 'K/KW/KWILLIAMS/Module-Build-0.2808.tar.gz',    0],
    },
    "configure flag works"
);


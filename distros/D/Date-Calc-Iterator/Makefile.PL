# $Id: Makefile.PL,v 1.1 2004/03/17 19:18:11 bronto Exp $

use 5.006;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my @REQUIRES = (
    'strict'     => 0,
    'warnings'   => 0,
    'Date::Calc' => 0,
    'Ref::Util'  => 0.202,
    'Carp'       => 0,
);

my @TEST_REQUIRES = (
    'Test::More'    => 0.88,
);

push(@REQUIRES, @TEST_REQUIRES) if $mm_ver < 6.64;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'Date::Calc::Iterator',
    'VERSION_FROM'  => 'lib/Date/Calc/Iterator.pm', # finds $VERSION
    ABSTRACT_FROM   => 'lib/Date/Calc/Iterator.pm', # retrieve abstract from module
    AUTHOR          => 'Marco Marongiu <bronto@cpan.org>',
    'PREREQ_PM'     => { @REQUIRES },

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => { @TEST_REQUIRES })
        : ()
    ),

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl')
        : ()
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
               'meta-spec' => { version => 2 },
               resources => {
                   repository  => {
                       type => 'git',
                       web  => 'https://github.com/brontolinux/date-calc-iterator',
                       url  => 'https://github.com/brontolinux/date-calc-iterator.git',
                   },
               },
          })
    ),

);

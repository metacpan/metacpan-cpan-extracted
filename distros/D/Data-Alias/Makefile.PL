use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use Config;

my %fussy_OS = (
	MSWin32	=> "Win32",
	aix	=> "AIX",
);

$fussy_OS{$^O}  and $] < 5.008009  and die "ERROR:  [OS unsupported]  " .
	"Data::Alias on $fussy_OS{$^O} requires perl 5.8.9 or later.\n";

die "ERROR: Data::Alias does not support old 5.005-style threads\n"
	if $Config{use5005threads};

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

my @REQUIRES = (
    'strict'    => 0,
    'warnings'  => 0,
    'Exporter'  => 0,
    'vars'      => 0,
    'Carp'      => 0,
);

my @TEST_REQUIRES = (
    'Test::More'    => 0.88,
);

push(@REQUIRES, @TEST_REQUIRES) if $mm_ver < 6.64;

WriteMakefile(
    NAME            => "Data::Alias",
    ABSTRACT        => 'Comprehensive set of aliasing operations',
    VERSION_FROM    => "lib/Data/Alias.pm",

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl')
        : ()
    ),

    PREREQ_PM       => { @REQUIRES },

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => { @TEST_REQUIRES })
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
                bugtracker  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Alias',
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/mvduin/perl-Data-Alias',
                    url  => 'https://github.com/mvduin/perl-Data-Alias.git',
                },
            },
          })
    ),

);


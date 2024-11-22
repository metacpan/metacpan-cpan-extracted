#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS  = 1;

install_share dist => "share";

WriteMakefile(
    NAME               => 'Chart::ECharts',
    AUTHOR             => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    VERSION_FROM       => 'lib/Chart/ECharts.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.010,
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0', 'File::ShareDir::Install' => '0.13'},
    TEST_REQUIRES      => {'Test::More'          => '0', 'JSON::PP'                => '0'},
    PREREQ_PM          => {'List::Util'          => '0', 'JSON::PP'                => '0', 'File::ShareDir' => '1.114'},
    META_MERGE         => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-Chart-ECharts/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-Chart-ECharts',
                web  => 'https://github.com/giterlizzi/perl-Chart-ECharts'
            },
        },
        x_purl => 'pkg:cpan/GDT/Chart-ECharts'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'Chart-ECharts-*'},
);

package MY;
use File::ShareDir::Install 'postamble';

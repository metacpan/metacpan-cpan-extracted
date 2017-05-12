use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
    NAME                => 'Dancer::Plugin::DirectoryView',
    AUTHOR              => q{Michal Wojciechowski <odyniec@cpan.org>},
    VERSION_FROM        => 'lib/Dancer/Plugin/DirectoryView.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/DirectoryView.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    CONFIGURE_REQUIRES => {
        'File::ShareDir::Install'   => 0,
    },
    PREREQ_PM => {
        'Dancer'     => 1.3070,
        'File::ShareDir'    => 1.0,
        'HTTP::Date'    => 0,
        'Test::More' => 0,
        'URI::Escape' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-DirectoryView-*' },
);

package MY;
use File::ShareDir::Install qw(postamble);
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefile_params = (
    'NAME'          => 'Clone',
    'AUTHOR'        => 'Ray Finch <rdf@cpan.org>',
    'VERSION_FROM'  => 'Clone.pm',
    'ABSTRACT_FROM' => 'Clone.pm',
    'LICENSE'       => 'perl_5',
    'PL_FILES'      => {},
    'TEST_REQUIRES' => {
      'Test::More' => '0.88',
      'B::COW'     => '0.004',
    },
    'LIBS'          => [''],     # e.g., '-lm'
    'DEFINE'        => '',       # e.g., '-DHAVE_SOMETHING'
    'INC'           => '',       # e.g., '-I/usr/include/other'
#   'OPTIMIZE'      => '-g',     # e.g., '-I/usr/include/other'
    'OPTIMIZE'      => '-O3',    # e.g., '-I/usr/include/other'
    clean           => { FILES => '_Inline' },
    META_MERGE      => {
      resources => {
        license    => 'http://dev.perl.org/licenses/',
        bugtracker => 'https://github.com/garu/Clone/issues',
        repository => 'http://github.com/garu/Clone',
      },
    },
);

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

$WriteMakefile_params{BUILD_REQUIRES} = {
  %{delete $WriteMakefile_params{TEST_REQUIRES} || {} },
  %{delete $WriteMakefile_params{BUILD_REQUIRES} || {} },
} if $EUMM_VERSION < 6.63_03;

$WriteMakefile_params{PREREQ_PM} = {
  %{delete $WriteMakefile_params{TEST_REQUIRES} || {} },
  %{delete $WriteMakefile_params{PREREQ_PM} || {} },
} if $EUMM_VERSION < 6.55_01;

WriteMakefile(%WriteMakefile_params);

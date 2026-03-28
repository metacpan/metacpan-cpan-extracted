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
        license    => 'https://dev.perl.org/licenses/',
        bugtracker => 'https://github.com/garu/Clone/issues',
        repository => 'https://github.com/garu/Clone',
      },
    },
    # Prevent macOS extended attributes (com.apple.provenance, etc.) from
    # being embedded in the distribution tarball.
    # - COPYFILE_DISABLE=1 stops macOS tar from adding ._AppleDouble sidecar files.
    # - PREOP strips any xattrs already set on the dist directory files (e.g.
    #   com.apple.provenance set by macOS on git-cloned files) before tar runs.
    #   xattr(1) is macOS-specific; the "|| true" makes it a no-op elsewhere.
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
        TAR      => 'COPYFILE_DISABLE=1 TAR_OPTIONS="--no-xattrs --no-acls" gtar',
        PREOP    => 'command -v xattr >/dev/null 2>&1 && xattr -cr $(DISTVNAME) || true',
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

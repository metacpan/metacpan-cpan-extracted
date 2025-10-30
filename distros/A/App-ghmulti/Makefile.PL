use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use File::Spec::Functions;
use autodie;

my $The_Module = 'App::ghmulti';
my $PM_File = catfile('lib', split(/::/, "$The_Module.pm"));
my $Git_URL = 'https://github.com/klaus-rindfrey/perl-' . join('-', split(/::/, lc($The_Module)));

my $Version;
open(my $h, '<', $PM_File);
foreach my $line (<$h>) {
  if ($line =~ /\bour\s+\$VERSION\s+.*?["']([^"']+)["']/) {
    $Version = $1;
    last;
  }
}
close($h);
die("VERSION not found in $PM_File") if !$Version;

my $meta_merge_supported = eval { ExtUtils::MakeMaker->VERSION(6.46) };

# PREREQ_PM
my %runtime_requires = (
                        'strict'                        => '0',
                        'warnings'                      => '0',
                        'Carp'                          => '0',
                        'Getopt::Std'                   => '0',
                        'Git::RemoteURL::Parse'         => '0.02',
                        'GitHub::Config::SSH::UserData' => '0.01',
                        'Pod::Usage'                    => '0',
                       );

# TEST_REQUIRES
my %test_requires = (
                     'strict'                => '0',
                     'warnings'              => '0',
                     'Capture::Tiny'         => '0.47',
                     'File::Basename'        => '0',
                     'File::Spec::Functions' => '0',
                     'Test::More'            => '0',
                    );

# CONFIGURE_REQUIRES
my %prereq_build = (
                    'autodie'               => '0',
                    'strict'                => '0',
                    'warnings'              => '0',
                    'ExtUtils::MakeMaker'   => '6.42',
                    'File::Spec::Functions' => '0',
                   );

# Added to %test_requires if needed
my %authortest_requires = (
                           'Capture::Tiny'         => '0.47',
                           'Cwd'                   => '0',
                           'File::Basename'        => '0',
                           'File::Spec::Functions' => '0',
                           'File::Temp'            => '0',
                           'File::chdir'           => '0.1011',
                           'Pod::Wordlist'         => '1.27',
                           'Test::CheckManifest'   => '1.43',
                           'Test::More'            => '0',
                           'Test::Pod'             => '1.51',
                           'Test::Spelling'        => '0.25',
                          );

if ($ENV{TEST_AUTHOR}) {
  print "Author tests enabled (TEST_AUTHOR=1)\n";
  %test_requires = (%test_requires,  %authortest_requires);
}

my %WriteMakefileArgs =
  (
   NAME               => $The_Module,
   AUTHOR             => q{Klaus Rindfrey <klausrin@cpan.org.eu>},
   VERSION_FROM       => $PM_File,
   ABSTRACT_FROM      => $PM_File,
   EXE_FILES          => [catfile('script', (split(/::/, $The_Module))[1])],
   LICENSE            => 'perl_5',
   MIN_PERL_VERSION   => '5.010',
   TEST_REQUIRES      => \%test_requires,
   PREREQ_PM          => \%runtime_requires,
   CONFIGURE_REQUIRES => \%prereq_build,
   dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   clean => { FILES => join('-', split(/::/, $The_Module)) . '-*' },
  );




if ($meta_merge_supported) {
  $WriteMakefileArgs{META_MERGE} =
    {
     "meta-spec" => { version => 2 },
     dynamic_config => 0,
     resources => {
                   repository => {
                                  type => 'git',
                                  url  => "$Git_URL.git",
                                  web  => "$Git_URL.git",
                                 },
                  },
     bugtracker => {
                    web => "$Git_URL/issues"
                   },
     provides => { $The_Module => { file => $PM_File, version => $Version },
                 },
     prereqs => {
                 runtime => { requires => \%runtime_requires },
                 test    => { requires => \%test_requires },
                 build   => { requires => \%prereq_build },
                },
    };
}

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
  my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
  @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

# unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
#   my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
#   @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
# }


delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
  unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{META_MERGE}
  unless eval { ExtUtils::MakeMaker->VERSION('6.46'); 1 };
delete $WriteMakefileArgs{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);


sub MY::postamble {
  return "
clean_all: clean
\trm -f MANIFEST README

README.md: $PM_File
\tpod2markdown $PM_File > README.md

README: $PM_File
\tpod2text $PM_File > README

all :: README

#manifest : README

policy-files:
\tdist-policyfiles -m $The_Module -l klaus-rindfrey -p perl- -u \\
        -s 'timeframe=10 days;perl_support_years=10'
";
}

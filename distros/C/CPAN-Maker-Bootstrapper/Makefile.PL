use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

$File::ShareDir::Install::INCLUDE_DOTFILES = 1;

if ( -d 'share' ) {
  install_share 'share';
}

WriteMakefile(
  NAME             => 'CPAN::Maker::Bootstrapper',
  MIN_PERL_VERSION => '5.010',
  AUTHOR           => 'Rob Lauer <rclauer@gmail.com>',
  VERSION_FROM     => 'lib/CPAN/Maker/Bootstrapper.pm',
  ABSTRACT         => 'CPAN::Maker::Bootstrapper',
  LICENSE          => 'perl',
  PL_FILES         =>     {}
,
  EXE_FILES        =>     [
      'bin/cmb',
      'bin/cpan-maker-bootstrapper',
      'bin/bootstrapper'
    ]
,
  MAN1PODS         =>     {}
,
  PREREQ_PM        => {
      'CLI::Simple' => '2.2.1',
      'CLI::Simple::Constants' => '2.2.1',
      'CLI::Simple::Utils' => '2.2.1',
      'Class::Accessor::Fast' => '0.51',
      'Config::Tiny' => '2.30',
      'Email::Valid' => '1.204',
      'File::Copy::Recursive' => '0.45',
      'File::HomeDir' => '1.006',
      'File::ShareDir' => '1.118',
      'IO::Interactive' => '1.027',
      'IO::Scalar' => '2.113',
      'JSON' => '4.10',
      'Log::Log4perl' => '0',
      'Module::Metadata' => '1.000038',
      'Module::ScanDeps::Static' => '1.9.3',
      'Pod::Extract' => '1.0.2',
      'Readonly' => '2.05',
      'Role::Tiny' => '2.002004',
      'Role::Tiny::With' => '2.002004',
      'Text::ASCIITable' => '0.22',
      'YAML::Tiny' => '1.76'
    },
  BUILD_REQUIRES   => {
    'ExtUtils::MakeMaker'     => '6.64',
    'File::ShareDir::Install' => 0,
    },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker'     => '6.64',
    'File::ShareDir::Install' => 0,
    },
  TEST_REQUIRES => {},
  META_MERGE =>    {
      'meta-spec'=>{
                       'version'=>2
                     },
      'prereqs'=>{
                     'runtime'=>{
                                    'suggests'=>{
                                                    'Git::Raw'=>'0.90',
                                                    'LLM::API'=>'1.0.1',
                                                    'Perl::Critic'=>'1.156',
                                                    'Term::ANSI::Color'=>'0'
                                                  }
                                  }
                   },
      'provides'=>{
                      'CPAN::Maker::Bootstrapper'=>{
                                                       'file'=>'lib/CPAN/Maker/Bootstrapper.pm',
                                                       'version'=>'2.2.3'
                                                     },
                      'CPAN::Maker::Bootstrapper::ConfigReader'=>{
                                                                     'file'=>'lib/CPAN/Maker/Bootstrapper/ConfigReader.pm',
                                                                     'version'=>'undef'
                                                                   },
                      'CPAN::Maker::Bootstrapper::Constants'=>{
                                                                  'file'=>'lib/CPAN/Maker/Bootstrapper/Constants.pm',
                                                                  'version'=>'undef'
                                                                },
                      'CPAN::Maker::Bootstrapper::Role::CreateConfig'=>{
                                                                           'file'=>'lib/CPAN/Maker/Bootstrapper/Role/CreateConfig.pm',
                                                                           'version'=>'undef'
                                                                         },
                      'CPAN::Maker::Bootstrapper::Role::CreateDeps'=>{
                                                                         'file'=>'lib/CPAN/Maker/Bootstrapper/Role/CreateDeps.pm',
                                                                         'version'=>'undef'
                                                                       },
                      'CPAN::Maker::Bootstrapper::Role::Critic'=>{
                                                                     'file'=>'lib/CPAN/Maker/Bootstrapper/Role/Critic.pm',
                                                                     'version'=>'undef'
                                                                   },
                      'CPAN::Maker::Bootstrapper::Role::ExtraFiles'=>{
                                                                         'file'=>'lib/CPAN/Maker/Bootstrapper/Role/ExtraFiles.pm',
                                                                         'version'=>'undef'
                                                                       },
                      'CPAN::Maker::Bootstrapper::Role::Filter'=>{
                                                                     'file'=>'lib/CPAN/Maker/Bootstrapper/Role/Filter.pm',
                                                                     'version'=>'undef'
                                                                   },
                      'CPAN::Maker::Bootstrapper::Role::Init'=>{
                                                                   'file'=>'lib/CPAN/Maker/Bootstrapper/Role/Init.pm',
                                                                   'version'=>'undef'
                                                                 },
                      'CPAN::Maker::Bootstrapper::Role::Installer'=>{
                                                                        'file'=>'lib/CPAN/Maker/Bootstrapper/Role/Installer.pm',
                                                                        'version'=>'2.2.3'
                                                                      },
                      'CPAN::Maker::Bootstrapper::Role::LLM::Annotator'=>{
                                                                             'file'=>'lib/CPAN/Maker/Bootstrapper/Role/LLM/Annotator.pm',
                                                                             'version'=>'undef'
                                                                           },
                      'CPAN::Maker::Bootstrapper::Role::LLM::Models'=>{
                                                                          'file'=>'lib/CPAN/Maker/Bootstrapper/Role/LLM/Models.pm',
                                                                          'version'=>'undef'
                                                                        },
                      'CPAN::Maker::Bootstrapper::Role::LLM::ReleaseNotes'=>{
                                                                                'file'=>'lib/CPAN/Maker/Bootstrapper/Role/LLM/ReleaseNotes.pm',
                                                                                'version'=>'undef'
                                                                              },
                      'CPAN::Maker::Bootstrapper::Role::LLM::Reviewer'=>{
                                                                            'file'=>'lib/CPAN/Maker/Bootstrapper/Role/LLM/Reviewer.pm',
                                                                            'version'=>'undef'
                                                                          },
                      'CPAN::Maker::Bootstrapper::Role::LLM::Utils'=>{
                                                                         'file'=>'lib/CPAN/Maker/Bootstrapper/Role/LLM/Utils.pm',
                                                                         'version'=>'undef'
                                                                       },
                      'CPAN::Maker::Bootstrapper::Role::ResolveVars'=>{
                                                                          'file'=>'lib/CPAN/Maker/Bootstrapper/Role/ResolveVars.pm',
                                                                          'version'=>'undef'
                                                                        },
                      'CPAN::Maker::Bootstrapper::Role::ScaffoldImporter'=>{
                                                                               'file'=>'lib/CPAN/Maker/Bootstrapper/Role/ScaffoldImporter.pm',
                                                                               'version'=>'undef'
                                                                             },
                      'Git::ReleaseDiffs'=>{
                                               'file'=>'lib/Git/ReleaseDiffs.pm',
                                               'version'=>'undef'
                                             },
                      'Text::ASCIITable::FixANSI'=>{
                                                       'file'=>'lib/Text/ASCIITable/FixANSI.pm',
                                                       'version'=>'1.0.0'
                                                     }
                    },
      'resources'=>{
                       'bugtracker'=>{
                                         'mailto'=>'rclauer@gmail.com',
                                         'web'=>'http://github.com/rlauer6/CPAN-Maker-Bootstrapper/issues'
                                       },
                       'homepage'=>'http://github.com/rlauer6/CPAN-Maker-Bootstrapper',
                       'repository'=>{
                                         'type'=>'git',
                                         'url'=>'git://github.com/rlauer6/CPAN-Maker-Bootstrapper.git',
                                         'web'=>'http://github.com/rlauer6/CPAN-Maker-Bootstrapper'
                                       }
                     }
    }

);
package MY;

use File::ShareDir::Install;
use English qw(-no_match_vars);

sub postamble {
  my $self = shift;

  my @ret = File::ShareDir::Install::postamble($self);

  my $postamble = join "\n", @ret;

  if ( -e 'postamble' ) {

    local $RS = undef;

    open my $fh, '<', 'postamble'
      or die "could not open postamble\n";

    $postamble .= <$fh>;

    close $fh;
  }

  return $postamble;
}

1;

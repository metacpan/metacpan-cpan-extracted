use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

$File::ShareDir::Install::INCLUDE_DOTFILES = 1;

if ( -d 'share' ) {
  install_share 'share';
}

WriteMakefile(
  NAME             => 'Config::Resolver',
  MIN_PERL_VERSION => '5.010',
  AUTHOR           => 'Rob Lauer <rclauer@gmail.com>',
  VERSION_FROM     => 'lib/Config/Resolver.pm',
  ABSTRACT         => 'Config::Resolver',
  LICENSE          => 'perl',
  PL_FILES         =>     {}
,
  EXE_FILES        =>     [
      'bin/config-resolver'
    ]
,
  MAN1PODS         =>     {}
,
  PREREQ_PM        => {
      'CLI::Simple' => '1.0.9',
      'Class::Accessor::Fast' => '0.51',
      'Config::INI::Tiny' => '0.106',
      'JSON' => '4.10',
      'Log::Log4perl' => '0',
      'Query::Param' => '0.02',
      'Readonly' => '2.05',
      'YAML::Tiny' => '1.76'
    },
  BUILD_REQUIRES   => {
      'ExtUtils::MakeMaker' => '6.64',
      'File::ShareDir::Install' => 0
    },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker'     => '6.64',
    'File::ShareDir::Install' => 0,
    },
  TEST_REQUIRES => {
      'IO::Scalar' => '2.113',
      'IO::String' => '1.08',
      'JSON' => '4.10',
      'Test::Warn' => '0.37',
      'YAML::Tiny' => '1.76'
    },
  META_MERGE =>    {
      'meta-spec'=>{
                       'version'=>2
                     },
      'provides'=>{
                      'Config::Resolver'=>{
                                              'file'=>'lib/Config/Resolver.pm',
                                              'version'=>'1.0.12'
                                            },
                      'Config::Resolver::CLI'=>{
                                                   'file'=>'lib/Config/Resolver/CLI.pm',
                                                   'version'=>'1.0.12'
                                                 },
                      'Config::Resolver::Utils'=>{
                                                     'file'=>'lib/Config/Resolver/Utils.pm',
                                                     'version'=>'1.0.12'
                                                   }
                    },
      'resources'=>{
                       'bugtracker'=>{
                                         'mailto'=>'rclauer@gmail.com',
                                         'web'=>'http://github.com/rlauer6/Config-Resolver/issues'
                                       },
                       'homepage'=>'http://github.com/rlauer6/Config-Resolver.git',
                       'repository'=>{
                                         'type'=>'git',
                                         'url'=>'git://github.com/rlauer6/Config-Resolver.git',
                                         'web'=>'http://github.com/rlauer6/Config-Resolver'
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

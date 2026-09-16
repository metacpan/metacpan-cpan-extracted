use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

$File::ShareDir::Install::INCLUDE_DOTFILES = 1;

if ( -d 'share' ) {
  install_share 'share';
}

WriteMakefile(
  NAME             => 'DarkPAN::Indexer',
  MIN_PERL_VERSION => '5.010',
  AUTHOR           => 'Rob Lauer <rclauer@gmail.com>',
  VERSION_FROM     => 'lib/DarkPAN/Indexer.pm',
  ABSTRACT         => 'DarkPAN::Indexer',
  LICENSE          => 'perl',
  PL_FILES         =>     {}
,
  EXE_FILES        =>     [
      'bin/darkpan-indexer'
    ]
,
  MAN1PODS         =>     {}
,
  PREREQ_PM        => {
      'Amazon::Credentials' => '2.0.0',
      'Amazon::S3::Lite' => '1.3.0',
      'Amazon::S3::Lite::Lock' => '0',
      'CLI::Simple' => '2.2.2',
      'CLI::Simple::Constants' => '2.2.2',
      'CLI::Simple::Utils' => '2.2.2',
      'Class::Accessor::Fast' => '0.51',
      'DBD::SQLite' => '0',
      'DBI' => '1.647',
      'Dist::Metadata' => '0',
      'JSON' => '4.10',
      'Role::Tiny' => '2.002004',
      'Role::Tiny::With' => '2.002004'
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
      'JSON' => '4.10',
      'Path::Tiny' => '0.150',
      'Test::Output' => '1.036'
    },
  META_MERGE =>    {
      'meta-spec'=>{
                       'version'=>2
                     },
      'prereqs'=>{
                     'runtime'=>{
                                    'suggests'=>{
                                                    'YAML::Tiny'=>'1.76'
                                                  }
                                  }
                   },
      'provides'=>{
                      'DarkPAN::Indexer'=>{
                                              'file'=>'lib/DarkPAN/Indexer.pm',
                                              'version'=>'1.0.2'
                                            },
                      'DarkPAN::Indexer::CLI'=>{
                                                   'file'=>'lib/DarkPAN/Indexer/CLI.pm',
                                                   'version'=>'1.0.2'
                                                 },
                      'DarkPAN::Indexer::Format'=>{
                                                      'file'=>'lib/DarkPAN/Indexer/Format.pm',
                                                      'version'=>'undef'
                                                    },
                      'DarkPAN::Indexer::Format::SQLite'=>{
                                                              'file'=>'lib/DarkPAN/Indexer/Format/SQLite.pm',
                                                              'version'=>'undef'
                                                            },
                      'DarkPAN::Indexer::Storage'=>{
                                                       'file'=>'lib/DarkPAN/Indexer/Storage.pm',
                                                       'version'=>'undef'
                                                     },
                      'DarkPAN::Indexer::Storage::Filesystem'=>{
                                                                   'file'=>'lib/DarkPAN/Indexer/Storage/Filesystem.pm',
                                                                   'version'=>'undef'
                                                                 },
                      'DarkPAN::Indexer::Storage::S3'=>{
                                                           'file'=>'lib/DarkPAN/Indexer/Storage/S3.pm',
                                                           'version'=>'undef'
                                                         }
                    },
      'resources'=>{
                       'bugtracker'=>{
                                         'mailto'=>'rclauer@gmail.com',
                                         'web'=>'https://github.com/rlauer6/DarkPAN-Indexer/issues'
                                       },
                       'homepage'=>'https://github.com/rlauer6/DarkPAN-Indexer',
                       'repository'=>{
                                         'type'=>'git',
                                         'url'=>'git@github.com:rlauer6/DarkPAN-Indexer.git',
                                         'web'=>'https://github.com/rlauer6/DarkPAN-Indexer'
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

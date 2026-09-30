use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

$File::ShareDir::Install::INCLUDE_DOTFILES = 1;

if ( -d 'share' ) {
  install_share 'share';
}

WriteMakefile(
  NAME             => 'DarkPAN::Resolver::SQLite',
  MIN_PERL_VERSION => '5.010',
  AUTHOR           => 'Rob Lauer <rclauer@gmail.com>',
  VERSION_FROM     => 'lib/DarkPAN/Resolver/SQLite.pm',
  ABSTRACT         => 'DarkPAN::Resolver::SQLite',
  LICENSE          => 'perl',
  PL_FILES         =>     {}
,
  EXE_FILES        =>     []
,
  MAN1PODS         =>     {}
,
  PREREQ_PM        => {
      'App::cpm::DistNotation' => '0',
      'App::cpm::version' => '0',
      'DBD::SQLite' => '0',
      'DBI' => '1.647',
      'HTTP::Tiny' => '0.088'
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
      'DBI' => '1.647'
    },
  META_MERGE =>    {
      'meta-spec'=>{
                       'version'=>2
                     },
      'provides'=>{
                      'DarkPAN::Resolver::SQLite'=>{
                                                       'file'=>'lib/DarkPAN/Resolver/SQLite.pm',
                                                       'version'=>'1.0.2'
                                                     }
                    },
      'resources'=>{
                       'bugtracker'=>{
                                         'mailto'=>'rclauer@gmail.com',
                                         'web'=>'https://github.com/rlauer6/DarkPAN-Resolver-SQLite/issues'
                                       },
                       'homepage'=>'https://github.com/rlauer6/DarkPAN-Resolver-SQLite',
                       'repository'=>{
                                         'type'=>'git',
                                         'url'=>'git@github.com:rlauer6/DarkPAN-Resolver-SQLite.git',
                                         'web'=>'https://github.com/rlauer6/DarkPAN-Resolver-SQLite'
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

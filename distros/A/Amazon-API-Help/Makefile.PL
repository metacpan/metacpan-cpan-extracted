use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

$File::ShareDir::Install::INCLUDE_DOTFILES = 1;

if ( -d 'share' ) {
  install_share 'share';
}

WriteMakefile(
  NAME             => 'Amazon::API::Help',
  MIN_PERL_VERSION => '5.010',
  AUTHOR           => 'Rob Lauer <rclauer@gmail.com>',
  VERSION_FROM     => 'lib/Amazon/API/Help.pm',
  ABSTRACT         => 'Amazon::API::Help',
  LICENSE          => 'perl',
  PL_FILES         =>     {}
,
  EXE_FILES        =>     [
      'bin/amzn-api-help'
    ]
,
  MAN1PODS         =>     {}
,
  PREREQ_PM        => {
      'Amazon::API::BuildInfo' => '2.6.0',
      'CLI::Simple' => '2.2.1',
      'CLI::Simple::Constants' => '2.2.1',
      'CLI::Simple::Utils' => '2.2.1',
      'File::ShareDir' => '1.118',
      'Pod::HTML2Pod' => '4.05',
      'Template' => '3.102',
      'Text::ASCIITable' => '0.22'
    },
  BUILD_REQUIRES   => {
      'ExtUtils::MakeMaker' => '6.64',
      'File::ShareDir::Install' => 0
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
                                                    'IO::Pager'=>'2.10'
                                                  }
                                  }
                   },
      'provides'=>{
                      'Amazon::API::Help'=>{
                                               'file'=>'lib/Amazon/API/Help.pm',
                                               'version'=>'1.0.3'
                                             }
                    },
      'resources'=>{
                       'bugtracker'=>{
                                         'mailto'=>'rclauer@gmail.com',
                                         'web'=>'https://github.com/rlauer6/Amazon-API-Help/issues'
                                       },
                       'homepage'=>'https://github.com/rlauer6/Amazon-API-Help',
                       'repository'=>{
                                         'type'=>'git',
                                         'url'=>'git@github.com:rlauer6/Amazon-API-Help.git',
                                         'web'=>'https://github.com/rlauer6/Amazon-API-Help'
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

use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

$File::ShareDir::Install::INCLUDE_DOTFILES = 1;

if ( -d 'share' ) {
  install_share 'share';
}

WriteMakefile(
  NAME             => 'Amazon::S3::Lite',
  MIN_PERL_VERSION => '5.010',
  AUTHOR           => 'Rob Lauer <rlauer@treasurersbriefcase.com>',
  VERSION_FROM     => 'lib/Amazon/S3/Lite.pm',
  ABSTRACT         => 'Amazon::S3::Lite',
  LICENSE          => 'perl',
  PL_FILES         =>     {}
,
  EXE_FILES        =>     []
,
  MAN1PODS         =>     {}
,
  PREREQ_PM        => {
      'Amazon::Signature4::Lite' => '1.0.0',
      'Carp::Always' => '0.16',
      'HTTP::Tiny' => '0.088',
      'IO::Socket::SSL' => '0',
      'JSON::PP' => '4.16',
      'List::Util' => '0',
      'Net::SSLeay' => '0',
      'Readonly' => '2.05',
      'Role::Tiny' => '2.002004',
      'Role::Tiny::With' => '2.002004',
      'URI::Escape' => '5.34',
      'XML::Twig' => '0'
    },
  BUILD_REQUIRES   => {
    'ExtUtils::MakeMaker'     => '6.64',
    'File::ShareDir::Install' => 0,
    },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker'     => '6.64',
    'File::ShareDir::Install' => 0,
    },
  TEST_REQUIRES => {
      'HTTP::Tiny' => '0',
      'IO::Scalar' => '0',
      'JSON::PP' => '4.16'
    },
  META_MERGE =>    {
      'meta-spec'=>{
                       'version'=>2
                     },
      'prereqs'=>{
                     'runtime'=>{
                                    'suggests'=>{
                                                    'Amazon::Credentials'=>'1.3.0',
                                                    'Log::Log4perl'=>'1.57'
                                                  }
                                  }
                   },
      'provides'=>{
                      'Amazon::S3::Lite'=>{
                                              'file'=>'lib/Amazon/S3/Lite.pm',
                                              'version'=>'1.3.1'
                                            },
                      'Amazon::S3::Lite::Constants'=>{
                                                         'file'=>'lib/Amazon/S3/Lite/Constants.pm',
                                                         'version'=>'undef'
                                                       },
                      'Amazon::S3::Lite::Credentials'=>{
                                                           'file'=>'lib/Amazon/S3/Lite/Credentials.pm',
                                                           'version'=>'1.3.1'
                                                         },
                      'Amazon::S3::Lite::Logger'=>{
                                                      'file'=>'lib/Amazon/S3/Lite/Logger.pm',
                                                      'version'=>'1.3.1'
                                                    },
                      'Amazon::S3::Lite::Policies'=>{
                                                        'file'=>'lib/Amazon/S3/Lite/Policies.pm',
                                                        'version'=>'undef'
                                                      }
                    },
      'resources'=>{
                       'bugtracker'=>{
                                         'mailto'=>'rlauer@treasurersbriefcase.com',
                                         'web'=>'http://github.com/rlauer6/Amazon-S3-Lite/issues'
                                       },
                       'homepage'=>'http://github.com/rlauer6/Amazon-S3-Lite.git',
                       'repository'=>{
                                         'type'=>'git',
                                         'url'=>'git://github.com/rlauer6/Amazon-S3-Lite.git',
                                         'web'=>'http://github.com/rlauer6/Amazon-S3-Lite.git'
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

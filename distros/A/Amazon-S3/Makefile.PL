use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

$File::ShareDir::Install::INCLUDE_DOTFILES = 1;

if ( -d 'share' ) {
  install_share 'share';
}

WriteMakefile(
  NAME             => 'Amazon::S3',
  MIN_PERL_VERSION => '5.010',
  AUTHOR           => 'Rob Lauer <rclauer@gmail.com>',
  VERSION_FROM     => 'lib/Amazon/S3.pm',
  ABSTRACT         => 'Perl interface to AWS S3 API',
  LICENSE          => 'perl',
  PL_FILES         =>     {}
,
  EXE_FILES        =>     [
      'bin/amzn-s3-cli'
    ]
,
  MAN1PODS         =>     {}
,
  PREREQ_PM        => {
      'CLI::Simple' => '2.2.3',
      'CLI::Simple::Constants' => '2.2.3',
      'CLI::Simple::Utils' => '2.2.3',
      'Class::Accessor::Fast' => '0.51',
      'Digest::CRC' => '0.24',
      'Digest::HMAC_SHA1' => '1.05',
      'Digest::MD5::File' => '0.08',
      'HTTP::Date' => '6.08',
      'IO::Scalar' => '2.113',
      'JSON::PP' => '4.16',
      'LWP::Protocol::https' => '0',
      'LWP::UserAgent::Determined' => '1.07',
      'Net::Amazon::Signature::V4' => '0.22',
      'Readonly' => '2.05',
      'URI' => '5.37',
      'URI::Escape' => '5.37',
      'XML::Simple' => '2.25'
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
      'Carp::Always' => '0.16',
      'Digest::MD5::File' => '0.08',
      'HTTP::Headers' => '7.04',
      'HTTP::Response' => '7.04',
      'HTTP::Tiny' => '0.088',
      'JSON' => '4.11',
      'JSON::PP' => '4.16',
      'Readonly' => '2.05',
      'Test::Output' => '1.036',
      'XML::Simple' => '2.25'
    },
  META_MERGE =>    {
      'meta-spec'=>{
                       'version'=>2
                     },
      'prereqs'=>{
                     'runtime'=>{
                                    'suggests'=>{
                                                    'Amazon::Credentials'=>'2.0.0',
                                                    'Crypt::Blowfish'=>'2.14',
                                                    'Crypt::CBC'=>'3.07',
                                                    'File::MimeInfo::Magic'=>'0.37',
                                                    'Text::ASCIITable'=>'0.22'
                                                  }
                                  }
                   },
      'provides'=>{
                      'Amazon::S3'=>{
                                        'file'=>'lib/Amazon/S3.pm',
                                        'version'=>'2.1.1'
                                      },
                      'Amazon::S3::Bucket'=>{
                                                'file'=>'lib/Amazon/S3/Bucket.pm',
                                                'version'=>'2.1.1'
                                              },
                      'Amazon::S3::BucketV2'=>{
                                                  'file'=>'lib/Amazon/S3/BucketV2.pm',
                                                  'version'=>'2.1.1'
                                                },
                      'Amazon::S3::CLI'=>{
                                             'file'=>'lib/Amazon/S3/CLI.pm',
                                             'version'=>'undef'
                                           },
                      'Amazon::S3::Constants'=>{
                                                   'file'=>'lib/Amazon/S3/Constants.pm',
                                                   'version'=>'2.1.1'
                                                 },
                      'Amazon::S3::Logger'=>{
                                                'file'=>'lib/Amazon/S3/Logger.pm',
                                                'version'=>'2.1.1'
                                              },
                      'Amazon::S3::Signature::V4'=>{
                                                       'file'=>'lib/Amazon/S3/Signature/V4.pm',
                                                       'version'=>'2.1.1'
                                                     },
                      'Amazon::S3::Util'=>{
                                              'file'=>'lib/Amazon/S3/Util.pm',
                                              'version'=>'2.1.1'
                                            },
                      'Digest::CRC64NVME'=>{
                                               'file'=>'lib/Digest/CRC64NVME.pm',
                                               'version'=>'undef'
                                             }
                    },
      'resources'=>{
                       'bugtracker'=>{
                                         'mailto'=>'rclauer@gmail.com',
                                         'web'=>'https://github.com/rlauer6/Amazon-S3/issues'
                                       },
                       'homepage'=>'https://github.com/rlauer6/Amazon-S3',
                       'repository'=>{
                                         'type'=>'git',
                                         'url'=>'git@github.com:rlauer6/Amazon-S3.git',
                                         'web'=>'https://github.com/rlauer6/Amazon-S3'
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

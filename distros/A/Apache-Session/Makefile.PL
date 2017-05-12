use 5.005; #VERSION_FROM in Makefile.PL
#Symbol.pm requires 5.002
#5.004 almost 11 years ago, earliest version supported by perlver
#5.003_07 earliest version on CPAN

use ExtUtils::MakeMaker;

print << 'EOT';

*** REQUEST ***
Please use Test::Reporter to report test results - it's the only way to measure
popularity of distribution.

EOT

if ($]<5.006) {
  print << 'EOT1';
If you really use perl older than 5.6 - write to alexchorny[AT]gmail.com
and tell me what version do you use, and why.
EOT1
  prompt('continue','y');
}

WriteMakefile1(
    NAME         => "Apache::Session",
    VERSION_FROM => "lib/Apache/Session.pm",
    MIN_PERL_VERSION => 5.005,
    META_MERGE => {
      resources=> {
        repository => 'http://github.com/chorny/Apache-Session',
      },
      keywords => ['CGI','session','web'],
    },
    'LICENSE'		=> 'perl',
    PREREQ_PM    => {
                     'File::Temp'      => 0, #core from 5.6.1
                     'Storable'        => '0.6', #Will be raised later
                     'constant'        => 0, #Available on CPAN now
#                     'MIME::Base64'    => 0, #new versions require 5.6
#                     'DB_File'         => 0, #test
                     'Digest::MD5'     => 0, #core from 5.8
                     'IO::File'        => 0, #core
                    },
    BUILD_REQUIRES => {
                     'Test::More'      => '0.47', #Build
                     'Test::Deep'      => '0.082', #Build
                     'Test::Exception' => '0.15', #Build
    },
    AUTHOR          => 'Casey West <casey[at]geeknest.com>',
    ABSTRACT        => 'A persistence framework for session data',
    'PL_FILES' => {},
);

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
  my %params=@_;
  my $eumm_version=$ExtUtils::MakeMaker::VERSION;
  $eumm_version=eval $eumm_version;
  die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
  die "License not specified" if not exists $params{LICENSE};
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
    delete $params{BUILD_REQUIRES};
  }
  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
  delete $params{META_MERGE} if $eumm_version < 6.46;
  delete $params{META_ADD} if $eumm_version < 6.46;
  delete $params{LICENSE} if $eumm_version < 6.31;
  delete $params{AUTHOR} if $] < 5.005;
  delete $params{ABSTRACT_FROM} if $] < 5.005;
  delete $params{BINARY_LOCATION} if $] < 5.005;

  WriteMakefile(%params);
}


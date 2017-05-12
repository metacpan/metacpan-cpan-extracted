package Apache::AuthDigest::API::Session;

use ExtUtils::MakeMaker;
use Config;

use strict;

my %config;

$config{INC} = Apache::src->new->inc;

if ($^O =~ /Win32/) {
  require Apache::MyConfig;

  $config{DEFINE}  = ' -D_WINSOCK2API_ -D_MSWSOCK_ ';
  $config{DEFINE} .= ' -D_INC_SIGNAL -D_INC_MALLOC '
    if $Config{usemultiplicity};

  $config{LIBS} =
    qq{ -L"$Apache::MyConfig::Setup{APACHE_LIB}" -lApacheCore } .
    qq{ -L"$Apache::MyConfig::Setup{MODPERL_LIB}" -lmod_perl};
}

WriteMakefile(
  NAME         => 'Apache::AuthDigest::API::Multi',
  VERSION_FROM => 'Multi.pm',
  PREREQ_PM    => { mod_perl => 1.26,
                    'Digest::MD5' => 2.13, },
  ABSTRACT     => 'AuthDigest API subclass for multiple authentication',
  AUTHOR       => 'geoff@cpan.org',
  %config,
);

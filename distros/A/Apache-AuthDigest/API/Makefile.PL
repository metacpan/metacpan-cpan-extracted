#!perl

use ExtUtils::MakeMaker;
use Apache::src ();
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
  NAME         => 'Apache::AuthDigest::API',
  VERSION_FROM => 'API.pm',
  PREREQ_PM    => { mod_perl              => 1.26,
                    'Digest::MD5'         => 2.13,
                    'HTTP::Headers::Util' => 1.09, },
  ABSTRACT     => 'mod_perl API for Digest Authentication',
  AUTHOR       => 'geoff@cpan.org',
  %config,
);


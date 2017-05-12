package Apache::AuthDigest::API::Session;

use ExtUtils::MakeMaker;
use Apache::ExtUtils qw(command_table);
use Apache::src ();
use Config;

use strict;

my @directives = (
  { name         => 'DigestSessionKey',
    errmsg       => 'r->notes() key to use as nonce',
    args_how     => 'TAKE1',
    req_override => 'OR_ALL', },
);

command_table(\@directives);

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
  NAME         => 'Apache::AuthDigest::API::Session',
  VERSION_FROM => 'Session.pm',
  PREREQ_PM    => { mod_perl => 1.26,
                    'Digest::MD5' => 2.13, },
  ABSTRACT     => 'AuthDigest API subclass for sessions',
  AUTHOR       => 'geoff@cpan.org',
  clean        => { FILES => '*.xs*' },
  %config,
);

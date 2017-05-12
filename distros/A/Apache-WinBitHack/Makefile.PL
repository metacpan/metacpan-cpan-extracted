package Apache::WinBitHack;

use ExtUtils::MakeMaker;
use Apache::ExtUtils qw(command_table);
use Apache::src ();
use Config;

use strict;

warn "This module is really only useful on Win32.\n"
  unless ($^O =~ /Win32/);

my @directives = (
  { name         => 'XBitHack',
    errmsg       => 'Off, On, or Full',
    args_how     => 'TAKE1',
    req_override => 'OR_OPTIONS', },
);

command_table(\@directives);

my %config;

$config{INC} = Apache::src->new->inc;

if ($^O =~ m/Win32/) {
  require Apache::MyConfig;

  $config{DEFINE}  = ' -D_WINSOCK2API_ -D_MSWSOCK_ ';
  $config{DEFINE} .= ' -D_INC_SIGNAL -D_INC_MALLOC '
    if $Config{usemultiplicity};

  $config{LIBS} =
    qq{ -L"$Apache::MyConfig::Setup{APACHE_LIB}" -lApacheCore } .
    qq{ -L"$Apache::MyConfig::Setup{MODPERL_LIB}" -lmod_perl};
}

WriteMakefile(
  NAME           => 'Apache::WinBitHack',
  VERSION_FROM   => 'WinBitHack.pm',
  PREREQ_PM      => { mod_perl => 1.26_01 },
  ABSTRACT       => 'Apache module to emulate XBitHack on Win32',
  AUTHOR         => 'authors@modperlcookbook.org',
  clean          => { FILES => '*.xs*' },
  %config,
);

print <<"END";

If you get an error about a missing 'perl_perl_merge_dir_config'
symbol, please use the latest mod_perl sources from CVS - see
http://perl.apache.org/from-cvs/ for details.

END


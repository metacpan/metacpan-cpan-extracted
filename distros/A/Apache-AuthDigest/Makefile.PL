package Apache::AuthDigest;

use ExtUtils::MakeMaker;
use Apache::ExtUtils qw(command_table);
use Apache::src ();
use Config;

use strict;

my @directives = (
  { name         => 'AuthDigestFile',
    errmsg       => 'text file containing user IDs and passwords',
    args_how     => 'TAKE1',
    req_override => 'OR_AUTHCFG', },
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
  NAME         => 'Apache::AuthDigest',
  VERSION_FROM => 'AuthDigest.pm',
  PREREQ_PM    => { mod_perl              => 1.26,
                    'Digest::MD5'         => 2.13,
                    'HTTP::Headers::Util' => 1.09, },
  DIR          => [ qw(API Full Session Multi) ],
  ABSTRACT     => 'mod_perl Digest authentication suite',
  AUTHOR       => 'geoff@cpan.org',
  clean        => { FILES => '*.xs*' },
  %config,
);

sub MY::test {
  if (eval "require Apache::TestMM") {
    Apache::TestMM::generate_script('t/TEST');
    Apache::TestMM->import(qw(test clean));
    return Apache::TestMM->test;
  }

  # The whitespace in front of @echo MUST be a single tab!
  return <<'EOF';
test::
	@echo This test suite requires Apache::Test
	@echo available from the mod_perl 2.0 sources
	@echo or the httpd-test distribution.
EOF
}

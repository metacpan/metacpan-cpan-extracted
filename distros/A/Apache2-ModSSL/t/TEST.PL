#!perl

use strict;
use warnings FATAL => 'all';

use lib qw(lib);

BEGIN {$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME}=0}

use Apache::TestRunPerl ();

my $I=Apache::TestRunPerl->new;

my @argv=@ARGV;			# save
Apache::TestConfig::autoconfig_skip_module_add('mod_proxy_html.c');

$I->run(@ARGV);

@ARGV=@argv;			# restore
Apache::TestConfig::autoconfig_skip_module_add('mod_ssl.c');
Apache::TestConfig::autoconfig_skip_module_add('mod_proxy_html.c');
$I->refresh;

$I->run(@ARGV);

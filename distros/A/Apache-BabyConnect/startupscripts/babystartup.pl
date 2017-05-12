use strict;

$ENV{MOD_PERL} or die "not running under mod_perl!";

# Set up the ENV for BABYCONNECT in the perl.conf just before requiring the babystartup.pl as follow:
#   PerlSetEnv BABYCONNECT /opt/DBI-BabyConnect/configuration
#   PerlRequire /opt/Apache-BabyConnect/startupscripts/babystartup.pl
#
# alternatively you can uncomment the line below:
#BEGIN { $ENV{BABYCONNECT} = '/opt/DBI-BabyConnect/configuration'; }

use ModPerl::Registry ();
use LWP::UserAgent ();

use Apache::BabyConnect ();

use Carp ();
$SIG{__WARN__} = \&Carp::cluck;

$Apache::BabyConnect::DEBUG = 2;

#ATTENTION: this is only a sample example to test with Apache::BabyConnect,
#  in production environment, do not enable logging and tracing. To do so
#  just call connect_on_init() with the database descriptor only. For example:
#Apache::BabyConnect->connect_on_init(DESCRIPTOR=>'BABYDB_001');

Apache::BabyConnect->connect_on_init(
	DESCRIPTOR => 'BABYDB_001',
	ERROR_FILE => '/var/www/htdocs/logs/error_BABYDB_001.log',
	TRACE_FILE => '/var/www/htdocs/logs/db_BABYDB_001.log',
	TRACE_LEVEL => 2
);

Apache::BabyConnect->connect_on_init(
	DESCRIPTOR =>'BABYDB_002',
	ERROR_FILE => '/var/www/htdocs/logs/error_BABYDB_002.log',
	TRACE_FILE => '/var/www/htdocs/logs/db_BABYDB_002.log',
	TRACE_LEVEL => 2
);

Apache::BabyConnect->connect_on_init(
	DESCRIPTOR => 'BABYDB_003',
	ERROR_FILE => '/var/www/htdocs/logs/error_BABYDB_003.log',
	TRACE_FILE => '/var/www/htdocs/logs/db_BABYDB_003.log',
	TRACE_LEVEL => 2
);

Apache::BabyConnect->connect_on_init(
	DESCRIPTOR => 'BABYDB_004',
	ERROR_FILE => '/var/www/htdocs/logs/error_BABYDB_004.log',
	TRACE_FILE => '/var/www/htdocs/logs/db_BABYDB_004.log',
	TRACE_LEVEL => 2
);

#http://perl.apache.org/docs/2.0/api/Apache2/ServerUtil.html
#Apache2::ServerUtil::server_shutdown_cleanup_register(\&do_my_cleanups);

1;

#This program is free software; you can redistribute it and/or modify
#it under the same terms as Perl itself, either Perl version 5.8.8 or,
#at your option, any later version of Perl 5 you may have available.


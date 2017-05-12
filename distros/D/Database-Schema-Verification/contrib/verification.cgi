#!/usr/bin/perl -w

use strict;
use warnings;

our $VERSION = '1.01';

use Config::Simple;
use Database::Schema::Verification;
use Database::Wrapper qw(:RETURN_TYPES :CONNECTION_TYPES);
use CGI qw(:standard escapeHTML);
use Net::IP;
use constant TABLE => 'verification';

# step 0: edit the ConnectionType => in accordance with Database::Wrapper
# step 1: create user "verify" in your database
# step 2: give write access to your verification table from the WEBSERVER ONLY! (no read access!!!)
# step 3: create config.ini in your application directory and point $config at it
# step 4: give read access to your webserver user (ie: apache,httpd,nobody) ONLY!
# step 5: add verification user to config.ini
# step 6: setup ssl for this server and or lock it down with .htaccess or other IP restrictions!

###############################
# change this and LOCK IT DOWN!
my $config = '../../config.ini';

sub _err {
	my $str = shift;
	print br(escapeHTML($str))."\n";
	print end_html()."\n";
	exit 0;
}

# start HTML
print header();
print start_html('Verification');

_err('missing vid') unless(param('vid'));
_err('missing verified_by') unless(param('verified_by'));
_err('missing action') unless(param('action'));


my $cfg = Config::Simple->new($config) || _err('unable to read config');

my $db = Database::Wrapper->new({
	ConnectionType 	=> CONNECTION_TYPE_MySQL,	# this part is stupid, working to fix it... it won't take a damn var
							# for now you have to edit this to connect to your database
	DatabaseName	=> $cfg->param('database'),
	User		=> $cfg->param('user'),
	Password	=> $cfg->param('password'),
	Host		=> $cfg->param('host'),
}) || _err('Database Error: '.$Database::Wrapper::ConnectionError);

my $table = $cfg->param('table');
$table = TABLE() if(!$table);

for(uc(param('action'))){
	my $v = Database::Schema::Verification->new(
			-dbh 		=> $db->{dbh},
			-vid 		=> param('vid'),
			-verified_by 	=> param('verified_by'),
			-verified_by_ip => $ENV{REMOTE_ADDR},
	);
	if(/^VERIFY$/){
		print '<script language=javascript>resizeTo(200,200);</script>'."\n";
		print br('Verifying id: ', escapeHTML(param('vid')))."\n";
		my ($err,$rv) = $v->verify(-action => 1);
		if($rv){
			print br('VERIFYED: '.escapeHTML(param('vid')))."\n";
			print br('VERIFYED BY: '.escapeHTML(param('verified_by')))."\n";
			print br('VERIFYED BY IP: '.escapeHTML($ENV{REMOTE_ADDR}))."\n";
		}
		else { print br('VERIFY Failed: '.escapeHTML($err)); }
		last;
	}
	if(/^SUPPRESS$/){
		print '<script language=javascript>resizeTo(200,200);</script>'."\n";
		print br('Suppressing id: ', tt(escapeHTML(param('vid'))))."\n";
		my ($err,$rv) = $v->verify(-action => 2);
		if($rv){ print br('SUPPRESSED: '.escapeHTML(param('vid'))); }
		else { print br('SUPPRESS Failed: '.escapeHTML($err)); }
		last;
	}
	if(/^UNDEFINE$/){
		print '<script language=javascript>resizeTo(200,200);</script>'."\n";
		print br('Undefining id: ', tt(escapeHTML(param('vid'))))."\n";
		my ($err,$rv) = $v->verify(-action => 3);
		if($rv){ print br('UNDEFINED: '.escapeHTML(param('vid'))); }
		else { print br('UNDEFINE Failed: '.escapeHTML($err)); }
		last;
	}
	if(/^REMOVE$/){
		print '<script language=javascript>resizeTo(200,200);</script>'."\n";
		print br('Removing id: ', tt(escapeHTML(param('vid'))))."\n";
		my ($err,$rv) = $v->remove(-action => 4);
		if($rv){ print br('REMOVED: '.escapeHTML(param('vid'))); }
		else { print br('REMOVE Failed: '.escapeHTML($err)); }
		last;
	}
	print ('Unknown Handler: ', tt(escapeHTML(param('action'))));
}
print end_html()."\n";
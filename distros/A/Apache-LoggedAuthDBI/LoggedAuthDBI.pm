package Apache::LoggedAuthDBI;

$Apache::LoggedAuthDBI::VERSION = '0.12';

use constant MP2 => $ENV{MOD_PERL_API_VERSION} == 2 ? 1 : 0;
use Apache::AuthDBI;
use DBI;
use strict;

use Exporter;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);


BEGIN {
	my @constants = qw( OK AUTH_REQUIRED FORBIDDEN DECLINED SERVER_ERROR );
	if (MP2) {
		require Apache2::Const;
		import Apache2::Const @constants;
	}
	else {
		require Apache::Constants;
		import Apache::Constants @constants;
	}
}

# configuration attributes, defaults will be overwritten with values from .htaccess.

my %CFG = (
	'Auth_DBI_data_source'      => '',
	'Log_ADBI_table'      => '',
	'Log_ADBI_ip_field'         => '',
	'Log_ADBI_un_field'         => '',
	'Log_ADBI_status_field'        => '',
	'Log_ADBI_time_field'        => ''
	);
my $Attr = { };



sub authen {
	my ($r) = @_;  # $r is the handler which allows direct access to Apache systems, DANGER!

	my $c = $r->connection;
	my ($incomingIP) = $c->remote_ip;
	my ($username) = $c->user;
	my $s = $r->server;
	my $serverName = $s->server_hostname;
	my $client = &client($serverName);

	# $auth is what goes in the database
	# $return_value is what the module returns
	# $auth and $return_value do NOT have to be the same thing!

	my $auth = 'DECLINED'; # default it to declined. if its not bruteforce and login/pw are correct it'll be set to OK
	my $return_value;

	my $errdocpath = $r->document_root;

    # get configuration
	my ($key, $val);
    while(($key, $val) = each %CFG) {
        $val = $r->dir_config($key) || $val;
        $key =~ s/^Log_ADBI_//;
        $Attr->{$key} = $val;
    }
	$Attr->{data_source} = $r->dir_config('Auth_DBI_data_source');


    # parse connect attributes, which may be tilde separated lists
    my @data_sources = split(/~/, $Attr->{data_source});
    my @usernames    = split(/~/, $Attr->{username});
    my @passwords    = split(/~/, $Attr->{password});
    $data_sources[0] = '' unless $data_sources[0]; # use ENV{DBI_DSN} if not defined

	# connect to database, use all data_sources until the connect succeeds
	my $j;
	my $dbh;
	for ($j = 0; $j <= $#data_sources; $j++) {
		last if ($dbh = DBI->connect($data_sources[$j], $usernames[$j], $passwords[$j]));
	}
	unless ($dbh) {
		$r->log_reason("db connect error with data_source >$Attr->{data_source}<: $DBI::errstr", $r->uri);
		return MP2 ? Apache2::Const::SERVER_ERROR() : Apache::Constants::SERVER_ERROR();
	}

	# connect to right database
	#my $dbh = DBI->connect("DBI:mysql:$DB_CFG{$client.'dbname'}:$DB_CFG{$client.'dbhost'}", $DB_CFG{$client.'dblogin'}, $DB_CFG{$client.'dbpass'});



	#THE RULES
	#
	# configure the tolerance levels using the following 8 variables
	#

	#autoreject if an IPaddress made X failed attempts in Y seconds
	my $seconds_declined = 120;
	my $times_declined = 5;

	#prevent brute force attacks, has an IPaddress made X attempts in Y seconds
	my $seconds_brute_ip = 300;
	my $times_brute_ip = 800;
	
	#prevent brute force attacks, has the same username been rejected X times in Y sec?
	my $seconds_brute_username = 60;
	my $times_brute_username = 3;

	#Prevent password sharing, has the same username accessed from X different IPs in Y sec
	my $minutes_pw_shared = 180;
	my $times_pw_shared = 30;


	#SQL Queries to detect brute forcing and or pass sharing
		# &get_count will return the number of entries that correspond to the query in $select. the result will be
		# compared with the $times_...  variable to detect a violation of our rules

	#autoreject if an IPaddress made X failed attempts in Y seconds
	my $select = "SELECT id FROM ".$Attr->{table}." WHERE ".$Attr->{ip_field}."='$incomingIP' AND ".$Attr->{status_field}."<>'0' AND ".$Attr->{time_field}." > (DATE_SUB(NOW(), INTERVAL '$seconds_declined' SECOND))";
	my $declined = &get_count($select, $dbh);

	#prevent brute force attacks, has an IPaddress made X attempts in Y seconds
	$select = "SELECT id FROM ".$Attr->{table}." WHERE ".$Attr->{ip_field}."='$incomingIP' AND ".$Attr->{time_field}." > (DATE_SUB(NOW(), INTERVAL '$seconds_brute_ip' SECOND))";
	my $brute_ip = &get_count($select, $dbh);

	#prevent brute force attacks, has the same username been rejected X times in Y sec?
	$select = "SELECT id FROM ".$Attr->{table}." WHERE ".$Attr->{un_field}."='$username' AND ".$Attr->{status_field}."<>'0' AND ".$Attr->{time_field}." > (DATE_SUB(NOW(), INTERVAL '$seconds_brute_username' SECOND))";
	my $brute_username = &get_count($select, $dbh);

	#Prevent password sharing, has the same username accessed from X different IPs in Y sec
	$select = "SELECT distinct(".$Attr->{ip_field}.") ".$Attr->{table}." WHERE ".$Attr->{un_field}."='$username' AND ".$Attr->{time_field}. "> (DATE_SUB(NOW(), INTERVAL '$minutes_pw_shared' MINUTE))";
	my $password_shared = &get_count($select, $dbh);



	#Take Action: in case of a detected violation beyond tolerance level send the user to an error page
	if ($declined >= $times_declined) {
		$r->filename($errdocpath . 'blocked.html');
		$return_value = 'OK';
	} elsif ($brute_ip >= $times_brute_ip || $brute_username >= $times_brute_username) {
		$r->filename($errdocpath . 'brute_force.html');
		$return_value = 'OK';
	} elsif ($password_shared >= $times_pw_shared) {
		$r->filename($errdocpath . 'pass_sharing.html');
		$auth = 'PASS_SHARED';
		$return_value = 'OK';

	#no brute force/pwsharing pass off to the main DBI authorization thingy...
	} else { 
		$auth = Apache::AuthDBI::authen($r);
		$return_value = $auth;
	}

	#If this is the initial request log the attempt in the database. the ifcheck is necessary to screen out
	#multiple entries caused by subrequests when everything goes through okay
	if ($r->is_initial_req) {
		my $sth = $dbh->prepare("INSERT INTO ".$Attr->{table}." VALUES ('', '$username', '$incomingIP', '$auth', NULL)");
		$sth->execute;
	}
  
	# disconnect from the database
	$dbh->disconnect;

	# Return the $auth
	return $return_value;
}


sub get_count {
	my ($sql, $dbh) = @_;
	my $sth = $dbh->prepare($sql);
	my $rv = $sth->execute;
	$rv = 0 if (!($rv > 0));
	return $rv;
}


1;

__END__

=head1 NAME

 Apache::LoggedAuthDBI


=head1 SYNOPSIS

 # Configuration in httpd.conf or startup.pl:

 PerlModule Apache::LoggedAuthDBI

 # Authentication and Authorization in .htaccess:

 AuthName DBI
 AuthType Basic

 PerlAuthenHandler Apache::AuthDBI::authen
 PerlAuthzHandler  Apache::AuthDBI::authz

 PerlSetVar Auth_DBI_data_source   dbi:driver:dsn
 PerlSetVar Auth_DBI_username      db_username
 PerlSetVar Auth_DBI_password      db_password
 #DBI->connect($data_source, $username, $password)

 PerlSetVar Log_ADBI_table         login_log
 PerlSetVar Log_ADBI_ip_field      IPaddress
 PerlSetVar Log_ADBI_un_field      username
 PerlSetVar Log_ADBI_status_field  status
 PerlSetVar Log_ADBI_time_field    timestamped
 # data required to access the log table

 PerlSetVar Auth_DBI_pwd_table     users
 PerlSetVar Auth_DBI_uid_field     username
 PerlSetVar Auth_DBI_pwd_field     password
 # authentication: SELECT pwd_field FROM pwd_table WHERE uid_field=$user

 require valid-user


=head1 DESCRIPTION

 This is an extension of Apache::AuthDBI by Edmund Mergl. Its purpose is
 to add a degree of protection against brute force attacks and password sharing.
 To accomplish this LoggedAuthDBI makes use of a log table that records IP, username,
 status and time of any given login attempt handled by this module.
 Whenever it is called it will perform four checks:

=over 4

=item *
 Did IPaddress 123 make X failed attempts in Y seconds?

 (autoreject IP addresses that have too many failed attempts on record)

=item *
 Did IPaddress 123 make X attempts in Y seconds?

 (if X gets very large while Y is small, the possibility of a brute force
 attack taking place is very real indeed)

=item *
 Has username foo been rejected X times in Y seconds?

 (this check as a means to help against proxy rotation in combination with
 brute force attempts)

=item *
 Does username foo have logins from X different IPaddresses in Y seconds?

 (this would surely indicate password sharing)

=back

 Should none of the four checks yield a violation AuthDBI is called and its
 return value used without modification.
 Otherwise it will redirect to a different filename while returning OK. This
 will cause a bruteforce tool to think it was successful in its attempt to
 guess a valid login/pass combination and either stop or collect this combination
 into its list of valid options.

 Consider this module beta ware as it has only seen action in the original
 context it was created for and at.


=head1 LOG TABLE

 While it is possible that a log table is already in place it might need some
 adjustment. See this MySQL CREATE TABLE command to see the required structure/
 how to create. Table name and field names are, of course, arbitrary as they are
 determined in the .htaccess file.

 <mysql>
 CREATE TABLE `member_log` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `username` varchar(64) default NULL,
  `IPaddress` varchar(15) default NULL,
  `status` varchar(15) default NULL,
  `timestamped` timestamp(14) NOT NULL,
  PRIMARY KEY  (`id`)
 ) TYPE=MyISAM
 </mysql>


=head1 LIST OF TOKENS

 Only the tokens specific to this module are discussed here. For reference
 on the remaining tokens consult the documentation on Apache::AuthDBI.

=over 4

=item *
 Log_ADBI_table

 Name of the table where login records will be kept.
 Has to at least contain fields holding IPaddress, username, status and timestamp.

=item *
 Log_ADBI_ip_field

 Field name of the Log_ADBI_table containing the IPaddress of the login attempt.

=item *
 Log_ADBI_un_field

 Field name of the Log_ADBI_table containing the username of the login attempt.

=item *
 Log_ADBI_status_field

 Field name of the Log_ADBI_table containing the status of the login attempt that was made.

=item *
 Log_ADBI_time_field

 Field name of the Log_ADBI_table containing the timestamp of the login attempt. 

=back


=head1 CONFIGURATION

 The module should be loaded upon startup of the Apache daemon.
 Add the following line to your httpd.conf:

 PerlModule Apache::LoggedAuthDBI
 
 Also, copy the following HTML files to the document root of Apache. These are needed
 as this module will redirect to these resources in case of detected perpetration. Using
 your own is perfectly okay as long as you either keep the naming or edit the filenames
 in the module.

=over 4

=item *
 blocked.html

=item *
 brute_force.html

=item *
 pass_sharing.html

=back

=head1 PREREQUISITES

 Apache::AuthDBI is required. This implies that minimum requirements for that
 module must be met.


=head1 AUTHORS

=over 4

=item *
 Apache::LoggedAuthDBI by Sung-Hun Kim

=item *
 Apache::AuthDBI by Edmund Mergl; now maintained and supported by the
 modperl mailinglist, subscribe by sending mail to
 modperl-subscribe@perl.apache.org.

=back

=head1 SEE ALSO

L<AuthDBI>

=head1 COPYRIGHT

 Copyright (c) 2005 Sung-Hun Kim. All rights reserved. 
 This program is free software;  you can redistribute it 
 and/or modify it under the same terms as Perl itself.

=cut

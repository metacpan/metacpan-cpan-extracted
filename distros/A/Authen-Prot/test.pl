#!/usr/bin/perl -w 
###############################################################################
#
# $Header: /usr/local/cvs/paulg/Authen-Prot/test.pl,v 1.6.1.1 1998/10/28 01:03:55 paulg Exp $
# Copyright (c) 1998 Paul Gampe and TWICS. All Rights Reserved.
#
###############################################################################

###############################################################################
##                 L I B R A R I E S / M O D U L E S
###############################################################################

BEGIN { $| = 1; print "1..87\n"; }
END {print "not ok 1\n" unless $loaded;}
use Authen::Prot;
$loaded = 1;
print "ok 1\n";

use strict;

###############################################################################
##                  G L O B A L   V A R I A B L E S
###############################################################################

use vars qw($VERSION @FIELDS);
$VERSION = do { my @r=(q$Revision: 1.6.1.1 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r};

## Some fields 'hopefully' common to most OS implementations
@FIELDS = qw( name uid owner min maxlen expire lifetime 
	          schange uchange pswduser pick_pwd gen_pwd 
			  restrict nullpw slogin ulogin );

###############################################################################
##                           M E T H O D S
###############################################################################
sub get_test {
    print "Checking for Term::Readline......";
    eval { require Term::ReadLine; };
    if ($@) {
        print "failed\n";
		print "skipping update account tests\n";
		return undef;
	} else {
		my $term = new Term::ReadLine 'Authen::Prot test.pl';
		my $OUT = $term->OUT || 'STDOUT';
		print $OUT <<EOT;
ok

This script can test the putprpwnam method for updating a password entry. 
The test will change the account last successful login time to now and
then set it back again to the original value.  If you would like to
perform the tests for modifying a password entry enter the name of the
account or carriage return to skip these tests.  

EOT
		my $prompt =  'Enter account name [carriage return to skip test]: ';
		my $test_acct   = $term->readline($prompt);
		return undef unless $test_acct;
		$prompt = "Run tests on the account $test_acct? [yes]/no: ";
		return ($term->readline($prompt) =~ /n/i) ? undef : $test_acct;
	}
}

###############################################################################
##                              M A I N
###############################################################################

warn "You probably need to be root for these tests to succeed"
	unless ($< == 0);

my $test_acct = get_test();

my ($pw,$i);

$i=2; ## start at test 2

##  2: setprpwent
eval { Authen::Prot::setprpwent() };
print $@ ? "not ok " : "ok ", $i++, "\n";

##  3: getprpwent
$pw = Authen::Prot->getprpwent();
print defined($pw) ? "ok " : "not ok ", $i++, "\n";

##  4: 
$pw = Authen::Prot->getprpwent();
print defined($pw) ? "ok " : "not ok ", $i++, "\n";

## 5-68: Test a few fields
my ($field,$full_field,$struct,$name);
foreach $field (@FIELDS) {
	foreach $struct (qw[ ufld sfld uflg sflg ]) {
		$name="_fd_".$field if ($struct =~ /fld/);
		$name="_fg_".$field if ($struct =~ /flg/);
		$full_field = "$struct$name";
		eval { $pw->$full_field(); };
		print "$@: not " if ($@);
		print "ok ", $i++, "\n";
	}
}

## 69: this should fail
eval { $pw = Authen::Prot->getprpwuid() };

print "not " unless ($@);
print "ok ", $i++, "\n";

## 70: this should work, assuming you have an account with uid = 0
$pw = Authen::Prot->getprpwuid(0) or print "not ";
print "ok ", $i++, "\n";

## 71:
print "not " unless ( $pw->ufld_fd_uid() == 0);
print "ok ", $i++, "\n";

## 72: getprpwnam this should fail
eval { $pw = Authen::Prot->getprpwnam() };

print "not " unless ($@);
print "ok ", $i++, "\n";

## 73: this should work, assuming you have an account named daemon
$pw = Authen::Prot->getprpwnam('daemon') or print "not ";
print "ok ", $i++, "\n";

## 74:
print "not " unless ( $pw->ufld_fd_name eq 'daemon');
print "ok ", $i++, "\n";

## putprpwnam
if (defined($test_acct)) {
	## 75:
	$pw = Authen::Prot->getprpwnam($test_acct) or print "not ";
	print "ok ", $i++, "\n";
	if(defined($pw)) { ## only do tests if we've got a valid account

		## 76: retrieve last login time
		my $last_login = $pw->ufld_fd_slogin;
		print "last successful login for ", $test_acct, " was: ",
			scalar(localtime($last_login)), "\n";

		my $now = time;	# save time now

		$pw->ufld_fd_slogin($now) or print "not ";
		print "ok ", $i++, "\n";

		## 77: commit update
		$pw->putprpwnam() or print "not ";
		print "ok ", $i++, "\n";

		## 78: retrive time again, should be new time
		$pw = Authen::Prot->getprpwnam($test_acct) or print "not ";
		print "ok ", $i++, "\n";

		## 79:
		print "not " unless ( $pw->ufld_fd_slogin == $now);
		print "ok ", $i++, "\n";

		print "last successful login for ", $test_acct, " set to: ",
			scalar(localtime($pw->ufld_fd_slogin)), "\n";

		## 80: reset last login time
		$pw->ufld_fd_slogin($last_login) or print "not ";
		print "ok ", $i++, "\n";

		## 81: commit update
		$pw->putprpwnam() or print "not ";
		print "ok ", $i++, "\n";

		## 82: retrive time again, should be old time
		$pw = Authen::Prot->getprpwnam($test_acct) or print "not ";
		print "ok ", $i++, "\n";

		print "last successful login for ", $test_acct, " restored to: ",
			scalar(localtime($pw->ufld_fd_slogin)), "\n";

	}
}

## 83: bigcrypt
my $crypt;
eval { $crypt = Authen::Prot::bigcrypt('test', 'test') };
print $@ ? "not ok " : "ok ", $i++, "\n";

## 84: acceptable_password should return zero cause password too simple
print "not " if Authen::Prot::acceptable_password('simple', 'STDERR');
print "ok ", $i++, "\n";

## 85: should return 1 cause cryptic password
print "not " unless Authen::Prot::acceptable_password('fj44jf99', 'STDERR');
print "ok ", $i++, "\n";

## 86:
print (($crypt ne 'teH0wLIpW0gyQ') ? "not ok " : "ok ", $i++, "\n");

## 87: endprpwent
eval { Authen::Prot::endprpwent() };
print $@ ? "not ok " : "ok ", $i++, "\n";

exit(0);


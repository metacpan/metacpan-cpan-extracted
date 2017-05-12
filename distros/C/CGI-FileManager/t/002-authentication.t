#!/usr/bin/perl -w
use strict;

use Test::More "no_plan";

use FindBin qw($Bin);

use lib "blib/lib";

my $pwfile = "$Bin/../authpasswd";
prepare_users();

BEGIN { use_ok( 'CGI::FileManager::Auth' ); }

#{
#	my $auth = CGI::FileManager::Auth->new();
#	is(ref($auth), 'CGI::FileManager::Auth', "object created");

#	is($auth->verify("gabor", "nincs"), 1, "correct user authenticated");
#	is($auth->verify("gabor", "gaborx"), 0, "in correct user NOT authenticated");
#	is($auth->home("gabor"), "$Bin/../dir", "home directory is correct");
#}


{
	my $auth = CGI::FileManager::Auth->new({
		PASSWD_FILE => $pwfile,
		});
	is(ref($auth), 'CGI::FileManager::Auth', "object created");
	is($auth->verify("gabor", "nincs"), 1, "correct user authenticated");
	is($auth->verify("gabor", "gaborx"), 0, "in correct user NOT authenticated");
	is($auth->home("gabor"), "$Bin/../dir", "home directory is correct");
}

sub prepare_users {
	use Unix::PasswdFile;

	open my $fh, ">", $pwfile or die "Cannot overwrite/create $pwfile";
	close $fh;

	my $pw = Unix::PasswdFile->new($pwfile);
	$pw->user('gabor', $pw->encpass('nincs'), 1, 10, "Gabor", "$Bin/../dir", "none");
	$pw->commit();
}
	



sub usage {
	print "$0 filename add username\n";
	print "$0 filename change username\n";
	exit;
}


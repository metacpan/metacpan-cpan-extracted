#!/usr/bin/perl

use warnings;
use strict;
use Unix::PasswdFile;

usage() if @ARGV != 3;
my ($file, $action, $username) = @ARGV;
usage() if $action ne "add" and $action ne "change";

if (not -e $file) {
	if ($action eq "change") {
		print "File '$file' does not exist\n";
		usage();
	}
	open my $fh, ">", $file;
}

my $pw = Unix::PasswdFile->new($file);
if ($action eq "change") {
	if (not $pw->user($username)) {
		print "No such user\n";
		usage();
	}
	print "New password: ";
	chomp(my $newpw = <STDIN>);
	$pw->passwd($username, $pw->encpass($newpw));
	$pw->commit;
	exit;
}

if ($action eq "add") {
	print "Password: ";
	chomp(my $newpw = <STDIN>);
	print "Home: ";
	chomp(my $home = <STDIN>);
	my $uid = $pw->maxuid || 0;
	$uid++;
	my $gid = 10;
	my $shell = "none";
	my $geco = $username;
	$pw->user($username, $pw->encpass($newpw), $uid, $gid, $geco, $home, $shell);
	$pw->commit();
	exit;
}
	



sub usage {
	print "$0 filename add username\n";
	print "$0 filename change username\n";
	exit;
}

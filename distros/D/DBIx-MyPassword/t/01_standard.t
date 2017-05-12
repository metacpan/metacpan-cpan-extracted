#!/usr/bin/perl

use warnings;
use strict;
use Test::Simple tests => 9;
use Text::CSV;

my $file = '.mypassword';

my (@uno) = ('test1','test1_user','test1_password','dbi:NoDriver1:nodb','RaiseError => 1');
my (@dos) = ('test2','test2_user','test2_password','dbi:NoDriver2:nodb','RaiseError => 2');

#--> 1) Sort-of a test... write a password file
my $csv = new Text::CSV;
open(FILE,">$file") or die("Unable to open $file");
for (\@uno, \@dos) {
	$csv->combine(@$_);
	print FILE $csv->string(),"\n";
}
close FILE;
ok(-e $file);

#--> 2) Test loading the module
eval "use DBIx::MyPassword qw($file);";
ok($@ eq '');

#--> 3) Test the virtual user names
my (@vu) = DBIx::MyPassword->getVirtualUsers();
ok($vu[0] eq $uno[0] and $vu[1] eq $dos[0]);

#--> 4) Test the virtual user
ok(DBIx::MyPassword->checkVirtualUser($vu[0]));

#--> 5) Test a fake virtual user
ok(not DBIx::MyPassword->checkVirtualUser($vu[0] . 'blahblahblah'));

#--> 6) Test the virtual user database naem
ok(DBIx::MyPassword->getUser($vu[0]) eq $uno[1]);

#--> 7) Test the virtual user password
ok(DBIx::MyPassword->getPassword($vu[0]) eq $uno[2]);

#--> 8) Test the data source
ok(DBIx::MyPassword->getDataSource($vu[0]) eq $uno[3]);

#--> 9) Test the options
ok(DBIx::MyPassword->getOptions($vu[0]) eq $uno[4]);

unlink $file;

#!/usr/bin/perl

use strict;
use DBI;
use Term::ReadKey;
use Email::Valid;

require 'conf.pl';

my ($db_src, $db_user, $db_pass) = conf();

my $dbh = DBI->connect($db_src, $db_user, $db_pass, { RaiseError => 1, PrintError => 1, AutoCommit => 0});

print "Username to add: ";
my $user = <>;
chomp($user);
if ($dbh->selectrow_array("select id from users where username = ?", undef, $user)) {
    print "$user name already in use\n";
    $dbh->rollback();
    $dbh->disconnect();
    exit 1;
}
print "Password for $user: ";
ReadMode('noecho');
my $password = ReadLine(0);
chomp($password);
print "\nPassword again: ";
my $password_confirm = ReadLine(0);
chomp($password_confirm);
ReadMode(0);
unless ($password eq $password_confirm) {
    print "\nTwo wrongs doesn't make a right!\n";
    $dbh->rollback();
    $dbh->disconnect();
    exit 1;
}
print "\n";

print "Users email: ";
my $email = <>;
chomp($email);
unless ($email = Email::Valid->address($email)) {
    print "Need a valid email\n";
    $dbh->rollback();
    $dbh->disconnect();
    exit 1;
}

my $lang = "";

do {
    print "Language: ";
    $lang = <>;
    chomp($lang);
} while ($lang ne $dbh->selectrow_array("select lang from languages where lang = ?", undef, $lang));

my $lang_id = $dbh->selectrow_array("select id from languages where lang = ?", undef, $lang);

$dbh->do("insert into users (id, username, password, email, lang) values (users_id.nextval,?,?,?,?)", undef, $user, $password, $email, $lang_id);

$dbh->commit();
print "$user($email:$lang) added...\n";

$dbh->disconnect();




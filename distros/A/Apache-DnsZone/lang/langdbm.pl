#!/usr/bin/perl

use strict;
use MLDBM qw(GDBM_File Data::Dumper);
use Fcntl;
use Data::Dumper;

my %lang = ();

opendir(DH, ".") or die $!;

while (my $filename = readdir(DH)) {
    next if -d $filename;
    next if $filename !~ /^(\w{2})\.lang$/;
    my $lang = $1;
    print "Importing $filename ($lang)\n";
    eval {
	require $filename;
	my %temp = lang();
	$lang{$lang} = \%temp;
    };
}

closedir(DH);

#print Dumper(\%lang);

unlink 'DnsZoneLang';

print "Dumping to DB\n";

my %dbm = ();
my $dbm = tie %dbm, 'MLDBM', 'DnsZoneLang', O_CREAT|O_RDWR, 0640 or die $!;

%dbm = %lang;

untie %dbm;
undef $dbm;

print "Done\n";

#print "Bringing it all in again\n";

#$dbm = tie %dbm, 'MLDBM', 'DnsZoneLang', O_RDONLY, 0640 or die $!;

#print Dumper(\%dbm);

#untie %dbm;
#undef $dbm;



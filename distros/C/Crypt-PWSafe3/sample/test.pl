#!/usr/bin/perl

use lib qw(blib/lib);
use Crypt::PWSafe3;


my $file = shift;

if (!$file) {
  print STDERR "Usage $0 <vault>\n";
  exit 1;
}

my $create = 1;
if (-e $file) {
  $create = 0;
}

my $vault = Crypt::PWSafe3->new(file => $file, create => $create, password => 'blah') or die "$!";

if ($create) {
  my %record = (
		user   => 'u3',
		passwd => 'p3',
		group  => 'g3',
		title  => 't3',
		notes  => scalar localtime(time)
	       );
  $vault->newrecord(%record);
  $vault->save();
  print "record saved to $file, execute $0 again to view it\n"
}
else {
  my @r = $vault->getrecords;
  foreach my $rec (@r) {
    printf qq(%s:
  User: %s
Passwd: %s
 Group: %s
 Title: %s
 Notes: %s
), $rec->uuid, $rec->user, $rec->passwd, $rec->group, $rec->title, $rec->notes;

    $rec->notes( scalar localtime(time));
#    $vault->modifyrecord($rec->uuid, notes => scalar localtime(time));
  }

  $vault->save;
}


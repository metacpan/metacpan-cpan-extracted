#!/usr/local/bin/perl -w
use Carp;
use DBI;
use DBD::SearchServer;

BEGIN {
  $tests = 8;
  $ENV{FULSEARCH} = './fultest' if !defined($ENV{FULSEARCH});
  $ENV{FULTEMP} = './fultest' if !defined($ENV{FULTEMP});	
}

print "1..$tests\n";

my $dbh = DBI->connect('dbi:SearchServer:','','');

print "ok 1\n" if defined($dbh);

my $cur;
$cur = $dbh->prepare('select title from test');

print "ok 2\n" if defined($cur);

#print "\$cur->{CursorName} is '$cur->{CursorName}'\n";
my $name1 = $cur->{CursorName};
print "ok 3\n" if length($name1) > 0;

$cur = $dbh->prepare('select filesize from test');
#print "\$cur->{CursorName} is '$cur->{CursorName}', prev was '$name1'\n";	
print "ok 4\n" if ((length($cur->{CursorName}) > 0) && ($cur->{CursorName} ne $name1));

$cur = $dbh->do('validate index test validate table');

print "ok 5\n" if defined($cur);

$dbh->disconnect();

print "ok 6\n";

# testing reconnection problems and attribs
$dbh = DBI->connect ('dbi:SearchServer:','','', { ss_maxhitsinternalcolumns => 64 });



print "ok 7\n" if $dbh;

print "$DBI::errstr\n" if (!$dbh->disconnect());

print "ok 8\n" if $dbh;

exit 0;



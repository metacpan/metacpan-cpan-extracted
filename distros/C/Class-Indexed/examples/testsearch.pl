#!/usr/bin/perl -w 

use strict;

use DBI;

use Class::Indexed::Words;

use Data::Dumper;

print "\ntest search\n===========\n\n";

print "keywords : ";
my $keywords = <STDIN>;
chomp($keywords);
my @keywords = split(/\s/,$keywords);
print "keywords : $keywords / keywords : @keywords\n";


my (@shortlist,@arglist);

foreach my $word (@keywords) {
    next if ($stopwords{$word});
    warn "word : $word \n";
    push(@shortlist, $word);
    push(@arglist,'?')
  }

warn @shortlist;
warn @arglist;

print "got keywords : ", join(', ',@shortlist), "\n.. searching...\n";

# get dbh
my $dbh = DBI->connect("dbi:mysql:testclass:localhost", 'testclass', 'foo');

# build SQL
my $where = 'WHERE CIRIND_Word IN (' . join(',',@arglist) . ') ';
my $sql = qq{
    SELECT CIMETA_Title, sum(CIRIND_Score) as score, count(*) as count, 
    CIMETA_Summary, CIRIND.CIMETA_ID, CIMETA_Key, CIMETA_KeyValue, CIMETA_URL
	FROM   CIRIND, CIMETA
	$where
	AND CIRIND.CIMETA_ID = CIMETA.CIMETA_ID
	Group By CIRIND.CIMETA_ID Order By score DESC, Count DESC };

my $sth = $dbh->prepare($sql) or warn"couldn't prepare statement!\n";

# get results
$sth->execute(@shortlist);
my $results = $sth->fetchall_arrayref();

print "..got results : \n";
foreach my $pub (@$results) {
    print "pub : $pub->[0] / score : $pub->[1] / matches : $pub->[2] \n";
}



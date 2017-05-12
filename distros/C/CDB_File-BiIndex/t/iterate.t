#!/usr/bin/perl -w

=head1 Basic Checks

This includes a test for a specific iteration bug that I had.

The situation is that we have a specific link, look it up in the
index, then want to investigate all susequent links.

=cut

$::verbose = 0 unless defined $::verbose;
#$::verbose = 0xFF unless defined $::verbose;
$loaded = 0;

BEGIN { print "1..14\n"} ;
END { print "not ok 1\n" unless $loaded; } ;

sub ok { print "ok ", shift, "\n" }
sub nogo { print "not " }

use CDB_File::BiIndex 0.026;
$loaded = 1;
$CDB_File::BiIndex::verbose=0xffff if $::verbose;

$index = new CDB_File::BiIndex "test-data/page_has_link.cdb", "test-data/link_on_page.cdb";
ok(1);
$::result1=$index->lookup_second("http://www.rum.com/");
print STDERR "lookup second returned $::result1\n" if $::verbose;
#print STDERR @$::result1, "\n";
ok(2);
$::result2=$index->second_set_iterate("http://www.rum.com/");
nogo unless $::result2 eq "http://www.rum.com/";
ok(3);
$::result3=$index->second_next();
print STDERR "result3 $result3\n" if $::verbose;
ok(4);
$index->second_reset();
@urls=();
while($url=$index->second_next()) {
  push @urls, $url;
}
$count=@urls;
print STDERR "index had $count articles\n" if $::verbose;
nogo unless (@urls == 10);
ok(5);
$index->first_reset();
@urls=();
while($url=$index->first_next()) {
  push @urls, $url;
}
$count=@urls;
print STDERR "index had $count articles\n" if $::verbose;
nogo unless (@urls == 2);
ok(6);
$::result4=$index->second_set_iterate("http://www.boredom.com/non_exist");
nogo unless $::result4 eq "http://www.ix.com";
print STDERR "result4 $::result4\n" if $::verbose;
ok(7);
$::result5=$index->second_next();
print STDERR "result5 $::result5\n" if $::verbose;
nogo unless $::result5 eq "http://www.jw.com/";
ok(8);
$::result6=$index->second_next();
print STDERR "result6 $::result6\n" if $::verbose;
nogo unless $::result6 eq "http://www.or.com/";
ok(9);
$::result7=$index->second_next();
print STDERR "result7 $::result7\n" if $::verbose;
nogo unless $::result7 eq "http://www.rum.com/";
ok(10);
$::result8=$index->second_next();
print STDERR "result8 $::result8\n" if $::verbose;
nogo unless $::result8 eq "http://www.so.com/";
ok(11);
$::result9=$index->second_next();
print STDERR "result9 $::result9\n" if $::verbose;
nogo unless $::result9 eq "xxxx:++++++++++++++++++++++++++++++++++++++++++";
ok(12);
$::result10=$index->second_next();
print STDERR "result10 $::result10\n" if $::verbose;
nogo if defined $::result10;
ok(13);
$::result11=$index->second_next();
print STDERR "result11 $::result11\n" if $::verbose;
nogo unless $::result11 eq "http://example.com/banana.html";
ok(14);

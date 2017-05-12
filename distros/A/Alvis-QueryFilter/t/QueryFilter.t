# -*- perl -*-

#  do query processing test

use Test::More tests => 1;
ok(1);

## uncomment this for proper testing (install tree-tagger and check Treetagger.pm before)
#$pid = fork();
#if ( !$pid ) {
#    exec("$^X bin/run_QF.pl --testquery t/test");
#}
#sleep(10);
#
#if ( system("wget -O t/TEST.out '" . 'http://localhost:9084?version=1.1&operation=searchRetrieve&recordSchema=D9.1&startRecord=1&maximumRecords=10&query=%28%20text%3D%22human%22%20%29' . "' '" . 'http://localhost:9084?version=1.1&operation=searchRetrieve&recordSchema=D9.1&startRecord=1&maximumRecords=10&query=text%3D%22response%22%20and%20to%20and%20text%3D%22heat%22%20and%20shock' . "' '" . 'http://localhost:9084?version=1.1&operation=searchRetrieve&recordSchema=D9.1&startRecord=1&maximumRecords=10&query=text%3D%22response to heat%22%20and%20text%3D%22shocks%22' . "' '" . 'http://localhost:9084?version=1.1&operation=searchRetrieve&recordSchema=D9.1&startRecord=1&maximumRecords=10&query=text%3D%22response to heat%22%20and%20text%3D%22shocks%22 and entity-species="Bacillus subtilis" and dc.date="2000"' . "' '" . 'http://localhost:9084?version=1.1&operation=searchRetrieve&recordSchema=D9.1&startRecord=1&maximumRecords=10&query=northern and blot and analyses and entity-species="Bacillus subtilis"' . "'") ) {
#	ok(0);
#} else {
#	kill 9,$pid;
#
#	open(T,"<t/TEST.out");
#	my $res = "";
#        while ( <T> ) { if ( /<output>/ ) { $res .= $_; } }
#        close(T);
#	my $lres = $res;
#	$res =~ s/[^\n]//g;
#	ok(length($res) == 5 , " got results $lres");
#}
#unlink("t/TEST.out");

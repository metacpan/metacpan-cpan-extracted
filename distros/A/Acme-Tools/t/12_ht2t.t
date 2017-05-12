# perl Makefile.PL;make;perl -Iblib/lib t/12_ht2t.t
BEGIN{require 't/common.pl'}
use Test::More tests => 5;
my $html=join"",<DATA>;
my %ent=(amp => '&', 160 => ' ');
my $entqr=join"|",keys%ent;
#$html=~s,&#?($entqr);,$ent{$1},g;
my @t0=ht2t($html);
my @t1=ht2t($html,"Tab"); #die serialize(\@t1,'t1','',1);
my @t2=ht2t($html,"Table-2");
#my @k=ht2t($html,"Oslo fylke");#print serialize(\@k,'k','',1);
my $aa;
ok(($aa=join(",",grep{eval{ht2t(1..$_)};!$@}0..4)) eq '1,2,3', "antarg=$aa");
ok_ref( \@t0, \@t1, 't0');
ok_ref( \@t1, [ ['123','Abc&def'],['997','XYZ'] ],           't1');
ok_ref( \@t2, [ ['ZYX','SOS'],['SMS','OPP'],['WTF','BMW'] ], 't2');
ok_ref( [ht2t(<<"","but")], [["1234","as\ndf",1234],['asdf',1234,'as df']], 'ht2t' );
  not this
  <table>
  <tr><td>asdf</td><td>asdf</td><td>asdf</td></tr> <tr><td>asdf</td><td>asdf</td><td>asdf</td></tr>
  </table>
  but this
  <table>
  <tr><td>&#160;12&#160;34</td><td>as\ndf</td><td>1234</td></tr>
  <tr><td>asdf</td><td>1234</td><td>as<b>df</b></td></tr>
  </table>

__DATA__
<html><body>
Table-1
<table>
<tr><td>123</td><td> Abc&amp;def</td></tr>
<tr><td>997</td><td>XYZ </td></tr>
</table>
Table-2 is here:
<table>
<tr><td>ZYX</td><td>SOS</td></tr>
<tr><td>SMS</td><td>OPP</td></tr>
<tr><td>WTF</td><td>BMW</td></tr>
</table>

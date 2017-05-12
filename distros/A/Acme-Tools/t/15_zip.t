# make test
# perl Makefile.PL; make; perl -Iblib/lib t/15_zip.t

BEGIN{require 't/common.pl'}
use Test::More tests => 19;
eval{ require Compress::Zlib }; if($@){ ok(1) for 1..19; exit }

#--zip
ok_ref( [zip([1,3,5])],                 [1,3,5], 'zip 1' );
ok_ref( [zip([1,3,5],[2,4,6])],         [1..6],  'zip 2' );
ok_ref( [zip([1,4,7],[2,5,8],[3,6,9])], [1..9],  'zip 3' );
sub ziperr{eval{zip(@_)};$@=~/ERROR.*zip/}
ok( ziperr([1,2],[3,4],5), 'zip err 1');
ok( ziperr([1,2],[3,4,5]), 'zip err 2');
ok( ziperr([1,2],[3,4],5), 'zip err 1');
ok( ziperr([1,2],[3,4,5]), 'zip err 2');

#--zipb64, zipbin, unzipb64, unzipbin, gzip, gunzip
my $s=join"",map random([qw/hip hop and you dont stop/]), 1..1000;
ok( length(zipb64($s)) / length($s) < 0.5,                       'zipb64');
ok( between(length(zipbin($s)) / length(zipb64($s)), 0.7, 0.8),  'zipbin zipb64');
ok( between(length(zipbin($s)) / length(zipb64($s)), 0.7, 0.8),  'zipbin zipb64');
ok( length(zipbin($s)) / length($s) < 0.4,                       'zipbin');
ok( $s eq unzipb64(zipb64($s)),                                  'unzipb64');
ok( $s eq unzipbin(zipbin($s)),                                  'unzipbin');
my $d=substr($s,1,1000);
ok( length(zipb64($s,$d)) / length(zipb64($s)) < 0.8 );
my $f;
ok( ($f=length(zipb64($s,$d)) / length(zipb64($s))) < 0.73 , "0.73 > $f");
#for(1..10){
#  my $s=join"",map random([qw/hip hop and you dont stop/]), 1..1000;
#  my $d=substr($s,1,1000);
#  my $f= length(zipbin($s,$d)) / length(zipbin($s));
#  print $f,"\n";
#}

#--gzip, gunzip
$s=join"",map random([qw/hip hop and you do not everever stop/]), 1..10000;
ok(length(gzip($s))/length($s) < 1/5);
ok($s eq gunzip(gzip($s)));
ok($s eq unzipbin(gunzip(gzip(zipbin($s)))));
ok($s eq unzipb64(unzipbin(gunzip(gzip(zipbin(zipb64($s)))))));

print length($s),"\n";
print length(gzip($s)),"\n";
print length(zipbin($s)),"\n";
print length(zipbin($s,$d)),"\n";


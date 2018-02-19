# make;perl -Iblib/lib t/41_changed.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 4;
my @lst;
@lst=map { changed(int($_/6)) ? ($_,'-') : ($_) } 1..20; testen();
@lst=map { changed(int($_/6)) ? ($_,'-') : ($_) } 1..20; testen();
sub testen{is( join("",@lst), '123456-789101112-131415161718-1920', 'ok list' )};
is(keys(%Acme::Tools::Changed_lastval), 2, 'count 2');

#print srlz(\%Acme::Tools::Changed_lastval,'l','',1);

@lst=map changed(int($_/6)),1..20;
is( srlz(\@lst,'lst'), qq(\@lst=(undef,'0','0','0','0','1','0','0','0','0','0','1','0','0','0','0','0','1','0','0');\n), '1st undef');

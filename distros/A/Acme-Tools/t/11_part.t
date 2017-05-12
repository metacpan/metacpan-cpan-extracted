# perl Makefile.PL;make;perl -Iblib/lib t/11_part.t
BEGIN{require 't/common.pl'}
use Test::More tests => 4;

my( $odd, $even ) = part {$_%2} 1..8;
ok_ref($odd, [1,3,5,7],'odd');
ok_ref($even,[2,4,6,8],'even');

my @words=qw/These are the words of this array/;

my %h=parth { uc(substr($_,0,1)) } @words;
#warn serialize(\%h);
ok_ref( \%h,
	{ T=>[qw/These the this/],
	  A=>[qw/are array/],
          W=>[qw/words/],
          O=>[qw/of/] },           'parth');

my @a=parta { length } @words;
#warn serialize(\@a);
ok_ref( \@a, [undef,undef,['of'],['are','the'],['this'],['These','words','array']], 'parta' );

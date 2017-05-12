# make test
# perl Makefile.PL; make; perl -Iblib/lib t/32_a2h_h2a.t
BEGIN{require 't/common.pl'}
use Test::More tests => 2;
my @a=(
        [qw( Make    Model   Sales Used    )],  #alphabetical colnames for tests below
        [qw( Nissan  Qashqai 17    47.22%  )],
        [qw( Nissan  Leaf    19    52.78%  )],
        [qw( Tesla   ModelS   8    100.00% )],
        [qw( Toyota  Avensis  7    12.50%  )],
        [qw( Toyota  RAV     12    21.43%  )],
        [qw( Toyota  Auris   18    32.14%  )],
        [qw( Toyota  Prius   19    33.93%  )],
        [qw( Volvo   XC90     4    22.22%  )],
        [qw( Volvo   V40     14    77.78%  )],
	[qw( Hyundai Ionic  22 ), undef    ],
      );
                         #  deb srlz(\@a,'a','',1);
my @h  = a2h(@a);        #  deb srlz(\@h,'h','',1);
my @a2 = h2a(@h);        #  deb srlz(\@a2,'a2','',1);

ok_ref( \@h, [
  {Make=>'Nissan', Model=>'Qashqai',Sales=>17,Used=>'47.22%'},
  {Make=>'Nissan', Model=>'Leaf',   Sales=>19,Used=>'52.78%'},
  {Make=>'Tesla',  Model=>'ModelS', Sales=>8, Used=>'100.00%'},
  {Make=>'Toyota', Model=>'Avensis',Sales=>7, Used=>'12.50%'},
  {Make=>'Toyota', Model=>'RAV',    Sales=>12,Used=>'21.43%'},
  {Make=>'Toyota', Model=>'Auris',  Sales=>18,Used=>'32.14%'},
  {Make=>'Toyota', Model=>'Prius',  Sales=>19,Used=>'33.93%'},
  {Make=>'Volvo',  Model=>'XC90',   Sales=>4, Used=>'22.22%'},
  {Make=>'Volvo',  Model=>'V40',    Sales=>14,Used=>'77.78%'},
  {Make=>'Hyundai',Model=>'Ionic',  Sales=>22,Used=>undef}       ]);

ok_ref( \@a, \@a2 );

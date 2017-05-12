use strict;
use Test qw( plan ok );

BEGIN { # print our plan before module loaded
    $^W= 1;
    plan(
        tests => 26,
        # todo => [3,4],
    );
}

use Algorithm::Loops qw(
        Filter
        MapCar MapCarE MapCarU MapCarMin
        NestedLoops
        NextPermute NextPermuteNum
);

ok(1); #1# Loaded module

my $res= do {
    my @mt;
    Filter {die} @mt;
};
ok( $res, "" );                            #2#
ok( eval{ Filter {die} 1; 1 }, undef );    #3#
ok( $@, "/(?i:^died at )/" );              #4#
# print "# $@#\n";
ok( (Filter {chop} "test"), "tes" );       #5#
ok( (Filter {chop} "test","me"), "tesm" ); #6#
ok( (Filter {y/a-z/A-Z/} "x","y"), "XY" ); #7#
{
    my @list= ( '', qw/ a bc d / );
    ok( (Filter {s/(.)/\U$1/} @list), "ABcD" );  #8#
    my @new= Filter {$_.=@_} @list;
    ok( "@new", "0 a0 bc0 d0" );           #9#

    ok( "@list", " a bc d" );              #10#
}

{
    my @list= qw/ X Y Z /;
    my @new= MapCarE {@_} [qw/ a b c /], [1..3], \@list;
    ok( "@new", "a 1 X b 2 Y c 3 Z" );     #11#
    @new= MapCarMin {@_} [qw/ a b c /], [1..3], \@list;
    ok( "@new", "a 1 X b 2 Y c 3 Z" );     #12#
    @new= MapCarU {@_} [qw/ a b c /], [1..3], \@list;
    ok( "@new", "a 1 X b 2 Y c 3 Z" );     #13#
    @new= MapCar {@_} [qw/ a b c /], [1..3], \@list;
    ok( "@new", "a 1 X b 2 Y c 3 Z" );     #14#

    @new= MapCarMin {@_} [qw/ a b c /], [1], \@list;
    ok( "@new", "a 1 X" );                 #15#
    @new= MapCarU {@_} [qw/ a b c /], [1], \@list;
    ok( $new[4], undef );                  #16#
    ok( $new[7], undef );                  #17#
    $new[4]= $new[7]= 'u';
    ok( "@new", "a 1 X b u Y c u Z" );     #18#
    @new= MapCar {@_} [qw/ a b c /], [1], \@list;
    ok( "@new", "a 1 X b Y c Z" );         #19#
}

ok( 0+NestedLoops( [[]], sub{1} ), 0 );    #20#
{
    my @res= NestedLoops(
        [ [2,3], [5,7], [11,13], ],
        sub {
            pop() * pop() * pop();
        },
    );
    ok( "@res",                            #21#
        "110 130 154 182 165 195 231 273" );

    my $res= NestedLoops(
        [ [1..2], [1..5], [1..7], ],
        sub { @_ },
    );
    ok( $res, 2*3*5*7 );                   #22#

    @res= NestedLoops(
        [ [1..2], [1..5], [1..7], ],
        { OnlyWhen => 1 },
        sub { join '', @_ },
    );
    ok( 0+@res, 2*(1+5*(1+7)) );           #23#

    $res= NestedLoops(
        [ [1..2], [1..5], [1..7], ],
        { OnlyWhen => 1 },
        sub { @_ },
    );
    ok( $res, 2*(1+5*(2+3*7)) );           #24#

    my $len= 3;
    #my $t= time();
    my $cnt= 0;
    for(  '0'x$len..'9'x$len  ) {
        $cnt++   if  ! /(.).*\1/;
    }
    #print "# regex: ", time()-$t, "s ($cnt)\n";

    #my $t= time();
    #for(  0..9  ) {
    # for(  0..9  ) {
    #  for(  0..9  ) {
    #   for(  0..9  ) {
    #    for(  0..9  ) {
    #        $cnt+=0   if  ! /(.).*\1/;
    #    }
    #   }
    #  }
    # }
    #}
    #print "# loops: ", time()-$t, "s\n";

    #$t= time();
    my $iter= NestedLoops(
        [   [0..9],
            ( sub { [$_+1..9] } ) x ($len-1),
        ],
    );
    $res= 0;
    my @list;
    while(  @list= $iter->()  ) {
        do {
            $res++;
        } while( NextPermute(@list) );
    }
    #print "# outside: ", time()-$t, "s\n";
    ok( $res, $cnt );                      #25#

    #$t= time();
    $res= NestedLoops(
        [   [0..9],
            ( sub {
                my %used;
                @used{@_}= (1) x @_;
                return [ grep !$used{$_}, 0..9 ];
            } ) x ($len-1),
        ],
        sub { 1 },
    );
    #print "# used: ", time()-$t, "s\n";
    ok( $res, $cnt );                      #26#

    #$t= time();
    #$res= NestedLoops(
    #    [   [0..9],
    #        ( sub { [$_+1..9] } ) x 2,
    #    ],
    #    { Permute => 1 },
    #    sub { 1 },
    #);
    #print "# permute: ", time()-$t, "s\n";
    #ok( $res, $cnt );                      #x#

    #$t= time();
    #$res= NestedLoops(
    #    [   [0..9],
    #        ( sub { [$_+1..9] } ) x 2,
    #    ],
    #    { PermuteNum => 1 },
    #    sub { 1 },
    #);
    #print "# numperm: ", time()-$t, "s\n";
    #ok( $res, $cnt );                      #x#

    # regex: 3s (30240)
    # loops: 7s
    # outside: 28s
    # permute: 37s
    # numperm: 38s
}

__END__

# This code fixes up test numbers above.
# Use:  perl -x t/basic.t
#!/usr/bin/perl -i.tmp -p
BEGIN { @ARGV= $0 }

s/(?<=#)\d+(?=#)/++$test/ge

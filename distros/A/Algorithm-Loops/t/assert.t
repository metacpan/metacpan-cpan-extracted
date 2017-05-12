use strict;
use Test qw( plan ok skip );

BEGIN { # print our plan before module loaded
    $^W= 1;
    plan(
        tests => 85,
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

my $croak= eval { require Carp; defined &Carp::croak }
    ?  0  :  "Carp::croak() not found";
print "# $@"   if  $@;
my $check;
my $lineNum;
sub SetLineNum { $lineNum= 1+(caller(0))[2]; }
while(  <DATA>  ) {
    $lineNum++;
    chomp;
    if(  m#^[/0]#  ) {
        $check= $_;
        next;
    }
    next   if  m/^#/;
    if(  s#^:##  ) {
        eval "\n#line $lineNum $0\n$_\n; 1"
          or  die $@;
        $croak= ''   if  /croak/;
        next;
    }
    s/[#\d\s]+$//;
    my( $sub )= /^&?(\w+)/i;
    ok(
        eval "\n#line $lineNum $0\n$_\n;1",
        undef,
        "fail: $_",
    );
    if(  $@  ) {
        chomp $@;
        print "# $@\n"
    }
    ok( $@, "/^$sub:/", "name: $_" )   if  $sub;
    ok( $@, $check, "mesg: $_" )   if  $check;
    skip( $croak, $@, "/ at ".quotemeta(__FILE__)." line /", "line: $_" )
        if  '' ne $croak;
}
exit( 0 );

# This code fixes up test numbers below:
{
    seek( DATA, 0, 0 );
    while(  <DATA>  ) {
        print;
        last   if  /^\s*__END__/;
    }
    my $croak= 1;
    my $check= 0;
    my $n= 2;
    while(  <DATA>  ) {
        if(  m#^[/0]#  ) {
            chomp( $check= $_ );
        } elsif(  /^:/  ) {
            $croak= 0   if  /croak/;
        } elsif(  /^#/  ) {
            ;
        } else {
            if(  ! s/\s*#.*//s  ) {
                chomp;
            }
            $_ .= ' ' x ( 32 - length );
            my( $sub )= /^&?(\w+)/i;
            my $c= 4 - !$sub - !$check - !$croak;
            $_ .= join "#", '', $n..$n+$c-1, $/;
            $n += $c;
        }
        print;
    }
}
BEGIN { SetLineNum }
__END__
/(?i:\bnot enough arg)/
 Filter;                        #2#3#4#
 MapCar;                        #5#6#7#
 MapCarE;                       #8#9#10#
 MapCarU;                       #11#12#13#
 MapCarMin;                     #14#15#16#
 NextPermute;                   #17#18#19#
 NextPermuteNum;                #20#21#22#
/(?i:\bcode reference\b)/
&Filter();                      #23#24#25#26#
&MapCar();                      #27#28#29#30#
&MapCarE();                     #31#32#33#34#
&MapCarU();                     #35#36#37#38#
&MapCarMin();                   #39#40#41#42#
NestedLoops [], {}, {};         #43#44#45#46#
NestedLoops [], [];             #47#48#49#50#
/(?i:\boption\S*: xul\b)/
NestedLoops [], {xul=>1};       #51#52#53#54#
/(?i:\barray reference\b)/
NestedLoops;                    #55#56#57#58#
MapCar {0} 'ARRAY';             #59#60#61#62#
MapCarE {0} {a=>1};             #63#64#65#66#
MapCarU {0} sub {1};            #67#68#69#70#
MapCarMin {0} \1;               #71#72#73#74#
:undef &Carp::croak;
/(?i:\bdifferent size)/
MapCarE {0} [], [1];            #75#76#77#
/(?i:\btoo many\b)/
NestedLoops [], {}, 1, sub {0}; #78#79#80#
/(?i:\bvoid context\b)/
NestedLoops [[]], {};           #81#82#83#
0
# Invalid type:
NestedLoops [1], {};            #84#85#

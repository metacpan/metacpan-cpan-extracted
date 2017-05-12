#!/usr/bin/perl -w
# $Id: 30_dump.t 189 2006-12-05 02:41:46Z fil $

use strict;

use Test::More ( tests=>55 );
use Data::Tabular::Dumper;

pass( 'loaded' );

my %params=( CSV=>["t/test-30-test.csv", {eol=>"\n", binary=>1}], 
             XML=>["t/test-30-test.xml", "table", "record" ],
             Excel=>["t/test-30-test.xls" ]
           );

my $allowed=Data::Tabular::Dumper->available();

foreach my $t ( qw( CSV XML Excel ) ) {
    delete $params{$t} unless $allowed->{$t};    
}


my %tests = (
#############################################
dataLoL => {
    data=>[
        [1..3],
        [4..5],
    ],
    CSV=>[
        qq(1,2,3\n),
        qq(4,5\n),
    ],
    XML=>[
        qq(<?xml version="1.0" encoding="iso-8859-1"?>\n),
        qq(<table>\n),
        qq(  <record>\n),
        qq(    <0>1</0>\n),
        qq(    <1>2</1>\n),
        qq(    <2>3</2>\n),
        qq(  </record>\n),
        qq(  <record>\n),
        qq(    <0>4</0>\n),
        qq(    <1>5</1>\n),
        qq(  </record>\n),
        qq(</table>\n),
    ]
},

#############################################
dataHoL => {
    data => {
        honk => [ qw( dealing card games ) ],
        bonk => [ qw( no one keeping score )]
    },
    CSV=>[
        qq(bonk,no,one,keeping,score\n),
        qq(honk,dealing,card,games\n),
    ],
    XML=>[
        qq(<?xml version="1.0" encoding="iso-8859-1"?>\n),
        qq(<table>\n),
        qq(  <record>\n),
        qq(    <0>bonk</0>\n),
        qq(    <1>no</1>\n),
        qq(    <2>one</2>\n),
        qq(    <3>keeping</3>\n),
        qq(    <4>score</4>\n),
        qq(  </record>\n),
        qq(  <record>\n),
        qq(    <0>honk</0>\n),
        qq(    <1>dealing</1>\n),
        qq(    <2>card</2>\n),
        qq(    <3>games</3>\n),
        qq(  </record>\n),
        qq(</table>\n),
    ],
},

#############################################
dataLoH => {
    data=> [
        { honk => 42, bonk=>17 },
        { honk => 12, blurf=>36 }
    ],
    CSV=>[
        qq(blurf,bonk,honk\n),
        qq(,17,42\n),
        qq(36,,12\n),
    ],
    XML=>[
        qq(<?xml version="1.0" encoding="iso-8859-1"?>\n),
        qq(<table>\n),
        qq(  <record>\n),
        qq(    <bonk>17</bonk>\n),
        qq(    <honk>42</honk>\n),
        qq(  </record>\n),
        qq(  <record>\n),
        qq(    <blurf>36</blurf>\n),
        qq(    <honk>12</honk>\n),
        qq(  </record>\n),
        qq(</table>\n),
    ]
},

#############################################
dataHoH => {
    data=> {
        monday => { honk => 42, bonk=>17 },
        wednesday => { honk => 12, blurf=>36 }
    },
    CSV => [
        qq(,blurf,bonk,honk\n),
        qq(monday,,17,42\n),
        qq(wednesday,36,,12\n)
    ],
    XML => [
        qq(<?xml version="1.0" encoding="iso-8859-1"?>\n),
        qq(<table>\n),
        qq(  <monday>\n),
        qq(    <bonk>17</bonk>\n),
        qq(    <honk>42</honk>\n),
        qq(  </monday>\n),
        qq(  <wednesday>\n),
        qq(    <blurf>36</blurf>\n),
        qq(    <honk>12</honk>\n),
        qq(  </wednesday>\n),
        qq(</table>\n),
    ]
},

#############################################
## 3-dimentional
dataLoLoL => {
    data=> [
        [ [15..20], [4..5] ],
        [ [11..13], [4..5] ]
    ],
    CSV=>[
        qq(Page 1\n),
        qq(15,16,17,18,19,20\n),
        qq(4,5\n),
        qq(\n),
        qq(Page 2\n),
        qq(11,12,13\n),
        qq(4,5\n),
        qq(\n),
    ],
    XML=>[
        qq(<?xml version="1.0" encoding="iso-8859-1"?>\n),
        qq(<table>\n),
        qq(  <Page_1>\n),
        qq(    <record>\n),
        qq(      <0>15</0>\n),
        qq(      <1>16</1>\n),
        qq(      <2>17</2>\n),
        qq(      <3>18</3>\n),
        qq(      <4>19</4>\n),
        qq(      <5>20</5>\n),
        qq(    </record>\n),
        qq(    <record>\n),
        qq(      <0>4</0>\n),
        qq(      <1>5</1>\n),
        qq(    </record>\n),
        qq(  </Page_1>\n),
        qq(  <Page_2>\n),
        qq(    <record>\n),
        qq(      <0>11</0>\n),
        qq(      <1>12</1>\n),
        qq(      <2>13</2>\n),
        qq(    </record>\n),
        qq(    <record>\n),
        qq(      <0>4</0>\n),
        qq(      <1>5</1>\n),
        qq(    </record>\n),
        qq(  </Page_2>\n),
        qq(</table>\n),
    ]
},

#############################################
dataHoLoL => {
    data=>{
        honk => [ [15..20], [4..5] ],
        bonk => [ [11..13], [4..5] ]
    },
    CSV=>[
        qq(bonk\n),
        qq(11,12,13\n),
        qq(4,5\n),
        qq(\n),
        qq(honk\n),
        qq(15,16,17,18,19,20\n),
        qq(4,5\n),
        qq(\n),
    ],
    XML=>[
        qq(<?xml version="1.0" encoding="iso-8859-1"?>\n),
        qq(<table>\n),
        qq(  <bonk>\n),
        qq(    <record>\n),
        qq(      <0>11</0>\n),
        qq(      <1>12</1>\n),
        qq(      <2>13</2>\n),
        qq(    </record>\n),
        qq(    <record>\n),
        qq(      <0>4</0>\n),
        qq(      <1>5</1>\n),
        qq(    </record>\n),
        qq(  </bonk>\n),
        qq(  <honk>\n),
        qq(    <record>\n),
        qq(      <0>15</0>\n),
        qq(      <1>16</1>\n),
        qq(      <2>17</2>\n),
        qq(      <3>18</3>\n),
        qq(      <4>19</4>\n),
        qq(      <5>20</5>\n),
        qq(    </record>\n),
        qq(    <record>\n),
        qq(      <0>4</0>\n),
        qq(      <1>5</1>\n),
        qq(    </record>\n),
        qq(  </honk>\n),
        qq(</table>\n),
    ]
},

#############################################
dataHoLoH => {
    data=> {
        honk => [ { biff=>17, boff=>18 }, {qw(who has all the mst3ks man)} ],
        bonk => [ { billy=>1, bobby=>42 } ]
    },
    CSV=>[
        qq(bonk\n),
        qq(billy,bobby\n),
        qq(1,42\n),
        qq(\n),
        qq(honk\n),
        qq(all,biff,boff,mst3ks,who\n),
        qq(,17,18,,\n),
        qq(the,,,man,has\n),
        qq(\n),
    ],
    XML=>[
        qq(<?xml version="1.0" encoding="iso-8859-1"?>\n),
        qq(<table>\n),
        qq(  <bonk>\n),
        qq(    <record>\n),
        qq(      <billy>1</billy>\n),
        qq(      <bobby>42</bobby>\n),
        qq(    </record>\n),
        qq(  </bonk>\n),
        qq(  <honk>\n),
        qq(    <record>\n),
        qq(      <biff>17</biff>\n),
        qq(      <boff>18</boff>\n),
        qq(    </record>\n),
        qq(    <record>\n),
        qq(      <all>the</all>\n),
        qq(      <mst3ks>man</mst3ks>\n),
        qq(      <who>has</who>\n),
        qq(    </record>\n),
        qq(  </honk>\n),
        qq(</table>\n),
    ]
},

#############################################
dataHoHoH => {
    data=> {
        honk => { one=>{ biff=>17, boff=>18 }, 
                  two=>{qw(who has all the mst3ks man)} 
                },
        bonk => { one=>{ billy=>1, bobby=>42 },
                  two=>{ zin=>1, bin=>1 } }
    },
    CSV => [
        qq(bonk\n),
        qq(,billy,bin,bobby,zin\n),
        qq(one,1,,42,\n),
        qq(two,,1,,1\n),
        qq(\n),
        qq(honk\n),
        qq(,all,biff,boff,mst3ks,who\n),
        qq(one,,17,18,,\n),
        qq(two,the,,,man,has\n),
        qq(\n),
    ],
    XML => [ 
        qq(<?xml version="1.0" encoding="iso-8859-1"?>\n),
        qq(<table>\n),
        qq(  <bonk>\n),
        qq(    <one>\n),
        qq(      <billy>1</billy>\n),
        qq(      <bobby>42</bobby>\n),
        qq(    </one>\n),
        qq(    <two>\n),
        qq(      <bin>1</bin>\n),
        qq(      <zin>1</zin>\n),
        qq(    </two>\n),
        qq(  </bonk>\n),
        qq(  <honk>\n),
        qq(    <one>\n),
        qq(      <biff>17</biff>\n),
        qq(      <boff>18</boff>\n),
        qq(    </one>\n),
        qq(    <two>\n),
        qq(      <all>the</all>\n),
        qq(      <mst3ks>man</mst3ks>\n),
        qq(      <who>has</who>\n),
        qq(    </two>\n),
        qq(  </honk>\n),
        qq(</table>\n),
],
},

#############################################
dataLoLoH => {
    data=>[
        [ { biff=>17, boff=>18 }, {qw(who has all the mst3ks man)},
          { biff=>42, boff=>42 }, {qw(who 42 all 42 mst3ks 42)}
        ],
        [ { billy=>1, bobby=>42 }, { zin=>1, bin=>1 } ]
    ],
    CSV=>[
        qq(Page 1\n),
        qq(all,biff,boff,mst3ks,who\n),
        qq(,17,18,,\n),
        qq(the,,,man,has\n),
        qq(,42,42,,\n),
        qq(42,,,42,42\n),
        qq(\n),
        qq(Page 2\n),
        qq(billy,bin,bobby,zin\n),
        qq(1,,42,\n),
        qq(,1,,1\n),
        qq(\n),
    ],
    XML=>[
        qq(<?xml version="1.0" encoding="iso-8859-1"?>\n),
        qq(<table>\n),
        qq(  <Page_1>\n),
        qq(    <record>\n),
        qq(      <biff>17</biff>\n),
        qq(      <boff>18</boff>\n),
        qq(    </record>\n),
        qq(    <record>\n),
        qq(      <all>the</all>\n),
        qq(      <mst3ks>man</mst3ks>\n),
        qq(      <who>has</who>\n),
        qq(    </record>\n),
        qq(    <record>\n),
        qq(      <biff>42</biff>\n),
        qq(      <boff>42</boff>\n),
        qq(    </record>\n),
        qq(    <record>\n),
        qq(      <all>42</all>\n),
        qq(      <mst3ks>42</mst3ks>\n),
        qq(      <who>42</who>\n),
        qq(    </record>\n),
        qq(  </Page_1>\n),
        qq(  <Page_2>\n),
        qq(    <record>\n),
        qq(      <billy>1</billy>\n),
        qq(      <bobby>42</bobby>\n),
        qq(    </record>\n),
        qq(    <record>\n),
        qq(      <bin>1</bin>\n),
        qq(      <zin>1</zin>\n),
        qq(    </record>\n),
        qq(  </Page_2>\n),
        qq(</table>\n),
    ]
},

# dataHoHoL


);


##################################################################
foreach my $name ( sort keys %tests ) {
    my $test = $tests{$name};

    foreach my $p ( values %params ) {
        next unless ref $p;
        $p->[0] =~ s/30-\w+/30-$name/;
    }

    # diag( $name );
    my $dumper = Data::Tabular::Dumper->open( %params );
    $dumper->dump( $test->{data} );
    $dumper->close;

    foreach my $t ( qw( CSV XML Excel ) ) {
        SKIP: {
            skip "$t support not available", 2 unless $params{$t};

            ok( (-f $params{$t}[0]), "Created $name ($t)" );

            if( $t eq 'Excel' ) {
                unlink( $params{ $t }[0] );
                skip "Can't verify $t files", 1;
            }

            my @content =  eval {
                local @ARGV = ( $params{$t}[0] );
                <>;
            };
            die $@ if $@;
            is_deeply( \@content, $test->{$t}, "OK" )
                or die "$params{$t}[0]";
            unlink( $params{$t}[0] );
        }
    }
}


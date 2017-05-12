#!/bin/perl -w
# $Id: 20_analyse.t 189 2006-12-05 02:41:46Z fil $

use strict;

use Test::More ( tests=>10 );
use Data::Tabular::Dumper;

pass( 'loaded' );

my %params=(XML=>["t/test-20.xml", {eol=>"\n", binary=>1}]);
my $allowed=Data::Tabular::Dumper->available();
my $dumper = Data::Tabular::Dumper->open( XML=>$params{XML} );


## 2-dimentional

#############################################
my $dataLoL = [
    [1..3],
    [4..5],
];

my $state = $dumper->analyse( $dataLoL );
is_deeply( $state, {
    depth => 1,
    maxdepth=>2,
    data => [
        {   depth=>2,
            data=>[1..3],
            maxdepth=>2,
        },
        {   depth=>2,
            data=>[4..5],
            maxdepth=>2,
        }
    ]
}, "LoL" );


#############################################
my $dataHoL = {
    honk => [ qw( dealing card games ) ],
    bonk => [ qw( no one keeping score )]
};

$state = $dumper->analyse( $dataHoL );
is_deeply( $state, {
    depth => 1,
    maxdepth=>2,
    data => [
        {   depth=>2,
            data=>[ qw( bonk no one keeping score ) ],
            maxdepth=>2,
        },
        {   depth=>2,
            data=>[ qw( honk dealing card games ) ],  
            maxdepth=>2,
        }
    ]
}, "HoL" );

#############################################
my $dataLoH = [
    { honk => 42, bonk=>17 },
    { honk => 12, blurf=>36 }
];

$state = $dumper->analyse( $dataLoH );

is_deeply( $state, {
        depth => 1,
        fields => [qw( blurf bonk honk )],
        maxdepth=>2,
        data => [
        {   depth=>2,
            data=>[ undef(), 17, 42 ],  
        #    maxdepth=>2,
        },
        {   depth=>2,
            data=>[ 36, undef(), 12 ],
        #    maxdepth=>2,
        }
    ]
}, "LoH" );

#############################################
my $dataHoH = {
    monday => { honk => 42, bonk=>17 },
    wednesday => { honk => 12, blurf=>36 }
};

$state = $dumper->analyse( $dataHoH );

is_deeply( $state, {
        depth => 1,
        fields => ['', qw( blurf bonk honk )],
        maxdepth=>2,
        data => [
        {   depth=>2,
            data=>[ 'monday', undef(), 17, 42 ],  
        #    maxdepth=>2,
        },
        {   depth=>2,
            data=>[ 'wednesday', 36, undef(), 12 ],
        #    maxdepth=>2,
        }
    ]
}, "HoH" );




#############################################
## 3-dimentional


my $dataLoLoL = [
    [ [15..20], [4..5] ],
    [ [11..13], [4..5] ]
];

$state = $dumper->analyse( $dataLoLoL );

is_deeply( $state, {
   depth => 1,
   maxdepth => 4,
   pages => [
        {   depth=>2,
            maxdepth => 3,
            data=>[ { depth=>3, data=> [15..20], maxdepth => 3 },
                    { depth=>3, data=> [4..5], maxdepth => 3 } ]
        },
        {   depth=>2,
            maxdepth => 3,
            data=>[ { depth=>3, data=> [11..13], maxdepth => 3 },
                    { depth=>3, data=> [4..5], maxdepth => 3 } ]
        }
    ]
  }, "LoLoL") or die "LoLoL=", Dumper $state;



#############################################
my $dataHoLoL = {
    honk => [ [15..20], [4..5] ],
    bonk => [ [11..13], [4..5] ]
};

$state = $dumper->analyse( $dataHoLoL );

is_deeply( $state, {
    depth => 1,
    maxdepth=>4,
    pages => [
        {   depth=>2,
            name=>'bonk',
            maxdepth=>3,
            data=>[ { depth=>3, data=> [11..13], maxdepth=>3 },
                    { depth=>3, data=> [4..5], maxdepth=>3 } ]
        },
        {  name=>'honk',
           depth=>2,
           maxdepth=>3,
           data=>[ { depth=>3, data=> [15..20], maxdepth=>3 },
                   { depth=>3, data=> [4..5], maxdepth=>3 } ]
        },
    ]
}, "HoLoL");


#############################################
my $dataHoLoH = {
    honk => [ { biff=>17, boff=>18 }, {qw(who has all the mst3ks man)} ],
    bonk => [ { billy=>1, bobby=>42 } ]
};

$state = $dumper->analyse( $dataHoLoH );

is_deeply( $state, {
    depth => 1,
    maxdepth => 4,
    pages => [
        {   data => [ { data => [1,42], depth => 3 } ],
            depth => 2,
            fields => [ qw( billy bobby ) ], 
            maxdepth => 3,
            name => 'bonk'
        },
        {   data => [ { data => [ undef(), 17, 18, undef(), undef() ],
                        depth => 3 },
                      { data => [ 'the', undef(), undef(), 'man', 'has' ],
                        depth => 3 },
                    ],
            depth => 2,
            fields => [ qw( all biff boff mst3ks who ) ],
            maxdepth => 3,
            name => 'honk'
        }
    ]
}, "HoLoH" );


#############################################
my $dataHoHoH = {
    honk => { one=>{ biff=>17, boff=>18 }, 
              two=>{qw(who has all the mst3ks man)} 
            },
    bonk => { one=>{ billy=>1, bobby=>42 },
              two=>{ zin=>1, bin=>1 } }
};

$state = $dumper->analyse( $dataHoHoH );

is_deeply( $state, {
    depth => 1,
    maxdepth => 4,
    pages => [ { 
            data => [ { data => [ 'one', 1, undef(), 42, undef() ], 
                        depth => 3 },
                      { data => [ 'two', undef(), 1, undef(), 1 ], 
                        depth => 3 } ],
            depth => 2,
            fields => [ '', qw( billy bin bobby zin ) ],
            maxdepth => 3,
            name => 'bonk'
        },
        { data => [ { data=>[ 'one', undef(), 17, 18, undef(), undef() ], 
                      depth => 3},
                    { data=>[ 'two', 'the', undef(), undef(), qw( man has ) ],
                      depth => 3 }
                  ],
          depth => 2,
          fields => [ '', qw( all biff boff mst3ks who ) ],
          maxdepth => 3,
          name => 'honk'
        }
    ]
}, "HoHoH" );

#############################################
my $dataLoLoH = [
    [ { biff=>17, boff=>18 }, {qw(who has all the mst3ks man)},
      { biff=>42, boff=>42 }, {qw(who 42 all 42 mst3ks 42)}
    ],
    [ { billy=>1, bobby=>42 }, { zin=>1, bin=>1 } ]
];

$state = $dumper->analyse( $dataLoLoH );

is_deeply( $state, {
    depth=>1,
    maxdepth=>4,
    pages => [
        { data => [ { depth => 3, 
                      data=>[ undef(), 17, 18, undef(), undef()] },
                    { depth => 3, 
                      data=>[ 'the', undef(), undef(), qw( man has ) ] },
                    { depth => 3, 
                      data=>[ undef(), 42, 42, undef(), undef() ] },
                    { depth => 3, 
                      data=>[ 42, undef(), undef(), 42, 42 ] },    
                 ],
          depth=>2, fields=>[ qw( all biff boff mst3ks who ) ],
          maxdepth=>3
        },
        {
            data => [ { data => [ 1, undef(), 42, undef() ], depth => 3 },
                      { data => [ undef(), 1, undef(), 1 ], depth => 3 },
                    ],
            depth => 2,
            fields => [ qw( billy bin bobby zin ) ],
            maxdepth => 3
        }
    ]
}, "LoLoH" );


#############################################
my $dataHoHoL = {
    one => { biff=>[1..5], boff=>[17..20] },
    two => { biff=>[17..25], bill=>[1..2] },
};

$state = $dumper->analyse( $dataHoHoL );

$dumper->close;

unlink( $params{XML}[0] ) or die "Unable to unlink $params{XML}[0]: $!";

__END__

$Log$
Revision 1.1  2006/03/24 03:53:11  fil
Initial revision


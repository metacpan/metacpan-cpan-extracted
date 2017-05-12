#!/usr/bin/perl -W
use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw{ gettimeofday tv_interval };
use Benchmark qw( timethese cmpthese );

use constant WIDTH_X => 64;
use constant WIDTH_Y => 64;

my @map; 
use AI::Pathfinding::AStar::Rectangle;
my $m = AI::Pathfinding::AStar::Rectangle->new({ width => WIDTH_X, heigth => WIDTH_Y });

for my $x (0 .. WIDTH_X - 1 )
{
    for my $y (0 .. WIDTH_Y - 1 )
    {
        $map[$x][$y] = 1;
    }
}

$map[5][$_] = 0 for 5 .. WIDTH_Y - 5;
$map[WIDTH_X - 5][$_] = 0 for 5 .. WIDTH_Y - 5;
$map[$_][5] = 0 for 5 .. WIDTH_X - 5;
$map[$_][WIDTH_Y - 5] = 0 for 5 .. WIDTH_X - 10;
$map[$_][10] = 0 for 10 .. WIDTH_X - 10;
$map[WIDTH_X - 10][$_] = 0 for 10 .. WIDTH_Y - 5;
$map[10][$_] = 0 for 10 .. WIDTH_Y - 10;
$map[$_][WIDTH_Y - 10] = 0 for 10 .. WIDTH_X - 15;
$map[WIDTH_X - 15][$_] = 0 for 15 .. WIDTH_Y - 10;
$map[$_][15] = 0 for 15 .. WIDTH_X - 15;

for my $x (0 .. WIDTH_X - 1 )
{
    for my $y (0 .. WIDTH_Y - 1 )
    {
        $m->set_passability($x, $y, $map[$x][$y]) ;
    }
}
my ( $x_start, $y_start ) = ( WIDTH_X >> 1, WIDTH_Y >> 1 );
my ( $x_end, $y_end ) = ( 0, 0 );

my $t0 = [gettimeofday];
my $path;
my $r = timethese( -1, {Perl=>sub { astar( $x_start, $y_start, $x_end, $y_end ) },
                XS=>sub {$m->astar($x_start, $y_start, $x_end, $y_end);}});
cmpthese($r);
die;
for (0..99) {
    $path = &astar( $x_start, $y_start, $x_end, $y_end );
}

print "Elapsed: ".tv_interval ( $t0 )."\n";
print "Path length: ".length($path)."\n";
# start end points
$map[ $x_start ][ $y_start ] = 3;
$map[ $x_end   ][ $y_end   ] = 4;
# draw path
my %vect = (
    #      x  y
    1 => [-1, 1, '|/'], 
    2 => [ 0, 1, '.|'],
    3 => [ 1, 1, '|\\'],
    4 => [-1, 0, '|<'],
    6 => [ 1, 0, '|>'],
    7 => [-1,-1, '|\\'],
    8 => [ 0,-1, '\'|'],
    9 => [ 1,-1, '|/']
);

my ( $x, $y ) = ( $x_start, $y_start );
for ( split //, $path )
{
    $map[$x][$y] = '|o';
    $x += $vect{$_}->[0];
    $y += $vect{$_}->[1];
    $map[$x][$y] = '|o';
}

printf "%02d", $_ for 0 .. WIDTH_X - 1;
print "\n";
for my $y ( 0 .. WIDTH_Y - 1 )
{
    for my $x ( 0 .. WIDTH_X - 1 )
    {
        print $map[$x][$y] eq 
        '1' ? "|_" : ( 
        $map[$x][$y] eq '0' ? "|#" : ( 
        $map[$x][$y] eq '3' ? "|S" : ( 
        $map[$x][$y] eq '4' ? "|E" : $map[$x][$y] ) ) );
    }
    print "$y\n";
}


sub astar
{
    my ( $xs, $ys, $xe, $ye ) = @_;
    my %close;
    my ( %open, @g, @h, @r, @open_idx );
    for my $x (0 .. WIDTH_X - 1 )
    {
        for my $y (0 .. WIDTH_Y - 1 )
        {
            $g[$x][$y] = 0;
            $r[$x][$y] = 0;
            $h[$x][$y] = 0;
        }
    }
    my %cost = (
        "0.-1"  =>  5, #|.
        "1.-1"  =>  7, #/.
        "1.0"   =>  5, #.-
        "1.1"   =>  7, #`\
        "0.1"   =>  5, #`|
        "-1.1"  =>  7, # 
        "-1.0"  =>  5,
        "-1.-1" =>  7
    );
    my $it = 0;
    my $oindx = 0;
    my ( $x, $y ) = ( $xs, $ys );
    while ( $x != $xe || $y != $ye )
    {
        $close{$x}{$y} = 1;
        $open{$x}{$y} = 0;

        for ( "0.-1", "-1.1", "0.1",  "1.1",  "-1.0", "1.-1", "1.0", "-1.-1" )
        {
            my ( $xd, $yd ) = split /\./, $_;
            my ( $xn, $yn ) = ( $x + $xd, $y + $yd );
            
            next if $xn == WIDTH_X ||
                $xn < 0 ||
                $yn == WIDTH_Y ||
                $yn < 0 || 
                $close{$xn}{$yn} || 
                $map[$xn][$yn] == 0;

            my $ng =  $g[$x][$y] + $cost{$_};
            if ( $open{$xn}{$yn} )
            {
                if ( $ng < $g[$xn][$yn] )
                {
                    $r[$xn][$yn] = [$x,$y];
                    $g[$xn][$yn] = $ng;
                }
            }
            else
            {
                $open{$xn}{$yn} = 1;
                $g[$xn][$yn] = $ng;
                my ( $xa, $ya ) = ( abs( $xn - $xe  ), abs( $yn - $ye ) );
                $h[$xn][$yn] = #( $xa > $ya ? $xa : $ya ) * 7;
( abs( $xn - $xe  ) + abs( $yn - $ye ) ) * 7; 
                $r[$xn][$yn] = [$x,$y];
                push @open_idx, [$xn, $yn, \$g[$xn][$yn], \$h[$xn][$yn]];
            }
#           deb($x, $y, $xn, $yn, \@g);
        }
        @open_idx = sort { ${$a->[2]} + ${$a->[3]} <=> ${$b->[2]} + ${$b->[3]} } @open_idx;
        ( $x, $y ) = @{ shift @open_idx };
        $it++;
    }
#   print "Iterations: $it: $oindx\n";
    my $path = "";
    my %idx2path =
    (
        "0.-1"  =>  8, #|.
        "1.-1"  =>  9, #/.
        "1.0"   =>  6, #.-
        "1.1"   =>  3, #`\
        "0.1"   =>  2, #`|
        "-1.1"  =>  1, # 
        "-1.0"  =>  4,
        "-1.-1" =>  7
    );

    while ( $x != $xs || $y != $ys )
    {
#       print "$x:$y\n";
        my ($xp, $yp) = @{$r[$x][$y]};
        $path = $idx2path{($x-$xp).".".($y-$yp)}.$path;
        ( $x, $y ) = ( $xp, $yp);
    }
#   print  "Path: $path\n";
    return $path;
}

sub calc_obstacle
{
    my ( $x1, $y1, $x2, $y2 ) = @_;
    my ( $x, $y, $Xend, $obstacle, $pixel);
    my $dx = abs($x2 - $x1);
    my $dy = abs($y2 - $y1);
    my $d = ( $dy << 1 ) - $dx;
    my $inc1 = $dy << 1;
    my $inc2 = ($dy - $dx) << 1;
    if ( $x1 > $x2)
        {
            $x = $x2;
            $y = $y2;
            $Xend = $x1;
        }
    else
    {
            $x = $x1;
            $y = $y1;
            $Xend = $x2;
        };
    $obstacle+=!$map[$x][$y];
    $pixel+=5;
    while ( $x < $Xend )
        {
            $x++;
            if ($d < 0) {$d += $inc1}
            else
        {
            $y++;
            $d += $inc2;
        };
        $obstacle+=!$map[$x][$y];
        $pixel += 5;
        };

    return ( $obstacle << 3 ) + $pixel;
}

sub deb
{
    my ( $x, $y, $xn, $yn, $g) = @_;
    for my $j ( 0 .. WIDTH_Y - 1 )
    {
        for my $i ( 0 .. WIDTH_X - 1 )
        {
            if ( !$map[$i][$j] )
            {
                print " ##"
            }
            else 
            {
                if ( $x == $i && $y == $j)
                {
                    print "c";
                }
                elsif ( $xn == $i && $yn == $j )
                {
                    print "n";
                }
                else
                {
                    print " ";
                }
                printf "%02d", $g->[$i]->[$j]
            }
        }
        print "\n";
    }
    <>;
}



#!/usr/bin/env perl
use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use PDL::Finance::TA;
use PDL::Graphics::Gnuplot;
use JSON::XS qw(decode_json);
use LWP::UserAgent;
use DateTime;
use Try::Tiny;
use Path::Tiny;

sub get_data($) {
    my $symbol = shift;
    my $filename = lc "$symbol.json";
    my $content;
    my $qdata;
    my $url = sprintf("https://api.gemini.com/v2/candles/%s/%s", lc $symbol, '1day');
    if (-e $filename) {
        print "Found $filename, loading data from that\n";
        $content = path($filename)->slurp;
    } else {
        my $lwp = LWP::UserAgent->new(timeout => 60);
        $lwp->env_proxy;
        my $resp = $lwp->get($url);
        if ($resp->is_success) {
            $content = $resp->decoded_content;
            path($filename)->spew($content);
        } else {
            warn "Error from request to $url: " . $resp->status_line;
            return undef;
        }
    }
    if (defined $content and length($content)) {
        my $jquotes = decode_json $content;
        if (ref $jquotes eq 'ARRAY' and scalar(@$jquotes)) {
            ## sort quotes by timestamp
            my @sorted = sort { $a->[0] <=> $b->[0] } @$jquotes;
            foreach my $q (@sorted) {
                ## timestamp is the first column in milliseconds
                $q->[0] /= 1000;
            }
            ## convert the quotes to a PDL
            $qdata = pdl(@sorted)->transpose;
        } else {
            warn "No quotes returned by $url or $filename";
            $qdata = undef;
        }
    } else {
        warn "No content received from $url or $filename";
        $qdata = undef;
    }
    ## now we operate on the $qdata PDL object
    return $qdata;
}

my $symbol = $ARGV[0] // 'DOGEUSD';
my $qdata = get_data($symbol);
die "Unable to get data for $symbol" unless ref $qdata eq 'PDL';
print $qdata;

my $timestamp = $qdata(, (0));
my $open_px = $qdata(, (1));
my $high_px = $qdata(, (2));
my $low_px = $qdata(, (3));
my $close_px = $qdata(, (4));
## use the default values
## each of these are 1-D PDLs
my ($bb_upper, $bb_middle, $bb_lower) = PDL::ta_bbands($close_px, 5, 2, 2, 0);
my $buys            = zeroes( $close_px->dims );
my $sells           = zeroes( $close_px->dims );
## use a 1 tick lookback
my $lookback        = 1;
## calculate the indexes of the lookback PDL based on LOW price
my $idx_0           = xvals( $low_px->dims ) - $lookback;
## if the lookback index is negative set it to 0
$idx_0 = $idx_0->setbadif( $idx_0 < 0 )->setbadtoval(0);
## get the indexes of when the LOW Price < Lower Bollinger Band based on the lookback
my $idx_1 = which( 
        ($low_px->index($idx_0) > $bb_lower->index($idx_0)) &
        ($low_px < $bb_lower)
);
## set the buys to be on the OPEN price for those indexes
$buys->index($idx_1) .= $open_px->index($idx_1);
## set all 0 values to BAD to avoid plotting zeroes
$buys->inplace->setvaltobad(0);

## calculate the indexes of the lookback PDL based on HIGH price
my $idx_2 = xvals( $high_px->dims ) - $lookback;
## if the lookback index is negative set it to 0
$idx_2 = $idx_2->setbadif( $idx_2 < 0 )->setbadtoval(0);
## get the indexes of when the HIGH Price > Upper Bollinger Band based on the lookback
my $idx_3 = which(
    ($high_px->index($idx_2) < $bb_upper->index($idx_2)) &
    ($high_px > $bb_upper )
);
## set the sells to be on the CLOSE price for those indexes
$sells->index($idx_3) .= $close_px->index($idx_3);
## set all 0 values to BAD to avoid plotting zeroes
$sells->inplace->setvaltobad(0);

## plot the data
my $pwin = gpwin(size => [1024, 768, 'px']);
$pwin->reset;
$pwin->multiplot;
$pwin->plot({
        object => '1 rectangle from screen 0,0 to screen 1,1 fillcolor rgb "black" behind',
        title => ["$symbol Open-High-Low-Close", textcolor => 'rgb "white"'],
        key => ['on', 'outside', textcolor => 'rgb "yellow"'],
        border => 'linecolor rgbcolor "white"',
        xlabel => ['Date', textcolor => 'rgb "yellow"'],
        ylabel => ['Price', textcolor => 'rgb "yellow"'],
        xdata => 'time',
        xtics => {format => '%Y-%m-%d', rotate => -90, textcolor => 'orange', },
        ytics => {textcolor => 'orange'},
        label => [1, $symbol, textcolor => 'rgb "cyan"', at => "graph 0.90,0.03"],
    },
    {
        with => 'financebars',
        linecolor => 'white',
        legend => 'Price',
    },
    $timestamp,
    $open_px,
    $high_px,
    $low_px,
    $close_px,
    ### Bollinger Bands plot
    {
        with => 'lines',
        axes => 'x1y1',
        linecolor => 'dark-green',
        legend => 'Bollinger Band - Upper'
    },
    $timestamp,
    $bb_upper, #upper band
    {
        with => 'lines',
        axes => 'x1y1',
        linecolor => 'dark-magenta',
        legend => 'Bollinger Band - Lower'
    },
    $timestamp,
    $bb_lower, #lower band
    {
        with => 'lines',
        axes => 'x1y1',
        linecolor => 'orange',
        legend => 'Bollinger Band - Middle'
    },
    $timestamp,
    $bb_middle, #middle band
    {
        with => 'points',
        pointtype => 5, #triangle
        linecolor => 'green',
        legend => 'Buys',
    },
    $timestamp,
    $buys,
    {
        with => 'points',
        pointtype => 7, #inverted triangle
        linecolor => 'red',
        legend => 'Sells',
    },
    $timestamp,
    $sells,
);
$pwin->end_multi;

$pwin->pause_until_close;

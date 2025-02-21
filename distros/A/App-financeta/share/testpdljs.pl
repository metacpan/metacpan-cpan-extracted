#!/usr/bin/env perl
use strict;
use warnings;
use PDL;
use PDL::NiceSlice;
use PDL::Finance::TA;
use JSON::XS qw(decode_json encode_json);
use LWP::UserAgent;
use DateTime;
use Try::Tiny;
use Path::Tiny;
use Template;
use Browser::Open;

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

## plot the data using Javascript in a Browser
## we have to create multiple objects
my @charts = ();
## convert the PDL to javascript and write to a file
## HighCharts requires timestamp in milliseconds
## each object should have the 5 dimensions: timestamp_ms, open, high, low, close - hence we transpose the PDL
my $px_pdl_js = encode_json pdl($timestamp * 1000, $open_px, $high_px, $low_px, $close_px)->transpose->unpdl;
push @charts, {
    title => $symbol,
    data => $px_pdl_js,
    type => 'candlestick',
    id => lc "candlestick-$symbol",
    y_axis => 0,
};
## add the indicator chart. Bollinger Bands are on the same axis as the price, so y_axis is 0
## we need to remove the BAD values completely from the new PDL
my $bb_upper_2 = pdl($timestamp * 1000, $bb_upper)->transpose;
my $bbu_idx = $bb_upper_2((1))->which;
my $bb_upper_clean = $bb_upper_2->dice_axis(1, $bbu_idx);
my $bb_upper_js = encode_json $bb_upper_clean->unpdl;

my $bb_middle_2 = pdl($timestamp * 1000, $bb_middle)->transpose;
my $bbm_idx = $bb_middle_2((1))->which;
my $bb_middle_clean = $bb_middle_2->dice_axis(1, $bbm_idx);
my $bb_middle_js = encode_json $bb_middle_clean->unpdl;

my $bb_lower_2 = pdl($timestamp * 1000, $bb_lower)->transpose;
my $bbl_idx = $bb_lower_2((1))->which;
my $bb_lower_clean = $bb_lower_2->dice_axis(1, $bbl_idx);
my $bb_lower_js = encode_json $bb_lower_clean->unpdl;

push @charts, {
    title => 'Bollinger Band - Upper',
    type => 'line',
    data => $bb_upper_js,
    id => lc "bb-upper-$symbol",
}, {
    title => 'Bollinger Band - Middle',
    type => 'line',
    data => $bb_middle_js,
    id => lc "bb-middle-$symbol",
}, {
    title => 'Bollinger Band - Lower',
    type => 'line',
    data => $bb_lower_js,
    id => lc "bb-lower-$symbol",
};

## for buys and sells we just want to avoid empty data
my $buys_2 = pdl($timestamp * 1000, $buys)->transpose;
my $bidx = $buys_2((1))->which;## check if !0 is true
my $clean_buys = $buys_2->dice_axis(1, $bidx);
my $buys_js = encode_json $clean_buys->unpdl;
push @charts, {
    title => 'Buy Signals',
    data => $buys_js,
    y_axis => 0,
    type => 'line',
    marker_symbol => 'triangle',
    marker_color => 'green',
    is_signal => 1,
};

my $sells_2 = pdl($timestamp * 1000, $sells)->transpose;
my $sidx = $sells_2((1))->which;## check if !0 is true
my $clean_sells = $sells_2->dice_axis(1, $sidx);
my $sells_js = encode_json $clean_sells->unpdl;
push @charts, {
    title => 'Sell Signals',
    data => $sells_js,
    y_axis => 0,
    type => 'line',
    marker_symbol => 'triangle-down',
    marker_color => 'red',
    is_signal => 1,
};
## create variables to pass to the template
my $ttconf = {
    page => { title => "Plot $symbol with HighCharts" },
    chart => { height => "600px", yaxes_index => [0], charts => \@charts, title => $symbol },
};
## load a pre-designed Template file 
my $ttcontent = do { local $/ = undef; <DATA> };
## dump it as a template file for the browser to load it
my $ttfile = path('pdlchart.tt')->realpath;
path($ttfile)->spew($ttcontent) unless -e $ttfile;
print "TTFile: $ttfile\n";
my $htmlfile = path('pdlchart.html')->realpath;
print "HTMLFile: $htmlfile\n";

my $tt = Template->new({ ABSOLUTE => 1 });
my $ret = $tt->process("$ttfile", $ttconf, "$htmlfile", { binmode => ':utf8' });
if ($ret) {
    my $url = "file://$htmlfile";
    print "opening $url\n";
    my $ok = Browser::Open::open_browser($url, 1);
    if (not defined $ok or $ok != 0) {
        die "Failed to open $url in a browser. Return value: $ok";
    } else {
        print "Successfully opened $url in browser\n";
    }
} else {
    die "Error processing template $ttfile: " . $tt->error() . "\n";
}


__DATA__
<!DOCTYPE HTML>
<html lang="en">
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="copyright" content="App::financeta Authors">
    <meta name="author" content="Vikas N Kumar <vikas@cpan.org>">
    <meta name="description" content="App::financeta">
    <link rel="icon" href="chart-line-solid.png" type="image/png">
    <title>[% page.title %]</title>
    <script src="https://code.highcharts.com/stock/highstock.js"></script>
    <style>
    #chart-container {
        min-width: 600px;
        min-height: 400px;
        height: [% chart.height %];
        width: 95%;
        margin: 20px;
    };
    </style>
    </head>
    <body>
        <h1>[% page.title %]</h1>
        <hr/>
        <div id="chart-container">
        </div>
        <hr/>
    <script type="text/javascript">
        [% IF chart %]
        var yaxes = [];
        [% FOREACH el IN chart.yaxes_index %]
            [% SWITCH el %]
            [% CASE 0 %]
                yaxes.push({
                    labels: { align: 'left' },
                    height: "400px",
                    resize: { enabled: true },
                });
            [% CASE 1 %]
                yaxes.push({
                    labels: { align: 'left' },
                    top: "400px",
                    height: "200px",
                    opposite: true,
                    offset: 0,
                    resize: { enabled: true },
                });
            [% CASE 2 %]
                yaxes.push({
                    labels: { align: 'left' },
                    top: "600px",
                    height: "200px",
                    opposite: true,
                    offset: 0,
                    resize: { enabled: true },
                });
            [% CASE 3 %]
                yaxes.push({
                    labels: { align: 'left' },
                    top: "800px",
                    height: "200px",
                    opposite: true,
                    offset: 0,
                    resize: { enabled: true },
                });
            [% CASE 4 %]
                yaxes.push({
                    labels: { align: 'left' },
                    top: "1000px",
                    height: "200px",
                    opposite: true,
                    offset: 0,
                    resize: { enabled: true },
                });
            [% END %]
        [% END %]
        window.chart = new Highcharts.stockChart('chart-container', {
            accessibility: { enabled: false },
            yAxis: yaxes,
            title: { text: "[% chart.title %]" },
            series:[
            [% FOREACH el IN chart.charts %]
                {
                    type: "[% el.type %]",
                    name: "[% el.title %]",
                    id: "[% el.id %]",
                    data: [% el.data %],
                    [% IF el.y_axis %]
                    yAxis: [% el.y_axis %],
                    [% END %]
                    [% IF el.is_signal %]
                    lineWidth: 0,
                    showInLegend: true,
                    marker: {
                        enabled: true,
                        fillColor: "[% el.marker_color %]",
                        radius: 4,
                        symbol: "[% el.marker_symbol %]",
                    },
                    [% END %]
                    [% IF el.type == 'area' %]
                    color: 'green',
                    negativeColor: 'red',
                    threshold: 0,
                    marker: { enabled: true },
                    [% END %]
                },
            [% END %]
            ],
            responsive: {
                rules: [{
                    condition: { maxWidth: 800 },
                    chartOptions: {
                        rangeSelector: {
                            inputEnabled: false
                        }
                    }
                }]
            }
        });
        [% END %]
    </script>
    </body>
</html>

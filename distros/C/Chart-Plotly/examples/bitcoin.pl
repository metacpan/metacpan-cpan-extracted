#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use Chart::Plotly;
use Chart::Plotly::Plot;
use Chart::Plotly::Trace::Ohlc;

use JSON;
use DateTime;
use DateTimeX::TO_JSON;

# Example using bitcoin data to show financial type charts: ohlc & candlesticks
# Thanks to Bryan Parker for the idea!

my $content = get_bitcoin_data();

my $ohlc = Chart::Plotly::Trace::Ohlc->new(%$content);

my $plot = Chart::Plotly::Plot->new( traces => [$ohlc],
                                     layout => { xaxis => { rangeslider => { visible => JSON::true } } } );

Chart::Plotly::show_plot($plot);

use Chart::Plotly::Trace::Candlestick;

my $candlestick = Chart::Plotly::Trace::Candlestick->new(%$content);

my $plot_with_grid = Chart::Plotly::Plot->new(
    traces => [$candlestick],
    layout => {
        xaxis => { rangeslider => { visible => JSON::false },
                   gridcolor   => '#000',
                   gridwidth   => 1
        },
        yaxis => {
            gridcolor => '#000',
            gridwidth => 1,
            dtick => 1
        }
    }
);

Chart::Plotly::show_plot($plot_with_grid);

sub get_bitcoin_data {
    use LWP::UserAgent;
    use HTTP::CookieJar::LWP;
    my $ua = LWP::UserAgent->new( cookie_jar => HTTP::CookieJar::LWP->new );
    $ua->agent('Mozilla/5.0');    # LWP UserAgent banned by default... Don't shoot the messenger...
    $ua->default_header( 'Content-Type' => 'application/json' );
    my $response = $ua->get('https://api.pro.coinbase.com/products/BTC-EUR/candles');

    if ( $response->is_success() ) {
        my $data = from_json( $response->decoded_content );
        my ( @x, @open, @close, @high, @low );
        for my $candle (@$data) {
            push @x, DateTime->from_epoch( epoch => $candle->[0] );
            push @low,   $candle->[1];
            push @high,  $candle->[2];
            push @open,  $candle->[3];
            push @close, $candle->[4];
        }
        return { x     => \@x,
                 open  => \@open,
                 close => \@close,
                 high  => \@high,
                 low   => \@low
        };
    } else {
        return { x     => [ 1 .. 5 ],
                 open  => [ 1, 6, 7 ],
                 close => [ 7, 12, 5 ],
                 high  => [ 8, 15, 10 ],
                 low   => [ 0.5, 5, 4 ]
        };
    }
}

#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Dash;
use aliased 'Dash::Core::Components' => 'dcc';
use aliased 'Dash::Html::Components' => 'html';
use aliased 'Dash::Dependencies'     => 'deps';

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

my $app = Dash->new(
    app_name => 'Dash Tutorial - 4 More About Callbacks: Prevent Update',
    external_stylesheets => $external_stylesheets
);

$app->layout(
    html->Div(
        [
            html->P('Enter a composite number to see its prime factors'),
            dcc->Input(
                id       => 'num',
                type     => 'number',
                debounce => JSON::true,
                min      => 1,
                step     => 1
            ),
            html->P( id => 'err', style => { color => 'red' } ),
            html->P( id => 'out' )
        ]
    )
);

sub prime_factors {
    my $num = shift;
    my ($n, $i, $out) = ($num, 2, []);
    while ($i * $i <= $n) {
        if ($n % $i == 0) {
            $n = int($n / $i);
            push @$out, $i;
        } else {
            $i += ($i == 2) ? 1 : 2;
        }
    }
    push @$out, $n;
    return $out;
}

$app->callback(
    [ deps->Output( 'out', 'children' ), deps->Output( 'err', 'children' ) ],
    [ deps->Input( 'num', 'value' ) ],
    sub {
        my $num = shift;
        if ( !defined $num ) {
            Dash::Exceptions::PreventUpdate->throw();
        }
        my $factors =  prime_factors($num);
        if (scalar @$factors == 1) {
            return Dash::no_update, "$num is prime!";
        }
        my $factors_output = $num . " is " . join(' * ', @$factors);
        return $factors_output, '';
    }
);

$app->run_server();

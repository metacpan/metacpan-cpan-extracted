## Please see file perltidy.ERR
## Please see file perltidy.ERR
#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Dash;
use aliased 'Dash::Core::Components' => 'dcc';
use aliased 'Dash::Html::Components' => 'html';
use Text::CSV;
use IO::All;

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

my $csv = Text::CSV::csv(
    in => io(
'https://gist.githubusercontent.com/chriddyp/c78bf172206ce24f77d6363a2d754b59/raw/c353e8ef842413cae56ae3920b8fd78468aa4cb2/usa-agricultural-exports-2011.csv'
    )
);

sub generate_table {
    my ( $data, $max_rows ) = @_;
    $max_rows //= 10;

    return html->Table(
        children => [
            html->Tr(
                children =>
                  [ map { html->Th( children => $_ ) } @{ $csv->[0] } ]
            ),
            map {
                html->Tr(
                    children => [ map { html->Td( children => $_ ) } @{$_} ] )
            } @{$csv}[ 1 .. $max_rows ]
        ]
    );
}

my $app = Dash->new(
    app_name             => 'Dash Tutorial - 2 Layout',
    external_stylesheets => $external_stylesheets
);

$app->layout(
    html->Div(
        children => [
            html->H4( children => 'US Agriculture Exports (2011)' ),
            generate_table($csv)
        ]
    )
);

$app->run_server();


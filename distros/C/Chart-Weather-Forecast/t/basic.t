use Chart::Weather::Forecast::Temperature;
use Try::Tiny;
use Test::More;
use Data::Dumper::Concise;

my $highs = [ 37, 28, 17, 22, 28, 25, 23 ];
my $lows  = [ 18, 14, -4, 10, 18, 17, 15 ];

# Test basic flow
my $issue;
my $forecast;
try {
    $forecast = Chart::Weather::Forecast::Temperature->new(
        highs       => $highs,
        lows        => $lows,
        chart_width => 280,
    );
    $forecast->create_chart;
}
catch {
    $issue = $_;
};
is( $issue, undef, 'Canonical work flow' );

SKIP: 
{
    eval 'use Image::Imlib2';
    skip( 'because Image::Imlib2 is required to test output image', 1 ) if $@;
        
    # Test we can read the image, its width in particular
    my $image = Image::Imlib2->load($forecast->chart_temperature_file);
    is($image->width, 280, 'chart width');

}

# Test that highs and lows are required
my $no_highs_failure = 0;
try {
    my $temperature_forecast = Chart::Weather::Forecast::Temperature->new(
        highs => [],
        lows  => [ 32, 45, 72 ],
    );
}
catch {
    $no_highs_failure = 1;
};
is( $no_highs_failure, 1, 'Constructor fails when no highs passed' );

my $no_lows_failure = 0;
try {
    my $temperature_forecast = Chart::Weather::Forecast::Temperature->new(
        highs => [ 32, 45, 72 ],
        lows  => [],
    );
}
catch {
    $no_lows_failure = 1;
};
is( $no_lows_failure, 1, 'Constructor fails when no lows passed' );

done_testing();

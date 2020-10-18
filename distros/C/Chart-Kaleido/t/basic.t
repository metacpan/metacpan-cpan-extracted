#!perl

use 5.010;
use warnings;

use JSON;
use Path::Tiny;

use Test2::V0;
use Chart::Kaleido::Plotly;

sub check_file_type {
    my ( $file, $expected ) = @_;
  SKIP: {
        eval { require File::LibMagic; };
        if ($@) {
            skip "requires File::LibMagic", 1;
            return;
        }
        my $magic = File::LibMagic->new;
        my $info  = $magic->info_from_filename("$file");
        if ( ref($expected) eq 'Regexp' ) {
            like( $info->{mime_type}, $expected );
        }
        else {
            is( $info->{mime_type}, $expected );
        }
    }
}

my $kaleido = Chart::Kaleido::Plotly->new();

diag "kaleido args: " . join( ' ', @{ $kaleido->kaleido_args } );

ok("create kaleido object");

my $data = decode_json(<<'END_OF_TEXT');
{ "data": [{"y": [1,2,1]}] }
END_OF_TEXT

# TODO: Seems there is an issue with IPC::Run and File::Temp on Windows,
# that if a tempdir is created before IPC::Run::start, it can have
# permission error..
if ( $^O eq 'MSWin32' ) {
    $kaleido->ensure_kaleido;
}
my $tempdir = Path::Tiny->tempdir;

my $png_file = path( $tempdir, "foo.png" );
$kaleido->save(
    file   => $png_file,
    plot   => $data,
    width  => 1024,
    height => 768
);
ok( ( -f $png_file ), "generate png" );
check_file_type( $png_file, 'image/png' );

my $svg_file = path( $tempdir, "foo.svg" );
$kaleido->save(
    file   => $svg_file,
    plot   => $data,
    width  => 1024,
    height => 768
);
ok( ( -f $svg_file ), "generate svg" );
check_file_type( $svg_file, qr/^(image\/svg|text\/plain)/ );

SKIP: {
    eval {
        require Chart::Plotly::Plot;
        require Chart::Plotly::Trace::Scatter;
    };
    if ($@) {
        skip "requires Chart::Plot", 1;
    }

    my $x       = [ 1 .. 15 ];
    my $y       = [ map { rand 10 } @$x ];
    my $scatter = Chart::Plotly::Trace::Scatter->new( x => $x, y => $y );
    my $plot    = Chart::Plotly::Plot->new();
    $plot->add_trace($scatter);

    $kaleido->transform(plot => $plot);
    pass("Chart::Plotly::Plot object as 'plot' parameter");
}

done_testing;

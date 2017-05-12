use strict;
use Test::More;
use Audio::Analyzer::ToneDetect;

use FindBin;

{
    my $td = Audio::Analyzer::ToneDetect->new(
        source => "${FindBin::Bin}/data/01.wav" );

    is( ref $td, 'Audio::Analyzer::ToneDetect',
        'object blessed w/ correct class' );
    is( $td->get_next_two_tones, '984.375 640.625', 'get two tones scalar' );

    {
        my @two = $td->get_next_two_tones;
        ok( @two, 'get two tones list...' );
        is( $two[0], 1515.625, '   ... tone a' );
        is( $two[1], 1234.375, '   ... tone b' );
    }
}

{
    my $td = Audio::Analyzer::ToneDetect->new(
        source      => "${FindBin::Bin}/data/01.wav",
        valid_tones => 'builtin'
    );

    is( $td->get_next_two_tones, '984.4 640.6',
        'valid_tones corrects tones to closest valid' );

    my @tone_with_error = $td->get_next_tone;
    ok( @tone_with_error, 'get_next_tone in list context w/valid list' );
    is( $tone_with_error[0], '1530.0', '   ... closest valid tone is correct' );
    is( $tone_with_error[1], '-14.375',
        '   ... delta detected to valid is correct' );
}

{
    my $callback_success = 0;
    my $td               = Audio::Analyzer::ToneDetect->new(
        source         => "${FindBin::Bin}/data/01.wav",
        valid_tones    => 'builtin',
        valid_error_cb => sub {
            $callback_success = 1
                if $_[0] == 984.4 && $_[1] == 984.375 && $_[2] == $_[1] - $_[0];
            return undef;
        } );
    my $tone = $td->get_next_tone;

    ok( $callback_success, 'valid_error_cb called with correct args' );
    is( $tone, 984.4, '   ... returning undef doesn\'t change tone' );

    $td->{valid_error_cb} = sub { return 10 };

    is( $td->get_next_tone, 10, '   ... returning a tone replaces valid tone' );

    $td->{valid_error_cb} = sub { return 0 };

    is( $td->get_next_tone, undef, '   ... returning 0 discards tone' );

    my $orig = $td->valid_tones();
    is( ref($orig), 'ARRAY', 'valid_tones() returns an array ref' );

    cmp_ok( scalar(@$orig), '>=', 200, '   ... that looks right' );

    $td->valid_tones( [ 1, 3, 2 ] );

    my $cur = $td->valid_tones();
    cmp_ok( scalar(@$cur), '==', 3, '   ... passing new array ref replaces' );

    is_deeply( $cur, [ 1, 2, 3 ], '   ... that is sorted' );
}

done_testing;

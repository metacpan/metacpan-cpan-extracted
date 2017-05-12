package Audio::Analyzer::ToneDetect;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.04';

use Audio::Analyzer;
use Carp;
use Sort::Key::Top 'rnkeytop';

sub new {
    my ( $class, %args ) = @_;

    my $self = bless {}, $class;

    $self->{source}          = delete $args{source}          || \*STDIN;
    $self->{sample_rate}     = delete $args{sample_rate}     || 16000;
    $self->{chunk_size}      = delete $args{chunk_size}      || 1024;
    $self->{chunk_max}       = delete $args{chunk_max}       || 70;
    $self->{min_tone_length} = delete $args{min_tone_length} || 0.5;
    $self->{valid_tones}     = delete $args{valid_tones};
    $self->{valid_error_cb}  = delete $args{valid_error_cb};
    $self->{rejected_freqs}  = delete $args{rejected_freqs}  || [];

    if ( $self->{valid_tones} && $self->{valid_tones} eq 'builtin' ) {
        $self->{valid_tones} = _get_builtin_tones();
    }

    croak(
        "Invalid chunk_size ($self->{chunk_size}). chunk_size must be power of 2"
    ) unless _is_pow_of_two( $self->{chunk_size} );

    $self->{chunks_required}
        = int(
        $self->{min_tone_length} * $self->{sample_rate} / $self->{chunk_size} );

    $self->{analyzer} = Audio::Analyzer->new(
        file        => $self->{source},
        sample_rate => $self->{sample_rate},
        dft_size    => $self->{chunk_size},
        channels    => 1,
        %args
    );

    $self->{freqs} = $self->{analyzer}->freqs;

    return $self;
}

sub valid_tones {
    my ( $self, $new_tone_map ) = @_;
    $self->{valid_tones} = [ sort @$new_tone_map  ] if $new_tone_map;
    return $self->{valid_tones};
}

sub get_next_tone {
    my $self            = shift;
    my $min_tone_length = shift;

    state $last_detected = 0;
    state @buff;

    my $chunks_required;
    if ($min_tone_length) {
        $chunks_required = int(
            $min_tone_length * $self->{sample_rate} / $self->{chunk_size} );
    }
    $chunks_required ||= $self->{chunks_required};

    my $chunk_count = 0;
    while ( $chunk_count < $self->{chunk_max} ) {
        $chunk_count++;
        my $chunk = $self->{analyzer}->next;
        my $fft   = $chunk->fft;
        my $top   = rnkeytop { $fft->[0][$_] } 1 => 0 .. $#{ $fft->[0] };
        my $detected_freq = $self->{freqs}[$top];
        next if $detected_freq == $last_detected;
        next if grep { $_ == $detected_freq } @{ $self->{rejected_freqs} };

        push @buff, $detected_freq;
        shift @buff if @buff > $chunks_required;
        next unless @buff == $chunks_required && _all_match( \@buff );
        $last_detected = $detected_freq;

        return $detected_freq unless $self->{valid_tones};

        my ( $valid_tone, $delta ) = $self->find_closest_valid($detected_freq);
        next unless $valid_tone;
        return wantarray ? ( $valid_tone, $delta ) : $valid_tone;
    }
    return;
}

sub get_next_two_tones {
    my $self = shift;
    my ( $tone_a_length, $tone_b_length ) = @_;

    my $tone_a = $self->get_next_tone($tone_a_length) || return;
    my $tone_b = $self->get_next_tone($tone_b_length) || return;
    return wantarray ? ( $tone_a, $tone_b ) : "$tone_a $tone_b";
}

sub find_closest_valid {
    my ( $self, $freq ) = @_;
    my $lower = 0;
    my $upper;

    for my $possibility ( @{ $self->{valid_tones} } ) {
        last if $upper;
        $lower = $possibility if $possibility <= $freq;
        $upper = $possibility if $possibility > $freq;
    }
    $upper ||= $lower;
    my $valid_tone
        = ( $freq - $lower ) < ( $upper - $freq )
        ? $lower
        : $upper;

    if ( $self->{valid_error_cb} ) {
        my $cb_result = $self->{valid_error_cb}
            ->( $valid_tone, $freq, $freq - $valid_tone );
        if ( defined $cb_result ) {
            return if $cb_result == 0;
            $valid_tone = $cb_result;
        }
    }

    return ( $valid_tone, $freq - $valid_tone );
}

sub _all_match { my $l = shift; $_ == $l->[0] || return 0 for @$l; return 1 }

sub _is_pow_of_two {

    # if pow of 2 exactly 1 bit is set all others unset and n - 1 will have
    # that bit unset and all lower bits set thus binary AND of n & n -1 will
    # result in 0
    return $_[0] != 0 && ( $_[0] & ( $_[0] - 1 ) ) == 0;
}

sub _get_builtin_tones {

    # via http://sourceforge.net/projects/tonedetect/ not sure complete/accurate
    # want better list

    return [ ( qw (
                282.2 288.5 294.7 296.5 304.7 307.8 313.0 321.4 321.7
                330.5 335.6 339.6 346.7 349.0 350.5 358.6 358.9 366.0
                368.5 371.5 378.6 382.3 384.6 389.0 398.1 399.2 399.8
                410.8 412.1 416.9 422.1 426.6 433.7 435.3 441.6 445.7
                454.6 457.1 457.9 470.5 473.2 474.8 483.5 489.8 495.8
                496.8 507.0 510.5 517.5 517.8 524.6 524.8 532.5 539.0
                540.7 543.3 547.5 553.9 562.3 562.5 564.7 569.1 577.5
                582.1 584.8 589.7 592.5 600.9 602.6 604.2 607.5 615.8
                617.4 622.5 623.7 631.5 634.5 637.5 640.6 643.0 645.7
                651.9 652.6 662.3 667.5 668.3 669.9 672.0 682.5 688.3
                691.8 693.0 697.5 701.0 707.3 712.5 716.7 726.8 727.1
                727.5 732.0 741.3 746.8 757.5 761.3 765.0 767.4 767.4
                772.5 787.5 788.5 794.3 795.4 799.0 802.5 810.2 817.5
                822.2 832.5 832.5 832.9 834.0 847.5 851.1 855.5 862.5
                870.5 871.0 877.5 879.0 881.0 892.5 903.2 907.9 910.0
                911.5 912.0 922.5 928.1 937.5 944.1 950.0 952.4 952.5
                953.7 967.5 977.2 979.9 984.4 992.0 996.8 1006.9 1011.6
                1034.7 1036.0 1041.2 1047.1 1063.2 1082.0 1084.0 1089.0 1092.4
                1122.1 1122.5 1130.0 1140.2 1153.4 1161.4 1180.0 1185.2 1191.4
                1217.8 1232.0 1246.0 1251.4 1285.8 1287.0 1304.0 1321.2 1344.0
                1357.6 1362.1 1395.0 1403.0 1423.5 1433.4 1465.0 1488.4 1530.0
                1556.7 1598.0 1628.3 1642.0 1669.0 1717.1 1743.0 1795.6 1820.0
                1877.5 1901.0 1985.0 2051.6 2073.0 2143.8 2164.0 2260.0 2341.8
                2361.0 2447.6 2465.0 2556.9 2575.0 2672.9 2688.0 2792.4 2807.0
                2932.0 3062.0 3197.0 3339.0 3487.0 )
        ) ];
}

1;
__END__

=encoding utf-8

=head1 NAME

Audio::Analyzer::ToneDetect - Detect freq of tones in an audio file or stream

=begin HTML

<a href="https://travis-ci.org/mikegrb/Audio-Analyzer-ToneDetect"><img src="https://api.travis-ci.org/mikegrb/Audio-Analyzer-ToneDetect.png" width="77" height="19" alt="Build Status" /></a>

=end HTML

=head1 SYNOPSIS

  use Audio::Analyzer::ToneDetect;
  my $tone_detect = Audio::Analyzer::ToneDetect->new( source => \*STDIN );
  my $tone = $tone_detect->get_next_tone();
  say "I heard $tone!";

=head1 DESCRIPTION

Consider this alpha software.  It is still under fairly active development and
the interface may change in incompatible ways.

Audio::Analyzer::ToneDetect is a module for detecting single frequency tones
in an audio stream or file.  It supports mono PCM data and defaults to STDIN.
For supporting other formats, eg MP3, you can pipe things through sox.

=head1 USAGE

=head2 new (%opts)

Takes the following named parameters:

=over 4

=item source \*FH or $path

The audio source.  Only Mono PCM is supported.  You can pass the path to a WAV
file or a file handle for an open file or stream.  Defaults to STDIN.


=item sample_rate 16000

Source sample rate, results will be orders of magnitude off if set incorrectly.
Defaults to 16000.

=item chunk_size 1024

Number of samples to analyze at once.  Corresponds to dft_size in L<Audio::Analyzer>.
Must be a power of 2.  Defaults to 1024.

=item chunk_max 70

Maximum number of chunks to process before returning.  Returns false if it
reaches this number of chunks without detecting a tone. With default chunk_size
and sample_rate, the default of 70 equates to about 4.5 seconds of audio.

=item min_tone_length 0.5

Minimum durration of a tone, in seconds, before we consider it detected.  Due to
sample rate, chunk size, and integer math, with defaults this ends up being
0.448 seconds.  The formula for actual seconds is int( min_length * sample_rate
/ chunk_size ) * chunk_size / sample_rate.  Default to 0.5

=item valid_tones undef, 'builtin', or ARRAYREF

A list of valid (expected) tones.  If supplied, the closest expected tone for
a given detected tone is returned. Call get_next_tone() in list context or
supply the following call back if you want both values.  A value of 'builtin'
uses a builtin list of valid classic Motorola Minitor tones.  Defaults to unset.

=item valid_error_cb

A callback that if provided and valid_tones is set will be called just before
get_next_tone or find_closest_valid returns.  Arguments are the closest valid
tone, the actual detected tone, the diference between the two in Hertz.

Example:

  valid_error_cb => sub { printf "VF %s DF %s EF %.2f\n", @_; return }

Return value is expected to be one of three possibilities.

=over 4

=item undef

Has no effect on program flow, if you don't want your call back changing stuff
make sure you have an explicit 'return' as the last line.

=item Zero (the number)

A return value of 0 discards the tone and continues the get_next_tone loop.

=item N

Any other value replaces the valid detected tone with the return value from the
call back.

=back

=item rejected_freqs undef or ARRAYREF

If specified, a reference to an array of frequencies that will be ignored. e.g
roger beeps, repeater beeps, etc.  Note, if you use valid tone detection, then
this is the raw detected tone, not the closest match.  Defaults to empty list.

=back

=head2 valid_tones

Returns the arraref of valid tones currently being used.  Optionally takes a
reference to an array of new tones to use that will be copied to replace the
current valid list.

=head2 get_next_tone

Returns the next detected tone in the stream.  Will return false if we go
through chunk_max without detecting a tone but the buffer will be preserved
between calls if the a tone begins just before hitting chunk_max.  If valid_tones
was supplied, returns the result of passing the tone to find_closest_valid(),
following it's list vs scalar semantics.

=head2 get_next_two_tones

Calls get next tone twice.  Will return false if either tone returns false.

=head2 find_closest_valid

In scalar context, returns the closest valid tone in valid_tones.  In list
context returns the closest valid tone and the delta from detected tone.

=head1 AUTHOR

Mike Greb E<lt>michael@thegrebs.comE<gt>

=head1 COPYRIGHT

Copyright 2013 - Mike Greb

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Audio::Analyzer>

L<Math::FFT>

=cut

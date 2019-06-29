package Audio::Chromaprint;
# ABSTRACT: Interface to the Chromaprint library

use Moose;
use Carp qw< croak >;
use FFI::Platypus 0.88;
use FFI::CheckLib;
use Moose::Util::TypeConstraints;

# This is in three statement so we could support 5.6.0,
# since hash version only came out in 5.8.0.
use constant 'MIN_SILENCE_THRESHOLD' => 0;
use constant 'MAX_SILENCE_THRESHOLD' => 32_767;
use constant 'BYTES_PER_SAMPLE'      => 2;

our $HAS_SUBS;
our %SUBS = (
    '_new'         => [ ['int']                       => 'opaque' ],
    '_get_version' => [ []                            => 'string' ],
    '_free'        => [ ['opaque']                    => 'void'   ],
    '_set_option'  => [ [ 'opaque', 'string', 'int' ] => 'int'    ],
    '_start'       => [ [ 'opaque', 'int', 'int' ]    => 'int'    ],
    '_finish'      => [ ['opaque']                    => 'int'    ],
    '_feed'        => [ ['opaque', 'string', 'int' ]  => 'int'    ],

    '_get_fingerprint_hash'     => [ [ 'opaque', 'uint32*' ], 'int' ],
    '_get_fingerprint'          => [ [ 'opaque', 'opaque*' ], 'int' ],
    '_get_raw_fingerprint'      => [ [ 'opaque', 'opaque*', 'int*' ], 'int' ],
    '_get_num_channels'         => [ [ 'opaque' ], 'int' ],
    '_get_sample_rate'          => [ [ 'opaque' ], 'int' ],
    '_get_item_duration'        => [ [ 'opaque' ], 'int' ],
    '_get_item_duration_ms'     => [ [ 'opaque' ], 'int' ],
    '_get_delay'                => [ [ 'opaque' ], 'int' ],
    '_get_delay_ms'             => [ [ 'opaque' ], 'int' ],
    '_get_raw_fingerprint_size' => [ [ 'opaque', 'int*' ], 'int' ],
    '_clear_fingerprint'        => [ [ 'opaque' ], 'int' ],

    '_dealloc' => [ [ 'opaque' ] => 'void' ],
);

sub BUILD {
    $HAS_SUBS++
        and return;

    my $ffi = FFI::Platypus->new;

    # Setting this mangler lets is omit the chromaprint_ prefix
    # from the attach call below, and the function names used
    # by perl
    $ffi->mangler( sub {
        my $name = shift;
        $name =~ s/^_/chromaprint_/xms;
        return $name;
    } );

    $ffi->lib( find_lib_or_exit( 'lib' => 'chromaprint', alien => 'Alien::chromaprint' ) );

    $ffi->attach( $_, @{ $SUBS{$_} } )
        for keys %SUBS;

    $ffi->attach_cast( '_opaque_to_string' => opaque => 'string' );
}

subtype 'ChromaprintAlgorithm',
    as 'Int',
    where { /^[1234]$/xms },
    message { 'algorithm must be 1, 2, 3 or 4' };

subtype 'ChromaprintSilenceThreshold',
    as 'Int',
    where { $_ >= MIN_SILENCE_THRESHOLD() && $_ <= MAX_SILENCE_THRESHOLD() },
    message { 'silence_threshold option must be between 0 and 32767' };

has 'algorithm' => (
    'is'      => 'ro',
    'isa'     => 'ChromaprintAlgorithm',
    'default' => sub {2},
);

has 'cp' => (
    'is'       => 'ro',
    'lazy'     => 1,
    'init_arg' => undef,
    'default'  => sub {
        my $self = shift;

        # subtract one from the algorithm so that
        # 1 maps to 2 maps to CHROMAPRINT_ALGORITHM_TEST2
        # (the latter has the value 1)
        my $cp   = _new( $self->algorithm - 1 );

        if ( $self->has_silence_threshold ) {
            _set_option(
                $cp, 'silence_threshold' => $self->silence_threshold,
            ) or croak('Error setting option silence_threshold');
        }

        return $cp;
    }
);

has 'silence_threshold' => (
    'is'        => 'ro',
    'isa'       => 'ChromaprintSilenceThreshold',
    'predicate' => 'has_silence_threshold',
);

sub get_version {
    # generate chromaprint object
    __PACKAGE__->can('_get_version')
        or __PACKAGE__->new();

    return _get_version();
}

sub start {
    my ( $self, $sample_rate, $num_channels ) = @_;

    $sample_rate =~ /^[0-9]+$/xms
        or croak 'sample_rate must be an integer';

    $num_channels =~ /^[12]$/xms
        or croak 'num_channels must be 1 or 2';

    _start( $self->cp, $sample_rate, $num_channels )
        or croak 'Unable to start (start)';
}

sub set_option {
    my ( $self, $name, $value ) = @_;

    $name && $value
        or croak('set_option( name, value )');

    length $name
        or croak('set_option requires a "name" string');

    $value =~ /^[0-9]+$/xms
        or croak('set_option requires a "value" integer');

    if ( $name eq 'silence_threshold' ) {
        $value >= MIN_SILENCE_THRESHOLD() && $value <= MAX_SILENCE_THRESHOLD()
            or croak('silence_threshold option must be between 0 and 32767');
    }

    _set_option( $self->cp, $name => $value )
        or croak("Error setting option $name (set_option)");
}

sub finish {
    my $self = shift;
    _finish( $self->cp )
        or croak('Unable to finish (finish)');
}

sub get_fingerprint_hash {
    my $self = shift;
    my $hash;
    _get_fingerprint_hash( $self->cp, \$hash )
        or croak('Unable to get fingerprint hash (get_fingerprint_hash)');
    return $hash;
}

sub get_fingerprint {
    my $self = shift;
    my $ptr;
    _get_fingerprint($self->cp, \$ptr)
        or croak('Unable to get fingerprint (get_fingerprint)');
    my $str = _opaque_to_string($ptr);
    _dealloc($ptr);
    return $str;
}

sub get_raw_fingerprint {
    my $self = shift;
    my ( $ptr, $size );

    _get_raw_fingerprint( $self->cp, \$ptr, \$size )
        or croak('Unable to get raw fingerprint (get_raw_fingerprint)');

    # not espeically fast, but need a cast with a variable length array
    my $fp = FFI::Platypus->new->cast( 'opaque' => "uint32[$size]", $ptr );
    _dealloc($ptr);
    return $fp;
}

sub get_num_channels {
    my $self = shift;
    return _get_num_channels($self->cp);
}

sub get_sample_rate {
    my $self = shift;
    return _get_sample_rate($self->cp);
}

sub get_item_duration {
    my $self = shift;
    return _get_item_duration($self->cp);
}

sub get_item_duration_ms {
    my $self = shift;
    return _get_item_duration_ms($self->cp);
}

sub get_delay {
    my $self = shift;
    return _get_delay($self->cp);
}

sub get_delay_ms {
    my $self = shift;
    return _get_delay_ms($self->cp);
}

sub get_raw_fingerprint_size {
    my $self = shift;
    my $size;
    _get_raw_fingerprint_size($self->cp, \$size)
        or croak('Unable to get raw fingerprint size (get_raw_fingerprint_size)');
    return $size;
}

sub clear_fingerprint {
    my $self = shift;
    _clear_fingerprint( $self->cp )
        or croak('Unable to clear fingerprint (clear_fingerprint)');
}

sub feed {
    my ( $self, $data ) = @_;
    _feed( $self->cp, $data, length($data) / BYTES_PER_SAMPLE() )
        or corak("unable to feed");
}

sub DEMOLISH {
    my $self = shift;
    _free( $self->cp );
}

# TODO: chromaprint_encode_fingerprint
# TODO: chromaprint_decode_fingerprint
# TODO: chromaprint_hash_fingerprint

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Audio::Chromaprint - Interface to the Chromaprint library

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Audio::Chromaprint;
    use Path::Tiny qw< path >;

    my $cp = Audio::Chromaprint->new();

    $cp->start( 44_100, 1 ); # sample rate (Hz), 1 audio stream
    $cp->feed( path('file.wav')->slurp_raw );
    $cp->finish;

    say "Fingerprint hash: ", $cp->get_fingerprint_hash;

=head1 DESCRIPTION

Chromaprint is the core component of the AcoustID project. It's a
client-side library that implements a custom algorithm for extracting
fingerprints from any audio source.

You can read more about Chromaprint on its
L<website|https://acoustid.org/chromaprint>.

This binding was done against 1.4.3. While it should work for newer versions,
please let us know if you are experiencing issues with newer versions.

=head1 ATTRIBUTES

=head2 algorithm

Integer representing the Chromaprint algorithm.

Acceptable values:

=over 4

=item * B<1>

=item * B<2>

=item * B<3>

=item * B<4>

=back

The default is B<2>. (This is the default in Chromaprint.)

=head2 silence_threshold

An integer representing the silence threshold.

Accepting a number between B<0> and B<32,767> (without a comma).

=head1 METHODS

=head2 new

    my $chromaprint = Audio::Chromaprint->new(
        'algorithm'         => 1,     # optional, default is 2
        'silence_threshold' => 1_000, # optional,
    );

=head2 start

    $chromaprint->start( $sample_rate, $num_streams );

Start the computation of a fingerprint with a new audio stream.

First argument is the sample rate (in integer) of the audio stream (in Hz).

Second argument is number of channels in the audio stream (1 or 2).

=head2 set_option

    $chromaprint->set_option( $key => $value );

Setting an option to Chromaprint.

In version 1.4.3 only the C<silence_threshold> is available, which we
also expose during instantiation under C<new>.

=head2 get_version

    my $version = $chromaprint->get_version();

Returns a string representing the version.

=head2 feed

    $chromaprint->feed($data);

Feed data to Chromaprint to analyze. The size definitions are handled
in the module, so you only send the data, no need for more.

You can use L<Path::Tiny> to do this easily using the C<slurp_raw>:

    use Path::Tiny qw< path >;
    my $file = path('some_file.wav');
    my $data = $file->slurp_raw();

    $chromaprint->feed($data);

=head2 finish

    $chromaprint->finish();

Process any remaining buffered audio data.

This has to be run before you can get the fingerprints.

=head2 get_fingerprint

    my $fingerprint = $chromaprint->get_fingerprint();

Provides a compressed string representing the fingerprint of the file.
You might prefer using C<get_fingerprint_hash>.

=head2 get_fingerprint_hash

    my $fingerprint_hash = $chromaprint->get_fingerprint_hash();

Provides a hash string, representing the fingerprint for the file.

=head2 get_raw_fingerprint

    my $raw_fingerprint = $chromaprint->get_raw_fingerprint();

Return the calculated fingerprint as an array of 32-bit integers.

=head2 get_raw_fingerprint_size

    my $fingerprint_size = $chromaprint->get_fingerprint_size();

Return the length of the current raw fingerprint.

=head2 clear_fingerprint

    $chromaprint->clear_fingerprint();

Clear the current fingerprint, but allow more data to be processed.

=head2 get_num_channels

    my $num_of_channels = $chromaprint->get_num_channels();

Get the number of channels that is internally used for fingerprinting.

=head2 get_sample_rate

    my $sample_rate = $chromaprint->get_sample_rate();

Get the sampling rate that is internally used for fingerprinting.

=head2 get_item_duration

    my $item_duration = $chromaprint->get_item_duration();

Get the duration of one item in the raw fingerprint in samples.

=head2 get_item_duration_ms

    my $item_duration_ms = $chromaprint->get_item_duration_ms();

Get the duration of one item in the raw fingerprint in milliseconds.

=head2 get_delay

    my $delay = $chromaprint->get_delay();

Get the duration of internal buffers that the fingerprinting algorithm uses.

=head2 get_delay_ms

    my $delay_ms = $chromaprint->get_delay_ms();

Get the duration of internal buffers that the fingerprinting algorithm uses.

=head1 UNSUPPORTED METHODS

We do not yet support the following methods.

=over 4

=item * C<encode_fingerprint>

=item * C<decode_fingerprint>

=item * C<hash_fingerprint>

=back

=head1 AUTHORS

=over 4

=item *

Sawyer X <xsawyerx@cpan.org>

=item *

Graham Ollis <plicease@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut

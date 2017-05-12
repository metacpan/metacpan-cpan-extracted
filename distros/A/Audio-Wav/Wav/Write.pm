package Audio::Wav::Write;

use strict;
eval { require warnings; }; #it's ok if we can't load warnings

use FileHandle;
use Audio::Wav::Write::Header;

use vars qw( $VERSION );
$VERSION = '0.14';

=head1 NAME

Audio::Wav::Write - Module for writing Microsoft WAV files.

=head1 SYNOPSIS

    use Audio::Wav;

    my $wav = new Audio::Wav;

    my $sample_rate = 44100;
    my $bits_sample = 16;

    my $details = {
	'bits_sample'	=> $bits_sample,
	'sample_rate'	=> $sample_rate,
	'channels'	=> 1,
	# if you'd like this module not to use a write cache, uncomment the next line
	#'no_cache'	=> 1,

    };

    my $write = $wav -> write( 'testout.wav', $details );

    &add_sine( 200, 1 );

    sub add_sine {
	my $hz = shift;
	my $length = shift;
	my $pi = ( 22 / 7 ) * 2;
	$length *= $sample_rate;
	my $max_no =  ( 2 ** $bits_sample ) / 2 - 1;
	for my $pos ( 0 .. $length ) {
	    $time = $pos / $sample_rate;
	    $time *= $hz;
	    my $val = sin $pi * $time;
	    my $samp = $val * $max_no;
	    $write -> write( $samp );
	}
    }

    $write -> finish();

=head1 DESCRIPTION

Currently only writes to a file.

=head1 SEE ALSO

L<Audio::Wav>

L<Audio::Wav::Read>

=head1 NOTES

This module shouldn't be used directly, a blessed object can be returned from L<Audio::Wav>.

=head1 METHODS

=cut

sub new {
    my $class = shift;
    my $out_file = shift;
    my $details = shift;
    my $tools = shift;

    my $handle = (ref $out_file eq 'GLOB') ? $out_file : new FileHandle ">$out_file";

    my $use_cache = 1;
    if ( ref $details eq 'HASH' && exists $details -> {no_cache} ) {
        my $no_cache = delete $details -> {no_cache};
        $use_cache = 0 if $no_cache;
    }

    my $self = {
        'use_cache'   => $use_cache,
        'write_cache' => undef,
        'out_file'    => $out_file,
        'cache_size'  => 4096,
        'handle'      => $handle,
        'details'     => $details,
        'block_align' => $details -> {block_align},
        'tools'       => $tools,
        'done_finish' => 0,
    };

    bless $self, $class;

    unless ( defined $handle ) {
        my $error = $!;
        chomp $error;
        $self -> _error( "unable to open file ($error)" );
        return $self;
    }

    binmode $handle;

    $self -> _init();
    $self -> _start_file();
    $self -> _examine_details( $details );

    if ( $self -> {details} -> {bits_sample} <= 8 ) {
        $self -> {use_offset} = ( 2 ** $self -> {details} -> {bits_sample} ) / 2;
    } else {
        $self -> {use_offset} = 0;
    }

    return $self; 
}

sub DESTROY {
    my $self = shift;
    return unless $self;
    return if $self -> {done_finish};
    $self -> finish();
}

=head2 finish

Finishes off & closes the current wav file.

    $write -> finish();

=cut

sub finish {
    my $self = shift;
    $self -> _purge_cache() if $self -> {use_cache};
    $self -> {header} -> finish( $self -> {pos} );
    $self -> {handle} -> close();
    $self -> {done_finish} = 1;
}

=head2 add_cue

Adds a cue point to the wav file. If $sample is undefined then the position will be the current position (end of all data written so far).

    # $byte_offset for 01 compatibility mode
    $write -> add_cue( $sample, "label", "note"  );

=cut

sub add_cue {
    my $self = shift;
    my $pos = shift;
    my $label = shift;
    my $note = shift;
    my $block_align = $self -> {details} -> {block_align};
    if ( defined $pos ) {
        $pos /= $block_align if $self -> {tools} -> is_01compatible();
    } else {
        $pos = $self -> {pos} / $block_align;
    }
    my $output = {
        'pos' => $pos,
    };
    $output -> {label} = $label if $label;
    $output -> {note} = $note if $note;
    $self -> {header} -> add_cue( $output );
}

=head2 set_sampler_info

All parameters are optional.

    my %info = (
        'midi_pitch_fraction' => 0,
        'smpte_format'        => 0,
        'smpte_offset'        => 0,
        'product'             => 0,
        'sample_period'       => 0,
        'manufacturer'        => 0,
        'sample_data'         => 0,
        'midi_unity_note'     => 65,
    );
    $write -> set_sampler_info( %info );

=cut

sub set_sampler_info {
    my ($self, @args) = @_;
    return $self -> {header} -> set_sampler_info( @args );
}

=head2 add_sampler_loop

All parameters are optional except start & end.

    my $length = $read -> length_samples();
    my( $third, $twothirds ) = map int( $length / $_ ), ( 3, 1.5 );
    my %loop = (
	'start'			=> $third,
	'end'			=> $twothirds,
	'fraction'		=> 0,
	'type'			=> 0,
    );
    $write -> add_sampler_loop( %loop );

=cut

sub add_sampler_loop {
    my ($self, @args) = @_;
    return $self -> {header} -> add_sampler_loop( @args );
}

=head2 add_display

=cut

sub add_display {
    my ($self, @args) = @_;
    return $self -> {header} -> add_display( @args );
}

=head2 set_info

Sets information to be contained in the wav file.

    $write -> set_info( 'artist' => 'Nightmares on Wax', 'name' => 'Mission Venice' );

=cut

sub set_info {
    my ($self, %info) = @_;
    $self -> {details} -> {info} = { %{ $self -> {details} -> {info} }, %info };
}

=head2 file_name

Returns the current filename.

    my $file = $write -> file_name();

=cut

sub file_name {
    my $self = shift;
    return $self -> {out_file};
}

=head2 write

Adds a sample to the current file.

    $write -> write( @sample_channels );

Each element in @sample_channels should be in the range of;

    where $samp_max = ( 2 ** bits_per_sample ) / 2
    -$samp_max to +$samp_max 

=cut

sub write {
    my ($self, @args) = @_;
    my $channels = $self -> {details} -> {channels};
    if ( $self -> {use_offset} ) {
        return $self -> write_raw( pack 'C'.$channels, map { $_ + $self -> {use_offset} } @args );
    } else {
        #TODO: performance: when we move to _init_write_sub, just use:
        #32: pack 'V1', ... 
        #24: substr pack('V1', ...), 3
        #16: pack 'v1', ...
        my $bytes_per_sample = $self->{details}->{bits_sample} >> 3;
        use bytes;
        my @samples = map { substr pack('V1', $_), 0, $bytes_per_sample } @args; 
#warn "bits/sample: $self->{details}->{bits_sample}, bytes/sample: $bytes_per_sample";
#warn "output samples(".scalar @samples."): ".join "-", map ord, split //, join '', @samples;
        return $self -> write_raw( join '', @samples );
    }
}

=head2 write_raw

Adds some pre-packed data to the current file.

    $write -> write_raw( $data, $data_length );

Where;

    $data is the packed data
    $data_length (optional) is the length in bytes of the data

=cut

sub write_raw {
    my $self = shift;
    my $data = shift;
    my $len = shift;
    $len = length $data unless $len;
    return unless $len;
    my $wrote = $len;
    if ( $self -> {use_cache} ) {
        $self -> {write_cache} .= $data;
        my $cache_len = length $self -> {write_cache};
        $self -> _purge_cache( $cache_len ) unless $cache_len < $self -> {cache_size};
    } else {
        $wrote = syswrite $self -> {handle}, $data, $len;
    }

    $self -> {pos} += $wrote;
    return $wrote; 
}

=head2 write_raw_samples

Adds some pre-packed data to the current file, returns number of samples written.

    $write -> write_raw_samples( $data, $data_length );

Where;

    $data is the packed data
    $data_length (optional) is the length in bytes of the data

=cut

sub write_raw_samples {
    my ($self, @args) = @_;
    my $written = $self -> write_raw( @args );
    return $written / $self -> {details} -> {block_align};
}

####################

sub _start_file {
    my $self = shift;
    my( $file, $details, $tools, $handle ) = map { $self -> {$_} } qw( out_file details tools handle );
    my $header = Audio::Wav::Write::Header -> new( $file, $details, $tools, $handle );
    $self -> {header} = $header;
    my $data = $header -> start();
    $self -> write_raw( $data );
    $self -> {pos} = 0;
}

sub _purge_cache {
    my $self = shift;
    my $len = shift;
    return unless $self -> {write_cache};
    my $cache = $self -> {write_cache};
    $len = length $cache unless $len;
    my $res = syswrite $self -> {handle}, $cache, $len;
    $self -> {write_cache} = undef;
}

sub _init {
    my $self = shift;
    my $details = $self -> {details};
    my $output = {};
    my @missing;
    my @needed = qw ( bits_sample channels sample_rate );
    my @wanted = qw ( block_align bytes_sec info wave-ex );

    foreach my $need ( @needed ) {
        if ( exists( $details -> {$need} ) && $details -> {$need} ) {
            $output -> {$need} = $details -> {$need};
        } else {
            push @missing, $need;
        }
    }
    return $self -> _error('I need the following parameters supplied: ' . join ', ', @missing ) if @missing;
    foreach my $want ( @wanted ) {
        next unless ( exists( $details -> {$want} ) && $details -> {$want} );
        $output -> {$want} = $details -> {$want};
    }
    unless ( exists $details -> {block_align} ) {
        my( $channels, $bits ) = map { $output -> {$_} } qw( channels bits_sample );
        my $mod_bits = $bits % 8 ? 1 : 0;
        $mod_bits += int $bits / 8;
        $output -> {block_align} = $channels * $mod_bits;
    }
    unless ( exists $output -> {bytes_sec} ) {
        my( $rate, $block ) = map { $output -> {$_} } qw( sample_rate block_align );
        $output -> {bytes_sec} = $rate * $block;
    }
    unless ( exists $output -> {info} ) {
        $output -> {info} = {};
    }

    $self -> {details} = $output; 
}

sub _examine_details {
    my $self = shift;
    my $details = shift;
    my( $cue, $label, $note ) =
        map { exists( $details -> {$_} ) ? $details -> {$_} : {} }
        qw( cue labl note );
    my $block_align = $self -> {details} -> {block_align};
    my $tools = $self -> {tools};
    foreach my $id ( sort keys %{$cue} ) {       # <-- Thanks to jeremyd713@hotmail.com
        my $pos = $cue -> {$id} -> {position};
        $pos *= $block_align if $tools -> is_01compatible();
        my( $in_label, $in_note ) = 
            map { exists( $_ -> {$id} ) ? $_ -> {$id} : '' }
            ( $label, $note );
        $self -> add_cue( $pos, $in_label, $in_note );
    }
    if ( exists $details -> {sampler} ) {
        my $sampler = $details -> {sampler};
        my $loops = delete $sampler -> {loop};
        $self -> set_sampler_info( %{$sampler} );
        foreach my $loop ( @{$loops} ) {
            $self -> add_sampler_loop( %{$loop} );
        }
    }
    if ( exists $details -> {display} ) {
        my @display = @{ $details -> {display} };
        my @fields = qw( id data );
        $self -> add_display( map { $fields[$_] => $display[$_] } 0, 1 );
    }
}

sub _error {
    my ($self, @args) = @_;
    return $self -> {tools} -> error( $self -> {out_file}, @args );
}

=head1 AUTHORS

    Nick Peskett (see http://www.peskett.co.uk/ for contact details).
    Kurt George Gjerde <kurt.gjerde@media.uib.no>. (0.02-0.03)

=cut

1;

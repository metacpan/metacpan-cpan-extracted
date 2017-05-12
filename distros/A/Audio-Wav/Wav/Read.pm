package Audio::Wav::Read;

use strict;
eval { require warnings; }; #it's ok if we can't load warnings

use FileHandle;

use vars qw( $VERSION );
$VERSION = '0.14';

=head1 NAME

Audio::Wav::Read - Module for reading Microsoft WAV files.

=head1 SYNOPSIS

    use Audio::Wav;

    my $wav = new Audio::Wav;
    my $read = $wav -> read( 'filename.wav' );
#OR
    my $read = Audio::Wav -> read( 'filename.wav' );

    my $details = $read -> details();

=head1 DESCRIPTION

Reads Microsoft Wav files.

=head1 SEE ALSO

L<Audio::Wav>

L<Audio::Wav::Write>

=head1 NOTES

This module shouldn't be used directly, a blessed object can be returned from L<Audio::Wav>.

=head1 METHODS

=cut

sub new {
    my $class = shift;
    my $file = shift;
    my $tools = shift;
    $file =~ s#//#/#g;
    my $size = -s $file;

    my $handle = (ref $file eq 'GLOB') ? $file : new FileHandle "<$file";

    my $self = {
        'real_size' => $size,
        'file'      => $file,
        'handle'    => $handle,
        'tools'     => $tools,
    };

    bless $self, $class; 

    unless ( defined $handle ) {
        $self -> _error( "unable to open file ($!)" );
        return $self;
    }

    binmode $handle; 

    if( $Audio::Wav::_has_inline ) {
        local $/ = undef;
        my $c_string = <DATA>; 
        Inline->import(C => $c_string);
    } else {
        #TODO: do we have a reference to $tools here if using shortcuts?
        if( $tools && $tools -> is_debug() ) {
            warn "can't load Inline, using slow pure perl reads\n";
        }
    }

    $self -> {data} = $self -> _read_file();
    my $details = $self -> details();
    $self -> _init_read_sub();
    $self -> {pos} = $details -> {data_start};
    $self -> move_to();
    return $self; 
}

# just in case there are any memory leaks
sub DESTROY {
    my $self = shift;
    return unless $self;
    if ( exists $self->{handle} && defined $self->{handle} ) {
        $self->{handle}->close();
    }
    if ( exists $self->{tools} ) {
        delete $self->{tools};
    }
}

=head2 file_name

Returns the file name.

    my $file = $read -> file_name();

=cut

sub file_name {
    my $self = shift;
    return $self -> {file};
}

=head2 get_info

Returns information contained within the wav file.

    my $info = $read -> get_info();

Returns a reference to a hash containing;
(for example, a file marked up for use in Audio::Mix)

    {
        'keywords' => 'bpm:126 key:a',
        'name'     => 'Mission Venice',
        'artist'   => 'Nightmares on Wax'
    };

=cut

sub get_info {
    my $self = shift;
    return unless exists $self -> {data} -> {info};
    return $self -> {data} -> {info};
}

=head2 get_cues

Returns the cuepoints marked within the wav file.

    my $cues = $read -> get_cues();

Returns a reference to a hash containing;
(for example, a file marked up for use in Audio::Mix)
(position is sample position)

    {
        1 => {
            label    => 'sig',
            position => 764343,
            note     => 'first',
        },
        2 => {
            label    => 'fade_in',
            position => 1661774,
            note     => 'trig',
        },
        3 => {
            label    => 'sig',
            position => 18033735,
            note     => 'last',
        },
        4 => {
            label    => 'fade_out',
            position => 17145150,
            note     => 'trig',
        },
        5 => {
            label    => 'end',
            position => 18271676,
        }
    }

=cut

sub get_cues {
    my $self = shift;
    return unless exists $self -> {data} -> {cue};
    my $data = $self -> {data};
    my $cues = $data -> {cue};
    my $output = {};
    foreach my $id ( keys %{$cues} ) {
        my $pos = $cues -> {$id} -> {position};
        my $record = { 'position' => $pos };
        $record -> {label} = $data -> {labl} -> {$id} if ( exists $data -> {labl} -> {$id} );
        $record -> {note} = $data -> {note} -> {$id} if ( exists $data -> {note} -> {$id} );
        $output -> {$id} = $record;
    }
    return $output; 
}

=head2 read_raw

Reads raw packed bytes from the current audio data position in the file.

    my $data = $self -> read_raw( $byte_length );

=cut

sub read_raw {
    my $self = shift;
    my $len = shift;
    my $data_finish = $self -> {data} -> {data_finish};
    if ( $self -> {pos} + $len > $data_finish ) {
        $len = $data_finish - $self -> {pos};
    }
    return $self -> _read_raw( $len );
}

=head2 read_raw_samples

Reads raw packed samples from the current audio data position in the file.

    my $data = $self -> read_raw_samples( $samples );

=cut

sub read_raw_samples {
    my $self = shift;
    my $len = shift;
    $len *= $self -> {data} -> {block_align};
    return $self -> read_raw( $len );
}

sub _read_raw {
    my $self = shift;
    my $len = shift;
    my $data;
    return unless $len && $len > 0;
    $self -> {pos} += read $self -> {handle}, $data, $len;
    return $data; 
}

=head2 read

Returns the current audio data position sample across all channels.

    my @channels = $self -> read();

Returns an array of unpacked samples.
Each element is a channel i.e ( left, right ).
The numbers will be in the range;

    where $samp_max = ( 2 ** bits_per_sample ) / 2
    -$samp_max to +$samp_max 

=cut

# read is generated by _init_read_sub
sub read { die "ERROR: can't call read without first calling _init_read_sub"; };

sub _init_read_sub {
    my $self = shift;
    my $handle      = $self -> {handle};
    my $details     = $self -> {data};
    my $channels    = $details -> {channels};
    my $block       = $details -> {block_align};
    my $read_op;

    #TODO: we try to do something if we have bits_per_sample != multiple of 8?
    if ( $details -> {bits_sample} <= 8 ) {
        # Data in .wav-files with <= 8 bits is unsigned. >8 bits is signed
        my $offset = 2 ** ($details -> {bits_sample}-1);
        $read_op = q[ return map $_ - ] . $offset .
                   q[, unpack( 'C'.$channels, $val ); ];
    } elsif ( $details -> {bits_sample} == 16 ) {
        # 16 bits could be handled by general case below, but this is faster
        if ( $self -> {tools} -> is_big_endian() ) {
            $read_op = q[ return
                unpack 's' . $channels,        # 3. unpack native as signed short
                pack   'S' . $channels,        # 2. pack native unsigned short
                unpack 'v' . $channels, $val;  # 1. unpack little-endian unsigned short
            ];
        } else {
            $read_op = q[ return unpack( 's' . $channels, $val ); ];
        }
    } elsif ( $details -> {bits_sample} <= 32 ) {
        my $bytes  = $details -> {block_align} / $channels;
        my $fill   = 4 - $bytes;
        my $limit  = 2 ** ($details -> {bits_sample}-1);
        my $offset = 2 **  $details -> {bits_sample};
#warn "b: $bytes, f: $fill";    
        $read_op = q[ return 
            map    {$_ & ] . $limit . q[ ?           # 4. If sign bit is set
                    $_ - ] . $offset . q[ : $_}      #    convert to negative number
            unpack 'V*',                             # 3. unpack as little-endian unsigned long
            pack   "(a] . $bytes.'x'.$fill . q[)*",  # 2. fill with \0 to 4-byte-blocks and repack
            unpack "(a] . $bytes . q[)*", $val;      # 1. unpack to elements sized "$bytes"-bytes
         ];
#        $sub = sub 
#               { return  map    {$_ & $limit  ?          # 4. If sign bit is set
#                                 $_ - $offset : $_}      #    convert to negative number
#                         unpack 'V*',                    # 3. unpack as little-endian unsigned long
#                         pack   "(a${bytes}x${fill})*",  # 2. fill with \0 to 4-byte-blocks and repack
#                         unpack "(a$bytes)*", shift()    # 1. unpack to elements sized "$bytes"-bytes
#               };
    } else {
        $self->_error("Unpacking elements with more than 32 ($details->{bits_sample}) bits per sample not supported!");
    }

    $self -> {read_sub_string} = q[
        sub {
            my $val;
            $self -> {pos} += read( $handle, $val, $block );
            return unless defined $val;
            ] . $read_op . q[
        };
    ];
    if( $Audio::Wav::_has_inline ) {
        init( $handle, $details->{bits_sample}/8, $channels,
            $self -> {tools} -> is_big_endian() ? 1 : 0);
        *read = \&read_c;
    } else {
        my $read_sub = eval $self -> {read_sub_string};
        die "eval of read_sub failed: $@\n" if($@);
        $self -> {read_sub} = $read_sub; #in case any legacy code peaked at that
        *read = \&$read_sub;
    }
#warn $self -> {read_sub_string};
}

=head2 position

Returns the current audio data position (as byte offset).

    my $byte_offset = $read -> position();

=cut

sub position {
    my $self = shift;
    return $self -> {pos} - $self -> {data} -> {data_start};
}

=head2 position_samples

Returns the current audio data position (in samples).

    my $samples = $read -> position_samples();

=cut

sub position_samples {
    my $self = shift;
    return ( $self -> {pos} - $self -> {data} -> {data_start} ) / $self -> {data} -> {block_align};
}

=head2 move_to

Moves the current audio data position to byte offset.

    $read -> move_to( $byte_offset );

=cut

sub move_to {
    my $self = shift;
    my $pos = shift;
    my $data_start = $self -> {data} -> {data_start};
    if ( $pos ) {
	$pos = 0 if $pos < 0;
    } else {
	$pos = 0;
    }
    $pos += $data_start;
    if ( $pos > $self -> {pos} ) {
        my $max_pos = $self -> reread_length() + $data_start;
        $pos = $max_pos if $pos > $max_pos;
    }
    if ( seek $self -> {handle}, $pos, 0 ) {
	$self -> {pos} = $pos;
	return 1;
    } else {
	return $self -> _error( "can't move to position '$pos'" );
    }
}

=head2 move_to_sample

Moves the current audio data position to sample offset.

    $read -> move_to_sample( $sample_offset );

=cut

sub move_to_sample {
    my $self = shift;
    my $pos = shift;
    return $self -> move_to() unless defined $pos ;
    return $self -> move_to( $pos * $self -> {data} -> {block_align} );
}

=head2 length

Returns the number of bytes of audio data in the file.

    my $audio_bytes = $read -> length();

=cut

sub length {
    my $self = shift;
    return $self -> {data} -> {data_length};
}

=head2 length_samples

Returns the number of samples of audio data in the file.

    my $audio_samples = $read -> length_samples();

=cut

sub length_samples {
    my $self = shift;
    my $data = $self -> {data};
    return $data -> {data_length} / $data -> {block_align};
}

=head2 length_seconds

Returns the number of seconds of audio data in the file.

    my $audio_seconds = $read -> length_seconds();

=cut

sub length_seconds {
    my $self = shift;
    my $data = $self -> {data};
    return $data -> {data_length} / $data -> {bytes_sec};
}

=head2 details

Returns a reference to a hash of lots of details about the file.
Too many to list here, try it with Data::Dumper.....

    use Data::Dumper;
    my $details = $read -> details();
    print Data::Dumper->Dump([ $details ]);

=cut

sub details {
    my $self = shift;
    return $self -> {data};
}

=head2 reread_length

Rereads the length of the file in case it is being written to
as we are reading it.

    my $new_data_length = $read -> reread_length();

=cut

sub reread_length {
    my $self = shift;
    my $handle = $self -> {handle};
    my $old_pos = $self -> {pos};
    my $data = $self -> {data};
    my $data_start = $data -> {data_start};
    seek $handle, $data_start - 4, 0;
    my $new_length = $self -> _read_long();
    seek $handle, $old_pos, 0;
    $data -> {data_length} = $new_length;
    return $new_length; 
}

#########

sub _read_file {
    my $self = shift;
    my $handle = $self -> {handle};
    my %details;
    my $type = $self -> _read_raw( 4 );
    my $length = $self -> _read_long( );
    my $subtype = $self -> _read_raw( 4 );
    my $tools = $self -> {tools};
    my $old_cooledit = $tools -> is_oldcooledithack();
    my $debug = $tools -> is_debug();

    $details{total_length} = $length;

    unless ( $type eq 'RIFF' && $subtype eq 'WAVE' ) {
        return $self -> _error( "doesn't seem to be a wav file" );
    }

    my $walkover;  # for fixing cooledit 96 data-chunk bug

    while ( ! eof $handle && $self -> {pos} < $length ) {
        my $head;
        if ( $walkover ) {
            # rectify cooledit 96 data-chunk bug
            $head = $walkover . $self -> _read_raw( 3 );
            $walkover = undef;
            print "debug: CoolEdit 96 data-chunk bug detected!\n" if $debug;
        } else {
            $head = $self -> _read_raw( 4 );
        }
        my $chunk_len = $self -> _read_long();
        printf "debug: head: '$head' at %6d (%6d bytes)\n", $self->{pos}, $chunk_len if $debug;
        if ( $head eq 'fmt ' ) {
            my $format = $self -> _read_fmt( $chunk_len );
            my $comp = delete $format -> {format};
            if ( $comp == 65534 ) {
                $format -> {'wave-ex'} = 1;
            } elsif ( $comp != 1 ) {
                return $self -> _error( "seems to be compressed, I can't handle anything other than uncompressed PCM" );
            } else {
                $format -> {'wave-ex'} = 0;
            }
            %details = ( %details, %{$format} );
            next;
        } elsif ( $head eq 'cue ' ) {
            $details{cue} = $self -> _read_cue( $chunk_len, \%details );
            next;
        } elsif ( $head eq 'smpl' ) {
            $details{sampler} = $self -> _read_sampler( $chunk_len );
            next;
        } elsif ( $head eq 'LIST' ) {
            my $list = $self -> _read_list( $chunk_len, \%details );
            next;
        } elsif ( $head eq 'DISP' ) {
            $details{display} = $self -> _read_disp( $chunk_len );
            next;
        } elsif ( $head eq 'data' ) {
            $details{data_start} = $self -> {pos};
            $details{data_length} = $chunk_len;
        } else {
            $head =~ s/[^\w]+//g;
            $self -> _error( "ignored unknown block type: $head at $self->{pos} for $chunk_len", 'warn' );
        }

        seek $handle, $chunk_len, 1;
        $self -> {pos} += $chunk_len;

        # read padding
        if ($chunk_len % 2) {
            my $pad = $self->_read_raw(1);
            if ( ($pad =~ /\w/) && $old_cooledit && ($head eq 'data') ) {
                # Oh no, this file was written by cooledit 96...
                # This is not a pad byte but the first letter of the next head.
               $walkover = $pad;
            }
        }

        #unless ( $old_cooledit ) {
        #    $chunk_len += 1 if $chunk_len % 2; # padding
        #}
        #seek $handle, $chunk_len, 1;
        #$self -> {pos} += $chunk_len;

    }

    if ( exists $details{data_start} ) {
        $details{length} = $details{data_length} / $details{bytes_sec};
        $details{data_finish} = $details{data_start} + $details{data_length};
    } else {
        $details{data_start} = 0;
        $details{data_length} = 0;
        $details{length} = 0;
        $details{data_finish} = 0;
    }
    return \%details; 
}


sub _read_list {
    my $self = shift;
    my $length = shift;
    my $details = shift;
    my $note = $self -> _read_raw( 4 );
    my $pos = 4;

    if ( $note eq 'adtl' ) {
        my %allowed = map { $_ => 1 } qw( ltxt note labl );
        while ( $pos < $length ) {
            my $head = $self -> _read_raw( 4 );
            $pos += 4;
            if ( $head eq 'ltxt' ) {
                my $record = $self -> _decode_block( [ 1 .. 6 ] );
                $pos += 24;
            } else {
                my $bits = $self -> _read_long();
                $pos += $bits + 4;

                if ( $head eq 'labl' || $head eq 'note' ) {
                    my $id = $self -> _read_long();
                    my $text = $self -> _read_raw( $bits - 4 );
                    $text =~ s/\0+$//;
                    $details -> {$head} -> {$id} = $text; 
                } else {
                    my $unknown = $self -> _read_raw ( $bits ); # skip unknown chunk
                }
                if ($bits % 2) { # eat padding
                    my $padding = $self -> _read_raw(1);
                    $pos++;
                }
            }
        }
        # if it's a broken file and we've read too much then go back
        if ( $pos > $length ) {
            seek $self->{handle}, $length-$pos, 1;
        }
    }
    elsif ( $note eq 'INFO' ) {
        my %allowed = $self -> {tools} -> get_info_fields();
        while ( $pos < $length ) {
            my $head = $self -> _read_raw( 4 );
            $pos += 4;
            my $bits = $self -> _read_long();
            $pos += $bits + 4;
            my $text = $self -> _read_raw( $bits );
            if ( $allowed{$head} ) {
                $text =~ s/\0+$//;
                $details -> {info} -> { $allowed{$head} } = $text;
            }
            if ($bits % 2) { # eat padding
                my $padding = $self -> _read_raw(1);
                $pos++;
            }
        }
    } else {
        my $data = $self -> _read_raw( $length - 4 );
    }
}

sub _read_cue {
    my $self = shift;
    my $length = shift;
    my $details = shift;
    my $cues = $self -> _read_long();
    my @fields = qw( id position chunk cstart bstart offset );
    my @plain = qw( chunk );
    my $output;
    for ( 1 .. $cues ) {
        my $record = $self -> _decode_block( \@fields, \@plain );
        my $id = delete $record -> {id};
        $output -> {$id} = $record;
    }
    return $output; 
}

sub _read_disp {
    my $self = shift;
    my $length = shift;
    my $type = $self -> _read_long();
    my $data = $self -> _read_raw( $length - 4 + ($length%2) );
    $data =~ s/\0+$//;
    return [ $type, $data ];
}

sub _read_sampler {
    my $self = shift;
    my $length = shift;
    my %sampler_fields = $self -> {tools} -> get_sampler_fields();

    my $record = $self -> _decode_block( $sampler_fields{fields} );

    for my $id ( 1 .. $record -> {sample_loops} ) {
        push @{ $record -> {loop} }, $self -> _decode_block( $sampler_fields{loop} );
    }

    $record -> {sample_specific_data} = _read_raw( $record -> {sample_data} );

    my $read_bytes =
        9 * 4                                   # sampler info
        + 6 * 4 * $record -> {sample_loops}   # loops
        + $record -> {sample_data};           # specific data


    # read any junk
    if ($read_bytes < $length ) {
        my $junk = $self->_read_raw( $length - $read_bytes );
    }

    if ( $length % 2 ) {
        my $pad = $self -> _read_raw( 1 );
    }

    # temporary nasty hack to gooble the last bogus 12 bytes
    #my $extra = $self -> _decode_block( $sampler_fields{extra} );

    return $record; 
}


sub _decode_block {
    my $self = shift;
    my $fields = shift;
    my $plain = shift;
    my %plain;
    if ( $plain ) {
        foreach my $field ( @{$plain} ) {
            for my $id ( 0 .. $#{$fields} ) {
                next unless $fields -> [$id] eq $field;
                $plain{$id} = 1;
            }
        }
    }
    my $no_fields = scalar @{$fields};
    my %record;
    for my $id ( 0 .. $#{$fields} ) {
        if ( exists $plain{$id} ) {
            $record{ $fields -> [$id] } = $self -> _read_raw( 4 );
        } else {
            $record{ $fields -> [$id] } = $self -> _read_long();
        }
    }
    return \%record; 
}

sub _read_fmt {
    my $self = shift;
    my $length = shift;
    my $data = $self -> _read_raw( $length );
    my $types = $self -> {tools} -> get_wav_pack();
    my $pack_str = '';
    my $fields = $types -> {order};
    foreach my $type ( @{$fields} ) {
        $pack_str .= $types -> {types} -> {$type};
    }
    my @data = unpack $pack_str, $data;
    my %record;
    for my $id ( 0 .. $#{$fields} ) {
        $record{ $fields -> [$id] } = $data[$id];
    }
    return { %record };
}

sub _read_long {
    my $self = shift;
    my $data = $self -> _read_raw( 4 );
    return unpack 'V', $data; 
}

sub _error {
    my ($self, @args) = @_;
    return $self -> {tools} -> error( $self -> {file}, @args );
}

=head1 AUTHORS

    Nick Peskett (see http://www.peskett.co.uk/ for contact details).
    Brian Szymanski <ski-cpan@allafrica.com> (0.07-0.14)
    Wolfram humann (pureperl 24 and 32 bit read support in 0.09)
    Kurt George Gjerde <kurt.gjerde@media.uib.no>. (0.02-0.03)

=cut

1;

__DATA__

#ifdef WIN32
  // Note: if it becomes a problem that Visual Studio 6 and
  // Embedded Visual C++ 4 dont realize that char has the same
  // size as int8_t, check for #if (_MSC_VER < 1300) and use
  // signed __int8, unsigned __int16, etc. as in:
  // http://msinttypes.googlecode.com/svn/trunk/stdint.h
  typedef signed char       int8_t;
  typedef signed short      int16_t;
  typedef signed int        int32_t;
  typedef unsigned char     uint8_t;
  typedef unsigned short    uint16_t;
  typedef unsigned int      uint32_t;
#endif

//NOTE: 16, 32 bit audio do *NOT* work on big-endian platforms yet!
//verified formats (output is identical output to pureperl):
// 1 channel signed   16 little endian
// 2 channel signed   16 little endian
// 1 channel unsigned  8 little endian
// 2 channel unsigned  8 little endian
//verified "looks right" on these formats:
// 1 channel signed   32 little endian
// 2 channel signed   32 little endian
// 1 channel signed   24 little endian
// 2 channel signed   24 little endian

//maximum number of channels per audio stream
#define MAX_CHANNELS 10
//maximum number of bytes per sample (in one channel)
#define MAX_SAMPLE 4

FILE *handle;
int sample_size;
int channels;
int big_end;
int is_signed;
char buf[MAX_SAMPLE];
SV* retvals[MAX_CHANNELS];

void init(FILE *fh, int ss, int ch, int be) {
    int i;
    handle = fh;
    sample_size = ss;
    channels = ch;
    big_end = be;
    is_signed = (ss != 1); //TODO: is this really right?
    for(i=0; i<MAX_CHANNELS; i++) {
        retvals[i] = newSV(0);
    }
}

void read_c(void *self) {
    int samples[MAX_CHANNELS];
    int nread;
    int i, s;

    Inline_Stack_Vars;
    Inline_Stack_Reset;

    for(i=0; i<channels; i++) {
        // having fread in the loop is probably slightly less efficient,
        // but it avoids byte alignment problems and fread is buffered,
        // so it "shouldn't be a problem" (tm). more info:
        // http://www.eventhelix.com/RealtimeMantra/ByteAlignmentAndOrdering.htm
        nread = fread( buf, sample_size, 1, handle );
        if( !nread ) {
            if( feof( handle ) && i ) {
                perror("got EOF mid-sample!");
            } else if( ferror( handle ) ) {
                perror("io error");
            }
            break;
        }
        switch(sample_size) {
            case 4:
                if(big_end) {
                    s = buf[0]; buf[0] = buf[3]; buf[3] = s;
                    s = buf[1]; buf[1] = buf[2]; buf[2] = s;
                }
                s = is_signed ?
                    *((int32_t *)buf) :
                    *((uint32_t *)buf) - 0x7fffffff - 1;
                break;
            case 3:
                //TODO: test this!
                if(big_end) { s = buf[0]; buf[0] = buf[2]; buf[2] = s; }
                s = *((uint32_t *)buf);
                if(big_end) { s = (s & 0xffffff00) >> 8; }
                else        { s = s & 0x00ffffff; }
                //make negative via 2s compliment if data is signed
                //and the sign bit is set
                if ( is_signed ) {
                    if ( s & 0x00800000 ) {
                        s = -((~s & 0x00ffffff)+1);
                    }
                } else {
                    //we *always* return signed data
                    s += -0x800000;
                }
                break;
            case 2: 
                if(big_end) { s = buf[0]; buf[0] = buf[1]; buf[1] = s; }
                s = is_signed ?
                    *((int16_t *)buf) :
                    *((uint16_t *)buf) + -0x8000;
                break;
            case 1:
                //note: Audio::Wav *always* returns signed data
                s = is_signed ?
                    *((int8_t *)buf) :
                    *((uint8_t *)buf) + -0x80;
                break;
        }
        sv_setiv(retvals[i], s);
        Inline_Stack_Push(retvals[i]);
    }
    Inline_Stack_Done;
}

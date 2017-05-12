package Audio::C4Stream::Wav;

#
# Author: Maxime Le Quinquis <mlequinq@cloud4pc.com>,  \(c\) 2010-2011
#		: Sylvain Afchain <safchain@cloud4pc.com>,  \(c\) 2010-2011
#
# Copyright: Cloud4pc
#

use 5.010001;
use strict;
use warnings;

use FileHandle;
use IO::Scalar;
use Carp;
use Data::Dumper;

use constant MAX_AMPL => 32767;

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );
our $VERSION = '1.00';

use Inline C => Config => LDDLFLAGS => "-O3";
use Inline C => Config => LIBS      => "-lgd";
use Inline C => 'DATA', VERSION => '1.00', NAME => 'Audio::C4Stream::Wav';

sub new {
	my $class = shift;
	my %parms = @_;

	if ( !$parms{filename} ) {
		carp "No filename";
		return;
	}
	my $this = {
		leftTrimLen         => 0,
		rightTrimLen        => 0,
		fadeInLen           => 0,
		fadeOutLen          => 0,
		leftBlankDetectLen  => 0,
		rightBlankDetectLen => 0,
		blankDetectDb       => 0,
		%parms,
	};

	bless $this, $class;

	#if ( $this->{rightTrimLen} ) {
	#	$this->{rightTrimLen} = $read->length_seconds - $this->{rightTrimLen};
	#}

	my $wavReader = WAV_new_reader(
		$parms{filename},
		{
			fade_in_len    => $this->{fadeInLen} || 0,
			fade_out_len   => $this->{fadeOutLen} || 0,
			left_trim_len  => $this->{leftTrimLen} || 0,
			right_trim_len => $this->{rightTrimLen} || 0,
			ampl_ratio     => 1
		}
	);
	unless ($wavReader) {
		return;
	}

	#nb octets read --> (30 secondes)
	#$this->{_leftTrimSize}  = int( $this->{leftTrimLen} * $this->{_size} / $read->length_seconds );
	#$this->{_rightTrimSize} = int( $this->{rightTrimLen} * $this->{_size} / $read->length_seconds );

	if ( $this->{blankDetectDb} ) {
		my $blankDetectAmpl = int( &_dbToAmpl( $this->{blankDetectDb} ) );
		if ( $blankDetectAmpl > 36767 ) {
			$blankDetectAmpl = 36767;
		}

		if ($blankDetectAmpl) {
			my $blankSize = WAV_left_trim_size( $wavReader, $blankDetectAmpl );
			if ($blankSize) {
				WAV_set_left_trim_size( $wavReader, $blankSize );
				$this->{_leftTrimSize} = $blankSize;
			}

			$blankSize = WAV_right_trim_size( $wavReader, $blankDetectAmpl );
			if ($blankSize) {
				WAV_set_right_trim_size( $wavReader, $blankSize );
				$this->{_rightTrimSize} = $blankSize;
			}
		}
	}

	if ( $this->{normalize} ) {
		my $highestAmpl   = WAV_highest_ampl($wavReader);
		my $normalizeAmpl = &_dbToAmpl( $this->{normalize} );

		WAV_set_ampl_ratio( $wavReader, $normalizeAmpl / $highestAmpl );
	}
	
	$this->{_wavReader} = $wavReader;

	return $this;
}

sub _log10 {
	return log(shift) / log(10);
}

sub _dbToAmpl {
	my $db = shift;

	return MAX_AMPL * exp( $db / 20 * log(10) );
}

sub _amplToDb {
	my $ampl = shift;

	return 20 * &_log10( $ampl / MAX_AMPL );
}

sub getPngData {
	my $this = shift;

	my $read = $this->{_read};

	my $wavDraw = WAV_init_draw(
		$this->{_wavReader},
		{
			data_size => $read->length,
			data_len  => $read->length_seconds,
			font      => 'fonts/ arialbd . ttf '
		}
	);

	my $png;
	WAV_draw( $wavDraw, 634, 77 * 2 + 2 + 6, $png );

	WAV_final_draw($wavDraw);

	return $png;
}

sub getNextRawData {
	my $this = shift;

	my $data;
	WAV_read_block( $this->{_wavReader}, $data );

	return $data;
}

sub getOrigDataLen {
	return WAV_get_length( shift->{_wavReader} );
}

sub getOrigSec {
	return WAV_get_length_seconds( shift->{_wavReader} );
}

sub getDataLen {
	return WAV_data_size( shift->{_wavReader} );
}

sub getSec {
	my $this = shift;

	return WAV_get_length_seconds( $this->{_wavReader} ) - $this->{leftTrimLen} - $this->{rightTrimLen};
}

sub DESTROY {
	my $this = shift;

	WAV_final_reader( $this->{_wavReader} );
}

1;

__DATA__
=head1 NAME

Audio::C4Stream::Wav - Perl extension for open and stream WAV files.

=head1 SYNOPSIS

  use Audio::C4Stream::Wav;
  
  my $audio = new Audio::C4Stream::Wav(
		filename            => $file,
		leftTrimLen         => 5,5, #in seconds
		rightTrimLen        => 5,5, #seconds
		fadeInLen           => 10, #seconds
		fadeOutLen          => 10, #seconds
		leftBlankDetectLen  => 0, #seconds (default 20)
		rightBlankDetectLen => 0, #seconds (default 20)
		blankDetectDb       => 30, #decibels
		normalize           => 0, #decibels
  );
  

=head1 DESCRIPTION

The functions are :

=over 7

=item C<getPngData> 

Get the sine wave graphic of the WAV data

=item C<getNextData> 

Get next data

=item C<getNextRawData> 

Get next source data

=item C<getOrigDataLen> 

Get the original data length

=item C<getOrigSec> 

Get the number of seconds of the original data

=item C<getDataLen> 

Get the length of the mixed data

=item C<getSec> 

Get the seconds of the data

=back

=head1 SEE ALSO

See Audio::C4Stream::Mixer

Depends on IO::Scalar and C library GD L<https://bitbucket.org/pierrejoye/gd-libgd/overview>

=head1 AUTHOR

cloud4pc, L<adeamara@cloud4pc.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by cloud4pc

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

__C__

#include <gd.h>
#include <gdfontl.h>

#define BLOCKSIZE 4096
#define MAX_AMPL 32767

struct wav_header_s {
	int chunkSize;
	int subChunkSize;
	short format;
	short channels;
	int sampleRate;
	int byteRate;
	short blockAlign;
	short bits;
	int length;
	double seconds;
};

struct wav_channels_s {
	short left;
	short right;
};

struct wav_callback_s {
	unsigned int offset;
	void (*callback)(struct wav_read_s *wav, char *data, int size);
};

struct wav_reader_s {
	struct wav_header_s header;
	int fd;
	
	/* all needs for trim processing */
	double left_trim_len;
	double right_trim_len;
	unsigned int left_trim_size;
	unsigned int right_trim_size;
	char left_trim_flag;
	char right_trim_flag;
	
	/* all needs for fade in/out processing */
	double fade_in_len;
	double fade_out_len;
	unsigned int fade_in_size;
	unsigned int fade_out_size;
	double fade_curr_ampl;
	double fade_in_step;
	double fade_out_step;
	char fade_in_flag;
	char fade_out_flag;

	/* for normalization stuff */
	double ampl_ratio;

	char current_block[BLOCKSIZE];
	unsigned int offset;
};

struct wav_draw_s {
	struct wav_reader_s *reader;
	
	char *font;
	
	unsigned int offset;
};

int wav_read_header(struct wav_reader_s *reader, int fd) {
	struct wav_header_s *header = &(reader->header);
	char buffer[10];

	memset (buffer, 0, sizeof(buffer));
	int r = read (fd, buffer, 4);
	if (r < 4) {
		fprintf(stderr, "Error in file WAV 1 %d\\n", r);
		return -1;
	}

	if (strcmp (buffer, "RIFF")) {
		fprintf(stderr, "Error in chunkID\\n");
		return -1;
	}

	fprintf (stderr, "ici\\n");
	r = read (fd, &(header->chunkSize), sizeof(header->chunkSize));
	if (r < sizeof (header->chunkSize)) {
		fprintf(stderr, "Error in chunkSize");
		return -1;
	}
fprintf (stderr, "ici %d\\n", header->chunkSize);
	memset (buffer, 0, sizeof(buffer));
	r = read (fd, buffer, 4);
	if (r < 4) {
		fprintf(stderr, "Error in file WAV 2\\n");
		return -1;
	}
fprintf (stderr, "la%d\\n", sizeof(buffer));
	if (strcmp (buffer, "WAVE")) {
		fprintf (stderr, "1 la%d\\n", sizeof(buffer));
		fprintf(stderr, "Error in file WAV 3, %d\\n", header->chunkSize);
		fprintf (stderr, "2 la%d\\n", sizeof(buffer));
		return -1;
	}
fprintf (stderr, "ici\\n");
	memset (buffer, 0, sizeof(buffer));
	r = read (fd, buffer, 4);
	if (r < 4) {
		fprintf(stderr, "Error in file WAV 4\\n");
		return -1;
	}

	if (strcmp (buffer, "fmt ")) {
		fprintf(stderr, "Error in file WAV 5\\n");
		return -1;
	}

	r = read (fd, &header->subChunkSize, sizeof(header->subChunkSize));
	if (r < sizeof (header->subChunkSize)) {
		fprintf(stderr, "Error in subChunkSize\\n");
		return -1;
	}

	r = read (fd, &header->format, sizeof(header->format));
	if (r < sizeof (header->format)) {
		fprintf(stderr, "Error in format\\n");
		return -1;
	}
	if (header->format != 1) {
		fprintf(stderr, "Audio Format must be PCM (1)\\n");
		return -1;
	}

	r = read (fd, &header->channels, sizeof(header->channels));
	if (r < sizeof (header->channels)) {
		fprintf(stderr, "Error in channels\\n");
		return -1;
	}
	if (header->channels != 2) {
		fprintf(stderr, "There must be 2 channels\\n");
		return -1;
	}

	r = read (fd, &header->sampleRate, sizeof(header->sampleRate));
	if (r < sizeof (header->sampleRate)) {
		fprintf(stderr, "Error with sampleRate\\n");
		return -1;
	}

	if (header->sampleRate != 44100) {
		fprintf(stderr, "Rate must be 44100\\n");
		return -1;
	}
	
	r = read (fd, &header->byteRate, sizeof(header->byteRate));
        if (r < sizeof(header->byteRate)) {
               fprintf(stderr, "Error with byteRate\\n");
		return -1;
        }

	r = read (fd, &header->blockAlign, sizeof(header->blockAlign));
    if (r < sizeof(header->blockAlign)) {
		fprintf(stderr, "Error with blockAlign\\n");
			return -1;
        }

	r = read (fd, &header->bits, sizeof(header->bits));
	if (r < sizeof (header->bits)) {
    	fprintf(stderr, "Error with bits per sample\\n");
		return -1;
	}
        if (header->bits != 16) {
                fprintf(stderr, "Error with bits per sample\\n");
		return -1;
        }

		memset (buffer, 0, sizeof(buffer));
        r = read (fd, buffer, 4);
        if (r < 4) {
                fprintf(stderr, "Error in file WAV\\n");
        }

        if (strcmp (buffer, "data")) {
                fprintf(stderr, "Error in file WAV\\n");
        }
	
	r = read (fd, &header->length, sizeof(header->length));
	if (r < sizeof (header->length)) {
		fprintf(stderr, "Error in length\\n");
		return -1;
	}
	
	header->seconds = header->length / (header->sampleRate * (header->bits / 2) * header->channels);
	
	return 0;
}

struct wav_reader_s *wav_new_reader_fd (int fd) {
	struct wav_reader_s *reader;
	
	if ((reader = (struct wav_reader_s *) malloc (sizeof (struct wav_reader_s))) == NULL) {
		fprintf(stderr, "Memory allocation error\\n");
		return NULL;
	}
	memset (reader, 0, sizeof (struct wav_reader_s));
	
	reader->fd = fd;
	reader->fade_curr_ampl = MAX_AMPL;
	
	if (wav_read_header(reader, fd) == -1) {
		free (reader);
		return NULL;
	}
	return reader;
}

struct wav_reader_s *wav_new_reader (char *filename) {
	struct wav_reader_s *reader;
	int fd;

	if ((fd = open (filename, O_RDONLY)) == -1)
		return NULL;

	return wav_new_reader_fd(fd);
}

void wav_init_reader (struct wav_reader_s *reader, HV *hv){
	SV **svp;
	char *ptr;
	
	/* fade in/out stuff */
	svp = hv_fetch(hv, "fade_in_len", strlen ("fade_in_len"), 0);
	if (svp && (ptr = SvPV_nolen(*svp)) != NULL)
		reader->fade_in_len = atof(ptr);
	svp = hv_fetch(hv, "fade_out_len", strlen ("fade_out_len"), 0);
	if (svp && (ptr = SvPV_nolen(*svp)) != NULL)
		reader->fade_out_len = atof(ptr);

	reader->fade_in_size = reader->fade_in_len * (double) reader->header.length / reader->header.seconds;
	if (reader->fade_in_size) {
		reader->fade_in_step = MAX_AMPL / (double) ( reader->fade_in_size / BLOCKSIZE );
		reader->fade_in_flag = 1;
		reader->fade_curr_ampl = 0;
	}		
	reader->fade_out_size = reader->fade_out_len * (double) reader->header.length / reader->header.seconds;
	if (reader->fade_out_size) {
		reader->fade_out_step = MAX_AMPL / (double) ( reader->fade_out_size / BLOCKSIZE );
	}
	
	/* left/right trim stuff */
	svp = hv_fetch(hv, "left_trim_len", strlen ("left_trim_len"), 0);
	if (svp && (ptr = SvPV_nolen(*svp)) != NULL)
		reader->left_trim_len = atof(ptr);
	svp = hv_fetch(hv, "right_trim_len", strlen ("right_trim_len"), 0);
	if (svp && (ptr = SvPV_nolen(*svp)) != NULL)
		reader->right_trim_len = atof(ptr);
	reader->left_trim_size = reader->left_trim_len * (double) reader->header.length / reader->header.seconds;
	if (reader->left_trim_size)
		reader->left_trim_flag = 1;
	reader->right_trim_size = reader->right_trim_len * (double) reader->header.length / reader->header.seconds;	
	
	/* normalization stuff */
	svp = hv_fetch(hv, "ampl_ratio", strlen ("ampl_ratio"), 0);
	if (svp && (ptr = SvPV_nolen(*svp)) != NULL)
		reader->ampl_ratio = atof(ptr);
}

unsigned int WAV_new_reader_fd (int fd, HV *hv) {
	struct wav_reader_s *reader;
	
	if ((reader = wav_new_reader_fd(fd)) == NULL) {
		croak("Memory allocation error");
		return 0;
	}
	
	wav_init_reader(reader, hv);

	return (unsigned int) reader;
}

unsigned int WAV_new_reader (char *filename, HV *hv) {
	struct wav_reader_s *reader;
	int fd;
	
	if ((fd = open (filename, O_RDONLY)) == -1)
		return NULL;
	
	if ((reader = wav_new_reader_fd(fd)) == NULL) {
		croak("Memory allocation error");
		return 0;
	}
	
	wav_init_reader(reader, hv);

	return (unsigned int) reader;
}

void wav_final_reader (struct wav_reader_s *reader) {
	close (reader->fd);
	free (reader);
}

void WAV_final_reader (int reader_ptr) {
	return ((struct wav_reader_s *) reader_ptr);
}

unsigned int WAV_get_length (struct wav_reader_s *reader) {
	return reader->header.length;
}

double WAV_get_length_seconds (struct wav_reader_s *reader) {
	return reader->header.seconds;
}

void wav_set_left_trim_size (struct wav_reader_s *reader, unsigned int size) {
	reader->left_trim_size = size;
	if (reader->left_trim_size)
		reader->left_trim_flag = 1;
}

void WAV_set_left_trim_size (int reader_ptr, unsigned int size) {
	wav_set_left_trim_size ((struct wav_reader_s *) reader_ptr, size);
}

void wav_set_right_trim_size (struct wav_reader_s *reader, unsigned int size) {
	reader->right_trim_size = size;
}

void WAV_set_right_trim_size (int reader_ptr, unsigned int size) {
	wav_set_right_trim_size((struct wav_reader_s *) reader_ptr, size);
}

void wav_set_ampl_ratio (struct wav_reader_s *reader, double ratio) {
	reader->ampl_ratio = ratio;
}

void WAV_set_ampl_ratio (int reader_ptr, double ratio) {
	wav_set_ampl_ratio((struct wav_reader_s *) reader_ptr, ratio);
}

int wav_highest_ampl (struct wav_reader_s *reader) {
	struct wav_channels_s *channels, *chptr;
	int r, highest = 0, pos = 0;

	pos = lseek (reader->fd, 0, 1);
	
	channels = (struct wav_channels_s *) reader->current_block;
	while ((r = read (reader->fd, channels, sizeof(channels))) > 0) {
		chptr = channels;

		while (r > 0) {
			if (abs (chptr->left) > highest)
			 	highest = abs (chptr->left);
			if (abs (chptr->right) > highest)
			 	highest = abs (chptr->right);
			
			r -= sizeof (struct wav_channels_s);
		}
	}
	lseek (reader->fd, pos, 0);
	
	return highest;
}

int WAV_highest_ampl (int reader_ptr) {
	return wav_highest_ampl((struct wav_reader_s *) reader_ptr);
}

int wav_left_trim_size (struct wav_reader_s *reader, int ampl) {
	struct wav_channels_s *channels, *chptr;
	int r, size = 0, pos = 0, ampl_ratio;

	if (! ampl) {
		return 0;
	}
	
	ampl_ratio = reader->ampl_ratio;
	if (! ampl_ratio)
		ampl_ratio = 1;
	
	pos = lseek (reader->fd, 0, 1);
	
	channels = (struct wav_channels_s *) reader->current_block;
	while ((r = read (reader->fd, channels, sizeof(channels))) > 0) {
		chptr = channels;

		while (r > 0) {
			if (abs (chptr->left) * ampl_ratio > ampl || abs (chptr->right) * ampl_ratio > ampl) {
				lseek (reader->fd, pos, 0);
				return size;
			}
			
			r -= sizeof (struct wav_channels_s);
			size += sizeof (struct wav_channels_s);
		}
	}
	lseek (reader->fd, pos, 0);

	return size;	
}

int WAV_left_trim_size (int reader_ptr, int ampl) {
	return 	wav_left_trim_size((struct wav_reader_s *) reader_ptr, ampl);
}

int wav_right_trim_size (struct wav_reader_s *reader, int ampl) {
	struct wav_channels_s *channels, *chptr;
	int r, size = 0, pos = 0, seek = 0, ampl_ratio;

	if (! ampl) {
		return 0;
	}
	
	ampl_ratio = reader->ampl_ratio;
	if (! ampl_ratio)
		ampl_ratio = 1;
	
	pos = lseek (reader->fd, 0, 1);
	
	seek = pos + reader->header.length - 20 * (int) ((double) reader->header.length / reader->header.seconds / 4) * 4;
	lseek (reader->fd, seek, 0);

	channels = (struct wav_channels_s *) reader->current_block;
	while ((r = read (reader->fd, channels, sizeof(channels))) > 0) {
		chptr = channels;

		while (r > 0) {
			if (abs (chptr->left) * ampl_ratio < ampl && abs (chptr->right) * ampl_ratio < ampl) {
				size += sizeof (struct wav_channels_s);
			}
			else {
				size = 0;
			}
			
			r -= sizeof (struct wav_channels_s);
		}
	}
	lseek (reader->fd, pos, 0);

	return size;	
}

int WAV_right_trim_size(int reader_ptr, int ampl) {
	return wav_right_trim_size((struct wav_reader_s *) reader_ptr, ampl);
}

int wav_data_size (struct wav_reader_s *reader) {
	return reader->header.length - reader->left_trim_size - reader->right_trim_size;
}

int WAV_data_size (int reader_ptr) {
	return wav_data_size ((struct wav_reader_s *) reader_ptr);
}

char *wav_read_block (struct wav_reader_s *reader, int *size) {
	struct wav_channels_s *channels, *chptr, *start = NULL;
	int r, towrite;

	*size = 0;
	channels = (struct wav_channels_s *) reader->current_block;
	while ((r = read (reader->fd, channels, BLOCKSIZE)) > 0) {
		chptr = channels;
		towrite = r;
		
		if ( reader->left_trim_flag && reader->offset > reader->left_trim_size ) {
			reader->left_trim_flag = 0;
		}
		
		if (reader->left_trim_flag) {
			while (r > 0) {
				if (reader->offset > reader->left_trim_size) {
					reader->left_trim_flag = 0;
					break;
				}
				r -= sizeof (struct wav_channels_s);
				towrite -= sizeof (struct wav_channels_s);
				reader->offset += sizeof (struct wav_channels_s);
				chptr++;
			}
		}
		start = chptr;
		
		if (towrite <= 0)
			continue;
		
		if ( reader->offset > ( reader->header.length - reader->right_trim_size) ) {
			return NULL;
		}
		
		if ( reader->fade_in_flag && reader->offset > reader->fade_in_size + reader->left_trim_size ) {
			reader->fade_in_flag = 0;
		}
		
		if ( !reader->fade_out_flag && reader->offset > ( reader->header.length - reader->fade_out_size - reader->right_trim_size) ) {
			reader->fade_out_flag = 1;
			reader->fade_curr_ampl = MAX_AMPL;
		}

		if ( reader->fade_in_flag || reader->fade_out_flag || reader->ampl_ratio != 1) {
			while (r > 0) {
				if ( reader->offset > ( reader->header.length - reader->right_trim_size) ) {
					towrite -= r;
					break;
				}
		
				chptr->left = (short) ((double) chptr->left * reader->ampl_ratio * (reader->fade_curr_ampl / MAX_AMPL));
				chptr->right = (short) ((double) chptr->right * reader->ampl_ratio * (reader->fade_curr_ampl / MAX_AMPL));
				
				r -= sizeof (struct wav_channels_s);
				reader->offset += sizeof (struct wav_channels_s);
				chptr++;
			}
			
			if (reader->fade_in_flag && reader->fade_curr_ampl <= MAX_AMPL) {
				reader->fade_curr_ampl += reader->fade_in_step;
			}
			else if (reader->fade_out_flag && reader->fade_curr_ampl >= 0) {
				reader->fade_curr_ampl -= reader->fade_out_step;
				fprintf(stderr, "%d\\n", (unsigned int) reader->fade_curr_ampl);
			}
			if (reader->fade_curr_ampl > MAX_AMPL) {
				reader->fade_curr_ampl = MAX_AMPL;
			}
			else if (reader->fade_curr_ampl < 0) {
				reader->fade_curr_ampl = 0;
			}
		}
		reader->offset += r;
		
		if ( towrite ) {	
			*size = towrite;
			
			return start;
		}
	}
	
	return NULL;
}

int WAV_read_block (int reader_ptr, SV *data) {
	struct wav_reader_s *reader = (struct wav_reader_s *) reader_ptr;
	char *start;
	int size;
	
	start = wav_read_block (reader, &size);
	if (size)
		sv_setpvn(data, (char *) start, size);
	
	return size;
}

struct wav_draw_s *wav_init_draw (struct wav_reader_s *reader) {
	struct wav_draw_s *draw;
	char *ptr;
	SV **svp;
	
	if ((draw = (struct wav_draw_s *) malloc (sizeof (struct wav_draw_s))) == NULL) {
		fprintf(stderr, "Memory allocation error\\n");
		return NULL;
	}
	memset (draw, 0, sizeof (struct wav_draw_s));
	
	draw->reader = reader;

	return draw;
}

unsigned int WAV_init_draw (int reader_ptr, HV *hv) {
	struct wav_reader_s *reader = (struct wav_reader_s *) reader_ptr;
	struct wav_draw_s *draw;
	char *ptr;
	SV **svp;
	
	if ((draw = wav_init_draw(reader)) == NULL) {
		croak("Memory allocation error");
		return 0;
	}
	
	svp = hv_fetch(hv, "font", strlen ("font"), 0);
	if (svp && (ptr = SvPV_nolen(*svp)) != NULL)
		draw->font = ptr;

	if (draw->font == NULL) {
		croak("No font");
	}
	
	return (unsigned int) draw;
}

void wav_final_draw (struct wav_draw_s *draw) {
	free (draw);
}

void WAV_final_draw (int draw_ptr) {
	free ((struct wav_draw_s *) draw_ptr);
}

char *wav_draw (struct wav_draw_s *draw, int width, int height, int *size) {
	struct wav_reader_s *reader;
	struct wav_channels_s *chptr;
	gdImagePtr im;
	int styleDotted[4];
  	int white, blue, orange, color, hblue, lblue, green, second, thrid;
  	int i, r, offset, data_size;
  	int xval, yval1, yval2, ymin1, ymin2, ymax1, ymax2;
  	int xtmp = 0, ytmp = 0, lx, ly1 = 0, ly2 = 0;
  	int draw1, draw2, pos;
  	int limit, mlimit1, mlimit2;
  	double step, curr;
  	char *font = "fonts/db.ttf";
  	char *png_ptr, *err;
  	int brect[8];
	
	if ((im = gdImageCreate(width, height)) == NULL) {
		fprintf(stderr, "gdImageCreate failed");
		return NULL;
	}
	
	white = gdImageColorAllocate(im, 255, 255, 255 );
	gdImageRectangle(im, 0, 0, width, height, white);
	
	hblue = gdImageColorAllocate(im, 90, 117, 112 );	//#5A7570
	green = gdImageColorAllocate(im, 47, 61, 58 );  	//#2f3d3a
	lblue = gdImageColorAllocate(im, 156, 176, 173 );	//#9CB0AD
	orange = gdImageColorAllocate(im, 223, 223, 223 ); 	//#DFDFDF
	second = gdImageColorAllocate(im, 86, 108, 105 ); 	//#DFDFDF
	thrid = gdImageColorAllocate(im, 110, 140, 135 ); 	//#DFDFDF
	
	blue = gdImageColorAllocate(im, 99, 126, 122 );		//008CEF
	
	gdImageFilledRectangle(im, 0, 0, width - 1, height - 1, orange);
	
	gdImageFilledRectangle(im, 0, 0, width - 1, height / 2 - 4, lblue);
	gdImageRectangle(im, 0, 0, width - 1, height / 2 - 4, hblue);
	
	gdImageFilledRectangle(im, 0, height / 2 + 3, width - 1, height - 1, lblue);
	gdImageRectangle(im, 0, height / 2 + 3, width - 1, height - 1, hblue);	
	
	styleDotted[0] = second;
	styleDotted[1] = gdTransparent;
	styleDotted[2] = gdTransparent;
	styleDotted[3] = gdTransparent;
	
	/*step = (double) ( 250 - 220 ) / height;
	for ( curr = 250, i = 0 ; i != height ; i++ ) {
		color = gdImageColorAllocate(im, (int) 156, (int) 176, (int) 173 );    //#9CB0AD
		gdImageLine(im, 0, i, width, i, color);
		
		curr -= step;
	}*/
	
	xval = -1;
	
	yval1 = -1;
	ymin1 = 0;
	ymax1 = 0;
	
	yval2 = -1;
	ymin2 = 0;
	ymax2 = 0;
	
	limit = height / 2 - 2;
	mlimit1 = height / 4;
	mlimit2 = height - height / 4;
		
	pos = lseek (draw->reader->fd, 0, 1);
	
	reader = draw->reader;
	
	draw->offset = 0;
	data_size = wav_data_size (reader);

	while ((chptr = wav_read_block (reader, &r)) != NULL) {
		i = 0;
		while (i < r) {
			xtmp = ((double) draw->offset / data_size) * width;
			ytmp = 0 - ((double) chptr->left / 65536) * limit;

			if (xval == -1 || xval != xtmp) {
				draw1 = draw2 = 1;
				xval = xtmp;
				ymin1 = ymax1 = ymin2 = ymax2 = 0;
			}
			
			if (ytmp < ymin1) {
				ymin1 = ytmp;
				draw1 = 1;
			}
			else if (ytmp > ymax1) {
				ymax1 = ytmp;
				draw1 = 1;
			}
			
			if (draw1) {
				gdImageLine(im, lx, ly1 + mlimit1 - 1, xval, ytmp + mlimit1 - 1, hblue);
				lx = xval;
				ly1 = ytmp;
				draw1 = 0;
			}
			
			ytmp = 0 - ((double) chptr->right / 65536) * limit;
			
			if (ytmp < ymin2) {
				ymin2 = ytmp;
				draw2 = 1;
			}
			else if (ytmp > ymax2) {
				ymax2 = ytmp;
				draw2 = 1;
			}
			
			if ( draw2 ) {
				gdImageLine(im, lx, ly2 + mlimit2 + 1, xval, ytmp + mlimit2 + 1, hblue);
				lx = xval;
				ly2 = ytmp;
				draw2 = 0;
			}

			i += sizeof (struct wav_channels_s);
			draw->offset += sizeof (struct wav_channels_s);
			chptr++;
		}
	}
	
	gdImageStringFT(im, brect, white, font, 8, 0, 5, mlimit1 + height / 8 + 13, "-6,0 db");	
	gdImageStringFT(im, brect, white, font, 8, 0, 5, mlimit2 - height / 8 - 4, "-6,0 db");
	gdImageStringFT(im, brect, white, font, 8, 0, 5, mlimit2 + height / 8 + 14, "-6,0 db");
	gdImageStringFT(im, brect, white, font, 8, 0, 5, height / 8 - 6, "-6,0 db");	
	
	gdImageLine(im, 0, mlimit1 - 1, width, mlimit1 - 1, second);
	gdImageLine(im, 0, mlimit1, width, mlimit1, blue);
	gdImageLine(im, 0, mlimit2, width, mlimit2, second);
	gdImageLine(im, 0, mlimit2 + 1, width, mlimit2 + 1, blue);
	
	gdImageSetStyle(im, styleDotted, 4);
	gdImageLine(im, 1, height / 8 - 1, width - 2, height / 8 - 1, gdStyled);
	gdImageLine(im, 1, mlimit2 + height / 8 + 1, width - 2, mlimit2 + height / 8 + 1, gdStyled);
	gdImageLine(im, 1, mlimit2 - height / 8 + 1, width - 2, mlimit2 - height / 8 + 1, gdStyled);
	gdImageLine(im, 1, mlimit1 + height / 8 - 1, width - 2, mlimit1 + height / 8 - 1, gdStyled);
	
	
	png_ptr = gdImagePngPtr(im, size);

	lseek (draw->reader->fd, pos, 0);
	
	return png_ptr;

}

int WAV_draw (int draw_ptr, int width, int height, SV *png) {
	char *png_ptr;
	int size;
	
	if ((png_ptr = wav_draw ((struct wav_draw_s *) draw_ptr, width, height, &size)) == NULL) {
		return 0;
	}
	
	sv_setpvn(png, png_ptr, size);
	
	return size;
}

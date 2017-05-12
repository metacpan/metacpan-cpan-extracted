package Audio::C4Stream::Mixer;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '1.00';

require XSLoader;
XSLoader::load('Audio::C4Stream::Mixer', $VERSION);

use Carp;

# 44100, 16bits, stereo
use constant PCMRATE => 176_400;

sub new {
	my $class = shift;
	my %parms = @_;

	my $this = {
		duration		=> 5,
		silentOut		=> 2,
		silentIn		=> 0,
		%parms,
		_buffer 			=> '',
		_decks 				=> ['', ''],		# just two deck A, B
		_currentDeck 		=> 0,
		_crossfading		=> 0
	};
	
	$this->{_crossfadeLen} = $this->{duration} * PCMRATE;
	$this->{_crossfader} = CROSSFADE_init ($this->{duration});
	
	$this->{_silentOutData} = '';
	if ($this->{silentOut}) {
		my $size = int (($this->{silentOut} * PCMRATE) / 4) * 4;
		$this->{_silentOutData} = pack ('c', 0) x $size;
	}
	
	$this->{_silentInData} = '';
	if ($this->{silentIn}) {
		my $size = int (($this->{silentIn} * PCMRATE) / 4) * 4;
		$this->{_silentInData} = pack ('c', 0) x $size;
	}
	
	$this->{_crossfadeLen} = int ($this->{_crossfadeLen} / 4) * 4;
	
	return bless $this, $class;
}

sub mixPcmFrames {
	my $this = shift;
	my $frames = shift;

	my $decks = $this->{_decks};

	$decks->[$this->{_currentDeck}] .= $frames;
	my $len = length($decks->[$this->{_currentDeck}]);
	
	# buffer for crossfading has reach the good len
	if (! $this->{_crossfading}) {
		if ($len > $this->{_crossfadeLen}) {
			my $data = substr ($decks->[$this->{_currentDeck}], 0, $len - $this->{_crossfadeLen}, '');
			
			return $data;
		}
	}
	else {
		if ($len >= $this->{_crossfadeLen}) {
			my $prevDeck = ($this->{_currentDeck} + 1) % 2;
			
			# if silentOut append silentOutData to the end of the previous deck
			if ($this->{silentOut}) {
				$decks->[$prevDeck] .= $this->{_silentOutData};
			}
			
			my $crossfadeLen = $this->{_crossfadeLen};
			
			my $lenPrevDeck = length($decks->[$prevDeck]);
			
			my $left = '';
			if ($lenPrevDeck >= $crossfadeLen) {
				$left = substr ($decks->[$prevDeck], 0, $lenPrevDeck - $crossfadeLen, '');
			}
			
			my $dataP = $decks->[$prevDeck];
			if (! length($dataP)) {
				my $data = substr ($decks->[$this->{_currentDeck}], 0, $len - $crossfadeLen, '');
		
				return $data;
			}

			# if silentIn add silentInData in front of the current deck
			if ($this->{silentIn}) {
				$decks->[$this->{_currentDeck}] = $this->{_silentInData} . $decks->[$this->{_currentDeck}];
			}
			
			my $dataN = substr ($decks->[$this->{_currentDeck}], 0, $crossfadeLen, '');
			$decks->[$prevDeck] = '';

			$this->{_crossfading} = 0;
			
			# if there is not enough in dataP simple concat 
			if ($lenPrevDeck < $crossfadeLen) {
				return $dataN.$dataP;
			}
			
			my $mixed = $dataP;
			CROSSFADE_ease_in_out_quad ($this->{_crossfader}, $dataP, $dataN, $mixed);

			return $left.$mixed;
		}	
	}
	
	return '';
}

sub switch {
	my $this = shift;
	
	my $decks = $this->{_decks};
	
	# switch the current deck
	$this->{_currentDeck} = ($this->{_currentDeck} + 1) % 2;
	
	$this->{_crossfading} = 1;
}

sub DESTROY {
	my $this = shift;
}

1;
__END__
=head1 NAME

Audio::C4Stream::Mixer - Perl extension for crossfade mixer.

=head1 SYNOPSIS

  use Audio::C4Stream::Mixer;
  
  my $mixer = new Audio::C4Stream::Mixer(duration => 1, silentOut => 0.8, silentIn => 0);
  $mixer->switch();

=head1 DESCRIPTION

This library can make crossfades.
Use it only with 16bits stereo, 44100hz sounds.

=head2 Constructor

Parameters are :

=over 3

=item C<duration> 

Crossfade time

=item C<silentOut> 

Silence time at the end

=item C<silentIn>  

Silence time at the beginning

=back

=head2 Fonctions

The functions are :

=over 2

=item C<mixPcmFrames> 

Accumulate the audio data

=item C<switch> 

Change the deck (only two : A or B)

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

See L<Audio::C4Stream::Wav>

=head1 AUTHOR

cloud4pc, L<adeamara@cloud4pc.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by cloud4pc

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

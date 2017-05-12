package Crypt::Enigma;

$VERSION = '1.4';

use strict;

sub new {
	my $class = shift;
	my $args = ref($_[0]) ? shift : {@_};

	# Setup the object
	my $self = {
		_rotorObjects		=> undef,
		_reflectorObject	=> undef,
		_stecker			=> undef,
		_settings			=> [],
		_debug				=> 0,
	};
	bless $self, $class;

	$self->_init( $args );

	return( $self );
};

sub _init {
	my $self = shift;
	my $args = shift;

	foreach( keys %{$args} ) {
		if( ($_ =~ /^(rotors|startletters|ringsettings|stecker)$/) && (ref($args->{$_}) ne 'ARRAY') ) {
			$self->_printDebug( "Argument '$_' should be an array reference (using defaults)" );
			delete( ${$args}{$_} );
		};
	};

	my $rotors			= $args->{rotors} || [ 'RotorI', 'RotorII', 'RotorIII' ];
	my $startletters	= $args->{startletters} || [ 'Z', 'A', 'A' ];
	my $rings			= $args->{ringsettings} || [ 0, 0, 0 ];
	my $reflector		= $args->{reflector} || 'ReflectorB';
	my $stecker			= $args->{stecker} || [];

	if( @{$rotors} < 3 ) {
		$self->_printDebug( 'A minimum of 3 rotors must be defined (using defaults)' );
		my @misc_rotors = ( 'RotorV', 'RotorVI', 'RotorVII' );
		while( @{$rotors} < 3 ) {
			push @{$rotors}, shift @misc_rotors;
		};
	};

	my $count = 0;
	foreach( @{$rotors} ) {
		push @{$self->{_settings}}, [ $_, $startletters->[$count], $rings->[$count] ];
		$count++;
	};

	# Create Reflector
	$self->setReflector( $reflector );

	# Setup Steckerboard
	$self->setSteckerBoard( $stecker );

	return( $self );
};


sub getRotorNames {
	my $self = shift;
	my @names;

	foreach( $self->_getRotorObjects ) {
		push @names, $_->getName;
	};	

	return( @names );
};

sub getStartLetters {
	my $self = shift;
	my @letters;

	foreach( $self->_getRotorObjects ) {
		push @letters, $_->getStartLetter;
	};	
	return( @letters );
};

sub getRingSettings {
	my $self = shift;                   
	my @rings;
	foreach( $self->_getRotorObjects ) {
		push @rings, $_->getRingSetting;
	};	
	return( @rings );
};

sub getReflector {
	my $self = shift;
	return( $self->{_reflectorObject}->getName );
};

sub setSteckerBoard {
	my $self = shift;
	my $stecker = shift;

	unless( (@{$stecker} % 2) == 0 ) {
		$self->_printDebug( 'Odd number of letters in setSteckerBoard (disabling Steckerboard)' );
		return;
	};

	for(my $count = 0; $count < @{$stecker}; $count = $count+2 ) {
		my $letter1 = uc( $stecker->[$count] );
		my $letter2 = uc( $stecker->[$count+1] );
		$self->{_stecker}->{$letter1} = $letter2;
		$self->{_stecker}->{$letter2} = $letter1;
	};

	return;
};

sub dumpSettings {
	my $self = shift;

	print STDERR "Rotors:\t\t". join( ' ', $self->getRotorNames ) ."\n";
	print STDERR "Start:\t\t". join( ' ', $self->getStartLetters ) ."\n";
	print STDERR "Rings:\t\t". join( ' ', $self->getRingSettings ) ."\n";
	print STDERR "Reflector:\t". $self->getReflector ."\n";

	return;
};

sub setRotor {
	my $self = shift;
	my $rotorName = shift;
	my $startLetter = uc( shift );
	my $ringSetting = shift;
	my $rotorNumber = shift;

	# Do some checking
	unless( defined($rotorName) && ($rotorName =~ /^Rotor(I|II|III|IV|V|VI|VII|VIII|Beta|Gamma)$/) ) {
		$self->_printDebug( 'Invalid rotor name (using default \'RotorI\')' );
		$rotorName = 'RotorI';
	};

	unless( defined($startLetter) && $startLetter =~ /^[A-Z]$/ ) {
		$self->_printDebug( "Invalid start letter (using default 'A' for $rotorName)" );
		$startLetter = 'A';
	};

	unless( defined($ringSetting) && ($ringSetting =~ /[0-9]$/) && ($ringSetting >= 0) && ($ringSetting <= 25) ) {
		$self->_printDebug( "Invalid ring setting (using default '0' for $rotorName)" );
		$ringSetting = 0;
	}

	unless( defined($rotorNumber) && ($rotorNumber > 0) && ($rotorNumber < 6) ) {
		$self->_printDebug( "Invalid rotor number (failed to add rotor $rotorName)" );
		return( 0 );
	};

	my $className = 'Crypt::Enigma::Rotors::'.$rotorName;
	my $rotorObj = $className->new( $startLetter, $ringSetting );
	$self->_storeRotorObject( $rotorObj, $rotorNumber-1 );

	return( 1 );
};


sub setReflector {
	my $self = shift;
	my $reflector = shift;

	unless( $reflector =~ /^Reflector(B|Bdunn|C|Cdunn)$/ ) {
		$self->_printDebug( 'Invalid reflector name (using default \'ReflectorB\')' );
		$reflector = 'ReflectorB';
	};

	my $reflectorClass = 'Crypt::Enigma::Reflectors::' . $reflector;
	my $reflectorObj = $reflectorClass->new;
	$self->_storeReflectorObject( $reflectorObj );

	return( 1 );
};


sub cipher {
	my $self = shift;
	my $plainText = uc(shift);
	my $cipherText = '';

	# setup the rotors
	my $count = 1;
	foreach( @{$self->{_settings}} ) {
		# setRotor(rotorName, startLetter, ringSetting, rotorNumber)
		$self->setRotor( $_->[0], , $_->[1], $_->[2], $count);
		$count++;
	};

	foreach my $letter ( split('', $plainText) ) {
		# next if the text is not alpha
		if( $letter !~ /[A-Z]/ ) {
			next;
		};

		# Stecker
		$letter = $self->_performSteckerSwap( $letter );

		# fwd cycle
		my $count = 0;
		foreach( $self->_getRotorObjects ) {
			# We always rotate the first scrambler
			if( $count == 0 ) {
				$_->_rotateDisk;
			};
			$letter = $_->fwdCipher( $letter );
			# rotate the next disk, if the flag is set
			if( $_->_getFlag('rotateNext') && ($count != 2) ) {
				$self->_cycleNextRotor( $self->_getRotorObject($count+1) );
				$_->_setFlag( rotateNext => 0 );
			};
			$count++;
		};

		# reflector
		$letter = $self->_reflect( $letter );

		# rev cycle
		foreach( reverse($self->_getRotorObjects) ) {
			$letter = $_->revCipher( $letter );
		};

		# Stecker
		$letter = $self->_performSteckerSwap( $letter );

		$cipherText .= $letter;
	};

	# return uppercase ciphertext, like the original Enigma would do :)
	return( uc($cipherText) );
};


sub _getRotorName {
	my $self = shift;
	my $rotor = shift;
	return( $self->{settings}->{_rotorObjects}->[$rotor]->getName );
};

sub _getStartLetter {
	my $self = shift;
	my $letter = shift;
	return( $self->{settings}->{startletters}->[$letter] );
};

sub _getRingSetting {
	my $self = shift;
	my $ring = shift;
	return( $self->{settings}->{rings}->[$ring] );
};

sub _storeRotorObject {
	my $self = shift;
	my $rotorObj = shift;
	my $rotorNumber = shift;

	if( defined($rotorNumber) ) {
		$self->{_rotorObjects}->[$rotorNumber] = $rotorObj;
	}
	else {
		push @{$self->{_rotorObjects}}, $rotorObj;
	};

	return( 1 );
};

sub _getRotorObject {
	my $self = shift;
	my $rotor = shift;
	return( $self->{_rotorObjects}->[$rotor] );
};

sub _getRotorObjects {
	my $self = shift;
	return( @{$self->{_rotorObjects}} );
};

sub _storeReflectorObject {
    my $self = shift;
    my $reflectorObj = shift;
    $self->{_reflectorObject} = $reflectorObj;
    return( 1 );
};

sub _getReflectorObject {
    my $self = shift;
    return( $self->{_reflectorObject} );
};


# alter the input using the reflector
sub _reflect {
	my $self = shift;
	my $inputLetter = shift;

	my $outputLetter = $self->_getReflectorObject->_reflect( $inputLetter );

	return( $outputLetter );
};

# alter the letter using the Steckerboard
sub _performSteckerSwap {
	my $self = shift;
	my $inputLetter = shift;

	if( defined($self->{_stecker}->{$inputLetter}) ) {
		return( $self->{_stecker}->{$inputLetter} );
	};

	return( $inputLetter );
};

# Rotate the next rotor
sub _cycleNextRotor {
	my $self = shift;
	my $rotorObj = shift;
	$rotorObj->_rotateDisk;

	return;
};

sub _printDebug {
	my $self = shift;
	my $msg = shift;

	if( $self->{_debug} ) {
		print $msg, "\n";
	};

	return;
};

sub setDebug {
	my $self = shift;
	my $debug = shift || 0;

	$self->{_debug} = $debug;

	return;
};

package Crypt::Enigma::Reflectors;

use strict;

sub _reflect {
	my $self = shift;
	my $inputLetter = shift;

  my $intInputLetter = ord($inputLetter) - 65;

  my $outputLetter = ${$self->{_alphabet}}[$intInputLetter];

  return( $outputLetter );
};

sub getName {
	my $self = shift;
	return( $self->{_label} );
};


package Crypt::Enigma::Reflectors::ReflectorB;

@Crypt::Enigma::Reflectors::ReflectorB::ISA = qw(Crypt::Enigma::Reflectors);

sub new {
	my $class = shift;

	my $self = {
		'_label'	=> 'ReflectorB',
		'_alphabet'		=> [ 
			'Y', 'R', 'U', 'H', 'Q', 'S', 'L', 'D', 'P', 'X', 'N', 'G', 'O', 'K', 'M', 'I', 'E', 'B', 'F', 'Z', 'C', 'W', 'V', 'J', 'A', 'T'
		],
	};
	bless $self, $class;

	return( $self );
};


package Crypt::Enigma::Reflectors::ReflectorBdunn;


@Crypt::Enigma::Reflectors::ReflectorBdunn::ISA = qw(Crypt::Enigma::Reflectors);

sub new {
	my $class = shift;

	my $self = {
		'_label'	=> 'ReflectorBdunn',
		'_alphabet'		=> [ 
			'E', 'N', 'K', 'Q', 'A', 'U', 'Y', 'W', 'J', 'I', 'C', 'O', 'P', 'B', 'L', 'M', 'D', 'X', 'Z', 'V', 'F', 'T', 'H', 'R', 'G', 'S'
		],
	};
	bless $self, $class;

	return( $self );
};


package Crypt::Enigma::Reflectors::ReflectorC;

@Crypt::Enigma::Reflectors::ReflectorC::ISA = qw(Crypt::Enigma::Reflectors);

sub new {
	my $class = shift;

	my $self = {
		'_label'	=> 'ReflectorC',
		'_alphabet'		=> [ 
			'F', 'N', 'P', 'J', 'I', 'A', 'O', 'Y', 'E', 'D', 'R', 'Z', 'X', 'W', 'G', 'C', 'T', 'K', 'U', 'Q', 'S', 'B', 'N', 'M', 'H', 'L'
		],
	};
	bless $self, $class;

	return( $self );
};


package Crypt::Enigma::Reflectors::ReflectorCdunn;

@Crypt::Enigma::Reflectors::ReflectorCdunn::ISA = qw(Crypt::Enigma::Reflectors);

sub new {
	my $class = shift;

	my $self = {
		'_label'	=> 'ReflectorCdunn',
		'_alphabet'		=> [ 
			'R', 'D', 'O', 'B', 'J', 'N', 'T', 'K', 'V', 'E', 'H', 'M', 'L', 'F', 'C', 'W', 'Z', 'A', 'X', 'G', 'Y', 'I', 'P', 'S', 'U', 'Q'
		],
	};
	bless $self, $class;

	return( $self );
};


package Crypt::Enigma::Rotors;

use strict;

sub _init {
	my $self = shift;
	my $startLetter = shift;

	my $intStartLetter = ord($startLetter) - 65;

	for( my $count = 0; $count < $intStartLetter; $count++ ) {
		# rotate the letters
		my $letter = pop @{$self->{_alphabet}};
		unshift @{$self->{_alphabet}}, $letter;
		$self->{_cycleLetterPosition} == 0 ? $self->{_cycleLetterPosition} = 25 : $self->{_cycleLetterPosition}--;
	};

	return( 0 );
};

sub getName {
	my $self = shift;
	return( $self->{_label} );
};

sub getStartLetter {
	my $self = shift;
	return( $self->{_startLetter} );
};

sub getRingSetting {
	my $self = shift;
	return( $self->{_ringSetting} );
};

sub fwdCipher {
	my $self = shift;
	my $inputLetter = shift;

	my $intInputLetter = ( ord($inputLetter) - 65 + $self->{_ringSetting} ) % 26;
	my $outputLetter = ${$self->{_alphabet}}[$intInputLetter];

	return( $outputLetter );
};


sub revCipher {
	my $self = shift;
	my $inputLetter = shift;
	my $outputLetter;

	my $count = 0;
	foreach ( @{$self->{_alphabet}} ) {
		if( $inputLetter eq $_ ) {
				$outputLetter = chr((($count - $self->{_ringSetting} + 26) % 26) + 65);
		};
		$count++;
	};
	return( $outputLetter );
};


# rotate the polyalphabetic substitution by 1 letter
sub _rotateDisk {
	my $self = shift;

	my $letter = pop @{$self->{_alphabet}};
	unshift @{$self->{_alphabet}}, $letter;

	if( $self->{_cycleLetterPosition} == 0 ) {
		$self->_setFlag( rotateNext => 1 );
		$self->{_cycleLetterPosition} = 25;
	}
	else {
		$self->{_cycleLetterPosition}--;
	};

	return( 0 );
};


sub _setFlag {
	my $self = shift;
	my $flag = shift;
	my $bool = shift;

	$self->{flags}->{$flag} = $bool;

	return( 1 );
};

sub _getFlag {
	my $self = shift;
	my $flag = shift;

	if( defined($self->{flags}->{$flag}) ) {
		return( $self->{flags}->{$flag} );
	};

	return( 0 );
};


package Crypt::Enigma::Rotors::RotorI;

@Crypt::Enigma::Rotors::RotorI::ISA = qw(Crypt::Enigma::Rotors);

sub new {
	my $class = shift;
	my $startLetter = shift;
	my $ringSetting = shift;

	my $self = {
		'_label'	=> 'RotorI',
		'_cycleLetterPosition' => (16 + $ringSetting) % 25,
		'_ringSetting' => $ringSetting,
		'_startLetter' => $startLetter,
		'_alphabet' => [
			'E', 'K', 'M', 'F', 'L', 'G', 'D', 'Q', 'V', 'Z', 'N', 'T', 'O', 'W', 'Y', 'H', 'X', 'U', 'S', 'P', 'A', 'I', 'B', 'R', 'C', 'J'
			]
	};
	bless $self, $class;

	$self->_init( $startLetter );

	return( $self );
};


package Crypt::Enigma::Rotors::RotorII;

@Crypt::Enigma::Rotors::RotorII::ISA = qw(Crypt::Enigma::Rotors);

sub new {
	my $class = shift;
	my $startLetter = shift;
	my $ringSetting = shift;

	my $self = {
		'_label'	=> 'RotorII',
		'_cycleLetterPosition' => (5 + $ringSetting) % 25,
		'_ringSetting' => $ringSetting,
		'_startLetter' => $startLetter,
		'_alphabet' => [
			'A', 'J', 'D', 'K', 'S', 'I', 'R', 'U', 'X', 'B', 'L', 'H', 'W', 'T', 'M', 'C', 'Q', 'G', 'Z', 'N', 'P', 'Y', 'F', 'V', 'O', 'E'
			]
	};
	bless $self, $class;

	$self->_init( $startLetter );

	return( $self );
};


package Crypt::Enigma::Rotors::RotorIII;

@Crypt::Enigma::Rotors::RotorIII::ISA = qw(Crypt::Enigma::Rotors);

sub new {
	my $class = shift;
	my $startLetter = shift;
	my $ringSetting = shift;

	my $self = {
		'_label'	=> 'RotorIII',
		'_cycleLetterPosition' => (22 + $ringSetting) % 25,
		'_ringSetting' => $ringSetting,
		'_startLetter' => $startLetter,
		'_alphabet' => [
			'B', 'D', 'F', 'H', 'J', 'L', 'C', 'P', 'R', 'T', 'X', 'V', 'Z', 'N', 'Y', 'E', 'I', 'W', 'G', 'A', 'K', 'M', 'U', 'S', 'Q', 'O'
			]
	};
	bless $self, $class;

	$self->_init( $startLetter );

	return( $self );
};


package Crypt::Enigma::Rotors::RotorIV;

@Crypt::Enigma::Rotors::RotorIV::ISA = qw(Crypt::Enigma::Rotors);


sub new {
	my $class = shift;
	my $startLetter = shift;
	my $ringSetting = shift;

	my $self = {
		'_label'	=> 'RotorIV',
		'_cycleLetterPosition' => (10 + $ringSetting) % 25,
		'_ringSetting' => $ringSetting,
		'_startLetter' => $startLetter,
		'_alphabet' => [
			'E', 'S', 'O', 'V', 'P', 'Z', 'J', 'A', 'Y', 'Q', 'U', 'I', 'R', 'H', 'X', 'L', 'N', 'F', 'T', 'G', 'K', 'D', 'C', 'M', 'W', 'B'
			]
	};
	bless $self, $class;

	$self->_init( $startLetter );

	return( $self );
};


package Crypt::Enigma::Rotors::RotorV;

@Crypt::Enigma::Rotors::RotorV::ISA = qw(Crypt::Enigma::Rotors);


sub new {
	my $class = shift;
	my $startLetter = shift;
	my $ringSetting = shift;

	my $self = {
		'_label'	=> 'RotorV',
		'_cycleLetterPosition' => (0 + $ringSetting) % 25,
		'_ringSetting' => $ringSetting,
		'_startLetter' => $startLetter,
		'_alphabet' => [
			'V', 'Z', 'B', 'R', 'G', 'I', 'T', 'Y', 'U', 'P', 'S', 'D', 'N', 'H', 'L', 'X', 'A', 'W', 'M', 'J', 'Q', 'O', 'F', 'E', 'C', 'K'
			]
	};
	bless $self, $class;

	$self->_init( $startLetter );

	return( $self );
};



package Crypt::Enigma::Rotors::RotorVI;

@Crypt::Enigma::Rotors::RotorVI::ISA = qw(Crypt::Enigma::Rotors);


sub new {
	my $class = shift;
	my $startLetter = shift;
	my $ringSetting = shift;

	my $self = {
		'_label'	=> 'RotorVI',
		'_cycleLetterPosition' => (13 + $ringSetting) % 25,
		'_ringSetting' => $ringSetting,
		'_startLetter' => $startLetter,
		'_alphabet' => [
			'J', 'P', 'G', 'V', 'O', 'U', 'M', 'F', 'Y', 'Q', 'B', 'E', 'N', 'H', 'Z', 'R', 'D', 'K', 'A', 'S', 'X', 'L', 'I', 'C', 'T', 'W'
			]
	};
	bless $self, $class;

	$self->_init( $startLetter );

	return( $self );
};



package Crypt::Enigma::Rotors::RotorVII;

@Crypt::Enigma::Rotors::RotorVII::ISA = qw(Crypt::Enigma::Rotors);


sub new {
	my $class = shift;
	my $startLetter = shift;
	my $ringSetting = shift;

	my $self = {
		'_label'	=> 'RotorVII',
		'_cycleLetterPosition' => (13 + $ringSetting) % 25,
		'_ringSetting' => $ringSetting,
		'_startLetter' => $startLetter,
		'_alphabet' => [
			'N', 'Z', 'J', 'H', 'G', 'R', 'C', 'X', 'M', 'Y', 'S', 'W', 'B', 'O', 'U', 'F', 'A', 'I', 'V', 'L', 'P', 'E', 'K', 'Q', 'D', 'T'
			]
	};
	bless $self, $class;

	$self->_init( $startLetter );

	return( $self );
};



package Crypt::Enigma::Rotors::RotorVIII;

@Crypt::Enigma::Rotors::RotorVIII::ISA = qw(Crypt::Enigma::Rotors);


sub new {
	my $class = shift;
	my $startLetter = shift;
	my $ringSetting = shift;

	my $self = {
		'_label'	=> 'RotorVIII',
		'_cycleLetterPosition' => (13 + $ringSetting) % 25,
		'_ringSetting' => $ringSetting,
		'_startLetter' => $startLetter,
		'_alphabet' => [
			'F', 'K', 'Q', 'H', 'T', 'L', 'X', 'O', 'C', 'B', 'J', 'S', 'P', 'D', 'Z', 'R', 'A', 'M', 'E', 'W', 'N', 'I', 'U', 'Y', 'G', 'V'
			]
	};
	bless $self, $class;

	$self->_init( $startLetter );

	return( $self );
};



package Crypt::Enigma::Rotors::RotorBeta;

@Crypt::Enigma::Rotors::RotorBeta::ISA = qw(Crypt::Enigma::Rotors);


sub new {
	my $class = shift;
	my $startLetter = shift;
	my $ringSetting = shift;

	my $self = {
		'_label'	=> 'RotorBeta',
		'_cycleLetterPosition' => (13 + $ringSetting) % 25,
		'_ringSetting' => $ringSetting,
		'_startLetter' => $startLetter,
		'_alphabet' => [
			'L', 'E', 'Y', 'J', 'V', 'C', 'N', 'I', 'X', 'W', 'P', 'B', 'Q', 'M', 'D', 'R', 'T', 'A', 'K', 'Z', 'G', 'F', 'U', 'H', 'O', 'S'
			]
	};
	bless $self, $class;

	$self->_init( $startLetter );

	return( $self );
};



package Crypt::Enigma::Rotors::RotorGamma;

@Crypt::Enigma::Rotors::RotorGamma::ISA = qw(Crypt::Enigma::Rotors);


sub new {
	my $class = shift;
	my $startLetter = shift;
	my $ringSetting = shift;

	my $self = {
		'_label'	=> 'RotorGamma',
		'_cycleLetterPosition' => (13 + $ringSetting) % 25,
		'_ringSetting' => $ringSetting,
		'_startLetter' => $startLetter,
		'_alphabet' => [
			'F', 'S', 'O', 'K', 'A', 'N', 'U', 'E', 'R', 'H', 'M', 'B', 'T', 'I', 'Y', 'C', 'W', 'L', 'Q', 'P', 'Z', 'X', 'V', 'G', 'J', 'D'
			]
	};
	bless $self, $class;

	$self->_init( $startLetter );

	return( $self );
};



1;


=pod

=head1 TITLE

Crypt::Enigma - Perl implementation of the Enigma cipher


=head1 DESCRIPTION

This module is a complete working Perl implementation of the Enigma Machine used during World War II. The cipher calculations are based on actual Enigma values and the resulting ciphered values are as would be expected from an Enigma Machine.

The implementation allows for all of the Rotors and Reflectors available to the real world Enigma to be used. A Steckerboard has also been implemented, allowing letter substitutions to be made.

The list of available rotors is as follows:

RotorI, RotorII, RotorIII, RotorIV, RotorV, RotorVI, RotorVII, RotorVIII, RotorBeta, RotorGamma.

The list of available reflectors is as follows:

ReflectorB, ReflectorBdunn, ReflectorC, ReflectorCdunn.

As with the real world Enigma, a minimum of 3 and a maximum of 5 rotors along with 1 reflector may be defined for each encryption/decryption.


=head1 SYNOPSIS

  use Crypt::Enigma;

  my $args = {
    rotors       => [ 'RotorI', 'RotorII', 'RotorIII' ],
    startletters => [ 'A', 'B', 'C' ],
    ringsettings => [ '0', '5', '10' ],
    reflector    => 'ReflectorB',
  };

  $enigma = Crypt::Enigma->new( $args );

  # Change rotor settings
  $enigma->setRotor( 'RotorVI', 'Z', '3', 1 );

  # Set the letter substitutions
  $enigma->setSteckerBoard( [ 'G', 'C' ] );

  # Encode the plaintext
  $cipher_text = $enigma->cipher( $plain_text );

  # Decode the ciphertext 
  $plain_text = $enigma->cipher( $cipher_text );


=head1 CLASS INTERFACE

=head2 CONSTRUCTORS

A C<Crypt::Enigma> object is created by calling the new constructor either with, or without arguments. If the constructor is called without arguments the defaults values will be used (unless these are set using the C<setRotor> method detailed below).

=over 4

=item new ( ARGS )

The arguments which can be used to create a C<Crypt::Enigma> instance are as follows:

  -rotors
  -startletters
  -ringsettings
  -stecker
  -reflector

The first four are to be passed in as references to arrays, while the last argument is a scalar.

=back

=head2 OBJECT METHODS

=over 4

=item cipher ( ARGS )

This method crypts and decrypts the supplied argument containing a string of text. Any characters which are not from the English alphabet (punctuation, numerics, etc) are ignored.

=item setRotor ( ARGS )

The C<setRotor> method is called to set a rotor of the Enigma to specific settings. The arguments to be passed in are as follows:

  -rotor name (eg. RotorI, RotorII, etc)
  -initial start letter (eg. 'A', 'B', etc)
  -ring setting (eg. '0', '1', etc)
  -rotor number (eg. '1', '2', etc)

If incorrect values are passed in, the default settings are used.

=item setReflector ( ARG )

The C<setReflector> method is called to set the reflector of the Enigma Machine. The argument to be passed in is a string containing the name of any of the available reflectors.

=item setSteckerBoard ( ARGS )

The Steckerboard is set by calling the C<setSteckerBoard> method and supplying a reference to an array as the first argument.

The array should contain a set of letter pairs, such as:

  [ 'A', 'B', 'C', 'D' ];

In this example, each instance of the letter 'A' will be replaced with the letter 'B' (and vice-versa) and each instance of the letter 'C' will be replaced with the letter 'D' (and vice-versa).

=item getRotorNames 

Returns an array containing the rotor names currently defined for encryption/decryption.

=item getStartLetters 

Returns an array containing the start letters currently defined for encryption/decryption.

=item getRingSettings 

Returns an array containing the ring settings currently defined for encryption/decryption.

=item getReflector 

Returns a string containing the name of the reflector currently defined for encryption/decryption.

=item dumpSettings

This method will print out (to STDERR) the current rotor settings.

=item setDebug ( ARG )

The C<setDebug> method is used to set the debug value of the C<Crypt::Enigma> object. The value of the argument can be either 1 (debug on) or 0 (debug off). The debug value is set to 0 by default.

=back

=head1 KNOWN BUGS

None, but that does not mean there are not any.

=head1 AUTHOR

Alistair Francis, <cpan@alizta.com>

=cut

#!/usr/bin/perl
#
# Authen::PluggableCaptcha::Challenge::DoMath
# Authen::PluggableCaptcha 
#
######################################################

use strict;

package Authen::PluggableCaptcha::Challenge::DoMath;

use vars qw(@ISA $VERSION);
$VERSION= '0.01';

use Authen::PluggableCaptcha::Challenge ();
our @ISA= qw( Authen::PluggableCaptcha::Challenge );

######################################################

use Digest::MD5 qw(md5_hex);
use Number::Spell;

######################################################

=pod

This is a type string captcha.

You have to type a string.  


Number::Spell
	Perl extension for spelling out numbers
	http://search.cpan.org/~lhoward/Number-Spell-0.04/Spell.pm

Lingua::EN::Numericalize
	Replaces English descriptions of numbers with numerals
	http://search.cpan.org/~ecalder/Lingua-EN-Numericalize-1.52/Numericalize.pm

Lingua::EN::WordsToNumbers
	convert numbers written in English to actual numbers
	http://search.cpan.org/~joey/Lingua-EN-Words2Nums-0.14/Words2Nums.pm	
	http://search.cpan.org/~emartin/Lingua-EN-WordsToNumbers-0.11/lib/Lingua/EN/WordsToNumbers.pm
	


=cut

##########################

our ( @_letters , @_digits , %_letters2digits , %_digits2letters );

BEGIN {

	# we need a mapping of letters to digits
	# it's done in a BEGIN block to only run 1x in a persistent environment
	@_letters= qw| a b c d e f g h i j k l m n o p q r s t u v w x y z |;
	@_digits= qw| 0 1 2 3 4 5 6 7 8 9 |;

	my 	$i;

	$i= 0;
	foreach my $char ( @_letters ) {
		$_letters2digits{ $char }= $_digits[ $i ];
		$i++;
	}
	$i= 0;
	foreach my $char ( @_digits ) {
		$_digits2letters{ $char }= $_letters[ $i ];
		$i++;
	}
	$i= undef;
}

##########################

sub new {
	my  ( $proto , %kw_args )= @_;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class );

		die "must supply 'keymanager_instance'" unless $kw_args{'keymanager_instance'};

		$self->_keymanager( $kw_args{'keymanager_instance'} );
		$self->_instructions("Please solve this math problem");

		$self->{'_internal_setup'}= {
			'response_type'=> {},
		};		

	# to make a math problem, we'll first make a hash off the publickey and site secret.
		my 	$working= md5_hex( 
				sprintf(
					"%s|%s" , 
						$self->keymanager->site_secret,
						$self->keymanager->publickey,
				)
			);

	# then we the hash into letters and numbers
		my 	( @letters , @digits );
		my 	@tmp= split // , $working;

		# if the last char of the md5 is a letter, we'll require a text (non numberc) response
		if ( $tmp[ -1 ] =~ /[a-zA-Z]/ ) {
			$self->{'_internal_setup'}{'response_type'}{'text'}= 1;
		}
		else {
			$self->{'_internal_setup'}{'response_type'}{'numeric'}= 1;
		}

		foreach my $char ( @tmp ) {
			if ( $char =~ /[a-zA-Z]/ ) {
				push @letters, $char;
			}
			elsif ( $char =~ /\d/ ) {
				push @digits, $char;
			}
		}
		
		# we want these to both be even:
		if ( $#letters < $#digits ) {
			my 	$i=0;
			while ( $#letters < $#digits ) {
				push @letters, $_digits2letters{ $digits[$i] };
				$i++;
			}
		}
		if ( $#digits < $#letters ) {
			my 	$i=0;
			while ( $#digits < $#letters ) {
				push @digits, $_letters2digits{ $letters[$i] };
				$i++;
			}
		}

		my 	( $int_1 , $int_2 )= ( $digits[0] , $digits[1] );
		my 	$operator= ( $digits[3] > 4 ) ? 'plus' : 'times' ;
		my 	$solution;
		if ( $operator eq 'plus' ) {
			$solution= $int_1 + $int_2 ;
		}
		elsif ( $operator eq 'times' ) {
			$solution= $int_1 * $int_2 ;
		}
		
		$self->_user_prompt( 
			sprintf( 
				'What is %s %s %s ? ' , 
					spell_number($int_1) , 
					$operator , 
					spell_number($int_2) 
			) 
		);

		if ( $self->{'_internal_setup'}{'response_type'}{'text'} ) {
		
			$self->_user_prompt( $self->user_prompt . '(in English as alphabetical characters)' );
			$self->_correct_response( spell_number($solution) );
		}
		else {
			$self->_user_prompt( $self->user_prompt . '(in digits)' );
			$self->_correct_response( $solution );
		}

	return $self;
}

sub validate {
	my 	( $self , %kw_args )= @_;
	
	if ( !defined $kw_args{'user_response'} ) {
		die "validate must be called with a 'user_response' argument";
	}
	if ( lc($kw_args{'user_response'}) eq lc($self->correct_response) ) {
		return 1;		
	}
	return 0;
}







###
1;
#!/usr/bin/perl
#
# Authen::PluggableCaptcha::KeyManager
#
######################################################

=head1 NAME

Authen::PluggableCaptcha::KeyManager

=head1 DESCRIPTION

This is the base class for managing captcha keys ( public facing captcha identifiers)

=head1 DESCRIPTION

This is the base class for managing captcha keys ( public facing captcha identifiers)

This class consolidates the routines previously  available in the KeyGenerator and KeyValidator classes

By default , this class always returns true on validate_publickey
There is no validation supported other than the timeliness provided by the key generation element.

This should be subclassed to provide for better implementations

This module supports the following functions:

	new
	validate_publickey
	generate_publickey
	expire_publickey


=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>

Returns a new L<Authen::PluggableCaptcha::KeyManager> ( or dervied ) object constructed according to PARAMS, where PARAMS are name/value pairs.

PARAMS are required name/value pairs.  Required PARAMS are:

=over 8

=item C<seed TYPE>

seed used for key management.  this could be a session id, a session id + url,  an empty string, or any other defined value.

=item C<site_secret TYPE>

site_secret used for key management.  this could be a shared value for your website.

=item C<time_expiry INT>

time_expiry - how many seconds is the captcha good for?

=item C<time_expiry_future INT>

time_expiry_future - how many seconds in the future can a captcha be valid for ( for use in clusters where clocks may not be in sync )

=item C<time_now INT>

time_now - current unix timestamp

=back

=back

=head1 OBJECT METHODS

=over 4

=item B<validate_publickey>

this is where you'd subclass and toss in functions that handles:
	
	is this key in the  right format ? ( regex )
	was this key ever used before? ( one time user )
	was this key accessed by more than one ip ?
	etc.

returns
	1 : valid
	0 : invalid
	-1 : error

=item B<expire_publickey>

handle expiring the key here.  this is a null function by default ( you shouldn't be able to expire a non-db backed key )

if this passed, we should do
	$self->EXPIRED(1);
	$self->INVALID(1);

so that the captcha won't be used again.

=item B<generate_publickey>

Returns a hash to be used for creating captchas.

By default,this hash is based on the time , seed , and site_secrect.

It is implemented as a seperate function to be replaced by subclasses

=item B<init_existing>
hoook called when initializing an existing captcha

	returns:
		1 on valid key
		0 on expired/invalid  key
		-1 on error (wrong format , missing args )

=back

=head1 DEBUGGING

Set the Following envelope variables for debugging

	$ENV{'Authen::PluggableCaptcha::KeyManager-DEBUG_FUNCTION_NAME'}

debug messages are sent to STDERR via the ErrorLoggingObject package



=cut




use strict;

package Authen::PluggableCaptcha::KeyManager;
use vars qw(@ISA $VERSION);
$VERSION= '0.01';


use Authen::PluggableCaptcha::ErrorLoggingObject ();
use Authen::PluggableCaptcha::Helpers ();
use Authen::PluggableCaptcha::StandardAttributesObject ();
use Authen::PluggableCaptcha::ValidityObject ();
our @ISA= qw( Authen::PluggableCaptcha::ErrorLoggingObject Authen::PluggableCaptcha::ValidityObject Authen::PluggableCaptcha::StandardAttributesObject );

######################################################

use Digest::MD5 qw ( md5_hex );

######################################################

use constant DEBUG_FUNCTION_NAME=> $ENV{'Authen::PluggableCaptcha::KeyManager-DEBUG_FUNCTION_NAME'} || 0;

######################################################

sub new {
	my  ( $proto , %kw_args )= @_;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class );

	# required elements
		my 	@_requires= qw( seed site_secret time_expiry time_expiry_future time_now );
		Authen::PluggableCaptcha::Helpers::check_requires( 
			kw_args__ref=> \%kw_args,
			error_message=> "Missing required element '%s' in KeyManager::New",
			requires_array__ref=> \@_requires
		);
		$self->seed( $kw_args{'seed'} );
		$self->site_secret( $kw_args{'site_secret'} );
		$self->time_expiry( $kw_args{'time_expiry'} );
		$self->time_expiry_future( $kw_args{'time_expiry_future'} );
		$self->time_now( $kw_args{'time_now'} );

	return $self;
}

sub validate_publickey {
	my 	( $self , %kw_args )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('validate_publickey');
	
	if ( defined $kw_args{'publickey'} ) {
		$self->publickey( $kw_args{'publickey'} );
	}
	
	if ( !$self->publickey ) {
		$self->INVALID(1);
		$self->ACCEPTABLE_ERROR(1);
		$self->set_error( 'validate_publickey','no publickey' );
		return -1;
	}
	
	#if we have an existing key, we need to perform a referential check
	
	# first check is on the format
	if 	( $self->publickey !~ m/[\w]{32}_[\d]{9,11}/ ) {
		#	key is not in the right format
		$self->INVALID(1);
		$self->ACCEPTABLE_ERROR(1);
		$self->set_error( 'validate_publickey','invalid key format' );
		return -1;
	}

	# if its in the format, then split the format into hash and time_start
	my 	( $hash , $time_start )= split '_' , $self->publickey;
	$self->{'_hash'}= $hash;
	$self->time_start( $time_start );

	# next check is on the timeliness
	if 	( 
			$self->time_now
			> 
			( $self->time_start + $self->time_expiry ) 
		) 
	{
		$self->EXPIRED(1);
		$self->ACCEPTABLE_ERROR(1);
		$self->set_error( 'validate_publickey','EXPIRED captcha time' );
		return 0;
	}

	# is the captcha too new?
	if 	( 
			$self->time_start
			> 
			( $self->time_now + $self->time_expiry_future ) 
		)
	{
		$self->INVALID(1);
		$self->set_error( 'validate_publickey','FUTURE captcha time' );
		return 0;
	}	

	return 1;
}



sub generate_publickey {
	my 	( $self )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('generate_publickey');

	$self->{'_hash'}= md5_hex(  
		sprintf( 
			"%s|%s|%s" , 
				$self->site_secret, 
				$self->time_now, 
				$self->seed 
		)  
	);

	#by default we just use a '_' join : KEY_TIMESTART
	$self->publickey( 
		join '_' , ( $self->{'_hash'} , $self->time_now ) 
	);
}



sub expire_publickey {
	my  ( $self , %kw_args )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('expire_publickey');
	return -1;
}


###
1;
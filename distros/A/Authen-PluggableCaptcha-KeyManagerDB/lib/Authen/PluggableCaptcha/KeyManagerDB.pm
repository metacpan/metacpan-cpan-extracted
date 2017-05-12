#############################################################################
# Authen::PluggableCaptcha::KeyManagerDB
# Pluggable Captcha system for perl
# Copyright(c) 2006-2007, Jonathan Vanasco (cpan@2xlp.com)
# Distribute under the Perl Artistic License
#
#############################################################################


=head1 NAME

Authen::PluggableCaptcha::KeyManagerDB - A sample DB backed KeyManger for L<Authen::PluggableCaptcha> that is compatible with L<Authen::PluggableCaptcha::KeyManager>

=head1 SYNOPSIS

This package is a sample database backed KeyManager for L<Authen::PluggableCaptcha>.  It uses Rose::DB::Object and Postgres.  It's more of a guide than an actual package, though it could be used in production.

=head1 DESCRIPTION

You should look at the DB connect info in L<Authen::PluggableCaptcha::KeyManagerDB::RoseDB> 

=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>
Returns a new L<Authen::PluggableCaptcha::KeyManager> object constructed according to PARAMS, where PARAMS are name/value pairs.

=back

=head1 OBJECT METHODS

The methods are functionally identical to L<Authen::PluggableCaptcha::KeyManager> 

Look at the source code to see how you might want to rewrite this.

=head1 DEBUG

use constant DEBUG_FUNCTION_NAME=> $ENV{'Authen::PluggableCaptcha::KeyManagerDB-DEBUG_FUNCTION_NAME'} || 0;
use constant DEBUG_SQL_ERROR=> $ENV{'Authen::PluggableCaptcha::KeyManagerDB-DEBUG_SQL_ERROR'} || 0;

=head1 AUTHOR

Jonathan Vanasco , cpan@2xlp.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Jonathan Vanasco

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package Authen::PluggableCaptcha::KeyManagerDB;

use strict;
use vars qw(@ISA $VERSION);
$VERSION= '0.02';

use Authen::PluggableCaptcha::KeyManager ();
use Authen::PluggableCaptcha::ErrorLoggingObject ();
use Authen::PluggableCaptcha::Helpers ();
use Authen::PluggableCaptcha::StandardAttributesObject ();
use Authen::PluggableCaptcha::ValidityObject ();
our @ISA= qw( 
	Authen::PluggableCaptcha::ErrorLoggingObject 
	Authen::PluggableCaptcha::ValidityObject 
	Authen::PluggableCaptcha::StandardAttributesObject 
	Authen::PluggableCaptcha::KeyManager
);

######################################################

use Digest::MD5 qw ( md5_hex );
use Time::HiRes ();

use Authen::PluggableCaptcha::KeyManagerDB::RoseDB;
use Authen::PluggableCaptcha::KeyManagerDB::RoseDB::Object;
use Authen::PluggableCaptcha::KeyManagerDB::RoseDB::Object::CaptchaKey;

######################################################

use constant DEBUG_FUNCTION_NAME=> $ENV{'Authen::PluggableCaptcha::KeyManagerDB-DEBUG_FUNCTION_NAME'} || 0;
use constant DEBUG_SQL_ERROR=> $ENV{'Authen::PluggableCaptcha::KeyManagerDB-DEBUG_SQL_ERROR'} || 0;

######################################################

sub new {
	my  ( $proto , %kw_args )= @_;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class );

	# required elements
		my 	@_requires= qw( seed site_secret time_expiry time_expiry_future time_now );
		Authen::PluggableCaptcha::Helpers::check_requires( 
			kw_args__ref=> \%kw_args,
			error_message=> "Missing required element '%s' in Authen::PluggableCaptcha::KeyManagerDB::New",
			requires_array__ref=> \@_requires
		);
		$self->seed( $kw_args{'seed'} );
		$self->site_secret( $kw_args{'site_secret'} );
		$self->time_expiry( $kw_args{'time_expiry'} );
		$self->time_expiry_future( $kw_args{'time_expiry_future'} );
		$self->time_now( $kw_args{'time_now'} );

		$self->db( $kw_args{'keymanager_args'}{'db'} );
		
		$self->{'_remote_ip'}= $kw_args{'keymanager_args'}{'remote_ip'} || undef;

	return $self;
}

sub db {
	my  ( $self , $db )= @_;
	if ( defined $db ) {
		$self->{'_db'}= $db;
	}
	return $self->{'_db'};
}



sub _db_key {
	# get/set the rose db object for the key
	my 	( $self , $db_key )= @_;
	if ( defined $db_key ) {
		$self->{'_db_key'}= $db_key;
	}
	return $self->{'_db_key'};
}




sub generate_publickey {
	my 	( $self )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('generate_publickey');

	my 	$publickey= $self->__generate_publickey();
	if ( $publickey == -1 ) {
		die "crap";
	}
	
	my 	$db_key= Authen::PluggableCaptcha::KeyManagerDB::RoseDB::Object::CaptchaKey->new(
		hex_id=> $publickey,
		is_valid=> 1,
		timestamp_created=> 'NOW()',
		ip_created=> $self->{'_remote_ip'},
	);
		if ( my $override_db= $self->db ) {
			$db_key->db( $override_db );
		}
		$db_key->save or die "could not save!";
	
	$self->_db_key( $db_key );
	$self->publickey( $publickey );
	return 1;
}

sub __generate_publickey {
	my 	( $self )= @_ ;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('__generate_publickey');

	my 	$hex_id;
	while ( !$hex_id ) {
		my 	$attempt= 	md5_hex(  
							sprintf( 
								"%s|%s|%s" , 
									$self->site_secret, 
									Time::HiRes::time(), 
									$self->seed 
							)
						);
		eval {
			my 	$db_key= Authen::PluggableCaptcha::KeyManagerDB::RoseDB::Object::CaptchaKey->new( 
				hex_id=> $attempt ,
				is_valid=> 1
			);
			if ( my $override_db= $self->db ) {
				$db_key->db( $override_db );
			}
			if ( !$db_key->load(speculative=> 1) ) {
				$hex_id= $attempt;
			}
		};
		if ( $@ ) {
			DEBUG_SQL_ERROR && Authen::PluggableCaptcha::ErrorLoggingObject::log_die( "$@" );
			$hex_id= "ERROR";
		}
	}
	if ( $hex_id eq 'ERROR' ){
		return -1;
	}
	return $hex_id;
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
	if 	( $self->publickey !~ m/[\w]{32}/ ) {
		#	key is not in the right format
		$self->INVALID(1);
		$self->ACCEPTABLE_ERROR(1);
		$self->set_error( 'validate_publickey','invalid key format' );
		return -1;
	}

	# if its in the format, then check the db
	my 	$db_key;
	my 	$ok_die;
	eval {
		$db_key= Authen::PluggableCaptcha::KeyManagerDB::RoseDB::Object::CaptchaKey->new( 
			hex_id=> $self->publickey ,
			is_valid=> 1
		);
		if ( my $override_db= $self->db ) {
			$db_key->db( $override_db );
		}
		if ( !$db_key->load(speculative=> 1) ) {
			$self->EXPIRED(1);
			$self->ACCEPTABLE_ERROR(1);
			$self->set_error( 'validate_publickey','Invalid Key' );
			$ok_die=1;
			die "ok";
		}
		
	};
	if ( $@ ) {
		if ( $ok_die ) 
		{
			$self->INVALID(1);
			$self->ACCEPTABLE_ERROR(1);
			$self->set_error( 'validate_publickey','not found' );
			return 0;
		}
	
		DEBUG_SQL_ERROR && Authen::PluggableCaptcha::ErrorLoggingObject::log_die( "$@" );
		$self->INVALID(1);
		$self->ACCEPTABLE_ERROR(0);
		$self->set_error( 'validate_publickey','DB error' );
		return -1;
	}

	$self->_db_key( $db_key );

	return 1;
}


sub expire_publickey {
	my  ( $self , %kw_args )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('expire_publickey');
	
	my 	$db_key= $self->_db_key or die "no db key in place";
	eval {
		$db_key->is_valid(0);
		$db_key->timestamp_used('NOW()');
		$db_key->ip_used($self->{'_remote_ip'});
		$db_key->save;
	};
	if ( $@ ) {
		die "$@";
	}
	
	$self->EXPIRED(1);
	$self->ACCEPTABLE_ERROR(1);
	
	return 1;
}

###
1;
#!/usr/bin/perl
#
#############################################################################
# Authen::PluggableCaptcha
# Pluggable Captcha system for perl
# Copyright(c) 2006-2007, Jonathan Vanasco (cpan@2xlp.com)
# Distribute under the Perl Artistic License
#
#############################################################################

=head1 NAME

Authen::PluggableCaptcha - A pluggable Captcha framework for Perl

=head1 SYNOPSIS

IMPORTANT-- the .03 release is incompatible with earlier versions.  
Most notably: all external hooks for hash mangling have been replaced with object methods ( ie: $obj->{'__Challenge'} is now $obj->challenge  ) and keyword arguments expecting a class name have the word '_class' as a suffix.

Authen::PluggableCaptcha is a framework for creating Captchas , based on the idea of creating Captchas with a plugin architecture. 

The power of this module is that it creates Captchas in the sense that a programmer writes Perl modules-- not just in the sense that a programmer calls a Captcha library for display.

The essence of a Captcha has been broken down into three components: KeyManager , Challenge and Render -- all of which programmers now have full control over.  Mix and match existing classes or create your own.  Authen::PluggableCaptcha helps you make your own captcha tests -- and it helps you do it fast.   

The KeyManager component handles creating & validatiing keys that are later used to uniquely identify a CAPTCHA.  By default the KeyManager uses a time-based key system, but it can be trivially extended to integrate with a database and make single-use keys.

The Challenge component maps a key to a set of instructions, a user prompt , and a correct response. 

The render component is used to display the challenge - be it text, image or sound.


  use Authen::PluggableCaptcha;
  use Authen::PluggableCaptcha::Challenge::TypeString;
  use Authen::PluggableCaptcha::Render::Image::Imager;

  # create a new captcha for your form
  my $captcha= Authen::PluggableCaptcha->new( 
    type=> "new", 
    seed=> $session->user->seed , 
    site_secret=> $MyApp::Config::site_secret 
  );
  my $captcha_publickey= $captcha->get_publickey();
  
  # image captcha?  create an html link to your captcha script with the public key
  my $html= qq|<img src="/path/to/captcha.pl?captcha_publickey=${captcha_publickey}"/>|;
  
  # image captcha?  render it
  my $existing_publickey= 'a33d8ce53691848ee1096061dfdd4639_1149624525';
  my $existing_publickey = $apr->param('captcha_publickey');
  my $captcha= Authen::PluggableCaptcha->new( 
    type=> 'existing' , 
    publickey=> $existing_publickey , 
    seed=> $session->user->seed , 
    site_secret=> $MyApp::Config::site_secret 
  );

  # save it as a file
  my $as_string= $captcha->render( 
    challenge_class=> 'Authen::PluggableCaptcha::Challenge::TypeString', 
    render_class=>'Authen::PluggableCaptcha::Render::Image::Imager' ,  
    format=>'jpeg' 
  );
  open(WRITE, ">test.jpg");
  print WRITE $as_string;
  close(WRITE);

  # or serve it yourself
  $r->add_header('Content Type: image/jpeg');
  $r->print( $as_string );
  
  # wait, what if we want to validate the captcha first?
  my $captcha= Authen::PluggableCaptcha->new( 
    type=> 'existing' , 
    publickey=> $apr->param('captcha_publickey'), 
    seed=> $session->user->seed , 
    site_secret= $MyApp::Config::site_secret 
  );
  if ( !$captcha->validate_response( user_response=> $apr->param('captcha_response') ) ) {
	  my $reason= $captcha->get_error('validate_response');
	  die "could not validate captcha because: ${reason}.";
  };

in the above example, $captcha->new just configures the captcha.  $captcha->render actually renders the image.
if the captcha is expired (too old by the default configuration) , the default expired captcha  routine from the plugin will take place
better yet, handle all the timely and ip/request validation in the application logic.  the timeliness just makes someone answer a captcha 1x every 5minutes, but doesn't prevent re/mis use

render accepts a 'render_class' argument that will internally dispatch the routines to a new instance of that class.  

using this method, multiple renderings and formats can be created using a single key and challenge.

=head1 DESCRIPTION

Authen::PluggableCaptcha is a fully modularized and extensible system for making Pluggable Catpcha (Completely Automated Public Turing Test to Tell Computers and Humans Apart) tests.

Pluggable?  All Captcha objects are instantiated and interfaced via the main module, and then manipulated to require various submodules as plug-ins.

Authen::PluggableCaptcha borrows from the functionality in Apache::Session::Flex

=head2 The Base Modules:

=head3 KeyManager

  Consolidates functionality previously found in KeyGenerator and KeyValidator

  Generates , parses and validates publickeys which are used to validate and create captchas
  Default is Authen::PluggableCaptcha::KeyManager , which makes a key %md5%_%time% and performs no additional checking

  A subclass is highly recommended.
  Subclasses can contain a regex or a bunch of DB interaction stuff to ensure a key is used only one time per ip address


=head3 Challenge

  simply put, a challenge is a test.  
  challenges internally require a ref to a KeyManager instance , it then maps that instance via it's own facilities into a test to render or validate
  a challege generates 3 bits of text: 
	instructions
	user_prompt
	correct_response

  a visual captcha would have user_prompt and correct_response as the same.  
  a text logic puzzle would not.

=head3 Render

  the rendering of a captcha for presentation to a user.
  This could be an image, sound, block of (obfuscated?) html or just plain text

=head1 Reasoning (reinventing the wheel)

Current CPAN captcha modules all exhibit one or more of the following traits:

=over

=item -
the module is tied heavily into a given image rendering library

=item -
the module only supports a single style of an image Catpcha

=item -
the module renders/saves the image to disk

=back

I wanted a module that works in a clustered environment, could be easily extended / implemented with the following design requirements:

=over

=item 1
challenges are presented by a public_key

=item 2
a seed (sessionID ?) + a server key (siteSecret) hash together to create a public key

=item 3
the public_key is handled by its own module which can be subclassed and replaced as long as it provides the required methods

=back

with this method, generating a public key 'your own way' is very easy, so the module integrates easily into your app

furthermore:

=over

=item *
the public_key creates a captcha test / challenge ( instructions , user_prompt , correct_repsonse ) for presentation or validation

=over

=item -
the captcha test is handled by its own module which can be subclassed as long as it provides the required methods

=item -
    want to upgrade a test? its right there

=item -
    want a private test?  create a new subclass

=item -
    want to add tests to cpan?  please do!

=back

=item *
the rendering is then handled by its own module which can be subclassed as long as it provides the required methods

=item *
the rendering doesn't just render a jpg for a visual captcha... the captcha challenge can then be rendered in any format

=over

=item -
image

=item -
audio

=item -
text

=back

=back

any single component can be extended or replaced - that means you can cheaply/easily/quickly create new captchas as older ones get defeated. instead of going crazy trying to make the worlds best captcha, you can just make a ton of crappy ones that are faster to make than to break :)

everything is standardized and made for modular interaction
since the public_key maps to a captcha test, the same key can create an image/audio/text captcha, 

Note that Render::Image is never called - it is just a base class.
The module ships with Render::Img::Imager, which uses the Imager library.  Its admittedly not very good- it is simple a proof-of-concept.

want gd/imagemagick?  write Render::Img::GD or Render::Image::ImageMagick with the appropriate hooks (and submit to CPAN!)

This functionality exists so that you don't need to run GD on your box if you've got a mod_perl setup that aready uses Imager.

Using any of the image libraries should be a snap- just write a render class that can create an image with 'user_prompt' text, and returns 'as_string'
Using any of the audio libraries will work in the same manner too.

Initial support includes the ability to have Textual logic Catptchas.  They do silly things like say "What is one plus one ? (as text in english)" 
HTML::Email::Obfuscate makes these hard to scrape, though a better solution is needed and welcome.

One of the main points of PluggableCaptcha is that even if you create a Captcha that is one step ahead of spammers ( read: assholes ) , they're not giving up -- they're just going to take longer to break the Captcha-- and once they do, you're sweating trying to protect yourself again.  

With PluggableCaptcha, it should be easier to :

=over

=item a-
create new captchas cheaply: make a new logic puzzle , a new way of rendering images , or change the random character builder into something that creates strings that look like words, so people can spell them easier.

=item b-
customize existing captchas: subclass captchas from the distribution , or others people submit to CPAN. create some site specific changes on the way fonts are rendered, etc.

=item c-
constantly change captchas ON THE FLY.  mix and match render and challenge classes.  the only thing that would take much work is swapping from a text to an image.  but 1 line of code controls what is in the image, or how to solve it!

=back

Under this system, ideally, people can change / adapt / update so fast , that spammers never get a break in their efforts to break captcha schemes!


=head1 CONSTRUCTOR

=over 4

=item B<new PARAMS>
Returns a new L<Authen::PluggableCaptcha> object constructed according to PARAMS, where PARAMS are name/value pairs.

PARAMS are name/value pairs.  

Required PARAMS are:

=over 8

=item C<type TYPE>

Type of captcha. Valid options are 'new' or 'existing'

=item C<seed TYPE>

seed used for key management.  this could be a session id, a session id + url,  an empty string, or any other defined value.

=item C<site_secret TYPE>

site_secret used for key management.  this could be a shared value for your website.

=back

Optional PARAMS are:

=over 8

=item C<keymanager_args TYPE>

The value for the keymanager_args key will be sent to the KeyManager on instantiation as 'keymanager_args'

This is useful if you need to specify a DB connection or something similar to the keymanager

=item C<do_not_validate_key INT>

This is valid only for 'existing' type captchas.  

passing this argument as the integer '1'(1) will not validate the publickey in the keymanager.

This is useful if you are externally handling the key management, and just use this package for Render + Challenge


=back

=head1 OBJECT METHODS

=over 4

=item B<captcha_type TYPE>

get the captcha type

=item B<keymanager>

returns an instance of the active keymanager

=item B<challenge_instance TYPE>

returns an instance of a challenge class TYPE

=item B<render_instance TYPE>

returns an instance of a render class TYPE

=item B<die_if_invalid>

calls a die if the captcha is invalid

=item B<get_publickey>

returns a publickey from the keymanager.

=item B<expire_publickey>

instructs the keymanager to expire the publickey. on success returns 1 and sets the captcha as invalid and expired.  returns 0 on failure and -1 on error.

=item B<validate_response>

Validates a user response against the key/time for this captcha

returns 1 on sucess, 0 on failure, -1 on error.

=item B<render PARAMS>

renders the captcha based on the kw_args submitted in PARAMS

returns the rendered captcha as a string

PARAMS are required name/value pairs.  Required PARAMS are:

=over 8

=item C<challenge_class TYPE>
Full name of a Authen::PluggableCaptcha::Challenge derived class

=item C<render_class TYPE>
Full name of a Authen::PluggableCaptcha::Render derived class

=back

=back

=head1 DEBUGGING

Set the Following envelope variables for debugging

	$ENV{'Authen::PluggableCaptcha-DEBUG_FUNCTION_NAME'}
	$ENV{'Authen::PluggableCaptcha-BENCH_RENDER'}

debug messages are sent to STDERR via the ErrorLoggingObject package



=head1 BUGS/TODO

This is an initial alpha release.  

There are a host of issues with it.  Most are discussed here:

To Do:

	priority | task
	+++| clean up how stuff is stored / passed around / accessing defaults.  there's a lot of messy stuff with in regards to passing around default values and redundancy of vars
	+++| create a better way to make attributes shared stored and accessed
	++ | Imager does not have facilities right now to do a 'sine warp' easily.  figure some sort of text warping for the imager module.
	++ | Port the rendering portions of cpan gd/imagemagick captchas to Img::(GD|ImageMagick)
	++ | Img::Imager make the default font more of a default
	++ | Img::Imager add in support to render each letter seperately w/a different font/size
	+  | Img::Imager better handle as_string/save + support for png format etc
	-  | is there a way to make the default font more cross platform?
	-- | add a sound plugin ( text-logic might render that a trivial enhancement depending on how obfuscation treats display )


=head1 STYLE GUIDE

If you make your own subclasses or patches, please keep this information in mind:


	The '.' and '..' prefixes are reserved namespaces ( ie: $self->{'.Attributes'} , $self->{'..Errors'} )
	
	Generally: '.' prefixes a shared or inherited trait ; '..' prefixes an class private variable
	
	If you see a function with _ in the code, its undocumented and unsupported.  Only write code against regular looking functions.  Never write code against _ or __ functions.  Never.
	
=head1 REFERENCES

Many ideas , most notably the approach to creating layered images, came from PyCaptcha , http://svn.navi.cx/misc/trunk/pycaptcha/

=head1 AUTHOR

Jonathan Vanasco , cpan@2xlp.com

Patches, support, features, additional etc

	Kjetil Kjernsmo, kjetilk@cpan.org


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jonathan Vanasco

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#############################################################################
#head

package Authen::PluggableCaptcha;

use strict;
use vars qw(@ISA $VERSION);
$VERSION= '0.05';

#############################################################################
#ISA modules

use Authen::PluggableCaptcha::ErrorLoggingObject ();
use Authen::PluggableCaptcha::Helpers ();
use Authen::PluggableCaptcha::StandardAttributesObject ();
use Authen::PluggableCaptcha::ValidityObject ();
@ISA= qw( Authen::PluggableCaptcha::ErrorLoggingObject Authen::PluggableCaptcha::StandardAttributesObject Authen::PluggableCaptcha::ValidityObject );

#############################################################################
#use constants

use constant DEBUG_FUNCTION_NAME=> $ENV{'Authen::PluggableCaptcha-DEBUG_FUNCTION_NAME'} || 0;
use constant DEBUG_VALIDATION=> $ENV{'Authen::PluggableCaptcha-DEBUG_VALIDATION'} || 0;
use constant BENCH_RENDER=> $ENV{'Authen::PluggableCaptcha-BENCH_RENDER'} || 0;

#############################################################################
#use modules

use Authen::PluggableCaptcha::KeyManager ();
use Authen::PluggableCaptcha::Render ();

#############################################################################
#defined variables

our %_DEFAULTS= (
	time_expiry=> 300,
	time_expiry_future=> 30,
);

our %__types= (
	'existing'=> 1,
	'new'=> 1
);


#############################################################################
#begin
BEGIN {
	if ( BENCH_RENDER ) {
		use Time::HiRes();
	}
};

#############################################################################
#subs

# constructor
sub new {
	my  ( $proto , %kw_args )= @_;
	my  $class= ref($proto) || $proto;
	my  $self= bless ( {} , $class );

	# make sure we have the requisite kw_args
	my 	@_requires= qw( type seed site_secret );
	Authen::PluggableCaptcha::Helpers::check_requires( 
		kw_args__ref=> \%kw_args,
		error_message=> "Missing required element '%s' in new",
		requires_array__ref=> \@_requires
	);

	if ( !$__types{$kw_args{'type'}} ) {
		die "invalid type";
	}

	$self->_captcha_type( $kw_args{'type'} );

	Authen::PluggableCaptcha::ErrorLoggingObject::_init( $self ); #re- ErrorLoggingObject 

	$self->seed( $kw_args{'seed'} );
	$self->site_secret( $kw_args{'site_secret'} );
	$self->time_expiry( $kw_args{'time_expiry'} || $Authen::PluggableCaptcha::_DEFAULTS{'time_expiry'} );
	$self->time_expiry_future( $kw_args{'time_expiry_future'} || $Authen::PluggableCaptcha::_DEFAULTS{'time_expiry_future'} );
	$self->time_now( time() );

	my 	$keymanager_class= $kw_args{'keymanager_class'} || 'Authen::PluggableCaptcha::KeyManager';

	unless ( $keymanager_class->can('generate_publickey') ) {
		eval "require $keymanager_class" || die $@ ;
	}
	unless ( $keymanager_class->can('validate_publickey') ) {
		die "keymanager_class can not validate_publickey" ;
	}
	
	$self->__keymanager_class( $keymanager_class );

	my 	$keymanager= $self->__keymanager_class->new(
		seed=> $self->seed ,
		site_secret=> $self->site_secret ,
		time_expiry=> $self->time_expiry ,
		time_expiry_future=> $self->time_expiry_future ,
		time_now=> $self->time_now ,
		keymanager_args=> $kw_args{'keymanager_args'}
	);
	$self->_keymanager( $keymanager );

	if ( $kw_args{'type'} eq 'existing' ) {
		$self->__init_existing( \%kw_args );
	}
	else {
		$self->__init_new( \%kw_args );
	}
	return $self;
}

sub captcha_type {
	my 	( $self )= @_;
	return $self->{'.captcha_type'};
}
sub _captcha_type {
	my 	( $self , $set_val )= @_;
	if 	( !defined $set_val ) {
		die "no captcha_type specified"
	}
	$self->{'.captcha_type'}= $set_val;
	return $self->{'.captcha_type'};
}


sub __init_existing {
=pod
existing captcha specific inits
=cut
	my 	( $self , $kw_args__ref )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('__init_existing');
	if ( ! defined $$kw_args__ref{'publickey'} || ! $$kw_args__ref{'publickey'} ) {
		die "'publickey' must be supplied during init";
	}
	$self->publickey( $$kw_args__ref{'publickey'} );

	if 	(
			defined $$kw_args__ref{'do_not_validate_key'} 
			&& 
			( $$kw_args__ref{'do_not_validate_key'} == 1 )
		)
	{
		$self->keymanager->publickey( $$kw_args__ref{'publickey'} );
		return 1;
	}

	my 	$validate_result= $self->keymanager->validate_publickey( publickey=> $$kw_args__ref{'publickey'} );
	DEBUG_VALIDATION && print STDERR "\n validate_result -> $validate_result ";

	if ( $validate_result < 0 ) {
		$self->keymanager->ACCEPTABLE_ERROR or die "Could not init_existing on keymanager";
	}
	elsif ( $validate_result == 0 ) {
		$self->keymanager->ACCEPTABLE_ERROR or die "Could not init_existing on keymanager";
	}
	if ( $self->keymanager->EXPIRED ) {
		$self->EXPIRED(1);
		return 0;
	}
	if ( $self->keymanager->INVALID ) {
		$self->INVALID(1);
		return 0;
	}
	return 1;
}


sub __init_new {
=pod
new captcha specific inits
=cut
	my 	( $self , $kw_args__ref )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('__init_new');

	$self->keymanager->generate_publickey() or die "Could not generate_publickey on keymanager";
	return 1;
}


sub __keymanager_class {
	my 	( $self , $class )= @_;
	if ( defined $class ){
		$self->{'..keymanager_class'}= $class;
	}
	return $self->{'..keymanager_class'};
}

sub _keymanager {
	my 	( $self , $instance )= @_;
	die "no keymanager instance" unless $instance;
	$self->{'..keymanager_instance'}= $instance;
	return $self->{'..keymanager_instance'};
}
sub keymanager {
	my 	( $self )= @_;
	return $self->{'..keymanager_instance'};
}



sub render_instance {
	my 	( $self , $render_instance_class )= @_;
	die unless $render_instance_class ;
	return $self->{'..render_instance'}{ $render_instance_class };
}
sub challenge_instance {
	my 	( $self , $challenge_instance_class , $challenge_instance_object )= @_;
	die unless $challenge_instance_class ;
	return $self->{'..challenge_instance'}{ $challenge_instance_class };
}

sub _render_instance {
	my 	( $self , $render_instance_class , $render_instance_object )= @_;
	die unless $render_instance_class ;
	die "no render_instance_object supplied" unless $render_instance_object;
	$self->{'..render_instance'}{ $render_instance_class }= $render_instance_object;
	return $self->{'..render_instance'}{ $render_instance_class };
}

sub _challenge_instance {
	my 	( $self , $challenge_instance_class , $challenge_instance_object )= @_;
	die unless $challenge_instance_class ;
	die "no challenge_instance_object supplied" unless $challenge_instance_object;
	$self->{'..challenge_instance'}{ $challenge_instance_class }= $challenge_instance_object;
	return $self->{'..challenge_instance'}{ $challenge_instance_class };
}


sub die_if_invalid {
	my 	( $self , %kw_args )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('die_if_invalid');

	if ( $self->INVALID ) {
		die "Authen::PluggableCaptcha Invalid , can not '$kw_args{from_function}'";
	}
}

sub get_publickey {
=pod
Generates a key that can be used to ( generate a captcha ) or ( validate a captcha )
=cut
	my 	( $self )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('generate_publickey');

	# die if the captcha is invalid
	$self->die_if_invalid( from_function=> 'generate_publickey' );

	return $self->keymanager->publickey;
}


sub expire_publickey {
=pod
Expires a publickey
=cut
	my 	( $self , %kw_args )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('validate_response');

	my 	$result= $self->keymanager->expire_publickey ;
	if 	( $result == 1 )
	{
		$self->EXPIRED(1);
		$self->INVALID(1);
	}
	return $result;
}


sub validate_response {
=pod
Validates a user response against the key/time for this captcha
=cut
	my 	( $self , %kw_args )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('validate_response');

	# die if the captcha is invalid
	$self->die_if_invalid( from_function=> 'validate_response' );
	if ( $self->EXPIRED ) {
		$self->set_error( 'validate_response' , 'KEY expired' );
		return 0;
	}

	# make sure we instantiated as an existing captcha
	if ( $self->captcha_type ne 'existing' ) {
		die "only 'existing' type can validate";
	}

	# make sure we have the requisite kw_args
	my 	@_requires= qw( challenge_class user_response );
	Authen::PluggableCaptcha::Helpers::check_requires( 
		kw_args__ref=> \%kw_args,
		error_message=> "Missing required element '%s' in validate",
		requires_array__ref=> \@_requires
	);

	# then actually validate the captcha

	# generate a challenge if necessary
	$self->_generate_challenge( challenge_class=>$kw_args{'challenge_class'} );
	my 	$challenge_class= $kw_args{'challenge_class'};
	my 	$challenge= $self->challenge_instance( $challenge_class );

	# validate the actual challenge
	if ( !$challenge->validate( user_response=> $kw_args{'user_response'} ) ) {
		$self->set_error('validate_response',"INVALID user_response");
		return 0;
	}

	return 1;
}

sub _generate_challenge {
	my 	( $self , %kw_args )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('_generate_challenge');

	# make sure we instantiated as an existing captcha
	if ( $self->captcha_type ne 'existing' ) {
		die "only 'existing' type can _generate_challenge";
	}

	# make sure we have the requisite kw_args
	my 	@_requires= qw( challenge_class );
	Authen::PluggableCaptcha::Helpers::check_requires( 
		kw_args__ref=> \%kw_args,
		error_message=> "Missing required element '%s' in _generate_challenge",
		requires_array__ref=> \@_requires
	);

	my 	$challenge_class= $kw_args{'challenge_class'};
	unless ( $challenge_class->can('generate_challenge') ) {
		eval "require $challenge_class" || die $@ ;
	}

	# if we haven't created a challege for this output already, do so
	if ( !$self->challenge_instance( $challenge_class ) ){
		$self->__generate_challenge__actual( \%kw_args );
	}
}


sub __generate_challenge__actual {
=pod
	actually generates the challenge for an item and caches internally
=cut
	my 	( $self , $kw_args__ref )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('__generate_challenge__actual');
	if ( !$$kw_args__ref{'challenge_class'} ) {
		die "missing challenge_class in __generate_challenge__actual";
	}

	my 	$challenge_class= $$kw_args__ref{'challenge_class'};
	delete  $$kw_args__ref{'challenge_class'};
	
	$$kw_args__ref{'keymanager_instance'}= $self->keymanager || die "No keymanager";

	my 	$challenge= $challenge_class->new( %{$kw_args__ref} );
	$self->_challenge_instance( $challenge_class , $challenge );
}

sub render {
	my 	( $self , %kw_args )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('render');

	# die if the captcha is invalid
	$self->die_if_invalid( from_function=> 'render' );

	# make sure we instantiated as an existing captcha
	if ( $self->captcha_type ne 'existing' ) {
		die "only 'existing' type can render";
	}

	# make sure we have the requisite kw_args
	my 	@_requires= qw( render_class challenge_class );
	Authen::PluggableCaptcha::Helpers::check_requires( 
		kw_args__ref=> \%kw_args,
		error_message=> "Missing required element '%s' in render",
		requires_array__ref=> \@_requires
	);


	my 	$render_class= $kw_args{'render_class'};
	unless ( $render_class->can('render') ) {
		eval "require $render_class" || die $@ ;
	}

	# if we haven't rendered for this output already, do so
	if ( !$self->render_instance( $render_class ) )
	{

		# grab a ref to the challenge
		# and supply the necessary refs

		$self->_generate_challenge( challenge_class=>$kw_args{'challenge_class'} );
		my 	$challenge_class= $kw_args{'challenge_class'};
		$kw_args{'challenge_instance'}= $self->challenge_instance( $challenge_class );
		$kw_args{'keymanager'}= $self->keymanager;
		$self->__render_actual( \%kw_args );
	}
	return $self->render_instance( $render_class )->as_string();
}


sub __render_actual {
=pod
	actually renders an item and caches internally
=cut
	my 	( $self , $kw_args__ref )= @_;
	DEBUG_FUNCTION_NAME && Authen::PluggableCaptcha::ErrorLoggingObject::log_function_name('__render_actual');

	# make sure we have the requisite kw_args
	my 	@_requires= qw( render_class challenge_class );
	Authen::PluggableCaptcha::Helpers::check_requires( 
		kw_args__ref=> $kw_args__ref,
		error_message=> "Missing required element '%s' in __render_actual",
		requires_array__ref=> \@_requires
	);

	my 	$render_class= $$kw_args__ref{'render_class'};
	delete  $$kw_args__ref{'render_class'};

	BENCH_RENDER && { $self->{'time_to_render'}= Time::HiRes::time() };
	my 	$render_object= $render_class->new( %{$kw_args__ref} );
	if ( $self->EXPIRED ){
		$render_object->init_expired( $kw_args__ref );
	}
	else {
		$render_object->init_valid( $kw_args__ref );
	}
	$render_object->render();
	$self->_render_instance( $render_class , $render_object );
	BENCH_RENDER && { $self->{'time_to_render'}= Time::HiRes::time()- $self->{'time_to_render'} };
}



#############################################################################
1;

=head1 NAME

Authen::PluggableCaptcha::Tutorial - How to use the Captcha System

=head1 Introduction

=head1 Conventions

=head1 TUTORIAL

=head2 Illustrated Steps

=head3 Generate a New Key...

	my 	$captcha= Authen::PluggableCaptcha->new( 
		type=>'new' , 
		seed=> 'a' , 
		site_secret=> 'z' 
	);
	my 	$captcha_publickey= $captcha->get_publickey();

=head3 Generate a JPEG...

	my	$captcha= Authen::PluggableCaptcha->new( 
		type=> 'existing' , 
		publickey=> $captcha_publickey, 
		seed=> 'a' , 
		site_secret=> 'z' 
	);

	my $as_string= $captcha->render( 
		challenge_class=> 'Authen::PluggableCaptcha::Challenge::TypeString', 
		render_class=>'Authen::PluggableCaptcha::Render::Image::Imager' ,  
		font_filename=> '/usr/X11R6/lib/X11/fonts/TTF/VeraMoIt.ttf',
		format=>'jpeg' 
	);
	
	# serve it directly, or write it
		open(WRITE, ">/path/to/dest.jpg");
		print WRITE $as_string;
		close(WRITE);

=head3 Generate an obfuscated HTML item...

again, create a new object

	my	$captcha= Authen::PluggableCaptcha->new( 
			type=> 'existing' , 
			publickey=> $captcha_publickey, 
			seed=> 'a' , 
			site_secret=> 'z' 
		);

render it

	my 	$as_string= $captcha->render( 
			challenge_class=> 'Authen::PluggableCaptcha::Challenge::DoMath', 
			render_class=>'Authen::PluggableCaptcha::Render::Text::HTML' 
		);

now you can serve it directly, or write it-- its just html text.  

note: if you put it into Tal or some other formats, it must be marked as a 'structure'

alternately, you could render with Authen::PluggableCaptcha::Render::Text::Plain, which does no obfuscation (bad! bad! bad!)

	open(WRITE, ">/path/to/dest.html");
	print WRITE $as_string;
	close(WRITE);

=head3 test an existing captcha for validation

create an object

	my 	$captcha= Authen::PluggableCaptcha->new( 
		type=> 'existing' , 
		publickey=> $captcha_publickey, 
		seed=> 'a' , 
		site_secret=> 'z' 
	);

run the validation 1x through, just so we get the vars set up and can pull the correct_response for the success

	my 	$i_doubt_this_will_work= $captcha->validate_response( 
			challenge_class=> 'Authen::PluggableCaptcha::Challenge::TypeString' , 
			user_response=>'a' 
		) ? "yes" : "no" ;

then we can toss in the correct response

	my 	$success= $captcha->validate_response( 
			challenge_class=> 'Authen::PluggableCaptcha::Challenge::TypeString' , 
			user_response=>$captcha->challenge_object->('Authen::PluggableCaptcha::Challenge::TypeString')->correct_response
		) ? "yes" : "no" ;

=head2 A real-world implementation

Originally Authen::PluggableCaptcha was designed for use in mod_perl under a clustered environment

This is how it is currently implemented on FindMeOn.com and RoadSound.com ( June 2006 ) 

=head3 Create a general Captcha init function in a webapp utility library

	sub CAPTCHA_init {
		my 	( $pageObject , $sectionName , $overrideFlag )= @_;
	
		# pageObject- context object that includes access to session , account, and libapreq
		# sectionName- the name of the what is requesting a captcha.  ie, your registration page would want to say 'registration', or a general auth page would say 'auth'
		#	this is used to create a seed, so the user doesn't get an identical captcha on each page
		# overrideFlag- bool value to force a re-init of the captcha
	
		if ( $pageObject->{'CaptchaInstance'} && !$overrideFlag ) {
			return;
		}
	
		# the seed for the captcha is a hash of the sectionName and the user's session_id
		my 	$seed= md5_hex( $sectionName . '|' . $pageObject->{'PageUser'}->get_session_id() );
		
		# we set/store the publickey to the captcha in the session.  we could show it to people, but honestly we do it like this because store/retrieve is easier than generating/validating every damn time
		my 	$captcha_key= $pageObject->{'PageUser'}->get_session_stored("captcha_publickey__${sectionName}");
	
		my 	$captcha;
		if 	( $captcha_key ) {
			$captcha= Authen::PluggableCaptcha->new( 
				type=> 'existing' , 
				site_secret=> $FindMeOn::Config::site_secret , 
				seed=> $seed ,
				publickey=> $captcha_key,
			);
			if ( $captcha->is_invalid() ) {
				$captcha_key= undef;
				$pageObject->{'_CaptchaInvalid'}= 1;
			} 
			if ( $captcha->is_expired() ) {
				$pageObject->{'_CaptchaExpired'}= 1;
				$captcha_key= undef;
			} 
		}
	
		if 	( !$captcha_key ) {
			$captcha= Authen::PluggableCaptcha->new( 
				type=> 'new' , 
				site_secret=> $FindMeOn::Config::site_secret , 
				seed=> $seed ,
			);
			$captcha_key= $captcha->get_publickey() or die "Error";
			$pageObject->{'PageUser'}->set_session_stored("captcha_publickey__${sectionName}",$captcha_key);
			$captcha= Authen::PluggableCaptcha->new( 
				type=> 'existing' , 
				site_secret=> $FindMeOn::Config::site_secret , 
				seed=> $seed ,
				publickey=> $captcha_key,
			);
		}
		$pageObject->{'CaptchaInstance'}= $captcha;
	}

=head3 Configure page views to intialize Captchas as needed 

a page that displays / verifies captchas just calls:

	&CAPTCHA_init( $self , 'registration', 1 );
	
if you didn't read the section above on what CAPTCHA_init does, you should

the cliffnotes are this though:
	
	$self= a page object that contains a context object with access to the session and libapreq functions
	'registration'= the name of the page used in creating a public_key seed ( this way register and confirm pages don't have the same captcha )
	1= an override flag, that forces the captcha object to be reset, as sometimes we cache objects
	

=head3 Show the captcha

make sure we called the init already 

to show a text captcha, we can render this directly into a Petal document

	%PetalPersonalizedHash= (
		'Captcha'=> {
			instructions=> undef,
			user_prompt=> $self->{'CaptchaInstance'}->render( 
				challenge_class=> 'Authen::PluggableCaptcha::Challenge::DoMath', 
				render_class=>'Authen::PluggableCaptcha:::Render::Text::HTML' 
			),
		},
	);

=head3 Validate the captcha

make sure we called the init already 

	if 	(
			!$self->{'CaptchaInstance'}->validate_response(
				challenge_class=> 'Authen::PluggableCaptcha::Challenge::DoMath',
				user_response=> $self->{'Form'}->get_validated('captcha_response'),
			)
		) {
		$self->{'Form'}->set_error('captcha_response','That answer is not correct, please try again');
		return $self->FORM_print();
	}
	else {
		# we're valid!
	}

=head3 So you want to diplay an image Dynamically?

first print the img block on a page that called Captcha Init

	my 	$captcha_embed= "<img src="/path/to/captcha/handler?section=registration" />";

then set up a sub / handler to generate the captcha on a url mapping

in this example, the captcha generator is in a central location -- /service/captcha/ -- so we supply the section name as a query arg.  
if the captcha generator were locked into a page, then you could just hardcode the section name
	
	sub render_image {
		my 	( $self )= @_ ;
	
		my 	$sectionName= $self->{'PageUser'}{'ApacheRequest'}->param('section');
	
		#initialize the captcha
		&FindMeOn::Functions::Misc::CAPTCHA_init( $self , $sectionName );
	
		$self->{'PageUser'}{'ApacheRequest'}->content_type('image/jpeg');
		$self->{'__BODY'}= $self->{'CaptchaInstance'}->render( 
			challenge_class=> 'Authen::PluggableCaptcha::Challenge::TypeString', 
			render_class=>'Authen::PluggableCaptcha::Render::Image::Imager' ,  
			font_filename=> '/usr/X11R6/lib/X11/fonts/TTF/VeraMoIt.ttf',
			format=>'jpeg' 
		);
		
		return;
	}


=head2 FAQ

=head3 There is a new constructor for both new and existing CAPTCHAs? I don't quite understand why you do it that way?

There is a single constructer that 'forks' into 2 separate init routines based on an argument to new().

Both arguments create a new KeyManager instance before they fork.

The type='new' routine immediately calls the KeyManager method generate_publickey  ( which could conceivably be a little resource intensive, if you've created a module that hits a db to check for collisions).  The fork was an obvious solution to split unnecessary calls out for performance optimization (ie: only run what you need )

The type='existing' routine automatically validates the construction arguments via the KeyManger method validate_publickey, which is unnecessary for new captchas.

Originally there was a single 'new', and from that you could call either 'new()' or 'existing()' -- but more people like 1 line of code.

=head3 Does it really need to know the site secret and seed for an existing CAPTCHA? Intuitively, I would think that it is only needed for a new CAPTCHA, and that only the public keys should be needed for an existing CAPTCHA?

That depends on how the KeyManager class you specify uses the site_secret to validate the key (which is why site_secret is not required in the base class , it can be an empty string ).
A DB backed key does not need the sitesecret for validation.  A logic backed key needs all the construction args to validate.

For example:

  key= md5( $site_secret , $time , $page_name , $session_id ) + ':' + $session
  key= 'xxxxxxxxxxxxxxxxxx:10000001'

If we know the site_secret under that formula, we always have every components of the item at our disposal -- and can validate the key for integrity

The default KeyManager class uses a site_secret to create the key.

=head3 Also, from the example in the Tutorial, it isn't quite clear if you first have to generate a new CAPTCHA, just to get its key, and then use that key to construct an existing CAPTCHA to create the JPEG. This isn't the case, is it? I could call render on it directly, right?

Yes. it renders directly on this example 'Generate a Captcha' above.

I think there is some confusion in this tutorial because i do 2 things that are a little odd:

	a- i run through the captcha generator to pull a new valid key, this way i can use a new example and have a key validate
	b- i run through the captcha validator while i can 'guess' an obviously wrong answer.  The way the system is structured, a solution is only provided when you try to validate the captcha.  That is because you might want to 'Render' an existing sound/image captcha which is completely isolated from Validating it.  By purposefully solving it wrong, the routine that sets up the correct user_response is run.

To display a CAPTCHA, you just create a new object and call the render method , passing in a challenge class and render class.  You can call the render method as often as you'd like.  Currently, the module will transparently validate the key in order to render the captcha.

=head3 You actually need to validate the key before check for a correct answer. But couldn't that data be stored on the backend?

Yes,  You could store the data on the backend.  The 'new' constructor will automatically call a key validator so it behaves more like this:

  my 	$captcha= new()
  if ( !$captcha->EXPIRED && !captcha->INVALID )
  {
  	render
  }
  
=head3 How would I store the key in the backend?

right now, you could either

  $dbh->do( store $captcha_publickey to db );

or

  create a KeyManager subclass, which creates a key and stores it to the db and does the validation

  you might be interested in L<Authen::PluggableCaptcha::KeyManagerDB>, which is a db backed keymanager class


=head3 How would I expire the key in the backend?

Good question.  expire_publickey is a method of the captcha and keymanager classes.  expire it in your page logic, or tell the base class to tell the manager to expire it.  but all that code is up to you.




=head3 Things there I don't grok, and so, it is something I kinda feel should be stored on the backend

That is totally understandable.  A lot of people want DB storage.  This module was written to support that as an option- not a requirement.

=head3 You still need to call new with "new" as type to get a valid key, right? Which means, it isn't completely standalone...

No.

The public key is something that is outwardly facing.

ie 

  http://mysite.com/captcha.jpg?key=abcdefg

you could call

  my $captcha= PluggableCaptcha->new( type="existing" , public_key="abcdefg" );

and then

  render that as an image

or

  process that for an answer


=head3 I'm still confused on the default public key system (yes, i know i can override it with my own class.  just wondering how yours works )

This might clarify-

  public_key= sprintf "%s:%s" , md5( time , site_secret , seed ) , time
  time= temporal component that lets a captcha work for only a 5 minute window.  note that is outside of, and inside of, the hash.  this makes the time realistically unspoofably
  site_secret= non-random seed unique to website to keep spammers from spoofing captcha
  seed= something unique to build this captcha
  
  in my setup:

    $seed= $url . $session{'id'}
    
  That makes sure that only 1 captcha is made for a certain URL and a certain session_id ( locked to that time - since the time is used to create the public key,  something 1 second later or earlier would be different )
  
  The drawback is that anyone with the same session_id (which can be spoofed / hijacked) can use that same captcha url for the time window
  
  If you're comfortable storing session data, this might be better for you:

    $seed= $url . $session{'id'} . $session{'captchas_solved'}
  
  Where $session{'captchas_solved'} is undefined at first, but every time a captcha on that session is solved,  session{captchas_solved}++

In the 'equation'/'transaction', the spammer has the URL , the session_id , and the time.  BUT he does not know the site secret, or can control the session variables.

If you've got sessions involved on the page that supports captchas, that approach could probably handle things securely.  It doesn't do a single-ticket expiry, but it pretty much makes it improbable to recreate the conditions to use a captcha more than once.

 
=head3 People have problems distinguishing one character for another in my CAPTCHA.  I have the following set (a-z) , how can I implement it?

Create your own challege class and run a filter or create a function that only uses your subset of characters.  This functionality was once provided in the system, but the list of discernable characters became so small it created captchas that were useless.  Depending on the way you render your captcha, the list will change- text/image captchas can render iIl1 similiarly, a warped image will make z2 or 5s  similar- or even 6G 9q. 

Creating your own captcha challenge class, and using it, takes almost no code or time at all to implement (20 lines, maybe? and you can use existing challlenge as a template)

Authen::Pluggable captcha was designed so you can quickly and easily override default functionality like this.


=head2 That's it!

yep.  sweet.


=head1 SUPPORT

=head1 AUTHOR

Jonathan Vanasco , cpan@2xlp.com

=head1 COPYRIGHT

Copyright (c) 2006 by Jonathan Vanasco.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
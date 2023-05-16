# NAME

Catalyst::Plugin::CSRFToken - Generate tokens to help prevent CSRF attacks

# SYNOPSIS

       package MyApp;
       use Catalyst;

       # The default functionality of this plugin expects a method 'sessionid' which
       # is associated with the current user session.  This method is provided by the
       # session plugin but you can provide your own or override 'default_csrf_session_id'
       # if you know what you are doing!

       MyApp->setup_plugins([qw/
         Session
         Session::State::Cookie
         Session::Store::Cookie
         CSRFToken
       /]);

       MyApp->config(
         'Plugin::CSRFToken' => { default_secret=>'changeme', auto_check_csrf_token => 1 }
       );
            
       MyApp->setup;
    
       package MyApp::Controller::Root;
    
       use Moose;
       use MooseX::MethodAttributes;
    
       extends 'Catalyst::Controller';
    
       sub login_form :Path(login_form) Args(0) {
         my ($self, $c) = @_;

         # A Basic manual check example if you leave 'auto_check_csrf_token' off (default)
         if($c->req->method eq 'POST') {
           Catalyst::Exception->throw(message => 'csrf_token failed validation')
             unless $c->check_csrf_token;
         }

         $c->stash(csrf_token => $c->csrf_token);  # send a token to your view and make sure you
                                                   # add it to your form as a hidden field
       }
    

# DESCRIPTION

This uses [WWW::CSRF](https://metacpan.org/pod/WWW%3A%3ACSRF) to generate hard to guess tokens tied to a give web session.  You can
generate a token and pass it to your view layer where it should be added to the form you are
trying to process, typically as a hidden field called 'csrf\_token' (althought you can change
that in configuration if needed).

Its probably best to enable 'auto\_check\_csrf\_token' true since that will automatically check
all POST, bPUT and PATCH request (but of course if you do this you have to be sure to add the token
to every single form.  If you need to just use this on a few forms (for example you have a 
large legacy application and need to improve security in steps) you can roll your own handling
via the `check_csrf_token` method as in the example given above.

# METHODS

This Plugin adds the following methods

## random\_token

This just returns base64 random string that is cryptographically secure and is generically
useful for anytime you just need a random token.   Default length is 48 but please note 
that the actual base64 length will be longer.  

## csrf\_token ($session, $token\_secret)

Generates a token for the current request path and user session and returns this string
in a form suitable to put into an HTML form hidden field value.  Accepts the following 
positional arguments:

- $session

    This is a string of data which is somehow linked to the current user session.   The default
    is to call the method 'default\_csrf\_session\_id' which currently just returns the value of
    '$c->sessionid'.  You can pass something here if you want a tigher scope (for example you
    want a token that is scoped to both the current user id and a given URL path).

- $token\_secret

    Default is whatever you set the configuration value 'default\_secret' to.

## check\_csrf\_token

Return true or false depending on if the current request has a token which is valid.  Accepts the
following arguments in the form of a hash:

- csrf\_token

    The token to check.   Default behavior is to invoke method `find_csrf_token_in_request` which
    looks in the HTTP request header and body parameters for the token.  Set this to validate a
    specific token.

- session

    This is a string of data which is somehow linked to the current user session.   The default
    is to call the method 'default\_csrf\_session\_id' which currently just returns the value of
    '$c->sessionid'.  You can pass something here if you want a tigher scope (for example you
    want a token that is scoped to both the current user id and a given URL path).

    It should match whatever you passed to `csrf_token` for the request token you are trying to validate.

- token\_secret

    Default is whatever you set the configuration value 'default\_secret' to.  Allows you to specify a
    custom secret (it should match whatever you passed to `csrf_token`).

- max\_age

    Defaults to whatever you set configuration value &lt;max\_age>.  A value in seconds that measures how
    long a token is considered 'not expired'.  I recommend setting this to as short a value as is 
    reasonable for your users to linger on a form page.

Example:

    $c->check_csrf_token(max_age=>(60*10)); # Don't accept a token that is older than 10 minutes.

**NOTE**: If the token 

## invalid\_csrf\_token

Returns true if the token is invalid.  This is just the inverse of 'check\_csrf\_token' and
it accepts the same arguments.

## last\_checked\_csrf\_token\_expired

Return true if the last checked token was considered expired based on the arguments used to
check it.  Useful if you are writing custom checking code that wants to return a different
error if the token was well formed but just too old.   Throws an exception if you haven't
actually checked a token.

## single\_use\_csrf\_token

Creates a token that is saved in the session.  Unlike 'csrf\_token' this token is not crytographically
signed so intead its saved in the user session and can only be used once.   You might prefer
this approach for classic HTML forms while the other approach could be better for API applications
where you don't want the overhead of a user session (or where you'd like the client to be able to
open multiply connections at once.

## check\_single\_use\_csrf\_token

Checks a single\_use\_csrf\_token.   Accepts the token to check but defaults to getting it from
the request if not provided.

# CONFIGURATION

This plugin permits the following configurations keys

## default\_secret

String that is used in part to generate the token to help ensure its hard to guess.

## max\_age

Default to 3600 seconds (one hour).   This is the length of time before the generated token
is considered expired.  One hour is probably too long. You should set it to the shortest
time reasonable.

## param\_key

Defaults to 'csrf\_token'.   The Body param key we look for the token.

## auto\_check\_csrf\_token

Defaults to false.   When set to true we automatically do a check for all POST, PATCH and
PUT method requests and if the check fails we delegate handling in the following way:

If the current controller does a method called 'handle\_failed\_csrf\_token\_check' we invoke that
passing the current context.

Else if the application class does a method called 'handle\_failed\_csrf\_token\_check' we invoke
that instead.

Failing either of those we just throw an expection which you can catch manually in the global
'end' action or else it will fail thru eventually to Catalyst's default error handler.

# AUTHOR

     John Napiorkowski <jnapiork@cpan.org>
    

# COPYRIGHT

Copyright (c) 2022 the above named AUTHOR

# LICENSE

You may distribute this code under the same terms as Perl itself.

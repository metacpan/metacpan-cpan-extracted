package Catalyst::Plugin::DebugCookie;

use strict;
use warnings;
use 5.008001;
use MRO::Compat;
use Catalyst::Plugin::DebugCookie::Util qw/check_debug_cookie_value/;

our $VERSION = '0.999004';

=head1 NAME

Catalyst::Plugin::DebugCookie - Catalyst plugin to turn on 
debug when a secure cookie and a query param are set  

=head1 SYNOPSIS

 # In your application class define the plugin
 use Catalyst qw/DebugCookie/;

 # In your controller, you must define an action method to set the cookie.
 # This should be secured by htpasswd or similar methods
 use Catalyst::Plugin::DebugCookie::Util qw/make_debug_cookie/;
 sub secure_debug_cookie :Path(/this/is/not/public) { 
	my ($self, $c, $username) = @_; 

	# this method is defined for you in the provided util class
	make_debug_cookie($c, $username);
	$c->res->body("Cookie set"); 
 }

 # Your configuration in perl  
 __PACKAGE__->config->{Plugin::DebugCookie} = {
	secret_key  => '001A4B28EE3936',
	cookie_name => 'mycookie',
 }

 # Or your configuration in L<Config::General> format 
 <Plugin::DebugCookie>
    secret_key 001A4B28EE3936
    cookie_name my_secure_debug_cookie 
 </Plugin::DebugCookie>

 # In your browser first set the cookie with your username
 http:///this/is/not/public/<username>

 # Finally, in your browser view a page with the parameter 'is_debug'
 # set with the same username used when generating the cookie.
 # The plugin will turn on debug mode for this request
 http://yourserver?is_debug=<username>

=head1 DESCRIPTION

Catalyst plugin to turn debug on a per request basis, typically used in a 
production environment where debug is off by default.  Two things must happen 
to enable debug. First, you have to go to a secure (ideally password protected)  
URL to set the cookie, which is a hash of your secret key and username.  Secondly,
you have to hit the page with the ?is_debug=<username> query parameter.

Note that this plugin will only work when catalyst debug is off since 
CATALYST_DEBUG=1 injects a 'sub debug { 1 }' into MyApp::, therefore
the overloaded debug in this plugin would not be executed.

=head1 CONFIGURATION

=head2 secret_key 

This is a key hashed with a username to provide cookie security 

=head2 cookie_name 

Sets the name of the cookie (optional). Defaults to 'debug_cookie'  

=head1 EXTENDED METHODS

The following methods are extended from the main Catalyst application class.

=head2 prepare 

Sets 'X-Catalyst-Debug' header and enables stats when debug is on

=cut
sub prepare { 
	my $class = shift; 
	my $self = $class->next::method(@_); 
	$self->response->header( 'X-Catalyst-Debug' => $self->debug ? 1 : 0 );
	if ($self->debug) {
		$self->stats->enable($self->use_stats);
	}
	$self; 
}

=head2 debug 

Determines whether debug should be 
set based on cookie and query param

=cut
sub debug { 
	my $self = shift;
	if (ref $self) { 
		return $self->next::method(@_) || $self->valid_debug_mode; 
	} else {
		$self->next::method(@_); 
	}
}

=head2 use_stats 

Determines whether use_stats should be 
set based on cookie and query param

=cut
sub use_stats { 
	my $self = shift;
	if (ref $self) { 
		return $self->{use_stats} ||= $self->valid_debug_mode; 
	} else {
		$self->next::method(@_); 
	}
}

=head1 METHODS

=head2 valid_debug_mode 

Checks for is_debug query param and checks for a valid cookie
and returns true if both are validated

=cut
sub valid_debug_mode {
	my $self = shift;

	if(my $is_debug = $self->req->query_params->{is_debug}) {
		return check_debug_cookie_value($self, $is_debug); 
	}

	return 0;
}

=head1 AUTHOR

 John Goulah       <jgoulah@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;

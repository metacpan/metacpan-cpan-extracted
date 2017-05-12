package Dancer::Plugin::Auth::Github;

use Dancer ':syntax';
use Dancer::Plugin;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp 'croak';

use Digest::SHA qw(sha256_hex);
use LWP::UserAgent;
use JSON qw(decode_json);


our $VERSION = '0.04';

my $client_id;
my $client_secret;
my $scope = "";
my $github_redirect_url = 'https://github.com/login/oauth/authorize/';
my $github_post_url = 'https://github.com/login/oauth/access_token/';
my $github_auth_failed = '/auth/github/failed';
my $github_auth_success = '/';
my $state_salt = "RandomSalt";

#A method to initializa everything
register 'auth_github_init' => sub {
	my $config = plugin_setting;
	
	$client_id 		  = $config->{client_id};
    $client_secret    = $config->{client_secret};
    	
	for my $param (qw/client_id client_secret/) {
        croak "'$param' is expected but not found in configuration" 
            unless $config->{$param};
    }
	#sthe following configs are optional.
 	if($config->{scope}) {
		$scope = $config->{scope};
	}
	#these configs have default values.
	if($config->{github_auth_failed})
	{
		$github_auth_failed = $config->{github_auth_failed};
	}
	if($config->{github_auth_success})
	{
		$github_auth_success = $config->{github_auth_success};
	}
	debug 'Loaded config..';
};
#returns the url you need to redirect to to authenticate on github
register 'auth_github_authenticate_url'  => sub {
	my $generate_state = sha256_hex($client_id.$client_secret.$state_salt);
	return "$github_redirect_url?&client_id=$client_id&scope=$scope&state=$generate_state";
};
#registers this as a callback url
get '/auth/github/callback' => sub {
	my $generate_state = sha256_hex($client_id.$client_secret.$state_salt);
	my $state_received = params->{'state'};
	if($state_received eq $generate_state) { 
		my $code                   = params->{'code'};
		my $browser                = LWP::UserAgent->new;
		my $resp                   = $browser->post($github_post_url,
		[
		client_id                  => $client_id,
		client_secret              => $client_secret, 
		code                       => $code,
		state                      => $state_received
		]);
		die "error while fetching: ", $resp->status_line
		unless $resp->is_success;
		
		my %querystr = parse_query_str($resp->decoded_content);
		my $acc = $querystr{access_token};
		
		if($acc) {
			my $jresp  = $browser->get("https://api.github.com/user?access_token=$acc");
			my $json = decode_json($jresp->decoded_content);
			session 'github_user' => $json;
			session 'github_access_token' => $acc;
			#session 'logged_in' => true;
			redirect $github_auth_success;
			return;
		} 
	}
	redirect $github_auth_failed;
};

#helper method to parse query string.
sub parse_query_str {
	my $str = shift;
	my %in = ();
	if (length ($str) > 0){
	      my $buffer = $str;
	      my @pairs = split(/&/, $buffer);
	      foreach my $pair (@pairs){
	           my ($name, $value) = split(/=/, $pair);
	           $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	           $in{$name} = $value; 
	      }
	 }
	return %in;
}
register_plugin;

1; # End of Dancer::Plugin::Auth::Github
__END__
=head1 NAME

Dancer::Plugin::Auth::Github - Authenticate with Github

=head1 SYNOPSIS

    package YourDancerApplication;

    use Dancer ':syntax';
    use Dancer::Plugin::Auth::Github;

    #You must use a session backend. 
    #You should be able to use any backend support by dancer.
    set 'session'      => 'Simple';
    
    #make sure you call this first.
    #initializes the config
    auth_github_init();

    hook before => sub {
        #we don't want to be in a redirect loop
        return if request->path =~ m{/auth/github/callback};
        if (not session('github_user')) {
            redirect auth_github_authenticate_url;
        }
    };

    #by default success will redirect to this route
    get '/' => sub {
        "Hello, ".session('github_user')->{'login'};
        #For all the github_user properties
        #look at http://developer.github.com/v3/users/
        #See the Response for "Get the authenticated user"
    };

    #additionally the plugin adds session('github_access_token')
    #so you can use it if you're doing other things with GitHub Api.

    #by default authentication failure will redirect to this route
    get '/auth/github/failed' => sub { return "Github authentication Failed" };

    ...

=head1 CONCEPT

This plugin helps you setup authentication with github OAuth api in your dancer application. 
It has a helper method that returns the URL you must redirect to for authentication with github,
it then defines a callback that handles the rest and if the user was authenticated, his/her info 
is stored in a session object C<session('github_user')>. The plugin also adds C<session('github_access_token)> 
if you're doing anything else with github api.

=head1 PREREQUESITES

In order for this plugin to work, you need the following:

=over 4 

=item * Github application

You must register your github application here L<https://github.com/settings/applications/new>. You also need 
to set the callback url in your application settings to C<yourdomain.com/auth/github/callback>. Note, for testing 
purposes GitHub allows you to use C<http://127.0.0.1:3000> as your application url.

=item * Configuration

The plugin needs to be configured with your C<client_id> and C<client_secret> 
(provided by Github once you register your application).

Set this in your Dancer's configuration under
C<plugins/Auth::Github>:

    # config.yml
    ...
	plugins:
	  "Auth::Github":
	    client_id: "abcde"
	    client_secret: "abcde"
	    scope: ""
	    github_auth_failed: "/fail"
	    github_auth_success: "/"

There is an optional scope, which can be one of the L<scopes here |http://developer.github.com/v3/oauth/#scopes>. 
Don't include scope if you just need the authenticated user
.C<github_auth_success> and C<github_auth_failed> are optional and default to 
'/' and '/auth/github/failed', respectively.

=item * Session backend

You need to setup a session backend in your dancer application for everything to work.
This plugin stores the authenticated user in a session with the name C<github_user>

You should be able to use any session backend, see
L<Dancer::Session> for details about various Dancer session backends, or
L<http://search.cpan.org/search?query=Dancer-Session|search the CPAN for new ones>.

=back

=head1 EXPORT

The plugin exports the following symbols to your application's namespace:


=head2 auth_github_init

This function should be called before all your route handlers. It loads up the configuration
from your C<config.yml>

=head2 auth_github_authenticate_url

This function returns an URL that is used to authenticate with github
You could put it in a hook like this: 

     hook 'before' => sub {
        # we don't want a redirect loop here
        #Github will call /auth/github/callback once the user is authenticated
        return if request->path =~ m{/auth/github/callback};
    
        if (not session('github_user')) {
            redirect auth_github_authenticate_url();
        }
    };

(See L<this page|http://search.cpan.org/dist/Dancer/lib/Dancer/Introduction.pod#Before_hooks> 
for more on C<before hooks>)

=head1 ROUTE HANDLERS

The plugin defines the following route handler automatically

=head2 /auth/github/callback

When a user authenticates on Github, Github redirects back to this url. (Note: You must 
set the callback url to this one). The route handler will save the access token and then
retrieve the authenticated user's information in the session.

If the authentication succeeded, then the plugin will redirect to url setup in the config :
C<github_auth_success>, if it failed, then the user is redirected to C<github_auth_fail>. 
By default C<github_auth_success = /> and C<github_auth_fail = "/auth/github/failed">

When the authentication succeeds two session objects are created. C<session('github_user')> .
For all the github_user properties L<see this page|http://developer.github.com/v3/users/>.
C<session('github_access_token')> is also created, if you need to do other things with the api.

=head1 AUTHOR

Gideon Israel Dsouza, C<< <gideon at cpan.org> >>, L<http://www.gideondsouza.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-auth-github at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Auth-Github>. 
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Auth::Github


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Auth-Github>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-Auth-Github>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Auth-Github>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-Auth-Github/>

=back


=head1 ACKNOWLEDGEMENTS

This project is more or less a port of L<Dancer::Plugin::Auth::Twitter> written by Alexis Sukrieh which itself is a port of 
L<Catalyst::Authentication::Credential::Twitter> written by Jesse Stay.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Gideon Israel Dsouza.

This project is open source L<here on github|https://github.com/gideondsouza/dancer-plugin-auth-github>. 

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut




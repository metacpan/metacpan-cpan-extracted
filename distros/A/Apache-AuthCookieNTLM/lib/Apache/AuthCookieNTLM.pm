package Apache::AuthCookieNTLM;

# Small wrapper to Apache::AuthenNTLM to store user login details to cookie
# and reduce the number of PDC requests.

use strict;
use Data::Dumper;
use Apache::Constants ':common';

use Apache::Request;
use Apache::Cookie;
use Apache::AuthenNTLM;
use base ('Apache::AuthenNTLM');

use vars qw($VERSION);
$VERSION = 0.07;

# Global to store stuff in
my $cookie_values = {};

sub handler ($$) {
	my ($self,$r) = @_;
	
	# Get auth type and name
	my ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);

	# Get server config
	my %config;
	foreach my $var ( qw(Expires Path Domain Secure Name) ) {
		$config{lc($var)} = $r->dir_config("$auth_name$var") || undef;
	}
	
	my $debug = $r->dir_config('ntlmdebug') || 0;
		
	# Set cookie name
	my $cname = $config{name} || $auth_type . '_' . $auth_name;
	print STDERR "AuthCookieNTLM - Looking for Cookie Name: $cname\n" if $debug > 0;
	
	# Look for cookie
	my $t = Apache::Request->new($self);
	my %cookiejar = Apache::Cookie->new($t)->parse;
	
	 if (!defined $cookiejar{$cname}
	         or ($r->method eq 'POST' and $r->header_in('content-length') == 0)){
	
		# Don't have the cookie, try authenticate
		my $v = Apache::AuthenNTLM::handler ($self, $r);
				
		if ($v == 0 && $cookie_values ne {}) {	
			# Set the cookie as we have user details
			my $cookie = Apache::Cookie->new($r,
				-name		=> $cname,
				-value		=> $cookie_values,
				-path		=> $config{'path'}	|| "/",
				);
			$cookie->expires($config{'expires'}) if defined $config{'expires'};
			$cookie->domain($config{'domain'}) if defined $config{'domain'};
			$cookie->secure('1') if defined $config{'secure'};
			
			# Set the cookie to header
			$r->header_out('Set-Cookie' => $cookie->bake());

			if($debug > 0) {
				print STDERR "AuthCookieNTLM - Setting Cookie Expire: " . $config{'expires'} . "\n" if $debug > 0 && defined $config{'expires'};
				print STDERR "AuthCookieNTLM - Setting Cookie Domain: " . $config{'domain'} . "\n" if $debug > 0 && defined $config{'domain'};
				print STDERR "AuthCookieNTLM - Setting Cookie Secure: " . $config{'secure'} . "\n" if $debug > 1 && defined $config{'secure'};
				print STDERR "AuthCookieNTLM - Setting Cookie values: " . Dumper($cookie_values) . "\n" if $debug > 1;
			}			
		}
		# AuthenNTLM loops so have to behave like it does
		# and return $v
		return $v;
	} else {
		print STDERR "AuthCookieNTLM - Found Cookies for '$cname'\n" if $debug > 0;
		my %c = $cookiejar{$cname}->parse();
		if(defined $c{$cname}) {
			print STDERR "AuthCookieNTLM - Cookie Matched \n" if $debug > 1;
			my %v = $c{$cname}->value();
			print STDERR "AuthCookieNTLM - Cookie values " . Dumper(\%v) . "\n" if $debug > 1;
			if(defined $v{'username'} && defined $v{'userdomain'}) {
				my $user = lc($v{'userdomain'} . '\\' . $v{'username'});
		        $r ->user($user) if ref($r) eq 'Apache';
				print STDERR "AuthCookieNTLM - REMOVE_USER SET: " . $user . "\n" if $debug > 1;
			}
		}
	}

	return OK;
}

sub check_cookie {
	my $self = shift;
	return 1 if ( $cookie_values eq {} || $cookie_values->{username} ne $self->{username} );
	return undef;
}

# Private method to set the cookie
sub set_cookie {
	my ($self, $conf) = @_;
	
	# Must have the user name to validate check_cookie()
	$cookie_values->{'username'} = $self->{'username'};
	$cookie_values->{'userdomain'} = $self->{'userdomain'};

	while( my ($name, $value) = each %{$conf}) {
		$cookie_values->{$name} = $value;
	}
};

# This is the method which others could overload to
# set what ever values they want.
sub choose_cookie_values {
	my ($self,$r) = @_;
	
	# Save
	if ($self->check_cookie()) {
		$self->set_cookie();
	}
}

# Overloaded to allow us to call choose_cookie_values
# and get access to the object.
sub map_user {
    my ($self, $r) = @_ ;
	
    $self->choose_cookie_values($r);

    return lc("$self->{userdomain}\\$self->{username}");
}


1;

__END__

=head1 NAME

Apache::AuthCookieNTLM - NTLM (Windows domain) authentication with cookies

=head1 SYNOPSIS

'WhatEver' should be replaced with the AuthName you choose
for this location's authentication.

    <Location />
        PerlAuthenHandler Apache::AuthCookieNTLM

        # NTLM CONFIG
        AuthType ntlm,basic
        AuthName WhatEver
        require valid-user

        #                   domain          pdc               bdc
        PerlAddVar ntdomain "name_domain1   name_of_pdc1"
        PerlAddVar ntdomain "other_domain   pdc_for_domain    bdc_for_domain"

        PerlSetVar defaultdomain default_domain
        PerlSetVar ntlmdebug 1

        # COOKIE CONFIG - all are optional and have defaults
        PerlSetVar WhatEverName cookie_name
        PerlSetVar WhatEverExpires +5h
        PerlSetVar WhatEverPath /
        PerlSetVar WhatEverDomain yourdomain.com
        PerlSetVar WhatEverSecure 1
    </Location>


=head1 DESCRIPTION

As explained in the Apache::AuthenNTLM module, depending on the user's 
config, IE will supply your Windows logon credentials to the web server
when the server asks for NTLM authentication. This saves the user typing in
their windows login and password. 

Apache::AuthCookieNTLM is an interface to Shannon Peevey's 
Apache::AuthenNTLM module. This modules authenticates a user 
using their Windows login against the Windows PDC, but to also 
stores their login name into a cookie. This means that it can be 
accessed from other pages and stops the system having to 
authenticate for every request.

We did consider using Apache::AuthCookie to store the details in a 
cookie but since using NTLM is basicaly there to remove the need
to login and is almost exclusively for intranets (as it needs access
to the PDC), we decided it was feasible not to use it.

=head1 APACHE CONFIGURATION

Please consult the Apache::AuthenNTLM documentation for more details on 
the NTLM configuration.

'WhatEver' should be replaced with the AuthName you choose
for this location's authentication.

=head2 PerlSetVar WhatEverName

Sets the cookie name. This will default to 
Apache::AuthCookieNTLM_WhatEver.

=head2 PerlSetVar WhatEverExpires 

Sets the cookie expiry time. This defaults to being 
a session only cookie.

=head2 PerlSetVar WhatEverPath

Sets the path that can retrieve the cookie. The default is /.

=head2 PerlSetVar WhatEverDomain

Defaults to current server name, set to what ever domain
you wish to be able to access the cookie.

=head2 PerlSetVar WhatEverSecure

Not set as default, set to 1 if you wish for cookies to
only be returned to a secure (https) server.

=head2 PerlSetVar ntlmdebug

Setting this value means debugging information is shown in the
apache error log, this value is also used for Apache::AuthenNTLM.
Default to 0, set to 1 or 2 for more debugging info.

=head1 OVERRIDEABLE METHODS

=head2 choose_cookie_values()

The method can be overwritten to set the values stored in the cookie

=head2 Example for overriding

This is an example of how to set your cookie values with whatever 
data you want.

  package MYAuthenNTLM;

  use Apache::AuthCookieNTLM;	
  use base ( 'Apache::AuthCookieNTLM' );
  use MyUserLookup_Package;
  
  sub choose_cookie_values {
    my ($self,$r) = @_;
	
    # Save if it's not already set
    if ($self->check_cookie()) {
		# Look up against other sources
	    my $person = MyUserLookup_Package->new($self->{'username'});

        $self->set_cookie({
            'email'	=> $person->email(),
            'shoe_size' => $person->shoe_size(),
        });
    }
  }
  1;

'username' and 'userdomain' are set automatically, though you 
can override them, they are used to set the REMOTE_USER value.

=head1 COMMON PROBLEMS

First test Apache::AuthenNTLM directly without this module.

=head2 NTLM Authentication

If you get prompted for a login / passwd / domain IE probably isn't 
sending the NTLM information. Ensure that IE sees the server as a 
'trusted' intranet site  (and therefor sends the username). You 
should be  able to set this as a policy across your network, or on 
each machine:

'Tools' -> 'Internet Options' -> 'Security' -> 'Local Intranet' ->
'Sites' -> 'Advanced' and add it in there, this must start
with http:// or https://

Once this is working you should be able to just replace

  PerlAuthenHandler Apache::AuthenNTLM

with		
		
  PerlAuthenHandler Apache::AuthCookieNTLM

And have it all just work[tm].

Remember to quit IE and reload as it's crap at implementing
changes on the fly!

=head2 Not setting cookies

IE doesn't seem to alert you (if you've turned prompt on 
for cookies). We guess it's because its from the trusted site.

Also check your using the right domain, as can be
seen when you turn debug on.

=head2 access to /test failed in error log - but it works

Because Apache::AuthenNTLM has to go through several loops
the first of which will fail, this will be reported in
your error log, but you can just ignore it.

=head1 SEE ALSO

L<Apache::AuthenNTLM>,
L<Apache::Cookie>,
L<CGI::Cookie>

=head1 AUTHOR

Leo Lapworth <llap@cuckoo.org>, Francoise Dehinbo

=cut
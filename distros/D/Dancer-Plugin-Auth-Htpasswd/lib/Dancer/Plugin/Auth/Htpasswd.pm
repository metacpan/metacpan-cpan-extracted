package Dancer::Plugin::Auth::Htpasswd;

use strict;
use warnings;

# ABSTRACT: Basic HTTP authentication with htpasswd files in Dancer apps

our $VERSION = '0.020'; # VERSION

use Authen::Htpasswd;
use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Response;
use MIME::Base64;

my $settings = plugin_setting;

# Protected paths defined in the configuration
my $paths = {};

if (exists $settings->{paths}) {
    $paths = $settings->{paths};
}

sub _auth_htpasswd {
    my ($passwd_file, $realm);
    
    if (1 == @_) {
        $passwd_file = shift;
        $realm = "Restricted area";
    }
    else {
        my %options = @_;
        $passwd_file = $options{passwd_file};
        $realm = $options{realm};
    }
    
    if (-r $passwd_file) {
        # Get authentication data from request
        my $auth = request->header('Authorization');
        
        if (defined $auth && $auth =~ /^Basic (.*)$/) {
            my ($user, $password) = split(/:/, (MIME::Base64::decode($1) ||
                ":"));
            
            my $htpasswd = Authen::Htpasswd->new($passwd_file);
            
            if ($htpasswd->lookup_user($user) && 
                $htpasswd->check_user_password($user, $password))
            {
                # Authorization succeeded
                request->env->{REMOTE_USER} = $user;                
                return 1;
            }
        }
    }
    else {
        # Cannot read the password file
        warning __PACKAGE__ . ": Password file '" . $passwd_file . "' can't " .
            "be read";
    }
    
    my $content = "Authorization required";
    
    return halt(Dancer::Response->new(
        status => 401,
        content => $content,
        headers => [
            'Content-Type' => 'text/plain',
            'Content-Length' => length($content),
            'WWW-Authenticate' => 'Basic realm="' . $realm . '"'
        ]
    ));
}

my $check_auth = sub {
    # Check if the request matches one of the protected paths (reverse sort the
    # paths to find the longest matching path first)
    foreach my $path (reverse sort keys %$paths) {
        my $path_re = '^' . quotemeta($path);
        
        if (request->path_info =~ qr{$path_re}) {
            if (ref $paths->{$path}) {
                _auth_htpasswd %{$paths->{$path}};
            }
            else {
                _auth_htpasswd $paths->{$path};
            }
            last;
        }
    }
};

hook before => $check_auth;
hook before_file_render => $check_auth;

register auth_htpasswd => \&_auth_htpasswd;

register_plugin;

1; # End of Dancer::Plugin::Auth::Htpasswd

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Plugin::Auth::Htpasswd - Basic HTTP authentication with htpasswd files in Dancer apps

=head1 VERSION

version 0.020

=head1 SYNOPSIS

Dancer::Plugin::Auth::Htpasswd allows you to use Apache-style htpasswd files to
implement basic HTTP authentication in Dancer web applications. 

Add the plugin to your application:

    use Dancer::Plugin::Auth::Htpasswd;

In the configuration file, list the paths that you want to protect and the
htpasswd files to use:

    plugins:
      "Auth::Htpasswd":
        paths:
          "/restricted": /path/to/htpasswd
          "/secret/documents":
            realm: "Top Secret Documents"
            passwd_file: /different/path/to/htpasswd

You can also enable authentication by calling the C<auth_htpasswd> function in a
before filter:

    before sub {
        auth_htpasswd realm => 'Secret Files',
                      passwd_file => '/path/to/htpasswd';
    };

or in a route handler:

    get '/restricted' => sub {
        auth_htpasswd '/path/to/htpasswd';
        
        # Authenticated
        ...
    };

=head1 DESCRIPTION

Dancer::Plugin::Auth::Htpasswd provides a simple way to implement basic HTTP
authentication in Dancer web applications using Apache-style htpasswd files.

=head1 CONFIGURATION

To configure the plugin, add its options in the C<plugins> section of your
application's configuration file. The supported options are listed below.

=head2 paths

Defines one or more paths that will be protected, including sub-paths (so if the
path is C<"/restricted">, then C<"/restricted/secret/file.html"> will also be
protected). Each path can have the following parameters:

=over 4

=item * C<passwd_file>

Location of the htpasswd file.

=item * C<realm>

Realm name that will be displayed in the authentication dialog. Default:
C<"Restricted area">

=back

Example:

    plugins:
      "Auth::Htpasswd":
        paths:
          "/classified":
            realm: "Classified Files"
            passwd_file: /path/to/htpasswd

If you don't need to set the realm, you can use the simplified syntax with just 
the location of the htpasswd file:

    plugins:
      "Auth::Htpasswd":
        paths:
          "/secret/documents": /path/to/htpasswd
          "/restricted": /another/path/to/htpasswd

=head1 SUBROUTINES

=head2 auth_htpasswd

Call this function in a before filter or at the beginning of a route handler. It
checks the specified htpasswd file to verify if the client is authorized to
access the requested path -- if not, it immediately returns a 401 Unauthorized
response to prompt the user to authenticate.

You can call this function with a single parameter, which is the location of the
htpasswd file to use:

    auth_htpasswd '/path/to/htpasswd';

or, with a hash of parameters:

    auth_htpasswd realm => 'Authorized personnel only',
                  passwd_file => '/path/to/htpasswd';

Parameters:

=over 4

=item * C<passwd_file>

Location of the htpasswd file.

=item * C<realm>

Realm name that will be displayed in the authentication dialog. Default:
C<"Restricted area">

=back

=head1 SEE ALSO

=over 4

=item *

L<Authen::Htpasswd>

=back

=head1 ACKNOWLEDGEMENTS

The plugin uses the L<Authen::Htpasswd> module, written by David Kamholz
and Yuval Kogman.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/odyniec/p5-Dancer-Plugin-Auth-Htpasswd/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/odyniec/p5-Dancer-Plugin-Auth-Htpasswd>

  git clone https://github.com/odyniec/p5-Dancer-Plugin-Auth-Htpasswd.git

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

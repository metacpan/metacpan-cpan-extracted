package Dancer::Plugin::Auth::CAS;
{
  $Dancer::Plugin::Auth::CAS::VERSION = '1.128';
}

=head1 NAME

Dancer::Plugin::Auth::CAS - CAS sso authentication for Dancer

=cut

use warnings;
use strict;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Response;
use Dancer::Exception ':all';
use HTTP::Headers;
use Authen::CAS::Client;
use Scalar::Util 'blessed';

our $VERSION;

register_exception('InvalidConfig', message_pattern => "Invalid or missing configuration: %s");
register_exception('CasError', message_pattern => "Unable to auth with CAS backend: %s");

my $settings = plugin_setting;

sub _auth_cas {
    my (%options) = @_;

    my $base_url = $settings->{cas_url} // raise( InvalidConfig => "cas_url is unset" );
    my $cas_version = $settings->{cas_version} ||  raise( InvalidConfig => "cas_version is unset");
    my $cas_user_map = $options{cas_user_map} || $settings->{cas_user_map} || 'cas_user';
    my $cas_denied_url = $options{cas_denied_path} || $settings->{cas_denied_path} || '/denied';

    my $ssl_verify_hostname = $settings->{ssl_verify_hostname};
    $ENV{"PERL_LWP_SSL_VERIFY_HOSTNAME"} = defined( $ssl_verify_hostname ) ? $ssl_verify_hostname : 1;

    # check supported versions
    unless( grep(/$cas_version/, qw( 2.0 1.0 )) ) {
        raise( InvalidConfig => "cas_version '$cas_version' not supported");
    }

    my $mapping = $settings->{cas_attr_map} || {};

    my $ticket = $options{ticket};
    my $params = request->params;
    unless( $ticket ) {
        my $tickets = $params->{ticket};
        # For the case when application also uses 'ticket' parameters
        # we only remove the real cas service ticket
        if( ref($tickets) eq "ARRAY" ) {
            while( my ($index, $value) = each @$tickets ) {
                # The 'ST-' is specified in CAS-protocol
                if( $value =~ m/^ST\-/ ) {
                    $ticket = delete $tickets->[$index];
                }
            }
        } else {
            $ticket = delete $params->{ticket};
        }
    }
    my $service = uri_for( request->path_info, $params );

    my $cas = Authen::CAS::Client->new( $base_url );

    my $user = session($cas_user_map);

    unless( $user ) {

        my $response = Dancer::Response->new( status => 302 );
        my $redirect_url;

        if( $ticket) {
            debug "Trying to validate via CAS '$cas_version' with ticket=$ticket";
            
            my $r;
            if( $cas_version eq "1.0" ) {
                $r = $cas->validate( $service, $ticket );
            }
            elsif( $cas_version eq "2.0" ) {
                $r = $cas->service_validate( $service, $ticket );
            }
            else {
                raise( InvalidConfig => "cas_version '$cas_version' not supported");
            }

            if( $r->is_success ) {

                # Redirect to given path
                info "Authenticated as: ".$r->user;
                if( $cas_version eq "1.0" ) {
                    session $cas_user_map => $r->user;
                } else {
                    session $cas_user_map => _map_attributes( $r->doc, $mapping );
                }
                $redirect_url = $service;

            } elsif( $r->is_failure ) {

                # Redirect to denied
                debug "Failed to authenticate: ".$r->code." / ".$r->message;
                $redirect_url = uri_for( $cas_denied_url );

            } else {

                # Raise hard error, backend has errors
                error "Unable to authenticate: ".$r->error;
                raise( CasError => $r->error );
            }

        } else {
            # Has no ticket, needs one
            debug "Redirecting to CAS: ".$cas->login_url( $service );
            $redirect_url = $cas->login_url( $service );
        }

        # General redir response
        $response->header( Location => $redirect_url );
        halt( $response );
    }
    
}

sub _map_attributes {
    my ( $doc, $mapping ) = @_;

    my $attrs = {};

    my $result = $doc->find( '/cas:serviceResponse/cas:authenticationSuccess' );
    if( $result ) { 
        my $node = $result->get_node(1);

        # extra all attributes
        my @attributes = $node->findnodes( "./cas:attributes/*" );
        foreach my $a (@attributes) {
            my $name = (split(/:/, $a->nodeName, 2))[1];
            my $val = $a->textContent;

            my $mapped_name = $mapping->{ $name } // $name;
            $attrs->{ $mapped_name } = $val;
        }
            
    }
    debug "Mapped attributes: ".to_dumper( $attrs );
    return $attrs;
}


register auth_cas => \&_auth_cas;
register_plugin;

1; # End of Dancer::Plugin::Auth::CAS
__END__

=pod

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Dancer::Plugin::Auth::CAS provides CAS single-sign-on authentication

Add the plugin to your application:

    use Dancer::Plugin::Auth::CAS;

Configure the plugin in your config:

  plugins:
    "Auth::CAS":
        cas_url: "https://your.org/sso"
        cas_denied_path: "/denied"
        cas_version: "2.0"
        cas_user_map: "user"
        cas_attr_map:
            email: "email"
            username: "username"
            firstName: "firstname"
            lastName: "lastname"

Call the C<auth_cas> function in a before filter:

    before sub {
        # fetches the ticket via URL 'ticket' parameter
        auth_cas; 

        # or if you want to fetch the ticket yourself:
        auth_cas( ticket => $cas_ticket_id ); 

        # or if you want to override global options:
        auth_cas(
            cas_denied_path => ... ,
            cas_user_map => ... ,
        );
    };

or in a route handler:
    
    get '/confidential' => sub {
        auth_cas;
        # Authenticated
        ...
    };

=head1 DESCRIPTION

Cancer::Plugin::Auth::CAS provides single-sign-on (sso) authentication 
via JASIGs Central Authentication Service (CAS). See L<http://www.jasig.org/cas>

=head1 CONFIGURATION

The available configuration options are listed below.

=head2 cas_url

The URL of your CAS server

=head2 cas_denied_path

Redirect towards this path or URL when authentication worked but was simply invalid.

=head2 cas_version

The version of your CAS server, usually '2.0' or '1.0'

=head2 cas_user_map

This lets you choose under what name the CAS user details will be stored in your session. Defaults to: 'cas_user'
All user attributes delivered by the CAS-Server will be stored as a HashRef under the session key of C<cas_user_map>. 
Defaults to: 'cas_user'

=head2 cas_attr_map 

This lets you map CAS user attributes towards your own attribute names.

Example:

    cas_attr_map:
        email: "user_email"
        username: "username"
        firstName: "first_name"
        lastName: "last_name"

This will map the CAS user attribute C<email> to C<user_email> aso..
          
=head1 FUNCTIONS

=head2 auth_cas ( %args )

This function may be called in a before filter or at the beginning of a route
handler. It checks if the client is authenticated, else it redirects the client 
towards the CAS-server SSO login URL.

If the login succeeds, the CAS-Server will redirect the client towards the 
first requested path including a 'ticket' as URL parameter. This triggers the C<auth_cas>
a second time, where it validates the 'ticket' against the CAS-Server. If the service ticket
validation fails, it will redirect the client towards the C<cas_denied_path> URL.

Once the ticket validation has been done, the server includes user attributes 
in its reponse to the Dancer application. These user attributes are stored as a HashRef in
a C<session> key (see C<cas_user_map>). These attributes can be renamed/mapped towards
your own keys with the C<cas_attr_map> option.

Parameters:

=over 4

=item * C<ticket> (optional)

If you want to extract the CAS ticket yourself, then you can forward it explicitly with this parameter.

=item * C<cas_denied_path> (optional)

See C<cas_denied_path> in the configuration section.

=item * C<cas_user_map> (optional)

See C<cas_user_map> in the configuration section.

=back

=head1 AUTHOR

Jean Stebens, C<< <cpan.helba at recursor.net> >>

=head1 BUGS

Please report any bugs or feature requests at L<https://github.com/corecache/Dancer-Plugin-Auth-CAS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Auth::CAS


You can also look for information at: L<https://github.com/corecache/Dancer-Plugin-Auth-CAS>

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2014 Jean Stebens.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


package Catalyst::Authentication::Credential::Facebook;

use strict;
use warnings;
use base qw( Class::Accessor::Fast );
use Data::Dumper;

BEGIN {
    __PACKAGE__->mk_accessors(qw/_facebook/);
}

our $VERSION = "0.01";

use Catalyst::Exception ();
use WWW::Facebook::API;

sub new {
    my ($class, $config, $c, $realm) = @_;
    my $self = {};
    bless $self, $class;

    # Hack to make lookup of the configuration parameters less painful
    my $params = { %{ $config }, %{ $realm->{config} } };

    # Create a WWW::Facebook::API instance
    $self->_facebook(
		WWW::Facebook::API->new(
			'desktop'	=> 0,
			'format'	=> 'JSON',
			'parse'		=> 1,
			%{ $c->config->{'facebook'} || { } },
		)
	);

    return $self;
}

sub authenticate {
    my ( $self, $c, $realm, $authinfo ) = @_;

	$self->_facebook->query( $c->request );

	# get facebook_id if there is one
	my $fb_user = $self->_facebook->canvas->get_fb_params();
	$c->log->debug('facebook_id from facebook: '.$fb_user->{'user'});

	if (!$authinfo || $fb_user->{'user'} && !$authinfo->{'facebook_id'}) { $authinfo->{'facebook_id'} = $fb_user->{'user'}; }

	if ( $authinfo->{'facebook_id'} ) {
		my $user_obj = $realm->find_user($authinfo, $c);

		if (ref $user_obj) {
			return $user_obj;
		}
	}

    return undef;
}
    
=head1 NAME

Catalyst::Authentication::Credential::Facebook - Facebook authentication for Catalyst

=head1 SYNOPSIS

In MyApp.pm

 use Catalyst qw/
    Authentication
    Session
    Session::Store::FastMmap
    Session::State::Cookie
	Facebook
 /;
 
 MyApp->config(
     "Plugin::Authentication" => {
         default_realm => "facebook",
         realms => {
             'facebook' => {
                 credential => {
                     class => "Facebook",
                 },
             },
         },
     },
 );

And then in your Controller:

 sub login : Local {
    my ($self, $c) = @_;
   
	if (my $user = $c->authenticate(undef,'facebook')) {
		# user is logged in - redirect or do something
	}
	else {
		# user has no account in your system
		# detect Facebook credentials and create an account
		# or do comething else
	} 
 }

=head1 DESCRIPTION

This module handles Facebook Platform authentication in a Catalyst application.

=head1 METHODS

As per guidelines of L<Catalyst::Plugin::Authentication>, there are two
mandatory methods, C<new> and C<authenticate>.

=head2 new()

Will not be called by you directly, but will use the configuration you
provide (see above). WWW::Facebook::API is required, but we also suggest you install Catalyst::Plugin::Facebook for ultimate Facebook integration after the user is authenticated.

=head2 authenticate( )

Handles the authentication. Nothing more, nothing less. It returns
a L<Catalyst::Authentication::User::Hash> (this is a user object from your database - the user table should have a column called "facebook_id", which the authenticated Facebook user is checked against)

=head1 AUTHOR

Jesse Stay
E<lt>jesse@staynalive.comE<gt>
L<http://staynalive.com>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Catalyst::Plugin::Authentication>, L<WWW::Facebook::API>

=head1 BUGS

C<Bugs? Impossible!>. Please report bugs to L<http://rt.cpan.org/Ticket/Create.html?Queue=Catalyst-Authentication-Credential-Facebook>

=head1 THANKS

Special thanks to David Romano and Clayton Scott for writing and maintaining WWW::Facebook::API

=cut

1;

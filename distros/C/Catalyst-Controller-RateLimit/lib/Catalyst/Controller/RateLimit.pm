package Catalyst::Controller::RateLimit;
use strict;
use warnings;
use parent 'Catalyst::Controller';
use Algorithm::FloodControl ();
use Carp qw/croak/;
use 5.008007;

# $Id: RateLimit.pm 23 2008-11-06 07:54:40Z gugu $
# $Source$
# $HeadURL: file:///var/svn/cps/trunk/lib/Catalyst/Controller/RateLimit.pm $

=head1 NAME

Catalyst::Controller::RateLimit - Protect your site from robots

=head1 VERSION

See $VERSION

=cut

our $VERSION = 0.28;

=head1 SYNOPSIS

Protects your site from flood, robots and spam.

    package MyApp::Controller::Post;
    use parent qw/Catalyst::Controller::RateLimit Catalyst::Controller/; 
        # Catalyst::Controller is not required, but i think, it will look better if you include it
    __PACKAGE__->config(
        rate_limit_backend_name => 'Cache::Memcached::Fast', 
        # ^- Optional. Only if your module is not Cache::Memcached::Fast child, but has the same behavior.
        rate_limit => {
            default => [
                {
                    attempts => 30,
                    period => 3600,
                }, {
                    attempts => 5,
                    period => 60,
                }
            ]
        }
    );

    sub login_form : Local { #Only check
        my ( $self, $c ) = @_;
        my $is_overrated = $self->flood_control->is_user_overrated( $c->user->login || $c->request->address );
        if ( $is_overrated ) {
            $c->forward( 'show_captcha' );
        }
        #...
    }

    sub login : Local { #Check and register attempt
        my ( $self, $c ) = @_;
        if ( $self->flood_control->register_attempt( $c->user->login || $c->request->address ) ) {
            # checking for CAPTCHA
        }
        #...
    }

    sub show_captcha : Local { # If user have reached his limits, it is called
        ... code to add captcha to page ...
    }

=head1 DESCRIPTION

Protects critical parts of your site from robots.

=head1 NOTES

=head1 METHODS

=head2 new

=head2 flood_control

Returns Algorithm::FloodControl object.

=cut

sub flood_control {
    my $self = shift;
    if ( ref $self->{rate_limit} eq 'HASH' ) {
        return new Algorithm::FloodControl( 
            $self->{rate_limit_backend_name} ?
                ( backend_name => $self->{rate_limit_backend_name} ) :
                (),
            storage => $self->_application->cache, 
            limits => $self->{rate_limit} 
        );
    }
    return;
}


=head1 AUTHOR

Andrey Kostenko, C<< <andrey at kostenko.name> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-stoprobots at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Controller-RateLimit>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Controller::RateLimit


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Controller-RateLimit>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Controller-RateLimit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Controller-RateLimit>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Controller-RateLimit>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Andrey Kostenko.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


1; # End of Catalyst::Controller::RateLimit

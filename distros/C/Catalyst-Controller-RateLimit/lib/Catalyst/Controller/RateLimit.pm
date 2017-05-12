package Catalyst::Controller::RateLimit;
use strict;
use warnings;
use base 'Catalyst::Controller';
use Params::Validate qw/:all/;
use Catalyst::Controller::RateLimit::Queue;
use Carp qw/croak/;
use 5.008007;

# $Id: RateLimit.pm 17 2008-10-30 14:34:47Z gugu $
# $Source$
# $HeadURL: file:///var/svn/cps/trunk/lib/Catalyst/Controller/RateLimit.pm $

=head1 NAME

Catalyst::Controller::RateLimit - Protect your site from robots

=head1 VERSION

See $VERSION

=cut

our ($VERSION) = sprintf "%.02f", ('$Revision: 17 $' =~ m{ \$Revision: \s+ (\S+) }mx)[0]/100;

=head1 SYNOPSIS

Protects your site from flood, robots and spam.

    package MyApp::Controller::Post;
    use parent qw/Catalyst::Controller::RateLimit Catalyst::Controller/; 
        # Catalyst::Controller is not required, but i think, it will look better if you include it
    __PACKAGE__->config(
        rate_limit => [
            {
                max_requests => 30,
                period => 3600,
                ban_time => 3600
            }, {
                max_requests => 5,
                period => 60,
            }
        ]
    );

    sub login_form : Local { #Only check
        my ( $self, $c ) = @_;
        my $is_overrated = $self->is_user_overrated( $c->user->login || $c->request->address );
        if ( $is_overrated ) {
            $c->forward( 'show_captcha' );
        }
        #...
    }

    sub login : Local { #Check and register attempt
        my ( $self, $c ) = @_;
        if ( $self->register_attempt( $c->user->login || $c->request->address ) ) {
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

=head2 is_user_overrated( identifier )

Returns true if user have reached his limits.

=head2 register_attempt( identifier )

Returns true if user have reached his limits. And increments number of his attempts.

=head2 ACCEPT_CONTEXT

=head2 setup

=cut

sub is_user_overrated {
    my ($self, $identifier) = @_;
    if ( ! $identifier ) {
        croak 'Usage: $self->is_user_overrated( user_identifier )';
    }
    my @configs = @{ $self->{rate_limit} };
    foreach my $config ( @configs ) {
        my $cache = $self->_application->cache;
        my $application_name = ref $self->_application;
        my $prefix = $application_name . '_rc_' . "$identifier|$config->{period}";
        if ( $config->{ban_time} ) {
            if ($cache->get( "${prefix}_id_$identifier" )){
                return 1;
            }
        }
        my $queue = Catalyst::Controller::RateLimit::Queue->new(
            cache => $cache,
            expires => $config->{ period },
            prefix => $prefix
        );
        if ( $queue->size >= $config->{max_requests} ) {
            if ( $config->{ban_time} ) {
                $cache->set( "${prefix}::id::$identifier", 1, $config->{ban_time} );
            }
            return 1;
        }
    }
    return;
}

sub register_attempt {
    my ( $self, $identifier ) = @_;
    if ( ! $identifier ) {
        croak 'Usage: $self->register_attempt( user_identifier )';
    }
    my $is_robot;
    my @configs = @{ $self->{rate_limit} };
    foreach my $config ( @configs ) {
        my $cache = $self->_application->cache;
        my $application_name = ref $self->_application;
        $is_robot = $self->is_user_overrated( $identifier );
        my $prefix = $application_name . '_rc_' . "$identifier|$config->{period}";
        my $queue = Catalyst::Controller::RateLimit::Queue->new(
            cache => $cache,
            expires => $config->{ period },
            prefix => $prefix
        );
        $queue->append( 1 );
    }
    if ( $is_robot ) {
        return 1;
    }
    return;
}

sub new {
    my ( $class, @params )  = @_;
    my $self = $class->NEXT::new( @params );
    my $c = $self->_application;
    if ( ! $c->can( 'cache' ) ) {
        croak "We need some caching plugin to work";
    }
    my $cache = $c->cache;
    foreach my $method ( qw/get set add incr delete/ ) {
        if ( ! $cache->can( $method ) ) {
           croak "Cache plugin does not support method $method. I don't know what to do.";
        }
    }
    return $self;
}

=head1 AUTHOR

Andrey Kostenko, C<< <andrey at kostenko.name> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-stoprobots at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-StopRobots>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::StopRobots


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-StopRobots>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-StopRobots>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-StopRobots>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-StopRobots>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Andrey Kostenko.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Catalyst::Plugin::StopRobots

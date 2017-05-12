package AnyEvent::Campfire;
{
  $AnyEvent::Campfire::VERSION = '0.0.3';
}

# Abstract: Base class of `AnyEvent::Campfire::*`
use Moose;
use namespace::autoclean;

use MIME::Base64;

has 'rooms' => ( is => 'rw' );

has 'token' => (
    is  => 'rw',
    isa => 'Str',
);

has 'account' => (
    is  => 'ro',
    isa => 'Str',
);

has 'authorization' => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

has '_events' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

sub _build_authorization {
    my $auth = 'Basic ' . encode_base64( shift->token . ':x' );
    $auth =~ s/\n//;
    return $auth;
}

sub emit {
    my ( $self, $name ) = ( shift, shift );
    if ( my $s = $self->_events->{$name} ) {
        for my $cb (@$s) {
            $self->$cb(@_) if $cb;
        }
    }
    return $self;
}

sub on {
    my ( $self, $name, $cb ) = @_;
    push @{ $self->{_events}{$name} ||= [] }, $cb;
    return $cb;
}

sub BUILD {
    my $self = shift;

    $self->rooms( [ split( /,/, $self->rooms ) ] );
    return $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AnyEvent::Campfire

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

    package AnyEvent::Campfire::Foo;
    use Moose;
    extends 'AnyEvent::Campfire';

    ## now this has `token`, `rooms`, `account` attributes.
    ## and `emit`, `on` methods.
    1;

=head1 DESCRIPTION

L<http://campfirenow.com/> API required C<token> to `authorization`.
you can check it out on L<https://E<lt>usernameE<gt>.campfirenow.com/member/edit>.

=head2 ATTRIBUTES

=over

=item token

API authentication token - get it via L<http://campfirenow.com/>

=item rooms

describe campfire chat rooms separated by comma - C<,>.

=item account

signin account

=back

=head2 METHODS

=over

=item on

to subscribe event using C<on>.

    # call `on` with `event name` and `callback`.
    $campfire->on('event-name', sub {
        my ($self, @args) = @_;
    });

=item emit

you can C<emit> the subscribed events.

    # emit subscribed events.
    $campfire->emit('event-name', $arg1, $arg2, ...);

=back

=head1 SEE ALSO

=over

=item L<https://github.com/37signals/campfire-api>

=back

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

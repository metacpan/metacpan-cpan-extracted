package HTML::FormFu::Plugin::RequestToken;

use strict;

our $VERSION = '2.04'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Moose;
use MooseX::Attribute::Chained;
extends 'HTML::FormFu::Plugin';

has context         => ( is => 'rw', traits  => ['Chained'] );
has field_name      => ( is => 'rw', traits  => ['Chained'] );
has session_key     => ( is => 'rw', traits  => ['Chained'] );
has expiration_time => ( is => 'rw', traits  => ['Chained'] );

sub process {
    my ($self) = @_;

    return if $self->form->get_all_element( { name => $self->field_name } );

    my $c = $self->form->stash->{'context'};

    $self->form->elements(
        [   {   type            => 'RequestToken',
                name            => $self->field_name,
                expiration_time => $self->expiration_time,
                context         => $self->context,
                session_key     => $self->session_key
            }
        ]
    );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Plugin::RequestToken

=head1 VERSION

version 2.04

=head1 AUTHORS

=over 4

=item *

Carl Franks <cpan@fireartist.com>

=item *

Nigel Metheringham <nigelm@cpan.org>

=item *

Dean Hamstead <dean@bytefoundry.com.au>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007-2018 by Carl Franks / Nigel Metheringham / Dean Hamstead.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

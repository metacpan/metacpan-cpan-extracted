package HTML::FormFu::Constraint::RequestToken;

use strict;

our $VERSION = '2.04'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Moose;

extends 'HTML::FormFu::Constraint';

sub BUILD {
    my ( $self, $args ) = @_;

    $self->message( $self->parent->message );

    return;
}

sub constrain_value {
    my ( $self, $value ) = @_;

    return $self->parent->verify_token($value);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Constraint::RequestToken

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

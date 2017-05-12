package Catalyst::Controller::RequestToken::Action::CreateToken;

use strict;
use warnings;

use base qw(Catalyst::Action);
use MRO::Compat;

sub execute {
    my $self = shift;
    my ( $controller, $c, @args ) = @_;

    $controller->create_token($c);
    return $self->next::method(@_);
}

1;

__END__

=head1 NAME

Catalyst::Controller::RequestToken::Action::CreateToken

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 INTERNAL METHODS

=over 4

=item execute

=back

=head1 SEE ALSO

L<Catalyst::Controller::RequestToken>
L<Catalyst>
L<Catalyst::Action>

=head1 AUTHOR

Hideo Kimura C<< <<hide<at>hide-k.net>> >>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut


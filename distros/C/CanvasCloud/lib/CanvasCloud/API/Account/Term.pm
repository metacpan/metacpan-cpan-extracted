package CanvasCloud::API::Account::Term;
$CanvasCloud::API::Account::Term::VERSION = '0.005';
# ABSTRACT: extends L<CanvasCloud::API::Account>

use Moose;
use namespace::autoclean;

extends 'CanvasCloud::API::Account';


augment 'uri' => sub { return '/terms'; };


sub list {
    my $self = shift;
    return $self->send( $self->request( 'GET', $self->uri ) );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CanvasCloud::API::Account::Term - extends L<CanvasCloud::API::Account>

=head1 VERSION

version 0.005

=head1 ATTRIBUTES

=head2 uri

augments base uri to append '/terms'

=head1 METHODS

=head2 list

return data object response from GET ->uri

=head1 AUTHOR

Ted Katseres

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ted Katseres.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

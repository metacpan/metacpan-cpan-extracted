package CanvasCloud::API::Users::MissingSubmissions;
$CanvasCloud::API::Users::MissingSubmissions::VERSION = '0.007';
# ABSTRACT: extends L<CanvasCloud::API::Users>

use Moose;
use namespace::autoclean;

extends 'CanvasCloud::API::Users';


augment 'uri' => sub { return '/missing_submissions'; };


sub list {
    my $self = shift;
    my $hash = shift || {};
    my $url = $self->uri;
    my ( $filter, $include );
    if ( exists $hash->{include} ) {
        $include = 'course' if ( $hash->{include} eq 'course' );
        $include = 'planner_overrides' if ( $hash->{include} eq 'planner_overrides' );
    }
    if ( exists $hash->{filter} ) {
        $filter = 'submittable' if ( $hash->{filter} eq 'submittable' );
    }
    if ( $filter || $include ) {
        $url .= '?' . ( $filter ? 'filter[]='.$filter : '' ) . ( $include ? 'include[]='.$include : '' );
    }
    
    return $self->send( $self->request( 'GET',  $url ) );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CanvasCloud::API::Users::MissingSubmissions - extends L<CanvasCloud::API::Users>

=head1 VERSION

version 0.007

=head1 ATTRIBUTES

=head2 uri

augments base uri to append '/missing_submissions'

=head1 METHODS

=head2 list

return data object response from GET ->uri

=head1 AUTHOR

Ted Katseres

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Ted Katseres.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

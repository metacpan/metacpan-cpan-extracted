package CanvasCloud::API::Account::Report;
$CanvasCloud::API::Account::Report::VERSION = '0.002';
# ABSTRACT: extends L<CanvasCloud::API::Account>

use Moose;
use namespace::autoclean;

extends 'CanvasCloud::API::Account';


augment 'uri' => sub { return '/reports'; };


sub list {
    my $self = shift;
    return $self->send( $self->request( 'GET', $self->uri ) );
}


sub check {
    my ( $self, $report, $report_id ) = @_;
    return $self->send( $self->request( 'GET', join( '/', $self->uri, $report, $report_id ) ) );
}


sub run {
    my ( $self, $report, $args ) = @_;

    my $r  = $self->request( 'POST', join( '/', $self->uri, $report ) );

    ## Process Args
    if ( defined $args && ref( $args ) eq 'HASH' ) {
        my $struct = {};

        if ( exists $args->{term_id} && defined $args->{term_id} ) {
            my $term_id = $args->{term_id} + 0;
            die 'Illegal Term '.$term_id if ( $term_id < 0 );
            $struct->{'parameters[enrollment_term_id]'} = $term_id;
        }

        $r->content( $self->encode_url( $struct ) );
    }

    return $self->send( $r );
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CanvasCloud::API::Account::Report - extends L<CanvasCloud::API::Account>

=head1 VERSION

version 0.002

=head1 ATTRIBUTES

=head2 uri

augments base uri to append '/reports'

=head1 METHODS

=head2 list

return data object response from GET ->uri

=head2 check( $report, $report_id )

return data object response from GET ->uri / $report / $report_id 

=head2 run( $report, { term_id => 1 } )

return data object response from POST ->uri / $report

arguments are POST'ed

=head1 AUTHOR

Ted Katseres

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ted Katseres.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

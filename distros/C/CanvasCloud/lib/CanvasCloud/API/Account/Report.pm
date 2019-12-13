package CanvasCloud::API::Account::Report;
$CanvasCloud::API::Account::Report::VERSION = '0.007';
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
        $r->content( $self->encode_url( { map { $_ => $args->{$_} } keys %$args } ) );
    }

    return $self->send( $r );
}



sub get {
    my ( $self, $report, $args ) = @_;

    my $result = $self->run( $report, $args );
    
    while ( $result->{status} =~ m/(running|created|compiling)/ ) {
        sleep 10; 
        $result = $self->check( $report, $result->{id} );
        #warn $result->{status};
    }

    if ( exists $result->{attachment} && exists $result->{attachment}{url} ) {
        my $resp;
        my $attempts = 3;
        while ( $attempts > 0 ) {
           $resp = $self->ua->get( $result->{attachment}{url} ); ## Download report without using class specific headers
           if ( $resp->is_success ) {
               $attempts = 0;
           } else {
               sleep 20; ## sleep 20 seconds and try again
               $attempts--;
           }
        }
        die $resp->status_line unless ( $resp->is_success );
        return $resp->decoded_content( charset => 'none' );
    }
    warn sprintf('Report->get ASSERT: id(%s) returned last status (%s)', $result->{id}, $result->{status} );
    return undef; ## never should but nothing would be retured
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CanvasCloud::API::Account::Report - extends L<CanvasCloud::API::Account>

=head1 VERSION

version 0.007

=head1 ATTRIBUTES

=head2 uri

augments base uri to append '/reports'

=head1 METHODS

=head2 list

return data object response from GET ->uri

=head2 check( $report, $report_id )

return data object response from GET ->uri / $report / $report_id 

=head2 run( $report, { 'parameters[enrollment_term_id]' => 1 } )

return data object response from POST ->uri / $report

arguments are POST'ed

  note(*): Most arguments will be in the form of parameters[named_argument_for_report] = "value"

=head2 get( $report, { 'parameters[enrollment_term_id]' => 1 } )

perform the self->run( ... ) && self->check( ... ) until report is finished returning the text.

=head1 AUTHOR

Ted Katseres

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Ted Katseres.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

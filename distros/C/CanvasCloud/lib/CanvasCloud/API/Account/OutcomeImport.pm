package CanvasCloud::API::Account::OutcomeImport;
$CanvasCloud::API::Account::OutcomeImport::VERSION = '0.007';
# ABSTRACT: extends L<CanvasCloud::API::Account>

use Moose;
use namespace::autoclean;

extends 'CanvasCloud::API::Account';


augment 'uri' => sub { return '/outcome_imports'; };


sub sendcsv {
    my ( $self, $file_or_string ) = @_;
    my $text;
    if ( -f $file_or_string ) {
        open( my $ZF, '<', $file_or_string ) or die sprintf( 'cannot open input file {%s} error {%s}', $file_or_string, $! );
        binmode $ZF;
        while (<$ZF>) { $text .= $_; }
        close $ZF;
    }
    else {
        $text = $file_or_string;
    }
    my $r = $self->request( 'POST', $self->uri . '?import_type=instructure_csv&extension=csv' );
    $r->content_type( 'text/csv' );
    $r->content("$text");
    return $self->send( $r );
}


sub status {
    my $self = shift;
    my $id   = shift || die 'id must be given!';
    return $self->send( $self->request( 'GET', $self->uri . '/' . $id  ) );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CanvasCloud::API::Account::OutcomeImport - extends L<CanvasCloud::API::Account>

=head1 VERSION

version 0.007

=head1 ATTRIBUTES

=head2 uri

augments base uri to append '/outcome_imports'

=head1 METHODS

=head2 sendcsv( $csvfile )

return data object response from POST ->uri / $csvfile

=head2 csvstatus

get sendfile status as GET ->uri/$id.json

=head1 AUTHOR

Ted Katseres

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Ted Katseres.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Data::AnyXfer::Elastic::Role::Importer_ES2;

use Carp;
use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);

=head1 NAME

Data::AnyXfer::Elastic::Role::Importer_ES2 - Role for Importing ES
datafiles (ES 2.3.5 Support)

=head1 DESCRIPTION

This role is used by
L<Data::AnyXfer::Elastic::Importer> to help play datafiles to ES 2.3.5

=head1 SEE ALSO

L<Data::AnyXfer::Elastic::Importer>

L<Data::AnyXfer::Elastic>

L<Data::AnyXfer::Elastic::IndexInfo>

=cut


sub convert_document_for_es2 {

    my ( $self, $document ) = @_;

    my $autocomplete = $document->{autocomplete};

    for my $data (
        ref $autocomplete eq 'ARRAY' ? @{$autocomplete} : $autocomplete )
    {
        # XXX : convert suggest structure to support ES 2.3.5
        if ( my $suggest = $data->{suggest} ) {

            if ( ref $suggest eq 'HASH' ) {

                # we want an output as well as input, so copy it
                $suggest->{output} = $suggest->{input};
                
                # we turn on payloads by default in IndexInfo_ES2, so it is
                # safe to use centre_geo_point as an automatic lat/lon payload
                if ( my $geo_point = $data->{centre_geo_point}
                    || $document->{location} )
                {
                    $suggest->{payload} = {
                        lat => $geo_point->{lat},
                        lon => $geo_point->{lon},
                    };
                }
            }
        }
    }
}



1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut


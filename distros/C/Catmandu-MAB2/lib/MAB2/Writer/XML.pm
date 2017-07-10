package MAB2::Writer::XML;

our $VERSION = '0.19';

use strict;
use Moo;
with 'MAB2::Writer::Handle';

has xml_declaration => ( is => 'ro' , default => sub {0} );
has collection      => ( is => 'ro' , default => sub {0} );


sub start {
    my ($self) = @_;

    print { $self->fh } "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" if $self->xml_declaration;
    print { $self->fh }
        "<datei xmlns=\"http://www.ddb.de/professionell/mabxml/mabxml-1.xsd\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.ddb.de/professionell/mabxml/mabxml-1.xsd http://www.d-nb.de/standardisierung/formate/mabxml-1.xsd\">\n" if $self->collection;
}


sub _write_record {
    my ( $self, $record ) = @_;
    my $fh = $self->fh;

    if ( $record->[0][0] eq 'LDR' ) {
        my $leader = $record->[0];
        my ( $status, $typ ) = ( $1, $2 )
            if $leader->[3] =~ /^\d{5}(\w)M2\.0\d*\s*(\w)$/;
        print $fh
            "<datensatz typ=\"$typ\" status=\"$status\" mabVersion=\"M2.0\">\n";
    }
    else {
        # default to typ and status
        print $fh "<datensatz typ=\"h\" status=\"n\" mabVersion=\"M2.0\">\n";
    }

    foreach my $field (@$record) {

        next if $field->[0] eq 'LDR';
        if ( $field->[2] eq '_' ) {
            print $fh
                "<feld nr=\"$field->[0]\" ind=\"$field->[1]\">$field->[3]</feld>\n";
        }
        else {
            print $fh "<feld nr=\"$field->[0]\" ind=\"$field->[1]\">\n";
            for ( my $i = 2; $i < scalar @$field; $i += 2 ) {
                my $value = $field->[ $i + 1 ];
                print $fh "    <uf code=\"$field->[$i]\">$value</uf>\n";
            }
            print $fh "</feld>\n";
        }
    }
    print $fh "</datensatz>\n";
}


sub end {
    my ($self) = @_;

    print { $self->fh } "</datei>\n" if $self->collection;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MAB2::Writer::XML - MAB2 XML format serializer

=head1 SYNOPSIS

L<MAB2::Writer::XML> is a MAB2 XML serializer.

    use MAB2::Writer::XML;

    my @mab_records = (
        [
          ['001', ' ', '_', '2415107-5'],
          ['331', ' ', '_', 'Code4Lib journal'],
          ['655', 'e', 'u', 'http://journal.code4lib.org/', 'z', 'kostenfrei'],
          ...
        ],
        {
          record => [
              ['001', ' ', '_', '2415107-5'],
              ['331', ' ', '_', 'Code4Lib journal'],
              ['655', 'e', 'u', 'http://journal.code4lib.org/', 'z', 'kostenfrei'],
              ...
          ]
        }
    );

    my $writer = MAB2::Writer::XML->new( fh => $fh, xml_declaration => 1, collection => 1 );
    
    $writer->start();

    foreach my $record (@mab_records) {
        $writer->write($record);
    }

    $writer->end();

=head1 Arguments

=over

=item C<xml_declaration>

Write XML declaration. Set to 0 or 1. Default: 0. Optional.

=item C<collection>

Wrap records in collection element (<datei>). Set to 0 or 1. Default: 0. Optional.

=back

See also L<MAB2::Writer::Handle>.

=head1 METHODS

=head2 new(file => $file | fh => $fh [, xml_declaration => 1, collection => 1, encoding => 'UTF-8'])

=head2 start()

Writes XML declaration and/or start element for a collection.

=head2 _write_record()

=head2 end()

Writes end element for the collection.

=head1 SEEALSO

L<MAB2::Writer::Handle>, L<Catmandu::Exporter>.

=head1 AUTHOR

Johann Rolschewski <jorol@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Johann Rolschewski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

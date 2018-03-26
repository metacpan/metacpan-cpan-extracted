package Catmandu::Importer::SRU::Parser::picaxml;
use strict;
use Moo;

sub parse {
	my ($self, $record) = @_;

    my $pica = $record->{recordData};

    my @record;
    my $id = undef;

    for my $field ($pica->getChildrenByLocalName('datafield')) {
        my $tag = $field->getAttribute('tag');
        my $occ = $field->getAttribute('occurrence');
        my @subfields = ();
        for my $subfield ($field->getChildrenByLocalName('subfield')) {
            my $code  = $subfield->getAttribute('code');
            my $value = $subfield->textContent;
            push @subfields, $code, $value;
			$id = $value if $tag eq '003@' and $code eq '0';
        }
        push @record, [$tag, $occ, @subfields];
    }

    return {_id => $id, record => \@record};
}

1;
__END__

=head1 NAME

Catmandu::Importer::SRU::Parser::picaxml - parse SRU records containing PICAXML

=head1 SYNOPSIS

This SRU record parser (see L<Catmandu::Importer::SRU>) parses the SRU response
record field C<recordData> as L<PICA XML|http://format.gbv.de/pica/xml> format and
returns L<PICA JSON|http://format.gbv.de/pica/json> structure as also implemented by
L<Catmandu::Importer::PICA>.

No validation is applied and namespaces definitions are just ignored, so importing
other XML formats with this parser may result in strange records.

=head1 AUTHOR

Jakob Voss C<< voss@gbv.de >>

=encoding utf8

=cut

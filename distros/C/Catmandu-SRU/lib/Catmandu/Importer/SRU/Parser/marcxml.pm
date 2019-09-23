package Catmandu::Importer::SRU::Parser::marcxml;

use Moo;
use XML::LibXML;

our $VERSION = '0.425';

sub parse {
    my ($self, $record) = @_;

    my $marc = $record->{recordData};

    my @out;
    my $id = undef;

    for my $field ($marc->getChildrenByLocalName('*')) {
        my $name  = $field->localname;
        my $value = $field->textContent // '';
        if ($name eq 'leader') {
            push @out, ['LDR', ' ', ' ', '_', $value];
        }
        elsif ($name eq 'controlfield') {
            my $tag = $field->getAttribute('tag');
            push @out, [$tag, ' ', ' ', '_', $value];
            $id = $value if $tag eq '001';
        }
        elsif ($name eq 'datafield') {
            my $tag      = $field->getAttribute('tag');
            my $ind1     = $field->getAttribute('ind1') // ' ';
            my $ind2     = $field->getAttribute('ind2') // ' ';
            my @subfield = ();
            for my $subfield ($field->getChildrenByLocalName('subfield')) {
                my $code  = $subfield->getAttribute('code');
                my $value = $subfield->textContent;
                push @subfield, $code, $value;
            }
            push @out, [$tag, $ind1, $ind2, @subfield];
        }
    }

    return {_id => $id, record => \@out};
}

1;
__END__

=head1 NAME

Catmandu::Importer::SRU::Parser::marcxml - Package transforms SRU responses into Catmandu MARC

=head1 SYNOPSIS

  my $importer = Catmandu::Importer::SRU->new(
    base => 'http://www.unicat.be/sru',
    query => '(isbn=0855275103 or isbn=3110035170 or isbn=9010017362 or isbn=9014026188)',
    recordSchema => 'marcxml',
    parser => 'marcxml',
  );

=head1 DESCRIPTION

Each MARCXML response will be transformed into an format as defined by L<Catmandu::Importer::MARC>

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=cut

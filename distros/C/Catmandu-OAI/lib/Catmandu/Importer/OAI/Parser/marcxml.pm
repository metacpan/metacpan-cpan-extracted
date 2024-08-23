package Catmandu::Importer::OAI::Parser::marcxml;

use Catmandu::Sane;
use Moo;

our $VERSION = '0.21';

sub parse {
    my ($self,$dom) = @_;

    return undef unless defined $dom;

    my @out;
    my $id = undef;

    # Read in the collection tag if available
    if ($dom->localname eq 'collection') {
      $dom = $dom->firstChild;
    }

    for my $field ($dom->getChildrenByLocalName('*')) {
        my $name  = $field->localname;
        my $value = $field->textContent // '';
        if ($name eq 'leader') {
            push @out, [ 'LDR', ' ', ' ', '_', $value ];
        }
        elsif ($name eq 'controlfield') {
            my $tag = $field->getAttribute( 'tag' );
            push @out, [ $tag, ' ', ' ', '_', $value ];
             $id = $value if $tag eq '001';
        }
        elsif ( $name eq 'datafield' ) {
            my $tag  = $field->getAttribute( 'tag' );
            my $ind1 = $field->getAttribute( 'ind1' ) // ' ';
            my $ind2 = $field->getAttribute( 'ind2' ) // ' ';
            my @subfield = ();
            for my $subfield ( $field->getChildrenByLocalName('subfield') ) {
                  my $code = $subfield->getAttribute( 'code' );
                  my $value = $subfield->textContent;
                  push @subfield, $code, $value;
            }
            push @out, [ $tag, $ind1, $ind2, @subfield ];
        }
     }

     return { _id => $id , record => \@out };
}

1;

package Catmandu::Fix::xml_transform;

our $VERSION = '0.17';

use Catmandu::Sane;
use Moo;
use Catmandu::Fix::Has;
use Catmandu::XML::Transformer;

with 'Catmandu::Fix::Base';

has field   => (fix_arg => 1);
has file    => (fix_opt => 1);
has format  => (fix_opt => 1);

has _transformer => (
    is => 'ro',
    lazy => 1,
    default => sub {
        Catmandu::XML::Transformer->new( 
            stylesheet => $_[0]->file,
            output_format => $_[0]->format,
        );
    }
);

sub emit {    
    my ($self,$fixer) = @_;    

    my $path = $fixer->split_path($self->field());
    my $key = pop @$path;
    
    my $transformer = $fixer->capture($self->_transformer); 

    return $fixer->emit_walk_path($fixer->var,$path,sub{
        my $var = $_[0];     
        $fixer->emit_get_key($var,$key,sub{
            my $var = $_[0];
            return "${var} = ${transformer}->transform(${var});";
        });
    });
}

1;
__END__

=head1 NAME

Catmandu::Fix::xml_transform - transform XML using XSLT stylesheet

=head1 SYNOPSIS
     
  # Transforms the 'xml' from marcxml to dublin core xml
  xml_transform('xml',file => 'marcxml2dc.xsl');

=head1 DESCRIPTION

This L<Catmandu::Fix> transforms XML with an XSLT stylesheet. Based on
L<Catmandu::XML::Transformer> the fix will transform and XML string into an XML
string, MicroXML (L<XML::Struct>) into MicroXML, and a DOM into a DOM. If the
stylesheet is intented to emit text (C<<  <xsl:output method="text"/> >>,
however, this fix I<always> transforms produces a string.

One ore multiple XSLT scripts can be specified with argument C<file>.

=head1 CONFIGURATION

=over

=item field

Data field to get XML from

=item file

One or more file names of optional XSLT scripts

=item format

Optional output format (C<string>, C<struct>, C<simple>, or C<dom>)

=back

=cut

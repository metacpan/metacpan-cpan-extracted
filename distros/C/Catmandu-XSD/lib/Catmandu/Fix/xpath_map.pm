package Catmandu::Fix::xpath_map;

use Catmandu::Sane;
use XML::LibXML::XPathContext;
use Moo;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

our $VERSION = '0.05';

has old_path   => (fix_arg => 1);
has xpath      => (fix_arg => 1);
has new_path   => (fix_arg => 1);
has namespaces => (fix_opt => 'collect');

sub emit {
    my ($self, $fixer) = @_;

    my $old_path    = $fixer->split_path($self->old_path);
    my $old_key     = pop @$old_path;
    my $new_path    = $fixer->split_path($self->new_path);
    my $xpath       = $fixer->capture($self->xpath);

    my $vals        = $fixer->generate_var;
    my $current_val = $fixer->generate_var;
    my $perl        = "";
    $perl .= $fixer->emit_declare_vars($vals, '[]');
    $perl .= $fixer->emit_declare_vars($current_val);

    $perl .= $fixer->emit_walk_path(
        $fixer->var,
        $old_path,
        sub {
            my $var = shift;
            $fixer->emit_get_key(
                $var, $old_key,
                sub {
                    my $var = shift;
                    "push(\@{${vals}}, ${var});";
                }
            );
        }
    );

    my $my_self = $fixer->capture($self);

    $perl
        .= "while (\@{${vals}}) {"
        . "${current_val} = ${my_self}->xpath_map(shift(\@{${vals}}),${xpath});"
        . $fixer->emit_create_path(
        $fixer->var,
        $new_path,
        sub {
            my $var = shift;
            "${var} = ${current_val};";
        }
        ) . "}";

    $perl;
}

sub xpath_map {
    my ($self, $data, $xpath) = @_;

    unless (ref($data) =~ /^XML::LibXML/) {
        my ($key) = keys %$data;
        $data  = $data->{$key}->[0];
    }

    my $xc = XML::LibXML::XPathContext->new($data);

    if ($self->namespaces) {
        for (keys %{$self->namespaces}) {
            $xc->registerNs($_,$self->namespaces->{$_});
        }
    }

    $xc->findvalue($xpath);
}

1;

__END__

=pod

=head1 NAME

Catmandu::Fix::xpath_map - map values from a XML::LibXML::Element value to a field

=head1 SYNOPSIS

   #   <mets:dmdSec ID="dmd1">
   #    <mets:mdWrap MDTYPE="MODS">
   #     <mets:xmlData>
   #      <mods:mods xmlns:mods="http://www.loc.gov/mods/v3" ID="mods1" version="3.4">
   #        <mods:titleInfo>
   #         <mods:title>Alabama blues</mods:title>
   #        </mods:titleInfo>
   #      </mods:mods>
   #     </mets:xmlData>
   #    </mets:mdWrap>
   #   </mets:dmdSec>

   # The dmdSec.0.mdWrap.xmlData contains a XML::LibXML::Element
   # Map the value of the 'mods:titleInfo/mods:title' XPath to
   # a new field 'my_new_field'.
   # Optionally provide one or more namespace mappings to use
   xpath_map(
       dmdSec.0.mdWrap.xmlData,
       'mods:titleInfo/mods:title',
       my_new_field,
       -mods:'http://www.loc.gov/mods/v3'
   )

   # Result:
   #
   # 'my_new_field' => 'Alabama blues'

=head1 DESCRIPTION

Not all XML fields in an XML Schema can be mapped to a Perl Hash using Catmandu::XSD.
Especially <any> fields in a schema, which can contain any type of XML are problematic.
These fields are mapped into a blessed XML::LibXML::Element object. Using the
C<xpath_map> Fix, on can access these blessed objects and extract data from it
using XPaths.

=head1 METHOD

=head2 xpath_map(xml_field, xpath, new_field [, namespace-prefix:namespace-url [,...]])

Map an XML field at C<xml_field> to C<new_field> using an XPath expresssion C<xpath>.

=head1 SEE ALSO

L<Catmandu::Fix>

=head1 AUTHOR

Patrick Hochstenbach , C<< patrick.hochstenbach at ugent.be >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

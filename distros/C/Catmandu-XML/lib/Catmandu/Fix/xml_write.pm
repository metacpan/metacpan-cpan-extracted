package Catmandu::Fix::xml_write;

our $VERSION = '0.17';

use Catmandu::Sane;
use Moo;
use XML::Struct::Writer;
use XML::LibXML::Reader;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

has field      => (fix_arg => 1);
has attributes => (fix_opt => 1); 
has pretty     => (fix_opt => 1);
has encoding   => (fix_opt => 1, default => sub { 'UTF-8' });
has version    => (fix_opt => 1);
has standalone => (fix_opt => 1);
has xmldecl    => (fix_opt => 1, default => sub { 1 });

has _writer => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        XML::Struct::Writer->new(
            map { $_ => $_[0]->$_ } grep { defined $_[0]->$_ }
            qw(attributes pretty encoding version standalone xmldecl)
        );
    }
);

sub emit {    
    my ($self,$fixer) = @_;    

    my $path = $fixer->split_path($self->field);
    my $key = pop @$path;
    
    my $writer = $fixer->capture($self->_writer); 
    my $pretty = $fixer->capture($self->pretty); 

    return $fixer->emit_walk_path($fixer->var,$path,sub{
        my $var = $_[0];     
        $fixer->emit_get_key($var,$key,sub{
            my $var = $_[0];
            return "${var} = (ref(${var}) =~ 'XML::LibXML::Document=')" .
                   "? ${var}->serialize(${pretty}) : do {".
                       "my \$s=''; ${writer}->to(\\\$s); ${writer}->write(${var}); \$s" .
                   "}";
        });
    });
}

1;
__END__

=head1 NAME

Catmandu::Fix::xml_write - serialize XML

=head1 SYNOPSIS
     
  # serialize XML structure given in field 'xml' 
  xml_write(xml)
  xml_write(xml, pretty: 1)

=head1 DESCRIPTION

This L<Catmandu::Fix> serializes XML documents (given in MicroXML form
as used by L<XML::Struct> or as instance of L<XML::LibXML::Document>).
In short, this is a wrapper around L<XML::Struct::Writer>.

=head1 CONFIGURATION

=over

=item attributes

Set to false to not expect attribute hashes in the XML structure.

=item pretty

Pretty-print XML if set to C<1>.

=item xmldecl

=item version

=item encoding

=item standalone

=back

=head1 SEE ALSO

L<Catmandu::Fix::xml_read>

=cut

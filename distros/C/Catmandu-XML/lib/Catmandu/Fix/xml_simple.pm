package Catmandu::Fix::xml_simple;

our $VERSION = '0.17';

use Catmandu::Sane;
use Moo;
use XML::Struct::Reader;
use XML::LibXML::Reader;
use Catmandu::Fix::Has;

with 'Catmandu::Fix::Base';

# TODO: avoid code duplication with xml_read

has field      => ( fix_arg => 1 );
has attributes => ( fix_opt => 1 );
has ns         => ( fix_opt => 1 );
has content    => ( fix_opt => 1 );
has root       => ( fix_opt => 1 );
has depth      => ( fix_opt => 1 );
has path       => ( fix_opt => 1 );
has whitespace => ( fix_opt => 1 );

sub simple { 1 }

has _reader => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        XML::Struct::Reader->new(
            map    { $_ => $_[0]->$_ }
              grep { defined $_[0]->$_ }
              qw(attributes ns simple root depth content whitespace)
        );
    }
);

sub emit {
    my ( $self, $fixer ) = @_;

    my $path = $fixer->split_path( $self->field );
    my $key  = pop @$path;

    my $reader     = $fixer->capture( $self->_reader );
    my $xpath      = $fixer->capture( $self->path );
    my $attributes = $fixer->capture( $self->attributes );

    # TODO: use XML::Struct::Simple instead
    my $options = $fixer->capture(
        {
            map  { $_ => $self->$_ }
            grep { defined $self->$_ } qw(root depth attributes)
        }
    );

    return $fixer->emit_walk_path(
        $fixer->var,
        $path,
        sub {
            my $var = $_[0];
            $fixer->emit_get_key(
                $var, $key,
                sub {
                    my $var = $_[0];
                    return <<PERL;
if (ref(${var}) and ref(${var}) =~ /^ARRAY/) {
    ${var} = XML::Struct::simpleXML( ${var}, %{${options}} );
} else {
    # TODO: code duplication with xml_read
    my \$stream = XML::LibXML::Reader->new( string => ${var} );
    ${var} = ${xpath} 
           ? [ ${reader}->readDocument(\$stream, ${xpath}) ]
           : ${reader}->readDocument(\$stream);
}
PERL
                }
            );
        }
    );
}

1;
__END__

=head1 NAME

Catmandu::Fix::xml_simple - parse/convert XML to key-value form

=head1 SYNOPSIS
     
  xml_read(xml)
  xml_simple(xml)

  xml_read(xml, simple=1)  # equivalent

=head1 DESCRIPTION

This L<Catmandu::Fix> transforms MicroXML or parses XML strings to key-value form with L<XML::Struct>.

=head1 OPTIONS

See L<Catmandu::Fix::xml_read> for parsing options.

=cut

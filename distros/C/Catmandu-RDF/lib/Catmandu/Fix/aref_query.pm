package Catmandu::Fix::aref_query;

use Catmandu::Sane;
use Moo;
use Catmandu::Fix;

our $VERSION = '0.31';

with 'Catmandu::Fix::Base';

has query => (
    is => 'ro',
    coerce => sub { RDF::aREF::Query->new( query => $_[0] ) } # TODO: ns
);

has path => (
    is => 'ro',
);

has subject => (
    is => 'ro',
);
 
around 'BUILDARGS', sub {
    my $orig = shift;
    my $self = shift;
 
    if (@_ == 3) {
        $orig->($self, subject => $_[0], query => $_[1], path => $_[2] );
    } elsif (@_ == 2) {
        $orig->($self, query => $_[0], path => $_[1] );
    } else {
        $orig->($self, @_);
    }
};

sub emit {
    my ($self, $fixer) = @_;

    my $subject = defined $self->subject ? $fixer->emit_string($self->subject) : 'undef';
    my $path    = $fixer->split_path($self->path);
    my $query   = $fixer->capture($self->query);

    # TODO: replace/append/single-value mode

    my $var     = $fixer->var;
    my $origin  = $fixer->generate_var;
    my $values  = $fixer->generate_var;

    my $perl = join "\n", 
        "my ${origin} = ${subject} // ${var}->{_uri} // ${var}->{_url};",
        "my ${values} = [ ${query}->apply( ${var}, ${origin} ) ];",
        $fixer->emit_create_path( $var, $path, sub {
            my $var = shift;
            join "\n", map { "  $_" } '', 
                "if (is_array_ref(${var})) {", 
                "  push \@{${var}}, \@{${values}};",
                "} else {",
                "  if (defined ${var}) {",
                "    unshift \@{${values}}, ${var};",
                "  }",
                "  ${var} = \@{${values}} > 1 ? ${values} : ${values}->[0];",
                "}"
            ;
        });

    # print $perl."\n";

    return $perl;
}

1;
__END__

=head1 NAME

Catmandu::Fix::aref_query - copy values of RDF in aREF to a new field

=head1 SYNOPSIS

In Catmandu Fix language

    aref_query( dc_title => title )
    aref_query( query => 'dc_title', field => 'title' )
    aref_query( 'http://example.org/subject', dc_title => title )

In Perl code

    use Catmandu::Fix::aref_query as => 'my_query';
    use RDF::aREF;
    
    my $rdf = encode_aref("example.ttl"); 
    my_query( $rdf, dc_title => 'title' );

=head1 DESCRIPTION

This L<Catmandu::Fix> can be used to map values of imported RDF, given in
L<aREF|http://gbv.github.io/aREF/> structure

=head1 ARGUMENTS

=over

=item subject

Optional subject URI (first argument). By default, the fields C<_uri> and
C<_uri> are used.

=item query

aREF query expression (first or second argument)

=item path

Field name to map RDF data to (last argument). Existing values are also kept.

=back

=head1 SEE ALSO

Function C<aref_query> in L<RDF::aREF>

=cut

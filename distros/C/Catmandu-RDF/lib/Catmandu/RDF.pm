package Catmandu::RDF;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(is_instance);
use Moo::Role;
use RDF::NS;

our $VERSION = '0.32';

our %TYPE_ALIAS = (
    Ttl  => 'Turtle',
    N3   => 'Notation3',
    Xml  => 'RDFXML',
    XML  => 'RDFXML',
    Json => 'RDFJSON',
);

has type => (
    is => 'ro',
    coerce => sub { my $t = ucfirst($_[0]); $TYPE_ALIAS{$t} // $t },
);

has ns => (
    is => 'ro',
    default => sub { RDF::NS->new },
    coerce => sub {
        return $_[0] if is_instance($_[0],'RDF::NS');
        return $_[0] if !$_[0];
        return RDF::NS->new($_[0]);
    },
    handles => ['uri'],
);

1;
__END__

=encoding utf8

=head1 NAME

Catmandu::RDF - Modules for handling RDF data within the Catmandu framework

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-RDF.svg)](https://travis-ci.org/LibreCat/Catmandu-RDF)
[![Coverage Status](https://coveralls.io/repos/LibreCat/Catmandu-RDF/badge.svg)](https://coveralls.io/r/LibreCat/Catmandu-RDF)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Catmandu-RDF.png)](http://cpants.cpanauthors.org/dist/Catmandu-RDF)

=end markdown

=head1 SYNOPSIS

Command line client C<catmandu>:

  catmandu convert RDF --url http://dx.doi.org/10.2474/trol.7.147
                       --fix 'aref_query(dct_title,title)' to YAML

  catmandu convert RDF --file rdfdump.ttl to RDF --type turtle

  # For big file the only efficient option to convert RDF is by
  # transforming the input stream into triples and writing to NTriples
  # in the output
  catmandu convert convert RDF --triples 1 --type ttl to RDF --type NTriples < rdfdump.ttl

See documentation of modules for more examples.

=head1 DESCRIPTION

Catmandu::RDF contains modules for handling RDF data within the L<Catmandu>
framework. RDF data is encoded/decoded in L<aREF|http://gbv.github.io/aREF/> as
implemented with L<RDF::aREF>. Please keep in mind that RDF is a graph-based
data structuring format with specialized technologies such as SPARQL and triple
stores.  Using Catmandu::RDF to transform RDF to RDF (e.g. conversion from one
RDF serialization to another) is possible but probably less performant than
decent RDF tools. Catmandu::RDF, however, is more conventient to convert
between RDF and  other data formats.

=head1 AVAILABLE MODULES

=over

=item L<Catmandu::Exporter::RDF>

Serialize RDF data (as RDF/XML, RDF/JSON, Turtle, NTriples, RDFa...)

=item L<Catmandu::Importer::RDF>

Parse RDF data (RDF/XML, RDF/JSON, Turtle, NTriples...) or import from a SPARQL
endpoint

=item L<Catmandu::Fix::aref_query>

Copy values of RDF data in aREF format to a new field

=back

=head1 SEE ALSO

This module is based on L<Catmandu>, L<RDF::aREF>, L<RDF::Trine>, and
L<RDF::NS>.

=head1 COPYRIGHT AND LICENSE

Copyright Jakob Voß, 2014-

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

Jakob Voß, Patrick Hochstenbach

=cut

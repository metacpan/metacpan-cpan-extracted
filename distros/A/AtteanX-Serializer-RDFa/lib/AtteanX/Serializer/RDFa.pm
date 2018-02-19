package AtteanX::Serializer::RDFa;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.01';

use Moo;
use Types::Standard qw(Str Maybe HashRef ConsumerOf);
use Encode qw(encode);
use Scalar::Util qw(blessed);
use Attean;
use Attean::ListIterator;
use namespace::clean;
use Attean::RDF qw(iri);
use RDF::RDFa::Generator;


has 'canonical_media_type' => (is => 'ro', isa => Str, init_arg => undef, default => 'application/xhtml+xml');

with 'Attean::API::TripleSerializer';
with 'Attean::API::AbbreviatingSerializer';

has 'style' => (is => 'ro', isa => Maybe[Str]); # TODO: might be improved with OptList?

has 'generator_options' => (is => 'ro', isa => HashRef, default => sub { return {} });

has _opts => (is => 'rw', isa => HashRef, lazy => 1, builder => '_build_opts');

sub _build_opts {
  my $self = shift;
  my $base = defined($self->base) ? $self->base->abs : undef;
  my %opts = (
				  style => $self->style,
				  namespacemap => $self->namespaces,
				  base => $base
				 );
  return \%opts;
}


sub media_types {
  return [qw(application/xhtml+xml text/html)];
}

sub _make_document {
  my ($self, $iter) = @_;
  my $store = Attean->get_store('Memory')->new();
  $store->add_iter($iter->as_quads(iri('http://graph.invalid/')));
  my $model = Attean::QuadModel->new( store => $store );
  return RDF::RDFa::Generator->new(%{$self->_opts})->create_document($model, %{$self->generator_options});
}

sub serialize_iter_to_io {
  my ($self, $io, $iter) = @_;
  my $document = $self->_make_document($iter);
  return $document->toFH($io);

}

sub serialize_iter_to_bytes {
  my ($self, $iter) = @_;
  my $document = $self->_make_document($iter);
  return $document->toString;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AtteanX::Serializer::RDFa - RDFa Serializer for Attean

=head1 SYNOPSIS

 use Attean;
 use Attean::RDF qw(iri);
 use URI::NamespaceMap;
 
 my $ser = Attean->get_serializer('RDFa')->new;
 my $string = $ser->serialize_iter_to_bytes($iter);
 
 my $ns = URI::NamespaceMap->new( { ex => iri('http://example.org/') });
 $ns->guess_and_add('foaf');
 my $note = RDF::RDFa::Generator::HTML::Pretty::Note->new(iri('http://example.org/foo'), 'This is a Note');
 my $ser = Attean->get_serializer('RDFa')->new(base => iri('http://example.org/'),
															  namespaces => $ns,
															  style => 'HTML::Pretty',
															  generator_options => { notes => [$note]});
 $ser->serialize_iter_to_io($fh, $iter);



=head1 DESCRIPTION

This module can be used to serialize RDFa with several different
styles. It is implemented using L<Attean> to wrap around
L<RDF::RDFa::Generator>, which does the heavy lifting.  It composes
L<Attean::API::TripleSerializer> and
L<Attean::API::AbbreviatingSerializer>.

=head1 METHODS AND ATTRIBUTES

=head2 Attributes


In addition to attributes required by L<Attean::API::TripleSerializer>
that should not be a concern to users, the following attributes can be
set:

=over


=item C<< style >>

This attribute sets the serialization style used by
L<RDF::RDFa::Generator>, see its documentation for details.

=item C<< namespaces >>

A HASH reference mapping prefix strings to L<URI::NamespaceMap>
objects. L<RDF::RDFa::Generator> will help manage this map, see its
documentation for details.

=item C<< base >>

An L<Attean::API::IRI> object representing the base against which
relative IRIs in the serialized data should be resolved. There is some
support in L<RDF::RDFa::Generator>, but currently, it doesn't do much.

=item C<< generator_options >>

A HASH reference that will be passed as options to
L<RDF::RDFa::Generator>'s C<create_document> method. This is typically
options that are specific to different styles, see synopsis for
example.

=back

=head2 Methods

This implements two required methods:

=over

=item C<< serialize_iter_to_io( $fh, $iterator ) >>

Serializes the elements from the L<Attean::API::Iterator> C<< $iterator >> to
the L<IO::Handle> object C<< $fh >>.

=item C<< serialize_iter_to_bytes( $fh ) >>

Serializes the elements from the L<Attean::API::Iterator> C<< $iterator >>
and returns the serialization as a UTF-8 encoded byte string.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-atteanx-serializer-rdfa/issues>.

=head1 SEE ALSO

L<RDF::RDFa::Generator>, L<RDF::Trine::Serializer::RDFa>.

=head1 TODO

=over

=item * The C<style> attribute may be implemented with better constraints.

=item * Make the writers (i.e. the code actually writing the DOM) configurable.

=back

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017, 2018 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


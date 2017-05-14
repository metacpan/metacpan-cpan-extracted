use strict;
use warnings;
package Conclave::OTK::Backend::File;
# ABSTRACT: OTK file based backend
use parent qw/Conclave::OTK::Backend/;

use RDF::Trine;
use RDF::Trine::Model;
use RDF::Trine::Parser;
use RDF::Trine::Store::Memory;
use RDF::Trine::Serializer::RDFXML;
use RDF::Query;
use Path::Tiny;
use Data::Dumper;

$ENV{PATH} = undef;

sub new {
  my ($class, $base_uri, %opts) = @_;
  my $self = bless({}, $class);

  my $filename = 'model.xml';
  $filename = $opts{filename} if $opts{filename};

  $self->{base_uri} = $base_uri;
  $self->{filename} = $filename;

  return $self;
}
  #my $store = RDF::Trine::Store::Memory->new;
  #my $model = RDF::Trine::Model->new($store);

  #my $serializer = RDF::Trine::Serializer::NQuads->new();

sub init {
  my ($self, $rdfxml) = @_;

  my $store = RDF::Trine::Store::Memory->new;
  my $model = RDF::Trine::Model->new($store);
  my $parser = RDF::Trine::Parser->new('rdfxml');
  my $serializer = RDF::Trine::Serializer::RDFXML->new( base_uri => $self->{base_uri} );

  $parser->parse_into_model($self->{base_uri}, $rdfxml, $model);

  open(my $fh, '>', $self->{filename});
  $serializer->serialize_model_to_file($fh, $model);
  close($fh);
}

sub update {
  my ($self, $sparql) = @_;

  my $query = RDF::Query->new($sparql, {update => 1});

  my $parser = RDF::Trine::Parser->new('rdfxml');
  my $serializer = RDF::Trine::Serializer::RDFXML->new( base_uri => $self->{base_uri} );
  my $file = path($self->{filename});
  my $data = $file->slurp_utf8;
  my $store = RDF::Trine::Store::Memory->new;
  my $model = RDF::Trine::Model->new($store);
  $parser->parse_into_model($self->{base_uri}, $data, $model);

  my $iterator = $query->execute($model);

  open(my $fh, '>', $self->{filename});
  $serializer->serialize_model_to_file($fh, $model);
  close($fh);

  return $iterator;
}

sub query {
  my ($self, $sparql) = @_;

  my $query = RDF::Query->new($sparql);

  my $parser = RDF::Trine::Parser->new('rdfxml');
  my $file = path($self->{filename});
  my $data = $file->slurp_utf8;
  my $store = RDF::Trine::Store::Memory->new;
  my $model = RDF::Trine::Model->new($store);
  $parser->parse_into_model($self->{base_uri}, $data, $model);
  my $iterator = $query->execute($model);

  my @result;
  while (my $triple = $iterator->next) {
    if (scalar(keys %$triple) == 1) {
      foreach (keys %$triple) {
        push @result, $triple->{$_}->[1]; # FIXME
      }
    }
    else {
      # FIXME
      my $str = $triple->as_string;
      if ($str =~ m/{\s*.*?=<(.*?)>,\s*.*?=<(.*?)>,\s*.*?=("|<)(.*?)("|>)/) {
        push @result, [($1,$2,$4)];
      }
    }
  }

  return @result;
}

sub delete {
  my ($self) = @_;

  unlink $self->{filename};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Conclave::OTK::Backend::File - OTK file based backend

=head1 VERSION

version 0.01

=head1 AUTHOR

Nuno Carvalho <smash@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2015 by Nuno Carvalho <smash@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

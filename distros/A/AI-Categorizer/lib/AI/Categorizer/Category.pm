package AI::Categorizer::Category;

use strict;
use AI::Categorizer::ObjectSet;
use Class::Container;
use base qw(Class::Container);

use Params::Validate qw(:types);
use AI::Categorizer::FeatureVector;

__PACKAGE__->valid_params
  (
   name => {type => SCALAR, public => 0},
   documents  => {
		  type => ARRAYREF,
		  default => [],
		  callbacks => { 'all are Document objects' => 
				 sub { ! grep !UNIVERSAL::isa($_, 'AI::Categorizer::Document'), @_ },
			       },
		  public => 0,
		 },
  );

__PACKAGE__->contained_objects
  (
   features => {
		class => 'AI::Categorizer::FeatureVector',
		delayed => 1,
	       },
  );

my %REGISTRY = ();

sub new {
  my $self = shift()->SUPER::new(@_);
  $self->{documents} = new AI::Categorizer::ObjectSet( @{$self->{documents}} );
  $REGISTRY{$self->{name}} = $self;
  return $self;
}

sub by_name {
  my ($class, %args) = @_;
  return $REGISTRY{$args{name}} if exists $REGISTRY{$args{name}};
  return $class->new(%args);
}

sub name { $_[0]->{name} }

sub documents {
  my $d = $_[0]->{documents};
  return wantarray ? $d->members : $d->size;
}

sub contains_document {
  return $_[0]->{documents}->includes( $_[1] );
}

sub add_document {
  my $self = shift;
  $self->{documents}->insert( $_[0] );
  delete $self->{features};  # Could be more efficient?
}

sub features {
  my $self = shift;

  if (@_) {
    $self->{features} = shift;
  }
  return $self->{features} if $self->{features};

  my $v = $self->create_delayed_object('features');
  return $self->{features} = $v unless $self->documents;

  foreach my $document ($self->documents) {
    $v->add( $document->features );
  }
  
  return $self->{features} = $v;
}

1;
__END__

=head1 NAME

AI::Categorizer::Category - A named category of documents

=head1 SYNOPSIS

  my $category = AI::Categorizer::Category->by_name("sports");
  my $name = $category->name;
  
  my @docs = $category->documents;
  my $num_docs = $category->documents;
  my $features = $category->features;
  
  $category->add_document($doc);
  if ($category->contains_document($doc)) { ...

=head1 DESCRIPTION

This simple class represents a named category which may contain zero
or more documents.  Each category is a "singleton" by name, so two
Category objects with the same name should not be created at once.

=head1 METHODS

=over 4

=item new()

Creates a new Category object and returns it.  Accepts the following
parameters:

=over 4

=item name

The name of this category

=item documents

A reference to an array of Document objects that should belong to this
category.

=back

=item by_name(name => $string)

Returns the Category object with the given name, or creates one if no
such object exists.

=item documents()

Returns a list of the Document objects in this category in a list
context, or the number of such objects in a scalar context.

=item features()

Returns a FeatureVector object representing the sum of all the
FeatureVectors of the Documents in this Category.

=item add_document($document)

Informs the Category that the given Document belongs to it.

=item contains_document($document)

Returns true if the given document belongs to this category, or false
otherwise.

=back

=head1 AUTHOR

Ken Williams, ken@mathforum.org

=head1 COPYRIGHT

Copyright 2000-2003 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

AI::Categorizer(3), Storable(3)

=cut

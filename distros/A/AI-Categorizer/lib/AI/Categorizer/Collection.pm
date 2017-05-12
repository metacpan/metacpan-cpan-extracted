package AI::Categorizer::Collection;
use strict;

use Params::Validate qw(:types);
use Class::Container;
use base qw(Class::Container);
__PACKAGE__->valid_params
  (
   verbose => {type => SCALAR, default => 0},
   stopword_file => { type => SCALAR, optional => 1 },
   category_hash => { type => HASHREF, default => {} },
   category_file => { type => SCALAR, optional => 1 },
  );

__PACKAGE__->contained_objects
  (
   document => { class => 'AI::Categorizer::Document::Text',
		 delayed => 1 },
  );

sub new {
  my ($class, %args) = @_;
  
  # Optimize so every document doesn't have to convert the stopword list to a hash
  if ($args{stopwords} and UNIVERSAL::isa($args{stopwords}, 'ARRAY')) {
    $args{stopwords} = { map {+$_ => 1} @{ $args{stopwords} } };
  }
  
  my $self = $class->SUPER::new(%args);

  if ($self->{category_file}) {
    local *FH;
    open FH, $self->{category_file} or die "Can't open $self->{category_file}: $!";
    while (<FH>) {
      my ($doc, @cats) = split;
      $self->{category_hash}{$doc} = \@cats;
    }
    close FH;
  }
  if (exists $self->{stopword_file}) {
    my %stopwords;
    local *FH;
    open FH, "< $self->{stopword_file}" or die "$self->{stopword_file}: $!";
    while (<FH>) {
      chomp;
      $stopwords{$_} = 1;
    }
    close FH;

    $self->delayed_object_params('document', stopwords => \%stopwords);
  }

  return $self;
}

# This should usually be replaced in subclasses with a faster version that doesn't
# need to create actual documents each time through
sub count_documents {
  my $self = shift;
  return $self->{document_count} if exists $self->{document_count};

  $self->rewind;
  my $count = 0;
  $count++ while $self->next;
  $self->rewind;

  return $self->{document_count} = $count;
}

# Abstract methods
sub next;
sub rewind;

1;
__END__

=head1 NAME

AI::Categorizer::Collection - Access stored documents

=head1 SYNOPSIS

  my $c = new AI::Categorizer::Collection::Files
    (path => '/tmp/docs/training',
     category_file => '/tmp/docs/cats.txt');
  print "Total number of docs: ", $c->count_documents, "\n";
  while (my $document = $c->next) {
    ...
  }
  $c->rewind; # For further operations
  
=head1 DESCRIPTION

This abstract class implements an iterator for accessing documents in
their natively stored format.  You cannot directly create an instance
of the Collection class, because it is abstract - see the
documentation for the C<Files>, C<SingleFile>, or C<InMemory>
subclasses for a concrete interface.

=head1 METHODS

=over 4

=item new()

Creates a new Collection object and returns it.  Accepts the following
parameters:

=over 4

=item category_hash

Indicates a reference to a hash which maps document names to category
names.  The keys of the hash are the document names, each value should
be a reference to an array containing the names of the categories to
which each document belongs.

=item category_file

Indicates a file which should be read in order to create the
C<category_hash>.  Each line of the file should list a document's
name, followed by a list of category names, all separated by
whitespace.

=item stopword_file

Specifies a file containing a list of "stopwords", which are words
that should automatically be disregarded when scanning/reading
documents.  The file should contain one word per line.  The file will
be parsed and then fed as the C<stopwords> parameter to the
Document C<new()> method.

=item verbose

If true, some status/debugging information will be printed to
C<STDOUT> during operation.

=item document_class

The class indicating what type of Document object should be created.
This generally specifies the format that the documents are stored in.
The default is C<AI::Categorizer::Document::Text>.

=back

=item next()

Returns the next Document object in the Collection.

=item rewind()

Resets the iterator for further calls to C<next()>.

=item count_documents()

Returns the total number of documents in the Collection.  Note that
this usually resets the iterator.  This is because it may not be
possible to resume iterating where we left off.

=back

=head1 AUTHOR

Ken Williams, ken@mathforum.org

=head1 COPYRIGHT

Copyright 2002-2003 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

AI::Categorizer(3), Storable(3)

=cut

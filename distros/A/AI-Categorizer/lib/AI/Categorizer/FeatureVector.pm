package AI::Categorizer::FeatureVector;

sub new {
  my ($package, %args) = @_;
  $args{features} ||= {};
  return bless {features => $args{features}}, $package;
}

sub names {
  my $self = shift;
  return keys %{$self->{features}};
}

sub set {
  my $self = shift;
  $self->{features} = (ref $_[0] ? $_[0] : {@_});
}

sub as_hash {
  my $self = shift;
  return $self->{features};
}

sub euclidean_length {
  my $self = shift;
  my $f = $self->{features};

  my $total = 0;
  foreach (values %$f) {
    $total += $_**2;
  }
  return sqrt($total);
}

sub normalize {
  my $self = shift;

  my $length = $self->euclidean_length;
  return $length ? $self->scale(1/$length) : $self;
}

sub scale {
  my ($self, $scalar) = @_;
  $_ *= $scalar foreach values %{$self->{features}};
  return $self;
}

sub as_boolean_hash {
  my $self = shift;
  return { map {($_ => 1)} keys %{$self->{features}} };
}

sub length {
  my $self = shift;
  return scalar keys %{$self->{features}};
}

sub clone {
  my $self = shift;
  return ref($self)->new( features => { %{$self->{features}} } );
}

sub intersection {
  my ($self, $other) = @_;
  $other = $other->as_hash if UNIVERSAL::isa($other, __PACKAGE__);

  my $common;
  if (UNIVERSAL::isa($other, 'ARRAY')) {
    $common = {map {exists $self->{features}{$_} ? ($_ => $self->{features}{$_}) : ()} @$other};
  } elsif (UNIVERSAL::isa($other, 'HASH')) {
    $common = {map {exists $self->{features}{$_} ? ($_ => $self->{features}{$_}) : ()} keys %$other};
  }
  return ref($self)->new( features => $common );
}

sub add {
  my ($self, $other) = @_;

  $other = $other->as_hash if UNIVERSAL::isa($other, __PACKAGE__);
  while (my ($k,$v) = each %$other) {
    $self->{features}{$k} += $v;
  }
}

sub dot {
  my ($self, $other) = @_;
  $other = $other->as_hash if UNIVERSAL::isa($other, __PACKAGE__);

  my $sum = 0;
  my $f = $self->{features};
  while (my ($k, $v) = each %$f) {
    $sum += $other->{$k} * $v if exists $other->{$k};
  }
  return $sum;
}

sub sum {
  my ($self) = @_;

  # Return total of values in this vector
  my $total = 0;
  $total += $_ foreach values %{ $self->{features} };
  return $total;
}

sub includes {
  return exists $_[0]->{features}{$_[1]};
}

sub value {
  return $_[0]->{features}{$_[1]};
}

sub values {
  my $self = shift;
  return @{ $self->{features} }{ @_ };
}

1;
__END__

=head1 NAME

AI::Categorizer::FeatureVector - Features vs. Values

=head1 SYNOPSIS

  my $f1 = new AI::Categorizer::FeatureVector
    (features => {howdy => 2, doody => 3});
  my $f2 = new AI::Categorizer::FeatureVector
    (features => {doody => 1, whopper => 2});
   
  @names = $f1->names;
  $x = $f1->length;
  $x = $f1->sum;
  $x = $f1->includes('howdy');
  $x = $f1->value('howdy');
  $x = $f1->dot($f2);
  
  $f3 = $f1->clone;
  $f3 = $f1->intersection($f2);
  $f3 = $f1->add($f2);
  
  $h = $f1->as_hash;
  $h = $f1->as_boolean_hash;
  
  $f1->normalize;

=head1 DESCRIPTION

This class implements a "feature vector", which is a flat data
structure indicating the values associated with a set of features.  At
its base level, a FeatureVector usually represents the set of words in
a document, with the value for each feature indicating the number of
times each word appears in the document.  However, the values are
arbitrary so they can represent other quantities as well, and
FeatureVectors may also be combined to represent the features of
multiple documents.

=head1 METHODS

=over 4

=item ...

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

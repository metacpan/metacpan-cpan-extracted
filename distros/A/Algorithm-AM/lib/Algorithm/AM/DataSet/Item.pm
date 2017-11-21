package Algorithm::AM::DataSet::Item;
use strict;
use warnings;
our $VERSION = '3.11';
# ABSTRACT: A single item for classification training and testing
use Carp;
our @CARP_NOT = qw(Algorithm::AM::DataSet);
use Exporter::Easy (
    OK => ['new_item']
);

# use to assign unique ids to new items; not meant to be secure
# or anything, just unique.
my $current_id = 'a';


#pod =head1 SYNOPSIS
#pod
#pod   use Algorithm::AM::DataSet::Item 'new_item';
#pod
#pod   my $item = new_item(
#pod     features => ['a', 'b', 'c'],
#pod     class => 'x',
#pod     comment => 'a sample, meaningless item'
#pod   );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class represents a single item contained in a data set. Each
#pod item has a feature vector and possibly a class label and comment
#pod string. Once created, the item is immutable.
#pod
#pod =head1 METHODS
#pod
#pod =head2 C<new>
#pod
#pod Creates a new Item object. The only required argument is
#pod 'features', which should be an array ref containing the feature
#pod vector. Each element of this array should be a string indicating the
#pod value of the feature at the given index. 'class' and 'comment'
#pod arguments are also accepted, where 'class' is the classification
#pod label and 'comment' can be any string to be associated with the item.
#pod A missing or undefined 'class' value is assumed to mean that the item
#pod classification is unknown. For the feature vector, empty strings are
#pod taken to indicate null values.
#pod
#pod =cut
sub new {
    my ($class, %args) = @_;
    if(!exists $args{features} ||
        'ARRAY' ne ref $args{features}){
        croak q[Must provide 'features' parameter of type array ref];
    }
    my $self = {};
    for(qw(features class comment)){
        $self->{$_} = $args{$_};
        delete $args{$_};
    }
    if(my $extra_keys = join ',', sort keys %args){
        croak "Unknown parameters: $extra_keys";
    }
    $self->{id} = $current_id;
    $current_id++;
    bless $self, $class;
    return $self;
}

#pod =head2 C<new_item>
#pod
#pod This is an exportable shortcut for the new method. If exported, then
#pod instead of calling C<<Algorithm::AM::DataSet::Item->new>>, you may
#pod simply call C<new_item>.
#pod
#pod =cut
sub new_item {
    # unpack here so that warnings about odd numbers of elements are
    # reported for this function, not for the new method
    my %args = @_;
    return __PACKAGE__->new(%args);
}

#pod =head2 C<class>
#pod
#pod Returns the classification label for this item, or undef if the class
#pod is unknown.
#pod
#pod =cut
sub class {
    my ($self) = @_;
    return $self->{class};
}

#pod =head2 C<features>
#pod
#pod Returns the feature vector for this item. This is an arrayref
#pod containing the string value for each feature. An empty string
#pod indicates that the feature value is null (meaning that it has
#pod no value).
#pod
#pod =cut
sub features {
    my ($self) = @_;
    # make a safe copy
    return [@{ $self->{features} }];
}

#pod =head2 C<comment>
#pod
#pod Returns the comment for this item. By default, the comment is
#pod just a comma-separated list of the feature values.
#pod
#pod =cut
sub comment {
    my ($self) = @_;
    if(!defined $self->{comment}){
        $self->{comment} = join ',', @{ $self->{features} };
    }
    return $self->{comment};
}

#pod =head2 C<cardinality>
#pod
#pod Returns the length of the feature vector for this item.
#pod
#pod =cut
sub cardinality {
    my ($self) = @_;
    return scalar @{$self->features};
}

#pod =head2 C<id>
#pod
#pod Returns a unique string id for this item, for use as a hash key or
#pod similar situations.
#pod
#pod =cut
sub id {
    my ($self) = @_;
    return $self->{id};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::AM::DataSet::Item - A single item for classification training and testing

=head1 VERSION

version 3.11

=head1 SYNOPSIS

  use Algorithm::AM::DataSet::Item 'new_item';

  my $item = new_item(
    features => ['a', 'b', 'c'],
    class => 'x',
    comment => 'a sample, meaningless item'
  );

=head1 DESCRIPTION

This class represents a single item contained in a data set. Each
item has a feature vector and possibly a class label and comment
string. Once created, the item is immutable.

=head1 METHODS

=head2 C<new>

Creates a new Item object. The only required argument is
'features', which should be an array ref containing the feature
vector. Each element of this array should be a string indicating the
value of the feature at the given index. 'class' and 'comment'
arguments are also accepted, where 'class' is the classification
label and 'comment' can be any string to be associated with the item.
A missing or undefined 'class' value is assumed to mean that the item
classification is unknown. For the feature vector, empty strings are
taken to indicate null values.

=head2 C<new_item>

This is an exportable shortcut for the new method. If exported, then
instead of calling C<<Algorithm::AM::DataSet::Item->new>>, you may
simply call C<new_item>.

=head2 C<class>

Returns the classification label for this item, or undef if the class
is unknown.

=head2 C<features>

Returns the feature vector for this item. This is an arrayref
containing the string value for each feature. An empty string
indicates that the feature value is null (meaning that it has
no value).

=head2 C<comment>

Returns the comment for this item. By default, the comment is
just a comma-separated list of the feature values.

=head2 C<cardinality>

Returns the length of the feature vector for this item.

=head2 C<id>

Returns a unique string id for this item, for use as a hash key or
similar situations.

=head1 AUTHOR

Theron Stanford <shixilun@yahoo.com>, Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Royal Skousen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Algorithm::AM::DataSet;
use strict;
use warnings;
our $VERSION = '3.11';
# ABSTRACT: Manage data used by Algorithm::AM
use Carp;
use Algorithm::AM::DataSet::Item;
use Path::Tiny;
use Exporter::Easy (
    OK => ['dataset_from_file']
);

#pod =head1 SYNOPSIS
#pod
#pod  use Algorithm::AM::DataSet 'dataset_from_file';
#pod  use Algorithm::AM::DataSet::Item 'new_item';
#pod  my $dataset = Algorithm::AM::DataSet->new(cardinality => 10);
#pod  # or
#pod  $dataset = dataset_from_file(path => 'finnverb', format => 'nocommas');
#pod  $dataset->add_item(
#pod    new_item(features => [qw(a b c d e f g h i)]));
#pod  my $item = $dataset->get_item(2);
#pod
#pod =head1 DESCRIPTION
#pod
#pod This package contains a list of items that can be used by
#pod L<Algorithm::AM> or L<Algorithm::AM::Batch> for classification.
#pod DataSets can be made one item at a time via the L</add_item> method,
#pod or they can be read from files via the L</dataset_from_file> function.
#pod
#pod =head2 C<new>
#pod
#pod Creates a new DataSet object. You must provide a C<cardinality> argument
#pod indicating the number of features to be contained in each data vector.
#pod You can then add items via the add_item method. Each item will contain
#pod a feature vector, and also optionally a class label and a comment
#pod (also called a "spec").
#pod
#pod =cut
sub new {
    my ($class, %opts) = @_;

    my $new_opts = _check_opts(%opts);

    my $self = bless $new_opts, $class;

    $self->_init;

    return $self;
}

# check the options for validity
# Return an option hash to initialize $self with
# For now only 'cardinality' is allowed/required.
sub _check_opts {
    my (%opts) = @_;

    my %final_opts;

    if(!defined $opts{cardinality}){
        croak q{Failed to provide 'cardinality' parameter};
    }
    $final_opts{cardinality} = $opts{cardinality};
    delete $opts{cardinality};

    if(keys %opts){
        # sort the keys in the error message to make testing possible
        croak 'Unknown parameters in DataSet constructor: ' .
            (join ', ', sort keys %opts);
    }

    return \%final_opts;
}

# initialize internal state
sub _init {
    my ($self) = @_;
    # contains all of the items in the dataset
    $self->{items} = [];

    # map unique class labels to unique integers;
    # these are the indices of the class labels in class_list below;
    # the indices must start at 1 for AM to work, as 0 is reserved
    # for heterogeneity.
    $self->{class_num_index} = {};
    # contains the list of class strings in an order that matches
    # the indices in class_num_index
    $self->{class_list} = [];
    # the total number of different classes contained in the data set
    $self->{num_classes} = 0;
    return;
}

#pod =head2 C<cardinality>
#pod
#pod Returns the number of features contained in the feature vector of a
#pod single item.
#pod
#pod =cut
sub cardinality {
    my ($self) = @_;
    return $self->{cardinality};
}

#pod =head2 C<size>
#pod
#pod Returns the number of items in the data set.
#pod
#pod =cut
sub size {
    my ($self) = @_;
    return scalar @{$self->{items}};
}

#pod =head2 C<classes>
#pod
#pod Returns the list of all unique class labels in the data set.
#pod
#pod =cut
sub classes {
    my ($self) = @_;
    return @{ $self->{class_list} };
}

#pod =head2 C<add_item>
#pod
#pod Adds a new item to the data set. The input may be either an
#pod L<Algorithm::AM::DataSet::Item> object, or the arguments to create
#pod one via its constructor (features, class, comment). This method will
#pod croak if the cardinality of the item does not match L</cardinality>.
#pod
#pod =cut
sub add_item {
    my ($self, @args) = @_;
    my $item;
    if('Algorithm::AM::DataSet::Item' eq ref $args[0]){
        $item = $args[0];
    }else{
        $item = Algorithm::AM::DataSet::Item->new(@args);
    }

    if($self->cardinality != $item->cardinality){
        croak 'Expected ' . $self->cardinality .
            ' features, but found ' . (scalar $item->cardinality) .
            ' in ' . (join ' ', @{$item->features}) .
            ' (' . $item->comment . ')';
    }

    if(defined $item->class){
        $self->_update_class_vars($item->class);
    }

    # store the new item
    push @{$self->{items}}, $item;
    return;
}

# keep track of classes; needs updating for new item
sub _update_class_vars {
    my ($self, $class) = @_;

    if(!$self->{class_num_index}->{$class}){
        $self->{num_classes}++;
        $self->{class_num_index}->{$class} = $self->{num_classes};
        push @{$self->{class_list}}, $class;
    }
    return;
}

#pod =head2 C<get_item>
#pod
#pod Return the item at the given index. This will be a
#pod L<Algorithm::AM::DataSet::Item> object.
#pod
#pod =cut
sub get_item {
    my ($self, $index) = @_;
    return $self->{items}->[$index];
}

#pod =head2 C<num_classes>
#pod
#pod Returns the number of different classification labels contained in
#pod the data set.
#pod
#pod =cut
sub num_classes {
    my ($self) = @_;
    return $self->{num_classes};
}

# Used by AM. Return an arrayref containing all of the
# classes for the data set (ordered the same as the data set).
sub _data_classes {
    my ($self) = @_;
    my @classes = map {
        defined $_->class ?
            $self->_index_for_class($_->class) :
            undef
        } @{$self->{items}};
    return \@classes;
}

# Used by AM. Return the integer mapped to the given class string.
sub _index_for_class {
    my ($self, $class) = @_;
    return $self->{class_num_index}->{$class};
}

# Used by Result, which traverses data structures from
# AM's guts.
sub _class_for_index {
    my ($self, $index) = @_;
    return $self->{class_list}->[$index - 1];
}

#pod =head2 C<dataset_from_file>
#pod
#pod This function may be exported. Given 'path' and 'format' arguments,
#pod it reads a file containing a dataset and returns a new DataSet object
#pod with the given data. The 'path' argument should be the path to the
#pod file. The 'format' argument should be 'commas' or 'nocommas',
#pod indicating one of the following formats. You may also specify 'unknown'
#pod and 'null' arguments to indicate the strings meant to represent an
#pod unknown class value and null feature values. By default these are
#pod 'UNK' and '='.
#pod
#pod The 'commas' file format is shown below:
#pod
#pod  class , f eat u re s , your comment here
#pod
#pod The commas separate the class label, feature values, and comments,
#pod and the whitespace around the commas is optional. Each feature value
#pod is separated with whitespace.
#pod
#pod The 'nocommas' file format is shown below:
#pod
#pod  class   features  your comment here
#pod
#pod Here the class, feature values, and comments are separated by
#pod whitespace. Each feature value must be a single character with no
#pod separating characters, so here the features are f, e, a, t, u, r,
#pod e, and s.
#pod
#pod Lines beginning with a pound character (C<#>) are ignored.
#pod
#pod =cut
sub dataset_from_file {## no critic (RequireArgUnpacking)
    my (%opts) = (
        unknown => 'UNK',
        null => '=',
        @_
    );

    croak q[Failed to provide 'path' parameter]
        unless exists $opts{path};
    croak q[Failed to provide 'format' parameter]
        unless exists $opts{format};

    my ($path, $format, $unknown, $null) = (
        path($opts{path}), @opts{'format', 'unknown', 'null'});

    croak "Could not find file $path"
        unless $path->exists;

    my ($field_sep, $feature_sep);
    if($format eq 'commas'){
        # class/features/comment separated by a comma
        $field_sep   = qr{\s*,\s*};
        # features separated by space
        $feature_sep = qr{\s+};
    }elsif($format eq 'nocommas'){
        # class/features/comment separated by space
        $field_sep   = qr{\s+};
        # no seps for features; each is a single character
        $feature_sep = qr{};
    }else{
        croak "Unknown value $format for format parameter " .
            q{(should be 'commas' or 'nocommas')};
    }

    if(!defined $unknown){
        croak q[Must provide a defined value for 'unknown' parameter];
    }

    my $reader = _read_data_sub(
        $path, $unknown, $null, $field_sep, $feature_sep);
    my $item = $reader->();
    if(!$item){
        croak "No data found in file $path";
    }
    my $dataset = __PACKAGE__->new(cardinality => $item->cardinality);
    $dataset->add_item($item);
    while($item = $reader->()){
        $dataset->add_item($item);
    }
    return $dataset;
}

# return a sub that returns one Item per call from the given FH,
# and returns undef once the file is done being read. Throws errors
# on bad file contents.
# Input is file (Path::Tiny), string representing unknown class,
# string representing null feature, field separator (class,
# features, comment) and feature separator
sub _read_data_sub {
    my ($data_file, $unknown, $null,
        $field_sep, $feature_sep) = @_;
    my $data_fh = $data_file->openr_utf8;
    my $line_num = 0;
    return sub {
        my $line;
        # grab the next non-blank line from the file
        while($line = <$data_fh>){
            $line_num++;
            # skip comments
            next if $line =~ m/^\s*#/;
            # cross-platform chomp
            $line =~ s/\R$//;
            $line =~ s/^\s+|\s+$//g;
            last if $line;
        }
        return unless $line;
        my ($class, $feats, $comment) = split /$field_sep/, $line, 3;
        # the line has to have at least the class label and features
        if(!defined $feats){
            croak "Couldn't read data at line $line_num in $data_file";
        }
        # if the class is specified as unknown, set it to undef to
        # indicate this to Item
        if($class eq $unknown){
            undef $class;
        }

        my @data_vars = split /$feature_sep/, $feats;
        # set null features to ''
        @data_vars = map {$_ eq $null ? '' : $_} @data_vars;

        return Algorithm::AM::DataSet::Item->new(
            features=> \@data_vars,
            class => $class,
            comment => $comment
        );
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::AM::DataSet - Manage data used by Algorithm::AM

=head1 VERSION

version 3.11

=head1 SYNOPSIS

 use Algorithm::AM::DataSet 'dataset_from_file';
 use Algorithm::AM::DataSet::Item 'new_item';
 my $dataset = Algorithm::AM::DataSet->new(cardinality => 10);
 # or
 $dataset = dataset_from_file(path => 'finnverb', format => 'nocommas');
 $dataset->add_item(
   new_item(features => [qw(a b c d e f g h i)]));
 my $item = $dataset->get_item(2);

=head1 DESCRIPTION

This package contains a list of items that can be used by
L<Algorithm::AM> or L<Algorithm::AM::Batch> for classification.
DataSets can be made one item at a time via the L</add_item> method,
or they can be read from files via the L</dataset_from_file> function.

=head2 C<new>

Creates a new DataSet object. You must provide a C<cardinality> argument
indicating the number of features to be contained in each data vector.
You can then add items via the add_item method. Each item will contain
a feature vector, and also optionally a class label and a comment
(also called a "spec").

=head2 C<cardinality>

Returns the number of features contained in the feature vector of a
single item.

=head2 C<size>

Returns the number of items in the data set.

=head2 C<classes>

Returns the list of all unique class labels in the data set.

=head2 C<add_item>

Adds a new item to the data set. The input may be either an
L<Algorithm::AM::DataSet::Item> object, or the arguments to create
one via its constructor (features, class, comment). This method will
croak if the cardinality of the item does not match L</cardinality>.

=head2 C<get_item>

Return the item at the given index. This will be a
L<Algorithm::AM::DataSet::Item> object.

=head2 C<num_classes>

Returns the number of different classification labels contained in
the data set.

=head2 C<dataset_from_file>

This function may be exported. Given 'path' and 'format' arguments,
it reads a file containing a dataset and returns a new DataSet object
with the given data. The 'path' argument should be the path to the
file. The 'format' argument should be 'commas' or 'nocommas',
indicating one of the following formats. You may also specify 'unknown'
and 'null' arguments to indicate the strings meant to represent an
unknown class value and null feature values. By default these are
'UNK' and '='.

The 'commas' file format is shown below:

 class , f eat u re s , your comment here

The commas separate the class label, feature values, and comments,
and the whitespace around the commas is optional. Each feature value
is separated with whitespace.

The 'nocommas' file format is shown below:

 class   features  your comment here

Here the class, feature values, and comments are separated by
whitespace. Each feature value must be a single character with no
separating characters, so here the features are f, e, a, t, u, r,
e, and s.

Lines beginning with a pound character (C<#>) are ignored.

=head1 SEE ALSO

For information on creating data sets, see the appendices in
the "red book", I<Analogical Modeling: An exemplar-based approach to
language>. See also the "green book",
I<Analogical Modeling of Language>, for an explanation of the method
in general, and the "blue book", I<Analogy and Structure>, for its
mathematical basis.

=head1 AUTHOR

Theron Stanford <shixilun@yahoo.com>, Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Royal Skousen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

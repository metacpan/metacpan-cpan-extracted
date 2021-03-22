package App::Followme::BaseData;

use 5.008005;
use strict;
use warnings;
use integer;
use lib '../..';

use base qw(App::Followme::ConfiguredObject);
use App::Followme::FIO;

#----------------------------------------------------------------------
# Default values of parameters

sub parameters {
    my ($pkg) = @_;

    return (
            list_length => 5,
            target_prefix => 'target',
            );
}

#----------------------------------------------------------------------
# Build a new variable value given its name and context

sub build {
    my ($self, $variable_name, $item, $loop) = @_;

    # Extract the sigil from the variable name, if present
    my ($sigil, $name) = $self->split_name($variable_name);

    # Extract the sort field from the variable name
    my ($data_field, $sort_field, $sort_reverse);
    ($data_field, $sort_field) = split('_by_', $name);
    if (defined $sort_field) {
        if ($sort_field =~ s/_reversed$//) {
            $sort_reverse = 1;
        } else {
            $sort_reverse = 0;
        }
    }

    my %cache = ();
    if ($sigil eq '$') {
        if (defined $item &&
           (! $self->{cache}{item} || $self->{cache}{item} ne $item)) {
            # Clear cache when argument to build changes
            %cache = (item => $item);
        } else {
            %cache = %{$self->{cache}};
        }
    }

    # Build the value associated with a name if it is not in the cache
    unless (exists $cache{$data_field}) {
        my %data = $self->fetch_data($data_field, $item, $loop);

        my $sorted_order = 0;
        my $sorted_data = $self->sort(\%data, $sort_field, $sort_reverse);
        $sorted_data = $self->format($sorted_order, $sorted_data);

        %cache = (%cache, %$sorted_data);
    }

    # Check the value for agreement with the sigil and return reference
    my $ref_value = $self->ref_value($cache{$data_field}, $sigil, $data_field);
    $self->{cache} = \%cache if $sigil eq '$';
    return $ref_value;
}

#----------------------------------------------------------------------
# Coerce the data to a hash

sub coerce_data {
    my ($self, $name, @data) = @_;

    my %data;
    if (@data == 0) {
        %data = ();

    } elsif (@data == 1) {
        %data = ($name => $data[0]);

    } elsif (@data % 2 == 0) {
        %data = @data;

    } else {
        my $pkg = ref $self;
        die "$name does not return a hash\n";
    }

    return %data;
}

#----------------------------------------------------------------------
# Fetch the data for building a variable's value

sub fetch_data {
    my ($self, $name, $item, $loop) = @_;

    my %data = $self->gather_data('get', $name, $item, $loop);
    return %data;
}

#----------------------------------------------------------------------
# Choose the file comparison routine that matches the configuration

sub file_comparer {
    my ($self, $sort_reverse) = @_;

    my $comparer;
    if ($sort_reverse) {
        $comparer = sub ($$) {$_[1]->[0] cmp $_[0]->[0]};
    } else {
        $comparer = sub ($$) {$_[0]->[0] cmp $_[1]->[0]};
    }

    return $comparer;
}

#----------------------------------------------------------------------
# If there is omly a single field containing data, return its name

sub find_data_field {
    my ($self, $data) = @_;

    my @keys = keys %$data;

    my $field;
    if (@keys == 1 ) {
        my $key = $keys[0];
        if (ref $data->{$key} eq 'ARRAY') {
            $field = $key;
        }
    }

    return $field;
}

#----------------------------------------------------------------------
# Find the values to sort by and format them so they are in sort order

sub find_sort_column {
    my ($self, $data_column, $sort_field) = @_;
    
    my $formatter = "format_$sort_field";
    $formatter = "format_nothing" unless $self->can($formatter);

    my @sort_column;
    my $sorted_order = 1;

    for my $data_item (@$data_column) {
        my %data = $self->fetch_data($sort_field, $data_item, $data_column);

        if (exists $data{$sort_field}) {
            push(@sort_column, $self->$formatter($sorted_order, 
                                                 $data{$sort_field}));
        } else {
            warn "Sort field not found: $sort_field";
            push(@sort_column, $data_item);
        }
        
    }

    return \@sort_column;
}

#----------------------------------------------------------------------
# Find the target, return the target plus an offset

sub find_target {
    my ($self, $offset, $item, $loop) = @_;
    die "Can't use \$target_* outside of for\n"  unless $loop;

    my $match = -999;
    foreach my $i (0 .. @$loop) {
        if ($loop->[$i] eq $item) {
            $match = $i;
            last;
        }
    }

    my $index = $match + $offset + 1;
    $index = 0 if $index < 1 || $index > @$loop;
    return $index ? $self->{target_prefix} . $index : '';
}

#----------------------------------------------------------------------
# Apply an optional format to the data

sub format {
    my ($self, $sorted_order, $sorted_data) = @_;

    foreach my $name (keys %$sorted_data) {
        next unless $sorted_data->{$name};

        my $formatter = join('_', 'format', $name);
        if ($self->can($formatter)) {
            if (ref $sorted_data->{$name} eq 'ARRAY') {
                for my $value (@{$sorted_data->{$name}}) {
                    $value = $self->$formatter($sorted_order,
                                               $value);
                }

            } elsif (ref $sorted_data->{$name} eq 'HASH') {
                die("Illegal data format for build: $name");

            } else {
                $sorted_data->{$name} =
                    $self->$formatter($sorted_order, $sorted_data->{$name});
            }
        }
    }

    return $sorted_data;
}

#----------------------------------------------------------------------
# Don't format anything

sub format_nothing {
    my ($self, $sorted_order, $value) = @_;
    return $value;
}

#----------------------------------------------------------------------
# Gather the data for building a variable's value

sub gather_data {
    my ($self, $method, $name, $item, $loop) = @_;

    my @data;
    $method = join('_', $method, $name);

    if ($self->can($method)) {
        @data = $self->$method($item, $loop);

    } else {
        @data = ();
    }

    my %data = $self->coerce_data($name, @data);
    return %data;
}

#----------------------------------------------------------------------
# Get the count of the item in the list

sub get_count {
    my ($self, $item, $loop) = @_;
    die "Can't use \$count outside of for\n" unless $loop;

    foreach my $i (0 .. @$loop) {
        if ($loop->[$i] eq $item) {
            my $count = $i + 1;
            return $count;
        }
    }

    return;
}

#----------------------------------------------------------------------
# Is this the first item in the list?

sub get_is_first {
    my ($self, $item, $loop) = @_;

    die "Can't use \$is_first outside of for\n" unless $loop;
    return $loop->[0] eq $item ? 1 : 0;
}

#----------------------------------------------------------------------
# Is this the last item in the list?

sub get_is_last {
    my ($self, $item, $loop) = @_;

    die "Can't use \$is_last outside of for\n"  unless $loop;
    return $loop->[-1] eq $item ? 1 : 0;
}

#----------------------------------------------------------------------
# Return the current list of loop items

sub get_loop {
    my ($self, $item, $loop) = @_;

    die "Can't use \@loop outside of for\n"  unless $loop;
    return $loop;
}

#----------------------------------------------------------------------
# Return the name of the current item in a loop

sub get_name {
    my ($self, $item) = @_;
    return $item;
}

#----------------------------------------------------------------------
# Get the current target

sub get_target {
    my ($self, $item, $loop) = @_;
    return $self->find_target(0, $item, $loop);
}

#----------------------------------------------------------------------
# Get the next target

sub get_target_next {
    my ($self, $item, $loop) = @_;
    return $self->find_target(1, $item, $loop);
}

#----------------------------------------------------------------------
# Get the previous target

sub get_target_previous {
    my ($self, $item, $loop) = @_;
    return $self->find_target(-1, $item, $loop);
}


#----------------------------------------------------------------------
# Augment the array to be sorted with the column to sort it by
sub make_augmented {
    my ($self, $sort_column, $data_column) = @_;

    my @augmented_list;
    for (my $i = 0; $i < @$sort_column; $i++) {
        push(@augmented_list, [$sort_column->[$i], $data_column->[$i]]);
    }

    return @augmented_list;
}

#----------------------------------------------------------------------
# Merge two sorted lists of augmented filenames

sub merge_augmented {
    my ($self, $list1, $list2) = @_;

    my @merged_list = ();
    my $sort_reverse = 1;
    my $comparer = $self->file_comparer($sort_reverse);

    while(@$list1 && @$list2) {
        last if @merged_list == $self->{list_length};
        if ($comparer->($list1->[0], $list2->[0]) > 0) {
            push(@merged_list, shift @$list2);
        } else {
            push(@merged_list, shift @$list1);
        }
    }

    while (@$list1) {
        last if @merged_list == $self->{list_length}; 
        push(@merged_list, shift @$list1);
    }

    while (@$list2) {
        last if @merged_list == $self->{list_length};
        push(@merged_list, shift @$list2);
    }

     return \@merged_list;
}

#----------------------------------------------------------------------
# Get a reference value and check it for agreement with the sigil

sub ref_value {
    my ($self, $value, $sigil, $data_field) = @_;

    my ($check, $ref_value);
    $value = '' unless defined $value;

    if ($sigil eq '$'){
        if (ref $value ne 'SCALAR') {
			# Convert data structures for inclusion in template
			$value = fio_flatten($value);
			$ref_value = \$value;
		} else {
			$ref_value = $value;
		}
        $check = ref $ref_value eq 'SCALAR';

    } elsif ($sigil eq '@') {
        $ref_value = $value;
        $check = ref $ref_value eq 'ARRAY';

    } elsif ($sigil eq '') {
        $ref_value = ref $value ? $value : \$value;
        $check = 1;
    }

    die "Unknown variable: $sigil$data_field\n" unless $check;
    return $ref_value;
}

#----------------------------------------------------------------------
# Set up the cache for data

sub setup {
    my ($self) = @_;

    $self->{cache} = {};
}

#----------------------------------------------------------------------
# Sort the data if it is in an array

sub sort {
    my ($self, $data, $sort_field, $sort_reverse) = @_;

    my $sorted_data;
    my $data_field = $self->find_data_field($data);

    if ($data_field) {
        my @augmented_data = $self->sort_with_field($data->{$data_field},
                                                    $sort_field, 
                                                    $sort_reverse);

        my @stripped_data = $self->strip_augmented(@augmented_data);
        $sorted_data = {$data_field => \@stripped_data};

    } else {
        $sorted_data = $data;
    }

    return $sorted_data;
}

#----------------------------------------------------------------------
# Sort augmented list by swartzian transform

sub sort_augmented {
    my ($self, $sort_reverse, @augmented_data) = @_;

    my $comparer = $self->file_comparer($sort_reverse);
    @augmented_data = sort $comparer @augmented_data;
    return @augmented_data;
}

#----------------------------------------------------------------------
# Sort data retaining the field you sort with

sub sort_with_field {
    my ($self, $data_column, $sort_field, $sort_reverse) = @_;
    $sort_field = 'name' unless defined $sort_field;
    $sort_reverse = 0 unless defined $sort_reverse;

    my $sort_column = $self->find_sort_column($data_column, $sort_field);

    return $self->sort_augmented($sort_reverse,
           $self->make_augmented($sort_column, $data_column));
}

#----------------------------------------------------------------------
# Return the filenames from an augmented set of files

sub strip_augmented {
    my $self = shift @_;
    return map {$_->[1]} @_;
}

#----------------------------------------------------------------------
# Split the sigil off from the variable name from a template

sub split_name {
    my ($self, $variable_name) = @_;

    my $name = $variable_name;
    $name =~ s/^([\$\@])//;
    my $sigil = $1 || '';

    return ($sigil, $name);
}

1;

=pod

=encoding utf-8

=head1 NAME

App::Followme::BaseData

=head1 SYNOPSIS

    use App::Followme::BaseData;
    my $meta = App::Followme::BaseData->new();
    my %data = $meta->build($name, $filename);

=head1 DESCRIPTION

This module is the base class for all metadata classes and provides the build
method used to interface metadata classes with the App::Followme::Template
class.

Followme uses templates to construct web pages. These templates contain
variables whose values are computed by calling the build method of the metadata
object, which is passed as an argument to the template function. The build
method returns either a reference to a scalar or list. The names correspond to
the variable names in the template. This class contains the build method, which
couples the variable name to the metadata object method that computes the value
of the variable.

=head1 METHODS

There is only one public method, build.

=over 4

=item my %data = $meta->build($name, $filename);

Build a variable's value. The first argument is the name of the variable
to be built. The second argument is the filename the variable is computed for.
If the variable returned is a list of files, this variable should be left
undefined.

=back

=head1 VARIABLES

The base metadata class can evaluate the following variables. When passing
a name to the build method, the sigil should not be used. All these variables
can only be used inside a for block.

=over 4

=item @loop

A list with all the loop items from the immediately enclosing for block.

=item $count

The count of the current item in the for block.The count starts at one.

=item $is_first

One if this is the first item in the for block, zero otherwise.

=item $is_last

One if this is the last item in the for block, zero otherwise

=item $name

The name of the current item in the for block.

=item $target

A string that can be used as a target for the location of the current item
in the page.

=item $target_next

A string that can be used as a target for the location of the next item
in the page. Empty if there is no next item.

=item $target_previous

A string that can be used as a target for the location of the previous item
in the page. Empty if there is no previous item.

=back

=head1 CONFIGURATION

There are two parameters:

=over 4

=item list_length

This determines the number of filenames in a merged list. The default
value of this parameter is 5

=item target_prefix

The prefix used to build the target names. The default value is 'target'.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut

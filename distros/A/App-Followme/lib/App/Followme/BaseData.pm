package App::Followme::BaseData;

use 5.008005;
use strict;
use warnings;
use integer;
use lib '../..';

use base qw(App::Followme::ConfiguredObject);

#----------------------------------------------------------------------
# Default values of parameters

sub parameters {
    my ($pkg) = @_;

    return (
            labels => 'previous,next',
            );
}

#----------------------------------------------------------------------
# Build a new variable value given its name and context

sub build {
    my ($self, $variable_name, $item, $loop) = @_;

    # Extract the sigil from the variable name, if present
    my ($sigil, $name) = $self->split_name($variable_name);

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
    unless (exists $cache{$name}) {
        my $sorted_order = $sigil eq '';
        my %data = $self->fetch_data($name, $item, $loop);
        %data = $self->format($sorted_order, %data);

        %cache = (%cache, %data);
    }

    # Check the value for agreement with the sigil and return reference
    my $ref_value = $self->ref_value($cache{$name}, $sigil, $name);
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
    return $self->gather_data('get', $name, $item, $loop);
}

#----------------------------------------------------------------------
# Apply an optional format to the data

sub format {
    my ($self, $sorted_order, %data) = @_;

    foreach my $name (keys %data) {
        my $method = join('_', 'format', $name);
        $data{$name} = $self->$method($sorted_order, $data{$name})
                       if $self->can($method);
    }

    return %data;
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
# Return the label for the current list item

sub get_label {
    my ($self, $item, $loop) = @_;

    die "Can't use \$label outside of for\n" unless $loop;

    my $count = $self->get_count($item, $loop);
    my @labels = split(/\s*,\s*/, $self->{labels});

    my $label;
    if (defined $count && $count <= @labels) {
        my @words = map {ucfirst $_} split(/\s+/, $labels[$count-1]);
        $label = join(' ', @words);
    } else {
        $label = '';
    }

    return $label;
}

#----------------------------------------------------------------------
# Return the current list of loop items

sub get_loop {
    my ($self, $item, $loop) = @_;

    die "Can't use \@loop outside of for\n"  unless $loop;
    return $loop;
}

#----------------------------------------------------------------------
# Return previous and next loop items

sub get_sequence {
    my ($self, $item, $loop) = @_;
    die "Can't use \@sequence outside of for\n"  unless $loop;

    my $match;
    foreach my $i (0 .. @$loop) {
        if ($loop->[$i] eq $item) {
            $match = $i;
            last;
        }
    }

    my @sequence;
    if (defined $match && $match > 0) {
        $sequence[0] = $loop->[$match-1];
    } else {
        $sequence[0] = '';
    }

    if (defined $match && $match < @$loop-1) {
        $sequence[1] = $loop->[$match+1];
    } else {
        $sequence[1] = '';
    }

    return \@sequence;
}

#----------------------------------------------------------------------
# Get a reference value and check it for agreement with the sigil

sub ref_value {
    my ($self, $value, $sigil, $name) = @_;

    my ($check, $ref_value);
    if ($sigil eq '$'){
        $value = '' unless defined $value;
        $ref_value = ref $value ? $value : \$value;
        $check = ref $ref_value eq 'SCALAR';

    } elsif ($sigil eq '@') {
        $ref_value = $value;
        $check = ref $ref_value eq 'ARRAY';

    } elsif ($sigil eq '' && defined $value) {
        $ref_value = ref $value ? $value : \$value;
        $check = 1;
    }

    die "Unknown variable: $sigil$name\n" unless $check;
    return $ref_value;
}

#----------------------------------------------------------------------
# Set up the cache for data

sub setup {
    my ($self, %configuration) = @_;

    $self->{cache} = {};
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

=item @sequence

A two item list containing the previous and next items in the for block. If the
current item is first or last, the corrsponding item in the sequence list will
be the empty string.

=item $count

The count of the current item in the for block.The count starts at one.

=item $is_first

One if this is the first item in the for block, zero otherwise.

=item $is_last

One if this is the last item in the for block, zero otherwise

=item $item

The current item in the for block.

=item $label

The string from the comma separated list of labels that corresponds to the
current item in a list.

=back

=head1 CONFIGURATION

There is one parameter:

=over 4

=item labels

A comma separated list of strings containing a list of labels to apply
to the values in a loop. The default value is "previous,next" and is
meant to be used with @sequence.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut

package DBIx::Simplish::Result;

# ABSTRACT: A result of a L<DBIx::Simplish> query.

use Moo;
use Types::Standard qw/InstanceOf Bool/;
use List::MoreUtils qw/zip/;
use Carp qw/croak/;
use Class::Load qw/load_class/;

our $VERSION = '1.002001'; # VERSION

has _sth => (
    is       => 'ro',
    required => 1,
    init_arg => 'sth',
    isa      => InstanceOf['DBI::st'],
    handles  => {
        _row_array => 'fetchrow_arrayref',
        _row_hash  => 'fetchrow_hashref',
        _all_array => 'fetchall_arrayref',
        _bind_cols => 'bind_columns',
        attr       => 'attr',
        rows       => 'rows',
        func       => 'func',
        fetch      => 'fetch',
        finish     => 'finish',
    },
);
has lc_columns => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

sub _col_case {
    my $self = shift;
    return $self->lc_columns ? 'NAME_lc' : 'NAME';
}

sub columns {
    my $self = shift;
    my $columns = $self->_sth->{$self->_col_case};
    return wantarray ? @{$columns} : $columns;
};

sub bind { ## no critic (RequireArgUnpacking, ProhibitBuiltinHomonyms)
    my $self = shift;
    return $self->_bind_cols(\@_[0..$#_]);
}

sub into { ## no critic (RequireArgUnpacking)
    my $self = shift;
    $self->_bind_cols(\@_[0..$#_]);
    return $self->fetch;
}

sub list {
    my $self = shift;
    my $list = $self->_row_array || [];
    return wantarray ? @{$list} : $list->[-1];
}

sub hash {
    my $self = shift;
    return $self->_row_hash($self->_col_case);
}

sub array {
    goto &_row_array;
}

sub kv_list {
    my $self = shift;
    return unless my @row = $self->list;
    my @columns = $self->columns;
    my @kv_list = zip(@columns, @row);
    return wantarray ? @kv_list : \@kv_list;
}

sub kv_array {
    my $self = shift;
    return scalar $self->kv_list
}

sub object {
    my ($self, $class, @args) = @_;
    $class = __PACKAGE__ . ":$class" if $class =~ /^:/;
    load_class($class);
    if ($class->can('new_from_dbix_simplish')) {
        return scalar $class->new_from_dbix_simplish($self, @args)
    } elsif ($class->can('new')) {
        return $class->new($self->kv_list);
    } else {
        croak(q/Can't locate object method "new_from_dbix_simplish" or "new"/);
    }
}

sub flat {
    my $self = shift;
    my @flat = map {@{$_}} $self->arrays;
    return wantarray ? @flat : \@flat;
}

sub arrays {
    my $self = shift;
    my $arrays = $self->_all_array;
    return wantarray ? @{$arrays} : $arrays;
}

sub hashes {
    my $self = shift;
    my @hashes;
    while (my $hash = $self->hash) {
        push @hashes, $hash;
    }
    return wantarray ? @hashes : \@hashes;
}

sub kv_flat {
    my $self = shift;
    my @flat = map {@{$_}} $self->kv_arrays;
    return wantarray ? @flat : \@flat;
}

sub kv_arrays {
    my $self = shift;
    my @arrays;
    while (my $array = $self->kv_array) {
        push @arrays, $array;
    }
    return wantarray ? @arrays : \@arrays;
}

sub objects {
    my ($self, $class, @args) = @_;
    $class = __PACKAGE__ . ":$class" if $class =~ /^:/;
    load_class($class);
    if ($class->can('new_from_dbix_simplish')) {
        my @objects = $class->new_from_dbix_simplish($self, @args);
        return wantarray ? @objects : \@objects;
    } elsif ($class->can('new')) {
        my @objects = map  {$class->new(@{$_})} $self->kv_arrays;
        return wantarray ? @objects : \@objects;
    } else {
        croak(q/Can't locate object method "new_from_dbix_simplish" or "new"/);
    }
}

sub map_arrays {
    my ($self, $col_num) = @_;
    my %map;
    while (my @array = $self->list) {
        my ($key) = splice @array, $col_num, 1;
        $map{$key} = \@array;
    }
    return wantarray ? %map : \%map;
}

sub map_hashes {
    my ($self, $col_name) = @_;
    my %map;
    while (my $map = $self->hash) {
        my $key = delete $map->{$col_name};
        $map{$key} = $map;
    }
    return wantarray ? %map : \%map;
}


sub map { ## no critic (ProhibitBuiltinHomonyms)
    my $self = shift;
    my %map = map {@{$_}} @{$self->_all_array([0, 1])};
    return wantarray ? %map : \%map;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Simplish::Result - A result of a L<DBIx::Simplish> query.

=head1 VERSION

version 1.002001

=head1 SYNOPSIS

    @columns = $result->columns

    $result->into($foo, $bar, $baz)
    $row = $result->fetch

    @row = $result->list      @rows = $result->flat
    $row = $result->array     @rows = $result->arrays
    $row = $result->hash      @rows = $result->hashes
    @row = $result->kv_list   @rows = $result->kv_flat
    $row = $result->kv_array  @rows = $result->kv_arrays

    %map = $result->map_arrays(...)
    %map = $result->map_hashes(...)
    %map = $result->map

    $rows = $result->rows

    $dump = $result->text

    $result->finish

=head1 DESCRIPTION

Result class for DBIx::Simplish

=head1 METHODS

=head2 attr(...)

Returns a copy of an sth attribute (property). See "Statement Handle Attributes" in DBI for details.

=head2 func(...)

This calls the func method on the sth of DBI. See DBI for details.

=head2 rows

Returns the number of rows affected by the last row affecting command, or -1 if the number of rows
is not known or not available.

For SELECT statements, it is generally not possible to know how many rows are returned. MySQL does
provide this information. See DBI for a detailed explanation.

=head2 finish

Finishes the statement. After finishing a statement, it can no longer be used. When the result
object is destroyed, its statement handle is automatically finished and destroyed. There should be
no reason to call this method explicitly; just let the result object go out of scope.

=head2 fetch

Returns a reference to the array that holds the values. This is the same array every time.

Subsequent fetches (using any method) may change the values in the variables passed and the returned
reference's array.

=head2 columns

Returns a list of column names. Affected by lc_columns.

=head2 bind(LIST)

Binds the given LIST of variables to the columns. Unlike with DBI's bind_columns, passing references is not needed.

Bound variables are very efficient. Binding a tied variable doesn't work.

=head2 into(LIST)

Combines bind with fetch. Returns what fetch returns.

=head2 list

Returns a list of values, or (in scalar context), only the last value.

=head2 hash

Returns a reference to a hash, keyed by column name. Affected by C<lc_columns>.

=head2 array

Returns a reference to an array.

=head2 kv_list

Returns an ordered list of interleaved keys and values. Affected by C<lc_columns>.

=head2 kv_array

Returns a reference to an array of interleaved column names and values. Like kv, but returns an array reference even in list context. Affected by C<lc_columns>.

=head2 object($class, ...)

Returns an instance of $class. Possibly affected by C<lc_columns>.

=head2 flat

Returns a flattened list.

=head2 arrays

Returns a list of references to arrays

=head2 hashes

Returns a list of references to hashes, keyed by column name. Affected by C<lc_columns>.

=head2 kv_flat

Returns an flattened list of interleaved column names and values. Affected by C<lc_columns>.

=head2 kv_arrays

Returns a list of references to arrays of interleaved column names and values. Affected by C<lc_columns>.

=head2 objects($class, ...)

Returns a list of instances of $class. Possibly affected by C<lc_columns>.

=head2 map_arrays($column_number)

Constructs a hash of array references keyed by the values in the chosen column, and returns a list of interleaved keys and values, or (in scalar context), a reference to a hash.

=head2 map_hashes($column_name)

Constructs a hash of hash references keyed by the values in the chosen column, and returns a list of interleaved keys and values, or (in scalar context), a reference to a hash. Affected by C<lc_columns>.

=head2 map

Constructs a simple hash, using the two columns as key/value pairs. Should only be used with queries that return two columns. Returns a list of interleaved keys and values, or (in scalar context), a reference to a hash.

=head1 SEE ALSO

L<DBIx::Simplish>

=head1 AUTHOR

Hans Staugaard <staugaard@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Hans Staugaard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

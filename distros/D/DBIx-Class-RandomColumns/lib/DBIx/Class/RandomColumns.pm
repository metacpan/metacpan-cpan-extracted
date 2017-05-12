package DBIx::Class::RandomColumns;

use strict;
use warnings;

our $VERSION = '0.005001';

use DBIx::Class 0.08009;

use parent qw/DBIx::Class/;

__PACKAGE__->mk_group_accessors(
    inherited => qw(
        _random_columns
        max_dup_checks
        default_field_size
        default_text_set
        default_int_max
        default_int_min
    )
);

__PACKAGE__->max_dup_checks(100);
__PACKAGE__->default_field_size(32);
__PACKAGE__->default_text_set(['0'..'9', 'a'..'z']);
__PACKAGE__->default_int_max(2*31-1);
__PACKAGE__->default_int_min(0);

=head1 NAME

DBIx::Class::RandomColumns - Implicit Random Columns

=head1 SYNOPSIS

  package My::Schema::Result::Utz;
  use parent 'DBIx::Class::Core';

  __PACKAGE__->load_components(qw/RandomColumns/);
  __PACKAGE__->table('utz');
  __PACKAGE__->add_columns(qw(id foo bar baz));
  __PACKAGE__->random_columns('id', bar => {size => 10});

  package My::Schema::Result::Gnarf;
  use parent 'DBIx::Class::Core';

  __PACKAGE__->load_components(qw/RandomColumns/);
  __PACKAGE__->table('gnarf');
  __PACKAGE__->add_columns(
    id => {
      datatype => 'integer',
      extra => {unsigned => 1},
      is_random => {max => 2**32-1, min => 0}
    },
    foo => {
      datatype => 'int',
      size => 10,
    },
    bar => {
      datatype => 'varchar',
      is_random => {size => 10},
      size => 32,
    },
    baz => {
      datatype => 'varchar',
      size => 255,
    },
  );

=head1 VERSION

This is version 0.004000

=head1 DESCRIPTION

This DBIx::Class component makes columns implicitly create random values.

The main reason why this module exists is to generate unpredictable primary
keys to add some additional security to web applications.  Most forms of
char and integer field types are supported.

=head1 METHODS

=cut

sub add_columns {
    my $class = shift;
    my @random_columns;
    my ($info, $opt);

    $class->next::method(@_);

    for my $column ($class->columns) {
        $info = $class->column_info($column);
        $opt = $info->{is_random}
            or next;
        push @random_columns, $column;
        push @random_columns, $opt
            if ref($opt) eq 'HASH';
    }
    $class->random_columns(@random_columns);

    return;	# nothing
}

=head2 remove_column

Hooks into L<DBIx::Class::ResultSource/remove_column> to remove the
random column configuration for the given column.

=cut

sub remove_column {
    my $class = shift;

    delete $class->random_columns->{$_[0]};

    return $class->next::method(@_);
}

=head2 remove_columns

Hooks into L<DBIx::Class::ResultSource/remove_columns> to remove the
random column configuration for the given columns.

=cut

sub remove_columns {
    my $class = shift;
    my $random_columns = $class->random_columns;

    delete $random_columns->{$_} for @_;

    return $class->next::method(@_);
}

=head2 random_columns

  __PACKAGE__->random_columns(@column_names);
  __PACKAGE__->random_columns(name1 => \%options1, name2 => \%options2);
  __PACKAGE__->random_columns(name1, name2 => \%options2);
  $random_columns = __PACKAGE__->random_columns;

Define or query fields that get random strings at creation. Each column
name may be followed by a hash reference containing options. In case no
explicit options are given, the method tries to find reasonable values.

Valid options are:

=over

=item C<max>:

Maximum number for integer fields. Defaults to C<2**31-1>. Must be an
integer number, that is greater than C<min> and should be positive.

=item C<min>:

Minimum number for integer fields. Defaults to C<0>. Must be an integer
number, that is lower than C<max> and can be negative unless the
corresponding field is not an unsigned integer.

=item C<set>:

A string or an array reference that contains the set of characters to use
for building a random content for string fields. The default set is
C<['0'..'9', 'a'..'z']>.

=item C<size>:

Length of the random string to create. Defaults to the size of the column or - if this
cannot be determined for whatever reason - to 32.

=item C<check>:

Search table before insert until generated column value is not found.
Defaults to false and must be set to a true value to activate.
Provided Perl's rand() function has sufficient entropy this lookup is only
usefull for short fields, because with the default set there are
C<36^field-size> possible combinations.

=back

Returns a hash reference, with column names of the random columns as keys and
hash references as values, that contain the random column settings.

=cut

sub random_columns {
    my $class = shift;
    my $random_auto_columns = $class->_random_columns || {};

    # act as read accessor when no arguments are given
    return $random_auto_columns unless @_;

    my ($col, $info, $opt);

    # loop over argument list
    while ($col = shift @_) {
        $info = $class->column_info($col);
        $class->throw_exception(qq{column "$col" doesn't exist})
            unless $class->has_column($col);
        $opt = ref $_[0] eq 'HASH' ? shift(@_) : {};

        # set auto column settings of current column
        # as a hash reference in $class->_random_columns;
        # the hash may contain:
        # min: minimum value for integer fields
        # max: maximum value for integer fields
        # set: set of character to build a random string
        # size: size of string fields
        # check: true=on / false=off
        my %conf = (check => $opt->{check});

        if (defined $opt->{max}) {
            $conf{max} = $opt->{max};
            $conf{min} = $opt->{min} || 0;
        }
        elsif (
            lc($info->{data_type} || '') =~ /^
                (?:
                    var(?:char2?|binary) |
                    (?:char(?:acter(?:\s+varying)?)?) |
                    binary |
                    (?:tiny|medium|long)?blob |
                    (?:tiny|medium|long)?text |
                    clob |
                    comment |
                    bytea
                )
            $/x
        ) {
            $conf{set} = defined($opt->{set}) ?
                             ref($opt->{set}) ?
                                 $opt->{set} : [split //, $opt->{set}] :
                                    $class->default_text_set;
            $conf{size} = $opt->{size} ||
                          $info->{size} ||
                          $class->default_field_size;
        }
        else {
            $conf{max} = 2**31-1;
            $conf{min} = 0;
        }
        $random_auto_columns->{$col} = \%conf;
    }

    # set internal class variable _random_columns
    return $class->_random_columns($random_auto_columns);
}

=head2 insert

Hooks into L<DBIx::Class::Row/insert> to create a random value for each
L<random column|/random_columns> that is not defined.

=cut

sub insert {
    my $self = shift;

    my $accessor;
    for (keys %{$self->random_columns}) {
        next if defined $self->get_column($_);	# skip if defined

        $accessor = $self->column_info($_)->{accessor} || $_;
        $self->$accessor($self->get_random_value($_));
    }
    return $self->next::method;
}

=head2 get_random_value

  $value = $instance->get_random_value($column_name);

Compute a random value for the given C<$column_name>.

Throws an exception if the concerning column has not been declared
as a random column.

=cut

sub get_random_value {
    my $self   = shift;
    my $column = shift;
    my $conf = $self->random_columns->{$column}
        or $self->throw_exception(qq{column "$column" is not a random column});
    my $check = $conf->{check};
    my $tries = $self->max_dup_checks;
    my $id;

    if ($conf->{max}) {
        # it's an integer column
        do { # check uniqueness if check => 1 for this column
            $id = int(rand($conf->{max} - $conf->{min} + 1)) + $conf->{min}
        } while $check and
                $tries-- and
                $self->result_source->resultset->search({$column => $id})->count;
    }
    else {
        my $set = $conf->{set};
        do { # check uniqueness if check => 1 for this column
            $id = '';
            # random id is as good as Perl's rand()
            $id .= $set->[int(rand(@$set))] for (1 .. $conf->{size});
        } while $check and
                $tries-- and
                $self->result_source->resultset->search({$column => $id})->count;
    }

    $self->throw_exception("escaped from busy loop in DBIx::Class::RandomColumns::get_random_column_id()")
        unless $tries;

    return $id;
}

1;

__END__

=head1 OPTIONS

=head2 is_random

  is_random => 1

  is_random => {size => 16, set => ['0'..'9','A'..'F']}

Instead of calling L</random_columns> it is also possible to specify option
C<is_random> in L<add_columns|DBIx::Class::ResultSource/add_columns>.
The value is either a true scalar value, indicating that this in fact is a
random column, or a hash reference, that has the same meaning as described
under L</random_columns>.

=head1 SEE ALSO

L<DBIx::Class>

=head1 AUTHOR

Bernhard Graf C<< <graf(a)cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dbix-class-randomclumns at rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-RandomColumns>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 - 2011 Bernhard Graf.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vim: set tabstop=4 shiftwidth=4 expandtab shiftround:

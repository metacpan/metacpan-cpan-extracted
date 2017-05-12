package Apache::FakeTable;
use strict;
use vars qw($VERSION);
$VERSION = '0.06';

=head1 Name

Apache::FakeTable - Pure Perl implementation of the Apache::Table interface

=head1 Synopsis

  use Apache::FakeTable;

  my $table = Apache::FakeTable->new($r);

  $table->set(From => 'david@example.com');

  $table->add(Cookie => 'One Cookie');
  $table->add(Cookie => 'Another Cookie');

  while(my($key, $val) = each %$table) {
      print "$key: $val\n";
  }

=head1 Description

This class emulates the behavior of the L<Apache::Table> class, and is
designed to behave exactly like Apache::Table. This means that all keys are
case-insensitive and may have multiple values. As a drop-in substitute for
Apache::Table, you should be able to use it exactly like Apache::Table.

You can treat an Apache::FakeTable object much like any other hash. However,
like Apache Table, those keys that contain multiple values will trigger
slightly different behavior than a traditional hash. The variations in
behavior are as follows:

=over

=item keys

Will return the same key multiple times, once for each value stored for that
key.

=item values

Will return the first value multiple times, once for each value stored for a
given key. It'd be nice if it returned all the values for a given key, instead
of the first value C<*> the number of values, but that's not the way
Apache::Table works, and I'm not sure I'd know how to implement it even if it
did!

=item each

Will return the same key multiple times, pairing it with each of its values
in turn.

=back

Otherwise, things should be quite hash-like, particularly when a key has only
a single value.

=head1 Interface

=head3 new()

  my $table = Apache::FakeTable->new($r);
  $table = Apache::FakeTable->new($r, $initial_size);

Returns a new C<Apache::FakeTable> object. An L<Apache> object is required as
the first argument. An optional second argument sets the initial size of the
table for storing values.

=cut

sub new {
    # We actually ignore the optional initial size argument.
    my ($class, $r) = @_;
    unless (UNIVERSAL::isa($r, 'Apache')) {
        require Carp;
        Carp::croak("Usage: " . __PACKAGE__ . "::new(pclass, r, nalloc=10)");
    }
    my $self = {};
    tie %{$self}, 'Apache::FakeTableHash';
    return bless $self, ref $class || $class;
}

=head3 get()

  my $value = $table->get($key);
  my @values = $table->get($key);
  my $value = $table->{$key};

Gets the value stored for a given key in the table. If a key has multiple
values, all will be returned when C<get()> is called in an array context, and
only the first value when it is called in a scalar context.

=cut

sub get {
    tied(%{shift()})->_get(@_);
}

=head3 set()

  $table->set($key, $value);
  $table->{$key} = $value;

Takes key and value arguments and sets the value for that key. Previous values
for that key will be discarded. The value must be a string, or C<set()> will
turn it into one. A value of C<undef> will be converted to the null string
('') a warning will be issued if warnings are enabled.

=cut

sub set {
    my ($self, $header, $value) = @_;
    # Issue a warning if the value is undefined.
    if (! defined $value and $^W) {
        require Carp;
        Carp::carp('Use of uninitialized value in null operation');
        $value = '';
    }
    $self->{$header} = $value;
}

=head3 unset()

  $table->unset($key);
  delete $table->{$key};

Takes a single key argument and deletes that key from the table, so that none
of its values will be in the table any longer.

=cut

sub unset {
    my $self = shift;
    delete $self->{shift()};
}

=head3 clear()

  $table->clear;
  %$table = ();

Clears the table of all values.

=cut

sub clear {
    %{shift()} = ();
}

=head3 add()

  $table->add($key, $value);

Adds a new value to the table. This method is the sole interface for adding
mutiple values for a single key.

=cut

sub add {
    # Issue a warning if the value is undefined.
    if (! defined $_[2] and $^W) {
        require Carp;
        Carp::carp('Use of uninitialized value in null operation');
        splice @_, 2, 1, '';
    }
    tied(%{shift()})->_add(@_);
}

=head3 merge()

  $table->merge($key, $value);

Merges a new value with an existing value by appending the new value to the
existing. The result is a string with the old value separated from the new by
a comma and a space. If C<$key> contains multiple values, then only the first
value will be used before appending the new value, and the remaining values
will be discarded.

=cut

sub merge {
    my ($self, $key, $value) = @_;
    if (exists $self->{$key}) {
        $self->{$key} .= ', ' . $value;
    } else {
        $self->{$key} = $value;
    }
}

=head3 do()

  $table->do($coderef);

Pass a code reference to this method to have it iterate over all of the
key/value pairs in the table. Keys with multiple values will trigger the
execution of the code reference multiple times, once for each value. The code
reference should expect two arguments: a key and a value. Iteration terminates
when the code reference returns false, so be sure to have it return a true
value if you want it to iterate over every value in the table.

=cut

sub do {
    my ($self, $code) = @_;
    while (my ($k, $val) = each %$self) {
        for my $v (ref $val ? @$val : $val) {
            return unless $code->($k => $v);
        }
    }
}

1;

##############################################################################
# This is the implementation of the case-insensitive hash that each table
# object is based on.
package
Apache::FakeTableHash;
use strict;
my %curr_keys;

sub TIEHASH {
    my $class = shift;
    return bless {}, ref $class || $class;
}

# Values are always stored as strings in an array.
sub STORE {
    my ($self, $key, $value) = @_;
    # Issue a warning if the value is undefined.
    if (! defined $value and $^W) {
        require Carp;
        Carp::carp('Use of uninitialized value in null operation');
        $value = '';
    }
    $self->{lc $key} = [ $key => ["$value"] ];
}

sub _add {
    my ($self, $key, $value) = @_;
    my $ckey = lc $key;
    if (exists $self->{$ckey}) {
        # Add it to the array,
        push @{$self->{$ckey}[1]}, "$value";
    } else {
        # It's a simple assignment.
        $self->{$ckey} = [ $key => ["$value"] ];
    }
}

sub DELETE {
    my ($self, $key) = @_;
    my $ret = delete $self->{lc $key};
    return $ret->[1][0];
}

sub FETCH {
    my $self = shift;
    my $key = lc shift;
    # Grab the values first so that we don't autovivicate the key.
    my $val = $self->{$key} or return;
    # If the key is the current key, return the value that's next. Otherwise,
    # return the first value.
    return $curr_keys{$self} && $curr_keys{$self}->[0] eq $key
      ? $val->[1][$curr_keys{$self}->[1]]
      : $val->[1][0];
}

sub _get {
    my ($self, $key) = @_;
    my $ckey = lc $key;
    # Prevent autovivication.
    return unless exists $self->{$ckey};
    # Return the array in an array context and just the first value in a
    # scalar context.
    return wantarray ? @{$self->{$ckey}[1]} : $self->{$ckey}[1][0];
}

sub CLEAR {
    %{shift()} = ();
}

sub EXISTS {
    my ($self, $key)= @_;
    return exists $self->{lc $key};
}

my $keyer = sub {
    my $self = shift;
    # Get the next key via perl's iterator.
    my $key = each %$self;
    # If there's no key, clear out our tracking of the current key and return.
    delete $curr_keys{$self}, return unless defined $key;
    # Cache the key and array index 0 for NEXTKEY and FETCH to use.
    $curr_keys{$self} = [ $key => 0 ];
    return $self->{$key}[0];
};

sub FIRSTKEY {
    my $self = shift;
    # Reset perl's iterator and then get the key.
    keys %$self;
    $self->$keyer();
}

sub NEXTKEY {
    my ($self, $last_key) = @_;
    # Return the last key if there are more values to be fetched for it.
    my $ckey = lc $last_key;
    return $last_key
      if $curr_keys{$self}->[0] eq $ckey
      && ++$curr_keys{$self}->[1] <= $#{$self->{$ckey}[1]};

    # Otherwise, just get the next key.
    $self->$keyer();
}

# Just be sure to clear out the current key.
sub DESTROY { delete $curr_keys{shift()}; }

1;
__END__

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/theory/apache-faketable/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/apache-faketable/issues/> or by sending mail to
L<bug-Apache-FakeTable@rt.cpan.org|mailto:bug-Apache-FakeTable@rt.cpan.org>.

=head1 See Also

L<Apache::Table>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2003-2011, David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

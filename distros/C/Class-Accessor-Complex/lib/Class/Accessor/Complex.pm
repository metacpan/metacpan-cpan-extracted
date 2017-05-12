use 5.008;
use strict;
use warnings;

package Class::Accessor::Complex;
our $VERSION = '1.100880';

# ABSTRACT: Arrays, hashes, booleans, integers, sets and more
use Carp qw(carp croak cluck);
use Data::Miscellany 'flatten';
use List::MoreUtils 'uniq';
use parent qw(Class::Accessor Class::Accessor::Installer);

sub mk_new {
    my ($self, @args) = @_;
    my $class = ref $self || $self;
    @args = ('new') unless @args;
    for my $name (@args) {
        $self->install_accessor(
            name => $name,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${name}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;

                # don't use $class, as that's already defined above
                my $this_class = shift;
                my $self = ref($this_class) ? $this_class : bless {},
                  $this_class;
                my %args =
                  (scalar(@_ == 1) && ref($_[0]) eq 'HASH')
                  ? %{ $_[0] }
                  : @_;
                $self->$_($args{$_}) for keys %args;
                $self->init(%args) if $self->can('init');
                $self;
            },
        );
        $self->document_accessor(
            name    => $name,
            purpose => <<'EODOC',
Creates and returns a new object. The constructor will accept as arguments a
list of pairs, from component name to initial value. For each pair, the named
component is initialized by calling the method of the same name with the given
value. If called with a single hash reference, it is dereferenced and its
key/value pairs are set as described before.
EODOC
            examples => [
                "my \$obj = $class->$name;",
                "my \$obj = $class->$name(\%args);",
            ],
        );
    }
    $self;    # for chaining
}

sub mk_singleton {
    my ($self, @args) = @_;
    my $class = ref $self || $self;
    @args = ('new') unless @args;
    my $singleton;
    for my $name (@args) {
        $self->install_accessor(
            name => $name,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${name}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;
                return $singleton if defined $singleton;

                # don't use $class, as that's already defined above
                my $this_class = shift;
                $singleton =
                  ref($this_class)
                  ? $this_class
                  : bless {}, $this_class;
                my %args =
                  (scalar(@_ == 1) && ref($_[0]) eq 'HASH')
                  ? %{ $_[0] }
                  : @_;
                $singleton->$_($args{$_}) for keys %args;
                $singleton->init(%args) if $singleton->can('init');
                $singleton;
            },
        );
        $self->document_accessor(
            name    => $name,
            purpose => <<'EODOC',
Creates and returns a new object. The object will be a singleton, so repeated
calls to the constructor will always return the same object. The constructor
will accept as arguments a list of pairs, from component name to initial
value. For each pair, the named component is initialized by calling the
method of the same name with the given value. If called with a single hash
reference, it is dereferenced and its key/value pairs are set as described
before.
EODOC
            examples => [
                "my \$obj = $class->$name;",
                "my \$obj = $class->$name(\%args);",
            ],
        );
    }
    $self;    # for chaining
}

sub mk_scalar_accessors {
    my ($self, @fields) = @_;
    my $class = ref $self || $self;
    for my $field (@fields) {
        $self->install_accessor(
            name => $field,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${field}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;
                return $_[0]->{$field} if @_ == 1;
                $_[0]->{$field} = $_[1];
            },
        );
        $self->document_accessor(
            name    => $field,
            purpose => <<'EODOC',
A basic getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it sets the value.
EODOC
            examples =>
              [ "my \$value = \$obj->$field;", "\$obj->$field(\$value);", ],
        );
        my @clear_methods = uniq "clear_${field}", "${field}_clear";
        for my $name (@clear_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    $_[0]->{$field} = undef;
                },
            );
        }
        $self->document_accessor(
            name       => \@clear_methods,
            purpose    => 'Clears the value.',
            examples   => ["\$obj->$clear_methods[0];"],
            belongs_to => $field,
        );
    }
    $self;    # for chaining
}

sub mk_class_scalar_accessors {
    my ($self, @fields) = @_;
    my $class = ref $self || $self;
    for my $field (@fields) {
        my $scalar;
        $self->install_accessor(
            name => $field,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${field}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;
                return $scalar if @_ == 1;
                $scalar = $_[1];
            },
        );
        $self->document_accessor(
            name    => $field,
            purpose => <<'EODOC',
A basic getter/setter method. This is a class variable, so it is shared
between all instances of this class. Changing it in one object will change it
for all other objects as well. If called without an argument, it returns the
value. If called with a single argument, it sets the value.
EODOC
            examples =>
              [ "my \$value = \$obj->$field;", "\$obj->$field(\$value);", ],
        );
        my @clear_methods = uniq "clear_${field}", "${field}_clear";
        for my $name (@clear_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    $scalar = undef;
                },
            );
        }
        $self->document_accessor(
            name    => \@clear_methods,
            purpose => <<'EODOC',
Clears the value. Since this is a class variable, the value will be undefined
for all instances of this class.
EODOC
            example    => "\$obj->$clear_methods[0];",
            belongs_to => $field,
        );
    }
    $self;    # for chaining
}

sub mk_concat_accessors {
    my ($self, @args) = @_;
    my $class = ref $self || $self;
    for my $arg (@args) {

        # defaults
        my $field = $arg;
        my $join  = '';
        if (ref $arg eq 'ARRAY') {
            ($field, $join) = @$arg;
        }
        $self->install_accessor(
            name => $field,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${field}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;
                my ($self, $text) = @_;
                if (defined $text) {
                    if (defined $self->{$field}) {
                        $self->{$field} = $self->{$field} . $join . $text;
                    } else {
                        $self->{$field} = $text;
                    }
                }
                return $self->{$field};
            },
        );
        $self->document_accessor(
            name => $field,

            # FIXME use the current value of $join in the docs
            purpose => <<'EODOC',
A getter/setter method. If called without an argument, it returns the
value. If called with a single argument, it appends to the current value.
EODOC
            examples =>
              [ "my \$value = \$obj->$field;", "\$obj->$field(\$value);", ],
        );
        my @clear_methods = uniq "clear_${field}", "${field}_clear";
        for my $name (@clear_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    $_[0]->{$field} = undef;
                },
            );
        }
        $self->document_accessor(
            name    => \@clear_methods,
            purpose => <<'EODOC',
Clears the value.
EODOC
            example    => "\$obj->$clear_methods[0];",
            belongs_to => $field,
        );
    }
    $self;    # for chaining
}

sub mk_array_accessors {
    my ($self, @fields) = @_;
    my $class = ref $self || $self;
    for my $field (@fields) {
        $self->install_accessor(
            name => $field,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${field}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;
                my ($self, @list) = @_;
                defined $self->{$field} or $self->{$field} = [];
                @{ $self->{$field} } =
                  map { ref $_ eq 'ARRAY' ? @$_ : ($_) } @list
                  if @list;
                wantarray ? @{ $self->{$field} } : $self->{$field};
            },
        );
        $self->document_accessor(
            name    => $field,
            purpose => <<'EODOC',
Get or set the array values. If called without arguments, it returns the
array in list context, or a reference to the array in scalar context. If
called with arguments, it expands array references found therein and sets the
values.
EODOC
            examples => [
                "my \@values    = \$obj->$field;",
                "my \$array_ref = \$obj->$field;",
                "\$obj->$field(\@values);",
                "\$obj->$field(\$array_ref);",
            ],
        );
        my @push_methods = uniq "push_${field}", "${field}_push";
        for my $name (@push_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    push @{ $self->{$field} } => @_;
                },
            );
        }
        $self->document_accessor(
            name       => \@push_methods,
            belongs_to => $field,
            purpose    => 'Pushes elements onto the end of the array.',
            examples   => ["\$obj->$push_methods[0](\@values);"],
        );
        my @pop_methods = uniq "pop_${field}", "${field}_pop";
        for my $name (@pop_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    pop @{ $_[0]->{$field} };
                },
            );
        }
        $self->document_accessor(
            name    => \@pop_methods,
            purpose => <<'EODOC',
Pops the last element off the array, returning it.
EODOC
            examples   => ["my \$value = \$obj->$pop_methods[0];"],
            belongs_to => $field,
        );
        my @unshift_methods = uniq "unshift_${field}", "${field}_unshift";
        for my $name (@unshift_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    unshift @{ $self->{$field} } => @_;
                },
            );
        }
        $self->document_accessor(
            name    => \@unshift_methods,
            purpose => <<'EODOC',
Unshifts elements onto the beginning of the array.
EODOC
            examples   => ["\$obj->$unshift_methods[0](\@values);"],
            belongs_to => $field,
        );
        my @shift_methods = uniq "shift_${field}", "${field}_shift";
        for my $name (@shift_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    shift @{ $_[0]->{$field} };
                },
            );
        }
        $self->document_accessor(
            name    => \@shift_methods,
            purpose => <<'EODOC',
Shifts the first element off the array, returning it.
EODOC
            examples   => ["my \$value = \$obj->$shift_methods[0];"],
            belongs_to => $field,
        );
        my @clear_methods = uniq "clear_${field}", "${field}_clear";
        for my $name (@clear_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    $_[0]->{$field} = [];
                },
            );
        }
        $self->document_accessor(
            name    => \@clear_methods,
            purpose => <<'EODOC',
Deletes all elements from the array.
EODOC
            examples   => ["\$obj->$clear_methods[0];"],
            belongs_to => $field,
        );
        my @count_methods = uniq "count_${field}", "${field}_count";
        for my $name (@count_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    exists $_[0]->{$field} ? scalar @{ $_[0]->{$field} } : 0;
                },
            );
        }
        $self->document_accessor(
            name    => \@count_methods,
            purpose => <<'EODOC',
Returns the number of elements in the array.
EODOC
            examples   => ["my \$count = \$obj->$count_methods[0];"],
            belongs_to => $field,
        );
        my @splice_methods = uniq "splice_${field}", "${field}_splice";
        for my $name (@splice_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my ($self, $offset, $len, @list) = @_;
                    splice(@{ $self->{$field} }, $offset, $len, @list);
                },
            );
        }
        $self->document_accessor(
            name    => \@splice_methods,
            purpose => <<'EODOC',
Takes three arguments: An offset, a length and a list.

Removes the elements designated by the offset and the length from the array,
and replaces them with the elements of the list, if any. In list context,
returns the elements removed from the array. In scalar context, returns the
last element removed, or C<undef> if no elements are removed. The array grows
or shrinks as necessary. If the offset is negative then it starts that far
from the end of the array. If the length is omitted, removes everything from
the offset onward. If the length is negative, removes the elements from the
offset onward except for -length elements at the end of the array. If both the
offset and the length are omitted, removes everything. If the offset is past
the end of the array, it issues a warning, and splices at the end of the
array.
EODOC
            examples => [
                "\$obj->$splice_methods[0](2, 1, \$x, \$y);",
                "\$obj->$splice_methods[0](-1);",
                "\$obj->$splice_methods[0](0, -1);",
            ],
            belongs_to => $field,
        );
        my @index_methods = uniq "index_${field}", "${field}_index";
        for my $name (@index_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my ($self, @indices) = @_;
                    my @result = map { $self->{$field}[$_] } @indices;
                    return $result[0] if @indices == 1;
                    wantarray ? @result : \@result;
                },
            );
        }
        $self->document_accessor(
            name    => \@index_methods,
            purpose => <<'EODOC',
Takes a list of indices and returns the elements indicated by those indices.
If only one index is given, the corresponding array element is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.
EODOC
            examples => [
                "my \$element   = \$obj->$index_methods[0](3);",
                "my \@elements  = \$obj->$index_methods[0](\@indices);",
                "my \$array_ref = \$obj->$index_methods[0](\@indices);",
            ],
            belongs_to => $field,
        );
        my @set_methods = uniq "set_${field}", "${field}_set";
        for my $name (@set_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${$name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    my @args = @_;
                    croak
"${class}::${field}_set expects an even number of fields\n"
                      if @args % 2;
                    while (my ($index, $value) = splice @args, 0, 2) {
                        $self->{$field}->[$index] = $value;
                    }
                    return @_ / 2;
                },
            );
        }
        $self->document_accessor(
            name    => \@set_methods,
            purpose => <<'EODOC',
Takes a list of index/value pairs and for each pair it sets the array element
at the indicated index to the indicated value. Returns the number of elements
that have been set.
EODOC
            examples   => ["\$obj->$set_methods[0](1 => \$x, 5 => \$y);"],
            belongs_to => $field,
        );
    }
    $self;    # for chaining
}

sub mk_class_array_accessors {
    my ($self, @fields) = @_;
    my $class = ref $self || $self;
    for my $field (@fields) {
        my @array;
        $self->install_accessor(
            name => $field,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${field}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;
                my ($self, @list) = @_;
                @array = map { ref $_ eq 'ARRAY' ? @$_ : ($_) } @list
                  if @list;
                wantarray ? @array : \@array;
            },
        );
        $self->document_accessor(
            name    => $field,
            purpose => <<'EODOC',
Get or set the array values. If called without an arguments, it returns the
array in list context, or a reference to the array in scalar context. If
called with arguments, it expands array references found therein and sets the
values.

This is a class variable, so it is shared between all instances of this class.
Changing it in one object will change it for all other objects as well.
EODOC
            examples => [
                "my \@values    = \$obj->$field;",
                "my \$array_ref = \$obj->$field;",
                "\$obj->$field(\@values);",
                "\$obj->$field(\$array_ref);",
            ],
        );
        my @push_methods = uniq "push_${field}", "${field}_push";
        for my $name (@push_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    push @array => @_;
                },
            );
        }
        $self->document_accessor(
            name    => \@push_methods,
            purpose => <<'EODOC',
Pushes elements onto the end of the array. Since this is a class variable, the
value will be changed for all instances of this class.
EODOC
            examples   => ["\$obj->$push_methods[0](\@values);"],
            belongs_to => $field,
        );
        my @pop_methods = uniq "pop_${field}", "${field}_pop";
        for my $name (@pop_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    pop @array;
                },
            );
        }
        $self->document_accessor(
            name    => \@pop_methods,
            purpose => <<'EODOC',
Pops the last element off the array, returning it. Since this is a class
variable, the value will be changed for all instances of this class.
EODOC
            examples   => ["my \$value = \$obj->$pop_methods[0];"],
            belongs_to => $field,
        );
        my @field_methods = uniq "unshift_${field}", "${field}_unshift";
        for my $name (@field_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    unshift @array => @_;
                },
            );
        }
        $self->document_accessor(
            name    => \@field_methods,
            purpose => <<'EODOC',
Unshifts elements onto the beginning of the array. Since this is a class
variable, the value will be changed for all instances of this class.
EODOC
            examples   => ["\$obj->$field_methods[0](\@values);"],
            belongs_to => $field,
        );
        my @shift_methods = uniq "shift_${field}", "${field}_shift";
        for my $name (@shift_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    shift @array;
                },
            );
        }
        $self->document_accessor(
            name    => \@shift_methods,
            purpose => <<'EODOC',
Shifts the first element off the array, returning it. Since this is a class
variable, the value will be changed for all instances of this class.
EODOC
            examples   => ["my \$value = \$obj->$shift_methods[0];"],
            belongs_to => $field,
        );
        my @clear_methods = uniq "clear_${field}", "${field}_clear";
        for my $name (@clear_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    @array = ();
                },
            );
        }
        $self->document_accessor(
            name    => \@clear_methods,
            purpose => <<'EODOC',
Deletes all elements from the array. Since this is a class variable, the value
will be changed for all instances of this class.
EODOC
            examples   => ["\$obj->$clear_methods[0];"],
            belongs_to => $field,
        );
        my @count_methods = uniq "count_${field}", "${field}_count";
        for my $name (@count_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    scalar @array;
                },
            );
        }
        $self->document_accessor(
            name    => \@count_methods,
            purpose => <<'EODOC',
Returns the number of elements in the array. Since this is a class variable,
the value will be changed for all instances of this class.
EODOC
            examples   => ["my \$count = \$obj->$count_methods[0];"],
            belongs_to => $field,
        );
        my @splice_methods = uniq "splice_${field}", "${field}_splice";
        for my $name (@splice_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my ($self, $offset, $len, @list) = @_;
                    splice(@array, $offset, $len, @list);
                },
            );
        }
        $self->document_accessor(
            name    => \@splice_methods,
            purpose => <<'EODOC',
Takes three arguments: An offset, a length and a list.

Removes the elements designated by the offset and the length from the array,
and replaces them with the elements of the list, if any. In list context,
returns the elements removed from the array. In scalar context, returns the
last element removed, or C<undef> if no elements are removed. The array grows
or shrinks as necessary. If the offset is negative then it starts that far
from the end of the array. If the length is omitted, removes everything from
the offset onward. If the length is negative, removes the elements from the
offset onward except for -length elements at the end of the array. If both the
offset and the length are omitted, removes everything. If the offset is past
the end of the array, it issues a warning, and splices at the end of the
array.

Since this is a class variable, the value will be changed for all instances of
this class.
EODOC
            examples => [
                "\$obj->$splice_methods[0](2, 1, \$x, \$y);",
                "\$obj->$splice_methods[0](-1);",
                "\$obj->$splice_methods[0](0, -1);",
            ],
            belongs_to => $field,
        );
        my @index_methods = uniq "index_${field}", "${field}_index";
        for my $name (@index_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my ($self, @indices) = @_;
                    my @result = map { $array[$_] } @indices;
                    return $result[0] if @indices == 1;
                    wantarray ? @result : \@result;
                },
            );
        }
        $self->document_accessor(
            name    => \@index_methods,
            purpose => <<'EODOC',
Takes a list of indices and returns the elements indicated by those indices.
If only one index is given, the corresponding array element is returned. If
several indices are given, the result is returned as an array in list context
or as an array reference in scalar context.

Since this is a class variable, the value will be changed for all instances of
this class.
EODOC
            examples => [
                "my \$element   = \$obj->$index_methods[0](3);",
                "my \@elements  = \$obj->$index_methods[0](\@indices);",
                "my \$array_ref = \$obj->$index_methods[0](\@indices);",
            ],
            belongs_to => $field,
        );
        my @set_methods = uniq "set_${field}", "${field}_set";
        for my $name (@set_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    my @args = @_;
                    croak
"${class}::${field}_set expects an even number of fields\n"
                      if @args % 2;
                    while (my ($index, $value) = splice @args, 0, 2) {
                        $array[$index] = $value;
                    }
                    return @_ / 2;
                },
            );
        }
        $self->document_accessor(
            name    => \@set_methods,
            purpose => <<'EODOC',
Takes a list of index/value pairs and for each pair it sets the array element
at the indicated index to the indicated value. Returns the number of elements
that have been set. Since this is a class variable, the value will be changed
for all instances of this class.
EODOC
            examples   => ["\$obj->$set_methods[0](1 => \$x, 5 => \$y);"],
            belongs_to => $field,
        );
    }
    $self;    # for chaining
}

sub mk_hash_accessors {
    my ($self, @fields) = @_;
    my $class = ref $self || $self;
    for my $field (@fields) {
        $self->install_accessor(
            name => $field,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${field}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;
                my ($self, @list) = @_;
                defined $self->{$field} or $self->{$field} = {};
                if (scalar @list == 1) {
                    my ($key) = @list;
                    if (my $type = ref $key) {
                        if ($type eq 'ARRAY') {
                            return @{ $self->{$field} }{@$key};
                        } elsif ($type eq 'HASH') {
                            while (my ($subkey, $value) = each %$key) {
                                $self->{$field}{$subkey} = $value;
                            }
                            return wantarray
                              ? %{ $self->{$field} }
                              : $self->{$field};
                        } else {
                            cluck
                              "Unrecognized ref type for hash method: $type.";
                        }
                    } else {
                        return $self->{$field}{$key};
                    }
                } else {
                    while (1) {
                        my $key = shift @list;
                        defined $key or last;
                        my $value = shift @list;
                        defined $value or carp "No value for key $key.";
                        $self->{$field}{$key} = $value;
                    }
                    return wantarray ? %{ $self->{$field} } : $self->{$field};
                }
            },
        );
        $self->document_accessor(
            name    => $field,
            purpose => <<'EODOC',
Get or set the hash values. If called without arguments, it returns the hash
in list context, or a reference to the hash in scalar context. If called
with a list of key/value pairs, it sets each key to its corresponding value,
then returns the hash as described before.

If called with exactly one key, it returns the corresponding value.

If called with exactly one array reference, it returns an array whose elements
are the values corresponding to the keys in the argument array, in the same
order. The resulting list is returned as an array in list context, or a
reference to the array in scalar context.

If called with exactly one hash reference, it updates the hash with the given
key/value pairs, then returns the hash in list context, or a reference to the
hash in scalar context.
EODOC
            examples => [
                "my \%hash     = \$obj->$field;",
                "my \$hash_ref = \$obj->$field;",
                "my \$value    = \$obj->$field(\$key);",
                "my \@values   = \$obj->$field([ qw(foo bar) ]);",
                "\$obj->$field(\%other_hash);",
                "\$obj->$field(foo => 23, bar => 42);",
            ],
        );
        my @clear_methods = uniq "clear_${field}", "${field}_clear";
        for my $name (@clear_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    $self->{$field} = {};
                },
            );
        }
        $self->document_accessor(
            name    => \@clear_methods,
            purpose => <<'EODOC',
Deletes all keys and values from the hash.
EODOC
            examples   => ["\$obj->$clear_methods[0];"],
            belongs_to => $field,
        );
        my @keys_methods = uniq "keys_${field}", "${field}_keys";
        for my $name (@keys_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    keys %{ $_[0]->{$field} };
                },
            );
        }
        $self->document_accessor(
            name    => \@keys_methods,
            purpose => <<'EODOC',
Returns a list of all hash keys in no particular order.
EODOC
            examples   => ["my \@keys = \$obj->$keys_methods[0];"],
            belongs_to => $field,
        );
        my @count_methods = uniq "count_${field}", "${field}_count";
        for my $name (@count_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    scalar keys %{ $_[0]->{$field} };
                },
            );
        }
        $self->document_accessor(
            name    => \@count_methods,
            purpose => <<'EODOC',
Returns the number of keys in the hash.
EODOC
            examples   => ["my \$count = \$obj->$count_methods[0];"],
            belongs_to => $field,
        );
        my @values_methods = uniq "values_${field}", "${field}_values";
        for my $name (@values_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    values %{ $_[0]->{$field} };
                },
            );
        }
        $self->document_accessor(
            name    => \@values_methods,
            purpose => <<'EODOC',
Returns a list of all hash values in no particular order.
EODOC
            examples   => ["my \@values = \$obj->$values_methods[0];"],
            belongs_to => $field,
        );
        my @exists_methods = uniq "exists_${field}", "${field}_exists";
        for my $name (@exists_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my ($self, $key) = @_;
                    exists $self->{$field} && exists $self->{$field}{$key};
                },
            );
        }
        $self->document_accessor(
            name    => \@exists_methods,
            purpose => <<'EODOC',
Takes a key and returns a true value if the key exists in the hash, and a
false value otherwise.
EODOC
            examples   => ["if (\$obj->$exists_methods[0](\$key)) { ... }"],
            belongs_to => $field,
        );
        my @delete_methods = uniq "delete_${field}", "${field}_delete";
        for my $name (@delete_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my ($self, @keys) = @_;
                    delete @{ $self->{$field} }{@keys};
                },
            );
        }
        $self->document_accessor(
            name => \@delete_methods,
            purpose =>
              'Takes a list of keys and deletes those keys from the hash.',
            examples   => ["\$obj->$delete_methods[0](\@keys);"],
            belongs_to => $field,
        );
    }
    $self;    # for chaining
}

sub mk_class_hash_accessors {
    my ($self, @fields) = @_;
    my $class = ref $self || $self;
    for my $field (@fields) {
        my %hash;
        $self->install_accessor(
            name => $field,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${field}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;
                my ($self, @list) = @_;
                if (scalar @list == 1) {
                    my ($key) = @list;
                    return $hash{$key} unless ref $key;
                    return @hash{@$key} if ref $key eq 'ARRAY';
                    if (ref($key) eq 'HASH') {
                        %hash = (%hash, %$key);
                        return wantarray ? %hash : \%hash;
                    }

                    # not a scalar, array or hash...
                    cluck sprintf
                      'Not a recognized ref type for static hash [%s]',
                      ref($key);
                } else {
                    while (1) {
                        my $key = shift @list;
                        defined $key or last;
                        my $value = shift @list;
                        defined $value or carp "No value for key $key.";
                        $hash{$key} = $value;
                    }
                    return wantarray ? %hash : \%hash;
                }
            },
        );
        $self->document_accessor(
            name    => $field,
            purpose => <<'EODOC',
Get or set the hash values. If called without arguments, it returns the hash
in list context, or a reference to the hash in scalar context. If called
with a list of key/value pairs, it sets each key to its corresponding value,
then returns the hash as described before.

If called with exactly one key, it returns the corresponding value.

If called with exactly one array reference, it returns an array whose elements
are the values corresponding to the keys in the argument array, in the same
order. The resulting list is returned as an array in list context, or a
reference to the array in scalar context.

If called with exactly one hash reference, it updates the hash with the given
key/value pairs, then returns the hash in list context, or a reference to the
hash in scalar context.

This is a class variable, so it is shared between all instances of this class.
Changing it in one object will change it for all other objects as well.
EODOC
            examples => [
                "my \%hash     = \$obj->$field;",
                "my \$hash_ref = \$obj->$field;",
                "my \$value    = \$obj->$field(\$key);",
                "my \@values   = \$obj->$field([ qw(foo bar) ]);",
                "\$obj->$field(\%other_hash);",
                "\$obj->$field(foo => 23, bar => 42);",
            ],
        );
        my @clear_methods = uniq "clear_${field}", "${field}_clear";
        for my $name (@clear_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    %hash = ();
                },
            );
        }
        $self->document_accessor(
            name    => \@clear_methods,
            purpose => <<'EODOC',
Deletes all keys and values from the hash. Since this is a class variable, the
value will be changed for all instances of this class.
EODOC
            examples => ["\$obj->$clear_methods[0];"],
        );
        my @keys_methods = uniq "keys_${field}", "${field}_keys";
        for my $name (@keys_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    keys %hash;
                },
            );
        }
        $self->document_accessor(
            name    => \@keys_methods,
            purpose => <<'EODOC',
Returns a list of all hash keys in no particular order. Since this is a class
variable, the value will be changed for all instances of this class.
EODOC
            examples   => ["my \@keys = \$obj->$keys_methods[0];"],
            belongs_to => $field,
        );
        my @values_methods = uniq "values_${field}", "${field}_values";
        for my $name (@values_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    values %hash;
                },
            );
        }
        $self->document_accessor(
            name    => \@values_methods,
            purpose => <<'EODOC',
Returns a list of all hash values in no particular order. Since this is a
class variable, the value will be changed for all instances of this class.
EODOC
            examples   => ["my \@values = \$obj->$values_methods[0];"],
            belongs_to => $field,
        );
        my @exists_methods = uniq "exists_${field}", "${field}_exists";
        for my $name (@exists_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    exists $hash{ $_[1] };
                },
            );
        }
        $self->document_accessor(
            name    => \@exists_methods,
            purpose => <<'EODOC',
Takes a key and returns a true value if the key exists in the hash, and a
false value otherwise. Since this is a class variable, the value will be
changed for all instances of this class.
EODOC
            examples   => ["if (\$obj->$exists_methods[0](\$key)) { ... }"],
            belongs_to => $field,
        );
        my @delete_methods = uniq "delete_${field}", "${field}_delete";
        for my $name (@delete_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my ($self, @keys) = @_;
                    delete @hash{@keys};
                },
            );
        }
        $self->document_accessor(
            name    => \@delete_methods,
            purpose => <<'EODOC',
Takes a list of keys and deletes those keys from the hash. Since this is a
class variable, the value will be changed for all instances of this class.
EODOC
            examples   => ["\$obj->$delete_methods[0](\@keys);"],
            belongs_to => $field,
        );
    }
    $self;    # for chaining
}

sub mk_abstract_accessors {
    my ($self, @fields) = @_;
    my $class = ref $self || $self;
    for my $field (@fields) {
        $self->install_accessor(
            name => $field,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${field}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;
                my $method = "${class}::${field}";
                eval "require Error::Hierarchy::Internal::AbstractMethod";
                if ($@) {

                    # Error::Hierarchy not installed?
                    die sprintf "called abstract method [%s]", $method;
                } else {

                    # need to pass method because caller() still doesn't see the
                    # anonymously named sub's name
                    throw Error::Hierarchy::Internal::AbstractMethod(
                        method => $method,);
                }
            }
        );
    }
    $self;    # for chaining
}

sub mk_boolean_accessors {
    my ($self, @fields) = @_;
    my $class = ref $self || $self;
    for my $field (@fields) {
        $self->install_accessor(
            name => $field,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${field}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;
                return $_[0]->{$field} if @_ == 1;
                $_[0]->{$field} = $_[1] ? 1 : 0;    # normalize
            },
        );
        $self->document_accessor(
            name    => $field,
            purpose => <<'EODOC',
If called without an argument, returns the boolean value (0 or 1). If called
with an argument, it normalizes it to the boolean value. That is, the values
0, undef and the empty string become 0; everything else becomes 1.
EODOC
            examples =>
              [ "\$obj->$field(\$value);", "my \$value = \$obj->$field;", ],
        );
        my @set_methods = uniq "set_${field}", "${field}_set";
        for my $name (@set_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    $_[0]->{$field} = 1;
                },
            );
        }
        $self->document_accessor(
            name       => \@set_methods,
            purpose    => 'Sets the boolean value to 1.',
            examples   => ["\$obj->$set_methods[0];"],
            belongs_to => $field,
        );
        my @clear_methods = uniq "clear_${field}", "${field}_clear";
        for my $name (@clear_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    $_[0]->{$field} = 0;
                },
            );
        }
        $self->document_accessor(
            name       => \@clear_methods,
            purpose    => 'Clears the boolean value by setting it to 0.',
            examples   => ["\$obj->$clear_methods[0];"],
            belongs_to => $field,
        );
    }
    $self;    # for chaining
}

sub mk_integer_accessors {
    my ($self, @fields) = @_;
    my $class = ref $self || $self;
    for my $field (@fields) {
        $self->install_accessor(
            name => $field,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${field}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;
                my $self = shift;
                return $self->{$field} || 0 unless @_;
                $self->{$field} = shift;
            },
        );
        $self->document_accessor(
            name    => $field,
            purpose => <<'EODOC',
A basic getter/setter method. If called without an argument, it returns the
value, or 0 if there is no previous value. If called with a single argument,
it sets the value.
EODOC
            examples =>
              [ "\$obj->$field(\$value);", "my \$value = \$obj->$field;", ],
        );
        my @reset_methods = uniq "reset_${field}", "${field}_reset";
        for my $name (@reset_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    $_[0]->{$field} = 0;
                },
            );
        }
        $self->document_accessor(
            name       => \@reset_methods,
            purpose    => 'Resets the value to 0.',
            examples   => ["\$obj->$reset_methods[0];"],
            belongs_to => $field,
        );
        my @inc_methods = uniq "inc_${field}", "${field}_inc";
        for my $name (@inc_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    $_[0]->{$field}++;
                },
            );
        }
        $self->document_accessor(
            name       => \@inc_methods,
            purpose    => 'Increases the value by 1.',
            examples   => ["\$obj->$inc_methods[0];"],
            belongs_to => $field,
        );
        my @dec_methods = uniq "dec_${field}", "${field}_dec";
        for my $name (@dec_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    $_[0]->{$field}--;
                },
            );
        }
        $self->document_accessor(
            name       => \@dec_methods,
            purpose    => 'Decreases the value by 1.',
            examples   => ["\$obj->$dec_methods[0];"],
            belongs_to => $field,
        );
    }
    $self;    # for chaining
}

sub mk_set_accessors {
    my ($self, @fields) = @_;
    my $class = ref $self || $self;
    for my $field (@fields) {
        my $insert_method   = "${field}_insert";
        my $elements_method = "${field}_elements";
        $self->install_accessor(
            name => $field,
            code => sub {
                local $DB::sub = local *__ANON__ = "${class}::${field}"
                  if defined &DB::DB && !$Devel::DProf::VERSION;
                my $self = shift;
                if (@_) {
                    $self->$insert_method(@_);
                } else {
                    $self->$elements_method;
                }
            },
        );
        $self->document_accessor(
            name    => $field,
            purpose => <<'EODOC',
A set is like an array except that each element can occur only one. It is,
however, not ordered. If called with a list of arguments, it adds those
elements to the set. If the first argument is an array reference, the values
contained therein are added to the set. If called without arguments, it
returns the elements of the set.
EODOC
            examples => [
                "my \@elements = \$obj->$field;",
                "\$obj->$field(\@elements);",
            ],
        );
        my @insert_methods = uniq "insert_${field}", $insert_method;
        for my $name (@insert_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    $self->{$field}{$_}++ for flatten(@_);
                },
            );
        }
        $self->document_accessor(
            name    => \@insert_methods,
            purpose => <<'EODOC',
If called with a list of arguments, it adds those elements to the set. If the
first argument is an array reference, the values contained therein are added
to the set.
EODOC
            examples   => ["\$obj->$insert_methods[0](\@elements);"],
            belongs_to => $field,
        );
        my @elements_methods = uniq "elements_${field}", $elements_method;
        for my $name (@elements_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    $self->{$field} ||= {};
                    keys %{ $self->{$field} };
                },
            );
        }
        $self->document_accessor(
            name       => \@elements_methods,
            purpose    => 'Returns the elements of the set.',
            examples   => ["my \@elements = \$obj->$elements_methods[0];"],
            belongs_to => $field,
        );
        my @delete_methods = uniq "delete_${field}", "${field}_delete";
        for my $name (@delete_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    delete $self->{$field}{$_} for @_;
                },
            );
        }
        $self->document_accessor(
            name    => \@delete_methods,
            purpose => <<'EODOC',
If called with a list of values, it deletes those elements from the set.
EODOC
            examples   => ["\$obj->$delete_methods[0](\@elements);"],
            belongs_to => $field,
        );
        my @clear_methods = uniq "clear_${field}", "${field}_clear";
        for my $name (@clear_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    $_[0]->{$field} = {};
                },
            );
        }
        $self->document_accessor(
            name       => \@clear_methods,
            purpose    => 'Deletes all elements from the set.',
            examples   => ["\$obj->$clear_methods[0];"],
            belongs_to => $field,
        );
        my @contains_methods = uniq "contains_${field}", "${field}_contains";
        for my $name (@contains_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my ($self, $key) = @_;
                    return unless defined $key;
                    exists $self->{$field}{$key};
                },
            );
        }
        $self->document_accessor(
            name    => \@contains_methods,
            purpose => <<'EODOC',
Takes a single key and returns a boolean value indicating whether that key is
an element of the set.
EODOC
            examples => ["if (\$obj->$contains_methods[0](\$element)) { ... }"],
            ,
            belongs_to => $field,
        );
        my @is_empty_methods = uniq "is_empty_${field}", "${field}_is_empty";
        for my $name (@is_empty_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    keys %{ $self->{$field} || {} } == 0;
                },
            );
        }
        $self->document_accessor(
            name => \@is_empty_methods,
            purpose =>
'Returns a boolean value indicating whether the set is empty of not.',
            examples   => ["\$obj->$is_empty_methods[0];"],
            belongs_to => $field,
        );
        my @size_methods = uniq "size_${field}", "${field}_size";
        for my $name (@size_methods) {
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my $self = shift;
                    scalar keys %{ $self->{$field} || {} };
                },
            );
        }
        $self->document_accessor(
            name       => \@size_methods,
            purpose    => 'Returns the number of elements in the set.',
            examples   => ["my \$size = \$obj->$size_methods[0];"],
            belongs_to => $field,
        );
    }
    $self;    # for chaining
}

sub mk_object_accessors {
    my ($self, @args) = @_;
    my $class = ref $self || $self;
    while (@args) {
        my $type = shift @args;
        my $list = shift @args or die "No slot names for $class";

        # Allow a list of hashrefs.
        my @list = ref($list) eq 'ARRAY' ? @$list : ($list);
        for my $obj_def (@list) {
            my ($name, @composites);
            if (!ref $obj_def) {
                $name = $obj_def;
            } else {
                $name = $obj_def->{slot};
                my $composites = $obj_def->{comp_mthds};
                @composites =
                    ref($composites) eq 'ARRAY' ? @$composites
                  : defined $composites ? ($composites)
                  :                       ();
            }
            for my $meth (@composites) {
                $self->install_accessor(
                    name => $meth,
                    code => sub {
                        local $DB::sub = local *__ANON__ = "${class}::{$meth}"
                          if defined &DB::DB && !$Devel::DProf::VERSION;
                        my ($self, @args) = @_;
                        $self->$name()->$meth(@args);
                    },
                );
                $self->document_accessor(
                    name    => $meth,
                    purpose => <<EODOC,
Calls $meth() with the given arguments on the object stored in the $name slot.
If there is no such object, a new $type object is constructed - no arguments
are passed to the constructor - and stored in the $name slot before forwarding
$meth() onto it.
EODOC
                    examples => [ "\$obj->$meth(\@args);", "\$obj->$meth;", ],
                );
            }
            $self->install_accessor(
                name => $name,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${name}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my ($self, @args) = @_;
                    if (ref($args[0]) && UNIVERSAL::isa($args[0], $type)) {
                        $self->{$name} = $args[0];
                    } else {
                        defined $self->{$name}
                          or $self->{$name} = $type->new(@args);
                    }
                    $self->{$name};
                },
            );
            $self->document_accessor(
                name    => $name,
                purpose => <<EODOC,
If called with an argument object of type $type it sets the object; further
arguments are discarded. If called with arguments but the first argument is
not an object of type $type, a new object of type $type is constructed and the
arguments are passed to the constructor.

If called without arguments, it returns the $type object stored in this slot;
if there is no such object, a new $type object is constructed - no arguments
are passed to the constructor in this case - and stored in the $name slot
before returning it.
EODOC
                examples => [
                    "my \$object = \$obj->$name;", "\$obj->$name(\$object);",
                    "\$obj->$name(\@args);",
                ],
            );
            my @clear_methods = uniq "clear_${name}", "${name}_clear";
            for my $meth (@clear_methods) {
                $self->install_accessor(
                    name => $meth,
                    code => sub {
                        local $DB::sub = local *__ANON__ = "${class}::${meth}"
                          if defined &DB::DB && !$Devel::DProf::VERSION;
                        delete $_[0]->{$name};
                    },
                );
            }
            $self->document_accessor(
                name       => \@clear_methods,
                purpose    => 'Deletes the object.',
                examples   => "\$obj->$clear_methods[0];",
                belongs_to => $name,
            );
        }
    }
    $self;    # for chaining
}

sub mk_forward_accessors {
    my ($self, %args) = @_;
    my $class = ref $self || $self;
    while (my ($slot, $methods) = each %args) {
        my @methods = ref $methods eq 'ARRAY' ? @$methods : ($methods);
        for my $field (@methods) {
            $self->install_accessor(
                name => $field,
                code => sub {
                    local $DB::sub = local *__ANON__ = "${class}::${field}"
                      if defined &DB::DB && !$Devel::DProf::VERSION;
                    my ($self, @args) = @_;
                    $self->$slot()->$field(@args);
                },
            );
            $self->document_accessor(
                name    => $field,
                purpose => <<EODOC,
Calls $field() with the given arguments on the object stored in the $slot
slot. 
EODOC
                examples => [ "\$obj->$field(\@args);", "\$obj->$field;", ],
            );
        }
    }
    $self;    # for chaining
}
1;


__END__
=pod

=head1 NAME

Class::Accessor::Complex - Arrays, hashes, booleans, integers, sets and more

=head1 VERSION

version 1.100880

=head1 SYNOPSIS

  package MyClass;
  use base 'Class::Accessor::Complex';
  __PACKAGE__
      ->mk_new
      ->mk_array_accessors(qw(an_array))
      ->mk_hash_accessors(qw(a_hash))
      ->mk_integer_accessors(qw(an_integer))
      ->mk_class_hash_accessors(qw(a_hash))
      ->mk_set_accessors(qw(testset))
      ->mk_object_accessors('Some::Foo' => {
          slot => 'an_object',
          comp_mthds => [ qw(do_this do_that) ]
      });

=head1 DESCRIPTION

This module generates accessors for your class in the same spirit as
L<Class::Accessor> does. While the latter deals with accessors for scalar
values, this module provides accessor makers for arrays, hashes, integers,
booleans, sets and more.

As seen in the synopsis, you can chain calls to the accessor makers. Also,
because this module inherits from L<Class::Accessor>, you can put a call
to one of its accessor makers at the end of the chain.

The accessor generators also generate documentation ready to be used with
L<Sub::Documentation>.

=head1 METHODS

=head2 mk_new

Takes an array of strings as its argument. If no argument is given, it uses
C<new> as the default. For each string it creates a constructor of that name.
The constructor accepts named arguments - that is, a hash - and will set the
hash values on the accessor methods denoted by the keys. For example,

    package MyClass;
    use base 'Class::Accessor::Complex';
    __PACKAGE__->mk_new;

    package main;
    use MyClass;

    my $o = MyClass->new(foo => 12, bar => [ 1..5 ]);

is the same as

    my $o = MyClass->new;
    $o->foo(12);
    $o->bar([1..5]);

The constructor will also call an C<init()> method, if there is one.

=head2 mk_singleton

Takes an array of strings as its argument. If no argument is given, it uses
C<new> as the default. For each string it creates a constructor of that name.

This constructor only ever returns a single instance of the class. That is,
after the first call, repeated calls to this constructor return the
I<same> instance.  Note that the instance is instantiated at the time of
the first call, not before. Any arguments are treated as for C<mk_new()>.
Naturally, C<init()> and any initializer methods are called only by the
first invocation of this method. 

=head2 mk_scalar_accessors

Takes an array of strings as its argument. For each string it creates methods
as described below, where C<*> denotes the slot name.

=over 4

=item C<*>

This method can store a value in a slot and retrieve that value. If it
receives an argument, it sets the value. Only the first argument is used,
subsequent arguments are ignored. If called without a value, the method
retrieves the value from the slot.

=item C<*_clear>, C<clear_*>

Clears the value by setting it to undef.

=back

=head2 mk_class_scalar_accessors

Takes an array of strings as its argument. For each string it creates methods
like those generated with C<mk_scalar_accessors()>, except that it is a class
scalar, i.e. shared by all instances of the class.

=head2 mk_concat_accessors

Takes an array of strings as its argument. For each string it creates methods
as described below, where C<*> denotes the slot name.

=over 4

=item C<*>

Like C<mk_scalar_accessors()>, but passing a value to the accessor doesn't
clear out the original value, but instead concatenates the new value to the
existing one. Thus, this kind of accessor is only good for plain scalars.

=item C<*_clear>, C<clear_*>

Clears the value by setting it to undef.

=back

=head2 mk_array_accessors

Takes an array of strings as its argument. For each string it creates methods
as described below, where C<*> denotes the slot name.

=over 4

=item C<*>

This method returns the list of values stored in the slot. If any arguments
are provided to this method, they I<replace> the current list contents. In an
array context it returns the values as an array and in a scalar context as a
reference to the array. Note that this reference is currently a direct
reference to the storage; changes to the storage will affect the contents of
the reference, and vice-versa. This behaviour is not guaranteed; caveat
emptor.

=item C<*_push>, C<push_*>

Pushes the given elements onto the end of the array. Like perl's C<push()>.

=item C<*_pop>, C<pop_*>

Pops one element off the end of the array. Like perl's C<pop()>.

=item C<*_shift>, C<shift_*>

Shifts one element off the beginning of the array. Like perl's C<shift()>.

=item C<*_unshift>, C<unshift_*>

Unshifts the given elements onto the beginning of the array. Like perl's
C<unshift()>.

=item C<*_splice>, C<splice_*>

Takes an offset, a length and a replacement list. The arguments and behaviour
are exactly like perl's C<splice()>.

=item C<*_clear>, C<clear_*>

Deletes all elements of the array.

=item C<*_count>, C<count_*>

Returns the number of elements in the array.

=item C<*_set>, C<set_*>

Takes a list, treated as pairs of index => value; each given index is
set to the corresponding value. No return.

=item C<*_index>, C<index_*>

Takes a list of indices and returns a list of the corresponding values. This is like an array slice.

=back

=head2 mk_class_array_accessors

Takes an array of strings as its argument. For each string it creates methods
like those generated with C<mk_array_accessors()>, except that it is a class
hash, i.e. shared by all instances of the class.

=head2 mk_hash_accessors

Takes an array of strings as its argument. For each string it creates methods
as described below, where C<*> denotes the slot name.

=over 4

=item C<*>

Called with no arguments returns the hash stored in the slot, as a hash
in a list context or as a reference in a scalar context.

Called with one simple scalar argument it treats the argument as a key
and returns the value stored under that key.

Called with one array (list) reference argument, the array elements
are considered to be be keys of the hash. x returns the list of values
stored under those keys (also known as a I<hash slice>.)

Called with one hash reference argument, the keys and values of the
hash are added to the hash.

Called with more than one argument, treats them as a series of key/value
pairs and adds them to the hash.

=item C<*_keys>, C<keys_*>

Returns the keys of the hash.

=item C<*_count>, C<count_*>

Returns the number of keys in the hash.

=item C<*_values>, C<values_*>

Returns the list of values.

=item C<*_exists>, C<exists_*>

Takes a single key and returns whether that key exists in the hash.

=item C<*_delete>, C<delete_*>

Takes a list and deletes each key from the hash.

=item C<*_clear>, C<clear_*>

Resets the hash to empty.

=back

=head2 mk_class_hash_accessors

Takes an array of strings as its argument. For each string it creates methods
like those generated with C<mk_hash_accessors()>, except that it is a class
hash, i.e. shared by all instances of the class.

=head2 mk_abstract_accessors

Takes an array of strings as its argument. For each string it creates methods
as described below, where C<*> denotes the slot name.

=over 4

=item C<*>

When called, it either dies (if L<Error::Hierarchy> is not installed) or
throws an exception of type L<Error::Hierarchy::Internal::AbstractMethod> (if
it is installed).

=back

=head2 mk_boolean_accessors

Takes an array of strings as its argument. For each string it creates methods
as described below, where C<*> denotes the slot name.

=over 4

=item C<*>

If given a true value - in the Perl sense, i.e. anything except C<undef>, C<0>
or the empty string - it sets the slot's value to C<1>, otherwise to C<0>. If
no argument is given, it returns the slot's value.

=item C<*_set>, C<set_*>

Sets the slot's value to C<1>.

=item C<*_clear>, C<clear_*>

Sets the slot's value to C<0>.

=back

=head2 mk_integer_accessors

    __PACKAGE__->mk_integer_accessors(qw(some_counter other_index));

Takes a list of accessor base names (simple strings). For each string it
creates methods as described below, where C<*> denotes the accessor base name.

=over 4

=item C<*>

A basic getter/setter that stores an integer value. Actually, it can store any
value, but when read back, it returns 0 if the value is undef.

=item C<*_reset>, C<reset_*>

Resets the slot's value to 0.

=item C<*_inc>, C<inc_*>

Increments the value, then returns it.

=item C<*_dec>, C<dec_*>

Decrements the value, then returns it.

=back

Example:

  package Foo;

  use base 'Class::Accessor::Complex';
  __PACKAGE__->mk_integer_accessors(qw(score));

Then:

  my $obj = Foo->new(score => 150);
  my $x = $obj->score_inc;   # is now 151
  $obj->score_reset;         # is now 0

=head2 mk_set_accessors

Takes an array of strings as its argument. For each string it creates methods
as described below, where C<*> denotes the slot name.

A set is different from a list in that it can contain every value only once
and there is no order on the elements (similar to hash keys, for example).

=over 4

=item C<*>

If called without arguments, it returns the elements in the set. If called
with arguments, it puts those elements into the set. As such, it is a wrapper
over C<*_insert()> and C<*_elements()>.

=item C<*_insert>, C<insert_*>

Inserts the given elements (arguments) into the set. If you pass an array
reference as the first argument, it is being dereferenced and used instead.

=item C<*_elements>, C<elements_*>

Returns the elements in the set.

=item C<*_delete>, C<delete_*>

Removes the given elements from the list. The order in which the elements are
returned is not guaranteed.

=item C<*_clear>, C<clear_*>

Empties the set.

=item C<*_contains>, C<contains_*>

Given an element, it returns whether the set contains the element.

=item C<*_is_empty>, C<is_empty_*>

Returns whether or not the set is empty.

=item C<*_size>, C<size_*>

Returns the number of elements in the set.

=back

=head2 mk_object_accessors

    MyClass->mk_object_accessors(
        'Foo' => 'phooey',
        'Bar' => [ qw(bar1 bar2 bar3) ],
        'Baz' => {
            slot => 'foo',
            comp_mthds => [ qw(bar baz) ]
        },
        'Fob' => [
            {
                slot       => 'dog',
                comp_mthds => 'bark',
            },
            {
                slot       => 'cat',
                comp_mthds => 'miaow',
            },
        ],
    );

The main argument should be a reference to an array. The array should contain
pairs of class => sub-argument pairs. The sub-arguments parsed thus:

=over 4

=item Hash Reference

See C<Baz> above. The hash should contain the following keys:

=over 4

=item C<slot>

The name of the instance attribute (slot).

=item C<comp_mthds>

A string or array reference, naming the methods that will be forwarded
directly to the object in the slot.

=back

=item Array Reference

As for C<String>, for each member of the array. Also works if each member is a
hash reference (see C<Fob> above).

=item String

The name of the instance attribute (slot).

=back

For each slot C<x>, with forwarding methods C<y()> and C<z()>, the following
methods are created:

=over 4

=item C<x>

A get/set method, see C<*> below.

=item C<y>

Forwarded onto the object in slot C<x>, which is auto-created via C<new()> if
necessary. The C<new()>, if called, is called without arguments.

=item C<z>

As for C<y>.

=back

So, using the example above, a method, C<foo()>, is created, which can get and
set the value of those objects in slot C<foo>, which will generally contain an
object of class C<Baz>. Two additional methods are created named C<bar()> and
C<baz()> which result in a call to the C<bar()> and C<baz()> methods on the
C<Baz> object stored in slot C<foo>.

Apart from the forwarding methods described above, C<mk_object_accessors()>
creates methods as described below, where C<*> denotes the slot name.

=over 4

=item C<*>

If the accessor is supplied with an object of an appropriate type, will set
set the slot to that value. Else, if the slot has no value, then an object is
created by calling C<new()> on the appropriate class, passing in any supplied
arguments.

The stored object is then returned.

=item C<*_clear>, C<clear_*>

Removes the object from the accessor.

=back

=head2 mk_forward_accessors

    __PACKAGE__->mk_forward_accessors(
        comp1 => 'method1',
        comp2 => [ qw(method2 method3) ],
    );

Takes a hash of mappings as its arguments. Each hash value is expected to be
either a string or an array reference. For each hash value an accessor is
created and forwarded to the accessor denoted by its associated hash key.

In the example above, a call to C<method1()> will be forwarded onto
C<comp1()>, and calls to C<method2()> and C<method3()> will be forwarded onto
C<comp2()>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Class-Accessor-Complex>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Accessor-Complex/>.

The development version lives at
L<http://github.com/hanekomu/Class-Accessor-Complex/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


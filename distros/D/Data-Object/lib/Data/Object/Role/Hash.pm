# ABSTRACT: Hash Object Role for Perl 5
package Data::Object::Role::Hash;

use strict;
use warnings;

use 5.014;

use Data::Object;
use Data::Object::Role;
use Data::Object::Library;
use Data::Object::Signatures;
use Scalar::Util;

map with($_), our @ROLES = qw(
    Data::Object::Role::Collection
    Data::Object::Role::Item
);

our $VERSION = '0.59'; # VERSION

method clear () {

    return $self->empty;

}

method count () {

    return $self->length;

}

method defined ($key) {

    return CORE::defined($self->{$key});

}

method delete ($key) {

    return CORE::delete($self->{$key});

}

method each ($code, @args) {

    for my $key (CORE::keys %$self) {

        my $value = $self->{$key};

        my $refs = {
            '$key'   => \$key,
            '$value' => \$value,
        };

        Data::Object::codify($code, $refs)->($key, $value, @args);

    }

    return $self;

}

method each_key ($code, @args) {

    for my $key (CORE::keys %$self) {

        my $value = $self->{$key};

        my $refs = {
            '$key'   => \$key,
            '$value' => \$value,
        };

        Data::Object::codify($code, $refs)->($key, @args);

    }

    return $self;

}

method each_n_values ($number, $code, @args) {

    my $refs = {};
    my @list = CORE::keys %$self;

    while (my @keys = CORE::splice(@list, 0, $number)) {

        my @values;

        for (my $i = 0; $i < @keys; $i++) {

            my $pos   = $i;
            my $key   = $keys[$pos];
            my $value = CORE::defined($key) ? $self->{$key} : undef;

            $refs->{"\$key${i}"}   = $key   if CORE::defined $key;
            $refs->{"\$value${i}"} = $value if CORE::defined $value;

            push @values, $value;

        }

        Data::Object::codify($code, $refs)->(@values, @args);

    }

    return $self;

}

method each_value ($code, @args) {

    for my $key (CORE::keys %$self) {

        my $value = $self->{$key};

        my $refs = {
            '$key'   => \$key,
            '$value' => \$value,
        };

        Data::Object::codify($code, $refs)->($value, @args);

    }

    return $self;

}

method empty () {

    CORE::delete @$self{CORE::keys %$self};

    return $self;

}

method eq {

    $self->throw("the eq() comparison operation is not supported");

    return;

}

method exists ($key) {

    return CORE::exists $self->{$key};

}

method filter_exclude (@args) {

    my %i = map { $_ => $_ } @args;

    return {

        CORE::map  { CORE::exists($self->{$_}) ? ($_ => $self->{$_}) : () }

        CORE::grep { not CORE::exists($i{$_}) } CORE::keys %$self

    };

}

method filter_include (@args) {

    return {

        CORE::map { CORE::exists($self->{$_}) ? ($_ => $self->{$_}) : () }

        @args

    };

}

method fold ($path, $store, $cache) {

    $store ||= {};
    $cache ||= {};

    my $ref = CORE::ref($self);
    my $obj = Scalar::Util::blessed($self);
    my $adr = Scalar::Util::refaddr($self);
    my $tmp = { %$cache };

    if ($adr && $tmp->{$adr}) {

        $store->{$path} = $self;

    } elsif ($ref eq 'HASH'  || ($obj and $obj->isa('Data::Object::Hash'))) {

        $tmp->{$adr} = 1;

        if (%$self) {

            for my $key (CORE::sort(CORE::keys %$self)) {

                my $place = $path ? CORE::join('.', $path, $key) : $key;
                my $value = $self->{$key};

                fold($value, $place, $store, $tmp);

            }

        } else {

            $store->{$path} = {};

        }

    } elsif ($ref eq 'ARRAY' || ($obj and $obj->isa('Data::Object::Array'))) {

        $tmp->{$adr} = 1;

        if (@$self) {

            for my $idx (0 .. $#$self) {

                my $place = $path ? CORE::join(':', $path, $idx) : $idx;
                my $value = $self->[$idx];

                fold($value, $place, $store, $tmp);

            }

        } else {

            $store->{$path} = [];

        }

    } else {

        $store->{$path} = $self if $path;

    }

    return $store;

}

method ge {

    $self->throw("the ge() comparison operation is not supported");

    return;

}

method get ($key) {

    return $self->{$key};

}

method grep ($code, @args) {

    my @caught;

    for my $key (CORE::keys %$self) {

        my $value = $self->{$key};

        my $refs = {
            '$key'   => \$key,
            '$value' => \$value,
        };

        my $result = Data::Object::codify($code, $refs)->($value, @args);

        push @caught, $key, $value if $result;

    }

    return { @caught };

}

method gt {

    $self->throw("the gt() comparison operation is not supported");

    return;

}

method head {

    $self->throw("the gt() comparison operation is not supported");

    return;

}

method invert () {

    return $self->reverse;

}

method iterator () {

    my @keys = CORE::keys %{$self};

    my $i = 0;

    return sub {

        return undef if $i > $#keys;

        return $self->{$keys[$i++]};

    }

}

method join {

    $self->throw("the join() comparison operation is not supported");

    return;

}

method keys () {

    return [ CORE::keys %$self ];

}

method le {

    $self->throw("the le() comparison operation is not supported");

    return;

}

method length () {

    return scalar CORE::keys %$self;

}

method list () {

    return [ %$self ];

}

method lookup ($path) {

    return undef unless ($self and $path) and (
        ('HASH' eq ref($self)) or Scalar::Util::blessed($self)
            and $self->isa('HASH')
    );

    return $self->{$path} if $self->{$path};

    my $next;
    my $rest;

    ($next, $rest) = $path =~ /(.*)\.([^\.]+)$/;
    return lookup($self->{$next}, $rest) if $next and $self->{$next};

    ($next, $rest) = $path =~ /([^\.]+)\.(.*)$/;
    return lookup($self->{$next}, $rest) if $next and $self->{$next};

    return undef;

}

method lt {

    $self->throw("the lt() comparison operation is not supported");

    return;

}

method map ($code, @args) {

    my @caught;

    for my $key (CORE::keys %$self) {

        my $value = $self->{$key};

        my $refs = {
            '$key'   => \$key,
            '$value' => \$value,
        };

        push @caught, (Data::Object::codify($code, $refs)->($key, @args));

    }

    return [ @caught ];

}

method merge (@args) {

    require Storable;

    return Storable::dclone($self) if ! @args;
    return Storable::dclone(merge($self, merge(@args))) if @args > 1;

    my ($right) = @args;
    my (%merge) = %$self;

    for my $key (CORE::keys %$right) {

        my $lprop = $$self{$key};
        my $rprop = $$right{$key};

        $merge{$key} = ((ref($rprop) eq 'HASH') and (ref($lprop) eq 'HASH'))
            ? merge($$self{$key}, $$right{$key}) : $$right{$key};

    }

    return Storable::dclone(\%merge);

}

method ne {

    $self->throw("the ne() comparison operation is not supported");

    return;

}

method pairs () {

    return [ CORE::map { [ $_, $self->{$_} ] } CORE::keys(%$self) ];

}

method reset () {

    @$self{ CORE::keys( %$self ) } = ();

    return $self;

}

method reverse {

    my $data = {};

    for (CORE::keys %$self) {

        $data->{$_} = $self->{$_} if CORE::defined($self->{$_});

    }

    return { CORE::reverse %$data };

}

method set ($key, $value) {

    return $self->{$key} = $value;

}

method slice (@args) {

    return { CORE::map { $_ => $self->{$_} } @args };

}

method sort {

    $self->throw("the sort() comparison operation is not supported");

    return;

}

method tail {

    $self->throw("the tail() comparison operation is not supported");

    return;

}

method unfold () {

    my $store = {};

    for my $key (CORE::sort(CORE::keys(%$self))) {

        my $node = $store;
        my @steps = CORE::split(/\./, $key);

        for (my $i=0; $i < @steps; $i++) {

            my $last = $i == $#steps;
            my $step = $steps[$i];

            if (my @parts = $step =~ /^(\w*):(0|[1-9]\d*)$/) {
                $node = $node->{$parts[0]}[$parts[1]] = $last
                    ? $self->{$key}
                    : exists $node->{$parts[0]}[$parts[1]]
                    ?        $node->{$parts[0]}[$parts[1]]
                    : {};
            } else {
                $node = $node->{$step} = $last
                    ? $self->{$key}
                    : exists $node->{$step}
                    ?        $node->{$step}
                    : {};
            }

        }

    }

    return $store;

}

method values (@args) {

    return [ @args ? @{$self}{@args} : CORE::values(%$self) ];

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Object::Role::Hash - Hash Object Role for Perl 5

=head1 VERSION

version 0.59

=head1 SYNOPSIS

    use Data::Object::Class;

    with 'Data::Object::Role::Hash';

=head1 DESCRIPTION

Data::Object::Role::Hash provides routines for operating on Perl 5 hash
references.

=head1 CODIFICATION

Certain methods provided by the this module support codification, a process
which converts a string argument into a code reference which can be used to
supply a callback to the method called. A codified string can access its
arguments by using variable names which correspond to letters in the alphabet
which represent the position in the argument list. For example:

    $hash->example('$a + $b * $c', 100);

    # if the example method does not supply any arguments automatically then
    # the variable $a would be assigned the user-supplied value of 100,
    # however, if the example method supplies two arguments automatically then
    # those arugments would be assigned to the variables $a and $b whereas $c
    # would be assigned the user-supplied value of 100

    # e.g.

    $hash->each('the value at $key is $value');

    # or

    $hash->each_n_values(4, 'the value at $key0 is $value0');

    # etc

Any place a codified string is accepted, a coderef or L<Data::Object::Code>
object is also valid. Arguments are passed through the usual C<@_> list.

=head1 METHODS

=head2 clear

    # given {1..8}

    $hash->clear; # {}

The clear method is an alias to the empty method. This method returns a
hash object. This method is an alias to the empty method.

=head2 count

    # given {1..4}

    my $count = $hash->count; # 2

The count method returns the total number of keys defined. This method returns
a number object.

=head2 data

    # given $hash

    $hash->data; # original value

The data method returns the original and underlying value contained by the
object. This method is an alias to the detract method.

=head2 defined

    # given {1..8,9,undef}

    $hash->defined(1); # 1; true
    $hash->defined(0); # 0; false
    $hash->defined(9); # 0; false

The defined method returns true if the value matching the key specified in the
argument if defined, otherwise returns false. This method returns a
number object.

=head2 delete

    # given {1..8}

    $hash->delete(1); # 2

The delete method returns the value matching the key specified in the argument
and returns the value. This method returns a data type object to be determined
after execution.

=head2 detract

    # given $hash

    $hash->detract; # original value

The detract method returns the original and underlying value contained by the
object.

=head2 dump

    # given {1..4}

    $hash->dump; # '{1=>2,3=>4}'

The dump method returns returns a string representation of the object.
This method returns a string value.

=head2 each

    # given {1..8}

    $hash->each(sub{
        my $key   = shift; # 1
        my $value = shift; # 2
    });

The each method iterates over each element in the hash, executing the code
reference supplied in the argument, passing the routine the key and value at the
current position in the loop. This method supports codification, i.e, takes an
argument which can be a codifiable string, a code reference, or a code data type
object. This method returns a hash value.

=head2 each_key

    # given {1..8}

    $hash->each_key(sub{
        my $key = shift; # 1
    });

The each_key method iterates over each element in the hash, executing the code
reference supplied in the argument, passing the routine the key at the current
position in the loop. This method supports codification, i.e, takes an argument
which can be a codifiable string, a code reference, or a code data type object.
This method returns a hash value.

=head2 each_n_values

    # given {1..8}

    $hash->each_n_values(4, sub {
        my $value_1 = shift; # 2
        my $value_2 = shift; # 4
        my $value_3 = shift; # 6
        my $value_4 = shift; # 8
        ...
    });

The each_n_values method iterates over each element in the hash, executing the
code reference supplied in the argument, passing the routine the next n values
until all values have been seen. This method supports codification, i.e, takes
an argument which can be a codifiable string, a code reference, or a code data
type object. This method returns a hash value.

=head2 each_value

    # given {1..8}

    $hash->each_value(sub {
        my $value = shift; # 2
    });

The each_value method iterates over each element in the hash, executing the code
reference supplied in the argument, passing the routine the value at the current
position in the loop. This method supports codification, i.e, takes an argument
which can be a codifiable string, a code reference, or a code data type object.
This method returns a hash value.

=head2 empty

    # given {1..8}

    $hash->empty; # {}

The empty method drops all elements from the hash. This method returns a
hash object. Note: This method modifies the hash.

=head2 eq

    # given $hash

    $hash->eq; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 exists

    # given {1..8,9,undef}

    $hash->exists(1); # 1; true
    $hash->exists(0); # 0; false

The exists method returns true if the value matching the key specified in the
argument exists, otherwise returns false. This method returns a
number object.

=head2 filter_exclude

    # given {1..8}

    $hash->filter_exclude(1,3); # {5=>6,7=>8}

The filter_exclude method returns a hash reference consisting of all key/value
pairs in the hash except for the pairs whose keys are specified in the
arguments. This method returns a hash value.

=head2 filter_include

    # given {1..8}

    $hash->filter_include(1,3); # {1=>2,3=>4}

The filter_include method returns a hash reference consisting of only key/value
pairs whose keys are specified in the arguments. This method returns a
hash object.

=head2 fold

    # given {3,[4,5,6],7,{8,8,9,9}}

    $hash->fold; # {'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9}

The fold method returns a single-level hash reference consisting of key/value
pairs whose keys are paths (using dot-notation where the segments correspond to
nested hash keys and array indices) mapped to the nested values. This method
returns a hash value.

=head2 ge

    # given $hash

    $hash->ge; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 get

    # given {1..8}

    $hash->get(5); # 6

The get method returns the value of the element in the hash whose key
corresponds to the key specified in the argument. This method returns a data
type object to be determined after execution.

=head2 grep

    # given {1..4}

    $hash->grep(sub {
        shift >= 3
    });

    # {3=>5}

The grep method iterates over each key/value pair in the hash, executing the
code reference supplied in the argument, passing the routine the key and value
at the current position in the loop and returning a new hash reference
containing the elements for which the argument evaluated true. This method
supports codification, i.e, takes an argument which can be a codifiable string,
a code reference, or a code data type object. This method returns a
hash object.

=head2 gt

    # given $hash

    $hash->gt; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 head

    # given $hash

    $hash->head; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 invert

    # given {1..8,9,undef,10,''}

    $hash->invert; # {''=>10,2=>1,4=>3,6=>5,8=>7}

The invert method returns the hash after inverting the keys and values
respectively. Note, keys with undefined values will be dropped, also, this
method modifies the hash. This method returns a hash value.
Note: This method modifies the hash.

=head2 iterator

    # given {1..8}

    my $iterator = $hash->iterator;
    while (my $value = $iterator->next) {
        say $value; # 2
    }

The iterator method returns a code reference which can be used to iterate over
the hash. Each time the iterator is executed it will return the values of the
next element in the hash until all elements have been seen, at which point
the iterator will return an undefined value. This method returns a
code object.

=head2 join

    # given $hash

    $hash->join; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 keys

    # given {1..8}

    $hash->keys; # [1,3,5,7]

The keys method returns an array reference consisting of all the keys in the
hash. This method returns an array value.

=head2 le

    # given $hash

    $hash->le; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 length

    # given {1..8}

    my $length = $hash->length; # 4

The length method returns the number of keys in the hash. This method
return a number object.

=head2 list

    # given $hash

    my $list = $hash->list;

The list method returns a shallow copy of the underlying hash reference as an
array reference. This method return an array object.

=head2 lookup

    # given {1..3,{4,{5,6,7,{8,9,10,11}}}}

    $hash->lookup('3.4.7'); # {8=>9,10=>11}
    $hash->lookup('3.4'); # {5=>6,7=>{8=>9,10=>11}}
    $hash->lookup(1); # 2

The lookup method returns the value of the element in the hash whose key
corresponds to the key specified in the argument. The key can be a string which
references (using dot-notation) nested keys within the hash. This method will
return undefined if the value is undef or the location expressed in the argument
can not be resolved. Please note, keys containing dots (periods) are not
handled. This method returns a data type object to be determined after
execution.

=head2 lt

    # given $hash

    $hash->lt; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 map

    # given {1..4}

    $hash->map(sub {
        shift + 1
    });

The map method iterates over each key/value in the hash, executing the code
reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing the
elements for which the argument returns a value or non-empty list. This method
returns a L<Data::Object::Array> object.

=head2 merge

    # given {1..8}

    $hash->merge({7,7,9,9}); # {1=>2,3=>4,5=>6,7=>7,9=>9}

The merge method returns a hash reference where the elements in the hash and
the elements in the argument(s) are merged. This operation performs a deep
merge and clones the datasets to ensure no side-effects. The merge behavior
merges hash references only, all other data types are assigned with precendence
given to the value being merged. This method returns a L<Data::Object::Hash>
object.

=head2 methods

    # given $hash

    $hash->methods;

The methods method returns the list of methods attached to object. This method
returns an array value.

=head2 ne

    # given $hash

    $hash->ne; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 new

    # given 1..4

    my $hash = Data::Object::Hash->new(1..4);
    my $hash = Data::Object::Hash->new({1..4});

The new method expects a list or hash reference and returns a new class
instance.

=head2 pairs

    # given {1..8}

    $hash->pairs; # [[1,2],[3,4],[5,6],[7,8]]

The pairs method is an alias to the pairs_array method. This method returns a
array object. This method is an alias to the pairs_array
method.

=head2 print

    # given {1..4}

    $hash->print; # '{1=>2,3=>4}'

The print method outputs the value represented by the object to STDOUT and
returns true. This method returns a number value.

=head2 reset

    # given {1..8}

    $hash->reset; # {1=>undef,3=>undef,5=>undef,7=>undef}

The reset method returns nullifies the value of each element in the hash. This
method returns a hash value. Note: This method modifies the
hash.

=head2 reverse

    # given {1..8,9,undef}

    $hash->reverse; # {8=>7,6=>5,4=>3,2=>1}

The reverse method returns a hash reference consisting of the hash's keys and
values inverted. Note, keys with undefined values will be dropped. This method
returns a hash value.

=head2 roles

    # given $hash

    $hash->roles;

The roles method returns the list of roles attached to object. This method
returns an array value.

=head2 say

    # given {1..4}

    $hash->say; # '{1=>2,3=>4}\n'

The say method outputs the value represented by the object appended with a
newline to STDOUT and returns true. This method returns a L<Data::Object::Number>
object.

=head2 set

    # given {1..8}

    $hash->set(1,10); # 10
    $hash->set(1,12); # 12
    $hash->set(1,0); # 0

The set method returns the value of the element in the hash corresponding to
the key specified by the argument after updating it to the value of the second
argument. This method returns a data type object to be determined after
execution.

=head2 slice

    # given {1..8}

    my $slice = $hash->slice(1,5); # {1=>2,5=>6}

The slice method returns a hash reference containing the elements in the hash
at the key(s) specified in the arguments. This method returns a
hash object.

=head2 sort

    # given $hash

    $hash->sort; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 tail

    # given $hash

    $hash->tail; # exception thrown

This method is a consumer requirement but has no function and is not implemented.
This method will throw an exception if called.

=head2 throw

    # given $hash

    $hash->throw;

The throw method terminates the program using the core die keyword, passing the
object to the L<Data::Object::Exception> class as the named parameter C<object>.
If captured this method returns an exception value.

=head2 type

    # given $hash

    $hash->type; # HASH

The type method returns a string representing the internal data type object name.
This method returns a string value.

=head2 unfold

    # given {'3:0'=>4,'3:1'=>5,'3:2'=>6,'7.8'=>8,'7.9'=>9}

    $hash->unfold; # {3=>[4,5,6],7,{8,8,9,9}}

The unfold method processes previously folded hash references and returns an
unfolded hash reference where the keys, which are paths (using dot-notation
where the segments correspond to nested hash keys and array indices), are used
to created nested hash and/or array references. This method returns a
hash object.

=head2 values

    # given {1..8}

    $hash->values; # [2,4,6,8]
    $hash->values(1,3); # [2,4]

The values method returns an array reference consisting of the values of the
elements in the hash. This method returns an array value.

=head1 ROLES

This package is comprised of the following roles.

=over 4

=item *

L<Data::Object::Role::Collection>

=item *

L<Data::Object::Role::Comparison>

=item *

L<Data::Object::Role::Defined>

=item *

L<Data::Object::Role::Detract>

=item *

L<Data::Object::Role::Dumper>

=item *

L<Data::Object::Role::Item>

=item *

L<Data::Object::Role::List>

=item *

L<Data::Object::Role::Output>

=item *

L<Data::Object::Role::Throwable>

=item *

L<Data::Object::Role::Type>

=back

=head1 SEE ALSO

=over 4

=item *

L<Data::Object::Array>

=item *

L<Data::Object::Class>

=item *

L<Data::Object::Class::Syntax>

=item *

L<Data::Object::Code>

=item *

L<Data::Object::Float>

=item *

L<Data::Object::Hash>

=item *

L<Data::Object::Integer>

=item *

L<Data::Object::Number>

=item *

L<Data::Object::Role>

=item *

L<Data::Object::Role::Syntax>

=item *

L<Data::Object::Regexp>

=item *

L<Data::Object::Scalar>

=item *

L<Data::Object::String>

=item *

L<Data::Object::Undef>

=item *

L<Data::Object::Universal>

=item *

L<Data::Object::Autobox>

=item *

L<Data::Object::Immutable>

=item *

L<Data::Object::Library>

=item *

L<Data::Object::Prototype>

=item *

L<Data::Object::Signatures>

=back

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

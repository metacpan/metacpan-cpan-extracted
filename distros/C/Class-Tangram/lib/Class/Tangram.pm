package Class::Tangram;

# Copyright (c) 2001 - 2005, Sam Vilain.  All right reserved.  This
# file is licensed under the terms of the Perl Artistic license.

=head1 NAME

Class::Tangram - Tangram-friendly classes, DWIM attributes

=head1 SYNOPSIS

 package MyObject;

 use base qw(Class::Tangram);

 our $fields = { int    => [ qw(foo bar) ],
                 string => [ qw(baz quux) ] };

 package main;

 my $object = MyObject->new(foo => 2, baz => "hello");

 print $object->baz();            # prints "hello"

 $object->set_quux("Something");

 $object->set_foo("Something");   # dies - not an integer

=head1 DESCRIPTION

Class::Tangram is a tool for defining objects attributes.  Simply
define your object's fields/attributes using the same data structure
introduced in _A Guided Tour of Tangram_ (see L<SEE ALSO>) and
detailed in L<Tangram::Schema>, and you get objects that work As You'd
Expect(tm).

Class::Tangram has no dependancy upon Tangram, and vice versa.
Neither requires anything special of your objects, nor do they insert
any special fields into your objects.  This is a very important
feature with innumerable benefits, and few (if any) other object
persistence tools have this feature.

So, fluff aside, let's run through how you use Class::Tangram to make
objects.

First, you decide upon the attributes your object is going to have.
You might do this using UML, or you might pick an existing database
table and declare each column to be an attribute (you can leave out
"id"; that one is implicit; also, leave out foreign keys until later).

Your object should use Class::Tangram as a base class;

  use base qw(Class::Tangram)

or for older versions of perl:

  use Class::Tangram;
  use vars qw(@ISA);
  @ISA = qw(Class::Tangram)

You should then define a C<$fields> variable in the scope of the
package, that is a B<hash> from attribute B<types> (see
L<Tangram::Type>) to either an B<array> of B<attribute names>, or
another B<hash> from B<attribute names> to B<options hashes> (or
C<undef>).  The layout of this structure coincides exactly with the
C<fields> portion of a tangram schema (see L<Tangram::Schema>), though
there are some extra options available.

This will hereon in be referred to as the `object schema' or just
`schema'.

For example,

 package Orange;
 use base qw(Class::Tangram);

 our $fields = {
     int => {
         juiciness => undef,
         segments => {
             # this code reference is called when this
             # attribute is set, to check the value is
             # OK - note, no object is passed, this is for
             # simple marshalling only.
             check_func => sub {
                 die "too many segments"
                     if (${(shift)} > 30);
             },
             # the default for this attribute.
             init_default => 7,
         },
     },
     ref => {
        grower => {
        },
     },

     # 'required' attributes - insist that these fields are
     # set, both with constructor and set()/set_X methods
     string => {
         # true: 'type' must have non-empty value (for
         # strings) or be logically true (for other types)
	 type => { required => 1 },

	 # false: 'tag' must be defined but may be empty
	 tag => { required => '' },
     },

     # fields allowed by Class::Tangram but not ever
     # stored by Tangram - no type checking by default
     transient => [ qw(_tangible) ],
 };

It is of critical importance to your sanity that you understand how
anonymous hashes and anonymous arrays work in Perl.  Some additional
features are used above that have not yet been introduced, but you
should be able to look at the above data structure and see that it
satisfies the conditions stated in the paragraph before it.  If it is
hazy, I recommend reading L<perlref> or L<perlreftut>.

When the schema for the object is first imported (see L<Schema
import>), Class::Tangram defines accessor functions for each of the
attributes defined in the schema.  These accessor functions are then
available as C<$object-E<gt>function> on created objects.  By virtue
of inheritance, various other methods are available.

From Class::Tangram 1.12 onwards, perl's C<AUTOLOAD> feature is not
used to implement accessors; closures are compiled when the class is
first used.

=cut

use strict 'vars', 'subs';
use Carp;

use vars qw($VERSION %defaults @ISA);

$VERSION = "1.57";

use Set::Object qw(blessed reftype refaddr ish_int is_int is_double is_key);

#---------------------------------------------------------------------
#  run-time globals

# $types{$class}->{$attribute} is the run-time discovered tangram type
# of each attribute
our (%types);

# $attribute_options{$class}->{$attribute} is the hash passed to tangram
# for the given attribute (ie T2::Class.attribute(foo).options)
our (%attribute_options);

# $check{$class}->{$attribute}->($value) is a function that will die
# if $value is not alright, see check_X functions
our (%check);

# Destructors for each attribute.  They are called as
# $cleaners{$class}->{$attribute}->($self, $attribute);
our (%cleaners);

# init_default values for each attribute.  These could be hash refs,
# array refs, code refs, or simple scalars.  They will be stored as
# $init_defaults{$class}->{$attribute}
our (%init_defaults);

# $required_attributes{$class}->{$attribute} records which attributes
# are required... used only by new() at present.
our (%required_attributes);

# companion association registry.
#
# $companions{$class}->{$attribute} = $rem_attribute
#
# The inserted/deleted object has;
#   $object->"${rem_attribute}_insert"($self)
#   $object->"${rem_attribute}_remove"($self)
# The sub is called as $coderef->($attribute, "insert", @objs);
#                   or $coderef->($attribute, "remove", @objs);
our (%companions);

# if a class is abstract, complain if one is constructed.
our (%abstract);

# Set when it is detected that Tangram is not installed
my $no_tangram;

=head1 METHODS

The following methods are available for all Class::Tangram objects

=head2 Constructor

A Constructor is a method that returns a new instance of an object.

=over 4

=item Class-E<gt>new (attribute1 =E<gt> value, attribute2 =E<gt> value)

Sets up a new object of type C<Class>, with attributes set to the
values supplied.

Can also be used as an object method (normal use is as a "class
method"), in which case it returns a B<copy> of the object, without
any deep copying.

=cut

sub new
{
    my $invocant = shift;
    my $class = ref $invocant || $invocant;

    # Setup the object
    my $self = { };
    bless $self, $class;

    # auto-load schema as necessary
    exists $types{$class} or import_schema($class);

    croak "Attempt to instantiate an abstract type $class"
	if ($abstract{$class});

    if (ref $invocant)
    {
	# The copy constructor; this could be better :)
	# this has the side effect of much auto-vivification.
	$self->set( $invocant->_copy(@_) ); # override with @values
    }
    else
    {
	$self->set (@_); # start with @values
    }

    $self->_fill_init_default();
    $self->_check_required();

    return $self;

}

sub _fill_init_default {
    my $self = shift;
    my $class = ref $self or confess "_fill_init_default usage error";

    # fill in fields that have defaults
    while ( my ($attribute, $default) =
	    each %{$init_defaults{$class}} ) {

	next if (exists $self->{$attribute});

	my $setter = "set_$attribute";
	if (ref $default eq "CODE") {
	    # sub { }, attribute gets return value
	    $self->$setter( $default->($self) );

	} elsif (ref $default eq "HASH") {
	    # hash ref, copy hash
	    $self->$setter( { %{ $default } } );

	} elsif (ref $default eq "ARRAY") {
	    # array ref, copy array
	    $self->$setter( [ @{ $default } ] );

	} else {
	    # something else, an object or a scalar
	    $self->$setter($default);
	}
    }
}

sub _check_required {
    my $self = shift;
    my $class = ref $self;

    # make sure field is not undef if 'required' option is set
    if (my $required = $required_attributes{$class}) {

	# find the immediate caller outside of this package
	my $i = 0;
	$i++ while UNIVERSAL::isa($self, scalar(caller($i))||";->");

	# give Tangram some lenience - it is exempt from the effects
	# of the "required" option
	unless ( caller($i) =~ m/^Tangram::/ ) {
	    my @missing;
	    while ( my ($attribute, $value) = each %$required ) {
		push(@missing, $attribute)
		    if ! exists $self->{$attribute};
	    }
	    croak("object missing required attribute(s): "
		  .join(', ',@missing).'.') if @missing;
	}
    }
}

# $obj->_copy($target): copy self into the first arg
sub _copy {
    my $self = shift;
    my $class = ref $self;
    my $types = $types{$class} || do { import_schema($class);
				       $types{$class}; };
    my %passed = (@_);

    # This will pretty much autovivify everything nearby.
    # c'est la vie
    my @rv;
    for my $field ( sort keys %$types ) {
	next if exists $passed{$field};
	my $func = "get_$field";
	push @rv, ($field => scalar($self->$func()));
    }
    return @rv, %passed;
}


=back

=head2 Accessing & Setting Attributes

=over

=item $instance->set(attribute => $value, ...)

Sets the attributes of the given instance to the given values.  croaks
if there is a problem with the values.

This function simply calls C<$instance-E<gt>set_attribute($value)> for
each of the C<attribute =E<gt> $value> pairs passed to it.

=cut

sub set {
    my $self = shift;

    # yes, this is a lot to do.  yes, it's slow.  But I'm fairly
    # certain that this could be handled efficiently if it were to be
    # moved inside the Perl interpreter or an XS module
    UNIVERSAL::isa($self, "Class::Tangram") or croak "type mismatch";
    my $class = ref $self;
    exists $check{$class} or import_schema($class);
    croak "set must be called with an even number of arguments"
	if (scalar(@_) & 1);

    while (my ($name, $value) = splice @_, 0, 2) {

	my $setter = "set_".$name;

	croak "attempt to set an illegal field $name in a $class"
	    unless $self->can($setter) or $self->can("AUTOLOAD");

	$self->$setter($value);
    }
}

=item $instance->get("attribute")

Gets the value of C<$attribute>.  This simply calls
C<$instance-E<gt>get_attribute>.  If multiple attributes are listed,
then a list of the attribute values is returned in order.  Note that
you get back the results of the scalar context C<get_attribute> call
in this case.

=cut

sub get {
    my $self = shift;
    croak "get what?" unless @_;
    UNIVERSAL::isa($self, "Class::Tangram") or croak "type mismatch";

    my $class = ref $self;
    exists $check{$class} or import_schema($class);

    my $multiget = (scalar(@_) != 1);

    my @return;
    while ( my $field = shift ) {
	my $getter = "get_".$field;
	croak "attempt to read an illegal field $field in a $class"
	    unless $self->can($getter) or $self->can("AUTOLOAD");

	if ( $multiget ) {
	    push @return, scalar($self->$getter());
	} else {
	    return $self->$getter();
	}
    }

    return @return;
}

=item $instance->attribute($value)

For DWIM's sake, the behaviour of this function depends on the type of
the attribute.

=over

=for the keen eye

This function, along with the get_attribute and set_attribute
functions, are actually written inside a loop of the import_schema()
function.  The rationale for this is that a single closure is faster
than two functions.

=item scalar attributes

If C<$value> is not given, then
this is equivalent to C<$instance-E<gt>get_attribute>

If C<$value> is given, then this is equivalent to
C<$instance-E<gt>set_attribute($value)>.  This usage issues a warning
if warnings are on; you should change your code to use the
set_attribute syntax for better readability.  OO veterans will tell
you that for maintainability object method names should always be a
verb.

=item associations

With attributes that are associations, the default action when a
parameter is given depends on what the argument list looks like.  If
it appears to be a series of C<(key =E<gt> value)> pairs (with or
without the keys), then it is translated into call to C<set>.
Containers (or C<undef>) are also allowed in place of values.

If the argument list contains only keys (ie, scalars) then it is
assumed you mean to `get' attributes.

If you pass this method an ambiguous argument list (eg, Key Key Value
or Value Key) then you get an exception.

=back

=item $instance->get_attribute([@keys])

=over

=item scalar attributes

Returns the value of the attribute.  This may be a normal scalar, for
C<int>, C<string>, and the C<datetime> related types, or an ARRAY or
HASH REF, in the case of C<flat_array> or C<flat_hash> types.

=item associations

The association types - C<ref>, C<set>, C<array> and C<hash> return
different results depending upon the context and presence of keys in
the method's parameter list.

In list context with no parameters, always returns the entire contents
of the container, as a list, without keys.  No sorting is applied,
unless there is an implicit order due to the type of container the
association uses (ie, arrays).

In scalar context with no parameters, always returns the container - a
Set::Object, Array or Hash (or, for single element containers, the
single element or C<undef> if it is empty).

In list context with parameters, the parameters are assumed to be a
list of keys to look up.  The container does its best to look up items
corresponding to the keys given, and then returns them in the same
order as the keys.

In scalar context with one parameter, the function returns that
element best described by that key, or C<undef> if it is not present
in the container.

=back

=cut

sub looks_like_KVKV {
    my $input = join("", map { is_key($_) ? "K" : "V" } @_);
    return ($input =~ m/^(K?V)+$/g);
}

sub looks_like_KK {
    my $input = join("", map { is_key($_) ? "K" : "V" } @_);
    return ($input =~ m/^K+$/g);
}

=over 4

=item `ref' attributes get

`ref' attributes are modelled as a container with a single element.

The accessor always returns the single element.

=cut

sub _get_X_ref {
    my $self = shift;
    my $X = shift;
    my $rv = $self->{$X};
    # work around perl 5.8.0 tie() bug
    my $t = tied $self->{$X};
    untie($self->{$X}) if ($t and $t =~ m/^Tangram/);
    return $self->{$X};
}

=item `array' attributes get

=cut

sub _get_X_array {
    my $self = shift;
    my $X = shift;
    my $a = ($self->{$X} ||= [ ]);
    # work around perl 5.8.0 tie() bug
    my $t = tied $self->{$X};
    untie($self->{$X}) if ($t and $t =~ m/^Tangram/);

    if (@_) {
	my @rv;
	while (@_) {
	    my $key = shift;
	    if (defined $key) {
		if (defined(my $n = ish_int($key))) {
		    push @rv, $a->[$n];
		} else {
		    carp("Keyed lookup to array container "
			 .ref($self)."->$X($key), returning last "
			 ."member of array")
			if $^W;
		    push @rv, $a->[$#{$a}];
		}
	    }
	}
	if (wantarray or @rv > 1) {
	    return @rv;
	} else {
	    return $rv[0];
	}
    } else {
	if (wantarray) {
	    return @{$a};
	} else {
	    return $a;
	}
    }
}

=item `set' attributes get

=cut

sub _get_X_set {
    my $self = shift;
    my $X = shift;
    my $a = ($self->{$X} ||= Set::Object->new());
    # work around perl 5.8.0 tie() bug
    my $t = tied $self->{$X};
    untie($self->{$X}) if ($t and $t =~ m/^Tangram/);

    if (@_) {
	# uh-oh, asking a set for keyed values. hmm.
	my @members = $a->members();  # maybe should shuffle
	my @rv;
	while (@_) {
	    my $key = shift;
	    if (defined $key and @members) {
		push @rv, (shift @members);
	    }
	}
	if (wantarray or @rv > 1) {
	    return @rv;
	} else {
	    return $rv[0];
	}
    } else {
	if (wantarray) {
	    return $a->members();
	} else {
	    return $a;
	}
    }
}

=item `hash' attributes get

=cut

sub _get_X_hash {
    my $self = shift;
    my $X = shift;
    my $a = ($self->{$X} ||= {});
    # work around perl 5.8.0 tie() bug
    my $t = tied $self->{$X};
    untie($self->{$X}) if ($t and $t =~ m/^Tangram/);

    if (@_) {
	my @rv;
	while (@_) {
	    my $key = shift;
	    if (defined $key) {
		push @rv, $a->{$key};
	    }
	}
	if (wantarray or @rv > 1) {
	    return @rv;
	} else {
	    return $rv[0];
	}
    } else {
	if (wantarray) {
	    return values %$a;
	} else {
	    return $a;
	}
    }

}

=back

=item $instance->set_attribute($value)

The normative way of setting attributes.  If you wish to override the
behaviour of an object when getting or setting an attribute, override
these functions.  They will be called when you use
C<$instance-E<gt>attribute>, C<$instance-E<gt>get()>, constructors,
etc.

When attributes that are associations are changed via other functions,
a new container with the new contents is built, and then passed to
this function.

=over

=item `ref' attributes set

Like all other container set methods, this method may be passed a Set,
Array or Hash, and all the members are added in order to (single
element) container.  If the resultant container has more than one
item, it raises a run-time warning.

=cut

sub _set_X_ref {
    my $self = shift;
    my $base_type = shift;
    my $companion = shift;
    my $X = shift;
    my $class = ref $self;

    my @ncc;
    while (@_) {
	my $value = shift;
	if (blessed($value)) {
	    if ($value->isa("Set::Object")) {
		push @ncc, $value->members();
	    } else {
		push @ncc, $value;
	    }
	} else {
	    my $ref = ref $value;
	    if ($ref eq "ARRAY") {
		@ncc = @$value;
	    } elsif ($ref eq "HASH") {
		@ncc = values %$value;
	    } elsif (defined $value) {
		push @ncc, $value;
            }
	}
    }

    if (@ncc) {
        if (my $checkit = \$check{$class}->{$X}) {
            # There's a check function! Use it!
            $ {$checkit}->(\$ncc[0]);
        } else {
            if (@ncc > 1) {
                carp ("container ".ref($self)."->$X overflowed! "
                      ."Rejecting members at end!")
                  if $^W;
                @ncc = $ncc[0];
            }
            croak("Tried to place `$ncc[0]' in a ref container")
              unless (ref $ncc[0]);
        }
    }

    my $old = $self->{$X};
    my $chosen = $self->{$X} = $ncc[0];

    if ($companion and refaddr($self->{$X}) != refaddr($old)) {
	my $remove = $companion."_remove";
	my $insert = $companion."_insert";
	my $includes = $companion."_includes";

        $old->$remove($self)
	    if ($old and $old->can($remove)
		and $old->can($includes)
		and $old->$includes($self));

	$chosen->$insert($self)
	    if ($chosen and $chosen->can($insert)
		and $chosen->can($includes)
		and !$chosen->$includes($self));
    }

}

=item `set' attributes set

=cut

sub _set_X_set {
    my $self = shift;
    my $base_type = shift;
    my $companion = shift;
    my $X = shift;
    my $class = ref $self;

    # Shortcut to avoid penalty when simply setting to a new container
    if (@_ == 1 and !$companion and
	UNIVERSAL::isa($_[0], "Set::Object")) {
        if (my $checkit = \$check{$class}->{$X}) {
            # There's a check function! Use it!
            $ {$checkit}->(\($_[0]));
        }
	delete $self->{$X};   # make sure it's not tied - 5.8.0 bug
	return $self->{$X} = $_[0];
    }

    my @ncc;
    while (@_) {
	my $value = (shift @_);
	if (blessed($value)) {
	    if ($value->isa("Set::Object")) {
		push @ncc, $value->members();
	    } else {
		push @ncc, $value;
	    }
	} else {
	    my $ref = ref $value;
	    if ($ref eq "ARRAY") {
		push @ncc, @$value;
	    } elsif ($ref eq "HASH") {
		push @ncc, values %$value;
	    } elsif (defined(ish_int($value))) {
		$ncc[$value] = (shift @_);
	    } else {
		# some other type of key, ignore it
	    }
	}
    }

    my ($old, $new);

    if ($companion) {
	# ordering is ignored for arrays when it comes to
	# companions
	$old = Set::Object->new( $self->{$X} ? $self->{$X}->members
				 : () );
    }
    $new = Set::Object->new(@ncc);

    if (my $checkit = \$check{$class}->{$X}) {
	# There's a check function! Use it!
	$ {$checkit}->(\$new);
    }
    $self->{$X} = $new;

    if ($companion) {

	# I love Set::Object, it should be a builtin data type :-)
	my $gone = $old - $new;
	my $added = $new - $old;

	my $includes_func = $companion."_includes";

	if ($gone->size) {
	    my $remove_func = $companion."_remove";
	    for my $gonner ($gone->members) {
		if ($gonner->can($remove_func) &&
		    $gonner->can($includes_func) &&
		    $gonner->$includes_func($self)) {
		    $gonner->$remove_func($self);
		}
	    }
	}

	if ($added->size) {
	    my $insert_func = $companion."_insert";
	    for my $new_mate ($added->members) {
		if ($new_mate->can($insert_func) &&
		    $new_mate->can($includes_func) &&
		    !$new_mate->$includes_func($self) ) {
		    $new_mate->$insert_func($self);
		}
	    }
	}
    }
}

=item `array' attributes set

=cut

sub _set_X_array {
    my $self = shift;
    my $base_type = shift;
    my $companion = shift;
    my $X = shift;
    my $class = ref $self;

    # Shortcut to avoid penalty when simply setting to a new container
    if (@_ == 1 and !$companion and ref $_[0] eq "ARRAY") {
	delete $self->{$X};   # make sure it's not tied - 5.8.0 bug
	if (my $checkit = \$check{$class}->{$X}) {
	    # There's a check function! Use it!
	    $ {$checkit}->(\($_[0]));
	}
	return $self->{$X} = $_[0];
    }

    my @ncc;
    while (@_) {
	my ($value) = (shift @_);
	if (blessed($value)) {
	    if ($value->isa("Set::Object")) {
		push @ncc, $value->members();
	    } else {
		push @ncc, $value;
	    }
	} else {
	    my $ref = ref $value;
	    if ($ref eq "ARRAY") {
		push @ncc, @$value;
	    } elsif ($ref eq "HASH") {
		push @ncc, values %$value;
	    } elsif (defined(ish_int($value))) {
		$ncc[$value] = (shift @_);
	    } else {
		# some other type of key, ignore it
	    }
	}
    }

    my ($set, $ncc);

    if ($companion) {
	# ordering is ignored for arrays when it comes to
	# companions
	$set = Set::Object->new( blessed($self->{$X})
				 ? (grep { ref $_ } $self->{$X}->members)
				 : () );
	$ncc = Set::Object->new(grep { ref $_ } @ncc);
    }

    if (my $checkit = $check{$class}->{$X}) {
	# There's a check function! Use it!
	$checkit->(\\@ncc);
    } else {
	confess "no checkit for $self - $class, X is $X, checkit is $$checkit\n";
    }

    $self->{$X} = \@ncc;

    if ($companion) {

	# I love Set::Object, it should be a builtin data type :-)
	my $gone = $set - $ncc;
	my $new = $ncc - $set;

	my $includes_func = $companion."_includes";

	if ($gone->size) {
	    my $remove_func = $companion."_remove";
	    for my $gonner ($gone->members) {
		if ($gonner->can($remove_func) &&
		    $gonner->can($includes_func) &&
		    $gonner->$includes_func($self)) {
		    $gonner->$remove_func($self);
		}
	    }
	}

	if ($new->size) {
	    my $insert_func = $companion."_insert";
	    for my $new_mate ($new->members) {
		if ($new_mate->can($insert_func) &&
		    $new_mate->can($includes_func) &&
		    !$new_mate->$includes_func($self) ) {
		    $new_mate->$insert_func($self);
		}
	    }
	}
    }
}

=item `hash' attributes set

=cut

sub _set_X_hash {
    my $self = shift;
    my $base_type = shift;
    my $companion = shift;
    my $X = shift;
    my $class = ref $self;

    # Shortcut to avoid penalty when simply setting to a new container
    if (@_ == 1 and !$companion and ref $_[0] eq "HASH") {
	delete $self->{$X};   # make sure it's not tied - 5.8.0 bug
	if (my $checkit = \$check{$class}->{$X}) {
	    # There's a check function! Use it!
	    $ {$checkit}->(\($_[0]));
	}
	return $self->{$X} = $_[0];
    }

    my %ncc;
    my $n = 0;
    my $ins = sub {
	my $item = shift;
	if (blessed $item and
	    $item->can(my $meth = "${X}_hek")) {
	    $ncc{$item->$meth} = $item;
	} else {
	    $ncc{"".$n++} = $item;
	}
    };

    while (@_) {
	my ($value) = (shift @_);
	if (blessed($value)) {
	    if ($value->isa("Set::Object")) {
		$ins->($_) foreach $value->members();
	    } else {
		$ins->($value);
	    }
	} else {
	    my $ref = ref $value;
	    if ($ref) {
		if ($ref eq "ARRAY") {
		    $ins->($_) foreach @$value;
		} elsif ($ref eq "HASH") {
		    while (my ($k, $v) = each %$value) {
			$ncc{$k} = $v;
		    }
		}
	    } elsif (defined(ish_int($value))) {
		# hmmf.  A number?  Well, just put it on the end.
		# exact convention to be determined later
		$ins->(shift @_);
	    } else {
		# a plain hash key
		$ncc{$value} = (shift @_);
	    }
	}
    }

    my $old = $self->{$X} || {};
    if (my $checkit = \$check{$class}->{$X}) {
	# There's a check function! Use it!
	$ {$checkit}->(\\%ncc);
    }
    $self->{$X} = \%ncc;

    if ($companion) {
	# ordering is ignored for arrays when it comes to
	# companions
	my $set = Set::Object->new(values %$old);
	my $ncc = Set::Object->new(values %ncc);

	# I love Set::Object, it should be a builtin data type :-)
	my $gone = $set - $ncc;
	my $new = $ncc - $set;

	my $includes_func = $companion."_includes";

	if ($gone->size) {
	    my $remove_func = $companion."_remove";
	    for my $gonner ($gone->members) {
		if ($gonner->can($remove_func) &&
		    $gonner->can($includes_func) &&
		    $gonner->$includes_func($self)) {
		    $gonner->$remove_func($self);
		}
	    }
	}

	if ($new->size) {
	    my $insert_func = $companion."_insert";
	    for my $new_mate ($new->members) {
		if ($new_mate->can($insert_func) &&
		    $new_mate->can($includes_func) &&
		    !$new_mate->$includes_func($self) ) {
		    $new_mate->$insert_func($self);
		}
	    }
	}
    }
}

=back

=item $instance->attribute_includes(@objects)

Returns true if all of the objects, or object => value pairs, are
present in the container.

=cut

sub _includes_X_set {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    my $a = $self->$getter || Set::Object->new();

    my $all_there = 1;
    my $item;
    while (@_) {
	if (blessed($item = shift) or reftype($item)) {
	    $all_there = 0 unless $a->includes($item);
	} elsif (defined(my $x = ish_int($item))) {
	    $all_there = 0 if $x > $a->size;
	} else {
	    carp("Searched for non-reference `$item' in set");
	}
	last unless $all_there;
    }
    return $all_there;
}

sub _includes_X_ref {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";

    my $all_there = 1;
    while (@_) {
	if (blessed(my $item = shift)) {
	    $all_there = 0
		unless (refaddr($self->$getter) == refaddr($item));
	} elsif (defined(my $x = ish_int($item))) {
	    $all_there = 0 if $x;
	}
	last unless $all_there;
    }
    return $all_there;
}

sub _includes_X_array {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    my $a = $self->$getter || [];

    my $all_there = 1;
    my $members;
    while (@_) {
	if (blessed(my $item = shift)) {
	    # includes without a key, d'oh!  convert to set
	    $members ||= Set::Object->new(@$a);
	    $all_there = 0 unless $members->includes($item);
	} elsif (defined(my $x = ish_int($item))) {
	    $all_there = 0, last unless ($x >= 0 && $x < @$a);
	    if (blessed($_[0])) {
		$item = shift;
		$all_there = 0 unless (refaddr($a->[$x]) == refaddr($item));
	    }
	}
	last unless $all_there;
    }
    return $all_there;
}

sub _includes_X_hash {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    my $a = $self->$getter || {};

    my $all_there = 1;
    my $members;
    while (@_) {
	if (blessed(my $item = shift)) {
	    # includes without a key, d'oh!  convert to set
	    $members ||= Set::Object->new(values %$a);
	    $all_there = 0 unless $members->includes($item);
	} elsif (defined(my $x = ish_int($item))) {
	    # lookup by index, ignore key for now
	    next
	} elsif (!ref($item)) {
	    # lookup by hash key
	    $all_there = 0, last unless exists $a->{$item};
	    if (blessed($_[0])) {
		my $key;
		($key, $item) = ($item, shift);
		$all_there = 0 unless refaddr($a->{$key}) == refaddr($item);
	    }
	}
	last unless $all_there;
    }
    return $all_there;
}


=item $instance->attribute_insert([key] => $object, [...])

Inserts all of the items into the collection.

Where possible, if the collection type can avoid a collision (perhaps
by duplicating an entry for a key or inserting a slot into an ordered
list), then such action is taken.

If you're inserting a list of objects into an array by number, ensure
that you list the keys in order, unless you know what you're doing.

eg

 $obj->myarray_insert( 1 => $obj1, 2 => $obj2, 1 => $obj3 )

will yield

 $obj->myarray()  ==  ( $obj3, $obj1, $obj2 );

Empty slots are shifted along with the rest of them.

=cut

sub _insert_X_ref {
    my $self = shift;
    my $X = shift;
    my $setter = "set_$X";
    my $getter = "get_$X";
    return $self->$setter($_[0] || scalar($self->$getter));
}
sub _insert_X_set {
    my $self = shift;
    my $X = shift;
    my $setter = "set_$X";
    my $getter = "get_$X";
    my @new = (scalar($self->$getter), @_);
    return $self->$setter(@new);
}
sub _insert_X_array {
    my $self = shift;
    my $X = shift;
    my $setter = "set_$X";
    my $getter = "get_$X";

    my @ncc = $self->$getter();
    while (@_) {
	my ($value) = (shift @_);
	if (blessed($value)) {
	    if ($value->isa("Set::Object")) {
		push @ncc, $value->members();
	    } else {
		push @ncc, $value;
	    }
	} else {
	    my $ref = ref $value;
	    if ($ref eq "ARRAY") {
		push @ncc, @$value;
	    } elsif ($ref eq "HASH") {
		push @ncc, values %$value;
	    } elsif (defined(ish_int($value))) {
		# FIXME - what about $object->insert(7 => \@obj) ?
		@ncc = (@ncc[0..$value-1], (shift @_),
			@ncc[$value..$#ncc]);
	    } else {
		# some other type of key, ignore it
	    }
	}
    }
    return $self->$setter(@ncc);
}
sub _insert_X_hash {
    my $self = shift;
    my $X = shift;
    my $setter = "set_$X";
    my $getter = "${X}_pairs";
    return $self->$setter($self->$getter, @_);
}


=item $instance->attribute_replace([key] => $object, [...])

"Replace" is, for the most part, identical to "insert".  However, if
collisions occur (whatever that means for the collection type you are
inserting to), then the target will be replaced, no duplications of
elements will occur in collection types supporting duplicates.

=cut

sub _replace_X_ref {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    my $setter = "set_$X";
    return $self->$setter((@_, scalar($self->$getter))[0]);
}
sub _replace_X_set {
    my $self = shift;
    my $X = shift;
    my $setter = "set_$X";
    my $getter = "get_$X";
    return $self->$setter(scalar($self->$getter), @_);
}
sub _replace_X_array {
    my $self = shift;
    my $X = shift;
    my $setter = "set_$X";
    my $getter = "get_$X";
    return $self->$setter(scalar($self->$getter), @_);
}
sub _replace_X_hash {
    my $self = shift;
    my $X = shift;
    my $setter = "set_$X";
    my $getter = "${X}_pairs";
    return $self->$setter(scalar($self->$getter), @_);
}


=item $instance->attribute_pairs

=cut

sub _pairs_X_ref {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    return map { ("" => $_) } $self->$getter(@_);
}
sub _pairs_X_set {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    return map { ("" => $_) } $self->$getter(@_);
}
sub _pairs_X_array {
    my $self = shift;
    my $X = shift;
    my $setter = "set_$X";
    my $getter = "get_$X";
    my $n = 0;
    return map { ($n++ => $_) } $self->$getter(@_);
}
sub _pairs_X_hash {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    return %{$self->$getter}
}

=item $instance->attribute_size

FETCHSIZE

=cut

sub _size_X_ref {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    return ($self->$getter ? 1 : 0);
}
sub _size_X_set {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    return $self->$getter->size();
}
sub _size_X_array {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    return scalar(@{$self->$getter});
}
sub _size_X_hash {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    return scalar(keys %{$self->$getter});
}


=item $instance->attribute_clear

Empties a collection

=cut

sub _clear_X_ref {
    my $self = shift;
    my $X = shift;
    my $setter = "set_$X";
    return ($self->$setter());
}
sub _clear_X_set { _clear_X_ref(@_) }
sub _clear_X_array { _clear_X_ref(@_) }
sub _clear_X_hash { _clear_X_ref(@_) }

=item $instance->attribute_push

Place an element on the end of a collection; identical to foo_insert
without an index.

=cut

sub _push_X_ref   { _insert_X_ref(@_) }
sub _push_X_set   { _insert_X_set(@_) }
sub _push_X_array { _insert_X_array(@_) }
sub _push_X_hash  { _insert_X_hash(@_) }

=item $instance->attribute_unshift

Place an element on the end of a collection; identical to foo_insert
without an index.

=cut

sub _unshift_X_ref   { _insert_X_ref(@_) }
sub _unshift_X_set   { _insert_X_set(@_) }
sub _unshift_X_array {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    my @ncc = $self->$getter();
    my $setter = "set_$X";
    return $self->$setter(@_, @ncc);
}
sub _unshift_X_hash  { _insert_X_hash(@_) }

=item $instance->attribute_pop

Returns the last element in a collection, and deletes that item from
the collection, but not necessarily in that order.  No parameters are
accepted.

=cut

sub _pop_X_ref   {
    my $self = shift;
    my $X = shift;
    my $setter = "set_$X";
    my $getter = "get_$X";
    if (wantarray) {
	my @rv = ($self->$getter());
	$self->$setter();
	return @rv;
    } else {
	my $rv = $self->$getter();
	$self->$setter();
	return $rv;
    }
}

sub _pop_X_set   {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    # sets don't have an order, so just delete any member
    if (my $val = $self->$getter(0)) {
	my $toaster = "${X}_remove";
	$self->$toaster($val);
	return $val;
    } else {
	return (wantarray ? () : undef);
    }
}
sub _pop_X_array {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    my @ncc = $self->$getter();
    my $rv = pop @ncc;
    my $setter = "set_$X";
    $self->$setter(@ncc);
    return $rv;
}
sub _pop_X_hash  {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    my $killer = "${X}_remove";
    my $hashref = $self->$getter();
    my ($key, $gonner) = (each %$hashref);
    $self->$killer($key => $gonner) if defined $key;
    return $gonner;
}

=item $instance->attribute_shift

Remove an element on the beginning of a collection, and return it

=cut

sub _shift_X_ref   { _pop_X_ref(@_) }
sub _shift_X_set   { _pop_X_set(@_) }
sub _shift_X_array {
    my $self = shift;
    my $X = shift;
    my $getter = "get_$X";
    my @ncc = $self->$getter();
    my $rv = shift @ncc;
    my $setter = "set_$X";
    $self->$setter(@ncc);
    return $rv;
}
sub _shift_X_hash  { _pop_X_hash(@_) }


=item $instance->attribute_splice($offset, $length, @objects)

Pretends that the collection is an array and splices it.

=cut

sub _splice_X_ref {  _splice_X_array(@_) }
sub _splice_X_set {  _splice_X_array(@_) }
sub _splice_X_array  {
    my $self = shift;
    my $X = shift;
    my $getter = "get_${X}";
    my $setter = "set_${X}";
    my @list = $self->$getter();
    if (wantarray) {
	my @rv = splice @list, @_;
	$self->$setter(@list);
	return @rv;
    } else {
	my $rv = splice @list, @_;
	$self->$setter(@list);
	return $rv;
    }
}
sub _splice_X_hash  {
    my $self = shift;
    my $X = shift;
    my $getter = "${X}_pairs";
    my $setter = "set_${X}";
    my @list = $self->$getter();
    if (wantarray) {
	my @rv = splice @list, @_;
	$self->$setter(@list);
	return @rv;
    } else {
	my $rv = splice @list, @_;
	$self->$setter(@list);
	return $rv;
    }
}

=item $instance->attribute_remove(@objects)

translates logically to a search for that item or index, followed by a
delete

This suite of functions applies to attributes that are sets (C<iset>
or C<set>).  It could in theory also apply generally to all
collections - ie also arrays (C<iarray> or C<array>), and hashes
(C<hash>, C<ihash>).

All of these modifications build a new container, then call
$object->set_attribute($container)

It is up to the set_attribute() function to update all related
classes.

=cut

sub _listify {
    map { (blessed($_)
	   ? (
	      $_->isa("Set::Object")
	      ? $_->members()
	      : $_
	     )
	   : (ref $_ eq "HASH"
	      ? (keys %$_)
	      : (ref $_ eq "ARRAY"
		 ? @$_
		 : ()))) } @_
}

sub _remove_X_ref {
    my $self = shift;
    my $X = shift;
    my $setter = "set_$X";
    my $getter = "get_$X";
    my $remove = Set::Object->new(_listify(@_));
    return $self->$setter(grep { !$remove->includes($_) }
			  $self->$getter);
}
sub _remove_X_set {
    my $self = shift;
    my $X = shift;
    my $setter = "set_$X";
    my $getter = "get_$X";
    my $remove = Set::Object->new(_listify(@_));
    return $self->$setter(grep { !$remove->includes($_) }
			  $self->$getter);
}

sub _remove_X_array {
    my $self = shift;
    my $X = shift;
    my $setter = "set_$X";
    my $getter = "get_$X";
    my @new = ($self->$getter);
    my %gone;
    while (@_) {
	my $item = shift;
	if (blessed($item)) {
	    for (my $i = 0; $i < @new; $i++) {
		$gone{$i} = 1, last
		    if (refaddr($item) == refaddr($new[$i]));
	    }
	} elsif (defined(ish_int($item))) {
	    $gone{$item} = 1;
	} else {
	    for (my $i = 0; $i < @new; $i++) {
		$gone{$i} = 1, last unless $gone{$i};
	    }
	}
    }
    delete @new[keys %gone];
    return $self->$setter(@new);
}

sub _remove_X_hash {
    my $self = shift;
    my $X = shift;
    my $getter = "${X}_pairs";
    my $setter = "set_$X";
    my %new = $self->$getter();
    while (@_) {
	my $item = shift;

	if (blessed($item)) {
	    while (my ($k, $v) = each %new) {
		$item = $k if (refaddr($item) == refaddr($v));
	    }
	} elsif (blessed($_[0])) {
	    # FIXME - only delete if the values match, perhaps?
	}

	($item) = next %new if (defined(ish_int($item)));

	delete $new{$item};
    }
    return $self->$setter(%new);
}




=back

B<Note:> The above functions can be overridden, but they may not be
called with the C<$self-E<gt>SUPER::> superclass chaining method.
This is because they are not defined within the scope of
Class::Tangram, only your package.

=cut

=head1 ATTRIBUTE TYPE CHECKING

Class::Tangram provides type checking of attributes when attributes
are set - either using the default C<set_attribute> functions, or
created via the C<new> constructor.

The checking has default behaviour for each type of attribute (see
L<Default Type Checking>), and can be extended arbitrarily via a
per-attribute C<check_func>, described below.  Critical attributes can
be marked as such with the C<required> flag.

The specification of this type checking is placed in the class schema,
in the per-attribute B<options hash>.  This is a Class::Tangram
extension to the Tangram schema structure.

=over

=item check_func

A function that is called with a B<reference> to the new value in
C<$_[0]>.  It should call C<die()> if the value is bad.  Note that
this check_func will never be passed an undefined value; this is
covered by the "required" option, below.

In the example schema (above), the attribute C<segments> has a
C<check_func> that prevents setting the value to anything greater than
30.  Note that it does not prevent you from setting the value to
something that is not an integer; if you define a C<check_func>, it
replaces the default.

=item required

If this option is set to a true value, then the attribute must be set
to a true value to pass type checking.  For string attributes, this
means that the string must be defined and non-empty (so "0" is true).
For other attribute types, the normal Perl definition of logical truth
is used.

If the required option is defined but logically false, (ie "" or 0),
then the attribute must also be defined, but may be set to a logically
false value.

If the required option is undefined, then the attribute may be set to
an undefined value.

For integration with tangram, the C<new()> function has a special
hack; if it is being invoked from within Tangram, then the required
test is skipped.

=back

=head2 Other per-attribute options

Any of the following options may be inserted into the per-attribute
B<options hash>:

=over

=item init_default

This value specifies the default value of the attribute when
it is created with C<new()>.  It is a scalar value, it is
copied to the fresh object.  If it is a code reference, that
code reference is called and its return value inserted into
the attribute.  If it is an ARRAY or HASH reference, then
that array or hash is COPIED into the attribute.

=item destroy_func

If anything special needs to happen to this attribute before the
object is destroyed (or when someone calls
C<$object-E<gt>clear_refs()>), then define this.  It is called as
C<$sub-E<gt>($object, "attribute")>.

=back

=head2 Default Type Checking

Default type checking s

=cut


=over

=item check_X (\$value)

This series of internal functions are built-in C<check_func> functions
defined for all of the standard Tangram attribute types.

=over

=item check_string

checks that the supplied value is less than 255 characters long.

=cut

sub check_string {
    croak "string too long (${$_[0]})"
	if (length ${$_[0]} > 255);
}

=item check_int

checks that the value is a (possibly signed) integer

=cut

sub check_int {
    no warnings;
    croak "not an integer (${$_[0]})"
	unless (is_int ${$_[0]} or ${$_[0]}+0 eq ${$_[0]});
}

=item check_real

checks that the value is a real number, by stringifying it and
matching it against (C<m/^-?\d*(\.\d*)?(e-?\d*)?$/>).  Inefficient?
Yes.  Patches welcome.

With my cries for help, where are the user-submitted patches?!  Well,
this function now checks the scalar flags that indicate that it
contains a number, which isn't flawless, but a lot faster :)

=cut

my $real_re = qr/^-?\d*(\.\d*)?(e-?\d*)?$/;
sub check_real {
    croak "not a real number (${$_[0]})"
	unless (is_double(${$_[0]}) or is_int(${$_[0]})
		or ${$_[0]} =~ m/$real_re/);
}

=item check_obj

checks that the supplied variable is a reference to a blessed object

=cut

# this pattern matches a regular reference
sub check_obj {
    croak "${$_[0]} is not an object reference"
	unless (blessed ${ $_[0] }
		or !${ $_[0] });
}

=item check_flat_array

checks that $value is a ref ARRAY and that all elements are unblessed
scalars.  Does NOT currently check that all values are of the correct
type (int vs real vs string, etc)

=cut

sub check_flat_array {
    croak "${$_[0]} is not a flat array"
	if (ref ${$_[0]} ne "ARRAY");
    croak "flat array ${$_[0]} may not contain references"
	if (map { (ref $_ ? "1" : ()) } @${$_[0]});
}

=item check_rawdate

checks that $value is of the form YYYY-MM-DD, or YYYYMMDD, or YYMMDD.

=cut

# YYYY-MM-DD HH:MM:SS
my $rawdate_re = qr/^(?:  \d{4}-\d{2}-\d{2}
                     |    (?:\d\d){3,4}
                     )$/x;
sub check_rawdate {
    croak "invalid SQL rawdate `${$_[0]}'"
	unless (${$_[0]} =~ m/$rawdate_re/o);
}

=item check_rawtime

checks that $value is of the form HH:MM(:SS)?

=cut

# YYYY-MM-DD HH:MM:SS
my $rawtime_re = qr/^\d{1,2}:\d{2}(?::\d{2})?$/;
sub check_rawtime {
    croak "invalid SQL rawtime `${$_[0]}'"
	unless (${$_[0]} =~ m/$rawtime_re/o);
}

=item check_rawdatetime

checks that $value is of the form YYYY-MM-DD HH:MM(:SS)? (the time
and/or the date can be missing), or a string of numbers between 6 and
14 numbers long.

=cut

my $rawdatetime_re = qr/^(?:
			    # YYYY-MM-DD HH:MM:SS
		            (?: (?:\d{4}-\d{2}-\d{2}\s+)?
		                \d{1,2}:\d{2}(?::\d{2})?
			    |   \d{4}-\d{2}-\d{2}
			    )
		         |  # YYMMDD, etc
		            (?:\d\d){3,7}
		         )$/x;
sub check_rawdatetime {
    croak "invalid SQL rawdatetime `${$_[0]}'"
	unless (${$_[0]} =~ m/$rawdatetime_re/o);
}

=item check_dmdatetime

checks that $value is of the form YYYYMMDDHH:MM:SS, or those allowed
for rawdatetime.

=cut

sub check_dmdatetime {
    croak "invalid dmdatetime `${$_[0]}'"
	unless (${$_[0]} =~ m/^\d{10}:\d\d:\d\d$|$rawdatetime_re/o
		or Date::Manip::ParseDate(${$_[0]}));
}

=item check_flat_hash

checks that $value is a ref HASH and all values are scalars.  Does NOT
currently check that all values are of the correct type (int vs real
vs string, etc)

=cut

sub check_flat_hash {
    croak "${$_[0]} is not a hash"
	unless (ref ${$_[0]} eq "HASH");
    while (my ($k, $v) = each %${$_[0]}) {
	croak "hash not flat"
	    if (ref $k or ref $v);
    }
}

=item check_set

Checks that the passed value is a Set::Object

=cut

sub check_set {
    confess "${$_[0]} is not a set"
	unless (UNIVERSAL::isa(${$_[0]}, "Set::Object"));
}

=item check_hash

Checks that the passed value is a perl HV

=cut

sub check_hash {
    confess "${$_[0]} is not a hash"
	unless (reftype(${$_[0]}) eq "HASH");
}

=item check_array

Checks that the passed value is a perl AV

=cut

sub check_array {
    confess "${$_[0]} is not an array"
	unless (reftype(${$_[0]}) eq "ARRAY");
}

=item check_nothing

checks whether Australians like sport

=cut

sub check_nothing { }

=back

=item destroy_X ($instance, $attr)

Similar story with the check_X series of functions, these are called
during object destruction on every attribute that has a reference that
might need breaking.  Note: B<these functions all assume that
attributes belonging to an object that is being destroyed may be
destroyed also>.  In other words, do not allow distinct objects to
share Set::Object containers or hash references in their attributes,
otherwise when one gets destroyed the others will lose their data.

Available functions:

=over

=item destroy_array

empties an array

=cut

sub destroy_array {
    my $self = shift;
    my $attr = shift;
    my $t = tied $self->{$attr};
    @{$self->{$attr}} = ()
	unless (defined $t and $t =~ m,Tangram::CollOnDemand,);
    delete $self->{$attr};
}

=item destroy_set

Calls Set::Object::clear to clear the set

=cut

sub destroy_set {
    my $self = shift;
    my $attr = shift;

    #return if (reftype $self ne "HASH");
    my $t = tied $self->{$attr};
    return if (defined $t and $t =~ m,Tangram::CollOnDemand,);
    if (ref $self->{$attr} eq "Set::Object") {
	$self->{$attr}->clear;
    }
    delete $self->{$attr};
}

=item destroy_hash

empties a hash

=cut

sub destroy_hash {
    my $self = shift;
    my $attr = shift;
    my $t = tied $self->{$attr};
    %{$self->{$attr}} = ()
	unless (defined $t and $t =~ m,Tangram::CollOnDemand,);
    delete $self->{$attr};
}

=item destroy_ref

destroys a reference.

=cut

sub destroy_ref {
    my $self = shift;
    delete $self->{(shift)};
}

=back

=item parse_X ($attribute, { schema option })

Parses the schema option field, and returns one or two closures that
act as a check_X and a destroy_X function for the attribute.

This is currently a very ugly hack, parsing the SQL type definition of
an object.  But it was bloody handy in my case for hacking this in
quickly.  This is probably unmanagably unportable across databases;
but send me bug reports on it anyway, and I'll try and make the
parsers work for as many databases as possible.

This perhaps should be replaced by primitives that go the other way,
building the SQL type definition from a more abstract definition of
the type.

Available functions:

=over

=item parse_string

parses SQL types of:

=over

=cut

use vars qw($quoted_part $sql_list);

$quoted_part = qr/(?: \"([^\"]+)\" | \'([^\']+)\' )/x;
$sql_list = qr/\(\s*
		  (
		      $quoted_part
		        (?:\s*,\s* $quoted_part )*
	          ) \s*\)/x;

sub parse_string {

    my $attribute = shift;
    my $option = shift;

    # simple case; return the check_string function.  We don't
    # need a destructor for a string so don't return one.
    if (!$option->{sql}) {
	return \&check_string;
    }

    my $sql = $option->{sql};

    # remove some common suffixes
    $sql =~ s{\s+default\s+\S+}{}si;
    $sql =~ s{(\s+not)?\s+null}{}si;

=item CHAR(N), VARCHAR(N)

closure checks length of string is less than N characters

=cut

    if ($option->{sql} =~ m/^\s*(?:var)?char\s*\(\s*(\d+)\s*\)/ix) {
	my $max_length = $1;
	return sub {
	    croak "string too long for $attribute"
		if (length ${$_[0]} > $max_length);
	};

=item TINYBLOB, BLOB, LONGBLOB

checks max. length of string to be 255, 65535 or 16777215 chars
respectively.  Also works with "TEXT" instead of "BLOB"

=cut

    } elsif ($option->{sql} =~ m/^\s*(?:tiny|long|medium)?
				 (?:blob|text)/ix) {
	my $max_length = ($1 ? ($1 eq "tiny"?255:2**24 - 1)
			  : 2**16 - 1);
	return sub {
	    croak "string too long for $attribute"
		if (${$_[0]} and length ${$_[0]} > $max_length);
	};

=item SET("members", "of", "set")

checks that the value passed is valid as a SQL set type, and that all
of the passed values are allowed to be a member of that set.

=cut

    } elsif (my ($members) = $option->{sql} =~
	     m/^\s*set\s*$sql_list/oi) {

	my %members;
	$members{lc($1 || $2)} = 1
	    while ( $members =~ m/\G[,\s]*$quoted_part/cog );

	return sub {
	    for my $x (split /\s*,\s*/, ${$_[0]}) {
		croak ("SQL set badly formed or invalid member $x "
		       ." (SET" . join(",", keys %members). ")")
		    if (not exists $members{lc($x)});
	    }
	};

=item ENUM("possible", "values")

checks that the value passed is one of the allowed values.

=cut

    } elsif (my ($values) = $option->{sql} =~
	     m/^\s*enum\s*$sql_list/oi ) {

	my %values;
	$values{lc($1 || $2)} = 1
	    while ( $values =~ m/\G[,\s]*$quoted_part/gc);

	return sub {
	    croak ("invalid enum value ${$_[0]} must be ("
		   . join(",", keys %values). ")")
		if (not exists $values{lc(${$_[0]})});
	}


    } else {
	croak ("Please build support for your string SQL type in "
	     ."Class::Tangram (".$option->{sql}.")");
    }
}

=back

=back

=back

=head2 Quick Object Dumping and Destruction

=over

=item $instance->quickdump

Quickly show the blessed hash of an object, without descending into
it.  Primarily useful when you have a large interconnected graph of
objects so don't want to use the B<x> command within the debugger.
It also doesn't have the side effect of auto-vivifying members.

This function returns a string, suitable for print()ing.  It does not
currently escape unprintable characters.

=cut

sub quickdump {
    my $self = shift;

    my $r = "REF ". (ref $self). "\n";
    for my $k (sort keys %$self) {
	eval {
	    $r .= ("   $k => "
		   . (
		      tied $self->{$k}
		      || ( ref $self->{$k}
			   ? $self->{$k}
			   : ( defined ($self->{$k})
			       ? "'".$self->{$k}."'"
			   : "undef" )
			 )
		     )
		   . "\n");
	};
	if ($@) {
	    $r .= "   $k => Error('$@')\n";
	}
    }
    return $r;
}


=item $instance->DESTROY

This function ensures that all of your attributes have their
destructors called.  It calls the destroy_X function for attributes
that have it defined, if that attribute exists in the instance that we
are destroying.  It calls the destroy_X functions as destroy_X($self,
$k)

=cut

sub DESTROY {
    my $self = shift;

    my $class = ref $self;

    # if no cleaners are known for this class, it hasn't been imported
    # yet.  Don't call import_schema, that would be a bad idea in a
    # destructor.
    exists $cleaners{$class} or return;

    # for every attribute that is defined, and has a cleaner function,
    # call the cleaner function.
    for my $k (keys %$self) {
	if (defined $cleaners{$class}->{$k} and exists $self->{$k}) {
	    $cleaners{$class}->{$k}->($self, $k);
	}
    }
    $self->{_DESTROYED} = 1;
}

=item $instance->clear_refs

This clears all references from this object, ie exactly what DESTROY
normally does, but calling an object's destructor method directly is
bad form.  Also, this function has no qualms with loading the class'
schema with import_schema() as needed.

This is useful for breaking circular references, if you know you are
no longer going to be using an object then you can call this method,
which in many cases will end up cleaning up most of the objects you
want to get rid of.

However, it still won't do anything about Tangram's internal reference
to the object, which must still be explicitly unlinked with the
Tangram::Storage->unload method.

=cut

sub clear_refs {
    my $self = shift;
    my $class = ref $self;

    exists $cleaners{$class} or import_schema($class);

    # break all ref's, sets, arrays
    for my $k (keys %$self) {
	if (defined $cleaners{$class}->{$k} and exists $self->{$k}) {
	    $cleaners{$class}->{$k}->($self, $k);
	}
    }
    $self->{_NOREFS} = 1;
}

=back

=head1 FUNCTIONS

The following functions are not intended to be called as object
methods.

=head2 Schema Import

 our $fields = { int => [ qw(foo bar) ],
                 string => [ qw(baz quux) ] };

 # Version 1.115 and below compatibility:
 our $schema = {
    fields => { int => [ qw(foo bar) ],
                string => [ qw(baz quux) ] }
    };

=over

=item Class::Tangram::import_schema($class)

Parses a tangram object field list, in C<${"${class}::fields"}> (or
C<${"${class}::schema"}-E<gt>{fields}> to the internal type information
hashes.  It will also define all of the attribute accessor and update
methods in the C<$class> package.

Note that calling this function twice for the same class is not
tested and may produce arbitrary results.  Patches welcome.

=cut

 # "parse" is special - it is passed the options hash given
 # by the user and should return (\&check_func,
 # \&destroy_func).  This is how the magical string type
 # checking is performed - see the entry for parse_string(),
 # below.

%defaults = (
	     int         => { check_func   => \&check_int,
			      load         => "Tangram/Scalar.pm",
			    },
	     real        => { check_func   => \&check_real,
			      load         => "Tangram/Scalar.pm",
			    },
	     string      => { parse        => \&parse_string,
			      load         => "Tangram/Scalar.pm",
			    },
	     ref         => { check_func   => \&check_obj,
			      destroy_func => \&destroy_ref,
			      load         => "Tangram/Ref.pm",
			    },
	     array       => { check_func   => \&check_array,
			      destroy_func => \&destroy_array,
			      load         => "Tangram/Array.pm",
			    },
	     iarray      => { check_func   => \&check_array,
			      destroy_func => \&destroy_array,
			      load         => "Tangram/IntrArray.pm",
			    },
	     flat_array  => { check_func   => \&check_flat_array,
			      load         => "Tangram/FlatArray.pm",
			    },
	     set         => { check_func   => \&check_set,
			      destroy_func => \&destroy_set,
			      init_default => sub { Set::Object->new() },
			      load         => "Tangram/Set.pm",
			    },
	     iset        => { check_func   => \&check_set,
			      destroy_func => \&destroy_set,
			      init_default => sub { Set::Object->new() },
			      load         => "Tangram/IntrSet.pm",
			    },
	     dmdatetime  => { check_func   => \&check_dmdatetime,
			      load         => "Tangram/DMDateTime.pm",
			    },
	     rawdatetime => { check_func   => \&check_rawdatetime,
			      load         => "Tangram/RawDateTime.pm",
			    },
	     rawdate     => { check_func   => \&check_rawdate,
			      load         => "Tangram/RawDate.pm",
			    },
	     rawtime     => { check_func   => \&check_rawtime,
			      load         => "Tangram/RawTime.pm",
			    },
	     flat_hash   => { check_func   => \&check_flat_hash,
			      load         => "Tangram/FlatHash.pm",
			    },
	     transient   => { check_func   => \&check_nothing,
			    },
	     hash        => { check_func   => \&check_hash,
			      destroy_func => \&destroy_hash,
			      load         => "Tangram/Hash.pm",
			    },
	     ihash       => { check_func   => \&check_hash,
			      destroy_func => \&destroy_hash,
			      load         => "Tangram/IntrHash.pm",
			    },
	     perl_dump   => { check_func   => \&check_nothing,
			      load         => "Tangram/PerlDump.pm",
			    },
	     yaml        => { check_func   => \&check_nothing,
			      load         => "Tangram/YAML.pm",
			    },
	     backref     => { check_func   => \&check_nothing,
			    },
	     storable    => { check_func   => \&check_nothing,
			      load         => "Tangram/Storable.pm",
			    },
	     idbif       => { check_func   => \&check_nothing,
			      load         => "Tangram/IDBIF.pm",
			    },
	    );

sub import_schema {    # Damn this function is long
    my $class = shift;

    return if exists $abstract{$class};

    eval {
	my ($fields, $bases, $abstract);
	{

	    # Here, we go hunting around for their defined schema and
	    # options
	    local $^W=0;
	    eval {
		$fields = (${"${class}::fields"} ||
			   ${"${class}::schema"}->{fields});
		$abstract = (${"${class}::abstract"} ||
			     ${"${class}::schema"}->{abstract});
		$bases = ${"${class}::schema"}->{bases};
	    };
	    if ( my @stack = (grep !/${class}::CT/,
			      @{"${class}::ISA"} )) {
		# clean "bases" information from @ISA
		my %seen = map { $_ => 1 } $class, __PACKAGE__;
		$bases = [];
		while ( my $super = pop @stack ) {
		    if ( defined ${"${super}::schema"}
			 or defined ${"${super}::fields"} ) {
			push @$bases, $super;
		    } else {
			push @stack, grep { !$seen{$_}++ }
			    @{"${super}::ISA"};
		    }
		}
		if ( !$fields and !@$bases ) {
		    croak ("No schema and no Class::Tangram "
			 ."superclass for $class; define "
			 ."${class}::fields!");
		}
	    }
	}

	# play around with the @ISA to insert an intermediate package
	my $target_pkg = $class."::CT";
	my $target_stash = \%{$target_pkg."::"};
	(@{$target_pkg."::ISA"}, @{$class."::ISA"})
	    = @{$class."::ISA"};
	@{$class."::ISA"} = $target_pkg;

	# if this is an abstract type, do not allow it to be
	# instantiated
        $abstract{$class} = $abstract ? 1 : 0;

	# If there are any base classes, import them first so that the
	# check, cleaners and init_defaults can be inherited
	if (defined $bases) {
	    (ref $bases eq "ARRAY")
		or croak "bases not an array ref for $class";

	    # Note that the order of your bases is significant, that
	    # is if you are using multiple iheritance then the later
	    # classes override the earlier ones.
	    for my $super ( @$bases ) {
		import_schema($super) unless (exists $check{$super});

		# copy each of the per-class configuration hashes to
		# this class as defaults.
		my ($k, $v);

		# FIXME - this repetition of code is getting silly :)
		$types{$class}->{$k} = $v
		    while (($k, $v) = each %{ $types{$super} } );
		$check{$class}->{$k} = $v
		    while (($k, $v) = each %{ $check{$super} } );
		$cleaners{$class}->{$k} = $v
		    while (($k, $v) = each %{ $cleaners{$super} } );
		$attribute_options{$class}->{$k} = $v
		    while (($k, $v) = each %{ $attribute_options{$super} } );
		$init_defaults{$class}->{$k} = $v
		    while (($k, $v) = each %{ $init_defaults{$super} } );
		$required_attributes{$class}->{$k} = $v
		    while (($k, $v) = each %{ $required_attributes{$super} } );
		$companions{$class}->{$k} = $v
		    while (($k, $v) = each %{ $companions{$super} } );
	    }
	}

	# iterate over each of the *types* of fields (string, int, ref, etc.)
	while (my ($type, $v) = each %$fields) {
	    if (ref $v eq "ARRAY") {
		$v = { map { $_, undef } @$v };
	    }

	    # iterate each of the *attributes* of a particular type
	    while (my ($attribute, $options) = each %$v) {

		my $accessors = _mk_accessor($attribute, $options, $class,
					     $target_pkg, $type);
                # now export all these accessors into caller's namespace
                while (my ($accessor, $coderef) = each %$accessors) {
                    my $accessor_name = $accessor;
                    # comes in like $class::$meth, so extract our meth
                    $accessor_name =~ s/(.*\:\:)+(\w+)$/$2/;
                    *{$accessor} = $coderef
                       unless $target_pkg->can($accessor_name);
                }
	    }
	}
    };
    $cleaners{$class} ||= {};

    $@ && die "$@ while trying to import schema for $class";
}

sub _mk_accessor {

    my ($attribute, $options, $class, $target_pkg, $type, $dontcarp) = @_;

    my $def = $defaults{$type};

    # hash of various accessor code refs to return
    my %accessors;

    # this is what we are finding out about each attribute
    # $type is already set
    my ($check_func, $default, $required, $cleaner,
        $companion, $base_type, $load);
    # set defaults from what they give
    $options ||= {};
    if (ref $options eq "HASH" or
        UNIVERSAL::isa($options, 'Tangram::Type')) {
        ($check_func, $default, $required, $cleaner,
         $companion, $base_type, $load)
          = @{$options}{qw(check_func init_default
                           required destroy_func
                           companion class load)};
    }

    # Fill their settings with info from defaults
    if (ref $def eq "HASH") {

        # try to magically parse their options
        if ( $def->{parse} and !($check_func and $cleaner) ) {
            my @a = $def->{parse}->($attribute, $options);
            $check_func ||= $a[0];
            $cleaner ||= $a[1];
        }

        # fall back to defaults for this class
        $load ||= $def->{load};
        $check_func ||= $def->{check_func};
        $cleaner ||= $def->{destroy_func};
        $default = $def->{init_default} unless defined $default;
    }

    # load a Tangram::Type module, if specified
    unless ($no_tangram or not defined $load) {
        if (!exists $INC{$load}) {
            eval 'require $load';
            $no_tangram = 1 if $@;
        }
    }

    # everything must be checked!
    croak("No check function for ${class}\->$attribute "
          ."(type $type); set \$Class::Tangram::defaults"
          ."{backref} to a sub (eg, \&Class::Tangram::"
          ."check_nothing)")
      unless (ref $check_func eq "CODE");

    carp("re-defining attribute `$attribute' in subclass "
         ."`$class'") if $^W and
           exists $types{$class}->{$attribute} and not $dontcarp;

    $types{$class}->{$attribute} = $type;
    $check{$class}->{$attribute} = $check_func;
    {
        local ($^W) = 0;

        # build an appropriate "get_attribute" method, and
        # define other per-type methods
        my ($get_closure, $set_closure, $is_assoc,
            $method_type);

        # implement with closures for speed
        if ( $type =~ m/^i?(set|array|hash|ref)$/ ) {
            $method_type = $1;
            $is_assoc = 1;
            $get_closure = "_get_X_$method_type";
            $set_closure = "_set_X_$method_type";
        } else {
            # GET_$attribute (scalar)
            # return value only
            $get_closure = sub { $_[0]->{$attribute}; };
        }

        # SET_$attribute (all)
        my $checkit = \$check{$class}->{$attribute};

        unless ($is_assoc or $set_closure) {
            # `required' hack for strings - duplicate the code
            # to avoid the following string comparison for
            # every set
            if ( $type eq "string" ) {
                $set_closure = sub {
                    my $self = shift;
                    my $value = shift;
                    my $err = '';
                    if ( defined $value and length $value ) {
                        $ {$checkit}->(\$value);
                    } elsif ( $required ) {
                        $err = "value is required";
                    } elsif ( defined $required ) {
                        $err = "value must be defined"
                          unless defined $value;
                    }
                    $err && croak
                      ("value failed type check - ${class}->"
                       ."set_$attribute('".($value || '')."') ($err)");
                    $self->{$attribute} = $value;
                }
            } else {
                $set_closure = sub {
                    my $self = shift;
                    my $value = shift;
                    my $err = '';
                    if ( defined $value ) {
                        $ {$checkit}->(\$value);
                    } elsif ( $required ) {
                        $err = "value is required";
                    } elsif ( defined $required ) {
                        $err = "value must be defined"
                          unless defined $value;
                    }
                    $err && croak
                      ("value failed type check - ${class}->"
                       ."set_$attribute('".($value || '')."') ($err)");
                    $self->{$attribute} = $value;
                }
            }
        }

        # flat hashes & arrays
        if ( $type =~ m/^flat_(array|hash)$/ ) {
            if ($1 eq "hash") {
                $get_closure = sub {
                    my $self = shift;
                    my $a = ($self->{$attribute} ||= {});
                    return (wantarray ? values %{ $a }
                            : $a);
                }
            } else {
                $get_closure = sub {
                    my $self = shift;
                    my $a = ($self->{$attribute} ||= []);
                    return (wantarray ? @{ $a } : $a);
                }
            }
        }

        # now collect the closures
        my ($getter, $setter)
          = ("get_$attribute", "set_$attribute");

        $accessors{$target_pkg."::".$getter} =
          (ref $get_closure ? $get_closure
           : sub {
               my $self = shift;
               return $self->$get_closure($attribute, @_);
           });
        $accessors{$target_pkg."::".$setter} =
          (ref $set_closure ? $set_closure
           : sub {
               my $self = shift;
               return $self->$set_closure
                 ($base_type, $companion, $attribute, @_);
           });

        if ($is_assoc) {

            foreach my $func (qw(includes insert replace
                                 pairs size clear remove
                                 push pop shift unshift
                                 splice)) {
                my $method = $target_pkg."::".$attribute."_".$func;
                my $real_method =
                  "_${func}_X_$method_type";
                $accessors{$method} =
                  sub {
                      my $self = shift;
                      return $self->$real_method($attribute, @_);
                  }
              }

	    # XXX - use `Want' to return lvalue subs here
            $accessors{$target_pkg."::$attribute"} = sub {
                my $self = shift;
                if ( @_ && looks_like_KVKV(@_) ) {
                    carp("The OO Police say change your call "
                         ."to ->set_$attribute") if ($^W);
                    return $self->$setter(@_);
                } elsif ( !@_ || looks_like_KK(@_) ) {
                    return $self->$getter(@_);
                } else {
                    croak("Ambiguous argument list "
                          ."passed to ${class}::"
                          ."${attribute}");
                }
            }

        } else {

	    # XXX - use `Want' to return lvalue subs here
            $accessors{$target_pkg."::$attribute"} = sub {
                my $self = shift;
                if ( @_ ) {
                    carp("The OO Police say change your call "
                         ."to ->set_$attribute") if ($^W);
                    return $self->$setter(@_);
                } else {
                    return $self->$getter(@_);
                }
            }

        }

        $cleaners{$class}->{$attribute} = $cleaner
          if (defined $cleaner);
        $init_defaults{$class}->{$attribute} = $default
          if (defined $default);
        $required_attributes{$class}->{$attribute} = $required
          if (defined $required);
        $attribute_options{$class}->{$attribute} =
          ( $options || {} );
        $companions{$class}->{$attribute} = $companion
          if (defined $companion);

    }
    return \%accessors;
}

=back

=head2 Run-time type information

It is possible to access the data structures that Class::Tangram uses
internally to verify attributes, create objects and so on.

This should be considered a B<HIGHLY EXPERIMENTAL> interface to
B<INTERNALS> of Class::Tangram.

Class::Tangram keeps seven internal hashes:

=over

=item C<%types>

C<$types{$class}-E<gt>{$attribute}> is the tangram type of each attribute,
ie "ref", "iset", etc.  See L<Tangram::Type>.

=item C<%attribute_options>

C<$attribute_options{$class}-E<gt>{$attribute}> is the options hash
for a given attribute.

=item C<%required_attributes>

C<$required_attributes{$class}-E<gt>{$attribute}> is the 'required'
option setting for a given attribute.

=item C<%check>

C<$check{$class}-E<gt>{$attribute}> is a function that will be passed
a reference to the value to be checked and either throw an exception
(die) or return true.

=item C<%cleaners>

C<$attribute_options{$class}-E<gt>{$attribute}> is a reference to a
destructor function for that attribute.  It is called as an object
method on the object being destroyed, and should ensure that any
circular references that this object is involved in get cleared.

=item C<%abstract>

C<$abstract-E<gt>{$class}> is set if the class is abstract

=item C<%init_defaults>

C<$init_defaults{$class}-E<gt>{$attribute}> represents what an
attribute is set to automatically if it is not specified when an
object is created. If this is a scalar value, the attribute is set to
the value. If it is a function, then that function is called (as a
method) and should return the value to be placed into that attribute.
If it is a hash ref or an array ref, then that structure is COPIED in
to the new object.  If you don't want that, you can do something like
this:

   [...]
    flat_hash => {
        attribute => {
            init_default => sub { { key => "value" } },
        },
    },
   [...]

Now, every new object will share the same hash for that attribute.

=item C<%companions>

Any "Companion" relationships between attributes, that are to be
treated as linked pairs of relationships; deleting object A from
container B of object C will also cause object C to be removed from
container D of object A.

=back

There are currently four functions that allow you to access parts of
this information.

=over

=item Class::Tangram::attribute_options($class)

Returns a hash ref to a data structure from attribute names to the
option hash for that attribute.

=cut

sub attribute_options {
    my $class = shift;
    return $attribute_options{$class};
}

=item Class::Tangram::attribute_types($class)

Returns a hash ref from attribute names to the tangram type for that
attribute.

=cut

sub attribute_types {
    my $class = shift;
    return $types{$class};
}

=item Class::Tangram::required_attributes($class)

Returns a hash ref from attribute names to the 'required' option setting for
that attribute.  May also be called as a method, as in
C<$instance-E<gt>required_attributes>.

=cut

sub required_attributes {
    my $class = ref $_[0] || $_[0];
    return $required_attributes{$class};
}

=item Class::Tangram::init_defaults($class)

Returns a hash ref from attribute names to the default intial values for
that attribute.  May also be called as a method, as in
C<$instance-E<gt>init_defaults>.

=cut

sub init_defaults {
    my $class = ref $_[0] || $_[0];
    return $init_defaults{$class};
}

=item Class::Tangram::companions($class)

Returns a hash ref from attribute names to the default intial values for
that attribute.  May also be called as a method, as in
C<$instance-E<gt>init_defaults>.

=cut

sub companions {
    my $class = ref $_[0] || $_[0];
    if (!defined($class)) {
	return keys %companions;
    } else {
	return $companions{$class};
    }
}

=item Class::Tangram::known_classes

This function returns a list of all the classes that have had their
object schema imported by Class::Tangram.

=cut

sub known_classes {
    return keys %types;
}

=item Class::Tangram::is_abstract($class)

This function returns true if the supplied class is abstract.

=cut

sub is_abstract {
    my $class = shift;
    $class eq "Class::Tangram" && ($class = shift);

    exists $cleaners{$class} or import_schema($class);
}

=item Class->set_init_default(attribute => $value);

Sets the default value on an attribute for newly created "Class"
objects, as if it had been declared with init_default.  Can be called
as a class or an instance method.

=cut

sub set_init_default {
    my $invocant = shift;
    my $class = ref $invocant || $invocant;

    exists $init_defaults{$class} or import_schema($class);

    while ( my ($attribute, $value) = splice @_, 0, 2) {
	$init_defaults{$class}->{$attribute} = $value;
    }
}

=back

=cut

# a little embedded package

package Tangram::Transient;

BEGIN {
    eval "use base qw(Tangram::Type)";
    if ( $@ ) {
	# no tangram
    } else {
	$Tangram::Schema::TYPES{transient} = bless {}, __PACKAGE__;
    }
}

sub coldefs { }

sub get_exporter { }
sub get_importer { }

sub get_import_cols {
#    print "Get_import_cols:" , Dumper \@_;
    return ();
}

=head1 SEE ALSO

L<Tangram::Schema>

B<A guided tour of Tangram, by Sound Object Logic.>

 http://www.soundobjectlogic.com/tangram/guided_tour/fs.html

=head1 DEPENDENCIES

The following modules are required to be installed to use
Class::Tangram:

   Set::Object => 1.02
   Test::Simple => 0.18
   Date::Manip => 5.21

Test::Simple and Date::Manip are only required to run the test suite.

If you find Class::Tangram passes the test suite with earlier versions
of the above modules, please send me an e-mail.

=head2 MODULE RELEASE

This is Class::Tangram version 1.14.

=head1 BUGS/TODO

=over

=item *

Inside an over-ridden C<$obj->set_attribute> function, it is not
possible to call C<$self->SUPER::set_attribute>, because that function
does not exist in any superclass' namespace.  So, you have to modify
your own hash directly - ie

  $self->{attribute} = $value;

Instead of the purer OO

  $self->SUPER::set_attribute($value);

Solutions to this problem may involve creating an intermediate
super-class that contains those functions, and then replacing
C<Class::Tangram> in C<@Class::ISA> with the intermediate class.

=item *

Container enhancements;

=over

=item copy constructor

The copy constructor now automatically duplicates 

=back


=back


   - $obj->new() should take a copy of containers etc

 New `array' functions:
   - $obj->attr_push()

 * Container notification system

   - all $obj->attr_do functions call $obj->set_attr to provide a
     single place to catch modifications of that attribute

   - 

 * 

 * back-reference notification system

There should be more functions for breaking loops; in particular, a
standard function called C<drop_refs($obj)>, which replaces references
to $obj with the appropriate C<Tangram::RefOnDemand> object so that an
object can be unloaded via C<Tangram::Storage->unload()> and actually
have a hope of being reclaimed.  Another function that would be handy
would be a deep "mark" operation for manual mark & sweep garbage
collection.

Need to think about writing some functions using C<Inline> for speed.
One of these days...

Allow C<init_default> values to be set in a default import function?

ie

  use MyClassTangramObject -defaults => { foo => "bar" };

=head1 AUTHOR

Sam Vilain, <sam@vilain.net>

=head2 CREDITS

 # Some modifications
 # Copyright Å© 2001 Micro Sharp Technologies, Inc., Vancouver, WA, USA
 # Author: Karl M. Hegbloom <karlheg@microsharp.com>
 # Perl Artistic Licence.

Many thanks to Charles Owens and David Wheeler for their feedback,
ideas, patches and bug testing.

=cut

69;

__END__

 # From old SYNOPSIS, I decided it was too long.  A lot of
 # the information here needs to be re-integrated into the
 # POD.

 package Project;

 # here's where we build the individual object schemas into
 # a Tangram::Schema object, which the Tangram::Storage
 # class uses to know which tables and columns to find
 # objects.
 use Tangram::Schema;

 # TIMTOWTDI - this is the condensed manpage version :)
 my $dbschema = Tangram::Schema->new
     ({ classes =>
       [ 'Orange'   => { fields => $Orange::fields },
         'MyObject' => { fields => $MyObject::schema }, ]});

 sub schema { $dbschema };

 package main;

 # See Tangram::Relational for instructions on using
 # "deploy" to create the database this connects to.  You
 # only have to do this if you want to write the objects to
 # a database.
 use Tangram::Relational;
 my ($dsn, $u, $p);
 my $storage = Tangram::Relational->connect
                   (Project->schema, $dsn, $u, $p);

 # Create an orange
 my $orange = Orange->new(
			  juiciness => 8,
			  type => 'Florida',
			  tag => '',  # required
			 );

 # Store it
 $storage->insert($orange);

 # This is how you get values out of the objects
 my $juiciness = $orange->juiciness;

 # a "ref" must be set to a blessed object, any object
 my $grower = bless { name => "Joe" }, "Farmer";
 $orange->set_grower ($grower);

 # these are all illegal - type checking is fairly strict
 my $orange = eval { Orange->new; };         print $@;
 eval { $orange->set_juiciness ("Yum"); };   print $@;
 eval { $orange->set_segments (31); };       print $@;
 eval { $orange->set_grower ("Mr. Nice"); }; print $@;

 # Demonstrate some "required" functionality
 eval { $orange->set_type (''); };           print $@;
 eval { $orange->set_type (undef); };        print $@;
 eval { $orange->set_tag (undef); };         print $@;

 # this works too, but is slower
 $orange->get( "juiciness" );
 $orange->set( juiciness => 123,
	       segments  => 17 );

 # Re-configure init_default - make each new orange have a
 # random juiciness
 $orange->set_init_default( juiciness => sub { int(rand(45)) } );

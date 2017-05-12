# Data::Variant.pm -- Algebraic datatypes for Perl
#
# Copyright (c) 2004-2013 Viktor Leijon (leijon@ludd.ltu.se) All rights reserved. 
# This program is free software; you can redistribute it and/or modify 
# it under the same terms as Perl itself. 
#

=head1 NAME

Data::Variant - Variant datatypes for perl.

=head1 SYNOPSIS

    use Data::Variant;
    use vars qw(&Empty &Leaf &Node);

    register_variant("Tree","Empty","Leaf <NUM>","Node Tree Tree");
    my $tree = Node((Node ((Leaf 3), (Leaf 4))), Leaf 5);

    sub printTree {
	my $tree = shift;
	my ($data, $left, $right);

	print "Data $data\n" 
	    if (match $tree,"Leaf", $data);
	printTree($left), printTree($right) 
	    if (match $tree,"Node",$left,$right);
    }

=head1 DESCRIPTION

This module offers a Haskell/O'Caml-style for variant data types. You
can register data types and then both construct them using the
constructors give, and match against them as conditionals. The best
way to understand what the module does is probably to look at the
included examples. Pattern matching together with variants is (in the
author's opinion) one of the very most useful features in Haskell and
while this implementation is very informal it serves the same
practical purpose.

There is some (very limited) typechecking available to make sure that
you use your data structure as intended (well, as declared really but
if you are wise these two coincide).

For the programmer unused to pattern matching, looking at the
synoposis or the examples is probably the easiest way to get an idea
of how to use the module.

=head1 FUNCTIONS

=over 4

=cut

package Data::Variant;

# Requires perl 5.8.0
use 5.8.0;
use warnings;
use strict;
use Carp;
use Exporter;
use Data::Dumper;
use Switch;

our $VERSION = "0.05";

our @ISA = qw(Exporter);
our @EXPORT = qw(register_variant match set_match mkpat);
our $DEBUG = 0;

sub constructor;

# Keep track of all existing datatypes.
our %dataTypes;
# This is a back-mapping from constructors to variant datatypes.
#  Do we need both this and dataTypes? Yes, it is handy.
our %constructors;
# This is the object pre-set for following calls to match 
our $matchObject; 

=item register_variant(NAME [, CONSTRUCTORS]) 

This function registers a variant with the module. The C<NAME> should
be a string uniquely naming the variant.

Next should come a list of constructors. A constructor can come in one
of two forms:

=over 8

=item * A list reference

The first element of the list should be a string, containing the name
of the constructor. This name will be the name of the constructor
function that will be used to construct new instances of this
variant. By convention constructors start with a capital letter.

The other elements should be strings indicating the type of the
variable stored in this position.

We are allowed the following types in this version:

=over 12

=item * C<< <NUM> >> - Numbers

=item * C<< <STRING> >> - Strings

=item * C<< <REF> >> - References

=item * C<< * >> - wildcard, allow any type for this field

=item * I< Type > - allow only other variants of I<Type>.

=back

This information is later used for some basic typechecking, see
L</"Typechecking">.

=item * A single string

The string should just be a space separated list, basically containing
the same as if it was list reference instead.


=back

B<NOTE: > The constructor has to be globally unique within your program.

Examples:
    
    # Registers the variant Tree with the constructors:
    #  Empty, Leaf and Node.
    #  The Empty node carries no data, the leaf node carries an int
    #  and an internal node carries two subtrees.
    register_variant("Tree","Empty","Leaf <NUM>","Node Tree Tree");

    # Essentially the same, but using list reference form.
    register_variant("Tree2", ["Empty2"],["Leaf2","<NUM>"],["Node2", "Tree2","Tree2"]);

    # The Maybe type from Haskell, often called an "optional value".
    register_variant("Maybe", "Nothing", "Just *");

=cut

sub register_variant {
    my $dt = shift;

    if (exists $dataTypes{$dt}) {
	carp "Registering datatype $dt twice";
    }

    my %altHash;
    while($_ = shift) {
	my ($con,@fields);

	# The function can be called either with space separated strings
	# or with array references.
	if (ref $_) {
	    ($con, @fields) = @{$_};
	} else {
	    ($con, @fields) = split;
	}

	carp "The constructor $con is repeated. in $dt\n"
	    if exists $altHash{$con};

	$altHash{$con} = \@fields;
	$constructors{$con} = $dt;
    }
   

    $dataTypes{$dt} =  \%altHash;
    print Dumper(\%dataTypes) if $DEBUG;

    # Last, export this variant to the caller so he gets the constructors.
    export_variant($dt,caller());

    return 1;
}

=item export_variant(VARIANT)

=item $val->export_variant

As a function, this function exports the variant named by the argument
C<VARIANT> to the calling module, making the constructors available in
the module.

As a method call, on an object that is a variant value, it exports the
constructors for the variant that the object is an instance of.

=cut

sub export_variant {
    my ($dt,$module) = @_;

    # This function is also called by register_variant.
    $module = defined $module ? $module : caller;
    
    $dt = $dt->{Type} if $dt->isa("Data::Variant");

    # We need to export all symbols to the caller so we can use them to
    # construct new instances of the variant.
    foreach my $cons (keys %{$dataTypes{$dt}}) {
	no strict;
	*{"$module\::$cons"} = sub { constructor($cons, @_) };
    }

    1;
}

=item Constructor([VARLIST])

The constructors that you gave C<register_variant> will be exported as
functions to the calling package, and are used to create new instances
of the variant. It is during this instantiation phase that type
checking is performed.

Note that if you want to use the functions without paranteses, or if
you have warnings turned on (and you probably should) you will have to
predeclare your constructors somehow, either by C<use vars qw{&Cons}>
or by C<sub Cons>.

B<Note: > The constructor will return an object with the appropriate data.

Examples:

    # Creation of some simple trees
    my $left  = Node ((Leaf 1), (Leaf 4));
    my $right = Node ((Leaf 3), Empty);
    my $tree  = Node $left, $right;

    # A few maybe variants
    my $nth   = Nothing
    my $sth   = Just "A string";



=cut

sub constructor {
    my $cons = shift;
    
    croak "Tried to use non-existing constructor $cons"
	unless (exists $constructors{$cons});

    my $type = $constructors{$cons};

    # This is the actual data object
    my $object = { Type => $type, Cons => $cons };

    # Assign all the fields.
    my @fields = @{$dataTypes{$type}->{$cons}};
    my @vals;
    foreach my $index (0..$#fields) {
	my $var = $fields[$index];
	my $val = shift;
	carp "Missing argument $var for constructor $cons" 
	    unless (defined $val);

	print "Setting $val = $var (cons: $cons)\n"
	    if ($DEBUG);

	# Simple run time typechecking.
	my $badtype = 0;
	switch ($var) {
	    # Tests "borrowed" from Switch.pm
	    case "<NUM>" { $badtype = 1 unless ((~$val&$val) eq 0) }
	    case "<STRING>" { $badtype = 1 unless (ref $val eq "") }
	    case "<REF>" { $badtype = 1 unless ref $val }
	    case "*"     { $badtype = 0 }
	    else         { # Variant type!
		$badtype = 1 unless (($val->isa("Data::Variant")) &&
				     $val->{Type} eq $var);
	    }
	}
	

	carp "Bad type, expected $var in position ".($index+1)." for $cons"
	    if $badtype;

	push @vals, $val;
    }

    $object->{VALS} = \@vals;

    croak "Too many arguments for constructor $cons"
	if (@_ > 0);

    bless $object;

    print Dumper(\$object)
	if $DEBUG;

    return $object;
}

=item match([OBJ], CONS, [VARLIST])

=item $obj->match(CONS,[VARLIST]

=item match(OBJ)

In its first two forms C<match> checks is C<OBJ> is constructed using
the constructor C<CONS> given. If it matches the variables in
C<VARLIST> are filled with the values of the fields of the object.

The number of elements in C<VARLIST> must match the number of values
in the object.

The first argument C<OBJ> can be left out if it has been pre-set using
C<set_match>.

It its second form, with only an object as parameter, it returns a
function reference that is useful in a C<switch> statement. The
contents of each C<case> must then be created using C<mkpat>.

=cut

sub match {
    my $obj;

    if (@_ == 1) {
	croak "A lone argument has to be a variant reference" 
	    unless $_[0]->isa("Data::Variant");
	my $obj = $_[0];
	# Create a closure and return it. 
	return sub { 
	      match($obj,@_)
	    };
    }

    # Find out which object to use.
    if (ref $_[0] ne "") {
	$obj = shift;
    } else {
	croak "No object pre-set" unless defined $matchObject;
	$obj = $matchObject;
    }

    croak "I need a valid object for match" 
	unless $obj->isa("Data::Variant");

    my $constr = shift;

    my $reqtype = $constructors{$constr};
    
    if ($reqtype ne $obj->{Type}) {
	carp "Non matching datatype. Has $obj->{Type} expected $reqtype";
	# You know, if this was Haskell this would have been a 
	# static type error to begin with.
    }
    
    if ($obj->{Cons} ne $constr) {
	# Not a match
	return 0;
    } else {
	# A match.

	#  1) Bind all variables
	# YYY: Can we detect unbindables??
	my $valsize = $#{$obj->{VALS}} + 1;
	carp "Wrong number of parameters to $constr matching"
	    if ($valsize != @_);

	foreach my $v (0..$valsize) {
	    if (ref $_[$v]) {
		${$_[$v]} = $obj->{VALS}->[$v];
	    } else {
		$_[$v] = $obj->{VALS}->[$v];
	    }
	}

	#  2) return true
	return 1;
    }

}

=item mkpat(CONS, [VARLIST]) 

This creates a reference to an array containing what would normally be
the input to match. This is mainly useful when working with C<switch>
statements.

=cut

sub mkpat {
    my @rv;
    
    croak "mkpat needs at least one argument"
	unless defined $_[0];
    
    push @rv, $_[0];
    
    foreach my $i (1..$#_) {
	push @rv,\$_[$i];
    }
    return \@rv;  
}


=item set_match(OBJ) 

=item $object->set_match

Presets an object to match against so that the first parameter of
C<match> can be left out in subsequent calls.

=cut

sub set_match {
    $matchObject = shift;
    warn "Parameter to set_match not a Data::Variant"
	unless ($matchObject->isa("Data::Variant"));
}


1;

__END__

=back

=head1 DETAILS

=head2 Typechecking

The typechecking is quite rudimentary. At runtime the type of the
value inserted is checked so that it corresponds to the type given in
the declaration. Currently using a bad type will make the library
C<croak>, complaining about the type.

In future versions the type checker might become a bit more versatile,
and optional.

=head2 Comparision with Haskell/ML

The data type C<Tree> given in L</SYNOPSIS> would look like this in 
Haskell:

    data Tree = Empty 
              | Leaf Int 
              | Node Tree Tree


In O'Caml you would write something like:

    type tree = Empty 
              | Leaf of int
              | Node of tree * tree

We have no static type safety like Haskell. This is more the Perl way
of doing it than the theoretical way.

=head1 SEE ALSO

Benjamin C. Pierce, Types and Programing Languages, chapter 11.10 for
a theoretical view of how typed lambda calculus can be extened with
variants (of little interest to most programmers but quite a nice book).

=head1 AUTHOR

Viktor Leijon <leijon@ludd.ltu.se>

package Class::PINT;

=head1 NAME

Class::PINT - A Class::DBI package providing Tangram and other OOPF features

=head1 DESCRIPTION

Class::PINT is an implementation of selected Tangram, and other OOPF
related features on top of Class::DBI.

The goal of PINT is to provide some of the power and flexibility of
Tangram with the maturity, transparency and extensibility of CDBI.
I also hope we can provide a place where more useful and adventurous
patchs, subclasses and plugins can be organised and integrated into
a usable package.

Class::PINT uses CDBI to generate general purpose accessors, mutators and
constructor methods. CDBI also provides simple relationships. Additional
Accessors/Mutators and relationships are added to handle more complex types
of attributes and relationships.

=head1 SYNOPSIS

Class

 package Address;

 use base qw(Class::PINT);

 __PACKAGE__->connection('dbi:mysql:database', 'username', 'password');

 __PACKAGE__->column_types(array => qw/StreetAddress/);

 __PACKAGE__->columns(All => qw/addressid StreetNumber StreetAddress Town City County/);

...

Application

 use Address;

 my $address = Address->create({StreetNumber => 108,
                                StreetAddress => ['Rose Court','Cross St'],
                                Town=>'Berkhamsted',
                                County=>'Hertfordshire'});

 my $county_string = $address->get_County; # read-only 'pure' accessor

 $address->set_City('Watford'); # write only mutator

 my $streetaddress_1 = $address->get_StreetAddress(0); # access array attribute

 my $attribute_foo = $object->get_Attribute('foo'); # element of hash attribute

=head1 METHODS

=head2 CLASS METHODS

=head2 search

Inherited from Class::DBI, doesn't support compound attributes. This method will be over-ridden to handle complex attributes and relationships later. Boolean Attributes should still work with this method.

see Class::DBI

=head2 search_like

Inherited from Class::DBI, doesn't support compound attributes. This method will be over-ridden to handle complex attributes and relationships later.

see Class::DBI

=head2 search_where

Inherited from Class::DBI::AbstractSearch, doesn't support compound attributes yet, but will be over-ridden to handle them later.

see Class::DBI::AbstractSearch

=head2 column_types

You need to specifiy the details of the connection and the names of the attributes
using the connection and columns methods respectively - see Class::DBI for more details
- before setting the column types

You can specify the type of attributes using column_types class method, which takes
the column type and the attributes of that type much like the CDBI columns method.

 __PACKAGE__->column_types(array => qw/StreetAddress/);

supported attribute types are :

=over

=item array

Array attributes are ordered lists that can be accessed in their entirety,
using normal accessors/mutators or individual elements or groups of elements.

=item hash

Hash attributes are keyed lists that can be accessed in their entirety,
using normal accessors/mutators or individual elements or groups of elements
using a key.

=item boolean

Boolean attributes are a single integer of 0 or 1. The attribute can then be set
or read using normal accessors/mutators or additional methods such as Attribute_is_False
or is_Attribute.

=back

=head2 column_rules

The column_rules method allows you to specify rules for attributes for validation, etc.
This also enables you to add behaviour for events called by triggers in the accessor
and mutators. You need to specify any column_types before specifying any column rules.

You can specify default behaviour by specifying the datatype of an attribute, such as an
integer. This method attempts to provide some of the benefits of Tangram style schema as
seen in Class::Tangram.

Specifying rules explicitly, and commenting them, make the objects behaviour much clearer
 while reducing the ammount of code written for sundry tasks.

 Address->column_rules( integer => [qw/count .. /] );

or

 Address->column_rules( integer => { count => { required => 1 }, .. );

You can also specify more detailed rules yourself :

 GeometricShape->column_rules( custom => {
                                           theta => {
                                                      check => $coderef,
                                                      required => 1,
                                                      ...
                                                     },
                                         }, .. );

Rules can be any of string, integer, float, reference, or object. Each with simple, and hopefully,
sensible default rules that can be over-ridden individually.

=over

=item string

The default validation for strings is to check that it is a scalar and not a reference to something.

=item integer

The default validation for an integer is that it is a string made up purely of digits, none of those
greek symbols or other beardy-wierdy, white socks and sandals nonsense. OK, you can have a + or - at
the start, but thats it.

=item float

A floating point number, thats some digits possibly with a decimal point in between them or at the start,
again you can start with a + or - but none of that scientific notation with a mantissa and all that malarky.

=item reference

A reference to something, it can even be a reference to another reference, just so long as its a reference,
you can specify the type of reference with reference_to - see below.

=item object

An object, which is essentially a blessed reference, you can specify that the object is of a particular type,
inherits from or implements a method - see below.

=back

All rules allow you to specify particular behavour for each attribute, these behaviours include validation,
defaults, requirements and triggered actions.

=over

=item check

Allows you to provide a sub or coderef that will be called to validate the value of this attribute. The sub
is passed the object and the new value for that attribute.

=item required

Allows you to specify if an attribute is a required value, it can be passed 1, 0 or a hashref specifying
whether to die or warn and the message to output to stderr.

=item default

Allows you to provide a default value for an attribute, this can be a value, sub or coderef that populates
the attribute. Subs are passed the object.

=item before_update

Allows you to provide a sub or coderef that is called before a value is updated, handy for tracking changes.

=item after_update

Allows you to provide a sub or coderef that is called after a value is updated, handy for something, surely.

=item object_can

When used in the object rule, allows you to require that an attribute is set to an object that implements
the method named

=item object_isa

When used in the object rule, allows you to require that an attribute is set to an object that inherits from
the class named

=item reference_to

When used in the reference or object rule, allows you to require that an attribute is a reference to something.

=back

NOTE: when applying rules to compound or complex attributes, the rules apply to each applicable part of the
attributes values.

=head2 CONSTRUCTORS

 my $object = Address->create({StreetNumber=>108,
                               StreetAddress=>['Rose Court','Cross St'],
                               Town=>'Berkhamsted',
                               County=>'Hertfordshire'});


=head2 ACCESSORS

This superclass attempts to make accessing and modifying object attributes as clear and predictable as possible.

my $county_string = $address->get_County; # read-only 'pure' accessor

my $first_line_of_streetaddress = $address->get_StreetAddress(0);

to get elements 0 to 8 of attribute Foo

$object->get_Foo(0..8);


=head2 MUTATORS

Class::PINT provides 2 forms of Mutator - get/set and write-only. get/set is
the default method named after the attribute such as :

$object->AttributeName($newvalue)

The write-only method is explictly named as set_AttributeName :

$object->set_AttributeName($newvalue)

You can also delete an attribute using

$object->delete($attribute_name) or $object->delete_AttributeName()

=head2 ADDITIONAL ATTRIBUTE METHODS

When you have specified an attributes type using column_types() there are additional
ways to access them.

=over

=item Array attribute methods

Array or Ordered List attributes support get,set and get/set accessor/mutators, as well as:
insert_AttributeName, delete_AttributeName, push_AttributeName, pop_AttributeName.
These attributes also have provide additional behaviour to the get/set and set methods.

see Class::PINT::DataTypes::Array (todo)

=item Hash attribute methods

Hash or Keyed List attributes support get,set and get/set accessor/mutators, as well as:
insert_AttributeName, delete_AttributeName, includes_AttributeName.

see Class::PINT::DataTypes::Hash (todo)

=item Boolean attribute methods

Boolean attributes support get,set and get/set accessor/mutators, as well as:
is_AttributeName, AttributeName_is_true, AttributeName_is_false, AttributeName_is_defined.

see Class::PINT::DataTypes::Boolean (todo)

=back

=cut

use strict;
our $VERSION = '0.01';

use base qw(Class::DBI Class::PINT::DataTypes Class::PINT::Relationships);

use Class::DBI::AbstractSearch;

use Data::Dumper;

__PACKAGE__->add_trigger(deflate_for_update => \&_deflate_complex_attributes);

####################################################################
# PINT public methods

# extra columns method to handle complex data types
sub column_types {
    no strict 'refs';
    my ($class,$group,@cols) = @_;
    if ( __PACKAGE__->_complex_types->{$group}) {
	@{__PACKAGE__->_complex_attributes()}{ map(lc($_),@cols) } = map( $group, @cols );
	# insert methods into class for each complex attribute
	foreach my $column (@cols) {
	    my $lc_column = lc $column;
	    # insert method for this action on this attribute into class
	    *{"$class\:\:$column"} = *{"$class\:\:$lc_column"} = sub {
		my $self = shift;
		$self->_flesh('All') unless $self->_attribute_exists($lc_column);
		return &${__PACKAGE__->_complex_types->{$group}{getset}}($self,$lc_column,@_);
	    };
	    foreach my $action (keys %{__PACKAGE__->_complex_types->{$group}}) {
		next if (lc($action) =~ /^(getset|read|write)$/);
		my $methodname = "${action}_$column";
		if ($action =~ /^Attribute_(.*)/) { $methodname = "${column}_$1"; }
		# insert method for this action on this attribute into class
		*{"$class\:\:".lc $methodname} = *{"$class\:\:$methodname"} = sub {
		    my $self = shift;
		    # flesh out attribute if it hasn't been populated yet
		    $self->_flesh('All') unless $self->_attribute_exists($lc_column);
		    # replace action with alias if present
		    unless (ref __PACKAGE__->_complex_types->{$group}{$action}) {
			$action = __PACKAGE__->_complex_types->{$group}{$action};
		    }
		    return &${__PACKAGE__->_complex_types->{$group}{$action}}($self,$lc_column,@_); 
		};

	    }
	}
    } else {
	die "$group is not a supported group\n"
    }
}


sub column_rules {
    
}

####################################################################
# over-ridden CDBI public methods

# over-rides inherited method from CDBI
sub normalize_column_values {
    my ($self, $column_values) = @_;
    while (my ($column, $value) = each %$column_values) {
        if (my $datatype = $self->_attribute_is_complex($column)) {
            # pre-process if complex type
            $column_values->{$column} = &{__PACKAGE__->_complex_types->{$datatype}{write}}($column,$value);
        }
    }
}

sub pure_accessor_name {
    my ($class, $column) = @_;
    return "get_$column";
}

sub mutator_name {
    my ($class, $column) = @_;
    return "set_$column";
}

####################################################################
# private methods

sub _deflate_complex_attributes {
    my $self = shift;
    foreach my $column ($self->is_changed) {
	warn "$column is changed\n";
	# pre-process each complex attribute
	if (my $datatype = $self->_attribute_is_complex($column)) {
	    $self->{$column} = &{__PACKAGE__->_complex_types->{$datatype}{write}}($column,$self->{$column});
	}
    }
}

sub _attribute_is_complex {
    my ($self,$column) = @_;
    my $is_complex = __PACKAGE__->_complex_attributes->{$column} || 0;
    return $is_complex;
}

####################################################################
# over-ridden CDBI private methods

# now copes with complex datatypes
sub _flesh {
#    warn "_flesh called \n";
	my ($self, @groups) = @_;
	my @real = grep $_ ne "TEMP", @groups;
	if (my @want = grep (!$self->_attribute_exists($_) && (lc($_) ne 'all'), $self->__grouper->columns_in(@real))) {
	    my %row;
	    @row{@want} = $self->sql_Flesh(join ", ", @want)->select_row($self->id);
	    foreach my $col (@want) {
		my $datatype = __PACKAGE__->_complex_attributes->{$col};
		next unless ($datatype);
		warn "getting value for column $col using read\n";
		warn '__PACKAGE__->_complex_types->{$datatype}{read} : ', __PACKAGE__->_complex_types->{$datatype}{read}, "\n";
		$row{$col} = &{__PACKAGE__->_complex_types->{$datatype}{read}}($col,$row{$col});
	    }
	    $self->_attribute_store(\%row);
	    $self->call_trigger('select');
	}
	return 1;
}

# now provides Tangram style rw, ro and wo accessors for any attribute
sub _mk_column_accessors {
    my $class = shift;
    foreach my $obj ($class->_find_columns(@_)) {
	my %method = (
		      rw => $obj->accessor($class->accessor_name($obj->name)),
		      ro => $obj->accessor($class->pure_accessor_name($obj->name)),
		      wo => $obj->mutator($class->mutator_name($obj->name)),
		     );
	foreach my $type (keys %method) {
	    my $name     = $method{$type};
	    my $acc_type = ($type eq 'rw') ? "make_accessor" : "make_${type}_accessor";
	    my $accessor = $class->$acc_type($obj->name_lc);
	    $class->_make_method($_, $accessor) for ($name, "_${name}_accessor");
	}
    }
}


################################################################################

=head1 SEE ALSO

L<perl>

Class::DBI

Tangram

Class::Tangram

Class::PINT::DataTypes

=head1 AUTHOR

Aaron J. Trevena, E<lt>aaron@droogs.orgE<gt>

=head1 COPYRIGHT

Licensed for use, modification and distribution under the Artistic
and GNU GPL licenses.

Copyright (C) 2004 by Aaron J Trevena <aaron@droogs.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut


################################################################################
################################################################################

1;

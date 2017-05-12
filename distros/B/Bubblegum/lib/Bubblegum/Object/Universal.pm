# ABSTRACT: Common Methods for Operating on Defined Values
package Bubblegum::Object::Universal;

use 5.10.0;
use namespace::autoclean;

use Bubblegum::Namespace;

use Scalar::Util ();
use Types::Standard ();

use Class::Load 'load_class';

our @ISA = (); # non-object
my  $TYPES = $Bubblegum::Namespace::ExtendedTypes;

our $VERSION = '0.45'; # VERSION

sub digest {
    my $self = CORE::shift;
    return wrapper($self, 'Digest');
}

sub dump {
    my $self = CORE::shift;
    return dumper($self)->encode;
}

sub dumper {
    my $self = CORE::shift;
    return wrapper($self, 'Dumper');
}

sub encoder {
    my $self = CORE::shift;
    return wrapper($self, 'Encoder');
}

sub instance {
    my $self  = CORE::shift;
    my $class = $$TYPES{'INSTANCE'};
    return load_class($class)->new(
        data => $self
    );
}

sub json {
    my $self = CORE::shift;
    return wrapper($self, 'Json');
}

sub refaddr {
    return Scalar::Util::refaddr(
        CORE::shift
    );
}

sub reftype {
    return Scalar::Util::reftype(
        CORE::shift
    );
}

sub wrapper {
    my $self  = CORE::shift;
    my $class = CORE::shift;
    my $wrapper = $$TYPES{'WRAPPER'};
    return load_class(join('::', $wrapper, $class))->new(
        data => $self
    );
}

sub yaml {
    my $self = CORE::shift;
    return wrapper($self, 'Yaml');
}

{
    no warnings 'once';
    *asa_aref       = \&Types::Standard::assert_ArrayRef;
    *asa_arrayref   = \&Types::Standard::assert_ArrayRef;
    *asa_bool       = \&Types::Standard::assert_Bool;
    *asa_boolean    = \&Types::Standard::assert_Bool;
    *asa_class      = \&Types::Standard::assert_ClassName;
    *asa_classname  = \&Types::Standard::assert_ClassName;
    *asa_coderef    = \&Types::Standard::assert_CodeRef;
    *asa_cref       = \&Types::Standard::assert_CodeRef;
    *asa_def        = \&Types::Standard::assert_Defined;
    *asa_defined    = \&Types::Standard::assert_Defined;
    *asa_fh         = \&Types::Standard::assert_FileHandle;
    *asa_filehandle = \&Types::Standard::assert_FileHandle;
    *asa_glob       = \&Types::Standard::assert_GlobRef;
    *asa_globref    = \&Types::Standard::assert_GlobRef;
    *asa_hashref    = \&Types::Standard::assert_HashRef;
    *asa_href       = \&Types::Standard::assert_HashRef;
    *asa_int        = \&Types::Standard::assert_Int;
    *asa_integer    = \&Types::Standard::assert_Int;
    *asa_nil        = \&Types::Standard::assert_Undef;
    *asa_null       = \&Types::Standard::assert_Undef;
    *asa_num        = \&Types::Standard::assert_Num;
    *asa_number     = \&Types::Standard::assert_Num;
    *asa_obj        = \&Types::Standard::assert_Object;
    *asa_object     = \&Types::Standard::assert_Object;
    *asa_ref        = \&Types::Standard::assert_Ref;
    *asa_reference  = \&Types::Standard::assert_Ref;
    *asa_regexpref  = \&Types::Standard::assert_RegexpRef;
    *asa_rref       = \&Types::Standard::assert_RegexpRef;
    *asa_scalarref  = \&Types::Standard::assert_ScalarRef;
    *asa_sref       = \&Types::Standard::assert_ScalarRef;
    *asa_str        = \&Types::Standard::assert_Str;
    *asa_string     = \&Types::Standard::assert_Str;
    *asa_undef      = \&Types::Standard::assert_Undef;
    *asa_undefined  = \&Types::Standard::assert_Undef;
    *asa_val        = \&Types::Standard::assert_Value;
    *asa_value      = \&Types::Standard::assert_Value;
    *isa_aref       = \&Types::Standard::is_ArrayRef;
    *isa_arrayref   = \&Types::Standard::is_ArrayRef;
    *isa_bool       = \&Types::Standard::is_Bool;
    *isa_boolean    = \&Types::Standard::is_Bool;
    *isa_class      = \&Types::Standard::is_ClassName;
    *isa_classname  = \&Types::Standard::is_ClassName;
    *isa_coderef    = \&Types::Standard::is_CodeRef;
    *isa_cref       = \&Types::Standard::is_CodeRef;
    *isa_def        = \&Types::Standard::is_Defined;
    *isa_defined    = \&Types::Standard::is_Defined;
    *isa_fh         = \&Types::Standard::is_FileHandle;
    *isa_filehandle = \&Types::Standard::is_FileHandle;
    *isa_glob       = \&Types::Standard::is_GlobRef;
    *isa_globref    = \&Types::Standard::is_GlobRef;
    *isa_hashref    = \&Types::Standard::is_HashRef;
    *isa_href       = \&Types::Standard::is_HashRef;
    *isa_int        = \&Types::Standard::is_Int;
    *isa_integer    = \&Types::Standard::is_Int;
    *isa_nil        = \&Types::Standard::is_Undef;
    *isa_null       = \&Types::Standard::is_Undef;
    *isa_num        = \&Types::Standard::is_Num;
    *isa_number     = \&Types::Standard::is_Num;
    *isa_obj        = \&Types::Standard::is_Object;
    *isa_object     = \&Types::Standard::is_Object;
    *isa_ref        = \&Types::Standard::is_Ref;
    *isa_reference  = \&Types::Standard::is_Ref;
    *isa_regexpref  = \&Types::Standard::is_RegexpRef;
    *isa_rref       = \&Types::Standard::is_RegexpRef;
    *isa_scalarref  = \&Types::Standard::is_ScalarRef;
    *isa_sref       = \&Types::Standard::is_ScalarRef;
    *isa_str        = \&Types::Standard::is_Str;
    *isa_string     = \&Types::Standard::is_Str;
    *isa_undef      = \&Types::Standard::is_Undef;
    *isa_undefined  = \&Types::Standard::is_Undef;
    *isa_val        = \&Types::Standard::is_Value;
    *isa_value      = \&Types::Standard::is_Value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bubblegum::Object::Universal - Common Methods for Operating on Defined Values

=head1 VERSION

version 0.45

=head1 SYNOPSIS

    use Bubblegum;

    my $thing = 0;
    $thing->instance; # bless({'data' => 0}, 'Bubblegum::Object::Instance')

=head1 DESCRIPTION

Universal methods work on variables whose data meets the criteria for being
defined. It is not necessary to use this module as it is loaded automatically by
the L<Bubblegum> class.

=head1 METHODS

=head2 digest

    my $thing = '...';
    $thing->digest; # bless({'data' => '...'}, 'Bubblegum::Wrapper::Digest')

    my $data = $thing->digest->data;

The digest method blesses the subject into the wrapper class,
L<Bubblegum::Wrapper::Digest>, and returns an instance. Please see
L<Bubblegum::Wrapper::Digest> for more information.

=head2 dumper

    my $thing = '...';
    $thing->dumper; # bless({'data' => '...'}, 'Bubblegum::Wrapper::Dumper')

    my $data = $thing->dumper->data;

The dumper method blesses the subject into the wrapper class,
L<Bubblegum::Wrapper::Dumper>, and returns an instance. Please see
L<Bubblegum::Wrapper::Dumper> for more information.

=head2 encoder

    my $thing = '...';
    $thing->encoder; # bless({'data' => '...'}, 'Bubblegum::Wrapper::Encoder')

    my $data = $thing->encoder->data;

The encoder method blesses the subject into the wrapper class,
L<Bubblegum::Wrapper::Encoder>, and returns an instance. Please see
L<Bubblegum::Wrapper::Encoder> for more information.

=head2 instance

    my $thing = 0;
    $thing->instance; # bless({'data' => 0}, 'Bubblegum::Object::Instance')

    my $data = $thing->instance->data;

The instance method blesses the subject into a generic container class,
Bubblegum::Object::Instance, and returns an instance. Please see
L<Bubblegum::Object::Instance> for more information.

=head2 json

    my $thing = '...';
    $thing->json; # bless({'data' => '...'}, 'Bubblegum::Wrapper::Json')

    my $data = $thing->json->data;

The json method blesses the subject into the wrapper class,
L<Bubblegum::Wrapper::Json>, and returns an instance. Please see
L<Bubblegum::Wrapper::Json> for more information.

=head2 wrapper

    my $thing = [1,0];
    $thing->wrapper('json');
    $thing->json; # bless({'data' => [1,0]}, 'Bubblegum::Wrapper::Json')

    my $json = $thing->json->encode;

The wrapper method blesses the subject into a Bubblegum wrapper, a container
class, which exists as an extension to the core data type methods, and returns
an instance. Please see any one of the core Bubblegum wrappers, e.g.,
L<Bubblegum::Wrapper::Digest>, L<Bubblegum::Wrapper::Dumper>,
L<Bubblegum::Wrapper::Encoder>, L<Bubblegum::Wrapper::Json> or
L<Bubblegum::Wrapper::Yaml>.

=head2 yaml

    my $thing = '...';
    $thing->yaml; # bless({'data' => '...'}, 'Bubblegum::Wrapper::Yaml')

    my $data = $thing->yaml->data;

The yaml method blesses the subject into the wrapper class,
L<Bubblegum::Wrapper::Yaml>, and returns an instance. Please see
L<Bubblegum::Wrapper::Yaml> for more information.

=head1 ASSERTIONS

All data type objects have access to type assertions methods which can be call
on to help ensure data integrity and prevent invalid usage patterns. The
following is a list of standard type assertion methods whose routines map to
those corresponding in the L<Types::Standard> library.

=head2 asa_aref

    my $thing = undef;
    $thing->asa_aref;

The aref method asserts that the caller is an array reference. If the caller is
not an array reference, the program will die.

=head2 asa_arrayref

    my $thing = undef;
    $thing->asa_arrayref;

The arrayref method asserts that the caller is an array reference. If the caller
is not an array reference, the program will die.

=head2 asa_bool

    my $thing = undef;
    $thing->asa_bool;

The bool method asserts that the caller is a boolean value. If the caller is not
a boolean value, the program will die.

=head2 asa_boolean

    my $thing = undef;
    $thing->asa_boolean;

The boolean method asserts that the caller is a boolean value. If the caller is
not a boolean value, the program will die.

=head2 asa_class

    my $thing = undef;
    $thing->asa_class;

The class method asserts that the caller is a class name. If the caller is not a
class name, the program will die.

=head2 asa_classname

    my $thing = undef;
    $thing->asa_classname;

The classname method asserts that the caller is a class name. If the caller is
not a class name, the program will die.

=head2 asa_coderef

    my $thing = undef;
    $thing->asa_coderef;

The coderef method asserts that the caller is a code reference. If the caller is
not a code reference, the program will die.

=head2 asa_cref

    my $thing = undef;
    $thing->asa_cref;

The cref method asserts that the caller is a code reference. If the caller is
not a code reference, the program will die.

=head2 asa_def

    my $thing = undef;
    $thing->asa_def;

The def method asserts that the caller is a defined value. If the caller is not
a defined value, the program will die.

=head2 asa_defined

    my $thing = undef;
    $thing->asa_defined;

The defined method asserts that the caller is a defined value. If the caller is
not a defined value, the program will die.

=head2 asa_fh

    my $thing = undef;
    $thing->asa_fh;

The fh method asserts that the caller is a file handle. If the caller is not a
file handle, the program will die.

=head2 asa_filehandle

    my $thing = undef;
    $thing->asa_filehandle;

The filehandle method asserts that the caller is a file handle. If the caller is
not a file handle, the program will die.

=head2 asa_glob

    my $thing = undef;
    $thing->asa_glob;

The glob method asserts that the caller is a glob reference. If the caller is
not a glob reference, the program will die.

=head2 asa_globref

    my $thing = undef;
    $thing->asa_globref;

The globref method asserts that the caller is a glob reference. If the caller is
not a glob reference, the program will die.

=head2 asa_hashref

    my $thing = undef;
    $thing->asa_hashref;

The hashref method asserts that the caller is a hash reference. If the caller is
not a hash reference, the program will die.

=head2 asa_href

    my $thing = undef;
    $thing->asa_href;

The href method asserts that the caller is a hash reference. If the caller is
not a hash reference, the program will die.

=head2 asa_int

    my $thing = undef;
    $thing->asa_int;

The int method asserts that the caller is an integer. If the caller is not an
integer, the program will die.

=head2 asa_integer

    my $thing = undef;
    $thing->asa_integer;

The integer method asserts that the caller is an integer. If the caller is not
an integer, the program will die.

=head2 asa_num

    my $thing = undef;
    $thing->asa_num;

The num method asserts that the caller is a number. If the caller is not a
number, the program will die.

=head2 asa_number

    my $thing = undef;
    $thing->asa_number;

The number method asserts that the caller is a number. If the caller is not a
number, the program will die.

=head2 asa_obj

    my $thing = undef;
    $thing->asa_obj;

The obj method asserts that the caller is an object. If the caller is not an
object, the program will die.

=head2 asa_object

    my $thing = undef;
    $thing->asa_object;

The object method asserts that the caller is an object. If the caller is not an
object, the program will die.

=head2 asa_ref

    my $thing = undef;
    $thing->asa_ref;

The ref method asserts that the caller is a reference. If the caller is not a
reference, the program will die.

=head2 asa_reference

    my $thing = undef;
    $thing->asa_reference;

The reference method asserts that the caller is a reference. If the caller is
not a reference, the program will die.

=head2 asa_regexpref

    my $thing = undef;
    $thing->asa_regexpref;

The regexpref method asserts that the caller is a regular expression reference.
If the caller is not a regular expression reference, the program will die.

=head2 asa_rref

    my $thing = undef;
    $thing->asa_rref;

The rref method asserts that the caller is a regular expression reference. If
the caller is not a regular expression reference, the program will die.

=head2 asa_scalarref

    my $thing = undef;
    $thing->asa_scalarref;

The scalarref method asserts that the caller is a scalar reference. If the
caller is not a scalar reference, the program will die.

=head2 asa_sref

    my $thing = undef;
    $thing->asa_sref;

The sref method asserts that the caller is a scalar reference. If the caller is
not a scalar reference, the program will die.

=head2 asa_str

    my $thing = undef;
    $thing->asa_str;

The str method asserts that the caller is a string. If the caller is not a
string, the program will die.

=head2 asa_string

    my $thing = undef;
    $thing->asa_string;

The string method asserts that the caller is a string. If the caller is not a
string, the program will die.

=head2 asa_nil

    my $thing = undef;
    $thing->asa_nil;

The nil method asserts that the caller is an undefined value. If the caller is
not an undefined value, the program will die.

=head2 asa_null

    my $thing = undef;
    $thing->asa_null;

The null method asserts that the caller is an undefined value. If the caller is
not an undefined value, the program will die.

=head2 asa_undef

    my $thing = undef;
    $thing->asa_undef;

The undef method asserts that the caller is an undefined value. If the caller is
not an undefined value, the program will die.

=head2 asa_undefined

    my $thing = undef;
    $thing->asa_undefined;

The undefined method asserts that the caller is an undefined value. If the
caller is not an undefined value, the program will die.

=head2 asa_val

    my $thing = undef;
    $thing->asa_val;

The val method asserts that the caller is a value. If the caller is not a value,
the program will die.

=head2 asa_value

    my $thing = undef;
    $thing->asa_value;

The value method asserts that the caller is a value. If the caller is not a
value, the program will die.

=head1 VALIDATIONS

All data type objects have access to type checking methods which can be call on
to help control the flow of operations. The following is a list of standard type
checking methods whose routines map to those corresponding in the
L<Types::Standard> library.

=head2 isa_aref

    my $thing = undef;
    $thing->isa_aref;

The aref method checks that the caller is an array reference. If the caller is
not an array reference, the method will return false.

=head2 isa_arrayref

    my $thing = undef;
    $thing->isa_arrayref;

The arrayref method checks that the caller is an array reference. If the caller
is not an array reference, the method will return false.

=head2 isa_bool

    my $thing = undef;
    $thing->isa_bool;

The bool method checks that the caller is a boolean value. If the caller is not
a boolean value, the method will return false.

=head2 isa_boolean

    my $thing = undef;
    $thing->isa_boolean;

The boolean method checks that the caller is a boolean value. If the caller is
not a boolean value, the method will return false.

=head2 isa_class

    my $thing = undef;
    $thing->isa_class;

The class method checks that the caller is a class name. If the caller is not a
class name, the method will return false.

=head2 isa_classname

    my $thing = undef;
    $thing->isa_classname;

The classname method checks that the caller is a class name. If the caller is
not a class name, the method will return false.

=head2 isa_coderef

    my $thing = undef;
    $thing->isa_coderef;

The coderef method checks that the caller is a code reference. If the caller is
not a code reference, the method will return false.

=head2 isa_cref

    my $thing = undef;
    $thing->isa_cref;

The cref method checks that the caller is a code reference. If the caller is not
a code reference, the method will return false.

=head2 isa_def

    my $thing = undef;
    $thing->isa_def;

The def method checks that the caller is a defined value. If the caller is not a
defined value, the method will return false.

=head2 isa_defined

    my $thing = undef;
    $thing->isa_defined;

The defined method checks that the caller is a defined value. If the caller is
not a defined value, the method will return false.

=head2 isa_fh

    my $thing = undef;
    $thing->isa_fh;

The fh method checks that the caller is a file handle. If the caller is not a
file handle, the method will return false.

=head2 isa_filehandle

    my $thing = undef;
    $thing->isa_filehandle;

The filehandle method checks that the caller is a file handle. If the caller is
not a file handle, the method will return false.

=head2 isa_glob

    my $thing = undef;
    $thing->isa_glob;

The glob method checks that the caller is a glob reference. If the caller is not
a glob reference, the method will return false.

=head2 isa_globref

    my $thing = undef;
    $thing->isa_globref;

The globref method checks that the caller is a glob reference. If the caller is
not a glob reference, the method will return false.

=head2 isa_hashref

    my $thing = undef;
    $thing->isa_hashref;

The hashref method checks that the caller is a hash reference. If the caller is
not a hash reference, the method will return false.

=head2 isa_href

    my $thing = undef;
    $thing->isa_href;

The href method checks that the caller is a hash reference. If the caller is not
a hash reference, the method will return false.

=head2 isa_int

    my $thing = undef;
    $thing->isa_int;

The int method checks that the caller is an integer. If the caller is not an
integer, the method will return false.

=head2 isa_integer

    my $thing = undef;
    $thing->isa_integer;

The integer method checks that the caller is an integer. If the caller is not an
integer, the method will return false.

=head2 isa_num

    my $thing = undef;
    $thing->isa_num;

The num method checks that the caller is a number. If the caller is not a
number, the method will return false.

=head2 isa_number

    my $thing = undef;
    $thing->isa_number;

The number method checks that the caller is a number. If the caller is not a
number, the method will return false.

=head2 isa_obj

    my $thing = undef;
    $thing->isa_obj;

The obj method checks that the caller is an object. If the caller is not an
object, the method will return false.

=head2 isa_object

    my $thing = undef;
    $thing->isa_object;

The object method checks that the caller is an object. If the caller is not an
object, the method will return false.

=head2 isa_ref

    my $thing = undef;
    $thing->isa_ref;

The ref method checks that the caller is a reference. If the caller is not a
reference, the method will return false.

=head2 isa_reference

    my $thing = undef;
    $thing->isa_reference;

The reference method checks that the caller is a reference. If the caller is not
a reference, the method will return false.

=head2 isa_regexpref

    my $thing = undef;
    $thing->isa_regexpref;

The regexpref method checks that the caller is a regular expression reference.
If the caller is not a regular expression reference, the method will return
false.

=head2 isa_rref

    my $thing = undef;
    $thing->isa_rref;

The rref method checks that the caller is a regular expression reference. If the
caller is not a regular expression reference, the method will return false.

=head2 isa_scalarref

    my $thing = undef;
    $thing->isa_scalarref;

The scalarref method checks that the caller is a scalar reference. If the caller
is not a scalar reference, the method will return false.

=head2 isa_sref

    my $thing = undef;
    $thing->isa_sref;

The sref method checks that the caller is a scalar reference. If the caller is
not a scalar reference, the method will return false.

=head2 isa_str

    my $thing = undef;
    $thing->isa_str;

The str method checks that the caller is a string. If the caller is not a
string, the method will return false.

=head2 isa_string

    my $thing = undef;
    $thing->isa_string;

The string method checks that the caller is a string. If the caller is not a
string, the method will return false.

=head2 isa_nil

    my $thing = undef;
    $thing->isa_nil;

The nil method checks that the caller is an undefined value. If the caller is
not an undefined value, the method will return false.

=head2 isa_null

    my $thing = undef;
    $thing->isa_null;

The null method checks that the caller is an undefined value. If the caller is
not an undefined value, the method will return false.

=head2 isa_undef

    my $thing = undef;
    $thing->isa_undef;

The undef method checks that the caller is an undefined value. If the caller is
not an undefined value, the method will return false.

=head2 isa_undefined

    my $thing = undef;
    $thing->isa_undefined;

The undefined method checks that the caller is an undefined value. If the caller
is not an undefined value, the method will return false.

=head2 isa_val

    my $thing = undef;
    $thing->isa_val;

The val method checks that the caller is a value. If the caller is not a value,
the method will return false.

=head2 isa_value

    my $thing = undef;
    $thing->isa_value;

The value method checks that the caller is a value. If the caller is not a
value, the method will return false.

=head1 SEE ALSO

=over 4

=item *

L<Bubblegum::Object::Array>

=item *

L<Bubblegum::Object::Code>

=item *

L<Bubblegum::Object::Hash>

=item *

L<Bubblegum::Object::Instance>

=item *

L<Bubblegum::Object::Integer>

=item *

L<Bubblegum::Object::Number>

=item *

L<Bubblegum::Object::Scalar>

=item *

L<Bubblegum::Object::String>

=item *

L<Bubblegum::Object::Undef>

=item *

L<Bubblegum::Object::Universal>

=back

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

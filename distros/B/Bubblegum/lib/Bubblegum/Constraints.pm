# ABSTRACT: Type and Constraints Library for Bubblegum
package Bubblegum::Constraints;

use 5.10.0;

use strict;
use utf8::all;
use warnings;

use Types::Standard ();

use base 'Exporter::Tiny';

our $VERSION = '0.45'; # VERSION

our @EXPORT_OK;
our %EXPORT_TAGS;

my $arrayref   = Types::Standard->get_type('ArrayRef');
my $boolean    = Types::Standard->get_type('Bool');
my $classname  = Types::Standard->get_type('ClassName');
my $coderef    = Types::Standard->get_type('CodeRef');
my $defined    = Types::Standard->get_type('Defined');
my $filehandle = Types::Standard->get_type('FileHandle');
my $globref    = Types::Standard->get_type('GlobRef');
my $hashref    = Types::Standard->get_type('HashRef');
my $integer    = Types::Standard->get_type('Int');
my $number     = Types::Standard->get_type('Num');
my $object     = Types::Standard->get_type('Object');
my $reference  = Types::Standard->get_type('Ref');
my $regexpref  = Types::Standard->get_type('RegexpRef');
my $scalarref  = Types::Standard->get_type('ScalarRef');
my $string     = Types::Standard->get_type('Str');
my $undefined  = Types::Standard->get_type('Undef');
my $value      = Types::Standard->get_type('Value');

no warnings 'once';

# EXPORT: ISAS

push @EXPORT_OK, 'isa_aref';
push @{$EXPORT_TAGS{isas}}, 'isa_aref';
*isa_aref = $arrayref->compiled_check;

push @EXPORT_OK, 'isa_arrayref';
push @{$EXPORT_TAGS{isas}}, 'isa_arrayref';
*isa_arrayref = $arrayref->compiled_check;

push @EXPORT_OK, 'isa_bool';
push @{$EXPORT_TAGS{isas}}, 'isa_bool';
*isa_bool = $boolean->compiled_check;

push @EXPORT_OK, 'isa_boolean';
push @{$EXPORT_TAGS{isas}}, 'isa_boolean';
*isa_boolean = $boolean->compiled_check;

push @EXPORT_OK, 'isa_class';
push @{$EXPORT_TAGS{isas}}, 'isa_class';
*isa_class = $classname->compiled_check;

push @EXPORT_OK, 'isa_classname';
push @{$EXPORT_TAGS{isas}}, 'isa_classname';
*isa_classname = $classname->compiled_check;

push @EXPORT_OK, 'isa_coderef';
push @{$EXPORT_TAGS{isas}}, 'isa_coderef';
*isa_coderef = $coderef->compiled_check;

push @EXPORT_OK, 'isa_cref';
push @{$EXPORT_TAGS{isas}}, 'isa_cref';
*isa_cref = $coderef->compiled_check;

push @EXPORT_OK, 'isa_def';
push @{$EXPORT_TAGS{isas}}, 'isa_def';
*isa_def = $defined->compiled_check;

push @EXPORT_OK, 'isa_defined';
push @{$EXPORT_TAGS{isas}}, 'isa_defined';
*isa_defined = $defined->compiled_check;

push @EXPORT_OK, 'isa_fh';
push @{$EXPORT_TAGS{isas}}, 'isa_fh';
*isa_fh = $filehandle->compiled_check;

push @EXPORT_OK, 'isa_filehandle';
push @{$EXPORT_TAGS{isas}}, 'isa_filehandle';
*isa_filehandle = $filehandle->compiled_check;

push @EXPORT_OK, 'isa_glob';
push @{$EXPORT_TAGS{isas}}, 'isa_glob';
*isa_glob = $globref->compiled_check;

push @EXPORT_OK, 'isa_globref';
push @{$EXPORT_TAGS{isas}}, 'isa_globref';
*isa_globref = $globref->compiled_check;

push @EXPORT_OK, 'isa_hashref';
push @{$EXPORT_TAGS{isas}}, 'isa_hashref';
*isa_hashref = $hashref->compiled_check;

push @EXPORT_OK, 'isa_href';
push @{$EXPORT_TAGS{isas}}, 'isa_href';
*isa_href = $hashref->compiled_check;

push @EXPORT_OK, 'isa_int';
push @{$EXPORT_TAGS{isas}}, 'isa_int';
*isa_int = $integer->compiled_check;

push @EXPORT_OK, 'isa_integer';
push @{$EXPORT_TAGS{isas}}, 'isa_integer';
*isa_integer = $integer->compiled_check;

push @EXPORT_OK, 'isa_num';
push @{$EXPORT_TAGS{isas}}, 'isa_num';
*isa_num = $number->compiled_check;

push @EXPORT_OK, 'isa_number';
push @{$EXPORT_TAGS{isas}}, 'isa_number';
*isa_number = $number->compiled_check;

push @EXPORT_OK, 'isa_obj';
push @{$EXPORT_TAGS{isas}}, 'isa_obj';
*isa_obj = $object->compiled_check;

push @EXPORT_OK, 'isa_object';
push @{$EXPORT_TAGS{isas}}, 'isa_object';
*isa_object = $object->compiled_check;

push @EXPORT_OK, 'isa_ref';
push @{$EXPORT_TAGS{isas}}, 'isa_ref';
*isa_ref = $reference->compiled_check;

push @EXPORT_OK, 'isa_reference';
push @{$EXPORT_TAGS{isas}}, 'isa_reference';
*isa_reference = $reference->compiled_check;

push @EXPORT_OK, 'isa_regexpref';
push @{$EXPORT_TAGS{isas}}, 'isa_regexpref';
*isa_regexpref = $regexpref->compiled_check;

push @EXPORT_OK, 'isa_rref';
push @{$EXPORT_TAGS{isas}}, 'isa_rref';
*isa_rref = $regexpref->compiled_check;

push @EXPORT_OK, 'isa_scalarref';
push @{$EXPORT_TAGS{isas}}, 'isa_scalarref';
*isa_scalarref = $scalarref->compiled_check;

push @EXPORT_OK, 'isa_sref';
push @{$EXPORT_TAGS{isas}}, 'isa_sref';
*isa_sref = $scalarref->compiled_check;

push @EXPORT_OK, 'isa_str';
push @{$EXPORT_TAGS{isas}}, 'isa_str';
*isa_str = $string->compiled_check;

push @EXPORT_OK, 'isa_string';
push @{$EXPORT_TAGS{isas}}, 'isa_string';
*isa_string = $string->compiled_check;

push @EXPORT_OK, 'isa_nil';
push @{$EXPORT_TAGS{isas}}, 'isa_nil';
*isa_nil = $undefined->compiled_check;

push @EXPORT_OK, 'isa_null';
push @{$EXPORT_TAGS{isas}}, 'isa_null';
*isa_null = $undefined->compiled_check;

push @EXPORT_OK, 'isa_undef';
push @{$EXPORT_TAGS{isas}}, 'isa_undef';
*isa_undef = $undefined->compiled_check;

push @EXPORT_OK, 'isa_undefined';
push @{$EXPORT_TAGS{isas}}, 'isa_undefined';
*isa_undefined = $undefined->compiled_check;

push @EXPORT_OK, 'isa_val';
push @{$EXPORT_TAGS{isas}}, 'isa_val';
*isa_val = $value->compiled_check;

push @EXPORT_OK, 'isa_value';
push @{$EXPORT_TAGS{isas}}, 'isa_value';
*isa_value = $value->compiled_check;

# EXPORT: NOTS

push @EXPORT_OK, 'not_aref';
push @{$EXPORT_TAGS{nots}}, 'not_aref';
*not_aref = $arrayref->complementary_type->compiled_check;

push @EXPORT_OK, 'not_arrayref';
push @{$EXPORT_TAGS{nots}}, 'not_arrayref';
*not_arrayref = $arrayref->complementary_type->compiled_check;

push @EXPORT_OK, 'not_bool';
push @{$EXPORT_TAGS{nots}}, 'not_bool';
*not_bool = $boolean->complementary_type->compiled_check;

push @EXPORT_OK, 'not_boolean';
push @{$EXPORT_TAGS{nots}}, 'not_boolean';
*not_boolean = $boolean->complementary_type->compiled_check;

push @EXPORT_OK, 'not_class';
push @{$EXPORT_TAGS{nots}}, 'not_class';
*not_class = $classname->complementary_type->compiled_check;

push @EXPORT_OK, 'not_classname';
push @{$EXPORT_TAGS{nots}}, 'not_classname';
*not_classname = $classname->complementary_type->compiled_check;

push @EXPORT_OK, 'not_coderef';
push @{$EXPORT_TAGS{nots}}, 'not_coderef';
*not_coderef = $coderef->complementary_type->compiled_check;

push @EXPORT_OK, 'not_cref';
push @{$EXPORT_TAGS{nots}}, 'not_cref';
*not_cref = $coderef->complementary_type->compiled_check;

push @EXPORT_OK, 'not_def';
push @{$EXPORT_TAGS{nots}}, 'not_def';
*not_def = $defined->complementary_type->compiled_check;

push @EXPORT_OK, 'not_defined';
push @{$EXPORT_TAGS{nots}}, 'not_defined';
*not_defined = $defined->complementary_type->compiled_check;

push @EXPORT_OK, 'not_fh';
push @{$EXPORT_TAGS{nots}}, 'not_fh';
*not_fh = $filehandle->complementary_type->compiled_check;

push @EXPORT_OK, 'not_filehandle';
push @{$EXPORT_TAGS{nots}}, 'not_filehandle';
*not_filehandle = $filehandle->complementary_type->compiled_check;

push @EXPORT_OK, 'not_glob';
push @{$EXPORT_TAGS{nots}}, 'not_glob';
*not_glob = $globref->complementary_type->compiled_check;

push @EXPORT_OK, 'not_globref';
push @{$EXPORT_TAGS{nots}}, 'not_globref';
*not_globref = $globref->complementary_type->compiled_check;

push @EXPORT_OK, 'not_hashref';
push @{$EXPORT_TAGS{nots}}, 'not_hashref';
*not_hashref = $hashref->complementary_type->compiled_check;

push @EXPORT_OK, 'not_href';
push @{$EXPORT_TAGS{nots}}, 'not_href';
*not_href = $hashref->complementary_type->compiled_check;

push @EXPORT_OK, 'not_int';
push @{$EXPORT_TAGS{nots}}, 'not_int';
*not_int = $integer->complementary_type->compiled_check;

push @EXPORT_OK, 'not_integer';
push @{$EXPORT_TAGS{nots}}, 'not_integer';
*not_integer = $integer->complementary_type->compiled_check;

push @EXPORT_OK, 'not_num';
push @{$EXPORT_TAGS{nots}}, 'not_num';
*not_num = $number->complementary_type->compiled_check;

push @EXPORT_OK, 'not_number';
push @{$EXPORT_TAGS{nots}}, 'not_number';
*not_number = $number->complementary_type->compiled_check;

push @EXPORT_OK, 'not_obj';
push @{$EXPORT_TAGS{nots}}, 'not_obj';
*not_obj = $object->complementary_type->compiled_check;

push @EXPORT_OK, 'not_object';
push @{$EXPORT_TAGS{nots}}, 'not_object';
*not_object = $object->complementary_type->compiled_check;

push @EXPORT_OK, 'not_ref';
push @{$EXPORT_TAGS{nots}}, 'not_ref';
*not_ref = $reference->complementary_type->compiled_check;

push @EXPORT_OK, 'not_reference';
push @{$EXPORT_TAGS{nots}}, 'not_reference';
*not_reference = $reference->complementary_type->compiled_check;

push @EXPORT_OK, 'not_regexpref';
push @{$EXPORT_TAGS{nots}}, 'not_regexpref';
*not_regexpref = $regexpref->complementary_type->compiled_check;

push @EXPORT_OK, 'not_rref';
push @{$EXPORT_TAGS{nots}}, 'not_rref';
*not_rref = $regexpref->complementary_type->compiled_check;

push @EXPORT_OK, 'not_scalarref';
push @{$EXPORT_TAGS{nots}}, 'not_scalarref';
*not_scalarref = $scalarref->complementary_type->compiled_check;

push @EXPORT_OK, 'not_sref';
push @{$EXPORT_TAGS{nots}}, 'not_sref';
*not_sref = $scalarref->complementary_type->compiled_check;

push @EXPORT_OK, 'not_str';
push @{$EXPORT_TAGS{nots}}, 'not_str';
*not_str = $string->complementary_type->compiled_check;

push @EXPORT_OK, 'not_string';
push @{$EXPORT_TAGS{nots}}, 'not_string';
*not_string = $string->complementary_type->compiled_check;

push @EXPORT_OK, 'not_nil';
push @{$EXPORT_TAGS{nots}}, 'not_nil';
*not_nil = $undefined->complementary_type->compiled_check;

push @EXPORT_OK, 'not_null';
push @{$EXPORT_TAGS{nots}}, 'not_null';
*not_null = $undefined->complementary_type->compiled_check;

push @EXPORT_OK, 'not_undef';
push @{$EXPORT_TAGS{nots}}, 'not_undef';
*not_undef = $undefined->complementary_type->compiled_check;

push @EXPORT_OK, 'not_undefined';
push @{$EXPORT_TAGS{nots}}, 'not_undefined';
*not_undefined = $undefined->complementary_type->compiled_check;

push @EXPORT_OK, 'not_val';
push @{$EXPORT_TAGS{nots}}, 'not_val';
*not_val = $value->complementary_type->compiled_check;

push @EXPORT_OK, 'not_value';
push @{$EXPORT_TAGS{nots}}, 'not_value';
*not_value = $value->complementary_type->compiled_check;

# EXPORT: TYPES

push @EXPORT_OK, 'type_aref';
push @{$EXPORT_TAGS{types}}, 'type_aref';
*type_aref = $arrayref->_overload_coderef;

push @EXPORT_OK, 'type_arrayref';
push @{$EXPORT_TAGS{types}}, 'type_arrayref';
*type_arrayref = $arrayref->_overload_coderef;

push @EXPORT_OK, 'type_bool';
push @{$EXPORT_TAGS{types}}, 'type_bool';
*type_bool = $boolean->_overload_coderef;

push @EXPORT_OK, 'type_boolean';
push @{$EXPORT_TAGS{types}}, 'type_boolean';
*type_boolean = $boolean->_overload_coderef;

push @EXPORT_OK, 'type_class';
push @{$EXPORT_TAGS{types}}, 'type_class';
*type_class = $classname->_overload_coderef;

push @EXPORT_OK, 'type_classname';
push @{$EXPORT_TAGS{types}}, 'type_classname';
*type_classname = $classname->_overload_coderef;

push @EXPORT_OK, 'type_coderef';
push @{$EXPORT_TAGS{types}}, 'type_coderef';
*type_coderef = $coderef->_overload_coderef;

push @EXPORT_OK, 'type_cref';
push @{$EXPORT_TAGS{types}}, 'type_cref';
*type_cref = $coderef->_overload_coderef;

push @EXPORT_OK, 'type_def';
push @{$EXPORT_TAGS{types}}, 'type_def';
*type_def = $defined->_overload_coderef;

push @EXPORT_OK, 'type_defined';
push @{$EXPORT_TAGS{types}}, 'type_defined';
*type_defined = $defined->_overload_coderef;

push @EXPORT_OK, 'type_fh';
push @{$EXPORT_TAGS{types}}, 'type_fh';
*type_fh = $filehandle->_overload_coderef;

push @EXPORT_OK, 'type_filehandle';
push @{$EXPORT_TAGS{types}}, 'type_filehandle';
*type_filehandle = $filehandle->_overload_coderef;

push @EXPORT_OK, 'type_glob';
push @{$EXPORT_TAGS{types}}, 'type_glob';
*type_glob = $globref->_overload_coderef;

push @EXPORT_OK, 'type_globref';
push @{$EXPORT_TAGS{types}}, 'type_globref';
*type_globref = $globref->_overload_coderef;

push @EXPORT_OK, 'type_hashref';
push @{$EXPORT_TAGS{types}}, 'type_hashref';
*type_hashref = $hashref->_overload_coderef;

push @EXPORT_OK, 'type_href';
push @{$EXPORT_TAGS{types}}, 'type_href';
*type_href = $hashref->_overload_coderef;

push @EXPORT_OK, 'type_int';
push @{$EXPORT_TAGS{types}}, 'type_int';
*type_int = $integer->_overload_coderef;

push @EXPORT_OK, 'type_integer';
push @{$EXPORT_TAGS{types}}, 'type_integer';
*type_integer = $integer->_overload_coderef;

push @EXPORT_OK, 'type_num';
push @{$EXPORT_TAGS{types}}, 'type_num';
*type_num = $number->_overload_coderef;

push @EXPORT_OK, 'type_number';
push @{$EXPORT_TAGS{types}}, 'type_number';
*type_number = $number->_overload_coderef;

push @EXPORT_OK, 'type_obj';
push @{$EXPORT_TAGS{types}}, 'type_obj';
*type_obj = $object->_overload_coderef;

push @EXPORT_OK, 'type_object';
push @{$EXPORT_TAGS{types}}, 'type_object';
*type_object = $object->_overload_coderef;

push @EXPORT_OK, 'type_ref';
push @{$EXPORT_TAGS{types}}, 'type_ref';
*type_ref = $reference->_overload_coderef;

push @EXPORT_OK, 'type_reference';
push @{$EXPORT_TAGS{types}}, 'type_reference';
*type_reference = $reference->_overload_coderef;

push @EXPORT_OK, 'type_regexpref';
push @{$EXPORT_TAGS{types}}, 'type_regexpref';
*type_regexpref = $regexpref->_overload_coderef;

push @EXPORT_OK, 'type_rref';
push @{$EXPORT_TAGS{types}}, 'type_rref';
*type_rref = $regexpref->_overload_coderef;

push @EXPORT_OK, 'type_scalarref';
push @{$EXPORT_TAGS{types}}, 'type_scalarref';
*type_scalarref = $scalarref->_overload_coderef;

push @EXPORT_OK, 'type_sref';
push @{$EXPORT_TAGS{types}}, 'type_sref';
*type_sref = $scalarref->_overload_coderef;

push @EXPORT_OK, 'type_str';
push @{$EXPORT_TAGS{types}}, 'type_str';
*type_str = $string->_overload_coderef;

push @EXPORT_OK, 'type_string';
push @{$EXPORT_TAGS{types}}, 'type_string';
*type_string = $string->_overload_coderef;

push @EXPORT_OK, 'type_nil';
push @{$EXPORT_TAGS{types}}, 'type_nil';
*type_nil = $undefined->_overload_coderef;

push @EXPORT_OK, 'type_null';
push @{$EXPORT_TAGS{types}}, 'type_null';
*type_null = $undefined->_overload_coderef;

push @EXPORT_OK, 'type_undef';
push @{$EXPORT_TAGS{types}}, 'type_undef';
*type_undef = $undefined->_overload_coderef;

push @EXPORT_OK, 'type_undefined';
push @{$EXPORT_TAGS{types}}, 'type_undefined';
*type_undefined = $undefined->_overload_coderef;

push @EXPORT_OK, 'type_val';
push @{$EXPORT_TAGS{types}}, 'type_val';
*type_val = $value->_overload_coderef;

push @EXPORT_OK, 'type_value';
push @{$EXPORT_TAGS{types}}, 'type_value';
*type_value = $value->_overload_coderef;

# EXPORT: TYPESOF

push @EXPORT_OK, 'typeof_aref';
push @{$EXPORT_TAGS{typesof}}, 'typeof_aref';
*typeof_aref = sub () {
    require Type::Params;
    Type::Params::compile($arrayref);
};

push @EXPORT_OK, 'typeof_arrayref';
push @{$EXPORT_TAGS{typesof}}, 'typeof_arrayref';
*typeof_arrayref = sub () {
    require Type::Params;
    Type::Params::compile($arrayref);
};

push @EXPORT_OK, 'typeof_bool';
push @{$EXPORT_TAGS{typesof}}, 'typeof_bool';
*typeof_bool = sub () {
    require Type::Params;
    Type::Params::compile($boolean);
};

push @EXPORT_OK, 'typeof_boolean';
push @{$EXPORT_TAGS{typesof}}, 'typeof_boolean';
*typeof_boolean = sub () {
    require Type::Params;
    Type::Params::compile($boolean);
};

push @EXPORT_OK, 'typeof_class';
push @{$EXPORT_TAGS{typesof}}, 'typeof_class';
*typeof_class = sub () {
    require Type::Params;
    Type::Params::compile($classname);
};

push @EXPORT_OK, 'typeof_classname';
push @{$EXPORT_TAGS{typesof}}, 'typeof_classname';
*typeof_classname = sub () {
    require Type::Params;
    Type::Params::compile($classname);
};

push @EXPORT_OK, 'typeof_coderef';
push @{$EXPORT_TAGS{typesof}}, 'typeof_coderef';
*typeof_coderef = sub () {
    require Type::Params;
    Type::Params::compile($coderef);
};

push @EXPORT_OK, 'typeof_cref';
push @{$EXPORT_TAGS{typesof}}, 'typeof_cref';
*typeof_cref = sub () {
    require Type::Params;
    Type::Params::compile($coderef);
};

push @EXPORT_OK, 'typeof_def';
push @{$EXPORT_TAGS{typesof}}, 'typeof_def';
*typeof_def = sub () {
    require Type::Params;
    Type::Params::compile($defined);
};

push @EXPORT_OK, 'typeof_defined';
push @{$EXPORT_TAGS{typesof}}, 'typeof_defined';
*typeof_defined = sub () {
    require Type::Params;
    Type::Params::compile($defined);
};

push @EXPORT_OK, 'typeof_fh';
push @{$EXPORT_TAGS{typesof}}, 'typeof_fh';
*typeof_fh = sub () {
    require Type::Params;
    Type::Params::compile($filehandle);
};

push @EXPORT_OK, 'typeof_filehandle';
push @{$EXPORT_TAGS{typesof}}, 'typeof_filehandle';
*typeof_filehandle = sub () {
    require Type::Params;
    Type::Params::compile($filehandle);
};

push @EXPORT_OK, 'typeof_glob';
push @{$EXPORT_TAGS{typesof}}, 'typeof_glob';
*typeof_glob = sub () {
    require Type::Params;
    Type::Params::compile($globref);
};

push @EXPORT_OK, 'typeof_globref';
push @{$EXPORT_TAGS{typesof}}, 'typeof_globref';
*typeof_globref = sub () {
    require Type::Params;
    Type::Params::compile($globref);
};

push @EXPORT_OK, 'typeof_hashref';
push @{$EXPORT_TAGS{typesof}}, 'typeof_hashref';
*typeof_hashref = sub () {
    require Type::Params;
    Type::Params::compile($hashref);
};

push @EXPORT_OK, 'typeof_href';
push @{$EXPORT_TAGS{typesof}}, 'typeof_href';
*typeof_href = sub () {
    require Type::Params;
    Type::Params::compile($hashref);
};

push @EXPORT_OK, 'typeof_int';
push @{$EXPORT_TAGS{typesof}}, 'typeof_int';
*typeof_int = sub () {
    require Type::Params;
    Type::Params::compile($integer);
};

push @EXPORT_OK, 'typeof_integer';
push @{$EXPORT_TAGS{typesof}}, 'typeof_integer';
*typeof_integer = sub () {
    require Type::Params;
    Type::Params::compile($integer);
};

push @EXPORT_OK, 'typeof_num';
push @{$EXPORT_TAGS{typesof}}, 'typeof_num';
*typeof_num = sub () {
    require Type::Params;
    Type::Params::compile($number);
};

push @EXPORT_OK, 'typeof_number';
push @{$EXPORT_TAGS{typesof}}, 'typeof_number';
*typeof_number = sub () {
    require Type::Params;
    Type::Params::compile($number);
};

push @EXPORT_OK, 'typeof_obj';
push @{$EXPORT_TAGS{typesof}}, 'typeof_obj';
*typeof_obj = sub () {
    require Type::Params;
    Type::Params::compile($object);
};

push @EXPORT_OK, 'typeof_object';
push @{$EXPORT_TAGS{typesof}}, 'typeof_object';
*typeof_object = sub () {
    require Type::Params;
    Type::Params::compile($object);
};

push @EXPORT_OK, 'typeof_ref';
push @{$EXPORT_TAGS{typesof}}, 'typeof_ref';
*typeof_ref = sub () {
    require Type::Params;
    Type::Params::compile($reference);
};

push @EXPORT_OK, 'typeof_reference';
push @{$EXPORT_TAGS{typesof}}, 'typeof_reference';
*typeof_reference = sub () {
    require Type::Params;
    Type::Params::compile($reference);
};

push @EXPORT_OK, 'typeof_regexpref';
push @{$EXPORT_TAGS{typesof}}, 'typeof_regexpref';
*typeof_regexpref = sub () {
    require Type::Params;
    Type::Params::compile($regexpref);
};

push @EXPORT_OK, 'typeof_rref';
push @{$EXPORT_TAGS{typesof}}, 'typeof_rref';
*typeof_rref = sub () {
    require Type::Params;
    Type::Params::compile($regexpref);
};

push @EXPORT_OK, 'typeof_scalarref';
push @{$EXPORT_TAGS{typesof}}, 'typeof_scalarref';
*typeof_scalarref = sub () {
    require Type::Params;
    Type::Params::compile($scalarref);
};

push @EXPORT_OK, 'typeof_sref';
push @{$EXPORT_TAGS{typesof}}, 'typeof_sref';
*typeof_sref = sub () {
    require Type::Params;
    Type::Params::compile($scalarref);
};

push @EXPORT_OK, 'typeof_str';
push @{$EXPORT_TAGS{typesof}}, 'typeof_str';
*typeof_str = sub () {
    require Type::Params;
    Type::Params::compile($string);
};

push @EXPORT_OK, 'typeof_string';
push @{$EXPORT_TAGS{typesof}}, 'typeof_string';
*typeof_string = sub () {
    require Type::Params;
    Type::Params::compile($string);
};

push @EXPORT_OK, 'typeof_nil';
push @{$EXPORT_TAGS{typesof}}, 'typeof_nil';
*typeof_nil = sub () {
    require Type::Params;
    Type::Params::compile($undefined);
};

push @EXPORT_OK, 'typeof_null';
push @{$EXPORT_TAGS{typesof}}, 'typeof_null';
*typeof_null = sub () {
    require Type::Params;
    Type::Params::compile($undefined);
};

push @EXPORT_OK, 'typeof_undef';
push @{$EXPORT_TAGS{typesof}}, 'typeof_undef';
*typeof_undef = sub () {
    require Type::Params;
    Type::Params::compile($undefined);
};

push @EXPORT_OK, 'typeof_undefined';
push @{$EXPORT_TAGS{typesof}}, 'typeof_undefined';
*typeof_undefined = sub () {
    require Type::Params;
    Type::Params::compile($undefined);
};

push @EXPORT_OK, 'typeof_val';
push @{$EXPORT_TAGS{typesof}}, 'typeof_val';
*typeof_val = sub () {
    require Type::Params;
    Type::Params::compile($value);
};

push @EXPORT_OK, 'typeof_value';
push @{$EXPORT_TAGS{typesof}}, 'typeof_value';
*typeof_value = sub () {
    require Type::Params;
    Type::Params::compile($value);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bubblegum::Constraints - Type and Constraints Library for Bubblegum

=head1 VERSION

version 0.45

=head1 SYNOPSIS

    package Server;

    use Bubblegum::Class;
    use Bubblegum::Constraints 'typeof_arrayref';

    has 'ifaces' => (
        is       => 'ro',
        isa      => typeof_arrayref,
        required => 1
    );

=head1 DESCRIPTION

Bubblegum::Constraints is the standard type-checking library for L<Bubblegum>
applications with a focus on minimalism and data integrity. This library derives
its type validation from L<Types::Standard>, the L<Type::Tiny> standard library.
B<Note: This is an early release available for testing and feedback and as such
is subject to change.>

By default, no functions are exported when using this package, all functionality
desired will need to be explicitly requested, and because many functions belong
to a particular group of functions there are export tags which can be used to
export sets of functions by group name. Any function can also be exported
individually. The following are a list of functions and groups currently
available:

=head2 -all

The all export group exports all functions from the L</-types>, L</-typesof>,
L</-isas>, and L</-nots> export groups.

=head2 -isas

The isas export group exports all functions which have the C<isa_> prefix. These
functions take a single argument and perform non-fatal type checking and return
true or false. The following is a list of functions exported by this group:

=head3 isa_aref

    isa_aref '...';

The isa_aref function validates that the argument is an array reference. If the
argument is not an array reference, the function will return false.

=head3 isa_arrayref

    isa_arrayref '...';

The isa_arrayref function validates that the argument is an array reference. If
the argument is not an array reference, the function will return false.

=head3 isa_bool

    isa_bool '...';

The isa_bool function validates that the argument is a boolean value. If the
argument is not a boolean value, the function will return false.

=head3 isa_boolean

    isa_boolean '...';

The isa_boolean function validates that the argument is a boolean value. If the
argument is not a boolean value, the function will return false.

=head3 isa_class

    isa_class '...';

The isa_class function validates that the argument is a class name. If the
argument is not a class name, the function will return false.

=head3 isa_classname

    isa_classname '...';

The isa_classname function validates that the argument is a class name. If the
argument is not a class name, the function will return false.

=head3 isa_coderef

    isa_coderef '...';

The isa_coderef function validates that the argument is a code reference. If the
argument is not a code reference, the function will return false.

=head3 isa_cref

    isa_cref '...';

The isa_cref function validates that the argument is a code reference. If the
argument is not a code reference, the function will return false.

=head3 isa_def

    isa_def '...';

The isa_def function validates that the argument is a defined value. If the
argument is not a defined value, the function will return false.

=head3 isa_defined

    isa_defined '...';

The isa_defined function validates that the argument is a defined value. If the
argument is not a defined value, the function will return false.

=head3 isa_fh

    isa_fh '...';

The isa_fh function validates that the argument is a file handle. If the
argument is not a file handle, the function will return false.

=head3 isa_filehandle

    isa_filehandle '...';

The isa_filehandle function validates that the argument is a file handle. If the
argument is not a file handle, the function will return false.

=head3 isa_glob

    isa_glob '...';

The isa_glob function validates that the argument is a glob reference. If the
argument is not a glob reference, the function will return false.

=head3 isa_globref

    isa_globref '...';

The isa_globref function validates that the argument is a glob reference. If the
argument is not a glob reference, the function will return false.

=head3 isa_hashref

    isa_hashref '...';

The isa_hashref function validates that the argument is a hash reference. If the
argument is not a hash reference, the function will return false.

=head3 isa_href

    isa_href '...';

The isa_href function validates that the argument is a hash reference. If the
argument is not a hash reference, the function will return false.

=head3 isa_int

    isa_int '...';

The isa_int function validates that the argument is an integer. If the
argument is not an integer, the function will return false.

=head3 isa_integer

    isa_integer '...';

The isa_integer function validates that the argument is an integer. If the
argument is not an integer, the function will return false.

=head3 isa_num

    isa_num '...';

The isa_num function validates that the argument is a number. If the
argument is not a number, the function will return false.

=head3 isa_number

    isa_number '...';

The isa_number function validates that the argument is a number. If the
argument is not a number, the function will return false.

=head3 isa_obj

    isa_obj '...';

The isa_obj function validates that the argument is an object. If the
argument is not an object, the function will return false.

=head3 isa_object

    isa_object '...';

The isa_object function validates that the argument is an object. If the
argument is not an object, the function will return false.

=head3 isa_ref

    isa_ref '...';

The isa_ref function validates that the argument is a reference. If the
argument is not a reference, the function will return false.

=head3 isa_reference

    isa_reference '...';

The isa_reference function validates that the argument is a reference. If the
argument is not a reference, the function will return false.

=head3 isa_regexpref

    isa_regexpref '...';

The isa_regexpref function validates that the argument is a regular expression
reference. If the argument is not a regular expression reference, the function
will return false.

=head3 isa_rref

    isa_rref '...';

The isa_rref function validates that the argument is a regular expression
reference. If the argument is not a regular expression reference, the function
will return false.

=head3 isa_scalarref

    isa_scalarref '...';

The isa_scalarref function validates that the argument is a scalar reference. If
the argument is not a scalar reference, the function will return false.

=head3 isa_sref

    isa_sref '...';

The isa_sref function validates that the argument is a scalar reference. If the
argument is not a scalar reference, the function will return false.

=head3 isa_str

    isa_str '...';

The isa_str function validates that the argument is a string. If the
argument is not a string, the function will return false.

=head3 isa_string

    isa_string '...';

The isa_string function validates that the argument is a string. If the
argument is not a string, the function will return false.

=head3 isa_nil

    isa_nil '...';

The isa_nil function validates that the argument is an undefined value. If the
argument is not an undefined value, the function will return false.

=head3 isa_null

    isa_null '...';

The isa_null function validates that the argument is an undefined value. If the
argument is not an undefined value, the function will return false.

=head3 isa_undef

    isa_undef '...';

The isa_undef function validates that the argument is an undefined value. If the
argument is not an undefined value, the function will return false.

=head3 isa_undefined

    isa_undefined '...';

The isa_undefined function validates that the argument is an undefined value. If
the argument is not an undefined value, the function will return false.

=head3 isa_val

    isa_val '...';

The isa_val function validates that the argument is a value. If the
argument is not a value, the function will return false.

=head3 isa_value

    isa_value '...';

The isa_value function validates that the argument is a value. If the
argument is not a value, the function will return false.

=head2 -nots

The nots export group exports all functions which have the C<not_> prefix. These
functions take a single argument and perform non-fatal negated type checking and
return true or false. The following is a list of functions exported by this
group:

=head3 not_aref

    not_aref '...';

The not_aref function validates that the argument is NOT an array reference. If
the argument is an array reference, the function will return false.

=head3 not_arrayref

    not_arrayref '...';

The not_arrayref function validates that the argument is NOT an array reference.
If the argument is an array reference, the function will return false.

=head3 not_bool

    not_bool '...';

The not_bool function validates that the argument is NOT a boolean value. If
the argument is a boolean value, the function will return false.

=head3 not_boolean

    not_boolean '...';

The not_boolean function validates that the argument is NOT a boolean value. If
the argument is a boolean value, the function will return false.

=head3 not_class

    not_class '...';

The not_class function validates that the argument is NOT a class name. If the
argument is a class name, the function will return false.

=head3 not_classname

    not_classname '...';

The not_classname function validates that the argument is NOT a class name. If
the argument is a class name, the function will return false.

=head3 not_coderef

    not_coderef '...';

The not_coderef function validates that the argument is NOT a code reference. If
the argument is a code reference, the function will return false.

=head3 not_cref

    not_cref '...';

The not_cref function validates that the argument is NOT a code reference. If
the argument is a code reference, the function will return false.

=head3 not_def

    not_def '...';

The not_def function validates that the argument is NOT a defined value. If the
argument is a defined value, the function will return false.

=head3 not_defined

    not_defined '...';

The not_defined function validates that the argument is NOT a defined value. If
the argument is a defined value, the function will return false.

=head3 not_fh

    not_fh '...';

The not_fh function validates that the argument is NOT a file handle. If the
argument is a file handle, the function will return false.

=head3 not_filehandle

    not_filehandle '...';

The not_filehandle function validates that the argument is NOT a file handle. If
the argument is a file handle, the function will return false.

=head3 not_glob

    not_glob '...';

The not_glob function validates that the argument is NOT a glob reference. If
the argument is a glob reference, the function will return false.

=head3 not_globref

    not_globref '...';

The not_globref function validates that the argument is NOT a glob reference. If
the argument is a glob reference, the function will return false.

=head3 not_hashref

    not_hashref '...';

The not_hashref function validates that the argument is NOT a hash reference. If
the argument is a hash reference, the function will return false.

=head3 not_href

    not_href '...';

The not_href function validates that the argument is NOT a hash reference. If
the argument is a hash reference, the function will return false.

=head3 not_int

    not_int '...';

The not_int function validates that the argument is NOT an integer. If the
argument is an integer, the function will return false.

=head3 not_integer

    not_integer '...';

The not_integer function validates that the argument is NOT an integer. If
the argument is an integer, the function will return false.

=head3 not_num

    not_num '...';

The not_num function validates that the argument is NOT a number. If the
argument is a number, the function will return false.

=head3 not_number

    not_number '...';

The not_number function validates that the argument is NOT a number. If the
argument is a number, the function will return false.

=head3 not_obj

    not_obj '...';

The not_obj function validates that the argument is NOT an object. If the
argument is an object, the function will return false.

=head3 not_object

    not_object '...';

The not_object function validates that the argument is NOT an object. If the
argument is an object, the function will return false.

=head3 not_ref

    not_ref '...';

The not_ref function validates that the argument is NOT a reference. If the
argument is a reference, the function will return false.

=head3 not_reference

    not_reference '...';

The not_reference function validates that the argument is NOT a reference. If
the argument is a reference, the function will return false.

=head3 not_regexpref

    not_regexpref '...';

The not_regexpref function validates that the argument is NOT a regular
expression reference. If the argument is a regular expression reference, the
function will return false.

=head3 not_rref

    not_rref '...';

The not_rref function validates that the argument is NOT a regular expression
reference. If the argument is a regular expression reference, the function will
return false.

=head3 not_scalarref

    not_scalarref '...';

The not_scalarref function validates that the argument is NOT a scalar
reference. If the argument is a scalar reference, the function will return
false.

=head3 not_sref

    not_sref '...';

The not_sref function validates that the argument is NOT a scalar reference. If
the argument is a scalar reference, the function will return false.

=head3 not_str

    not_str '...';

The not_str function validates that the argument is NOT a string. If the
argument is a string, the function will return false.

=head3 not_string

    not_string '...';

The not_string function validates that the argument is NOT a string. If the
argument is a string, the function will return false.

=head3 not_nil

    not_nil '...';

The not_nil function validates that the argument is NOT an undefined value. If
the argument is an undefined value, the function will return false.

=head3 not_null

    not_null '...';

The not_null function validates that the argument is NOT an undefined value. If
the argument is an undefined value, the function will return false.

=head3 not_undef

    not_undef '...';

The not_undef function validates that the argument is NOT an undefined value. If
the argument is an undefined value, the function will return false.

=head3 not_undefined

    not_undefined '...';

The not_undefined function validates that the argument is NOT an undefined
value. If the argument is an undefined value, the function will return false.

=head3 not_val

    not_val '...';

The not_val function validates that the argument is NOT a value. If the argument
is a value, the function will return false.

=head3 not_value

    not_value '...';

The not_value function validates that the argument is NOT a value. If the
argument is a value, the function will return false.

=head2 -types

The types export group exports all functions which have the C<type_> prefix.
These functions take a single argument/expression and perform fatal type
checking operation returning the argument/expression if successful. The follow
is a list of functions exported by this group:

=head3 type_aref

    type_aref '...';

The type_aref function asserts that the argument is an array reference. If
the argument is not an array reference, the function will cause the program to
die.

=head3 type_arrayref

    type_arrayref '...';

The type_arrayref function asserts that the argument is an array reference. If
the argument is not an array reference, the function will cause the program to
die.

=head3 type_bool

    type_bool '...';

The type_bool function asserts that the argument is a boolean value. If the
argument is not a boolean value, the function will cause the program to die.

=head3 type_boolean

    type_boolean '...';

The type_boolean function asserts that the argument is a boolean value. If the
argument is not a boolean value, the function will cause the program to die.

=head3 type_class

    type_class '...';

The type_class function asserts that the argument is a class name. If the
argument is not a class name, the function will cause the program to die.

=head3 type_classname

    type_classname '...';

The type_classname function asserts that the argument is a class name. If the
argument is not a class name, the function will cause the program to die.

=head3 type_coderef

    type_coderef '...';

The type_coderef function asserts that the argument is a code reference. If the
argument is not a code reference, the function will cause the program to die.

=head3 type_cref

    type_cref '...';

The type_cref function asserts that the argument is a code reference. If the
argument is not a code reference, the function will cause the program to die.

=head3 type_def

    type_def '...';

The type_def function asserts that the argument is a defined value. If the
argument is not a defined value, the function will cause the program to die.

=head3 type_defined

    type_defined '...';

The type_defined function asserts that the argument is a defined value. If the
argument is not a defined value, the function will cause the program to die.

=head3 type_fh

    type_fh '...';

The type_fh function asserts that the argument is a file handle. If the argument
is not a file handle, the function will cause the program to die.

=head3 type_filehandle

    type_filehandle '...';

The type_filehandle function asserts that the argument is a file handle. If
the argument is not a file handle, the function will cause the program to die.

=head3 type_glob

    type_glob '...';

The type_glob function asserts that the argument is a glob reference. If the
argument is not a glob reference, the function will cause the program to die.

=head3 type_globref

    type_globref '...';

The type_globref function asserts that the argument is a glob reference. If the
argument is not a glob reference, the function will cause the program to die.

=head3 type_hashref

    type_hashref '...';

The type_hashref function asserts that the argument is a hash reference. If the
argument is not a hash reference, the function will cause the program to die.

=head3 type_href

    type_href '...';

The type_href function asserts that the argument is a hash reference. If the
argument is not a hash reference, the function will cause the program to die.

=head3 type_int

    type_int '...';

The type_int function asserts that the argument is an integer. If the argument
is not an integer, the function will cause the program to die.

=head3 type_integer

    type_integer '...';

The type_integer function asserts that the argument is an integer. If the
argument is not an integer, the function will cause the program to die.

=head3 type_num

    type_num '...';

The type_num function asserts that the argument is a number. If the argument is
not a number, the function will cause the program to die.

=head3 type_number

    type_number '...';

The type_number function asserts that the argument is a number. If the argument
is not a number, the function will cause the program to die.

=head3 type_obj

    type_obj '...';

The type_obj function asserts that the argument is an object. If the argument is
not an object, the function will cause the program to die.

=head3 type_object

    type_object '...';

The type_object function asserts that the argument is an object. If the argument
is not an object, the function will cause the program to die.

=head3 type_ref

    type_ref '...';

The type_ref function asserts that the argument is a reference. If the argument
is not a reference, the function will cause the program to die.

=head3 type_reference

    type_reference '...';

The type_reference function asserts that the argument is a reference. If the
argument is not a reference, the function will cause the program to die.

=head3 type_regexpref

    type_regexpref '...';

The type_regexpref function asserts that the argument is a regular expression
reference. If the argument is not a regular expression reference, the function
will cause the program to die.

=head3 type_rref

    type_rref '...';

The type_rref function asserts that the argument is a regular expression
reference. If the argument is not a regular expression reference, the function
will cause the program to die.

=head3 type_scalarref

    type_scalarref '...';

The type_scalarref function asserts that the argument is a scalar reference. If
the argument is not a scalar reference, the function will cause the program to
die.

=head3 type_sref

    type_sref '...';

The type_sref function asserts that the argument is a scalar reference. If the
argument is not a scalar reference, the function will cause the program to die.

=head3 type_str

    type_str '...';

The type_str function asserts that the argument is a string. If the argument is
not a string, the function will cause the program to die.

=head3 type_string

    type_string '...';

The type_string function asserts that the argument is a string. If the argument
is not a string, the function will cause the program to die.

=head3 type_nil

    type_nil '...';

The type_nil function asserts that the argument is an undefined value. If the
argument is not an undefined value, the function will cause the program to die.

=head3 type_null

    type_null '...';

The type_null function asserts that the argument is an undefined value. If the
argument is not an undefined value, the function will cause the program to die.

=head3 type_undef

    type_undef '...';

The type_undef function asserts that the argument is an undefined value. If the
argument is not an undefined value, the function will cause the program to die.

=head3 type_undefined

    type_undefined '...';

The type_undefined function asserts that the argument is an undefined value. If
the argument is not an undefined value, the function will cause the program to
die.

=head3 type_val

    type_val '...';

The type_val function asserts that the argument is a value. If the argument is
not a value, the function will cause the program to die.

=head3 type_value

    type_value '...';

The type_value function asserts that the argument is a value. If the argument is
not a value, the function will cause the program to die.

=head2 -typesof

The typesof export group exports all functions which have the C<typeof_> prefix.
These functions take no argument and return a type-validation code reference to
be used with your object-system of choice. The following is a list of functions
exported by this group:

=head3 typeof_aref

    typeof_aref;

The typeof_aref function returns a type constraint in the form of a code
reference which asserts that the argument is an array reference. If the argument
is not an array reference, the function will cause the program to die.

=head3 typeof_arrayref

    typeof_arrayref;

The typeof_arrayref function returns a type constraint in the form of a code
reference which asserts that the argument is an array reference. If the argument
is not an array reference, the function will cause the program to die.

=head3 typeof_bool

    typeof_bool;

The typeof_bool function returns a type constraint in the form of a code
reference which asserts that the argument is a boolean value. If the argument is
not a boolean value, the function will cause the program to die.

=head3 typeof_boolean

    typeof_boolean;

The typeof_boolean function returns a type constraint in the form of a code
reference which asserts that the argument is a boolean value. If the argument is
not a boolean value, the function will cause the program to die.

=head3 typeof_class

    typeof_class;

The typeof_class function returns a type constraint in the form of a code
reference which asserts that the argument is a class name. If the argument is
not a class name, the function will cause the program to die.

=head3 typeof_classname

    typeof_classname;

The typeof_classname function returns a type constraint in the form of a code
reference which asserts that the argument is a class name. If the argument is
not a class name, the function will cause the program to die.

=head3 typeof_coderef

    typeof_coderef;

The typeof_coderef function returns a type constraint in the form of a code
reference which asserts that the argument is a code reference. If the argument
is not a code reference, the function will cause the program to die.

=head3 typeof_cref

    typeof_cref;

The typeof_cref function returns a type constraint in the form of a code
reference which asserts that the argument is a code reference. If the argument
is not a code reference, the function will cause the program to die.

=head3 typeof_def

    typeof_def;

The typeof_def function returns a type constraint in the form of a code
reference which asserts that the argument is a defined value. If the argument is
not a defined value, the function will cause the program to die.

=head3 typeof_defined

    typeof_defined;

The typeof_defined function returns a type constraint in the form of a code
reference which asserts that the argument is a defined value. If the argument is
not a defined value, the function will cause the program to die.

=head3 typeof_fh

    typeof_fh;

The typeof_fh function returns a type constraint in the form of a code reference
which asserts that the argument is a file handle. If the argument is not a file
handle, the function will cause the program to die.

=head3 typeof_filehandle

    typeof_filehandle;

The typeof_filehandle function returns a type constraint in the form of a code
reference which asserts that the argument is a file handle. If the argument is
not a file handle, the function will cause the program to die.

=head3 typeof_glob

    typeof_glob;

The typeof_glob function returns a type constraint in the form of a code
reference which asserts that the argument is a glob reference. If the argument
is not a glob reference, the function will cause the program to die.

=head3 typeof_globref

    typeof_globref;

The typeof_globref function returns a type constraint in the form of a code
reference which asserts that the argument is a glob reference. If the argument
is not a glob reference, the function will cause the program to die.

=head3 typeof_hashref

    typeof_hashref;

The typeof_hashref function returns a type constraint in the form of a code
reference which asserts that the argument is a hash reference. If the argument
is not a hash reference, the function will cause the program to die.

=head3 typeof_href

    typeof_href;

The typeof_href function returns a type constraint in the form of a code
reference which asserts that the argument is a hash reference. If the argument
is not a hash reference, the function will cause the program to die.

=head3 typeof_int

    typeof_int;

The typeof_int function returns a type constraint in the form of a code
reference which asserts that the argument is an integer. If the argument is not
an integer, the function will cause the program to die.

=head3 typeof_integer

    typeof_integer;

The typeof_integer function returns a type constraint in the form of a code
reference which asserts that the argument is an integer. If the argument is not
an integer, the function will cause the program to die.

=head3 typeof_num

    typeof_num;

The typeof_num function returns a type constraint in the form of a code
reference which asserts that the argument is a number. If the argument is not a
number, the function will cause the program to die.

=head3 typeof_number

    typeof_number;

The typeof_number function returns a type constraint in the form of a code
reference which asserts that the argument is a number. If the argument is not a
number, the function will cause the program to die.

=head3 typeof_obj

    typeof_obj;

The typeof_obj function returns a type constraint in the form of a code
reference which asserts that the argument is an object. If the argument is not
an object, the function will cause the program to die.

=head3 typeof_object

    typeof_object;

The typeof_object function returns a type constraint in the form of a code
reference which asserts that the argument is an object. If the argument is not
an object, the function will cause the program to die.

=head3 typeof_ref

    typeof_ref;

The typeof_ref function returns a type constraint in the form of a code
reference which asserts that the argument is a reference. If the argument is not
a reference, the function will cause the program to die.

=head3 typeof_reference

    typeof_reference;

The typeof_reference function returns a type constraint in the form of a code
reference which asserts that the argument is a reference. If the argument is not
a reference, the function will cause the program to die.

=head3 typeof_regexpref

    typeof_regexpref;

The typeof_regexpref function returns a type constraint in the form of a code
reference which asserts that the argument is a regular expression reference. If
the argument is not a regular expression reference, the function will cause the
program to die.

=head3 typeof_rref

    typeof_rref;

The typeof_rref function returns a type constraint in the form of a code
reference which asserts that the argument is a regular expression reference. If
the argument is not a regular expression reference, the function will cause the
program to die.

=head3 typeof_scalarref

    typeof_scalarref;

The typeof_scalarref function returns a type constraint in the form of a code
reference which asserts that the argument is a scalar reference. If the argument
is not a scalar reference, the function will cause the program to die.

=head3 typeof_sref

    typeof_sref;

The typeof_sref function returns a type constraint in the form of a code
reference which asserts that the argument is a scalar reference. If the argument
is not a scalar reference, the function will cause the program to die.

=head3 typeof_str

    typeof_str;

The typeof_str function returns a type constraint in the form of a code
reference which asserts that the argument is a string. If the argument is not a
string, the function will cause the program to die.

=head3 typeof_string

    typeof_string;

The typeof_string function returns a type constraint in the form of a code
reference which asserts that the argument is a string. If the argument is not a
string, the function will cause the program to die.

=head3 typeof_nil

    typeof_nil;

The typeof_nil function returns a type constraint in the form of a code
reference which asserts that the argument is an undefined value. If the argument
is not an undefined value, the function will cause the program to die.

=head3 typeof_null

    typeof_null;

The typeof_null function returns a type constraint in the form of a code
reference which asserts that the argument is an undefined value. If the argument
is not an undefined value, the function will cause the program to die.

=head3 typeof_undef

    typeof_undef;

The typeof_undef function returns a type constraint in the form of a code
reference which asserts that the argument is an undefined value. If the argument
is not an undefined value, the function will cause the program to die.

=head3 typeof_undefined

    typeof_undefined;

The typeof_undefined function returns a type constraint in the form of a code
reference which asserts that the argument is an undefined value. If the argument
is not an undefined value, the function will cause the program to die.

=head3 typeof_val

    typeof_val;

The typeof_val function returns a type constraint in the form of a code
reference which asserts that the argument is a value. If the argument is not a
value, the function will cause the program to die.

=head3 typeof_value

    typeof_value;

The typeof_value function returns a type constraint in the form of a code
reference which asserts that the argument is a value. If the argument is not a
value, the function will cause the program to die.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

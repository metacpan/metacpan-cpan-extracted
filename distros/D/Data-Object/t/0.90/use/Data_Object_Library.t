use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Data::Object::Library

=abstract

Data-Object Library Configuration

=synopsis

  use Data::Object::Library;

=description

Data::Object::Library is a L<Type::Tiny> type library (L<Type::Library>) which
extends the L<Types::Standard>, L<Types::Common::Numeric>, and
L<Types::Common::String> libraries, and adds type constraints and coercions for
L<Data::Object> objects.

=cut

=type Any

  has data => (
    is  => 'ro',
    isa => 'Any',
  );

The Any type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Any> function can be
used to throw an exception is the argument can not be validated. The C<is_Any>
function can be used to return true or false if the argument can not be
validated.

=cut

=type AnyObj

  has data => (
    is  => 'ro',
    isa => 'AnyObj',
  );

The AnyObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Any> object. The
C<assert_AnyObj> function can be used to throw an exception if the argument can
not be validated. The C<is_AnyObj> function can be used to return true or false if
the argument can not be validated.

=cut

=type AnyObject

  has data => (
    is  => 'ro',
    isa => 'AnyObject',
  );

The AnyObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Any> object. The
C<assert_AnyObject> function can be used to throw an exception if the argument can
not be validated. The C<is_AnyObject> function can be used to return true or false
if the argument can not be validated.

=cut

=type ArrayLike

  has data => (
    is  => 'ro',
    isa => 'ArrayLike',
  );

The ArrayLike type constraint is provided by the L<Types::TypeTiny> library.
Please see that documentation for more information. The C<assert_ArrayLike>
function can be used to throw an exception if the argument can not be
validated. The C<is_ArrayLike> function can be used to return true or false if
the argument can not be validated.

=cut

=type ArrayObj

  has data => (
    is  => 'ro',
    isa => 'ArrayObj',
  );

The ArrayObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Array> object. The
C<assert_ArrayObj> function can be used to throw an exception if the argument can
not be validated. The C<is_ArrayObj> function can be used to return true or false
if the argument can not be validated.

=cut

=type ArrayObject

  has data => (
    is  => 'ro',
    isa => 'ArrayObject',
  );

The ArrayObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Array> object. The
C<assert_ArrayObject> function can be used to throw an exception if the argument
can not be validated. The C<is_ArrayObject> function can be used to return true or
false if the argument can not be validated.

=cut

=type ArrayRef

  has data => (
    is  => 'ro',
    isa => 'ArrayRef',
  );

The ArrayRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ArrayRef>
function can be used to throw an exception if the argument can not be
validated. The C<is_ArrayRef> function can be used to return true or false if the
argument can not be validated.

=cut

=type Bool

  has data => (
    is  => 'ro',
    isa => 'Bool',
  );

The Bool type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Bool> function can be
used to throw an exception if the argument can not be validated. The C<is_Bool>
function can be used to return true or false if the argument can not be
validated.

=cut

=type ClassName

  has data => (
    is  => 'ro',
    isa => 'ClassName[MyClass]',
  );

The ClassName type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ClassName>
function can be used to throw an exception if the argument can not be
validated. The C<is_ClassName> function can be used to return true or false if the
argument can not be validated.

=cut

=type CodeLike

  has data => (
    is  => 'ro',
    isa => 'CodeLike',
  );

The CodeLike type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_CodeLike> function can be
used to throw an exception if the argument can not be validated. The C<is_CodeLike>
function can be used to return true or false if the argument can not be
validated.

=cut

=type CodeObj

  has data => (
    is  => 'ro',
    isa => 'CodeObj',
  );

The CodeObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Code> object. The C<assert_CodeObj>
function can be used to throw an exception if the argument can not be
validated. The C<is_CodeObj> function can be used to return true or false if the
argument can not be validated.

=cut

=type CodeObject

  has data => (
    is  => 'ro',
    isa => 'CodeObject',
  );

The CodeObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Code> object. The
C<assert_CodeObject> function can be used to throw an exception if the argument
can not be validated. The C<is_CodeObject> function can be used to return true or
false if the argument can not be validated.

=cut

=type CodeRef

  has data => (
    is  => 'ro',
    isa => 'CodeRef',
  );

The CodeRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_CodeRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_CodeRef> function can be used to return true or false if the argument can not
be validated.

=cut

=type ConsumerOf

  has data => (
    is  => 'ro',
    isa => 'ConsumerOf[MyRole]',
  );

The ConsumerOf type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ConsumerOf>
function can be used to throw an exception if the argument can not be
validated. The C<is_ConsumerOf> function can be used to return true or false if
the argument can not be validated.

=cut

=type DataObj

  has data => (
    is  => 'ro',
    isa => 'DataObj',
  );

The DataObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Data> object. The
C<assert_DataObj> function can be used to throw an exception if the argument
can not be validated. The C<is_DataObj> function can be used to return true or
false if the argument can not be validated.

=cut

=type DataObject

  has data => (
    is  => 'ro',
    isa => 'DataObject',
  );

The DataObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Data> object. The
C<assert_DataObject> function can be used to throw an exception if the argument
can not be validated. The C<is_DataObject> function can be used to return true
or false if the argument can not be validated.

=cut

=type Defined

  has data => (
    is  => 'ro',
    isa => 'Defined',
  );

The Defined type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Defined> function
can be used to throw an exception if the argument can not be validated. The
C<is_Defined> function can be used to return true or false if the argument can not
be validated.

=cut

=type Dict

  has data => (
    is  => 'ro',
    isa => 'Dict',
  );

The Dict type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Dict> function can be
used to throw an exception if the argument can not be validated. The C<is_Dict>
function can be used to return true or false if the argument can not be
validated.

=cut

=type DispatchObj

  has data => (
    is  => 'ro',
    isa => 'DispatchObj',
  );

The DispatchObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Dispatch> object. The
C<assert_DispatchObj> function can be used to throw an exception if the
argument can not be validated. The C<is_DispatchObj> function can be used to
return true or false if the argument can not be validated.

=cut

=type DispatchObject

  has data => (
    is  => 'ro',
    isa => 'DispatchObject',
  );

The DispatchObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Dispatch> object. The
C<assert_DispatchObject> function can be used to throw an exception if the
argument can not be validated. The C<is_DispatchObject> function can be used to
return true or false if the argument can not be validated.

=cut

=type Enum

  has data => (
    is  => 'ro',
    isa => 'Enum',
  );

The Enum type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Enum> function can be
used to throw an exception if the argument can not be validated. The C<is_Enum>
function can be used to return true or false if the argument can not be
validated.

=cut

=type ExceptionObj

  has data => (
    is  => 'ro',
    isa => 'ExceptionObj',
  );

The ExceptionObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Exception> object. The
C<assert_ExceptionObj> function can be used to throw an exception if the
argument can not be validated. The C<is_ExceptionObj> function can be used to
return true or false if the argument can not be validated.

=cut

=type ExceptionObject

  has data => (
    is  => 'ro',
    isa => 'ExceptionObject',
  );

The ExceptionObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Exception> object. The
C<assert_ExceptionObject> function can be used to throw an exception if the
argument can not be validated. The C<is_ExceptionObject> function can be used
to return true or false if the argument can not be validated.

=cut

=type FileHandle

  has data => (
    is  => 'ro',
    isa => 'FileHandle',
  );

The FileHandle type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_FileHandle>
function can be used to throw an exception if the argument can not be
validated. The C<is_FileHandle> function can be used to return true or false if
the argument can not be validated.

=cut

=type FloatObj

  has data => (
    is  => 'ro',
    isa => 'FloatObj',
  );

The FloatObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Float> object. The
C<assert_FloatObj> function can be used to throw an exception if the argument can
not be validated. The C<is_FloatObj> function can be used to return true or false
if the argument can not be validated.

=cut

=type FloatObject

  has data => (
    is  => 'ro',
    isa => 'FloatObject',
  );

The FloatObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Float> object. The
C<assert_FloatObject> function can be used to throw an exception if the argument
can not be validated. The C<is_FloatObject> function can be used to return true or
false if the argument can not be validated.

=cut

=type FuncObj

  has data => (
    is  => 'ro',
    isa => 'FuncObj',
  );

The FuncObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Func> object. The
C<assert_FuncObj> function can be used to throw an exception if the argument
can not be validated. The C<is_FuncObj> function can be used to return true or
false if the argument can not be validated.

=cut

=type FuncObject

  has data => (
    is  => 'ro',
    isa => 'FuncObject',
  );

The FuncObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Func> object. The
C<assert_FuncObject> function can be used to throw an exception if the argument
can not be validated. The C<is_FuncObject> function can be used to return true
or false if the argument can not be validated.

=cut

=type GlobRef

  has data => (
    is  => 'ro',
    isa => 'GlobRef',
  );

The GlobRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_GlobRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_GlobRef> function can be used to return true or false if the argument can not
be validated.

=cut

=type HasMethods

  has data => (
    is  => 'ro',
    isa => 'HasMethods[...]',
  );

The HasMethods type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_HasMethods>
function can be used to throw an exception if the argument can not be
validated. The C<is_HasMethods> function can be used to return true or false if
the argument can not be validated.

=cut

=type HashLike

  has data => (
    is  => 'ro',
    isa => 'HashLike',
  );

The HashLike type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_HashLike> function can be
used to throw an exception if the argument can not be validated. The C<is_HashLike>
function can be used to return true or false if the argument can not be
validated.

=cut

=type HashObj

  has data => (
    is  => 'ro',
    isa => 'HashObj',
  );

The HashObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Hash> object. The C<assert_HashObj>
function can be used to throw an exception if the argument can not be
validated. The C<is_HashObj> function can be used to return true or false if the
argument can not be validated.

=cut

=type HashObject

  has data => (
    is  => 'ro',
    isa => 'HashObject',
  );

The HashObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Hash> object. The
C<assert_HashObject> function can be used to throw an exception if the argument
can not be validated. The C<is_HashObject> function can be used to return true or
false if the argument can not be validated.

=cut

=type HashRef

  has data => (
    is  => 'ro',
    isa => 'HashRef',
  );

The HashRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_HashRef> function
can be used to throw an exception if the argument can not be validated. The
C<is_HashRef> function can be used to return true or false if the argument can not
be validated.

=cut

=type InstanceOf

  has data => (
    is  => 'ro',
    isa => 'InstanceOf[MyClass]',
  );

The InstanceOf type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_InstanceOf>
function can be used to throw an exception if the argument can not be
validated. The C<is_InstanceOf> function can be used to return true or false if
the argument can not be validated.

=cut

=type Int

  has data => (
    is  => 'ro',
    isa => 'Int',
  );

The Int type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Int> function can be
used to throw an exception if the argument can not be validated. The C<is_Int>
function can be used to return true or false if the argument can not be
validated.

=cut

=type IntObj

  has data => (
    is  => 'ro',
    isa => 'IntObj',
  );

The IntObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntObj> function can be used to throw an exception if the argument can
not be validated. The C<is_IntObj> function can be used to return true or false if
the argument can not be validated.

=cut

=type IntObject

  has data => (
    is  => 'ro',
    isa => 'IntObject',
  );

The IntObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntObject> function can be used to throw an exception if the argument can
not be validated. The C<is_IntObject> function can be used to return true or false
if the argument can not be validated.

=cut

=type IntRange

  has data => (
    is  => 'ro',
    isa => 'IntRange[0, 25]',
  );

The IntRange type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_IntRange> function can be
used to throw an exception if the argument can not be validated. The C<is_IntRange>
function can be used to return true or false if the argument can not be
validated.

=cut

=type IntegerObj

  has data => (
    is  => 'ro',
    isa => 'IntegerObj',
  );

The IntegerObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntegerObj> function can be used to throw an exception if the argument
can not be validated. The C<is_IntegerObj> function can be used to return true or
false if the argument can not be validated.

=cut

=type IntegerObject

  has data => (
    is  => 'ro',
    isa => 'IntegerObject',
  );

The IntegerObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Integer> object. The
C<assert_IntegerObject> function can be used to throw an exception if the argument
can not be validated. The C<is_IntegerObject> function can be used to return true
or false if the argument can not be validated.

=cut

=type Item

  has data => (
    is  => 'ro',
    isa => 'Item',
  );

The Item type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Item> function can be
used to throw an exception if the argument can not be validated. The C<is_Item>
function can be used to return true or false if the argument can not be
validated.

=cut

=type LaxNum

  has data => (
    is  => 'ro',
    isa => 'LaxNum',
  );

The LaxNum type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_LaxNum> function
can be used to throw an exception if the argument can not be validated. The
C<is_LaxNum> function can be used to return true or false if the argument can not
be validated.

=cut

=type LowerCaseSimpleStr

  has data => (
    is  => 'ro',
    isa => 'LowerCaseSimpleStr',
  );

The LowerCaseSimpleStr type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_LowerCaseSimpleStr> function can be used to throw an exception if the
argument can not be validated. The C<is_LowerCaseSimpleStr> function can be used
to return true or false if the argument can not be validated.
information.

=cut

=type LowerCaseStr

  has data => (
    is  => 'ro',
    isa => 'LowerCaseStr',
  );

The LowerCaseStr type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The C<assert_type>
function can be used to throw an exception if the argument can not be
validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.

=cut

=type Map

  has data => (
    is  => 'ro',
    isa => 'Map[Int, HashRef]',
  );

The Map type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Map> function can be
used to throw an exception if the argument can not be validated. The C<is_Map>
function can be used to return true or false if the argument can not be
validated.

=cut

=type Maybe

  has data => (
    is  => 'ro',
    isa => 'Maybe',
  );

The Maybe type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Maybe> function can be
used to throw an exception if the argument can not be validated. The C<is_Maybe>
function can be used to return true or false if the argument can not be
validated.

=cut

=type NegativeInt

  has data => (
    is  => 'ro',
    isa => 'NegativeInt',
  );

The NegativeInt type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_NegativeInt> function can be used to throw an exception if the argument
can not be validated. The C<is_NegativeInt> function can be used to return true or
false if the argument can not be validated.

=cut

=type NegativeNum

  has data => (
    is  => 'ro',
    isa => 'NegativeNum',
  );

The NegativeNum type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_NegativeNum> function can be used to throw an exception if the argument
can not be validated. The C<is_NegativeNum> function can be used to return true or
false if the argument can not be validated.

=cut

=type NegativeOrZeroInt

  has data => (
    is  => 'ro',
    isa => 'NegativeOrZeroInt',
  );

The NegativeOrZeroInt type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_NegativeOrZeroInt> function can be used to throw an exception if the
argument can not be validated. The C<is_NegativeOrZeroInt> function can be used to
return true or false if the argument can not be validated.
information.

=cut

=type NegativeOrZeroNum

  has data => (
    is  => 'ro',
    isa => 'NegativeOrZeroNum',
  );

The NegativeOrZeroNum type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

=cut

=type NonEmptySimpleStr

  has data => (
    is  => 'ro',
    isa => 'NonEmptySimpleStr',
  );

The NonEmptySimpleStr type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

=cut

=type NonEmptyStr

  has data => (
    is  => 'ro',
    isa => 'NonEmptyStr',
  );

The NonEmptyStr type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_type> function
can be used to throw an exception if the argument can not be validated. The
C<is_type> function can be used to return true or false if the argument can not be
validated.

=cut

=type Num

  has data => (
    is  => 'ro',
    isa => 'Num',
  );

The Num type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Num> function can be
used to throw an exception if the argument can not be validated. The C<is_Num>
function can be used to return true or false if the argument can not be
validated.

=cut

=type NumObj

  has data => (
    is  => 'ro',
    isa => 'NumObj',
  );

The NumObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumObj> function can be used to throw an exception if the argument can
not be validated. The C<is_NumObj> function can be used to return true or false if
the argument can not be validated.

=cut

=type NumObject

  has data => (
    is  => 'ro',
    isa => 'NumObject',
  );

The NumObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumObject> function can be used to throw an exception if the argument can
not be validated. The C<is_NumObject> function can be used to return true or false
if the argument can not be validated.

=cut

=type NumRange

  has data => (
    is  => 'ro',
    isa => 'NumRange[0, 25]',
  );

The NumRange type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_NumRange> function can be
used to throw an exception if the argument can not be validated. The C<is_NumRange>
function can be used to return true or false if the argument can not be
validated.

=cut

=type NumberObject

  has data => (
    is  => 'ro',
    isa => 'NumberObject',
  );

The NumberObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Number> object. The
C<assert_NumberObject> function can be used to throw an exception if the argument
can not be validated. The C<is_NumberObject> function can be used to return true
or false if the argument can not be validated.

=cut

=type NumericCode

  has data => (
    is  => 'ro',
    isa => 'NumericCode',
  );

The NumericCode type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_NumericCode> function can be used to throw an exception if the argument
can not be validated. The C<is_NumericCode> function can be used to return true or
false if the argument can not be validated.

=cut

=type Object

  has data => (
    is  => 'ro',
    isa => 'Object',
  );

The Object type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Object> function
can be used to throw an exception if the argument can not be validated. The
C<is_Object> function can be used to return true or false if the argument can not
be validated.

=cut

=type OptList

  has data => (
    is  => 'ro',
    isa => 'OptList',
  );

The OptList type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_OptList> function
can be used to throw an exception if the argument can not be validated. The
C<is_OptList> function can be used to return true or false if the argument can not
be validated.

=cut

=type Optional

  has data => (
    is  => 'ro',
    isa => 'Dict[id => Optional[Int]]',
  );

The Optional type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Optional>
function can be used to throw an exception if the argument can not be
validated. The C<is_Optional> function can be used to return true or false if the
argument can not be validated.

=cut

=type Overload

  has data => (
    is  => 'ro',
    isa => 'Overload',
  );

The Overload type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Overload>
function can be used to throw an exception if the argument can not be
validated. The C<is_Overload> function can be used to return true or false if the
argument can not be validated.

=cut

=type Password

  has data => (
    is  => 'ro',
    isa => 'Password',
  );

The Password type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_Password>
function can be used to throw an exception if the argument can not be
validated. The C<is_Password> function can be used to return true or false if the
argument can not be validated.

=cut

=type PositiveInt

  has data => (
    is  => 'ro',
    isa => 'PositiveInt',
  );

The PositiveInt type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_PositiveInt> function can be used to throw an exception if the argument
can not be validated. The C<is_PositiveInt> function can be used to return true or
false if the argument can not be validated.

=cut

=type PositiveNum

  has data => (
    is  => 'ro',
    isa => 'PositiveNum',
  );

The PositiveNum type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_PositiveNum> function can be used to throw an exception if the argument
can not be validated. The C<is_PositiveNum> function can be used to return true or
false if the argument can not be validated.

=cut

=type PositiveOrZeroInt

  has data => (
    is  => 'ro',
    isa => 'PositiveOrZeroInt',
  );

The PositiveOrZeroInt type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_PositiveOrZeroInt> function can be used to throw an exception if the
argument can not be validated. The C<is_PositiveOrZeroInt> function can be used to
return true or false if the argument can not be validated.
information.

=cut

=type PositiveOrZeroNum

  has data => (
    is  => 'ro',
    isa => 'PositiveOrZeroNum',
  );

The PositiveOrZeroNum type constraint is provided by the
L<Types::Common::Numeric> library. Please see that documentation for more The
C<assert_type> function can be used to throw an exception if the argument can not
be validated. The C<is_type> function can be used to return true or false if the
argument can not be validated.
information.

=cut

=type Ref

  has data => (
    is  => 'ro',
    isa => 'Ref[SCALAR]',
  );

The Ref type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_type> function can be
used to throw an exception if the argument can not be validated. The C<is_type>
function can be used to return true or false if the argument can not be
validated.

=cut

=type RegexpObj

  has data => (
    is  => 'ro',
    isa => 'RegexpObj',
  );

The RegexpObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Regexp> object. The
C<assert_RegexpObj> function can be used to throw an exception if the argument can
not be validated. The C<is_RegexpObj> function can be used to return true or false
if the argument can not be validated.

=cut

=type RegexpObject

  has data => (
    is  => 'ro',
    isa => 'RegexpObject',
  );

The RegexpObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Regexp> object. The
C<assert_RegexpObject> function can be used to throw an exception if the argument
can not be validated. The C<is_RegexpObject> function can be used to return true
or false if the argument can not be validated.

=cut

=type RegexpRef

  has data => (
    is  => 'ro',
    isa => 'RegexpRef',
  );

The RegexpRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_RegexpRef>
function can be used to throw an exception if the argument can not be
validated. The C<is_RegexpRef> function can be used to return true or false if the
argument can not be validated.

=cut

=type ReplaceObj

  has data => (
    is  => 'ro',
    isa => 'ReplaceObj',
  );

The ReplaceObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Replace> object. The
C<assert_ReplaceObj> function can be used to throw an exception if the argument
can not be validated. The C<is_ReplaceObj> function can be used to return true
or false if the argument can not be validated.

=cut

=type ReplaceObject

  has data => (
    is  => 'ro',
    isa => 'ReplaceObject',
  );

The ReplaceObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Replace> object. The
C<assert_ReplaceObject> function can be used to throw an exception if the
argument can not be validated. The C<is_ReplaceObject> function can be used to
return true or false if the argument can not be validated.

=cut

=type RoleName

  has data => (
    is  => 'ro',
    isa => 'RoleName',
  );

The RoleName type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_RoleName>
function can be used to throw an exception if the argument can not be
validated. The C<is_RoleName> function can be used to return true or false if the
argument can not be validated.

=cut

=type ScalarObj

  has data => (
    is  => 'ro',
    isa => 'ScalarObj',
  );

The ScalarObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Scalar> object. The
C<assert_ScalarObj> function can be used to throw an exception if the argument can
not be validated. The C<is_ScalarObj> function can be used to return true or false
if the argument can not be validated.

=cut

=type ScalarObject

  has data => (
    is  => 'ro',
    isa => 'ScalarObject',
  );

The ScalarObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Scalar> object. The
C<assert_ScalarObject> function can be used to throw an exception if the argument
can not be validated. The C<is_ScalarObject> function can be used to return true
or false if the argument can not be validated.

=cut

=type ScalarRef

  has data => (
    is  => 'ro',
    isa => 'ScalarRef',
  );

The ScalarRef type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_ScalarRef>
function can be used to throw an exception if the argument can not be
validated. The C<is_ScalarRef> function can be used to return true or false if the
argument can not be validated.

=cut

=type SearchObj

  has data => (
    is  => 'ro',
    isa => 'SearchObj',
  );

The SearchObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Search> object. The
C<assert_SearchObj> function can be used to throw an exception if the argument
can not be validated. The C<is_SearchObj> function can be used to return true
or false if the argument can not be validated.

=cut

=type SearchObject

  has data => (
    is  => 'ro',
    isa => 'SearchObject',
  );

The SearchObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Search> object. The
C<assert_SearchObject> function can be used to throw an exception if the
argument can not be validated. The C<is_SearchObject> function can be used to
return true or false if the argument can not be validated.

=cut

=type SimpleStr

  has data => (
    is  => 'ro',
    isa => 'SimpleStr',
  );

The SimpleStr type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_SimpleStr> function can be used to throw an exception if the argument can
not be validated. The C<is_SimpleStr> function can be used to return true or false
if the argument can not be validated.

=cut

=type SingleDigit

  has data => (
    is  => 'ro',
    isa => 'SingleDigit',
  );

The SingleDigit type constraint is provided by the L<Types::Common::Numeric>
library. Please see that documentation for more information. The
C<assert_SingleDigit> function can be used to throw an exception if the argument
can not be validated. The C<is_SingleDigit> function can be used to return true or
false if the argument can not be validated.

=cut

=type SpaceObj

  has data => (
    is  => 'ro',
    isa => 'SpaceObj',
  );

The SpaceObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Space> object. The
C<assert_SpaceObj> function can be used to throw an exception if the argument
can not be validated. The C<is_SpaceObj> function can be used to return true or
false if the argument can not be validated.

=cut

=type SpaceObject

  has data => (
    is  => 'ro',
    isa => 'SpaceObject',
  );

The SpaceObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Space> object. The
C<assert_SpaceObject> function can be used to throw an exception if the
argument can not be validated. The C<is_SpaceObject> function can be used to
return true or false if the argument can not be validated.

=cut

=type Str

  has data => (
    is  => 'ro',
    isa => 'Str',
  );

The Str type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Str> function can be
used to throw an exception if the argument can not be validated. The C<is_Str>
function can be used to return true or false if the argument can not be
validated.

=cut

=type StrMatch

  has data => (
    is  => 'ro',
    isa => 'StrMatch',
  );

The StrMatch type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_StrMatch>
function can be used to throw an exception if the argument can not be
validated. The C<is_StrMatch> function can be used to return true or false if the
argument can not be validated.

=cut

=type StrObj

  has data => (
    is  => 'ro',
    isa => 'StrObj',
  );

The StrObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StrObj> function can be used to throw an exception if the argument can
not be validated. The C<is_StrObj> function can be used to return true or false if
the argument can not be validated.

=cut

=type StrObject

  has data => (
    is  => 'ro',
    isa => 'StrObject',
  );

The StrObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StrObject> function can be used to throw an exception if the argument can
not be validated. The C<is_StrObject> function can be used to return true or false
if the argument can not be validated.

=cut

=type StrictNum

  has data => (
    is  => 'ro',
    isa => 'StrictNum',
  );

The StrictNum type constraint is provided by the L<Types::Standard> library.
Please see that documentation for more information. The C<assert_StrictNum>
function can be used to throw an exception if the argument can not be
validated. The C<is_StrictNum> function can be used to return true or false if the
argument can not be validated.

=cut

=type StringLike

  has data => (
    is  => 'ro',
    isa => 'StringLike',
  );

The StringLike type constraint is provided by the L<Types::TypeTiny> library.
Please see that documentation for more information. The C<assert_StringLike>
function can be used to throw an exception if the argument can not be
validated. The C<is_StringLike> function can be used to return true or false if
the argument can not be validated.

=cut

=type StringObj

  has data => (
    is  => 'ro',
    isa => 'StringObj',
  );

The StringObj type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StringObj> function can be used to throw an exception if the argument can
not be validated. The C<is_StringObj> function can be used to return true or false
if the argument can not be validated.

=cut

=type StringObject

  has data => (
    is  => 'ro',
    isa => 'StringObject',
  );

The StringObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::String> object. The
C<assert_StringObject> function can be used to throw an exception if the argument
can not be validated. The C<is_StringObject> function can be used to return true
or false if the argument can not be validated.

=cut

=type StrongPassword

  has data => (
    is  => 'ro',
    isa => 'StrongPassword',
  );

The StrongPassword type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_StrongPassword> function can be used to throw an exception if the
argument can not be validated. The C<is_StrongPassword> function can be used to
return true or false if the argument can not be validated.

=cut

=type Tied

  has data => (
    is  => 'ro',
    isa => 'Tied[MyClass]',
  );

The Tied type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Tied> function can be
used to throw an exception if the argument can not be validated. The C<is_Tied>
function can be used to return true or false if the argument can not be
validated.

=cut

=type Tuple

  has data => (
    is  => 'ro',
    isa => 'Tuple[Int, Str, Str]',
  );

The Tuple type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Tuple> function can be
used to throw an exception if the argument can not be validated. The C<is_Tuple>
function can be used to return true or false if the argument can not be
validated.

=cut

=type TypeTiny

  has data => (
    is  => 'ro',
    isa => 'TypeTiny',
  );

The TypeTiny type constraint is provided by the L<Types::TypeTiny> library. Please
see that documentation for more information. The C<assert_TypeTiny> function can be
used to throw an exception if the argument can not be validated. The C<is_TypeTiny>
function can be used to return true or false if the argument can not be
validated.

=cut

=type Undef

  has data => (
    is  => 'ro',
    isa => 'Undef',
  );

The Undef type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Undef> function can be
used to throw an exception if the argument can not be validated. The C<is_Undef>
function can be used to return true or false if the argument can not be
validated.

=cut

=type UndefObj

  has data => (
    is  => 'ro',
    isa => 'UndefObj',
  );

The UndefObj type constraint is provided by this library and accepts any object
that is, or is derived from, a L<Data::Object::Undef> object. The
C<assert_UndefObj> function can be used to throw an exception if the argument can
not be validated. The C<is_UndefObj> function can be used to return true or false
if the argument can not be validated.

=cut

=type UndefObject

  has data => (
    is  => 'ro',
    isa => 'UndefObject',
  );

The UndefObject type constraint is provided by this library and accepts any
object that is, or is derived from, a L<Data::Object::Undef> object. The
C<assert_UndefObject> function can be used to throw an exception if the argument
can not be validated. The C<is_UndefObject> function can be used to return true or
false if the argument can not be validated.

=cut

=type UpperCaseSimpleStr

  has data => (
    is  => 'ro',
    isa => 'UpperCaseSimpleStr',
  );

The UpperCaseSimpleStr type constraint is provided by the
L<Types::Common::String> library. Please see that documentation for more The
C<assert_UpperCaseSimpleStr> function can be used to throw an exception if the
argument can not be validated. The C<is_UpperCaseSimpleStr> function can be used
to return true or false if the argument can not be validated.
information.

=cut

=type UpperCaseStr

  has data => (
    is  => 'ro',
    isa => 'UpperCaseStr',
  );

The UpperCaseStr type constraint is provided by the L<Types::Common::String>
library. Please see that documentation for more information. The
C<assert_UpperCaseStr> function can be used to throw an exception if the
argument can not be validated. The C<is_UpperCaseStr> function can be used to
return true or false if the argument can not be validated.

=cut

=type Value

  has data => (
    is  => 'ro',
    isa => 'Value',
  );

The Value type constraint is provided by the L<Types::Standard> library. Please
see that documentation for more information. The C<assert_Value> function can be
used to throw an exception if the argument can not be validated. The C<is_Value>
function can be used to return true or false if the argument can not be
validated.

=cut

# TESTING

use_ok 'Data::Object::Library';

ok 1 and done_testing;

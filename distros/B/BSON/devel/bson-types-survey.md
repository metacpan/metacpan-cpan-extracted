# BSON LEGACY TYPE SURVEY

**NOTE**: This document refers to classes from BSON.pm version 0.16, before
changes implemented in response to this study.  It is preserved in the
repository for historical reference only.

## Description

This document maps BSON types from the [BSON
specification](http://bsonspec.org/spec.html) to Perl classes that
correspond to each type.  This document refers to such classes as "BSON
type classes" or just "type classes".

The goal of this document is to provide a foundation to determine a way to
unify the different BSON type classes.  For each type and class, it
indicates whether the mapping is one-way or two-way.  The public API of the
different classes is noted as well.

Broadly speaking, many type classes are drawn from the
[BSON](http://p3rl.org/BSON), [MongoDB](http://p3rl.org/MongoDB) and
[Mango](http://p3rl.org/Mango) Perl distributions.  Other CPAN modules serve as
type classes in a codec-specific manner.

The BSON types are named according to their libbson terms with their
hexadecimal code noted.  Additional pseudo-types are noted at the end.

# `0x01 BSON_TYPE_DOUBLE`

`BSON_TYPE_DOUBLE` is serialized and deserialized directly via native Perl
floating point (NV types) variables.

No BSON type classes exist specifically for doubles, but see
`BSON_TYPE_INT32` and Mango::BSON::Number, which can be used to force
double interpretation.

# `0x02 BSON_TYPE_UTF8`

`BSON_TYPE_UTF8` is deserialized to native Perl strings (PV type).
Serialization is codec dependent: as Perl scalars may have dual
string/numeric representation, codecs may choose to encode scalars as a
numeric BSON type or as a `BSON_TYPE_UTF8`.

The following type classes exist to ensure `BSON_TYPE_UTF8` encoding:

### MongoDB::BSON::String

    my $obj = bless \$string, "MongoDB::BSON::String";

This class has no module and no methods.  Users must manually bless a
string reference into this class.

### BSON::String

    $obj = BSON::String->new( $string );

This class has the following methods:

* new
* value

Only string overloading is supported, returning the `value` method.

It is implemented as a hash reference `{ value => $string }`.

# `0x03 BSON_TYPE_DOCUMENT`

`BSON_TYPE_DOCUMENT` corresponds closely to a native Perl hash reference, with
the following exceptions:

* BSON documents are ordered and Perl hash references are not
* On decoding, the presence of special keys in a `BSON_TYPE_DOCUMENT`
  signal a `DBREF`.  However, not all codecs need respect this.
* On encoding, special keys may or may not be legal.  In Mango, a `$raw`
  key indicates a `RAW` BSON string.

All known codecs will serialize a Perl hash reference (or tied hash) to a
`BSON_TYPE_DOCUMENT`.  Deserialization is as follows:

* Mango will deserialize to a `Mango::BSON::Document`.
* BSON.pm will deserialize to a Perl hash reference (default) or a
  `Tie::IxHash` object based on an option flag.
* MongoDB will currently deserialize only to a Perl hash reference.

The following type classes exist:

### Tie::IxHash

This implements an ordered tied hash interface and has other supporting
methods.  It is extremely slow.  Hash::Ordered has been written as a
potential replacement but it not yet supported by anything.

### Mango::BSON::Document

This implements an extremely limited tied hash API.  It is slow.

# `0x04 BSON_TYPE_ARRAY`

`BSON_TYPE_ARRAY` is serialized and deserialized directly via native Perl
array references (AV type).

# `0x05 BSON_TYPE_BINARY`

`BSON_TYPE_BINARY` is usually implemented via a BSON type class, but the
MongoDB driver will treat a blessed scalar reference as `SUBTYPE_GENERIC`
boolean data.  All codecs decode into their respective BSON type class.

The following type classes exist:

### MongoDB::BSON::Binary

    $obj = MongoDB::BSON::Binary->new( data => $data, subtype => $subtype);

Subtype defaults to `SUBTYPE_GENERIC`.  It provides unexported constants
for all known types.

This class has the following methods:

* `data` – accessor
* `subtype` – accessor

It implements string overloading that returns `data` plus fallbacks.

It is implemented as a Moo class.

### BSON::Binary

    $obj = BSON::Binary->new( $data, $subtype );

This class has the following methods:

* new – subtype defaults to `SUBTYPE_GENERIC`
* data – returns an *array reference* to bytes (oy!); also read-write (oy!)
* type – returns the subtype
* to_s – returns the data as a BSON fragment (based on the data method, so
  horribly inefficient); also undocumented

It is implemented as a hash reference.  The `$data` given to new is split
into a new `data` element (array reference).  String overloading maps to
the `to_s` function.

### Mango::BSON::Binary

    $obj = Mango::BSON::Binary->new( data => $data, type => $subtype);

Subtype defaults to 'generic'.  Subtypes are implemented as strings rather
than numbers.

It implements a `TO_JSON` method.  It implements string overloading to
return Base64 encoded binary data, plus a fallback.

It is implemented as a Mojo::Base class.

# `0x06 BSON_TYPE_UNDEFINED`

This BSON type is deprecated.  Decoding it is fatal in BSON.pm and
Mango::BSON.  It decodes to `undef` in MongoDB.

# `0x07 BSON_TYPE_OID`

`BSON_TYPE_OID` is always implemented via a BSON type class.  Each codec
implementation has its own OID type class.  These classes also maintain a
counter to generate OIDs as needed.

The following type classes exist:

### MongoDB::OID

    my $id1 = MongoDB::OID->new;
    my $id2 = MongoDB::OID->new(value => $id1->value);
    my $id3 = MongoDB::OID->new($id1->value);
    my $id4 = MongoDB::OID->new($id1);

The class has the following methods:

* `new` – this generates an ID with no arguments, or takes a key/value pair
  or a single value or another object.  The value must be a 24-digit
  hexadecimal string.
* `value` – (accessor) returns the value as a 24-digit hexadecimal string.
* `to_string` – same as `value`
* `get_time` – returns integer value of timestamp portion of OID
* `TO_JSON` – returns hash reference with extended JSON representation of
  an OID
* `_get_pid` –  returns integer value of PID portion of OID

String overloading with fallback is provided.

It is implemented as a Moo class with a single 'value' attribute.

### BSON::ObjectId

    my $oid  = BSON::ObjectId->new;
    my $oid2 = BSON::ObjectId->new($string);
    my $oid3 = BSON::ObjectId->new($binary_string);

The class has the following methods:

* `new` – takes nothing or else a 12 byte binary value or 24 byte
  hexadecimal value
* `value` - (r/w accessor) takes 24 byte or 12 byte, always returns 12
  bytes
* `is_legal` – class method to check for a 24-byte hex string
* `to_s` – returns 24 byte hexadecimal string
* `op_eq` – used to implement equality overloading
* `_from_s` – helper to convert 24 byte hex string to 12 byte packed value

String overloading and equality overloading is provided.

It is implemented as a blessed hashref with a packed (binary) 'value'
element.

### Mango::BSON::ObjectID

    my $oid = Mango::BSON::ObjectID->new('1a2b3c4e5f60718293a4b5c6');

The class has the following methods:

* `new` – takes nothing or a 24 bytes hexadecimal string
* `from_epoch` – modifies object to have an OID of the given epoch
* `to_bytes` - returns binary OID (or generates lazily)
* `to_epoch` – returns epoch seconds from OID
* `to_string` – returns 24 byte hex string

Overloading is provided for string and boolean, with fallback.

It is implemented as a Mojo::Base class with a private 'oid' attributes, which is
a binary OID.

# `0x08 BSON_TYPE_BOOL`

`BSON_TYPE_BOOL` is implemented using various type classes, often involving
the many boolean class implementations on CPAN.

The MongoDB Perl driver deserializes to the
[boolean](http://p3rl.org/boolean) class.  It serializes the most popular
boolean classes: 

* [boolean](http://p3rl.org/boolean)
* [JSON::XS::Boolean](http://p3rl.org/JSON::XS::Boolean)
* [JSON::PP::Boolean](http://p3rl.org/JSON::PP::Boolean)
* [JSON::Tiny::_Bool](http://p3rl.org/JSON::Tiny::_Bool)
* [Mojo::JSON::_Bool](http://p3rl.org/Mojo::JSON::_Bool)
* [Cpanel::JSON::XS::Boolean](http://p3rl.org/Cpanel::JSON::XS::Boolean)
* [Types::Serialiser::Boolean](http://p3rl.org/Types::Serialiser::Boolean)

The Mango::BSON codec deserializes to `Mojo::JSON::_Bool`  It serializes
Mojo::JSON, but also *any* reference to a SCALAR is treated as if it were
a `Mojo::JSON::_Bool` object.  That should work with most other boolean
types, as they all use similar internal structure.

BSON.pm only serializes to/from BSON::Bool:

### BSON::Bool

    my $true  = BSON::Bool->true;
    my $false = BSON::Bool->false;
    my $odd   = BSON::Bool->new( time % 2 )

The class has the following methods:

* `new` – take a single argument
* `true` – alternate constructor
* `false` – alternate constructor
* `value` – returns 0 or 1
* `op_eq` – implements equality

Overloads boolean and equality operators.

It is implemented as a hash reference with a 'value' element.  (N.B. This
will *not* be treated as a boolean object by Mango.)

# `0x09 BSON_TYPE_DATE_TIME`

`BSON_TYPE_DATE_TIME` is implemented with type classes.  Codecs vary on
whether they use established CPAN modules or provide their own.

The MongoDB Perl driver deserializes by default to
[DateTime](http://p3rl.org/DateTime).  Other supported deserializations
include:

* [DateTime::Tiny](http://p3rl.org/DateTime::Tiny) 
* [Time::Moment](http://p3rl.org/Time::Moment) 
* epoch seconds (if dt_type is undef)

The BSON.pm and Mango codecs only serialize/deserialize to their respective
type classes:

### BSON::Time

    my $dt = BSON::Time->new( $epoch );

This class has the following methods:

* `new` – takes no args or a single epoch second argument
* `value` – stored time in milliseconds (r/w accessor)
* `epoch` – stored time in seconds
* `op_eq` – implements equality for overloading

Overloads equality and stringifiction.

It is implemented as a hash reference with a 'value' element.

### Mango::BSON::Time

    my $time = Mango::BSON::Time->new(time * 1000);

The class has the following methods:

* `new` – no args or time in milliseconds since the epoch
* `TO_JSON` – numeric milliseconds
* `to_datetime` – RFC 3339 date and time (via Mojo::Date)
* `to_epoch` – floating epoch seconds
* `to_string` – string (milliseconds)

Overloads bool, stringification, and fallback.

It is implemented as a Mojo::Base class with a private 'time' element.

# `0x0A BSON_TYPE_NULL`

`BSON_TYPE_NULL` is serialized and deserialized directly via native
Perl `undef` (SV type) in all codecs.

# `0x0B BSON_TYPE_REGEX`

`BSON_TYPE_REGEX` is implemented either natively or by a type class,
depending on the codec.

Both BSON.pm and Mango serializes/deserialize to native Perl regular
expression references.

The MongoDB Perl driver always deserializes to a MongoDB::BSON::Regexp
object for security reasons.  It serializes that and native qr references.

### MongoDB::BSON::Regexp

    my $obj = MongoDB::BSON::Regexp->new(pattern => $p, flags => $f);

The class has the following methods:

* `new`
* `pattern` – accessor
* `flags` – accessor
* `try_compile` – attempt to create a regexp reference

It is implemented as a Moo class.

# `0x0C BSON_TYPE_DBPOINTER`

This BSON type is deprecated.  Decoding it is fatal in all three
implementations.

# `0x0D BSON_TYPE_CODE`

`BSON_TYPE_CODE` is implemented via type classes in all codecs.  The same
classes are used for `BSON_TYPE_CODEWSCOPE` and are documented here.

Type classes include:

### MongoDB::Code

    my $obj = MongoDB::Code->(code => $string, scope => $hashref);

This class has the following methods:

* `new`
* `code` – accessor
* `scope` – accessor

It is implemented as a Moo object.

### BSON::Code

    my $obj = BSON::Code->($string, $hashref);

This class has the following methods:

* `new`
* `code` – accessor
* `scope` – accessor
* `length` – length of the `code` attribute

It is implemented as a hash reference with 'code' and 'scope' attributes.

### Mango::BSON::Code

    my $obj = Mango::BSON::Code->(code => $string, scope => $hashref);

This class has the following methods:

* `code` – accessor
* `scope` – accessor

It is implemented as a Mojo::Base object.

# `0x0E BSON_TYPE_SYMBOL`

This BSON type is deprecated.  BSON.pm and MongoDB decode it to
a UTF-8 string.  It is fatal in Mango::BSON.

# `0x0F BSON_TYPE_CODEWSCOPE`

See `BSON_TYPE_CODE`.

# `0x10 BSON_TYPE_INT32`

`BSON_TYPE_INT32` is deserialized as a native Perl integer (IV type).
Serialization is codec dependent: as Perl scalars may have dual
string/numeric representation, codecs may choose to encode scalars as a
numeric BSON type or as a `BSON_TYPE_UTF8`.

When numeric serialization proceeds, all three codecs serialize integers
that fit in 32 bits to `BSON_TYPE_INT32`.

Mango uses a type class for representing numbers unambiguously:

### Mango::BSON::Number

    my $number = Mango::BSON::Number->new(666, Mango::BSON::INT64);

This class has the following methods:

* `new`
* `value`
* `type` - one of various constants
* `TO_JSON` - numeric value
* `to_string` – string value
* `isa_number` – a function, not a method; determines if a value is a
  number or a string based on Perl's internal SV flags
* `guess_type` – a function, not a method; chooses a BSON type for a
  numeric value (double, int32, int64)

It overloads string and boolean operators.

It is implemented as a Mojo::Base class.

# `0x11 BSON_TYPE_TIMESTAMP`

`BSON_TYPE_TIMESTAMP` is implemented with type classes specific to each
codec implementation.

### MongoDB::Timestamp

    my $obj = MongoDB::Timestamp->new( sec => $sec, inc => $inc );

This class has the following methods:

* `new`
* `sec` – accessor
* `inc` – accessor

It is implemented as a Moo class.

### BSON::Timestamp

    my $obj = BSON::Timestamp->new( $sec, $inc );

This class has the following methods:

* `new`
* `seconds` – r/w accessor
* `increment` – r/w accessor

It is implemented as a hash reference with 'increment' and 'seconds'
fields.

### Mango::BSON::Timestamp

    my $ts = Mango::BSON::Timestamp->new(seconds => 23, increment => 5);

This class has the following methods:

* `new`
* `seconds` – r/w accessor
* `increment` – r/w accessor

It is implemented as a Mojo::Base class.

# `0x12 BSON_TYPE_INT64`

`BSON_TYPE_INT64` is generally implemented using native Perl integers (IV
type) on 64-bit platforms, but for compatibility on 32-bit platforms or to
force 64-bit representation during serialization, codecs support various
type classes from CPAN.

* MongoDB: [Math::BigInt](http://p3rl.org/Math::BigInt) always serializes
  to `BSON_TYPE_INT64`.  It is used to deserialize `BSON_TYPE_INT64` on
  32-bit platforms.
* BSON.pm: (undocumented!) [Math::Int64](http://p3rl.org/Math::Int64)
  (*NOT pure perl*) serializes to `BSON_TYPE_INT64`. Deserialization
  returns a Math::Int64 object on 32-bit platforms.
* Mango always deserializes to a native Perl integer (and won't work on a
  Perl without 64-bit integers).  Mango::BSON::Number can be used to
  explicitly serialize a 64-bit number.

See `BSON_TYPE_INT32` for more on Mango::BSON::Number.

# `0x7F BSON_TYPE_MAXKEY`

`BSON_TYPE_MAXKEY` is implemented with type classes specific to each codec
implementation.

### MongoDB::MaxKey

    bless {}, 'MongoDB::MaxKey';

This class has no module and no methods.  Users must manually bless a
reference (of any sort) into this class.

### BSON::MaxKey

    my $obj = BSON::MaxKey->new;

This class has no methods other than a constructor.

### Mango::BSON::_MaxKey

    bless {}, 'Mango::BSON::_MaxKey';

This class has no module and no methods.  A helper method is provided
by Mango::BSON to return a singleton.

# `0xFF BSON_TYPE_MINKEY`

`BSON_TYPE_MINKEY` is implemented with type classes specific to each codec
implementation.

### MongoDB::MinKey

    bless {}, 'MongoDB::MinKey';

This class has no module and no methods.  Users must manually bless a
reference (of any sort) into this class.

### BSON::MinKey

    my $obj = BSON::MinKey->new;

This class has no methods other than a constructor.

### Mango::BSON::_MinKey

    bless {}, 'Mango::BSON::_MinKey';

This class has no module and no methods.  A helper method is provided
by Mango::BSON to return a singleton.

# `DBREF`

DBRefs are special documents that refer to another document.  They are
discouraged, but still supported by many drivers.  They must have '$id' and
'$ref' fields and may have a '$db' field.

This is implemented for the MongoDB perl driver as
[MongoDB::DBRef](http://p3rl.org/MongoDB::DBRef) and the MongoDB codec uses
a [callback](https://metacpan.org/pod/MongoDB::BSON#dbref_callback) to
control deserialization.

# `RAW`

Some codecs support serializing a 'raw' object, which contains a document
already serialized to BSON.

MongoDB uses a virtual MongoDB::BSON::Raw class, which is a manually
blessed scalar reference.

Mango uses a hash reference with a '$raw' document key.

# `UNSUPPORTED`

Deserializing unknown BSON types is fatal in all codecs:

* MongoDB dies with "type %d not supported"
* BSON.pm dies with "Unsupported type $type" (integer)
* Mango::BSON dies with "Unknown BSON type"


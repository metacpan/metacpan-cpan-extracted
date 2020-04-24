use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object

=cut

=abstract

Object-Orientation for Perl 5

=cut

=includes

function: Args
function: Array
function: Boolean
function: Box
function: Code
function: Data
function: Error
function: False
function: Float
function: Hash
function: Name
function: Number
function: Opts
function: Regexp
function: Scalar
function: Space
function: String
function: Struct
function: True
function: Undef
function: Vars

=cut

=synopsis

  package main;

  use Data::Object;

  my $array = Array [1..4];

  # my $iterator = $array->iterator;

  # $iterator->next; # 1

=cut

=description

This package automatically exports and provides constructor functions for
creating chainable data type objects from raw Perl data types.

=cut

=libraries

Data::Object::Types

=cut

=function Args

The Args function returns a L<Data::Object::Args> object.

=signature Args

Args(HashRef $data) : InstanceOf["Data::Object::Args"]

=example-1 Args

  package main;

  use Data::Object 'Args';

  my $args = Args; # [...]

=example-2 Args

  package main;

  my $args = Args {
    subcommand => 0
  };

  # $args->subcommand;

=cut

=function Array

The Array function returns a L<Data::Object::Box> which wraps a
L<Data::Object::Array> object.

=signature Array

Array(ArrayRef $data) : InstanceOf["Data::Object::Box"]

=example-1 Array

  package main;

  my $array = Array; # []

=example-2 Array

  package main;

  my $array = Array [1..4];

=cut

=function Boolean

The Boolean function returns a L<Data::Object::Boolean> object representing a
true or false value.

=signature Boolean

Boolean(Bool $data) : BooleanObject

=example-1 Boolean

  package main;

  my $boolean = Boolean;

=example-2 Boolean

  package main;

  my $boolean = Boolean 0;

=cut

=function Box

The Box function returns a L<Data::Object::Box> object representing a data type
object which is automatically deduced.

=signature Box

Box(Any $data) : InstanceOf["Data::Object::Box"]

=example-1 Box

  package main;

  my $box = Box;

=example-2 Box

  package main;

  my $box = Box 123;

=example-3 Box

  package main;

  my $box = Box [1..4];

=example-4 Box

  package main;

  my $box = Box {1..4};

=cut

=function Code

The Code function returns a L<Data::Object::Box> which wraps a
L<Data::Object::Code> object.

=signature Code

Code(CodeRef $data) : InstanceOf["Data::Object::Box"]

=example-1 Code

  package main;

  my $code = Code;

=example-2 Code

  package main;

  my $code = Code sub { shift };

=cut

=function Data

The Data function returns a L<Data::Object::Data> object.

=signature Data

Data(Str $file) : InstanceOf["Data::Object::Data"]

=example-1 Data

  package main;

  use Data::Object 'Data';

  my $data = Data;

=example-2 Data

  package main;

  my $data = Data 't/Data_Object.t';

  # $data->contents(...);

=cut

=function Error

The Error function returns a L<Data::Object::Exception> object.

=signature Error

Error(Str | HashRef) : InstanceOf["Data::Object::Exception"]

=example-1 Error

  package main;

  use Data::Object 'Error';

  my $error = Error;

  # die $error;

=example-2 Error

  package main;

  my $error = Error 'Oops!';

  # die $error;

=example-3 Error

  package main;

  my $error = Error {
    message => 'Oops!',
    context => { time => time }
  };

  # die $error;

=cut

=function False

The False function returns a L<Data::Object::Boolean> object representing a
false value.

=signature False

False() : BooleanObject

=example-1 False

  package main;

  my $false = False;

=cut

=function Float

The Float function returns a L<Data::Object::Box> which wraps a
L<Data::Object::Float> object.

=signature Float

Float(Num $data) : InstanceOf["Data::Object::Box"]

=example-1 Float

  package main;

  my $float = Float;

=example-2 Float

  package main;

  my $float = Float '0.0';

=cut

=function Hash

The Hash function returns a L<Data::Object::Box> which wraps a
L<Data::Object::Hash> object.

=signature Hash

Hash(HashRef $data) : InstanceOf["Data::Object::Box"]

=example-1 Hash

  package main;

  my $hash = Hash;

=example-2 Hash

  package main;

  my $hash = Hash {1..4};

=cut

=function Name

The Name function returns a L<Name::Object::Name> object.

=signature Name

Name(Str $data) : InstanceOf["Data::Object::Name"]

=example-1 Name

  package main;

  use Data::Object 'Name';

  my $name = Name 'Example Title';

  # $name->package;

=cut

=function Number

The Number function returns a L<Data::Object::Box> which wraps a
L<Data::Object::Number> object.

=signature Number

Number(Num $data) : InstanceOf["Data::Object::Box"]

=example-1 Number

  package main;

  my $number = Number;

=example-2 Number

  package main;

  my $number = Number 123;

=cut

=function Opts

The Opts function returns a L<Data::Object::Opts> object.

=signature Opts

Opts(HashRef $data) : InstanceOf["Data::Object::Opts"]

=example-1 Opts

  package main;

  use Data::Object 'Opts';

  my $opts = Opts;

=example-2 Opts

  package main;

  my $opts = Opts {
    spec => ['files|f=s']
  };

  # $opts->files; [...]

=cut

=function Regexp

The Regexp function returns a L<Data::Object::Box> which wraps a
L<Data::Object::Regexp> object.

=signature Regexp

Regexp(RegexpRef $data) : InstanceOf["Data::Object::Box"]

=example-1 Regexp

  package main;

  my $regexp = Regexp;

=example-2 Regexp

  package main;

  my $regexp = Regexp qr/.*/;

=cut

=function Space

The Space function returns a L<Data::Object::Space> object.

=signature Space

Space(Str $data) : InstanceOf["Data::Object::Space"]

=example-1 Space

  package main;

  use Data::Object 'Space';

  my $space = Space 'Example Namespace';

=cut

=function Scalar

The Scalar function returns a L<Data::Object::Box> which wraps a
L<Data::Object::Scalar> object.

=signature Scalar

Scalar(Ref $data) : InstanceOf["Data::Object::Box"]

=example-1 Scalar

  package main;

  my $scalar = Scalar;

=example-2 Scalar

  package main;

  my $scalar = Scalar \*main;

=cut

=function Struct

The Struct function returns a L<Data::Object::Struct> object.

=signature Struct

Struct(HashRef $data) : InstanceOf["Data::Object::Struct"]

=example-1 Struct

  package main;

  use Data::Object 'Struct';

  my $struct = Struct;

=example-2 Struct

  package main;

  my $struct = Struct {
    name => 'example',
    time => time
  };

=cut

=function String

The String function returns a L<Data::Object::Box> which wraps a
L<Data::Object::String> object.

=signature String

String(Str $data) : InstanceOf["Data::Object::Box"]

=example-1 String

  package main;

  my $string = String;

=example-2 String

  package main;

  my $string = String 'abc';

=cut

=function True

The True function returns a L<Data::Object::Boolean> object representing a true
value.

=signature True

True() : BooleanObject

=example-1 True

  package main;

  my $true = True;

=cut

=function Undef

The Undef function returns a L<Data::Object::Undef> object representing the
I<undefined> value.

=signature Undef

Undef() : InstanceOf["Data::Object::Box"]

=example-1 Undef

  package main;

  my $undef = Undef;

=cut

=function Vars

The Vars function returns a L<Data::Object::Vars> object representing the
available environment variables.

=signature Vars

Vars() : InstanceOf["Data::Object::Vars"]

=example-1 Vars

  package main;

  use Data::Object 'Vars';

  my $vars = Vars;

=example-2 Vars

  package main;

  my $vars = Vars {
    user => 'USER'
  };

  # $vars->user; # $USER

=cut

package main;

my $subs = testauto(__FILE__);

$subs->package;
$subs->document;
$subs->libraries;
$subs->inherits;
$subs->attributes;
$subs->types;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Array');
  is_deeply $result->source, [1..4];

  $result
});

$subs->example(-1, 'Array', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Array');
  is_deeply $result->source, [];

  $result
});

$subs->example(-2, 'Array', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Array');
  is_deeply $result->source, [1..4];

  $result
});

$subs->example(-1, 'Boolean', 'function', fun($tryable) {
  ok !(my $result = $tryable->result);
  ok $result->isa('Data::Object::Boolean');
  is $$result, 0;

  $result
});

$subs->example(-2, 'Boolean', 'function', fun($tryable) {
  ok !(my $result = $tryable->result);
  ok $result->isa('Data::Object::Boolean');
  is $$result, 0;

  $result
});

$subs->example(-1, 'Box', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Undef');
  is ${$result->source}, undef;

  $result
});

$subs->example(-2, 'Box', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Number');
  is ${$result->source}, 123;

  $result
});

$subs->example(-3, 'Box', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Array');
  is_deeply $result->source, [1..4];

  $result
});

$subs->example(-4, 'Box', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Hash');
  is_deeply $result->source, {1..4};

  $result
});

$subs->example(-1, 'Code', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Code');

  $result
});

$subs->example(-2, 'Code', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Code');

  $result
});

$subs->example(-1, 'False', 'function', fun($tryable) {
  ok !(my $result = $tryable->result);
  ok $result->isa('Data::Object::Boolean');
  is $$result, 0;

  $result
});

$subs->example(-1, 'Float', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Float');
  is ${$result->source}, '0.0';

  $result
});

$subs->example(-2, 'Float', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Float');
  is ${$result->source}, '0.0';

  $result
});

$subs->example(-1, 'Hash', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Hash');
  is_deeply $result->source, {};

  $result
});

$subs->example(-2, 'Hash', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Hash');
  is_deeply $result->source, {1..4};

  $result
});

$subs->example(-1, 'Number', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Number');
  is ${$result->source}, 1;

  $result
});

$subs->example(-2, 'Number', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Number');
  is ${$result->source}, 123;

  $result
});

$subs->example(-1, 'Regexp', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Regexp');
  like ${$result->source}, qr/\.\*/;

  $result
});

$subs->example(-2, 'Regexp', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Regexp');
  like ${$result->source}, qr/\.\*/;

  $result
});

$subs->example(-1, 'Scalar', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Scalar');
  is "${$result->source}", '';

  $result
});

$subs->example(-2, 'Scalar', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Scalar');
  is "${$result->source}", '*main::main';

  $result
});

$subs->example(-1, 'String', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::String');
  is "${$result->source}", '';

  $result
});

$subs->example(-2, 'String', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::String');
  is "${$result->source}", 'abc';

  $result
});

$subs->example(-1, 'True', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Boolean');
  is $$result, 1;

  $result
});

$subs->example(-1, 'Undef', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Box');
  ok $result->source->isa('Data::Object::Undef');
  is ${$result->source}, undef;

  $result
});

$subs->example(-1, 'Args', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Args');

  $result
})
&&
$subs->example(-2, 'Args', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Args');

  $result
})
if eval {
  require Data::Object::Args
};

$subs->example(-1, 'Data', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Data');

  $result
})
&&
$subs->example(-2, 'Data', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Data');

  $result
})
if eval {
  require Data::Object::Data
};

$subs->example(-1, 'Error', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Error');

  $result
})
&&
$subs->example(-2, 'Error', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Error');

  $result
})
if eval {
  require Data::Object::Error
};

$subs->example(-1, 'Opts', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Opts');

  $result
})
&&
$subs->example(-2, 'Opts', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Opts');

  $result
})
if eval {
  require Data::Object::Opts
};

$subs->example(-1, 'Name', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Name');

  $result
})
if eval {
  require Data::Object::Name
};

$subs->example(-1, 'Space', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Space');

  $result
})
if eval {
  require Data::Object::Space
};

$subs->example(-1, 'Struct', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  $DB::single=1;
  ok $result->isa('Data::Object::Struct');

  $result
})
&&
$subs->example(-2, 'Struct', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Struct');

  $result
})
if eval {
  require Data::Object::Struct
};

$subs->example(-1, 'Vars', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Vars');

  $result
})
&&
$subs->example(-2, 'Vars', 'function', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Data::Object::Vars');

  $result
})
if eval {
  require Data::Object::Vars
};

ok 1 and done_testing;

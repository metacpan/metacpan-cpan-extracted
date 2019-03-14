package Data::Object::String;

use Try::Tiny;

use Data::Object::Class;
use Data::Object::Export qw(
  cast
  croak
  load
);

map with($_), my @roles = qw(
  Data::Object::Role::Detract
  Data::Object::Role::Dumper
  Data::Object::Role::Output
  Data::Object::Role::Throwable
  Data::Object::Role::Type
);

map with($_), my @rules = qw(
  Data::Object::Rule::Comparison
  Data::Object::Rule::Defined
);

use overload (
  '""'     => 'data',
  '~~'     => 'data',
  fallback => 1
);

use parent 'Data::Object::Kind';

# BUILD

sub new {
  my ($class, $arg) = @_;

  my $role = 'Data::Object::Role::Type';

  if (Scalar::Util::blessed($arg)) {
    $arg = $arg->data if $arg->can('does') && $arg->does($role);
  }

  $arg = $arg ? "$arg" : "";

  if (!defined($arg) || ref($arg)) {
    croak('Instantiation Error: Not a String');
  }

  return bless \$arg, $class;
}

# METHODS

sub roles {
  return cast([@roles]);
}

sub rules {
  return cast([@rules]);
}

# DISPATCHERS

sub append {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Append';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub camelcase {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Camelcase';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub chomp {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Chomp';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub chop {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Chop';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub concat {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Concat';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub contains {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Contains';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub defined {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Defined';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub eq {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Eq';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub ge {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Ge';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub gt {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Gt';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub hex {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Hex';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub index {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Index';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub lc {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Lc';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub lcfirst {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Lcfirst';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub length {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Length';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub lines {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Lines';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub lowercase {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Lowercase';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub le {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Le';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub lt {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Lt';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub ne {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Ne';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub replace {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Replace';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub reverse {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Reverse';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub rindex {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Rindex';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub snakecase {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Snakecase';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub split {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Split';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub strip {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Strip';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub titlecase {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Titlecase';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub trim {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Trim';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub uc {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Uc';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub ucfirst {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Ucfirst';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub uppercase {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Uppercase';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub words {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::String::Words';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

1;

=encoding utf8

=head1 NAME

Data::Object::String

=cut

=head1 ABSTRACT

Data-Object String Class

=cut

=head1 SYNOPSIS

  use Data::Object::String;

  my $string = Data::Object::String->new('abcedfghi');

=cut

=head1 DESCRIPTION

Data::Object::String provides routines for operating on Perl 5 string
data. String methods work on data that meets the criteria for being a string. A
string holds and manipulates an arbitrary sequence of bytes, typically
representing characters. Users of strings should be aware of the methods that
modify the string itself as opposed to returning a new string. Unless stated, it
may be safe to assume that the following methods copy, modify and return new
strings based on their function.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 append

  append() : StrObject

The append method modifies and returns the string with the argument list
appended to it separated using spaces. This method returns a
string object.

=over 4

=item append example

  # given 'firstname'

  $string->append('lastname'); # firstname lastname

=back

=cut

=head2 camelcase

  camelcase() : StrObject

The camelcase method modifies the string such that it will no longer have any
non-alphanumeric characters and each word (group of alphanumeric characters
separated by 1 or more non-alphanumeric characters) is capitalized. Note, this
method modifies the string. This method returns a L<Data::Object::String>
object.

=over 4

=item camelcase example

  # given 'hello world'

  $string->camelcase; # HelloWorld

=back

=cut

=head2 chomp

  chomp() : StrObject

The chomp method is a safer version of the chop method, it's used to remove the
newline (or the current value of $/) from the end of the string. Note, this
method modifies and returns the string. This method returns a
string object.

=over 4

=item chomp example

  # given "name, age, dob, email\n"

  $string->chomp; # name, age, dob, email

=back

=cut

=head2 chop

  chop() : StrObject

The chop method removes the last character of a string and returns the character
chopped. It is much more efficient than "s/.$//s" because it neither scans nor
copies the string. Note, this method modifies and returns the string. This
method returns a string value.

=over 4

=item chop example

  # given "this is just a test."

  $string->chop; # this is just a test

=back

=cut

=head2 concat

  concat(Any $arg1) : StrObject

The concat method modifies and returns the string with the argument list
appended to it. This method returns a string value.

=over 4

=item concat example

  # given 'ABC'

  $string->concat('DEF', 'GHI'); # ABCDEFGHI

=back

=cut

=head2 contains

  contains(Str | RegexpRef $arg1) : NumObject

The contains method searches the string for the string specified in the
argument and returns true if found, otherwise returns false. If the argument is
a string, the search will be performed using the core index function. If the
argument is a regular expression reference, the search will be performed using
the regular expression engine. This method returns a L<Data::Object::Number>
object.

=over 4

=item contains example

  # given 'Nullam ultrices placerat nibh vel malesuada.'

  $string->contains('trices'); # 1; true
  $string->contains('itrices'); # 0; false

  $string->contains(qr/trices/); # 1; true
  $string->contains(qr/itrices/); # 0; false

=back

=cut

=head2 defined

  defined() : NumObject

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
number object.

=over 4

=item defined example

  # given $string

  $string->defined; # 1

=back

=cut

=head2 eq

  eq(Any $arg1) : NumObject

The eq method returns true if the argument provided is equal to the value
represented by the object. This method returns a number value.

=over 4

=item eq example

  # given 'exciting'

  $string->eq('Exciting'); # 0

=back

=cut

=head2 ge

  ge(Any $arg1) : NumObject

The ge method returns true if the argument provided is greater-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=over 4

=item ge example

  # given 'exciting'

  $string->ge('Exciting'); # 1

=back

=cut

=head2 gt

  gt(Any $arg1) : NumObject

The gt method returns true if the argument provided is greater-than the value
represented by the object. This method returns a number value.

=over 4

=item gt example

  # given 'exciting'

  $string->gt('Exciting'); # 1

=back

=cut

=head2 hex

  hex() : Str

The hex method returns the value resulting from interpreting the string as a
hex string. This method returns a data type object to be determined after
execution.

=over 4

=item hex example

  # given '0xaf'

  string->hex; # 175

=back

=cut

=head2 index

  index(Str $arg1, Num $arg2) : NumObject

The index method searches for the argument within the string and returns the
position of the first occurrence of the argument. This method optionally takes a
second argument which would be the position within the string to start
searching from (also known as the base). By default, starts searching from the
beginning of the string. This method returns a data type object to be determined
after execution.

=over 4

=item index example

  # given 'unexplainable'

  $string->index('explain'); # 2
  $string->index('explain', 0); # 2
  $string->index('explain', 1); # 2
  $string->index('explain', 2); # 2
  $string->index('explain', 3); # -1
  $string->index('explained'); # -1

=back

=cut

=head2 lc

  lc() : StrObject

The lc method returns a lowercased version of the string. This method returns a
string object. This method is an alias to the lowercase method.

=over 4

=item lc example

  # given 'EXCITING'

  $string->lc; # exciting

=back

=cut

=head2 lcfirst

  lc() : StrObject

The lcfirst method returns a the string with the first character lowercased.
This method returns a string value.

=over 4

=item lcfirst example

  # given 'EXCITING'

  $string->lcfirst; # eXCITING

=back

=cut

=head2 le

  le(Any $arg1) : NumObject

The le method returns true if the argument provided is less-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=over 4

=item le example

  # given 'exciting'

  $string->le('Exciting'); # 0

=back

=cut

=head2 length

  length() : NumObject

The length method returns the number of characters within the string. This
method returns a number value.

=over 4

=item length example

  # given 'longggggg'

  $string->length; # 9

=back

=cut

=head2 lines

  lines() : ArrayObject

The lines method breaks the string into pieces, split on 1 or more newline
characters, and returns an array reference consisting of the pieces. This method
returns an array value.

=over 4

=item lines example

  # given "who am i?\nwhere am i?\nhow did I get here"

  $string->lines; # ['who am i?','where am i?','how did i get here']

=back

=cut

=head2 lowercase

  lowercase() : StrObject

The lowercase method is an alias to the lc method. This method returns a
string object.

=over 4

=item lowercase example

  # given 'EXCITING'

  $string->lowercase; # exciting

=back

=cut

=head2 lt

  lt(Any $arg1) : NumObject

The lt method returns true if the argument provided is less-than the value
represented by the object. This method returns a number value.

=over 4

=item lt example

  # given 'exciting'

  $string->lt('Exciting'); # 0

=back

=cut

=head2 ne

  ne(Any $arg1) : NumObject

The ne method returns true if the argument provided is not equal to the value
represented by the object. This method returns a number value.

=over 4

=item ne example

  # given 'exciting'

  $string->ne('Exciting'); # 1

=back

=cut

=head2 new

  new(Str $arg1) : StrObject

The new method expects a string and returns a new class instance.

=over 4

=item new example

  # given abcedfghi

  my $string = Data::Object::String->new('abcedfghi');

=back

=cut

=head2 replace

  replace(Str $arg1, Str $arg2) : StrObject

The replace method performs a smart search and replace operation and returns the
modified string (if any modification occurred). This method optionally takes a
replacement modifier as it's final argument. Note, this operation expects the
2nd argument to be a replacement String. This method returns a
string object.

=over 4

=item replace example

  # given 'Hello World'

  $string->replace('World', 'Universe'); # Hello Universe
  $string->replace('world', 'Universe', 'i'); # Hello Universe
  $string->replace(qr/world/i, 'Universe'); # Hello Universe
  $string->replace(qr/.*/, 'Nada'); # Nada

=back

=cut

=head2 reverse

  reverse() : ArrayObject

The reverse method returns a string where the characters in the string are in
the opposite order. This method returns a string value.

=over 4

=item reverse example

  # given 'dlrow ,olleH'

  $string->reverse; # Hello, world

=back

=cut

=head2 rindex

  rindex(Str $arg1, Num $arg2) : NumObject

The rindex method searches for the argument within the string and returns the
position of the last occurrence of the argument. This method optionally takes a
second argument which would be the position within the string to start
searching from (beginning at or before the position). By default, starts
searching from the end of the string. This method returns a data type object to
be determined after execution.

=over 4

=item rindex example

  # given 'explain the unexplainable'

  $string->rindex('explain'); # 14
  $string->rindex('explain', 0); # 0
  $string->rindex('explain', 21); # 14
  $string->rindex('explain', 22); # 14
  $string->rindex('explain', 23); # 14
  $string->rindex('explain', 20); # 14
  $string->rindex('explain', 14); # 0
  $string->rindex('explain', 13); # 0
  $string->rindex('explain', 0); # 0
  $string->rindex('explained'); # -1

=back

=cut

=head2 roles

  roles() : ArrayRef

The roles method returns the list of roles attached to object. This method
returns an array value.

=over 4

=item roles example

  # given $string

  $string->roles;

=back

=cut

=head2 rules

  rules() : ArrayRef

The rules method returns consumed rules.

=over 4

=item rules example

  my $rules = $any->rules();

=back

=cut

=head2 snakecase

  snakecase() : StrObject

The snakecase method modifies the string such that it will no longer have any
non-alphanumeric characters and each word (group of alphanumeric characters
separated by 1 or more non-alphanumeric characters) is capitalized. The only
difference between this method and the camelcase method is that this method
ensures that the first character will always be lowercased. Note, this method
modifies the string. This method returns a string value.

=over 4

=item snakecase example

  # given 'hello world'

  $string->snakecase; # helloWorld

=back

=cut

=head2 split

  split(RegexpRef $arg1, Num $arg2) : ArrayObject

The split method splits the string into a list of strings, separating each
chunk by the argument (string or regexp object), and returns that list as an
array reference. This method optionally takes a second argument which would be
the limit (number of matches to capture). Note, this operation expects the 1st
argument to be a Regexp object or a String. This method returns a
array object.

=over 4

=item split example

  # given 'name, age, dob, email'

  $string->split(', '); # ['name', 'age', 'dob', 'email']
  $string->split(', ', 2); # ['name', 'age, dob, email']
  $string->split(qr/\,\s*/); # ['name', 'age', 'dob', 'email']
  $string->split(qr/\,\s*/, 2); # ['name', 'age, dob, email']

=back

=cut

=head2 strip

  strip() : StrObject

The strip method returns the string replacing occurences of 2 or more
whitespaces with a single whitespace. This method returns a
string object.

=over 4

=item strip example

  # given 'one,  two,  three'

  $string->strip; # one, two, three

=back

=cut

=head2 titlecase

  titlecase() : StrObject

The titlecase method returns the string capitalizing the first character of
each word (group of alphanumeric characters separated by 1 or more whitespaces).
Note, this method modifies the string. This method returns a
string object.

=over 4

=item titlecase example

  # given 'mr. john doe'

  $string->titlecase; # Mr. John Doe

=back

=cut

=head2 trim

  trim() : StrObject

The trim method removes 1 or more consecutive leading and/or trailing spaces
from the string. This method returns a string value.

=over 4

=item trim example

  # given ' system is   ready   '

  $string->trim; # system is   ready

=back

=cut

=head2 uc

  uc() : StrObject

The uc method returns an uppercased version of the string. This method returns a
string object. This method is an alias to the uppercase method.

=over 4

=item uc example

  # given 'exciting'

  $string->uc; # EXCITING

=back

=cut

=head2 ucfirst

  uc() : StrObject

The ucfirst method returns a the string with the first character uppercased.
This method returns a string value.

=over 4

=item ucfirst example

  # given 'exciting'

  $string->ucfirst; # Exciting

=back

=cut

=head2 uppercase

  uppercase() : StrObject

The uppercase method is an alias to the uc method. This method returns a
string object.

=over 4

=item uppercase example

  # given 'exciting'

  $string->uppercase; # EXCITING

=back

=cut

=head2 words

  words() : ArrayObject

The words method splits the string into a list of strings, separating each
group of characters by 1 or more consecutive spaces, and returns that list as an
array reference. This method returns an array value.

=over 4

=item words example

  # given "is this a bug we're experiencing"

  $string->words; # ["is","this","a","bug","we're","experiencing"]

=back

=cut

=head1 ROLES

This package inherits all behavior from the folowing role(s):

=cut

=over 4

=item *

L<Data::Object::Role::Detract>

=item *

L<Data::Object::Role::Dumper>

=item *

L<Data::Object::Role::Output>

=item *

L<Data::Object::Role::Throwable>

=item *

L<Data::Object::Role::Type>

=back

=head1 RULES

This package adheres to the requirements in the folowing rule(s):

=cut

=over 4

=item *

L<Data::Object::Rule::Comparison>

=item *

L<Data::Object::Rule::Defined>

=back

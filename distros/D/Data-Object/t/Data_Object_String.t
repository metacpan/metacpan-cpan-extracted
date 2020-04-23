use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Data::Object::String

=cut

=abstract

String Class for Perl 5

=cut

=includes

method: append
method: camelcase
method: chomp
method: chop
method: concat
method: contains
method: defined
method: eq
method: ge
method: gt
method: hex
method: index
method: lc
method: lcfirst
method: le
method: length
method: lines
method: lowercase
method: lt
method: ne
method: render
method: replace
method: reverse
method: rindex
method: snakecase
method: split
method: strip
method: titlecase
method: trim
method: uc
method: ucfirst
method: uppercase
method: words

=cut

=synopsis

  package main;

  use Data::Object::String;

  my $string = Data::Object::String->new('abcedfghi');

=cut

=libraries

Data::Object::Types

=cut

=inherits

Data::Object::Kind

=cut

=integrates

Data::Object::Role::Dumpable
Data::Object::Role::Proxyable
Data::Object::Role::Throwable

=cut

=description

This package provides methods for manipulating string data.

=cut

=method append

The append method appends arugments to the string using spaces.

=signature append

append() : Str

=example-1 append

  my $string = Data::Object::String->new('firstname');

  $string->append('lastname'); # firstname lastname

=cut

=method camelcase

The camelcase method converts the string to camelcase.

=signature camelcase

camelcase() : Str

=example-1 camelcase

  my $string = Data::Object::String->new('hello world');

  $string->camelcase; # HelloWorld

=cut

=method chomp

The chomp method removes the newline (or the current value of $/) from the end
of the string.

=signature chomp

chomp() : Str

=example-1 chomp

  my $string = Data::Object::String->new("name, age, dob, email\n");

  $string->chomp; # name, age, dob, email

=cut

=method chop

The chop method removes and returns the last character of the string.

=signature chop

chop() : Str

=example-1 chop

  my $string = Data::Object::String->new("this is just a test.");

  $string->chop; # this is just a test

=cut

=method concat

The concat method returns the string with the argument list appended to it.

=signature concat

concat(Any $arg1) : Str

=example-1 concat

  my $string = Data::Object::String->new('ABC');

  $string->concat('DEF', 'GHI'); # ABCDEFGHI

=cut

=method contains

The contains method searches the string for a substring or expression returns
true or false if found.

=signature contains

contains(Str | RegexpRef $arg1) : Num

=example-1 contains

  my $string = Data::Object::String->new('Nullam ultrices placerat.');

  $string->contains('trices'); # 1

=example-2 contains

  my $string = Data::Object::String->new('Nullam ultrices placerat.');

  $string->contains('itrices'); # 0

=example-3 contains

  my $string = Data::Object::String->new('Nullam ultrices placerat.');

  $string->contains(qr/trices/); # 1

=example-4 contains

  my $string = Data::Object::String->new('Nullam ultrices placerat.');

  $string->contains(qr/itrices/); # 0

=cut

=method defined

The defined method returns true, always.

=signature defined

defined() : Num

=example-1 defined

  my $string = Data::Object::String->new();

  $string->defined; # 1

=cut

=method eq

The eq method returns true if the argument provided is equal to the string.

=signature eq

eq(Any $arg1) : Num

=example-1 eq

  my $string = Data::Object::String->new('exciting');

  $string->eq('Exciting'); # 0

=cut

=method ge

The ge method returns true if the argument provided is greater-than or equal-to
the string.

=signature ge

ge(Any $arg1) : Num

=example-1 ge

  my $string = Data::Object::String->new('exciting');

  $string->ge('Exciting'); # 1

=cut

=method gt

The gt method returns true if the argument provided is greater-than the string.

=signature gt

gt(Any $arg1) : Num

=example-1 gt

  my $string = Data::Object::String->new('exciting');

  $string->gt('Exciting'); # 1

=cut

=method hex

The hex method returns the value resulting from interpreting the string as a hex string.

=signature hex

hex() : Str

=example-1 hex

  my $string = Data::Object::String->new('0xaf');

  $string->hex; # 175

=cut

=method index

The index method searches for the argument within the string and returns the
position of the first occurrence of the argument.

=signature index

index(Str $arg1, Num $arg2) : Num

=example-1 index

  my $string = Data::Object::String->new('unexplainable');

  $string->index('explain'); # 2

=example-2 index

  my $string = Data::Object::String->new('unexplainable');

  $string->index('explain', 0); # 2

=example-3 index

  my $string = Data::Object::String->new('unexplainable');

  $string->index('explain', 1); # 2

=example-4 index

  my $string = Data::Object::String->new('unexplainable');

  $string->index('explain', 2); # 2

=example-5 index

  my $string = Data::Object::String->new('unexplainable');

  $string->index('explained'); # -1

=cut

=method lc

The lc method returns a lowercased version of the string.

=signature lc

lc() : Str

=example-1 lc

  my $string = Data::Object::String->new('EXCITING');

  $string->lc; # exciting

=cut

=method lcfirst

The lcfirst method returns a the string with the first character lowercased.

=signature lcfirst

lcfirst() : Str

=example-1 lcfirst

  my $string = Data::Object::String->new('EXCITING');

  $string->lcfirst; # eXCITING

=cut

=method le

The le method returns true if the argument provided is less-than or equal-to
the string.

=signature le

le(Any $arg1) : Num

=example-1 le

  my $string = Data::Object::String->new('exciting');

  $string->le('Exciting'); # 0

=cut

=method length

The length method returns the number of characters within the string.

=signature length

length() : Num

=example-1 length

  my $string = Data::Object::String->new('longggggg');

  $string->length; # 9

=cut

=method lines

The lines method returns an arrayref of parts by splitting on 1 or more newline
characters.

=signature lines

lines() : ArrayRef

=example-1 lines

  my $string = Data::Object::String->new(
    "who am i?\nwhere am i?\nhow did I get here"
  );

  $string->lines; # ['who am i?','where am i?','how did I get here']

=cut

=method lowercase

The lowercase method is an alias to the lc method.

=signature lowercase

lowercase() : Str

=example-1 lowercase

  my $string = Data::Object::String->new('EXCITING');

  $string->lowercase; # exciting

=cut

=method lt

The lt method returns true if the argument provided is less-than the string.

=signature lt

lt(Any $arg1) : Num

=example-1 lt

  my $string = Data::Object::String->new('exciting');

  $string->lt('Exciting'); # 0

=cut

=method ne

The ne method returns true if the argument provided is not equal to the string.

=signature ne

ne(Any $arg1) : Num

=example-1 ne

  my $string = Data::Object::String->new('exciting');

  $string->ne('Exciting'); # 1

=cut

=method render

The render method treats the string as a template and performs a simple token
replacement using the argument provided.

=signature render

render(HashRef $arg1) : Str

=example-1 render

  my $string = Data::Object::String->new('Hi, {name}!');

  $string->render({name => 'Friend'}); # Hi, Friend!

=cut

=method replace

The replace method performs a search and replace operation and returns the modified string.

=signature replace

replace(Str $arg1, Str $arg2) : Str

=example-1 replace

  my $string = Data::Object::String->new('Hello World');

  $string->replace('World', 'Universe'); # Hello Universe

=example-2 replace

  my $string = Data::Object::String->new('Hello World');

  $string->replace('world', 'Universe', 'i'); # Hello Universe

=example-3 replace

  my $string = Data::Object::String->new('Hello World');

  $string->replace(qr/world/i, 'Universe'); # Hello Universe

=example-4 replace

  my $string = Data::Object::String->new('Hello World');

  $string->replace(qr/.*/, 'Nada'); # Nada

=cut

=method reverse

The reverse method returns a string where the characters in the string are in
the opposite order.

=signature reverse

reverse() : Str

=example-1 reverse

  my $string = Data::Object::String->new('dlrow ,olleH');

  $string->reverse; # Hello, world

=cut

=method rindex

The rindex method searches for the argument within the string and returns the
position of the last occurrence of the argument.

=signature rindex

rindex(Str $arg1, Num $arg2) : Num

=example-1 rindex

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain'); # 14

=example-2 rindex

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 0); # 0

=example-3 rindex

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 21); # 14

=example-4 rindex

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 22); # 14

=example-5 rindex

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 23); # 14

=example-6 rindex

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 20); # 14

=example-7 rindex

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 14); # 0

=example-8 rindex

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 13); # 0

=example-9 rindex

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explain', 0); # 0

=example-10 rindex

  my $string = Data::Object::String->new('explain the unexplainable');

  $string->rindex('explained'); # -1

=cut

=method snakecase

The snakecase method converts the string to snakecase.

=signature snakecase

snakecase() : Str

=example-1 snakecase

  my $string = Data::Object::String->new('hello world');

  $string->snakecase; # hello_world

=cut

=method split

The split method returns an arrayref by splitting on the argument.

=signature split

split(RegexpRef $arg1, Num $arg2) : ArrayRef

=example-1 split

  my $string = Data::Object::String->new('name, age, dob, email');

  $string->split(', '); # ['name', 'age', 'dob', 'email']

=example-2 split

  my $string = Data::Object::String->new('name, age, dob, email');

  $string->split(', ', 2); # ['name', 'age, dob, email']

=example-3 split

  my $string = Data::Object::String->new('name, age, dob, email');

  $string->split(qr/\,\s*/); # ['name', 'age', 'dob', 'email']

=example-4 split

  my $string = Data::Object::String->new('name, age, dob, email');

  $string->split(qr/\,\s*/, 2); # ['name', 'age, dob, email']

=cut

=method strip

The strip method returns the string replacing occurences of 2 or more
whitespaces with a single whitespace.

=signature strip

strip() : Str

=example-1 strip

  my $string = Data::Object::String->new('one,  two,  three');

  $string->strip; # one, two, three

=cut

=method titlecase

The titlecase method returns the string capitalizing the first character of
each word.

=signature titlecase

titlecase() : Str

=example-1 titlecase

  my $string = Data::Object::String->new('mr. john doe');

  $string->titlecase; # Mr. John Doe

=cut

=method trim

The trim method removes one or more consecutive leading and/or trailing spaces
from the string.

=signature trim

trim() : Str

=example-1 trim

  my $string = Data::Object::String->new('   system is   ready   ');

  $string->trim; # system is   ready

=cut

=method uc

The uc method returns an uppercased version of the string.

=signature uc

uc() : Str

=example-1 uc

  my $string = Data::Object::String->new('exciting');

  $string->uc; # EXCITING

=cut

=method ucfirst

The ucfirst method returns a the string with the first character uppercased.

=signature ucfirst

ucfirst() : Str

=example-1 ucfirst

  my $string = Data::Object::String->new('exciting');

  $string->ucfirst; # Exciting

=cut

=method uppercase

The uppercase method is an alias to the uc method.

=signature uppercase

uppercase() : Str

=example-1 uppercase

  my $string = Data::Object::String->new('exciting');

  $string->uppercase; # EXCITING

=cut

=method words

The words method returns an arrayref by splitting on 1 or more consecutive
spaces.

=signature words

words() : ArrayRef

=example-1 words

  my $string = Data::Object::String->new(
    'is this a bug we\'re experiencing'
  );

  $string->words; # ["is","this","a","bug","we're","experiencing"]

=cut

package main;

my $subs = testauto(__FILE__);

$subs->package;
$subs->document;
$subs->libraries;
$subs->inherits;
$subs->attributes;
$subs->routines;
$subs->functions;
$subs->types;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'append', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'firstname lastname';

  $result
});

$subs->example(-1, 'camelcase', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "HelloWorld";

  $result
});

$subs->example(-1, 'chomp', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "name, age, dob, email";

  $result
});

$subs->example(-1, 'chop', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "this is just a test";

  $result
});

$subs->example(-1, 'concat', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "ABCDEFGHI";

  $result
});

$subs->example(-1, 'contains', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'defined', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'eq', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-1, 'ge', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'gt', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'hex', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 175;

  $result
});

$subs->example(-1, 'index', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 2;

  $result
});

$subs->example(-1, 'lc', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'exciting';

  $result
});

$subs->example(-1, 'lcfirst', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "eXCITING";

  $result
});

$subs->example(-1, 'le', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-1, 'length', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 9;

  $result
});

$subs->example(-1, 'lines', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['who am i?','where am i?','how did I get here'];

  $result
});

$subs->example(-1, 'lowercase', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "exciting";

  $result
});

$subs->example(-1, 'lt', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);
  is $result, 0;

  $result
});

$subs->example(-1, 'ne', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 1;

  $result
});

$subs->example(-1, 'render', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "Hi, Friend!";

  $result
});

$subs->example(-1, 'replace', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "Hello Universe";

  $result
});

$subs->example(-1, 'reverse', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "Hello, world";

  $result
});

$subs->example(-1, 'rindex', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 14;

  $result
});

$subs->example(-1, 'snakecase', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "hello_world";

  $result
});

$subs->example(-1, 'split', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ['name', 'age', 'dob', 'email'];

  $result
});

$subs->example(-1, 'strip', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "one, two, three";

  $result
});

$subs->example(-1, 'titlecase', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "Mr. John Doe";

  $result
});

$subs->example(-1, 'trim', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "system is   ready";

  $result
});

$subs->example(-1, 'uc', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "EXCITING";

  $result
});

$subs->example(-1, 'ucfirst', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "Exciting";

  $result
});

$subs->example(-1, 'uppercase', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, "EXCITING";

  $result
});

$subs->example(-1, 'words', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is_deeply $result, ["is","this","a","bug","we're","experiencing"];

  $result
});

ok 1 and done_testing;

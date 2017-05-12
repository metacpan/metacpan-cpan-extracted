#!perl -w

use strict;

use Test::More;

# Testing _check_subobj()


use Array::To::Moose qw(array_to_moose throw_multiple_rows);

BEGIN {
  eval "use Test::Exception";
  plan skip_all => "Test::Exception needed" if $@;
}

plan tests => 11;

#----------------------------------------
package Sibling;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

has [ qw( name sex ) ] => (is => 'rw', isa => 'Str' );

__PACKAGE__->meta->make_immutable;

#----------------------------------------
package Cousin;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

has [ qw( name sex ) ] => (is => 'rw', isa => 'Str' );

__PACKAGE__->meta->make_immutable;

#----------------------------------------
package Person;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

has [ qw( name sex ) ] => (is => 'rw', isa =>          'Str' );
has SibH               => (is => 'rw', isa => 'HashRef[Sibling]' );
has SibA               => (is => 'rw', isa => 'ArrayRef[Sibling]');
has SibB               => (is => 'rw', isa =>           'Sibling'); # (B)are

__PACKAGE__->meta->make_immutable;

package main;

my @s1 = ( 'John', 'm' );
my @s2 = ( 'Jane', 'f' );

my @p1 = ( 'Bill', 'm' );
my @p2 = ( 'Pam',  'f' );

my $data = [ [ @p1, @s1 ],
             [ @p1, @s2 ],
             [ @p2, @s1 ],
             [ @p2, @s2 ],
           ];

# Moose says HashRef, desc says ArrayRef
#----------------------------------------
my $desc = {  class => 'Person',
           name  => 0,
           sex   => 1,
           SibH  => {
             class => 'Sibling',
             name  => 2,
             sex   => 3,
           }
};

throws_ok { array_to_moose(data => $data, desc => $desc); }
  qr/'SibH' has type 'HashRef\[Sibling\]' but your.*of type 'ARRAY'/,
'_check_subobj(): Moose says HashRef[`a], desc says ArrayRef[`a]';

# Moose says HashRef[`a] desc says Hashref[`b]
#----------------------------------------
$desc = {  class => 'Person',
              name  => 0,
              sex   => 1,
              SibH  => {
                class => 'Cousin',    # !! should be Sibling
                key   => 2,
                name  => 2,
                sex   => 3,
              }
};

throws_ok { array_to_moose(data => $data, desc => $desc); }
  qr/'SibH' has type 'HashRef\[Sibling\]' but your.*of type 'HashRef\[Cousin\]'/,
  '_check_subobj(): Moose says HashRef[`a], desc says HashRef[`b]';

# Moose and desc both say HashRef[`a]
#----------------------------------------
$desc = {  class => 'Person',
           name  => 0,
           sex   => 1,
           SibH  => {
             class => 'Sibling',
             key   => 2,
             name  => 2,
             sex   => 3,
           }
};

lives_ok { array_to_moose(data => $data, desc => $desc) }
  '_check_subobj(): Moose & desc both say HashRef[`a]';

# Moose says ArrayRef, desc says HashRef
#----------------------------------------
$desc = {  class => 'Person',
           name  => 0,
           sex   => 1,
           SibA  => {
             class => 'Sibling',
             key => 2,            # force it to be a hashref
             name  => 2,
             sex   => 3,
           }
};

throws_ok { array_to_moose(data => $data, desc => $desc); }
  qr/'SibA' has type 'ArrayRef\[Sibling\]' but your.*of type 'HASH'/,
'_check_subobj(): Moose says ArrayRef[`a], desc says HashRef[`a]';

# Moose says ArrayRef[`a], desc says ArrayRef[`b]
#----------------------------------------
$desc = {  class => 'Person',
              name  => 0,
              sex   => 1,
              SibA  => {
                class => 'Cousin',    # !! should be Sibling
                name  => 2,
                sex   => 3,
              }
};

throws_ok { array_to_moose(data => $data, desc => $desc); }
  qr/'SibA' has type 'ArrayRef\[Sibling\]' but your.*of type 'ArrayRef\[Cousin\]'/,
  '_check_subobj(): Moose says ArrayRef[`a], desc says ArrayRef[`b]';


# Moose and desc both say ArrayRef[`a]
#----------------------------------------
$desc = {  class => 'Person',
           name  => 0,
           sex   => 1,
           SibA  => {
             class => 'Sibling',
             name  => 2,
             sex   => 3,
           }
};

lives_ok { array_to_moose(data => $data, desc => $desc) }
  '_check_subobj(): Moose & desc both say ArrayRef[`a]';

# Moose says `a, desc says HashRef[`a]
#----------------------------------------
$desc = {  class => 'Person',
           name  => 0,
           sex   => 1,
           SibB  => {
             class => 'Sibling',
             key => 2,            # force it to be a hashref
             name  => 2,
             sex   => 3,
           }
};

throws_ok { array_to_moose(data => $data, desc => $desc); }
  qr/'SibB' has type 'Sibling' but your.* a 'HASH'.*expected ARRAY/,
'_check_subobj(): Moose says `a, desc says HashRef[`a]';

# Moose says `a, desc says ArrayRef[`a] which is converted to `a
#----------------------------------------
$desc = {  class => 'Person',
           name  => 0,
           sex   => 1,
           SibB  => {
             class => 'Sibling',
             name  => 2,
             sex   => 3,
           }
};

lives_ok { array_to_moose(data => $data, desc => $desc); }
'_check_subobj(): Moose says `a, desc says ArrayRef[`a]';

# Moose says `a, desc says `b
#----------------------------------------
$desc = {  class => 'Person',
              name  => 0,
              sex   => 1,
              SibB  => {
                class => 'Cousin',    # !! should be Sibling
                name  => 2,
                sex   => 3,
              }
};

throws_ok { array_to_moose(data => $data, desc => $desc); }
  qr/'SibB' has type 'Sibling' but your.*of type 'Cousin'/,
  '_check_subobj(): Moose says `a, desc says `b';

# Moose says `a, desc returns multiple rows, throw_multiple_rows is "on"
#----------------------------------------
throw_multiple_rows();

$desc = {  class => 'Person',
              name  => 0,
              sex   => 1,
              SibB  => {
                class => 'Sibling',
                name  => 2,
                sex   => 3,
              }
};

throws_ok { array_to_moose(data => $data, desc => $desc); }
  qr/Expected a single 'Sibling' object, but got \d of them at/,
  '_check_subobj(): Moose says single `a, but > 1 (throw)';

# Moose says `a, desc returns multiple rows, throw_multiple_rows is "off"
#----------------------------------------
throw_multiple_rows(0);

$desc = {  class => 'Person',
              name  => 0,
              sex   => 1,
              SibB  => {
                class => 'Sibling',
                name  => 2,
                sex   => 3,
              }
};

lives_ok { array_to_moose(data => $data, desc => $desc); }
  "_check_subobj(): Moose says single `a, got > 1 (don't care)";

#!perl -w

use strict;

use Test::More;

# Testing types, initially "Maybe[`]"


use Array::To::Moose qw(array_to_moose throw_multiple_rows);

BEGIN {
  eval "use Test::Exception";
  plan skip_all => "Test::Exception needed" if $@;
}

plan tests => 1;

#----------------------------------------
package Person;
use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

has 'name'    => (is => 'rw', isa =>        'Str' );
has 'sibling' => (is => 'rw', isa => 'Maybe[Str]' );

__PACKAGE__->meta->make_immutable;

package main;

my @s1 = ( 'John', 'Bill' );
my @s2 = ( 'Jane', 'Alex' );

my $data = [ [ @s1 ], [ @s2 ] ];

my $desc = {  class => 'Person',
           name    => 0,
           sibling => 1,
};

lives_ok { array_to_moose(data => $data, desc => $desc); }
  'Type Maybe[`]';

# Handle these (from Moose::Util::TypeConstraints)
#
#   use Moose::Util::TypeConstraints;
# 
#   subtype 'Natural',
#       as 'Int',
#       where { $_ > 0 };
# 
#   subtype 'NaturalLessThanTen',
#       as 'Natural',
#       where { $_ < 10 },
#       message { "This number ($_) is not less than ten!" };
# 
#   coerce 'Num',
#       from 'Str',
#       via { 0+$_ };
# 
#   class_type 'DateTimeClass', { class => 'DateTime' };
# 
#   role_type 'Barks', { role => 'Some::Library::Role::Barks' };
# 
#   enum 'RGBColors', [qw(red green blue)];
# 
#   union 'StringOrArray', [qw( String ArrayRef )];
# 
#   no Moose::Util::TypeConstraints;

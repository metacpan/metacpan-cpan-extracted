#!perl

use strict;
use warnings;

use Test::More tests => 5;
#use Test::More qw/no_plan/;
use Test::Exception;

#
# These tests are for some of the less common options to be used with
# Class::Meta::Declare, such as specifying a different class than C:M for
# building and having optional code for methods.
#

BEGIN {
    chdir 't' if -d 't';
    use lib '../lib';
    use_ok('Class::Meta::Declare');
}

{

    package Class::Meta::Subclass;

    use base 'Class::Meta';
    $INC{'Class/Meta/Subclass.pm'} = 1;  # trick 'use' into thinking it's loaded
}

throws_ok { Class::Meta::Declare->new( meta => [ use => 'No::Such::Class' ] ) }
  qr/Cannot use No::Such::Class as building class: /,
  'Trying to use a non-existent class as the building class should fail';

ok my $declare = Class::Meta::Declare->create(
    meta       => [ use => "Class::Meta::Subclass", package => 'Foo' ],
    attributes => [ foo  => {}, bar => {} ]
  ),
  '... but specifying an alternate build class should succeed';

isa_ok $declare->cm, 'Class::Meta::Subclass', 'The building class';
$declare->cm->build;
ok my $foo = Foo->new, '... and we should be able to build the class';

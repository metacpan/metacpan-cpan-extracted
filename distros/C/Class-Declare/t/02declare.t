#!/usr/bin/perl -w
# $Id: 02declare.t 1511 2010-08-21 23:24:49Z ian $

# declare.t
#
# Ensure declare() behaves appropriately. Test such things as:
#   - calling twice within a package
#   - valid call parameters
#   - invalid call parameters
#
# NB: Not all tests of declare() are performed here. See other test
#     scripts.

use strict;
use Test::More tests => 10;
use Test::Exception;

# create a package with derived from Class::Declare
lives_ok {
  package Test::Declare::One;

  use strict;
  use base qw( Class::Declare );

  __PACKAGE__->declare();

  1;
} 'empty declare() succeeds';

# call declare twice for the same package
dies_ok {
  package Test::Declare::Two;

  use strict;
  use base qw( Class::Declare );

  __PACKAGE__->declare();
  __PACKAGE__->declare();

  1;
} 'duplicate calls to declare() fail';

# only accepts valid arguments
lives_ok {
  package Test::Declare::Three;

  use strict;
  use base qw( Class::Declare );

  __PACKAGE__->declare( public     => undef ,
                        private    => undef ,
                        protected  => undef ,
                        class      => undef ,
                        static     => undef ,
                        restricted => undef ,
                        init       => undef ,
                        strict     => undef ,
                        friends    => undef );
  1;
} 'valid arguments to declare() OK';

# invalid arguments cause failure
dies_ok {
  package Test::Declare::Four;

  use strict;
  use base qw( Class::Declare );

  __PACKAGE__->declare( foo => undef );

  1;
} 'invalid declare() arguments fails';

# cannot declare attributes of name 'public', 'private', etc
# i.e. attributes cannot mask any of the methods supplied by
# Class::Declare
# NB: only need to test this twice as all reserved attribute names
#     will execute either the "class" code or the
#     "public/private/etc" code
dies_ok {
  package Test::Declare::Five;

  use strict;
  use base qw( Class::Declare );

  __PACKAGE__->declare( public => { protected => undef } );

  1
} 'invalid public/private/protected attribute name';

dies_ok {
  package Test::Declare::Six;

  use strict;
  use base qw( Class::Declare );

  __PACKAGE__->declare( class  => { private   => undef } );

  1
} 'invalid class attribute name';

# cannot redeclare attributes
dies_ok {
  package Test::Declare::Seven;

  use strict;
  use base qw( Class::Declare );

  __PACKAGE__->declare( public  => { attribute => undef } ,
                        private => { attribute => undef } );

  1
} 'attribute redefinition' ;

# can declare attributes to have a code reference as their value
lives_ok {
  package Test::Declare::Eight;

  use strict;
  use base qw( Class::Declare );

  __PACKAGE__->declare( static => { attribute => sub { rand } } );

  1
} 'CODEREF attribute value OK' ;

# can we declare a single attribute without a hash reference?
lives_ok {
  package Test::Declare::Nine;

  use strict;
  use base qw( Class::Declare );

  __PACKAGE__->declare( public => 'attribute' );

  1
} 'single attribute definition OK';

# can we declare a list of attributes, all defaulting to undef?
lives_ok {
  package Test::Declare::Ten;

  use strict;
  use base qw( Class::Declare );

  __PACKAGE__->declare( class => [ qw( a b c d e f ) ] );

  1
} 'list of attributes defaulting to undef OK';

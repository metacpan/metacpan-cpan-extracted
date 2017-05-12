#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;

BEGIN { use_ok 'Class::Fields::Attribs' }

# Check that the attributes exported okay.
is( Class::Fields::Attribs::PRIVATE  , PRIVATE      ,'PRIVATE'  );
is( Class::Fields::Attribs::PUBLIC   , PUBLIC       ,'PUBLIC'   );
is( Class::Fields::Attribs::INHERITED, INHERITED    ,'INHERITED');
is( Class::Fields::Attribs::PROTECTED, PROTECTED    ,'PROTECTED');


#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;
use_ok('Data::FormValidator::Constraints::Upload');

# Exercise the _is_allowed_type() helper function

# Test the negative case
isnt( Data::FormValidator::Constraints::Upload::_is_allowed_type('foo'),
  1, "'foo'        not considered an allowed mime type" );

# Reality check that a simple jpeg is allowed
is( Data::FormValidator::Constraints::Upload::_is_allowed_type('image/jpeg'),
  1, "'image/jpeg'  is considered an allowed mime type" );

# Check that we handle case insensitivity
is( Data::FormValidator::Constraints::Upload::_is_allowed_type('image/JPEG'),
  1, "'image/JPEG'  is considered an allowed mime type" );

# Also ensure progressive jpegs are allowed
is( Data::FormValidator::Constraints::Upload::_is_allowed_type('image/pjpeg'),
  1, "'image/pjpeg' is considered an allowed mime type" );

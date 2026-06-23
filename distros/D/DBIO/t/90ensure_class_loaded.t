use strict;
use warnings;

use Test::More;
use DBIO::Test;
use DBIO::Util 'sigwarn_silencer';
use Class::Inspector;

BEGIN {
  package TestPackage::A;
  sub some_method {}
}

my $schema = DBIO::Test->init_schema(no_deploy => 1);

plan tests => 28;

# Test ensure_class_found
ok( $schema->ensure_class_found('DBIO::Schema'),
    'loaded package DBIO::Schema was found' );
ok( !Class::Inspector->loaded('DBIO::Test::FakeComponent'),
    'DBIO::Test::FakeComponent not loaded yet' );
ok( $schema->ensure_class_found('DBIO::Test::FakeComponent'),
    'package DBIO::Test::FakeComponent was found' );
ok( !Class::Inspector->loaded('DBIO::Test::FakeComponent'),
    'DBIO::Test::FakeComponent not loaded by ensure_class_found()' );
ok( $schema->ensure_class_found('TestPackage::A'),
    'anonymous package TestPackage::A found' );
ok( !$schema->ensure_class_found('FAKE::WONT::BE::FOUND'),
        'fake package not found' );

# Test load_optional_class
my $retval = eval { $schema->load_optional_class('ANOTHER::FAKE::PACKAGE') };
ok( !$@, 'load_optional_class on a nonexistent class did not throw' );
ok( !$retval, 'nonexistent package not loaded' );
$retval = eval { $schema->load_optional_class('DBIO::Test::OptionalComponent') };
ok( !$@, 'load_optional_class on an existing class did not throw' );
ok( $retval, 'DBIO::Test::OptionalComponent loaded' );
eval { $schema->load_optional_class('DBIO::Test::ErrorComponent') };
like( $@, qr/did not return a true value/,
      'DBIO::Test::ErrorComponent threw ok' );

# Simulate a PAR environment
{
  my @code;
  local @INC = @INC;
  unshift @INC, sub {
    if ($_[1] eq 'VIRTUAL/PAR/PACKAGE.pm') {
      return (sub { return 0 unless @code; $_ = shift @code; 1; } );
    }
    else {
      return ();
    }
  };

  $retval = eval { $schema->load_optional_class('FAKE::PAR::PACKAGE') };
  ok( !$@, 'load_optional_class on a nonexistent PAR class did not throw' );
  ok( !$retval, 'nonexistent PAR package not loaded' );


  # simulate a class which does load but does not return true
  @code = (
    q/package VIRTUAL::PAR::PACKAGE;/,
    q/0;/,
  );

  $retval = eval { $schema->load_optional_class('VIRTUAL::PAR::PACKAGE') };
  ok( $@, 'load_optional_class of a no-true-returning PAR module did throw' );
  ok( !$retval, 'no-true-returning PAR package not loaded' );

  # simulate a normal class (no one adjusted %INC so it will be tried again
  @code = (
    q/package VIRTUAL::PAR::PACKAGE;/,
    q/1;/,
  );

  $retval = eval { $schema->load_optional_class('VIRTUAL::PAR::PACKAGE') };
  ok( !$@, 'load_optional_class of a PAR module did not throw' );
  ok( $retval, 'PAR package "loaded"' );

  # see if we can still load stuff with the coderef present
  $retval = eval { $schema->load_optional_class('DBIO::ResultClass::HashRefInflator') };
  ok( !$@, 'load_optional_class did not throw' ) || diag $@;
  ok( $retval, 'DBIO::ResultClass::HashRefInflator loaded' );
}

# Test ensure_class_loaded
ok( Class::Inspector->loaded('TestPackage::A'), 'anonymous package exists' );
eval { $schema->ensure_class_loaded('TestPackage::A'); };
ok( !$@, 'ensure_class_loaded detected an anon. class' );
eval { $schema->ensure_class_loaded('FakePackage::B'); };
like( $@, qr/Can't locate/,
     'ensure_class_loaded threw exception for nonexistent class' );
ok( !Class::Inspector->loaded('DBIO::Test::FakeComponent'),
   'DBIO::Test::FakeComponent not loaded yet' );
eval { $schema->ensure_class_loaded('DBIO::Test::FakeComponent'); };
ok( !$@, 'ensure_class_loaded detected an existing but non-loaded class' );
ok( Class::Inspector->loaded('DBIO::Test::FakeComponent'),
   'DBIO::Test::FakeComponent now loaded' );

{
  # Squash warnings about syntax errors in SytaxErrorComponent.pm
  local $SIG{__WARN__} = sigwarn_silencer(
    qr/String found where operator expected|Missing operator before/
  );

  eval { $schema->ensure_class_loaded('DBIO::Test::SyntaxErrorComponent1') };
  like( $@, qr/syntax error/,
        'ensure_class_loaded(DBIO::Test::SyntaxErrorComponent1) threw ok' );
  eval { $schema->load_optional_class('DBIO::Test::SyntaxErrorComponent2') };
  like( $@, qr/syntax error/,
        'load_optional_class(DBIO::Test::SyntaxErrorComponent2) threw ok' );
}


eval {
  package Fake::ResultSet;

  use base 'DBIO::ResultSet';

  __PACKAGE__->load_components('+DBIO::Test::SyntaxErrorComponent3');
};

# Make sure the errors in components of resultset classes are reported right.
like($@, qr!syntax error at .*\QDBIO/Test/SyntaxErrorComponent3.pm\E!, "Errors from RS components reported right");

1;

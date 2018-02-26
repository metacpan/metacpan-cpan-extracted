use strict;
use warnings;

use FindBin;
use Test::More;
use Test::Exception;
use Class::Inspector;

use lib "$FindBin::Bin/lib";

plan tests => 25;

BEGIN {
  package TestPackage::A;
  sub some_method {}
}

use_ok('MyModule');

MyModule->load_components('Foo');

# Clear down inc so ppl dont mess us up with installing modules that we
# expect not to exist
#@INC = ();
# This breaks Carp1.08/perl 5.10.0; bah

throws_ok { MyModule->load_components('+ClassC3ComponentFooThatShouldntExist'); } qr/^Can't locate ClassC3ComponentFooThatShouldntExist.pm in \@INC/;

is(MyModule->new->message, "Foo MyModule", "it worked");

ok( MyModule->ensure_class_found('MyModule::Plugin::Foo'),
    'loaded package MyModule::Plugin::Foo was found' );
ok( !Class::Inspector->loaded('MyModule::OwnComponent'),
    'MyModule::OwnComponent not loaded yet' );
ok( MyModule->ensure_class_found('MyModule::OwnComponent'),
    'package MyModule::OwnComponent was found' );
ok( !Class::Inspector->loaded('MyModule::OwnComponent'),
    'MyModule::OwnComponent not loaded by ensure_class_found()' );
ok( MyModule->ensure_class_found('TestPackage::A'),
    'anonymous package TestPackage::A found' );
ok( !MyModule->ensure_class_found('FAKE::WONT::BE::FOUND'),
        'fake package not found' );

# Test load_optional_class
my $retval = eval { MyModule->load_optional_class('ANOTHER::FAKE::PACKAGE') };
ok( !$@, 'load_optional_class on a nonexistent class did not throw' );
ok( !$retval, 'nonexistent package not loaded' );
$retval = eval { MyModule->load_optional_class('MyModule::OwnComponent') };
ok( !$@, 'load_optional_class on an existing class did not throw' );
ok( $retval, 'MyModule::OwnComponent loaded' );
throws_ok (
  sub { MyModule->load_optional_class('MyModule::ErrorComponent') },
  qr/did not return a true value/,
  'MyModule::ErrorComponent threw ok'
);

eval { MyModule->load_optional_class('ENDS::WITH::COLONS::') };
like( $@, qr/Invalid class name 'ENDS::WITH::COLONS::'/, 'Throw on Class::' );

# Simulate a PAR environment
{
  my @code;
  local @INC = @INC;
  unshift @INC, sub {
    if ($_[1] =~ m{^VIRTUAL/PAR/PACKAGE[0-9]*\.pm$}) {
      return (sub { return 0 unless @code; $_ = shift @code; 1; } );
    }
    else {
      return ();
    }
  };

  $retval = eval { MyModule->load_optional_class('FAKE::PAR::PACKAGE') };
  ok( !$@, 'load_optional_class on a nonexistent PAR class did not throw' );
  ok( !$retval, 'nonexistent PAR package not loaded' );


  # simulate a class which does load but does not return true
  @code = (
    q/package VIRTUAL::PAR::PACKAGE1;/,
    q/0;/,
  );

  $retval = eval { MyModule->load_optional_class('VIRTUAL::PAR::PACKAGE1') };
  ok( $@, 'load_optional_class of a no-true-returning PAR module did throw' );
  ok( !$retval, 'no-true-returning PAR package not loaded' );

  # simulate a normal class
  @code = (
    q/package VIRTUAL::PAR::PACKAGE2;/,
    q/1;/,
  );

  $retval = eval { MyModule->load_optional_class('VIRTUAL::PAR::PACKAGE2') };
  ok( !$@, 'load_optional_class of a PAR module did not throw' );
  ok( $retval, 'PAR package "loaded"' );

  # see if we can still load stuff with the coderef present
  $retval = eval { MyModule->load_optional_class('AnotherModule') };
  ok( !$@, 'load_optional_class did not throw' ) || diag $@;
  ok( $retval, 'AnotherModule loaded' );

  @code = (
    q/package VIRTUAL::PAR::PACKAGE3;/,
    q/1;/,
  );

  $retval = eval { MyModule->ensure_class_found('VIRTUAL::PAR::PACKAGE3') };
  ok( !$@, 'ensure_class_found of a PAR module did not throw' );
  ok( $retval, 'PAR package "found"' );
}

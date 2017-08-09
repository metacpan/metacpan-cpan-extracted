#!/usr/bin/perl

# Reproduce some of the unit tests in the main unit tests
# of the method interface, but not all. This makes the maintenance
# slightly less annoying.

use strict;
use warnings;
use Test::More tests => 24;
use Class::Inspector::Functions;

# To make maintaining this a little faster,
# CI is defined as Class::Inspector, and
# BAD for a class we know doesn't exist.
use constant CI  => 'Class::Inspector';
use constant BAD => 'Class::Inspector::Nonexistant';

my @exported_functions = qw(
  installed
  loaded
  filename
  functions
  methods
  subclasses
);

my @exportok_functions = qw(
  loaded_filename
  function_refs
  function_exists
);

#####################################################################
# Begin Tests

# check the export lists:
foreach my $function (@exported_functions) {
  ok( main->can($function), "exported function '$function' was found" );
}

foreach my $function (@exportok_functions) {
  ok( ! main->can($function), "optionally exported function '$function' was not found" );
}

Class::Inspector::Functions->import(':ALL');

foreach my $function (@exportok_functions) {
  ok( main->can($function), "optionally exported function '$function' was found after full import" );
}



# Check the loaded function
ok(   loaded( CI ), "loaded detects loaded" );
ok( ! loaded( BAD ), "loaded detects not loaded" );

# Check the file name functions
my $filename = filename( CI );
ok( $filename eq File::Spec->catfile( "Class", "Inspector.pm" ), "filename works correctly" );
ok( index( loaded_filename(CI), $filename ) >= 0, "loaded_filename works" );
my $inc_filename = CI->_inc_filename( CI );
ok( ($filename eq $inc_filename or index( loaded_filename(CI), $inc_filename ) == -1), "loaded_filename works" );
ok( index( resolved_filename(CI), $filename ) >= 0, "resolved_filename works" );
ok( ($filename eq $inc_filename or index( resolved_filename(CI), $inc_filename ) == -1), "resolved_filename works" );

unshift @INC, sub {
  my $coderef  = shift;
  my $filename = shift;
  
  if ($filename eq 'Foo/Bar.pm') {
    open my $fh, '<', __FILE__;
    return (undef, $fh);
  }
  return
};

unshift @INC, [ sub { 
  my $arrayref = shift;
  my $filename = shift;

  die "args wrong" unless
     ref($arrayref->[0]) eq 'CODE' 
  && $arrayref->[1] == 1
  && $arrayref->[2] == 2
  && $arrayref->[3] == 3;

  if($filename eq 'Foo/Baz.pm') {
    open my $fh,  '<', __FILE__;
    return $fh;
  }
  return
}, 1,2,3];

unshift @INC, MyHook->new;

# Check the installed stuff
ok( installed( CI ), "installed detects installed" );
ok( ! installed( BAD ), "installed detects not installed" );
ok( installed( 'Foo::Bar'), "installed detects coderef installed" );
ok( installed( 'Foo::Baz'), "installed detects arrayref installed" );
ok( installed( 'Foo::Foo'), "installed detects object installed" );

package
  MyHook;

sub new {
  my($class) = @_;
  bless {}, $class;
}

sub MyHook::INC {
  my($self, $filename) = @_;
  die "self wrong" unless ref $self eq 'MyHook';
  
  if($filename eq 'Foo/Foo.pm') {
    open my $fh, '<', __FILE__;
    return $fh;
  }
  return;
}

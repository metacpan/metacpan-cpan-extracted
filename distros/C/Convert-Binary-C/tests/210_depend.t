################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN { plan tests => 90 }

my $CCCFG = require './tests/include/config.pl';

eval {
  $c1 = Convert::Binary::C->new( Include => ['tests/include/files'] );
  $c2 = Convert::Binary::C->new( Include => ['tests/include/files'] );
};
ok($@,'',"failed to create Convert::Binary::C objects");

eval {
  $c1->parse_file( 'tests/include/files/files.h' );
  $c2->parse( <<CODE );
#include <empty.h>
#include <ifdef.h>
#include <ifnull.h>
#include <something.h>
CODE
};
ok($@,'',"failed to parse C-code");

eval {
  $dep1 = $c1->dependencies;
  $dep2 = $c2->dependencies;
  @files1a = $c1->dependencies;
  @files2a = $c2->dependencies;
};
ok($@,'',"failed to retrieve dependencies");

@files1s = keys %$dep1;
@files2s = keys %$dep2;

@incs = qw(
  tests/include/files/empty.h
  tests/include/files/ifdef.h
  tests/include/files/ifnull.h
  tests/include/files/something.h
);

@ref1 = ( 'tests/include/files/files.h', @incs );
@ref2 = @incs;

s/\\/\//g for @files1a, @files2a, @files1s, @files2s;

print "# \@files1a => @files1a\n";

ok( join(',', sort @ref1), join(',', sort @files1a),
    "dependency names differ" );

print "# \@files1s => @files1s\n";

ok( join(',', sort @ref1), join(',', sort @files1s),
    "dependency names differ" );

print "# \@files2a => @files2a\n";

ok( join(',', sort @ref2), join(',', sort @files2a),
    "dependency names differ" );

print "# \@files2s => @files2s\n";

ok( join(',', sort @ref2), join(',', sort @files2s),
    "dependency names differ" );

eval {
  $c2 = Convert::Binary::C->new( %$CCCFG );
  $c2->parse_file( 'tests/include/include.c' );
};
ok($@,'',"failed to create object / parse file");

eval {
  $dep2 = $c2->dependencies;
};
ok($@,'',"failed to retrieve dependencies");

# check that the size, mtime and ctime entries are correct
for my $dep ( $dep1, $dep2 ) {
  for my $file ( keys %$dep ) {
    my($size, $mtime, $ctime) = (stat($file))[7,9,10];
    ok( $size,  $dep->{$file}{size},  "size mismatch for '$file'" );
    ok( $mtime, $dep->{$file}{mtime}, "mtime mismatch for '$file'" );
    ok( $ctime, $dep->{$file}{ctime}, "ctime mismatch for '$file'" );
  }
}

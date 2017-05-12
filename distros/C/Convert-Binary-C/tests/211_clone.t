################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN { plan tests => 35 }

my $CCCFG = require 'tests/include/config.pl';

eval {
  $orig = new Convert::Binary::C %$CCCFG;
};
ok($@,'',"failed to create Convert::Binary::C object");

eval {
  # Clone at least twice, to make sure memory of the first clone(s) will
  # get freed (and to make sure that cloning works a couple of times)
  $clone = $orig->clone->clone->clone;
};
ok($@,'',"failed to clone empty object");

ok( reccmp($orig->configure(), $clone->configure()), 1, "wrong configuration" );

eval {
  my $foo = $clone->struct;
};
ok( $@, qr/without parse data/, "parse data check failed" );

eval {
  $orig->parse_file( 'tests/include/include.c' );
};
ok($@,'',"failed to parse C-file");

eval {
  $clone = $orig->clone->clone->clone;
};
ok($@,'',"failed to clone full object");

eval {
  $dump1 = $orig->sourcify;
  $dump2 = $clone->sourcify;
};
ok($@,'',"failed to sourcify");
ok( $dump1, $dump2, "dumps differ" );

ok( reccmp(scalar $orig->dependencies, scalar $clone->dependencies), 1, "dependencies differ" );

ok( reccmp($orig->configure, $clone->configure), 1, "wrong configuration" );

@meth = qw( enum compound struct union typedef );

for my $meth ( @meth ) {
  my $meth_names = $meth.'_names';
  $ORIG{$meth}        = [$orig->$meth()];
  $ORIG{$meth_names}  = [$orig->$meth_names()];
  $ORIG{$meth.'hash'} = { map { ($_ => $orig->$meth($_)) } $orig->$meth_names() };
}

undef $orig;  # destroy original object

for my $meth ( @meth ) {
  my $meth_names = $meth.'_names';
  my @orig_names = sort @{$ORIG{$meth_names}};

  print "# checking if any names exist\n";
  ok( @orig_names > 0 );

  print "# checking counts for \$clone->$meth / \$clone->$meth_names\n";
  ok(scalar @{$ORIG{$_}}, scalar $clone->$_(), "count mismatch in $_")
      for $meth, $meth_names;

  print "# checking parsed names for \$clone->$meth_names\n";
  ok(join( ',', @orig_names ),
     join( ',', sort $clone->$meth_names() ),
     "parsed names differ in $meth_names" );

  ok( scalar grep $_, map {
        print "# checking \$clone->$meth( \"$_\" )\n";
        reccmp($ORIG{$meth.'hash'}{$_}, $clone->$meth($_))
      } @orig_names );
}

sub reccmp
{
  my($ref, $val) = @_;

  ref $ref or return $ref eq $val;

  if( ref $ref eq 'ARRAY' ) {
    @$ref == @$val or return 0;
    for( 0..$#$ref ) {
      reccmp( $ref->[$_], $val->[$_] ) or return 0;
    }
  }
  elsif( ref $ref eq 'HASH' ) {
    @{[keys %$ref]} == @{[keys %$val]} or return 0;
    for( keys %$ref ) {
      reccmp( $ref->{$_}, $val->{$_} ) or return 0;
    }
  }
  else { return 0 }

  return 1;
}

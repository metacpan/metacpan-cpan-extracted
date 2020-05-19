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

BEGIN { plan tests => 98 }

my $CCCFG = require './tests/include/config.pl';

eval {
  $orig  = Convert::Binary::C->new( %$CCCFG );
  @clone = map { Convert::Binary::C->new( %$CCCFG ) } 1 .. 2;
};
ok($@,'',"failed to create Convert::Binary::C objects");

eval {
  $orig->parse_file( 'tests/include/include.c' );
  $orig->parse( <<ENDPARSE );
  enum __foobar__;
  enum __undefined__;
  typedef int _int_2_, _int_3_, _int_4_;
ENDPARSE
};
ok($@,'',"failed to parse C-file");

eval {
  $dump1 = $orig->sourcify;
  $dump2 = $orig->sourcify;
  $dump3 = $orig->sourcify;
};
ok($@,'',"failed to dump definitions");

ok( $dump1, $dump2, "dumps 1+2 differ" );
ok( $dump2, $dump3, "dumps 2+3 differ" );

ok( !/^#line/m ) for $dump1, $dump2, $dump3;
ok( !/^#define/m ) for $dump1, $dump2, $dump3;

eval {
  $dump1 = $orig->sourcify( { Context => 1 } );
  $dump2 = $orig->sourcify( { Context => 1 } );
  $dump3 = $orig->sourcify( { Context => 1 } );
};
ok($@,'',"failed to dump definitions with context");

ok( $dump1, $dump2, "context dumps 1+2 differ" );
ok( $dump2, $dump3, "context dumps 2+3 differ" );

ok( /^#line\s+\d+\s+"[^"]+"/m ) for $dump1, $dump2, $dump3;
ok( !/^#define/m ) for $dump1, $dump2, $dump3;

eval {
  $dump1 = $orig->sourcify( { Defines => 1 } );
  $dump2 = $orig->sourcify( { Defines => 1 } );
  $dump3 = $orig->sourcify( { Defines => 1 } );
};
ok($@,'',"failed to dump definitions with context");

ok( $dump1, $dump2, "context dumps 1+2 differ" );
ok( $dump2, $dump3, "context dumps 2+3 differ" );

ok( !/^#line/m ) for $dump1, $dump2, $dump3;
ok( /^#define\s+\w+/m ) for $dump1, $dump2, $dump3;

eval {
  $dump1 = $orig->sourcify( { Context => 1, Defines => 1 } );
  $dump2 = $orig->sourcify( { Context => 1, Defines => 1 } );
  $dump3 = $orig->sourcify( { Context => 1, Defines => 1 } );
};
ok($@,'',"failed to dump definitions with context");

ok( $dump1, $dump2, "context dumps 1+2 differ" );
ok( $dump2, $dump3, "context dumps 2+3 differ" );

ok( /^#line\s+\d+\s+"[^"]+"/m ) for $dump1, $dump2, $dump3;
ok( /^#define\s+\w+/m ) for $dump1, $dump2, $dump3;

eval {
  $clone[0]->parse( $orig->sourcify( { Context => 1, Defines => 1 } ) );
};
ok($@,'',"failed to parse clone data (0)");

eval {
  $clone[1]->parse( $clone[0]->sourcify( { Context => 1, Defines => 1 } ) );
};
ok($@,'',"failed to parse clone data (1)");

for my $meth ( qw( enum compound struct union typedef macro ) ) {
  my $meth_names = $meth.'_names';
  my @orig_names = sort $orig->$meth_names();

  print "# checking if any names exist\n";
  ok( @orig_names > 0 );

  for my $c ( 0 .. $#clone ) {
    print "# checking counts for \$clone[$c]->$meth_names\n";
    ok(scalar $orig->$_(), scalar $clone[$c]->$_(), "count mismatch in $_ ($c)")
        for $meth, $meth_names;

    print "# checking parsed names for \$clone[$c]->$meth_names\n";
    ok(join( ',', @orig_names ),
       join( ',', sort $clone[$c]->$meth_names() ),
       "parsed names differ in $meth_names ($c)" );

    my @failed = map {
                   print "# checking \$clone[$c]->$meth( \"$_\" )\n";
                   reccmp($orig->$meth($_), $clone[$c]->$meth($_)) ? () : $_
                 } @orig_names;

    print "# $_\n" for @failed;

    ok(scalar @failed, 0, "$meth failed cloning");
  }
}

eval {
  $orig->clean->parse( <<ENDC );
#pragma pack( push, 1 )
typedef struct { struct B *x; } A;
typedef struct B { A *x; } B;
#pragma pack( pop )
enum buzz { BUZZER };
struct foo {
  enum { FOOBAR } bar;
  enum buzz       baz;
};
struct {
  struct {
    enum { FOO } bar;
  } x;
  union {
    enum { ZAP } husel;
  };
} x;
ENDC
};
ok($@,'',"failed to parse C code");

eval {
  $clone[0]->clean->parse( $orig->sourcify );
};
ok($@,'',"failed to parse sourcified code");

eval {
  $orig->clean->parse( 'typedef struct { ' . 'struct { 'x42 . 'int a;' . ' } a;'x42 . ' } rec;' );
};
ok($@,'',"failed to parse C code");

eval {
  $clone[1]->clean->parse( $orig->sourcify );
};
ok($@,'',"failed to parse sourcified code");

sub reccmp
{
  my($ref, $val) = @_;

  unless (ref $ref) {
    return 1 unless defined $ref || defined $val;
    return 0 unless defined $ref && defined $val;
    my $r = $ref eq $val;
    print "# $ref ne $val\n" unless $r;
    return $r;
  }

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

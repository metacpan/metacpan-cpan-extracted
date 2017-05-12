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

BEGIN {
  plan tests => 1907;
}

my $CCCFG = require 'tests/include/config.pl';

%basic = ( char => 1, short => 1, int => 1,
           long => 1, signed => 1, unsigned => 1,
           float => 1, double => 1, void => 1 );

eval {
  $c = Convert::Binary::C->new(
         ShortSize    => 2,
         IntSize      => 4,
         LongSize     => 4,
         LongLongSize => 8,
         EnumSize     => 4,
         PointerSize  => 4,
         Alignment    => 4,
       )->parse( <<ENDC );

typedef struct {
  int    a;
  short  b[3][1];
  long  *c;
  char   d;
  char  *e[2];
} Typedef, *PTypedef, ATypedef[2][3];

struct Struct {
  char  *a[2][2];
  struct {
    int  a;
    enum {
      ENUM
    }    b[2], *c;
  }      b[3], *c[2];
};

union Union {
  struct {
    char  color[2];
    long  size;
    union {
      struct {
        char a;
      }     foo;
      char  taste;
    }     stuff;
  }       apple;
  char    grape[3];
  struct {
    union {
      long  weight;
      short foo;
      enum { FOO } test;
      struct {
        char  a;
        union {
          short b;
          char  c;
        };
      }     compound;
    };
    short price[3];
  }       melon;
};

enum Enum {
  ZERO
};

struct Main {
  Typedef       a[2], *b, *c[3][4];
  struct Struct d[1][2], *e, *f[2];
  union Union   g, *h;
  enum Enum     i, *j, k[3], *l[2][3];
  int           m, *n, *o[4];
  PTypedef      p[2], *q, *r[3][4];
  ATypedef      s[2], *t, *u[3][4];
};

typedef struct {
  int foo;
} Array[2];

typedef struct {
  Array bar;
} Type;

ENDC
};
ok($@,'',"failed to create object / parse code");

@ref = (
  { members => [qw(.apple.color[0] .grape[0] .melon.weight .melon.foo .melon.test .melon.compound.a)],
    types   => [qw(char            char      long          short      enum        char             )], },
  { members => [qw(.apple.color[1] .grape[1] .melon.weight+1 .melon.foo+1 .melon.test+1 .melon.compound+1)],
    types   => [qw(char            char      long            short        enum          struct           )], },
  { members => [qw(.grape[2] .melon.compound.b .melon.compound.c .melon.weight+2 .melon.test+2 .apple+2)],
    types   => [qw(char      short             char              long            enum          struct  )], },
  { members => [qw(.melon.weight+3 .melon.test+3 .melon.compound.b+1 .apple+3)],
    types   => [qw(long            enum          short               struct  )], },
  { members => [qw(.apple.size .melon.price[0])],
    types   => [qw(long        short          )], },
  { members => [qw(.apple.size+1 .melon.price[0]+1)],
    types   => [qw(long          short            )], },
  { members => [qw(.melon.price[1] .apple.size+2)],
    types   => [qw(short           long         )], },
  { members => [qw(.apple.size+3 .melon.price[1]+1)],
    types   => [qw(long          short            )], },
  { members => [qw(.apple.stuff.foo.a .apple.stuff.taste .melon.price[2])],
    types   => [qw(char               char               short          )], },
  { members => [qw(.melon.price[2]+1 .apple+9)],
    types   => [qw(short             struct  )], },
  { members => [qw(.apple+10 .melon+10)],
    types   => [qw(struct    struct   )], },
  { members => [qw(.apple+11 .melon+11)],
    types   => [qw(struct    struct   )], },
);

for my $off ( 0 .. $c->sizeof( 'Union' )-1 ) {
  my @members = eval { $c->member( 'Union', $off ) };
  ok( $@, '' );
  for( 0 .. $#members ) {
    my $type = eval { $c->typeof( "Union $members[$_]" ) };
    ok( $@, '' );
    ok( $members[$_], $ref[$off]{members}[$_] );
    ok( $type, $ref[$off]{types}[$_] );
  }
}

run_tests($c);

eval {
  $c->configure(%$CCCFG)->clean->parse_file( 'tests/include/include.c' );
};
ok($@,'',"failed to create Convert::Binary::C object");

run_tests($c);

sub run_tests {
  my $c = shift;

  for my $mtype ( $c->compound_names ) {
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    my $fail = 0;
    my $success = 0;
    my $sizeof = $c->sizeof($mtype);
    for my $off ( 0 .. $sizeof ) {
      my @warn;
      my $member = eval { $c->member( $mtype, $off ) };
      if( $off == $sizeof ) {
        unless( $@ =~ /Offset $off out of range \(0 <= offset < $sizeof\)/ ) {
          print "# wrong error\n";
          $fail++;
        }
        else { $success++ }
      }
      else {
        unless( $@ eq '' ) {
          print "# unexpected error\n";
          $fail++;
        }
        else { $success++ }
        my @members = eval { $c->member( $mtype, $off ) };
        unless( $@ eq '' ) {
          print "# unexpected error\n";
          $fail++;
        }
        else { $success++ }
        unless( @members > 0 and $members[0] eq $member ) {
          print "# wrong members in list context\n";
          $fail++;
        }
        else { $success++ }
        for $member( @members ) {
          my $type = eval { $c->typeof( "$mtype $member" ) || '[pad]' };
          unless( $@ eq '' ) {
            print "# unexpected error\n";
            $fail++;
          }
          else { $success++ }
          my $offset = eval { $c->offsetof($mtype, $member) };
          unless( $@ eq '' ) {
            print "# unexpected error\n";
            $fail++;
          }
          else { $success++ }
          unless( $offset == $off ) {
            print "# invalid offset\n";
            $fail++;
          }
          else { $success++ }
          $member =~ s/\+\d+$//;
          while( $member ) {
            my $typeof = eval { $c->typeof("$mtype $member") };
            unless( $@ eq '' ) {
              print "# unexpected error\n";
              $fail++;
            }
            else { $success++ }
            unless( defined $typeof ) {
              print "# undefined type\n";
              $fail++;
            }
            else { $success++ }
            $member =~ s/(?:\[\d+\]|\.\w+|^\w+)$//;
          }
        }
      }
    }
    for( @warn ) {
      print "# wrong warning\n";
      $fail++;
    }
    ok( $fail == 0 );
    ok( $success > 0 );
  }

  for my $t ( $c->compound_names, $c->typedef_names ) {
    my %h;
    my @m;
    my $fail = 0;
    my $success = 0;
    my $meth = $c->def($t) or next;
    my $def = $c->$meth( $t );

    $meth eq 'typedef' and $h{$t} = $t;
    get_types( \%h, \@m, $c, $t, $def );

    while( my($k,$v) = each %h ) {
      my $to = $c->typeof($k);
      unless( $to eq $v ) {
        print "# typeof mismatch for $meth <$k> ('$to' != '$v')\n";
        $fail++;
      }
      else { $success++ }
    }
    ok( $fail == 0 );
    ok( $success > 0 );

    if( @m >= 2 ) {
      $fail = $success = 0;
      my %dup;
      for my $member ( $c->member($t) ) {
        my $ref = shift @m;
        warn "[$t][$member]" unless defined $ref;
        if( $t.$member ne $ref ) {
          print "# '$t$member' ne '$ref'\n";
          $fail++;
        }
        else { $success++ }
        if( $dup{$member}++ ) {
          print "# duplicate member '$t$member' (count=$dup{$member})\n";
          $fail++;
        }
        else { $success++ }
      }
      ok( $fail == 0 );
      ok( $success > 0 );
    }
  }
}


sub get_types {
  my($r, $m, $c, $t, $d) = @_;
  if( exists $d->{declarator} ) {
    my($p,$n,$a) = $d->{declarator} =~ /^(\*?)(\w+)((?:\[\])?(?:\[\d+\])*)$/ or die "BOO!";
    my $dim = [$a =~ /\[(\d+)?\]/g];
    get_array($r, $m, $c, $t, $d->{type}, $p, $dim);
  }
  elsif( exists $d->{declarations} ) {
    # it's a compound
    for my $d1 ( @{$d->{declarations}} ) {
      if( exists $d1->{declarators} ) {
        for my $d2 ( @{$d1->{declarators}} ) {
          my($p,$n,$b,$a) = $d2->{declarator} =~ /^(\*?)(\w*)(:\d+)?((?:\[\])?(?:\[\d+\])*)$/ or die "BOO!";
          defined $b and $n eq '' and next;
          my $dim = [$a =~ /\[(\d+)?\]/g];
          get_array($r, $m, $c, "$t.$n", $b ? "$d1->{type} $b" : $d1->{type}, $p, $dim);
        }
      }
      else {
        get_types($r, $m, $c, $t, $d1->{type});
      }
    }
  }
  else {
    push @$m, $t;
  }
}

sub get_array {
  my($r, $m, $c, $t, $d, $p, $dim) = @_;
  my $rt;

  if( ref $d ) {
    if( exists $d->{declarations} ) {
      $rt = $d->{type};
    }
    elsif( exists $d->{enumerators} ) {
      $rt = 'enum';
    }
    else { die "BOO!" }
  }
  else { $rt = $d }

  my $a = join '', map { defined $_ ? "[$_]" : '[]' } @$dim;

  $p and $rt .= " $p";
  $a and $rt .= " $a";

  $r->{$t} ||= $rt;

  if( @$dim ) {
    my @dim = @$dim;
    my $cd = shift @dim;
    defined $cd or return; # don't add incomplete types
    for my $i ( 0 .. $cd-1 ) {
      get_array($r, $m, $c, $t."[$i]", $d, $p, \@dim);
    }
  }
  elsif( !$p ) {
    if( ref $d ) {
      get_types($r, $m, $c, $t.$a, $d);
    }
    else {
      if( $d =~ /^(?:struct|union)/ ) {
        get_types($r, $m, $c, $t.$a, $c->compound($d));
      }
      elsif( $d =~ /^enum\s+\w+/ ) {
        push @$m, $t;
      }
      elsif( $d =~ /^\w+$/ and not exists $basic{$d} ) {
        get_types($r, $m, $c, $t.$a, $c->typedef($d));
      }
      else {
        push @$m, $t;
      }
    }
  }
  else {
    push @$m, $t;
  }
}

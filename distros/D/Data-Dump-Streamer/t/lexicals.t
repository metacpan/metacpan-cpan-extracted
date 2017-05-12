use strict;
use warnings;

#$Id: lexicals.t 26 2006-04-16 15:18:52Z demerphq $#

use Data::Dump::Streamer;
use Test::More tests => 14;
(my $helper=$0)=~s/\w+\.\w+$/test_helper.pl/;
require $helper;
diag "\nPadWalker ",
    eval "use PadWalker 0.99; 1" ? qq($PadWalker::VERSION is) : "isn't",
    " installed";

$::No_Redump=$::No_Redump=1;
$::No_Dumper=$::No_Dumper=1;

{
    my $v = 'foo';
    my @v = ('f','o','o');
    my $z = 1;
    no warnings;
    sub get_sub {
        my @v=(@v,1);
        my @y=('b','a','r');
        my $x = join " ", @_, @v, $v, $z;

        sub {
            my @y = ( $x, "A".."G", @y);
            my @v = ( "M".."R", @v);
            my $x = join ":", @y, @v, $z||'undef';
            $x . "!!";
        },
        sub { $x = shift; $z = shift if @_; },
        do {
            my @y=split //,'fuzz';
            sub { return join "+",$z,$x,@y;}
        },

    }
}



{
    my $expect;
    if ( $] >= 5.013_001 ) {
        $expect = <<'EXPECT';
my ($x,$z,@v,@y,@y_eclipse_1);
$x = 'f o o 1 foo 1';
$z = 1;
@v = (
       'f',
       ( 'o' ) x 2,
       1
     );
@y = (
       'b',
       'a',
       'r'
     );
@y_eclipse_1 = (
                 'f',
                 'u',
                 ( 'z' ) x 2
               );
$CODE1 = sub {
           my(@y) = ($x, ('A', 'B', 'C', 'D', 'E', 'F', 'G'), @y);
           my(@v) = (('M', 'N', 'O', 'P', 'Q', 'R'), @v);
           my $x = join(':', @y, @v, $z || 'undef');
           $x . '!!';
         };
$CODE2 = sub {
           $x = shift();
           $z = shift() if @_;
         };
$CODE3 = sub {
           return join('+', $z, $x, @y_eclipse_1);
         };

EXPECT
    }
    else {
        $expect = <<'EXPECT';
my ($x,$z,@v,@y,@y_eclipse_1);
$x = 'f o o 1 foo 1';
$z = 1;
@v = (
       'f',
       ( 'o' ) x 2,
       1
     );
@y = (
       'b',
       'a',
       'r'
     );
@y_eclipse_1 = (
                 'f',
                 'u',
                 ( 'z' ) x 2
               );
$CODE1 = sub {
           my(@y) = ($x, ('A', 'B', 'C', 'D', 'E', 'F', 'G'), @y);
           my(@v) = (('M', 'N', 'O', 'P', 'Q', 'R'), @v);
           my $x = join(':', @y, @v, $z || 'undef');
           $x . '!!';
         };
$CODE2 = sub {
           $x = shift @_;
           $z = shift @_ if @_;
         };
$CODE3 = sub {
           return join('+', $z, $x, @y_eclipse_1);
         };

EXPECT
    }

    test_dump( 'Lexicals!!', scalar(Dump()), ( get_sub() ), $expect);
}

{
#    local $Data::Dump::Streamer::DEBUG=1;

    my $x;
    $x = sub { $x };

    test_dump( "Self-referential", scalar(Dump()),( $x ), <<'EXPECT');
$x = sub {
       $x;
     };
EXPECT
}

{
    my $a;
    my $b = sub { $a };

    test_dump( "Nested closure with shared state", scalar(Dump()),
        ( sub { $a, $b } ), <<'EXPECT');
my ($a,$b);
$a = undef;
$b = sub {
       $a;
     };
$CODE1 = sub {
           $a, $b;
         };
EXPECT
}

{

    my $a;
    my $b;
    my $z = sub { $a, $b };
    my $y = do { my $b; sub { $a, $b } };
    test_dump( "Overlapping declarations", scalar(Dump()),
        ( $y, $z ), <<'EXPECT');
my ($a,$b,$b_eclipse_1);
$a = undef;
$b = undef;
$b_eclipse_1 = undef;
$CODE1 = sub {
           $a, $b;
         };
$CODE2 = sub {
           $a, $b_eclipse_1;
         };
EXPECT
}

{

    my $a;
    my $z = sub { $a };
    my $b;
    my $y = sub { $a, $b };

    test_dump( "Overlapping declarations two", scalar(Dump()),
        ( $y, $z ), <<'EXPECT');
my ($a,$b);
$a = undef;
$b = undef;
$CODE1 = sub {
           $a, $b;
         };
$CODE2 = sub {
           $a;
         };
EXPECT
}

{

    my $z = do {
        my $a;
        sub { $a };
    };
    my $y = do {
        my $a;
        sub { $a };
    };

    test_dump( "Unrelated environments", scalar(Dump()),
        ( $z, $y ), <<'EXPECT');
my ($a,$a_eclipse_1);
$a = undef;
$a_eclipse_1 = undef;
$CODE1 = sub {
           $a;
         };
$CODE2 = sub {
           $a_eclipse_1;
         };
EXPECT
}

{
    my $bad = \&Not::Implemented;
    test_dump( "Unimplemented code", scalar(Dump()), ( $bad ), <<'EXPECT');
$CODE1 = \&Not::Implemented;
EXPECT
}

{
    my $a;
    my $z = sub { $a };

    test_dump(  "Shared state/enclosed", scalar(Dump()), ( $z, sub { $a, $z } ),
        <<'EXPECT');
my ($a);
$a = undef;
$z = sub {
       $a;
     };
$CODE1 = sub {
           $a, $z;
         };
EXPECT

    test_dump(  "Named  Shared state/enclosed", scalar(Dump())->Names('foo','bar'),
        ( $z, sub { $a, $z } ),
        <<'EXPECT');
my ($a);
$a = undef;
$foo = sub {
         $a;
       };
$bar = sub {
         $a, $foo;
       };
EXPECT
}
{

    no warnings;
    our $b;
    my $a;
    my $b = sub { $b };

    test_dump(  "sub b", scalar(Dump()), ( $b ), <<'EXPECT');
$CODE1 = sub {
           $b;
         };
EXPECT

    test_dump(  "double sub b", scalar(Dump()), ( sub { $b } ), <<'EXPECT');
my ($b);
$b = sub {
       $b;
     };
$CODE1 = sub {
           $b;
         };
EXPECT


}
{

    my $a = "foo";
    my $x = sub { return $a . "bar" };
    sub f { print $x->() }
    test_dump(  "recursively nested subs", scalar(Dump()), ( \&f ), <<'EXPECT');
my ($a,$x);
$a = 'foo';
$x = sub {
       return $a . 'bar';
     };
$CODE1 = sub {
           print &$x();
         };
EXPECT
}
{
    test_dump(  "EclipseName", Dump->EclipseName('%d_foiled_%s'),
        ( [
              map {
                my $x;
                my $x_eclipse_1;
                sub {$x}, sub {$x_eclipse_1};
              } 1, 2
            ] ), <<'EXPECT');
my ($1_foiled_x,$1_foiled_x_eclipse_1,$x,$x_eclipse_1);
$1_foiled_x = undef;
$1_foiled_x_eclipse_1 = undef;
$x = undef;
$x_eclipse_1 = undef;
$ARRAY1 = [
            sub {
              $x;
            },
            sub {
              $x_eclipse_1;
            },
            sub {
              $1_foiled_x;
            },
            sub {
              $1_foiled_x_eclipse_1;
            }
          ];

EXPECT

}
{
    test_dump(  "EclipseName 2", Dump->EclipseName('%s_muhaha_%d'),
        ( [
              map {
                my $x;
                my $x_eclipse_1;
                sub {$x}, sub {$x_eclipse_1};
              } 1, 2
            ] ), <<'EXPECT');
my ($x,$x_eclipse_1,$x_eclipse_1_muhaha_1,$x_muhaha_1);
$x = undef;
$x_eclipse_1 = undef;
$x_eclipse_1_muhaha_1 = undef;
$x_muhaha_1 = undef;
$ARRAY1 = [
            sub {
              $x;
            },
            sub {
              $x_eclipse_1;
            },
            sub {
              $x_muhaha_1;
            },
            sub {
              $x_eclipse_1_muhaha_1;
            }
          ];
EXPECT

}


if (0){
    #no warnings;
    my @close;
    my ($x,$y)=(3.141,5);
    for my $a ($x, $y) {
        for my $b ($x, $y) {
            push @close, sub { ++$a, ++$b; return } if \$a != \$b
        }
    }
    my $out=Dump(\@close)->Out();
    print $out;
    #print B::Deparse::WARN_MASK;
}


__END__

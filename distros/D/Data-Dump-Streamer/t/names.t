use Test::More tests => 50;
BEGIN { use_ok( 'Data::Dump::Streamer', qw(:undump Dump) ); }
use strict;
use warnings;
use Data::Dumper;

#$Id: names.t 26 2006-04-16 15:18:52Z demerphq $#

# imports same()
(my $helper=$0)=~s/\w+\.\w+$/test_helper.pl/;
require $helper;
# use this one for simple, non evalable tests. (GLOB)
#   same ( $got,$expected,$name,$obj )
#
# use this one for eval checks and dumper checks but NOT for GLOB's
# same ( $name,$obj,$expected,@args )

my $dump;
my $o = Data::Dump::Streamer->new();

isa_ok( $o, 'Data::Dump::Streamer' );
# Make sure Dump($var)->Names($name)->Out() works...
is (scalar(Dump(@{[0,1]})->Names('foo','bar')->Out()),"\$foo = 0;\n\$bar = 1;\n",'Dump()->Names()');
{
    same( "Named", $o->Declare(0)->Names('x','y'), <<'EXPECT', ( @{[ 0 , 1 ]} ) );
$x = 0;
$y = 1;
EXPECT
}
{
    my $s=0;
    my $a=[];
    my $h={};
    my $c=sub{1};

    same( "Named Vars ", $o->Declare(0)->Names('*s','*a','*h','*c'), <<'EXPECT', ( $s,$a,$h,$c ) );
$s = 0;
@a = ();
%h = ();
sub c {
  1;
};
EXPECT
    #local $Data::Dump::Streamer::DEBUG=0;
    same( "Named Vars Refs", $o->Declare(0)->Names('*s','*a','*h','*c'), <<'EXPECT', ( $s,$a,$h,$c, ),\( $s,$a,$h,$c, ) );
$s = 0;
@a = ();
%h = ();
sub c {
  1;
};
$SCALAR1 = \$s;
$REF1 = \\@a;
$REF2 = \\%h;
$REF3 = \\&c;
EXPECT
#$o->diag;
}
{
my $z=[1,2,3];
my $x=\$z->[0];
my $y=\$z->[2];

    same( "Named() two", $o->Names('*z','x','y'), <<'EXPECT', ( $z,$x,$y ) );
@z = (
       1,
       2,
       3
     );
$x = \$z[0];
$y = \$z[2];
EXPECT
    #local $Data::Dump::Streamer::DEBUG=1;
    same( "Named() three", $o->Names('x','y','*z'), <<'EXPECT', ( $x,$y,$z ) );
$x = 'R: $z[0]';
$y = 'R: $z[2]';
@z = (
       1,
       2,
       3
     );
$x = \$z[0];
$y = \$z[2];
EXPECT
}
{

    my ($a,$b);
    $a = [{ a => \$b }, { b => undef }];
    $b = [{ c => \$b }, { d => \$a }];
    same( "Named Harder", $o->Names('*prime','ref'), <<'EXPECT', ( $a,$b ) );
@prime = (
           { a => \$ref },
           { b => undef }
         );
$ref = [
         { c => $prime[0]{a} },
         { d => \\@prime }
       ];
EXPECT

    same( "Named Harder Swap", $o->Names('prime','*ref'), <<'EXPECT', ( $a,$b ) );
$prime = [
           { a => \\@ref },
           { b => undef }
         ];
@ref = (
         { c => $prime->[0]{a} },
         { d => \$prime }
       );
EXPECT
    same( "Named Harder Two", $o->Names('*prime','*ref'), <<'EXPECT', ( $a,$b ) );
@prime = (
           { a => \\@ref },
           { b => undef }
         );
@ref = (
         { c => $prime[0]{a} },
         { d => \\@prime }
       );
EXPECT
#print $o->diag;
}
{
    #local $Data::Dump::Streamer::DEBUG=1;
    my ($a,$b);
    $a = [undef, { b => undef }];
    $b = [undef, { d => $a }];
    $b->[0]={ c => $b };
    $a->[0]={ a => $b };
    same( "Named Simpler", $o->Names('*prime','ref'), <<'EXPECT', ( $a,$b ) );
@prime = (
           { a => 'V: $ref' },
           { b => undef }
         );
$ref = [
         { c => 'V: $ref' },
         { d => \@prime }
       ];
$prime[0]{a} = $ref;
$ref->[0]{c} = $ref;
EXPECT
    same( "Named Simpler Swap", $o->Names('prime','*ref'), <<'EXPECT', ( $a,$b ) );
$prime = [
           { a => \@ref },
           { b => undef }
         ];
@ref = (
         { c => \@ref },
         { d => $prime }
       );
EXPECT
    same( "Named Simpler Two", $o->Names('*prime','*ref'), <<'EXPECT', ( $a,$b ) );
@prime = (
           { a => \@ref },
           { b => undef }
         );
@ref = (
         { c => \@ref },
         { d => \@prime }
       );
EXPECT
#print $o->diag;
}
{
    same( "Declare Named()", $o->Declare(1)->Names('x','y'), <<'EXPECT', ( @{[ 0 , 1 ]} ) );
my $x = 0;
my $y = 1;
EXPECT
}
{
my $z=[1,2,3];
my $x=\$z->[0];
my $y=\$z->[2];

    same( "Declare Named() two", $o->Names('*z','x','y'), <<'EXPECT', ( $z,$x,$y ) );
my @z = (
          1,
          2,
          3
        );
my $x = \$z[0];
my $y = \$z[2];
EXPECT

    same( "Declare Named() three", $o->Names('x','y','*z'), <<'EXPECT', ( $x,$y,$z ) );
my $x = 'R: $z[0]';
my $y = 'R: $z[2]';
my @z = (
          1,
          2,
          3
        );
$x = \$z[0];
$y = \$z[2];
EXPECT
}
{
    #local $Data::Dump::Streamer::DEBUG=1;
    my ($a,$b);
    $a = [{ a => \$b }, { b => undef }];
    $b = [{ c => \$b }, { d => \$a }];
    same( "Declare Named Harder", $o->Names('*prime','ref'), <<'EXPECT', ( $a,$b ) );
my @prime = (
              { a => 'R: $ref' },
              { b => undef }
            );
my $ref = [
            { c => 'V: $prime[0]{a}' },
            { d => \\@prime }
          ];
$prime[0]{a} = \$ref;
$ref->[0]{c} = $prime[0]{a};
EXPECT
    same( "Declare Named Harder Swap", $o->Names('prime','*ref'), <<'EXPECT', ( $a,$b ) );
my $prime = [
              { a => \do { my $v = 'V: @ref' } },
              { b => undef }
            ];
my @ref = (
            { c => $prime->[0]{a} },
            { d => \$prime }
          );
${$prime->[0]{a}} = \@ref;
EXPECT
    same( "Declare Named Harder Two", $o->Names('*prime','*ref'), <<'EXPECT', ( $a,$b ) );
my @prime = (
              { a => \do { my $v = 'V: @ref' } },
              { b => undef }
            );
my @ref = (
            { c => $prime[0]{a} },
            { d => \\@prime }
          );
${$prime[0]{a}} = \@ref;
EXPECT

#print $o->diag;
}
{
    #local $Data::Dump::Streamer::DEBUG=1;
    my ($a,$b);
    $a = [undef, { b => undef }];
    $b = [undef, { d => $a }];
    $b->[0]={ c => $b };
    $a->[0]={ a => $b };
    same( "Declare Named Simpler", $o->Names('*prime','ref'), <<'EXPECT', ( $a,$b ) );
my @prime = (
              { a => 'V: $ref' },
              { b => undef }
            );
my $ref = [
            { c => 'V: $ref' },
            { d => \@prime }
          ];
$prime[0]{a} = $ref;
$ref->[0]{c} = $ref;
EXPECT
    same( "Declare Named Simpler Swap", $o->Names('prime','*ref'), <<'EXPECT', ( $a,$b ) );
my $prime = [
              { a => 'V: @ref' },
              { b => undef }
            ];
my @ref = (
            { c => 'V: @ref' },
            { d => $prime }
          );
$prime->[0]{a} = \@ref;
$ref[0]{c} = \@ref;
EXPECT
    same( "Declare Named Simpler Two", $o->Names('*prime','*ref'), <<'EXPECT', ( $a,$b ) );
my @prime = (
              { a => 'V: @ref' },
              { b => undef }
            );
my @ref = (
            { c => 'V: @ref' },
            { d => \@prime }
          );
$prime[0]{a} = \@ref;
$ref[0]{c} = \@ref;
EXPECT
#print $o->diag;
}
{
    #local $Data::Dump::Streamer::DEBUG=1;
    my ($x,$y,$z);
    $z = [($x={ a => \$y }), { b => undef }];
    $y = [{ c => \$y }, ({ d => \$z })];

    same( "Hash Named Harder", $o->Declare(0)->Names('*prime','ref'), <<'EXPECT', ( $x,$y ) );
%prime = ( a => \$ref );
$ref = [
         { c => $prime{a} },
         { d => \[
           \%prime,
           { b => undef }
         ] }
       ];
EXPECT
    same( "Hash Named Harder Swap", $o->Names('prime','*ref'), <<'EXPECT', ( $y,$x ) );
$prime = [
           { c => 'V: $ref{a}' },
           { d => \[
             \%ref,
             { b => undef }
           ] }
         ];
%ref = ( a => \$prime );
$prime->[0]{c} = $ref{a};
EXPECT
    same( "Hash Named Harder Two", $o->Names('*prime','*ref'), <<'EXPECT', ( $x,$y ) );
%prime = ( a => \\@ref );
@ref = (
         { c => $prime{a} },
         { d => \[
           \%prime,
           { b => undef }
         ] }
       );
EXPECT
#print $o->diag;
}
{
    #local $Data::Dump::Streamer::DEBUG=1;
    my ($x,$y,$z);
    $z = [undef, { b => undef }];
    $y = [undef, { d => $z }];
    $x=$y->[0]={ c => $y };
    $z->[0]={ a => $y };

    same( "Hash Named Simpler", $o->Names('*prime','ref'), <<'EXPECT', ( $x,$y ) );
%prime = ( c => 'V: $ref' );
$ref = [
         \%prime,
         { d => [
           { a => 'V: $ref' },
           { b => undef }
         ] }
       ];
$prime{c} = $ref;
$ref->[1]{d}[0]{a} = $ref;
EXPECT
    same( "Hash Named Simpler Swap", $o->Names('prime','*ref'), <<'EXPECT', ( $x,$y ) );
$prime = { c => \@ref };
@ref = (
         $prime,
         { d => [
           { a => \@ref },
           { b => undef }
         ] }
       );
EXPECT
    same( "Hash Named Simpler Two", $o->Names('*prime','*ref'), <<'EXPECT', ( $x,$y ) );
%prime = ( c => \@ref );
@ref = (
         \%prime,
         { d => [
           { a => \@ref },
           { b => undef }
         ] }
       );
EXPECT
#print $o->diag;
}
{
my $z={0..3};
my $x=\$z->{0};
my $y=\$z->{2};

    same( "Hash Declare Named() two", $o->Declare(1)->Names('*z','x','y'), <<'EXPECT', ( $z,$x,$y ) );
my %z = (
          0 => 1,
          2 => 3
        );
my $x = \$z{0};
my $y = \$z{2};
EXPECT

    same( "Hash Declare Named() three", $o->Names('x','y','*z'), <<'EXPECT', ( $x,$y,$z ) );
my $x = 'R: $z{0}';
my $y = 'R: $z{2}';
my %z = (
          0 => 1,
          2 => 3
        );
$x = \$z{0};
$y = \$z{2};
EXPECT
}
{
    #local $Data::Dump::Streamer::DEBUG=1;
    my ($x,$y,$z);
    $z = [($x={ a => \$y }), { b => undef }];
    $y = [{ c => \$y }, { d => \$z }];
    same( "Hash Declare Named Harder", $o->Names('*prime','ref'), <<'EXPECT', ( $x,$y ) );
my %prime = ( a => 'R: $ref' );
my $ref = [
            { c => 'V: $prime{a}' },
            { d => \[
              \%prime,
              { b => undef }
            ] }
          ];
$prime{a} = \$ref;
$ref->[0]{c} = $prime{a};
EXPECT
    same( "Hash Declare Named Harder Swap", $o->Names('prime','*ref'), <<'EXPECT', ( $x,$y ) );
my $prime = { a => \do { my $v = 'V: @ref' } };
my @ref = (
            { c => $prime->{a} },
            { d => \[
              $prime,
              { b => undef }
            ] }
          );
${$prime->{a}} = \@ref;
EXPECT
    same( "Hash Declare Named Harder Two", $o->Names('*prime','*ref'), <<'EXPECT', ( $x,$y ) );
my %prime = ( a => \do { my $v = 'V: @ref' } );
my @ref = (
            { c => $prime{a} },
            { d => \[
              \%prime,
              { b => undef }
            ] }
          );
${$prime{a}} = \@ref;
EXPECT

#print $o->diag;
}
{
    #local $Data::Dump::Streamer::DEBUG=1;
    my ($x,$y,$z);
    $z = [undef, { b => undef }];
    $y = [undef, { d => $z }];
    $x=$y->[0]={ c => $y };
    $z->[0]={ a => $y };
    same( "Hash Declare Named Simpler", $o->Names('*prime','ref'), <<'EXPECT', ( $x,$y ) );
my %prime = ( c => 'V: $ref' );
my $ref = [
            \%prime,
            { d => [
              { a => 'V: $ref' },
              { b => undef }
            ] }
          ];
$prime{c} = $ref;
$ref->[1]{d}[0]{a} = $ref;
EXPECT
    same( "Hash Declare Named Simpler Swap", $o->Names('prime','*ref'), <<'EXPECT', ( $x,$y ) );
my $prime = { c => 'V: @ref' };
my @ref = (
            $prime,
            { d => [
              { a => 'V: @ref' },
              { b => undef }
            ] }
          );
$prime->{c} = \@ref;
$ref[1]{d}[0]{a} = \@ref;
EXPECT
    same( "Hash Declare Named Simpler Two", $o->Names('*prime','*ref'), <<'EXPECT', ( $x,$y ) );
my %prime = ( c => 'V: @ref' );
my @ref = (
            \%prime,
            { d => [
              { a => 'V: @ref' },
              { b => undef }
            ] }
          );
$prime{c} = \@ref;
$ref[1]{d}[0]{a} = \@ref;
EXPECT
$o->Declare(0);
#print $o->diag;
}
{
    #local $Data::Dump::Streamer::DEBUG=1;
    my ($x,$y,$z);
    $z = [undef, { b => undef }];
    $y = bless [undef, { d => $z }],'bar';
    $x=bless(($y->[0]={ c => $y }),'foo');
    $z->[0]={ a => $y };
    same( "Blessed Declare Named Simpler", $o->Declare(1)->Names('*prime','ref'), <<'EXPECT', ( $x,$y ) );
my %prime = ( c => 'V: $ref' );
my $ref = bless( [
            bless( \%prime, 'foo' ),
            { d => [
              { a => 'V: $ref' },
              { b => undef }
            ] }
          ], 'bar' );
$prime{c} = $ref;
$ref->[1]{d}[0]{a} = $ref;
EXPECT
    same( "Blessed Declare Named Simpler Swap", $o->Names('prime','*ref'), <<'EXPECT', ( $x,$y ) );
my $prime = bless( { c => 'V: @ref' }, 'foo' );
my @ref = (
            $prime,
            { d => [
              { a => 'V: @ref' },
              { b => undef }
            ] }
          );
$prime->{c} = bless( \@ref, 'bar' );
$ref[1]{d}[0]{a} = bless( \@ref, 'bar' );
EXPECT
    same( "Blessed Declare Named Simpler Two", $o->Names('*prime','*ref'), <<'EXPECT', ( $x,$y ) );
my %prime = ( c => 'V: @ref' );
my @ref = (
            bless( \%prime, 'foo' ),
            { d => [
              { a => 'V: @ref' },
              { b => undef }
            ] }
          );
$prime{c} = bless( \@ref, 'bar' );
$ref[1]{d}[0]{a} = bless( \@ref, 'bar' );
EXPECT
$o->Declare(0);
#print $o->diag;
}
{
    #local $Data::Dump::Streamer::DEBUG=1;
    my ($x,$y,$z);
    $z = [undef, { b => undef }];
    $y = bless [undef, { d => $z }],'bar';
    $x=bless(($y->[0]={ c => $y }),'foo');
    $z->[0]={ a => $y };
    same( "Blessed Named Simpler", $o->Declare(0)->Names('*prime','ref'), <<'EXPECT', ( $x,$y ) );
%prime = ( c => 'V: $ref' );
$ref = bless( [
         bless( \%prime, 'foo' ),
         { d => [
           { a => 'V: $ref' },
           { b => undef }
         ] }
       ], 'bar' );
$prime{c} = $ref;
$ref->[1]{d}[0]{a} = $ref;
EXPECT
    same( "Blessed Named Simpler Swap", $o->Names('prime','*ref'), <<'EXPECT', ( $x,$y ) );
$prime = bless( { c => bless( \@ref, 'bar' ) }, 'foo' );
@ref = (
         $prime,
         { d => [
           { a => bless( \@ref, 'bar' ) },
           { b => undef }
         ] }
       );
EXPECT
    same( "Blessed Named Simpler Two", $o->Names('*prime','*ref'), <<'EXPECT', ( $x,$y ) );
%prime = ( c => bless( \@ref, 'bar' ) );
@ref = (
         bless( \%prime, 'foo' ),
         { d => [
           { a => bless( \@ref, 'bar' ) },
           { b => undef }
         ] }
       );
EXPECT
$o->Declare(0);
#print $o->diag;
}
{
    #local $Data::Dump::Streamer::DEBUG=1;
    my ($x,$y,$z);
    $z = [undef, { b => undef }];
    $y = bless [undef, { d => \$z }],'bar';
    $x=bless(($y->[0]={ c => \$y }),'foo');
    $z->[0]={ a => \$y };
    same( "Harder Blessed Named", $o->Declare(0)->Names('*prime','ref'), <<'EXPECT', ( $x,$y ) );
%prime = ( c => \$ref );
$ref = bless( [
         bless( \%prime, 'foo' ),
         { d => \[
           { a => $prime{c} },
           { b => undef }
         ] }
       ], 'bar' );
EXPECT
    same( "Harder Blessed Named Swap", $o->Names('prime','*ref'), <<'EXPECT', ( $x,$y ) );
$prime = bless( { c => \bless( \@ref, 'bar' ) }, 'foo' );
@ref = (
         $prime,
         { d => \[
           { a => $prime->{c} },
           { b => undef }
         ] }
       );
EXPECT
    same( "Harder Blessed Named Two", $o->Names('*prime','*ref'), <<'EXPECT', ( $x,$y ) );
%prime = ( c => \bless( \@ref, 'bar' ) );
@ref = (
         bless( \%prime, 'foo' ),
         { d => \[
           { a => $prime{c} },
           { b => undef }
         ] }
       );
EXPECT
$o->Declare(0);
#print $o->diag;
}
{
    #local $Data::Dump::Streamer::DEBUG=1;
    my ($x,$y,$z);
    $z = [undef, { b => undef }];
    $y = bless [undef, { d => \$z }],'bar';
    $x=bless(($y->[0]={ c => \$y }),'foo');
    $z->[0]={ a => \$y };
    same( "Declare Harder Blessed Named", $o->Declare(1)->Names('*prime','ref'), <<'EXPECT', ( $x,$y ) );
my %prime = ( c => 'R: $ref' );
my $ref = bless( [
            bless( \%prime, 'foo' ),
            { d => \[
              { a => 'V: $prime{c}' },
              { b => undef }
            ] }
          ], 'bar' );
$prime{c} = \$ref;
${$ref->[1]{d}}->[0]{a} = $prime{c};
EXPECT
    same( "Declare Harder Blessed Named Swap", $o->Names('prime','*ref'), <<'EXPECT', ( $x,$y ) );
my $prime = bless( { c => \do { my $v = 'V: @ref' } }, 'foo' );
my @ref = (
            $prime,
            { d => \[
              { a => $prime->{c} },
              { b => undef }
            ] }
          );
${$prime->{c}} = bless( \@ref, 'bar' );
EXPECT
    same( "Declare Harder Blessed Named Two", $o->Names('*prime','*ref'), <<'EXPECT', ( $x,$y ) );
my %prime = ( c => \do { my $v = 'V: @ref' } );
my @ref = (
            bless( \%prime, 'foo' ),
            { d => \[
              { a => $prime{c} },
              { b => undef }
            ] }
          );
${$prime{c}} = bless( \@ref, 'bar' );
EXPECT
$o->Declare(0);
#print $o->diag;
}
{
    my $x=[];
    push @$x,\$x;
    same( "Doc Array Self ref", $o->Names('*x')->Declare(0), <<'EXPECT', ( $x ) );
@x = ( \\@x );
EXPECT
}
 #Dump->Names('*x')->Out($x);
__END__
# with eval testing
{
    same( "", $o, <<'EXPECT', (  ) );
EXPECT
}
# without eval testing
{
    same( $dump = $o->Data()->Out, <<'EXPECT', "", $o );
EXPECT
}

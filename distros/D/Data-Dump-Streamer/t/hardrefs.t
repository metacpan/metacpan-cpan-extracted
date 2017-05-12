use Test::More tests => 16;

#$Id: hardrefs.t 26 2006-04-16 15:18:52Z demerphq $#

BEGIN { use_ok( 'Data::Dump::Streamer', qw(:undump) ); }
use strict;
use warnings;
use Data::Dumper;

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

{                # Hard Refs

    my $array = [];
    my $hash = {A => \$array};
    @$array = ( \$hash );
    my $top = [ $array, $hash ];

        #same( $dump = $o->Data($top)->Out, <<'EXPECT', "Hard Refs", $o );
        same( "Hard Refs", $o ,<<'EXPECT', ( $top )  );
$ARRAY1 = [
            [ \do { my $v = 'V: $ARRAY1->[1]' } ],
            { A => \do { my $v = 'V: $ARRAY1->[0]' } }
          ];
${$ARRAY1->[0][0]} = $ARRAY1->[1];
${$ARRAY1->[1]{A}} = $ARRAY1->[0];
EXPECT


    same( "Hard Refs Two", $o,
            <<'EXPECT', ( $array, $hash ) );
$ARRAY1 = [ \$HASH1 ];
$HASH1 = { A => \$ARRAY1 };
EXPECT

    same("Hard Refs Three", $o->Declare(1),
        <<'EXPECT',( $array, $hash ) );
my $ARRAY1 = [ 'R: $HASH1' ];
my $HASH1 = { A => \$ARRAY1 };
$ARRAY1->[0] = \$HASH1;
EXPECT
    ;
    same( "Hard Refs Five", $o->Declare(1),
        <<'EXPECT',  (  $hash,$array, ) );
my $HASH1 = { A => 'R: $ARRAY1' };
my $ARRAY1 = [ \$HASH1 ];
$HASH1->{A} = \$ARRAY1;
EXPECT
    same( "Hard Refs Four", $o->Declare(0),
        <<'EXPECT', (  $hash, $array, ) );
$HASH1 = { A => \$ARRAY1 };
$ARRAY1 = [ \$HASH1 ];
EXPECT
}
{    # Scalar Cross

    my ( $ar, $x, $y ) = ( [ 1, 2 ] );
    $x       = \$y;
    $y       = \$x;
    $ar->[0] = \$ar->[1];
    $ar->[1] = \$ar->[0];

    same( "Scalar Cross One (\$ar)", $o, <<'EXPECT', ($ar) );
$ARRAY1 = [
            'R: $ARRAY1->[1]',
            'R: $ARRAY1->[0]'
          ];
$ARRAY1->[0] = \$ARRAY1->[1];
$ARRAY1->[1] = \$ARRAY1->[0];
EXPECT
    {    #local $Data::Dump::Streamer::DEBUG=1;

        same( "Scalar Cross Two (\$x,\$y)", $o, <<'EXPECT', ( $x, $y ) );
$REF1 = \$REF2;
$REF2 = \$REF1;
EXPECT
    }

    #local $Data::Dump::Streamer::DEBUG=1;
    same( "Scalar Cross Three [ \$x,\$y ]", $o , <<'EXPECT', [ $x, $y ] );
$ARRAY1 = [
            \do { my $v = 'V: $ARRAY1->[1]' },
            \do { my $v = 'V: $ARRAY1->[0]' }
          ];
${$ARRAY1->[0]} = $ARRAY1->[1];
${$ARRAY1->[1]} = $ARRAY1->[0];
EXPECT
}

{
    my $x;
    $x = \$x;

    same("Declare Leaf One ( \$x )", $o->Declare(1),<<'EXPECT',$x );
my $REF1 = 'R: $REF1';
$REF1 = \$REF1;
EXPECT

    same( "Declare Leaf Two  [ \$x ]", $o->Declare(1) , <<'EXPECT', [$x] );
my $ARRAY1 = [ \do { my $v = 'V: $ARRAY1->[0]' } ];
${$ARRAY1->[0]} = $ARRAY1->[0];
EXPECT

    same( 'Declare Leaf Three  ( \\$x )', $o->Declare(1), <<'EXPECT', \$x  );
my $REF1 = \do { my $v = 'V: $REF1' };
$$REF1 = $REF1;
EXPECT
    same("Leaf One ( \$x )", $o->Declare(0),<<'EXPECT',$x );
$REF1 = \$REF1;
EXPECT

    same( "Leaf Two  [ \$x ]", $o->Declare(0) , <<'EXPECT', [$x] );
$ARRAY1 = [ \do { my $v = 'V: $ARRAY1->[0]' } ];
${$ARRAY1->[0]} = $ARRAY1->[0];
EXPECT

    same( 'Leaf Three  ( \\$x )', $o->Declare(0), <<'EXPECT', \$x  );
$REF1 = \do { my $v = 'V: $REF1' };
$$REF1 = $REF1;
EXPECT
}

__END__
# with eval testing
{
    same( "", $o, <<'EXPECT', (  ) );

}
# without eval testing
{
    same( $dump = $o->Data()->Out, <<'EXPECT', "", $o );
EXPECT
}

use Test::More tests => 8;

#$Id: impure_madness.t 26 2006-04-16 15:18:52Z demerphq $#

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
is( $o->Purity, 1 ,'Purity is the norm...');
$o->Purity(0);
is( $o->Purity, 0 ,'... but some like it impure!');
{
    local *icky;
    *icky=\ "icky";
    our $icky;
    my $id = 0;
    my $btree;
    $btree = sub {
        my ( $d, $m, $p ) = @_;
        return $p
          if $d > $m;
        return [ $btree->( $d + 1, $m, $p . '0' ), $btree->( $d + 1, $m, $p . '1' ) ];
    };

    my $t = $btree->( 0, 1, '' );
    my ( $x, $y, $qr );
    $x = \$y;
    $y = \$x;
    $qr = bless qr/this is a test/m, 'foo_bar';

    my $array = [];
    my $hash = bless {
        A      => \$array,
        'B-B'  => ['$array'],
        'CCCD' => [ 'foo', 'bar' ],
        'E'=>\\1,
        'F'=>\\undef,
        'Q'=>sub{\@_}->($icky),
      },
      'ThisIsATest';
    $hash->{G}=\$hash;
    my $boo = 'boo';
    @$array = ( \$hash, \$hash, \$hash, \$qr, \$qr, \'foo', \$boo );
    my $cap = capture( $x, $y, $qr, $x, $y, $qr );

    test_dump( {
                name=>'Impure Impure Madness cap( $qr,$qr )',
                no_redump=>1,
                no_dumper=>1,
               }, $o, capture( $qr, $qr ),
               <<'EXPECT');
$ARRAY1 = [
            bless( qr/this is a test/m, 'foo_bar' ),
            alias_to($ARRAY1->[0])
          ];
EXPECT


    test_dump( {name=>"Total Impure Madness",
                no_redump=>1,
                no_dumper=>1,
               }, $o, ( $cap,$array,$boo,$hash,$qr ),
               <<'EXPECT');
$ARRAY1 = [
            \$ARRAY1->[1],
            \$ARRAY1->[0],
            alias_to($foo_bar1),
            alias_to($ARRAY1->[0]),
            alias_to($ARRAY1->[1]),
            alias_to($foo_bar1)
          ];
$ARRAY2 = [
            \$ThisIsATest1,
            $ARRAY2->[0],
            $ARRAY2->[0],
            \$foo_bar1,
            $ARRAY2->[3],
            \'foo',
            \$VAR1
          ];
$VAR1 = 'boo';
$ThisIsATest1 = bless( {
                  A     => \$ARRAY2,
                  "B-B" => [ '$array' ],
                  CCCD  => [
                             'foo',
                             'bar'
                           ],
                  E     => \\1,
                  F     => \\undef,
                  G     => $ARRAY2->[0],
                  Q     => [ make_ro( 'icky' ) ]
                }, 'ThisIsATest' );
$foo_bar1 = bless( qr/this is a test/m, 'foo_bar' );

EXPECT


}
{
    my ($x,$y);
    $x=\$y;
    $y=\$x;

    my $a=[1,2];
    $a->[0]=\$a->[1];
    $a->[1]=\$a->[0];

    #$cap->[-1]=5;
    my $s;
    $s=\$s;
    my $bar='bar';
    my $foo='foo';
    my $halias= {foo=>1,bar=>2};
    alias_hv(%$halias,'foo',$foo);
    alias_hv(%$halias,'bar',$bar);
    alias_hv(%$halias,'foo2',$foo);

    my ($t,$u,$v,$w)=(1,2,3,4);
    my $cap=sub{ \@_ }->($x,$y);
    my $q1=qr/foo/;
    my $q2=bless qr/bar/,'bar';
    my $q3=\bless qr/baz/,'baz';
    #same( $dump = $o->Data( $a,$q1,$q2,$q3,[$x,$y],[$s,$x,$y],$t,$u,$v,$t,[1,2,3],{1..4},$cap,$cap,$t,$u,$v,$halias)->Out, <<'EXPECT', "More Impure Madness", $o );
    test_dump( {
                name=>"More Impure Madness",
                no_redump=>1,
                no_dumper=>1,
               }, $o,
               ( $a,$q1,$q2,$q3,[$x,$y],[$s,$x,$y],$t,$u,$v,$t,[1,2,3],
               {1..4},$cap,$cap,$t,$u,$v,$halias),
               <<'EXPECT');
$ARRAY1 = [
            \$ARRAY1->[1],
            \$ARRAY1->[0]
          ];
$Regexp1 = qr/foo/;
$bar1 = bless( qr/bar/, 'bar' );
$REF1 = \bless( qr/baz/, 'baz' );
$ARRAY2 = [
            \$ARRAY5->[1],
            \$ARRAY5->[0]
          ];
$ARRAY3 = [
            \$ARRAY3->[0],
            $ARRAY2->[0],
            $ARRAY2->[1]
          ];
$VAR1 = 1;
$VAR2 = 2;
$VAR3 = 3;
alias_ref(\$VAR4,\$VAR1);
$ARRAY4 = [
            1,
            2,
            3
          ];
$HASH1 = {
           1 => 2,
           3 => 4
         };
$ARRAY5 = [
            $ARRAY2->[0],
            $ARRAY2->[1]
          ];
alias_ref(\$ARRAY6,\$ARRAY5);
alias_ref(\$VAR5,\$VAR1);
alias_ref(\$VAR6,\$VAR2);
alias_ref(\$VAR7,\$VAR3);
$HASH2 = {
           bar  => 'bar',
           foo  => 'foo',
           foo2 => alias_to($HASH2->{foo})
         };
EXPECT
}
{
    #local $Data::Dump::Streamer::DEBUG = 1;
    my $x;
    $x = sub { \@_ }->( $x, $x );
    push @$x, $x;
    test_dump( {
                name=>"Impure Alias Array",
                no_redump=>1,
                no_dumper=>1,
               }, $o,
               ( $x ),
               <<'EXPECT');
$ARRAY1 = [
            alias_to($ARRAY1),
            alias_to($ARRAY1),
            $ARRAY1
          ];
EXPECT
}
__END__
#
test_dump( {name=>"merlyns test 2",
            verbose=>1}, $o, ( \\@a ),
            <<'EXPECT',  );


# with eval testing
{
    same( "", $o, <<'EXPECT', (  ) );

}
# without eval testing
{
    same( $dump = $o->Data()->Out, <<'EXPECT', "", $o );
EXPECT
}

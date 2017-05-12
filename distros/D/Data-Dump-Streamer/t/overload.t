use Test::More tests => 7;
use Data::Dump::Streamer 'Dump';
use Carp ();
use Symbol 'gensym';
use strict;
use warnings;
require overload;

#$Id: overload.t 26 2006-04-16 15:18:52Z demerphq $#

# imports same()
(my $helper=$0)=~s/\w+\.\w+$/test_helper.pl/;
require $helper;

sub dump_obj {
    my $obj = shift;
    my $error;
    if ( not eval { my @list = Dump( $obj ); 1 } ) {
        $error = $@;
        diag( $error );
    }
    return ! defined $error;
}

ok( dump_obj( bless( do{ my $v="FooBar"; \ $v }, 'T' ) ),
    '${} overloading' );
{
    my $h={a=>'b'};
    ok( dump_obj( [ bless( [ 1, 2, 3, 4, $h ], 'T' ),$h ] ),
        '@{} overloading' );
}
ok( dump_obj( bless( {a=>'b',c=>[1,2,3,4]}, 'T' ) ),
    '%{} overloading' );
ok( dump_obj( bless( sub{}, 'T' ) ),
    '&{} overloading' );
ok( dump_obj( bless( gensym(), 'T' ) ),
    '*{} overloading' );
our @foofoo=qw(foo foo);
our $foofoo=bless \@foofoo,'T';
my $x=bless \*foofoo,'T';
ok( dump_obj( $x ),'containing glob' );

{
    my ($r1,$r2);
    $r1 = \$r2;
    $r2 = \$r1;
    my $c= sub {die};
    my $fh= gensym();
    my $gv= \*foofoo ;
    my $h={a=>'b',r1=>$r1,r2=>$r2,c=>$c,gv=>$gv};
    my $a1=[ 0..4, $h, $r1, $r2,$c,$fh,$gv ];
    $h->{array}=$a1;
    my $a2=[$a1,$h];

    bless $_,'T' for $r1,$r2,$c,$fh,$gv,$h,$a1,$a2;

    my $o=Dump();
    test_dump( {name=>'overloading madness',no_dumper=>1}, $o, $a2, <<'EXPECT');
$T1 = [
        [
          0,
          1,
          2,
          3,
          4,
          'V: $T1->[1]',
          \do { my $v = 'V: $T1->[0][7]' },
          \do { my $v = 'V: $T1->[0][6]' },
          sub {
            die;
          },
          do{ require Symbol; Symbol::gensym },
          \*::foofoo
        ],
        {
          a     => 'b',
          array => 'V: $T1->[0]',
          c     => 'V: $T1->[0][8]',
          gv    => 'V: $T1->[0][10]',
          r1    => 'V: $T1->[0][6]',
          r2    => 'V: $T1->[0][7]'
        }
      ];
$T1->[0][5] = $T1->[1];
${$T1->[0][6]} = $T1->[0][7];
${$T1->[0][7]} = $T1->[0][6];
$T1->[1]{array} = $T1->[0];
$T1->[1]{c} = $T1->[0][8];
$T1->[1]{gv} = $T1->[0][10];
$T1->[1]{r1} = $T1->[0][6];
$T1->[1]{r2} = $T1->[0][7];
*::foofoo = \do { my $v = 'V: *::foofoo{ARRAY}' };
*::foofoo = [
              ( 'foo' ) x 2
            ];
${*::foofoo} = *::foofoo{ARRAY};
bless( $T1->[0][6], 'T' );
bless( $T1->[0][7], 'T' );
bless( $T1->[0][8], 'T' );
bless( $T1->[0][9], 'T' );
bless( $T1->[0][10], 'T' );
bless( $T1->[0], 'T' );
bless( $T1->[1], 'T' );
bless( $T1, 'T' );
bless( *::foofoo{ARRAY}, 'T' );
EXPECT
}


package T;
BEGIN {
    overload->import(
        map { my $operation = $_;
              $operation => sub { Carp::confess( "The overloaded method $operation was called" ) } }
        map { split( ' ' ) }
        values %overload::ops
    );
}

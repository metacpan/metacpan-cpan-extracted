use Test::More tests => 7;

#$Id: madness.t 26 2006-04-16 15:18:52Z demerphq $#

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


    same( 'Madness cap( $qr,$qr )', $o ,<<'EXPECT', capture( $qr, $qr ) );
$ARRAY1 = [
            bless( qr/this is a test/m, 'foo_bar' ),
            'A: $ARRAY1->[0]'
          ];
alias_av(@$ARRAY1, 1, $ARRAY1->[0]);
EXPECT


    #same( $dump = $o->Data( $cap,$array,$boo,$hash,$qr )->Out, <<'EXPECT', "Total Madness", $o );
    same( "Total Madness", $o,<<'EXPECT',( $cap,$array,$boo,$hash,$qr ) );
$ARRAY1 = [
            'R: $ARRAY1->[1]',
            'R: $ARRAY1->[0]',
            'A: $foo_bar1',
            'A: $ARRAY1->[0]',
            'A: $ARRAY1->[1]',
            'A: $foo_bar1'
          ];
$ARRAY1->[0] = \$ARRAY1->[1];
$ARRAY1->[1] = \$ARRAY1->[0];
alias_av(@$ARRAY1, 3, $ARRAY1->[0]);
alias_av(@$ARRAY1, 4, $ARRAY1->[1]);
$ARRAY2 = [
            \$ThisIsATest1,
            'V: $ARRAY2->[0]',
            'V: $ARRAY2->[0]',
            \$foo_bar1,
            'V: $ARRAY2->[3]',
            \'foo',
            \$VAR1
          ];
$ARRAY2->[1] = $ARRAY2->[0];
$ARRAY2->[2] = $ARRAY2->[0];
$ARRAY2->[4] = $ARRAY2->[3];
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
                  Q     => [ 'icky' ]
                }, 'ThisIsATest' );
make_ro($ThisIsATest1->{Q}[0]);
$foo_bar1 = bless( qr/this is a test/m, 'foo_bar' );
alias_av(@$ARRAY1, 2, $foo_bar1);
alias_av(@$ARRAY1, 5, $foo_bar1);
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
    #same( $dump = $o->Data( $a,$q1,$q2,$q3,[$x,$y],[$s,$x,$y],$t,$u,$v,$t,[1,2,3],{1..4},$cap,$cap,$t,$u,$v,$halias)->Out, <<'EXPECT', "More Madness", $o );
    same(  "More Madness", $o ,
        <<'EXPECT',( $a,$q1,$q2,$q3,[$x,$y],[$s,$x,$y],$t,$u,$v,$t,[1,2,3],{1..4},$cap,$cap,$t,$u,$v,$halias));
$ARRAY1 = [
            'R: $ARRAY1->[1]',
            'R: $ARRAY1->[0]'
          ];
$ARRAY1->[0] = \$ARRAY1->[1];
$ARRAY1->[1] = \$ARRAY1->[0];
$Regexp1 = qr/foo/;
$bar1 = bless( qr/bar/, 'bar' );
$REF1 = \bless( qr/baz/, 'baz' );
$ARRAY2 = [
            'R: $ARRAY5->[1]',
            'R: $ARRAY5->[0]'
          ];
$ARRAY3 = [
            \do { my $v = 'V: $ARRAY3->[0]' },
            'V: $ARRAY2->[0]',
            'V: $ARRAY2->[1]'
          ];
${$ARRAY3->[0]} = $ARRAY3->[0];
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
            'V: $ARRAY2->[0]',
            'V: $ARRAY2->[1]'
          ];
$ARRAY2->[0] = \$ARRAY5->[1];
$ARRAY2->[1] = \$ARRAY5->[0];
$ARRAY3->[1] = $ARRAY2->[0];
$ARRAY3->[2] = $ARRAY2->[1];
$ARRAY5->[0] = $ARRAY2->[0];
$ARRAY5->[1] = $ARRAY2->[1];
alias_ref(\$ARRAY6,\$ARRAY5);
alias_ref(\$VAR5,\$VAR1);
alias_ref(\$VAR6,\$VAR2);
alias_ref(\$VAR7,\$VAR3);
$HASH2 = {
           bar  => 'bar',
           foo  => 'foo',
           foo2 => 'A: $HASH2->{foo}'
         };
alias_hv(%$HASH2, 'foo2', $HASH2->{foo});
EXPECT
}
{
    #local $Data::Dump::Streamer::DEBUG = 1;
    my $x;
    $x = sub { \@_ }->( $x, $x );
    push @$x, $x;
    same(   "Tye Alias Array", $o, <<'EXPECT',( $x ) );
$ARRAY1 = [
            'A: $ARRAY1',
            'A: $ARRAY1',
            'V: $ARRAY1'
          ];
alias_av(@$ARRAY1, 0, $ARRAY1);
alias_av(@$ARRAY1, 1, $ARRAY1);
$ARRAY1->[2] = $ARRAY1;
EXPECT
}
{
    undef $!;
format STDOUT =
@<<<<<<   @││││││   @>>>>>>
"left",   "middle", "right"
.

    my $expected_dot;
    if ( defined $. && length $. ) {
        $expected_dot = $.;
    }
    elsif ( defined $. ) {
        $expected_dot = "''";
    }
    else {
        $expected_dot = 'undef';
    }
    my %hash = (
        UND => undef,
        IV  => 1,
        NV  => 3.14159265358979,
        PV  => "string",
        PV8 => "ab\ncd\x{20ac}\t",
        RV  => \$.,
        AR  => [ 1..2 ],
        HR  => { key => "value" },
        CR  => sub { "code"; },
        GLB => *STDERR,
        IO  => *{$::{STDERR}}{IO},
        FMT => \*{$::{STDOUT}}{FORMAT},
        OBJ => bless(qr/("[^"]+")/,"Zorp"),
        );

    # Dumping differences per perl version:
    # 5.12.0+:
    #
    #   IO handles are now blessed into IO::File, I guess?
    #
    if ( $] >= 5.012_000 ) {
        my $expect = <<'EXPECT';
$HASH1 = {
           AR  => [
                    1,
                    2
                  ],
           CR  => sub {
                    use warnings;
                    use strict 'refs';
                    'code';
                  },
           FMT => \do{ local *F; my $F=<<'_EOF_FORMAT_'; $F=~s/^\s+# //mg; eval $F; die $F.$@ if $@; *F{FORMAT};
                  # format F =
                  # @<<<<<<   @││││││   @>>>>>>
                  # 'left', 'middle', 'right'
                  # .
_EOF_FORMAT_
                  },
           GLB => *::STDERR,
           HR  => { key => 'value' },
           IO  => bless( *{Symbol::gensym()}{IO}, 'IO::File' ),
           IV  => 1,
           NV  => 3.14159265358979,
           OBJ => bless( qr/("[^"]+")/, 'Zorp' ),
           PV  => 'string',
           PV8 => "ab\ncd\x{20ac}\t",
           RV  => \do { my $v = expected_dot },
           UND => undef
         };
EXPECT
        require B::Deparse;
        if (new B::Deparse -> coderef2text (
              sub { no strict; 1; use strict; 1; }
           ) !~ 'refs') {
            $expect =~ s/strict 'refs'/strict/;
        }
        same( $dump= $o->Data(\%hash)->Out, template( $expect, expected_dot => $expected_dot ), "", $o);
    }
    elsif ( $] >= 5.008_008 ) {
        same( $dump= $o->Data(\%hash)->Out, template( <<'EXPECT', expected_dot => $expected_dot ), "", $o);
$HASH1 = {
           AR  => [
                    1,
                    2
                  ],
           CR  => sub {
                    use warnings;
                    use strict 'refs';
                    'code';
                  },
           FMT => \do{ local *F; my $F=<<'_EOF_FORMAT_'; $F=~s/^\s+# //mg; eval $F; die $F.$@ if $@; *F{FORMAT};
                  # format F =
                  # @<<<<<<   @││││││   @>>>>>>
                  # 'left', 'middle', 'right'
                  # .
_EOF_FORMAT_
                  },
           GLB => *::STDERR,
           HR  => { key => 'value' },
           IO  => bless( *{Symbol::gensym()}{IO}, 'IO::Handle' ),
           IV  => 1,
           NV  => 3.14159265358979,
           OBJ => bless( qr/("[^"]+")/, 'Zorp' ),
           PV  => 'string',
           PV8 => "ab\ncd\x{20ac}\t",
           RV  => \do { my $v = expected_dot },
           UND => undef
         };
EXPECT
    }
    elsif ( $] >= 5.008_000 ) {
        same( $dump= $o->Data(\%hash)->Out, template( <<'EXPECT', expected_dot => $expected_dot ), "", $o);
$HASH1 = {
           AR  => [
                    1,
                    2
                  ],
           CR  => sub {
                    BEGIN {${^WARNING_BITS} = "UUUUUUUUUUUU"}
                    use strict 'refs';
                    'code';
                  },
           FMT => \do{ local *F; my $F=<<'_EOF_FORMAT_'; $F=~s/^\s+# //mg; eval $F; die $F.$@ if $@; *F{FORMAT};
                  # format F =
                  # @<<<<<<   @││││││   @>>>>>>
                  # 'left', 'middle', 'right'
                  # .
_EOF_FORMAT_
                  },
           GLB => *::STDERR,
           HR  => { key => 'value' },
           IO  => bless( *{Symbol::gensym()}{IO}, 'IO::Handle' ),
           IV  => 1,
           NV  => 3.14159265358979,
           OBJ => bless( qr/("[^"]+")/, 'Zorp' ),
           PV  => 'string',
           PV8 => "ab\ncd\x{20ac}\t",
           RV  => \do { my $v = expected_dot },
           UND => undef
         };
EXPECT
    }
    else {
        same( $dump= $o->Data(\%hash)->Out, template( <<'EXPECT', expected_dot => $expected_dot ), "", $o);
$HASH1 = {
           AR  => [
                    1,
                    2
                  ],
           CR  => sub {
                    'code';
                  },
           FMT => \do { my $v = undef },
           GLB => *::STDERR,
           HR  => { key => 'value' },
           IO  => bless( *{Symbol::gensym()}{IO}, 'IO::Handle' ),
           IV  => 1,
           NV  => 3.14159265358979,
           OBJ => bless( qr/("[^"]+")/, 'Zorp' ),
           PV  => 'string',
           PV8 => "ab\ncd\x{20ac}\t",
           RV  => \do { my $v = expected_dot },
           UND => undef
         };
EXPECT
    }
}

sub template {
    my ( $pattern, %replacements ) = @_;

    for ( keys %replacements ) {
        $pattern =~ s/$_/$replacements{$_}/g;
    }

    return $pattern;
}
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

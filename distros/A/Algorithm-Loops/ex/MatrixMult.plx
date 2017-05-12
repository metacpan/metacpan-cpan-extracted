#!/usr/bin/perl -w

use strict;

use Algorithm::Loops qw( MapCarE );

Main( @ARGV );
exit( 0 );


sub Mult {
    my( $x, $y )= @_;
    my @prod= map {
        my $row= $_;
        [
            map {
                my $sum= 0;
                $sum += $_   for  MapCarE {
                    pop() * pop()
                } $row, $_;
                $sum;
            } MapCarE {\@_} @$y
        ]
    } @$x;
    return \@prod;
}


{

    my( %fmt4exp, @exps2fmt, $fullfmt );

    BEGIN {
        %fmt4exp= (
            -100 => '+1.0e-999',
             -10 => '+1.00e-99',
              -5 => '+1.000e-9',
              -1 => '+0.000000',
              +3 => '   +0.000',
              +5 => '     +0.0',
              +7 => '       +0',
              +9 => '+1.000e+9',
             +99 => '+1.000e99',
          +99999 => '+1.00e999',
        );
        @exps2fmt= sort {$a<=>$b} keys %fmt4exp;
        $fullfmt= '%+14.7e'; # %+1.2345678e-99
    }

    sub Num2Str {
        my( $num )= @_;
        my $full= sprintf $fullfmt, $num;
        my( $sign, $one, $rest, $esign, $eabs )=
            $full =~ m<
                ^\s*
                ([-+]?)(\d)\.(\d*)
                [eE]([-+]?)(\d+)
                \s*$
            >x;
        my $exp= $esign . $eabs;
        my $fmt;
        for my $exp2fmt (  @exps2fmt  ) {
            if(  $exp <= $exp2fmt  ) {
                $fmt= $fmt4exp{$exp2fmt};
                last;
            }
        }
        my $str= $fmt;
        if(  $fmt =~ /e/  ) {
            $str =~ s/\+/$sign/;
            $str =~ s/1/$one/;
            $str =~ s{\.(0+)(?=[eE])}{
                (   sprintf( "%14.".length($1)."e", $num )
                        =~ /(\.\d+)/
                )[0]
            }e;
            $str =~ s/(9+)/sprintf "%0".length($1)."d", $eabs/e;
        } else {
            if(  $exp < 0  ) {
                $str =~ s/\+/$sign/;
                $rest= '0'x($eabs-1) . $one . $rest;
            } else {
                $one= substr( $one . $rest, 0, 1+$exp );
                substr( $rest, 0, $exp )= '';
                $str =~ s/([\s+0]+)/sprintf "%+".length($1)."s", $sign.$one/e;
            }
            $str =~ s{\.(0+)}{
                (   sprintf( "%14.".length($1)."f", $num )
                        =~ /(\.\d+)$/
                )[0]
            }e;
            $str =~ s{\.(0+)$}{
                (   sprintf( "%14.".length($1)."f", $num )
                        =~ /(\.\d+)/
                )[0]
            }e;
            $str =~ s/(\.?0+)$/' ' x length($1)/e
                if  $fmt =~ /\./;
        }
        return $str;
    }

}


sub Main {
    if(  ! @_  ) {
        open STDIN, "<&DATA"
            or  die "Can't dup DATA to STDIN: $!\n";
    }
    my( @lines, $mat, $x, $p );
    do {
        $_= <>;
        $_= ''   if  ! defined $_  ||  $_ eq /^__END__\b/;
        if(  ! /\d/  ) {   # Numberless line between matrices:
            if(  $mat  &&  ! /^And\s*$/  ) {
                if(  ! $x  &&  $p  ) {
                    print "And\n";
                }
                print @lines;
                if(  ! $x  ) {
                    $x= $mat;
                    print "times\n";
                } else {
                    print "equals\n";
                    $p= Mult( $x, $mat );
                    for my $row (  @$p  ) {
                        print join( " ", map Num2Str($_), @$row ), $/;
                    }
                    undef $x;
                }
            }
            @lines= ();
            undef $mat;
        } else {
            push @lines, $_;
            chomp( $_ );
            for my $row (  split '/', $_  ) {
                push @$mat, [ $row =~ /([^\s,]+)/g ];
            }
        }
    } while(  '' ne $_  );
}
__END__
  1,  3
  4, -1
 -2,  2
times
 -6,  2, 5, -3
  4, -1, 3,  1
equals
   +6        -1       +14        +0
  -28        +9       +17       -13
  +20        -6        -4        +8
And
  1 2 3 4
times
  1 / 2 / 3
equals
MapCarE: Arrays with different sizes (4 and 3) at MatrixMult.plx line 93

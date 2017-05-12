
=head1 NAME

Bio::Metabolic::MatrixOps - Operations on PDL::Matrix objects

=head1 SYNOPSIS

  use Bio::Metabolic::MatrixOps;


=head1 DESCRIPTION

This module contains all matrix operations that are needed for calculations
involving the stoichiometric matrix

=head1 AUTHOR

Oliver Ebenhoeh, oliver.ebenhoeh@rz.hu-berlin.de

=head1 SEE ALSO

Bio::Metabolic 
Bio::Metabolic::Substrate 
Bio::Metabolic::Substrate::Cluster 
Bio::Metabolic::Reaction
Bio::Metabolic::Network

=cut

=head1 METHODS

=head2 method xrow

$m->xrow($r1,$r2);
Exchanges rows $r1 and $r2 in matrix $m.

=cut

use PDL;
use PDL::Matrix;
use Math::Fraction;
use Math::Cephes qw(:fract);

sub PDL::Matrix::xrow {    # $m, $row1, $row2
    my $matrix = shift;
    my ( $r1, $r2 ) = @_;

    my $d = $r1 - $r2;
    ( my $tmp = $matrix->slice("$r1:$r2:$d,:") ) .=
      $matrix->slice("$r2:$r1:$d,:")->sever
      if $d != 0;
}

=head2 method xcol

$m->xcol($r1,$r2);
Exchanges columns $r1 and $r2 in matrix $m.

=cut

sub PDL::Matrix::xcol {
    my $matrix = shift;
    my ( $r1, $r2 ) = @_;

    my $d = $r1 - $r2;
    ( my $tmp = $matrix->slice(":,$r1:$r2:$d") ) .=
      $matrix->slice(":,$r2:$r1:$d")->sever
      if $d != 0;
}

=head2 method addrows

$m->addrows($r1,$r2[,$lambda]);
Adds $lambda times the $r2-th row to $r1

=cut

sub PDL::Matrix::addcols {    # $matrix->($i,$j[,$lambda])
                              # adds lambda * j-th row to i-th row
    my $matrix = shift;
    my $i      = shift;
    my $j      = shift;
    my $lambda = @_ ? shift: 1;

    ( my $tmp = $matrix->slice(":,($i)") ) +=
      $lambda * $matrix->slice(":,($j)")->sever;
}

=head2 method addcols

$m->addcols($c1,$c2[,$lambda]);
Adds $lambda times the $c2-th column to $c1

=cut

sub PDL::Matrix::addrows {    # $matrix->($i,$j[,$lambda])
                              # adds lambda * j-th row to i-th row
    my $matrix = shift;
    my $i      = shift;
    my $j      = shift;
    my $lambda = @_ ? shift: 1;

    ( my $tmp = $matrix->slice("($i),:") ) +=
      $lambda * $matrix->slice("($j),:")->sever;
}

=head2 method delcol

$m->delcol($c);
Sets all coefficients in the column $c to zero.

=cut

sub PDL::Matrix::delcol {    # set row to zero
    my ( $matrix, $r ) = @_;

    ( my $tmp = $matrix->slice(":,$r") ) .= 0;
}

=head2 method delcols

$m->delcols(@c);
Sets all coefficients in the columns specified in @c to zero.

=cut

sub PDL::Matrix::delcols {    # set several rows to zero
    my ( $matrix, @rows ) = @_;

    my $r;
    foreach $r (@rows) {
        $matrix->delcol($r);
    }
}

=head2 method delrow

$m->delrow($r);
Sets all coefficients in the row $r to zero.

=cut

sub PDL::Matrix::delrow {    # set row to zero
    my ( $matrix, $r ) = @_;

    ( my $tmp = $matrix->slice("$r,:") ) .= 0;
}

=head2 method delrows

$m->delrows(@r);
Sets all coefficients in the rows specified in @r to zero.

=cut

sub PDL::Matrix::delrows {    # set several rows to zero
    my ( $matrix, @rows ) = @_;

    my $r;
    foreach $r (@rows) {
        $matrix->delrow($r);
    }
}

=head2 method det # probably obsolete!!!! Check with PDL::Matrix / PDL::MatrixOps

$det = $m->det;
Returns the determinant of matrix $m, undef if $m is not square.

=cut

#sub PDL::Matrix::det {
#    my $matrix = shift->copy;

#    my @dims = $matrix->dims;

#    return undef if ( @dims < 2 );
#    my $n = $dims[0] < $dims[1] ? $dims[0] : $dims[1];

#    my ( $nzindex, $tmp, $r2 );
#    my $sign = 1;
#    my $r    = 0;
#    my $rank = $n;
#    while ( $r < $rank ) {

#    print "Entering loop with r=$r, rank=$rank\n";
#        my $row = $matrix->slice("($r),:");
#        if ( $row->where( $row == 0 )->nelem >= $n ) {
#            if ( $r < $rank - 1 ) {
#                $matrix->xrow( $r, $rank - 1 )
#                  ;    #print("Reihenaustausch, $matrix\n");
#                $sign = -$sign;
#            }
#            $rank--;
#        }
#        else {
#            $nzindex = which( $row != 0 )->at(0);
#            if ( $nzindex > $r ) {
#                $matrix->xcol( $r, $nzindex )
#                  ;    #print("Spaltenaustausch, $matrix\n");
#                $sign *= -1;
#            }
#            for ( $r2 = $r + 1 ; $r2 < $rank ; $r2++ ) {
#                $matrix->addrows( $r2, $r,
#                    -$matrix->at( $r2, $r ) / $matrix->at( $r, $r ) );

##	($tmp = $matrix->slice(":,$r2")) .= $matrix->slice(":,$r2") - $matrix->at($r,$r2)/$matrix->at($r,$r) * $matrix->slice(":,$r");
#            }
#            $r++;
#        }

#        #    print "$r,$rank,$matrix\n";
#    }
#    my $det = 1;
#    for ( $r = 0 ; $r < $n ; $r++ ) {
#        $det *= $matrix->at( $r, $r );
#    }
#    return ( $det * $sign );
#}

=head2 method is_pos_def

$m->is_pos_def;
Returns true if matrix $m is truely positive definite, false otherwise

=cut

sub PDL::Matrix::is_pos_def {
    my $matrix = shift;

    my ( $n, $m ) = $matrix->dims;

    for ( my $i = 0 ; $i < $n ; $i++ ) {
        return (0) unless $matrix->slice("0:$i,0:$i")->det > 0;
    }

    return (1);
}

=head2 method row_echelon_int;

$row_echelon_matrix = $m->row_echelon_int;
($row_echelon_matrix, $permutation_vector, $rank) = $m->row_echelon_int;

Returns the integer row echelon form of matrix $m.
In array context also returns the permutation vector indication how the
rows of $m were permuted while calculating the row echelon form and the
rank of the matrix $m.

=cut

sub PDL::Matrix::row_echelon_int {
    my $matrix = shift->copy;

    #  print "reference of matrix is now: ".ref($matrix)."\n";
    return ( null, null, 0 ) if ( $matrix->isempty );

    my ( $n, $m ) = $matrix->dims;

    my $rank = $m;
    my $r    = 0;
    my $perm = msequence 1, $n;

    #  bless $perm, ref($matrix);

    my ( $nzindex, $tmp, $r2, $frac, $p, $q );
    while ( $r < $rank ) {

        #    print "Entering loop with r=$r, rank=$rank\n";
        my $row = $matrix->slice("($r),:");
        if ( $row->where( $row == 0 )->nelem == $n ) {

            #      print "Exchange rows $r and ".eval($rank-1)."...\n";
            $matrix->xrow( $r, $rank - 1 );    #print $matrix;
            $rank--;
        }
        else {
            $nzindex = which( $row != 0 )->at(0);
            if ( $nzindex > $r ) {

                #	print "Exchange columns $r and $nzindex...\n";
                $matrix->xcol( $r, $nzindex );
                $perm->xcol( $r,   $nzindex );
            }
            for ( $r2 = $r + 1 ; $r2 < $rank ; $r2++ ) {

                #      for ($r2=0;$r2<$rank;$r2++) {
                #	if ($r2 != $r) {
                ( $p, $q ) =
                  frac( $matrix->at( $r2, $r ), $matrix->at( $r, $r ) )->list;

#	print "Reihe $r2:p=$p,q=$q  ".frac($matrix->at($r,$r2),$matrix->at($r,$r))->string."\n";
                ( $tmp = $matrix->slice("$r2,:") ) .=
                  $q * $matrix->slice("$r2,:") - $p * $matrix->slice("$r,:");

                #      }
            }
            $r++;
        }

        #    print "$r,$rank,$matrix\n";
    }

    #    return wantarray ? ( $matrix, $perm->slice("(0),:"), $rank ) : $matrix;
    return wantarray ? ( $matrix, $perm, $rank ) : $matrix;
}

=head2 method cutrow

$mnew = $m->cutrow($r);
Returns a matrix without row $r, i.e. the number of rows is
reduced by one.

=cut

sub PDL::Matrix::cutrow {
    my $matrix = shift->copy;
    my $r      = shift;

    my ( $x, $y ) = $matrix->mdims;

    if ( $r < $x - 1 ) {
        my $slstr1 = "$r:" . eval( $x - 2 ) . ",:";
        my $slstr2 = eval( $r + 1 ) . ":" . eval( $x - 1 ) . ",:";
        ( my $tmp = $matrix->slice("$slstr1") ) .=
          $matrix->slice("$slstr2")->sever;
    }
    $x -= 2;
    return $x < 0 ? null: $matrix->slice("0:$x,:");
}

=head2 method cutcol

$mnew = $m->cutcol($c);
Returns a matrix without column $c, i.e. the number of columns is
reduced by one.

=cut

sub PDL::Matrix::cutcol {
    my $matrix = shift->copy;
    my $r      = shift;

    my ( $x, $y ) = $matrix->mdims;
    return undef if ( !defined $y );

    if ( $r < $y - 1 ) {
        my $slstr1 = ":,$r:" . eval( $y - 2 );
        my $slstr2 = ":," . eval( $r + 1 ) . ":" . eval( $y - 1 );
        ( my $tmp = $matrix->slice("$slstr1") ) .=
          $matrix->slice("$slstr2")->sever;
    }
    $y -= 2;
    return $y < 0 ? null: $matrix->slice(":,0:$y");
}

=head2 method cutrows

$mnew = $m->cutrows(@r);
Returns a matrix without all rows specified in @r, i.e. the number 
of rows is reduced by the number of elements in @r.

=cut

sub PDL::Matrix::cutrows {
    my $matrix = shift->copy;
    my @rows   = sort { $b <=> $a } @_;

    for ( my $r = 0 ; $r < @rows ; $r++ ) {
        $matrix = $matrix->cutrow( $rows[$r] );
    }
    return $matrix;
}

=head2 method cutcols

$mnew = $m->cutcols(@c);
Returns a matrix without all columns specified in @c, i.e. the number 
of columns is reduced by the number of elements in @c.

=cut

sub PDL::Matrix::cutcols {
    my $matrix = shift->copy;
    my @rows   = sort { $b <=> $a } @_;

    for ( my $r = 0 ; $r < @rows ; $r++ ) {
        $matrix = $matrix->cutcol( $rows[$r] );
    }
    return $matrix;
}

=head2 method permrows

$mnew = $m->permrows($permutation_vector);

Returns a matrix with the rows permuted as specified by $permutation_vector.
$permutation_vector must be a PDL.

EXAMPLE: If $m is a 3x3 matrix, then 
  $p = $m->permrows(pdl [2,0,1]);
will return a matrix with the last row of $m as first row, the first row of $m
as the second and the second row of $m as the last row.

=cut

*PDL::Matrix::permrows = \&permrows;

sub permrows {
    my $matrix = shift->copy;
    my $perm;
    if ( ref( $_[0] ) eq "PDL::Matrix" ) {
        $perm = shift;
        my @pdims = $perm->mdims;
        $perm = $perm->transpose if $pdims[1] == 1;
    }
    elsif ( ref( $_[0] ) eq "PDL" ) {
        $perm = shift->copy->dummy(1);
        bless $perm, 'PDL::Matrix';
    }
    elsif ( ref( $_[0] ) eq "ARRAY" ) {
        $perm = pdl( $_[0] );
    }
    else {
        $perm = pdl(@_);
    }

    my ( $c, $r ) = $matrix->dims();

    #  print "$c columns, $r rows, perm has ".eval($perm->nelem)." entries\n";
    return undef if ( $r != $perm->nelem );

    #  print "permrows called\n";
    my $cnt;
    for ( $cnt = 0 ; $cnt < $r ; $cnt++ ) {
        my $xchpos = which( $perm->slice("(0),:") == $cnt )->at(0);
        if ( $xchpos != $cnt ) {

            #      print "exchange rows $xchpos and $cnt\n";
            $matrix->xrow( $xchpos, $cnt );
            $perm->xcol( $xchpos, $cnt );
        }
    }

    return $matrix;
}

=head2 method kernel

$ker = $m->kernel;
Returns the kernel of matrix $m, i.e. the matrix with linearly independent
column vectors $c satisfying the equation $m x $c = 0.

=cut

sub PDL::Matrix::kernel {
    my $matrix = shift->copy;

    my ( $rem, $perm, $rank ) = $matrix->row_echelon_int();

    my ( $cols, $rows ) = $rem->dims();

    my $vec;
    my @veclist = ();

    my ( $cnt, $r );
    for ( $cnt = $rank ; $cnt < $cols ; $cnt++ ) {

        #    print "Solution number ".eval($cnt-$rank+1).":\n";
        $vec = zeroes($cols);
        set $vec, $cnt, 1;

        for ( $r = $rank - 1 ; $r >= 0 ; $r-- ) {

            #      print "Calculating row $r:\n";
            my ($row) = $rem->slice("($r),:");
            my $sum = inner( $row, $vec );

            # ensure only integers remain
            my ( $gcd, $redsum, $redpivot ) =
              euclid( $sum, $rem->at( $r, $r ) );
            $vec *= $redpivot;
            set $vec, $r, -( $sum * $redpivot / $rem->at( $r, $r ) );

            #      print "$vec\n";
        }

        push( @veclist, $vec );
    }

    #  print "kernel: Rank=$rank,Columns=$cols,vecs:@veclist\n";
    #  my $retmat = cat(@veclist)->xchg(0,1);
    #  $retmat->permrows($perm);
    #  return $retmat;
    return null unless @veclist;
    my $retmat = bless cat(@veclist)->xchg( 0, 1 ), ref($matrix);
    return $retmat->permrows($perm);
}

=head2 method invert # probably obsolete!!!! Check with PDL::Matrix / PDL::MatrixOps

$inv = $m->invert;
Returns the inverse of $m, undef if $m is not invertible.

=cut

sub PDL::Matrix::invert {
    my $matrix = shift->copy;

    #  print "ref(matrix) is ".ref($matrix)."\n";
    #  my ($pkg,$file,$line)=caller();

    my @dims = $matrix->dims;

    if ( $dims[0] != $dims[1] ) {
        croak("Inverse for non-square matrix not defined!\n");
        return undef;
    }

    my $n = $dims[0];    # n x n matrix

    # $inverse = 1
    #  print "matrix $matrix";
    #  print "invert called from package $pkg, file $file, line $line (n=$n)\n";
    #  my $inverse = ref($matrix)->new($n,$n);
    my $inverse = mzeroes( $n, $n );

    #  (my $tmp = $inverse->diagonal(0,1)) .= 1;   # some strange error!!!!
    #  for (my $del=0;$del<$n;$del++) {set($inverse,$del,$del,1)};
    $inverse->diagonal( 0, 1 ) .= 1;

    for ( my $colnr = 0 ; $colnr < $n ; $colnr++ ) {

        # find pivot element
        my $colnz = which( $matrix->slice(":,($colnr)")->sever != 0 );
        my $ppiv  = which( $colnz >= $colnr );
        if ( $ppiv->nelem == 0 ) {
            print "Matrix not invertible\n";
            return undef;
        }
        my $pivotrow = $colnz->at( $ppiv->at(0) );

        if ( $pivotrow != $colnr ) {
            $matrix->xrow( $colnr,  $pivotrow );
            $inverse->xrow( $colnr, $pivotrow );
        }

        my $akk = $matrix->at( $colnr, $colnr );    # this is a_{kk}
        for ( my $rownr = 0 ; $rownr < $n ; $rownr++ ) {
            if ( $rownr != $colnr ) {

                #	my $q = - $matrix->at($colnr,$rownr) / $akk;
                my $q = -$matrix->at( $rownr, $colnr ) / $akk;
                $matrix->addrows( $rownr,  $colnr, $q );
                $inverse->addrows( $rownr, $colnr, $q );
            }
        }

        #    print "Matrix now (column $colnr) : $matrix\n";
        #    print "Inverse now (column $colnr) : $inverse\n";

    }

    #  my $diag = $matrix->diagonal(0,1);
    #  if (!(which($diag==0)->isempty)) {
    #    print "Matrix non inversible!\n";
    #    return undef;
    #  }

    for ( my $d = 0 ; $d < $n ; $d++ ) {
        if ( $matrix->at( $d, $d ) == 0 ) {
            croak("Matrix non inversible!");
            return undef;
        }

        #    ($tmp = $inverse->slice(":,($d)")) /= $diag->at($d);
        my $tmp;
        ( $tmp = $inverse->slice("($d),:") ) /= $matrix->at( $d, $d );
    }

    #  print "inverse: $inverse";
    return $inverse;
}

=head2 method char_pol

$coefficient_vector = $m->char_pol;

Returns a PDL with the coefficients of the characteristic polynomial of $m.

EXAMPLE:
               [1 2 1]
  The matrix M=[2 0 3] has the characeristic polynomial
               [1 1 1]
  p(x) = det(M-x1) = a_3 x^3 + a_2 x^2 + a_1 x + a_0 = -x^3+2x^2+7x+1.

  $m = mdpl [[1,2,1],[2,0,3],[1,1,1]];
  $cp = $m->char_pol;
This returns [1,7,2,-1]. $cp->at(n) contains the coefficient a_n.

=cut

sub PDL::Matrix::char_pol {
    my $matrix = shift;

    my @dims = $matrix->dims;
    my $n    = $dims[0];

    #  print "Dimension: $n\nMatrix: $matrix\n";
    my $lvec = @_ ? shift: ones($n);

   #  print "lvec: $lvec\n";
   #  if ($n == 1) {
   #    return $lvec->at(0) == 1 ? [$matrix->at(0,0),-1] : [$matrix->at(0,0),0];
   #  }
    return pdl [ $matrix->at( 0, 0 ), -$lvec->at(0) ] if $n == 1;

    my $lambdas = which( $lvec == 1 );

    #  print "Lambdas at $lambdas\n";
    return pdl [ eval( $matrix->determinant ) ] if ( $lambdas->nelem == 0 );

    my $lambda = $lambdas->at(0);

    #  print "...choosing lambda at $lambda\n";
    set( $lvec, $lambda, 0 );    # now recursively calculate...

    #  print "calling char_pol with $lvec\n";
    #  print ">>>>>>>>>>>>>\n";
    my $coeff1 = $matrix->char_pol( $lvec->copy );

    #  print "<<<<<<<<<<<<< (lvec is $lvec)\n";

    #  print "Coefficients due to leaving out lambda: $coeff1\n";

    #  print "lvec before splicing: $lvec\n";
    my @tmpl = $lvec->list;
    splice( @tmpl, $lambda, 1 );
    $lvec = pdl(@tmpl);
    $lvec = $lvec->dummy(0) if $lvec->dims == 0;

    #  print "lvec after splicing: $lvec\n";

    # reduce matrix
    my $redmat = $matrix->cutrow($lambda)->cutcol($lambda);

    #  $redmat = $redmat->cutcol($lambda);

    #  print "calling char_pol with $lvec and reduced matrix $redmat\n";
    #  print ">>>>>>>>>>>>>\n";
    my $coeff2 = $redmat->char_pol( $lvec->copy );

    #  print "<<<<<<<<<<<<<\n";

    #  print "Coefficients due to lambda: $coeff2\n";

    #  unshift(@$coeff2,0);
    $coeff2 = pdl [ 0, $coeff2->list ];

    #  print "after unshifting: ".join(',',@$coeff2)."\n";

    #  my $res = [];
    #  for (my $i=0;$i<@$coeff2;$i++) {
    #    $res->[$i] = $coeff1->[$i] - $coeff2->[$i];
    #  }
    $coeff1 =
      pdl [ $coeff1->list, zeroes( $coeff2->nelem - $coeff1->nelem )->list ]
      if $coeff2->nelem != $coeff1->nelem;
    my $res = $coeff1 - $coeff2;

    #  print "returning ".join(',',@$res)."\n";
    #  if ($res->[@$res-1] < 0) {
    #    foreach my $r (@$res) {
    #      $r *= -1;
    #    }
    #  }
    #  $res *= -1 if ($res->at($res->nelem-1) < 0);
    #  return bless $res, 'PDL::Mat';
    return $res;
}

=head2 method to_Hurwitz

$hurwitz_matrix = $m->to_Hurwitz;

Returns the Hurwitz matrix.
The coefficients of the Hurwitz matrix are defined to be:
H_ij = a_{n-2i+j} if 0 < 2i-j <= n, 0 otherwise where a_n are the 
coefficients of the characteristic polynomial.

=cut

sub PDL::Matrix::to_Hurwitz {
    my $matrix = shift;

    #  my @dims = $matrix->dims;
    my $cp_coeff;

    #  if (ref($matrix) =~ /PDL/) {
    if ( !$matrix->isempty ) {
        $cp_coeff = $matrix->char_pol;

        #    print "getting charac. pol. :".join(',',@$cp_coeff)."\n";
    }
    else {

        #    $cp_coeff = $matrix;
        #    croak("to_Hurwitz: matrix is not 2-dim!");
        $cp_coeff = shift;
    }

    #  my $n = @$cp_coeff-1;
    my $n = $cp_coeff->nelem - 1;

    #  my $hurwitz = ref($matrix)->new($n,$n);
    my $hurwitz = mzeroes( $n, $n );
    for ( my $i = 1 ; $i <= $n ; $i++ ) {
        for (
            my $j = 2 * $i - $n > 1 ? 2 * $i - $n : 1 ;
            $j <= $n && $j <= 2 * $i ;
            $j++
          )
        {

            #      print "Setting ($i,$j) to a_".eval($n-2*$i+$j)."\n";
            #      set($hurwitz,$i-1,$j-1,$cp_coeff->at($n-2*$i+$j));
            set( $hurwitz, $j - 1, $i - 1, $cp_coeff->at( $n - 2 * $i + $j ) );
        }
    }

    return $hurwitz;
}

=head2 method Hurwitz_crit

if ($m->Hurwitz_crit) { ... }

Returns true if the Hurwitz condition is fulfilled, i.e. if all
sub-determinants are larger than zero and a_n/a_0 > 0 for all n >= 1.

=cut

sub PDL::Matrix::Hurwitz_crit {
    my $matrix = shift;

    my $cp_coeff = $matrix->char_pol;

    $cp_coeff *= -1 if $cp_coeff->at( $cp_coeff->nelem - 1 ) < 0;

    #  foreach my $c (@$cp_coeff) {
    #    return(0) unless $c > 0;
    #  }
    return (0) unless which( $cp_coeff > 0 )->nelem == $cp_coeff->nelem;

    #  my $hurwitz = $cp_coeff->to_Hurwitz;
    my $hurwitz = PDL::Matrix::null->to_Hurwitz($cp_coeff);

    return $hurwitz->is_pos_def;
}

1;

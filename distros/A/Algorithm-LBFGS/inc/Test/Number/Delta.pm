#line 1
package Test::Number::Delta;
use strict;
#use warnings; bah -- not supported before 5.006

use vars qw ($VERSION @EXPORT @ISA);
$VERSION = "1.03";

# Required modules
use Carp;
use Test::Builder;
use Exporter;

@ISA = qw( Exporter );
@EXPORT = qw( delta_not_ok delta_ok delta_within delta_not_within );

#line 116

my $Test = Test::Builder->new;
my $Epsilon = 1e-6;
my $Relative = undef;

sub import {
    my $self = shift;
    my $pack = caller;
    my $found = grep /within|relative/, @_;
    croak "Can't specify more than one of 'within' or 'relative'"
        if $found > 1;
    if ($found) {
        my ($param,$value) = splice @_, 0, 2;
        croak "'$param' parameter must be non-zero"
            if $value == 0;
        if ($param eq 'within') {
            $Epsilon = abs($value);
        }
        elsif ($param eq 'relative') {
            $Relative = abs($value);
        }
        else {
            croak "Test::Number::Delta parameters must come first";
        }
    } 
    $Test->exported_to($pack);
    $Test->plan(@_);
    $self->export_to_level(1, $self, $_) for @EXPORT;
}

#--------------------------------------------------------------------------#
# _check -- recursive function to perform comparison
#--------------------------------------------------------------------------#

sub _check {
    my ($p, $q, $epsilon, $name, @indices) = @_;
    my ($ok, $diag) = ( 1, q{} ); # assume true
    if ( ref $p eq 'ARRAY' || ref $q eq 'ARRAY' ) {
        if ( @$p == @$q ) {
            for my $i ( 0 .. $#{$p} ) {
                my @new_indices;
                ($ok, $diag, @new_indices) = _check( 
                    $p->[$i], 
                    $q->[$i], 
                    $epsilon, 
                    $name,
                    scalar @indices ? @indices : (),
                    $i,
                );
                if ( not $ok ) {
                    @indices = @new_indices;
                    last;
                }
            }
        }
        else {
            $ok = 0;
            $diag = "Got an array of length " . scalar(@$p) .
                    ", but expected an array of length " . scalar(@$q);
        }
    }
    else {
        $ok = abs($p - $q) < $epsilon;
        if ( ! $ok ) {
            my ($ep, $dp) = _ep_dp( $epsilon );
            $diag = sprintf("%.${dp}f and %.${dp}f are not equal" . 
                " to within %.${ep}f", $p, $q, $epsilon
            );
        }
    }
    return ( $ok, $diag, scalar(@indices) ? @indices : () );
}

sub _ep_dp {
    my $epsilon = shift;
    my ($exp) = sprintf("%e",$epsilon) =~ m/e(.+)/;
    my $ep = $exp < 0 ? -$exp : 1;
    my $dp = $ep + 1;
    return ($ep, $dp);
}

#line 200

#--------------------------------------------------------------------------#
# delta_within()
#--------------------------------------------------------------------------#

#line 237

sub delta_within($$$;$) {
	my ($p, $q, $epsilon, $name) = @_;
    croak "Value of epsilon to delta_within must be non-zero"
        if $epsilon == 0;
    $epsilon = abs($epsilon);
    my ($ok, $diag, @indices) = _check( $p, $q, $epsilon, $name );
    if ( @indices ) {
        $diag = "At [" . join( "][", @indices ) . "]: $diag";
    }
    return $Test->ok($ok,$name) || $Test->diag( $diag );
}

#--------------------------------------------------------------------------#
# delta_ok()
#--------------------------------------------------------------------------#

#line 264

sub delta_ok($$;$) {
	my ($p, $q, $name) = @_;
    {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my $e = $Relative 
            ? $Relative * (abs($p) > abs($q) ? abs($p) : abs($q))
            : $Epsilon;
        delta_within( $p, $q, $e, $name );
    }
}

#--------------------------------------------------------------------------#
# delta_not_ok()
#--------------------------------------------------------------------------#

#line 292

sub delta_not_within($$$;$) {
	my ($p, $q, $epsilon, $name) = @_;
    croak "Value of epsilon to delta_not_within must be non-zero"
        if $epsilon == 0;
    $epsilon = abs($epsilon);
    my ($ok, undef, @indices) = _check( $p, $q, $epsilon, $name );
    $ok = !$ok;
    my ($ep, $dp) = _ep_dp( $epsilon );
    my $diag = sprintf("Arguments are equal to within %.${ep}f", $epsilon);
    return $Test->ok($ok,$name) || $Test->diag( $diag );
}

#line 315

sub delta_not_ok($$;$) {
	my ($p, $q, $name) = @_;
    {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        my $e = $Relative 
            ? $Relative * (abs($p) > abs($q) ? abs($p) : abs($q))
            : $Epsilon;
        delta_not_within( $p, $q, $e, $name );
    }
}


1; #this line is important and will help the module return a true value
__END__

#line 387

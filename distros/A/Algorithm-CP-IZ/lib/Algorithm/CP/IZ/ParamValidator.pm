#
# Parameter validator
#
package Algorithm::CP::IZ::ParamValidator;

use strict;
use warnings;

use base qw(Exporter);

use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(validate);

use Carp;
use vars qw(@CARP_NOT);
@CARP_NOT = qw(Algorithm::CP::IZ);

use Scalar::Util qw(looks_like_number);
use List::Util qw(first);

my $INT_CLASS = "Algorithm::CP::IZ::Int";

sub _is_int {
    my ($x) = @_;
    return looks_like_number($x);
}

sub _is_var_or_int {
    my ($x) = @_;
    my $r = ref $x;
    if ($r) {
	return $r eq $INT_CLASS;
    }
    else {
	return looks_like_number($x);
    }
}

sub _is_code {
    my ($x) = @_;
    return ref $x eq 'CODE';
}

sub _is_code_if_defined {
    my ($x) = @_;
    return defined($x) ? _is_code($x) : 1;
}

sub _is_optional_var {
    my ($x) = @_;
    return 1 unless (defined($x));
    return ref $x eq $INT_CLASS;
}

sub _is_array_of_int {
    my ($n, $x) = @_;
    return 0 unless (ref $x eq 'ARRAY');
    return 0 unless (scalar @$x >= $n);

    my $bad = first {
	!looks_like_number($_);
    } @$x;

    return !defined($bad);
}

sub _is_array_of_var_or_int {
    my ($n, $x) = @_;
    return 0 unless (ref $x eq 'ARRAY');
    return 0 unless (scalar @$x >= $n);

    my $bad = 0;

    first {
	if (defined($_)) {
	    my $v = $_;
	    my $r = ref $v;
	    if ($r) {
		if ($r eq $INT_CLASS) {
		    0;
		}
		else  {
		    $bad++;
		    1;
		}
	    }
	    else {
		if (defined($v) && looks_like_number($v)) {
		    0;
		}
		else {
		    $bad++;
		    1;
		}
	    }
	}
	else {
	    $bad++;
	    1;
	}
    } @$x;

    return $bad == 0;
}

my %Validator = (
    I => \&_is_int,
    V => \&_is_var_or_int,
    C => \&_is_code,
    C0 => \&_is_code_if_defined,
    oV => \&_is_optional_var,
    iA0 => sub { _is_array_of_int(0, @_) },
    iA1 => sub { _is_array_of_int(1, @_) },
    vA0 => sub { _is_array_of_var_or_int(0, @_) },
    vA1 => sub { _is_array_of_var_or_int(1, @_) },
);

sub validate {
    my $params = shift;
    my $types = shift;
    my $hint = shift;

    unless (@$params == @$types) {
	local @CARP_NOT; # to report internal error
	croak __PACKAGE__ . ": n of type does not match with params.";
    }

    for my $i (0..@$params-1) {
	my $rc;

	if (ref $types->[$i] eq 'CODE') {
	    $rc = &{$types->[$i]}($params->[$i]);
	}
	else {
	    unless ($Validator{$types->[$i]}) {
		local @CARP_NOT; # to report internal error
		croak __PACKAGE__ . ": Parameter type($i) " . ($types->[$i] // "undef") . " is not defined.";
	    }

	    $rc = &{$Validator{$types->[$i]}}($params->[$i]);
	}

	unless ($rc) {
	    my ($package, $filename, $line, $subroutine, $hasargs,
		$wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller(1);
	    $subroutine =~ /(.*)::([^:]*)$/;
	    my ($p, $s) = ($1, $2);
	    croak "$p: $hint";
	}
    }
}

1;

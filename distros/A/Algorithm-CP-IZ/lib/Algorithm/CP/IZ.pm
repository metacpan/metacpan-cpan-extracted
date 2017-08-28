package Algorithm::CP::IZ;

# use 5.020001;
use 5.009000; # need Newx in XS
use strict;
use warnings;

use Carp;
use Scalar::Util qw(weaken);

require Exporter;
use AutoLoader;

use Algorithm::CP::IZ::Int;
use Algorithm::CP::IZ::RefVarArray;
use Algorithm::CP::IZ::RefIntArray;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Algorithm::CP::IZ ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	CS_INT_MAX
	CS_INT_MIN
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	CS_INT_MAX
	CS_INT_MIN
);

our $VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Algorithm::CP::IZ::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Algorithm::CP::IZ', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

my $Instances = 0;

sub new {
    my $class = shift;

    if ($Instances > 0) {
	croak __PACKAGE__ . ": another instance is working.";
    }

    Algorithm::CP::IZ::cs_init();
    $Instances++;

    bless {
	_vars => [],
	_cxt0 => [],
	_cxt => [],
	_const_vars => {},
	_backtracks => {},
	_ref_int_arrays => {},
	_ref_var_arrays => {},
    }, $class;
}

sub DESTROY {
    my $self = shift;
    my $vars = $self->{_vars};

    for my $v (@$vars) {
	# we must check existence of variable for global destruction.
	$v->_invalidate($v) if ($v);
    }

    Algorithm::CP::IZ::cs_end();
    $Instances--;
}

sub save_context {
    my $self = shift;
    
    my $ret = Algorithm::CP::IZ::cs_saveContext();

    my $cxt = $self->{_cxt};
    push(@$cxt, []);

    $self->backtrack(undef, 0, sub { pop(@$cxt) });

    return $ret;
}

sub restore_context {
    my $self = shift;

    my $cxt = $self->{_cxt};
    if (@$cxt == 0) {
	croak "restore_context: bottom of context stack";
    }

    Algorithm::CP::IZ::cs_restoreContext();
}

sub restore_context_until {
    my $self = shift;
    my $label = shift;

    Algorithm::CP::IZ::cs_restoreContextUntil($label);
}

sub restore_all {
    my $self = shift;
    my $label = shift;

    Algorithm::CP::IZ::cs_restoreAll();

    # pop must be after cs_restoreContext to save cs_backtrack context.
    $self->{_cxt} = [];
}


sub accept_context {
    my $self = shift;

    my $cxt = $self->{_cxt};
    if (@$cxt == 0) {
	croak "accept_context: bottom of context stack";
    }

    Algorithm::CP::IZ::cs_acceptContext();

    # pop must be after cs_acceptContext to save cs_backtrack context.
    pop(@$cxt);
}

sub accept_context_until {
    my $self = shift;
    my $label = shift;

    my $cxt = $self->{_cxt};

    unless (1 <= $label && $label <= @$cxt) {
	croak "accept_context_until: invalid label";
    }

    while (@$cxt >= $label) {
	Algorithm::CP::IZ::cs_acceptContext();

	# pop must be after cs_acceptContext to save cs_backtrack context.
	pop(@$cxt);
    }
}

sub accept_all {
    my $self = shift;
    my $label = shift;

    Algorithm::CP::IZ::cs_acceptAll();

    # pop must be after cs_acceptContext to save cs_backtrack context.
    $self->{_cxt} = [];
}

my $Backtrack_id = 0;

sub backtrack {
    my $self = shift;
    my ($var, $index, $handler) = @_;

    my $id = $Backtrack_id++;
    $self->{_backtracks}->{$id} = [$var, $index, $handler];

    my $backtracks = $self->{_backtracks};
    weaken($backtracks);

    $self->{_backtrack_code_ref} ||= sub {
	my $bid = shift;
	my $r = $backtracks->{$bid};
	my $bh = $r->[2];
	&$bh($r->[0], $r->[1]);

	delete $backtracks->{$bid};
    };

    my $vptr = defined($var) ? $var->{_ptr} : 0;

    Algorithm::CP::IZ::cs_backtrack($vptr, $id,
				    $self->{_backtrack_code_ref});
}

sub get_nb_fails {
    my $self = shift;

    return Algorithm::CP::IZ::cs_getNbFails();
}

sub get_nb_choice_points {
    my $self = shift;

    return Algorithm::CP::IZ::cs_getNbChoicePoints();
}

sub _create_int_from_min_max {
    my ($self, $min, $max) = @_;
    return Algorithm::CP::IZ::cs_createCSint(int($min), int($max));
}

sub _create_int_from_domain {
    my ($self, $int_array) = @_;

    my $parray = Algorithm::CP::IZ::alloc_int_array([map { int($_) } @$int_array]);
    my $ptr = Algorithm::CP::IZ::cs_createCSintFromDomain($parray, scalar @$int_array);
    Algorithm::CP::IZ::free_array($parray);

    return $ptr;
}

sub create_int {
    my $self = shift;
    my $p1 = shift;

    my $ptr;
    my $name;

    if (!ref $p1 && @_ == 0) {
	return $self->_const_var($p1);
    }
    elsif (ref $p1 && ref $p1 eq 'ARRAY') {
	$name = shift;
	$ptr = $self->_create_int_from_domain($p1);
    }
    else {
	my $min = $p1;
	my $max = shift;
	$name = shift;

	$ptr = $self->_create_int_from_min_max($min, $max);
    }

    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    if (defined $name) {
	$ret->name($name);
    }

    my $vars = $self->{_vars};
    push(@$vars, $ret);

    return $ret;
}

sub search {
    my $self = shift;
    my $var_array = shift;
    my $params = shift;

    my $array = [map { $_->{_ptr } } @$var_array];

    my $max_fail = -1;
    my $find_free_var_id = 0;
    my $find_free_var_func = sub { die "search: Internal error"; };
    my $criteria_func = undef;

    if ($params->{FindFreeVar}) {
	my $ffv = $params->{FindFreeVar};

	if (ref $ffv) {
	    unless (ref $ffv eq 'CODE') {
		croak "search: FindFreeVar must be number or coderef";
	    }

	    $find_free_var_id = -1;
	    $find_free_var_func = sub {
		return &$ffv($var_array);
	    };
	}
	else {
	    $find_free_var_id = int($ffv);
	}
    }

    if ($params->{Criteria}) {
	my $cr = $params->{Criteria};
	unless (ref $cr && ref $cr eq 'CODE') {
	    croak "search: Criteria must be coderef";
	}

	$criteria_func = $cr;
    }

    if ($params->{MaxFail}) {
	$max_fail = int($params->{MaxFail});
    }

    if ($criteria_func) {
	return Algorithm::CP::IZ::cs_searchCriteria($array,
						    $find_free_var_id,
						    $find_free_var_func,
						    $criteria_func,
						    $max_fail);
    }
    else {
 	return Algorithm::CP::IZ::cs_search($array,
					    $find_free_var_id,
					    $find_free_var_func,
					    $max_fail);
   }
}

sub find_all {
    my $self = shift;
    my $var_array = shift;
    my $found_func = shift;
    my $params = shift;

    unless (ref $found_func eq 'CODE') {
	croak "find_all: usage: find_all([vars], &callback_func, {params})";
    }

    my $array = [map { $_->{_ptr } } @$var_array];

    my $find_free_var_id = 0;
    my $find_free_var_func = sub { die "find_all: Internal error"; };

    if ($params->{FindFreeVar}) {
	my $ffv = $params->{FindFreeVar};

	if (ref $ffv) {
	    unless (ref $ffv eq 'CODE') {
		croak "find_all: FindFreeVar must be number or coderef";
	    }

	    $find_free_var_id = -1;
	    $find_free_var_func = sub {
		return &$ffv($var_array);
	    };
	}
	else {
	    $find_free_var_id = int($ffv);
	}
    }

    my $call_back = sub {
	&$found_func($var_array);
    };

    return Algorithm::CP::IZ::cs_findAll($array,
					 $find_free_var_id,
					 $find_free_var_func,
					 $call_back);
}

sub _push_object {
    my $self = shift;
    my $obj = shift;

    my $cxt = $self->{_cxt};
    my $cur_cxt = $self->{_cxt0};

    if (scalar @$cxt > 0) {
	$cur_cxt = $cxt->[(scalar @$cxt) - 1];
    }

    push(@$cur_cxt, $obj);
}

sub _create_registered_var_array {
    my $self = shift;
    my $var_array = shift;;

    my $key = join(",", map { sprintf("%x", $_->{_ptr}) } @$var_array);
    my $r = $self->{_ref_var_arrays}->{$key};
    return $r if ($r);

    my $parray = Algorithm::CP::IZ::RefVarArray->new($var_array);
    $self->{_ref_var_arrays}->{$key} = $parray;

    return $parray;
}

sub _create_registered_int_array {
    my $self = shift;
    my $int_array = shift;;

    my $key = join(",", map { sprintf("%x", $_) } @$int_array);
    my $r = $self->{_ref_int_arrays}->{$key};
    return $r if ($r);

    my $parray = Algorithm::CP::IZ::RefIntArray->new($int_array);
    $self->{_ref_int_arrays}->{$key} = $parray;

    return $parray;
}

sub _const_var {
    my $self = shift;
    my $val = shift;

    my $hash = $self->{_const_vars};

    return $hash->{$val} if (exists($hash->{$val}));

    my $v = $self->create_int($val, $val);
    $hash->{$val} = $v;

    return $v;
}

#####################################################
# Demon
#####################################################

sub event_all_known {
    my $self = shift;
    my ($var_array, $handler, $ext) = @_;

    my $parray = $self->_create_registered_var_array($var_array);

    my $h = sub {
	return &$handler($var_array, $ext) ? 1 : 0;
    };

    $self->_push_object($h);

    return Algorithm::CP::IZ::cs_eventAllKnown($$parray, scalar(@$var_array), $h);
}

sub event_known {
    my $self = shift;
    my ($var_array, $handler, $ext) = @_;

    my $parray = $self->_create_registered_var_array($var_array);

    my $h = sub {
	my ($val, $index) = @_;
	return &$handler($val, $index, $var_array, $ext) ? 1 : 0;
    };

    $self->_push_object($h);

    return Algorithm::CP::IZ::cs_eventKnown($$parray, scalar(@$var_array), $h);
}

sub event_new_min {
    my $self = shift;
    my ($var_array, $handler, $ext) = @_;

    my $parray = $self->_create_registered_var_array($var_array);

    my $h = sub {
	my ($index, $old_min) = @_;
	return &$handler($var_array->[$index], $index, $old_min, $var_array, $ext) ? 1 : 0;
    };

    $self->_push_object($h);

    return Algorithm::CP::IZ::cs_eventNewMin($$parray, scalar(@$var_array), $h);
}

sub event_new_max {
    my $self = shift;
    my ($var_array, $handler, $ext) = @_;

    my $parray = $self->_create_registered_var_array($var_array);

    my $h = sub {
	my ($index, $old_min) = @_;
	return &$handler($var_array->[$index], $index, $old_min, $var_array, $ext) ? 1 : 0;
    };

    $self->_push_object($h);

    return Algorithm::CP::IZ::cs_eventNewMax($$parray, scalar(@$var_array), $h);
}

sub event_neq {
    my $self = shift;
    my ($var_array, $handler, $ext) = @_;

    my $parray = $self->_create_registered_var_array($var_array);

    my $h = sub {
	my ($index, $val) = @_;
	return &$handler($var_array->[$index], $index, $val, $var_array, $ext) ? 1 : 0;
    };

    $self->_push_object($h);

    return Algorithm::CP::IZ::cs_eventNeq($$parray, scalar(@$var_array), $h);
}

#####################################################
# Global constraints
#####################################################

sub _register_variable {
    my ($self, $var) = @_;

    my $vars = $self->{_vars};
    push(@$vars, $var);
}

sub _argv_func {
    my $v = shift;
    my $N = shift;
    my $arg2_func = shift;
    my $argv_func = shift;

    if (@$v == 1) {
	return $v;
    }
    elsif (@$v == 2) {
	no strict "refs";
	return &$arg2_func(@$v);
    }
    elsif (@$v <= $N) {
	my $n = scalar @$v;
	no strict "refs";
	my $xs = "$argv_func$n";
	return &$xs(@$v);
    }

    my @ptrs;
    my @rest = @$v;
    for my $i (1..$N) {
	my $p = shift @rest;
	push(@ptrs, $p);
    }

    push(@rest, _argv_func(\@ptrs, $N, $arg2_func, $argv_func));

    return _argv_func(\@rest, $N, $arg2_func, $argv_func);
}

sub Add {
    my $self = shift;
    my @params = @_;

    if (@params < 1) {
	croak 'usage: Add(v1, v2, ...)';
    }
    if (@params == 1) {
	return $params[0] if (ref $params[0]);
	return $self->_const_var(int($params[0]));
    }

    my @v = map { ref $_ ? $_ : $self->_const_var(int($_)) } @params;

    my $ptr = _argv_func([map { $_->{_ptr}} @v], 10,
			 "Algorithm::CP::IZ::cs_Add",
			 "Algorithm::CP::IZ::cs_VAdd");

    my $ret = Algorithm::CP::IZ::Int->new($ptr);
    $self->_register_variable($ret);

    return $ret;
}

sub Mul {
    my $self = shift;
    my @params = @_;

    if (@params < 1) {
	croak 'usage: Mul(v1, v2, ...)';
    }
    if (@params == 1) {
	return $params[0] if (ref $params[0]);
	return $self->_const_var(int($params[0]));
    }

    my @v = map { ref $_ ? $_ : $self->_const_var(int($_)) } @params;

    my $ptr = _argv_func([map { $_->{_ptr}} @v], 10,
			 "Algorithm::CP::IZ::cs_Mul",
			 "Algorithm::CP::IZ::cs_VMul");

    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub Sub {
    my $self = shift;
    my @params = @_;

    if (@params != 2) {
	croak 'usage: Sub(v1, v2)';
    }

    my @v = map { ref $_ ? $_ : $self->_const_var(int($_)) } @params;
    my $ptr = Algorithm::CP::IZ::cs_Sub(map {$_->{_ptr}} @v);
    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub Div {
    my $self = shift;
    my @params = @_;

    if (@params != 2) {
	croak 'usage: Div(v1, v2)';
    }

    my @v = map { ref $_ ? $_ : $self->_const_var(int($_)) } @params;
    my $ptr = Algorithm::CP::IZ::cs_Div(map {$_->{_ptr}} @v);

    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub ScalProd {
    my $self = shift;
    my $vars = shift;
    my $coeffs = shift;

    if (@$coeffs != @$vars) {
	croak 'usage: ScalProd([ceoffs], [vars])';
    }

    @$vars = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$vars;

    my $p1 = $self->_create_registered_var_array($vars);
    my $p2 = $self->_create_registered_int_array($coeffs);
    my $n = @$coeffs;

    my $ptr = Algorithm::CP::IZ::cs_ScalProd($$p1, $$p2, $n);
    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub AllNeq {
    my $self = shift;
    my $var_array = shift;;

    my $parray = $self->_create_registered_var_array($var_array);

    return Algorithm::CP::IZ::cs_AllNeq($$parray, scalar(@$var_array));
}

sub Sigma {
    my $self = shift;
    my $var_array = shift;;

    unless (ref $var_array eq 'ARRAY') {
	croak "Sigma: usage: Sigma([vars])";
    }

    @$var_array = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$var_array;

    my $parray = $self->_create_registered_var_array($var_array);

    my $ptr = Algorithm::CP::IZ::cs_Sigma($$parray, scalar(@$var_array));

    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub Abs {
    my $self = shift;
    my @params = @_;

    if (@params != 1) {
	croak 'usage: Abs(v)'
    }

    my @v = map { ref $_ ? $_ : $self->_const_var(int($_)) } @params;
    my $ptr = Algorithm::CP::IZ::cs_Abs(map {$_->{_ptr}} @v);
    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub Min {
    my $self = shift;
    my $var_array = shift;;

    unless (ref $var_array eq 'ARRAY') {
	croak "Min: usage: Min([vars])";
    }

    @$var_array = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$var_array;

    my $parray = $self->_create_registered_var_array($var_array);

    my $ptr = Algorithm::CP::IZ::cs_Min($$parray, scalar(@$var_array));

    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub Max {
    my $self = shift;
    my $var_array = shift;;

    unless (ref $var_array eq 'ARRAY') {
	croak "Max: usage: Max([vars])";
    }

    @$var_array = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$var_array;

    my $parray = $self->_create_registered_var_array($var_array);

    my $ptr = Algorithm::CP::IZ::cs_Max($$parray, scalar(@$var_array));

    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub IfEq {
    my $self = shift;
    unless (scalar @_ == 4 && ref $_[0] && ref $_[1]) {
	croak "IfEq: usage: IfEq(vint1, vint2, val1, val2)";
    }
    my ($vint1, $vint2, $val1, $val2) = @_;

    return Algorithm::CP::IZ::cs_IfEq($vint1->{_ptr}, $vint2->{_ptr},
				      int($val1), int($val2));
}

sub IfNeq {
    my $self = shift;
    unless (scalar @_ == 4 && ref $_[0] && ref $_[1]) {
	croak "IfNeq: usage: IfNeq(vint1, vint2, val1, val2)";
    }
    my ($vint1, $vint2, $val1, $val2) = @_;

    return Algorithm::CP::IZ::cs_IfNeq($vint1->{_ptr}, $vint2->{_ptr},
				       $val1, $val2);
}

sub OccurDomain {
    my $self = shift;

    unless (scalar @_ == 2 && !ref $_[0] && ref $_[1] && ref $_[1] eq 'ARRAY') {
	croak "OccurDomain: usage: OccurDomain(val, [array])";
    }
    my ($val, $var_array) = @_;

    @$var_array = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$var_array;

    my $parray = $self->_create_registered_var_array($var_array);

    my $ptr = Algorithm::CP::IZ::cs_OccurDomain(int($val),
						$$parray, scalar(@$var_array));

    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub OccurConstraints {
    my $self = shift;

    unless (scalar @_ == 3
	    && !ref $_[1]
	    && ref $_[2] && ref $_[2] eq 'ARRAY') {

	croak "usage: OccurConstraints(vint, val, [array])";
    }
    my ($vint, $val, $var_array) = @_;

    $vint = ref $vint ? $vint : $self->_const_var(int($vint));
    @$var_array = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$var_array;

    my $parray = $self->_create_registered_var_array($var_array);

    my $ret = Algorithm::CP::IZ::cs_OccurConstraints($vint->{_ptr}, int($val),
						     $$parray,
						     scalar(@$var_array));
    return $ret;
}

sub Index {
    my $self = shift;

    unless (scalar @_ == 2
	    && ref $_[0] && ref $_[0] eq 'ARRAY'
	    && !ref $_[1]) {

	croak "usage: Index([var_array], val)";
    }
    my ($var_array, $val) = @_;

    @$var_array = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$var_array;

    my $parray = $self->_create_registered_var_array($var_array);

    my $ptr = Algorithm::CP::IZ::cs_Index($$parray, scalar(@$var_array), $val);
    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub Element {
    my $self = shift;

    unless (scalar @_ == 2
	    && ref $_[0]
	    && ref $_[1] && ref $_[1] eq 'ARRAY') {

	croak "usage: Element(index, [value_array])";
    }
    my ($index, $val_array) = @_;

    @$val_array = map { int($_) } @$val_array;

    my $parray = $self->_create_registered_int_array($val_array);

    my $ptr = Algorithm::CP::IZ::cs_Element($index->{_ptr},
					    $$parray, scalar(@$val_array));
    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

#
# Create Reif* Methods
#
{
    my @names = qw(Eq Neq Lt Le Gt Ge);
    
    for my $n (@names) {
	my $meth_name = "Reif$n";
	my $ucn = uc $n;

	my $meth = sub {
	    my $self = shift;
	    unless (@_ == 2) {
		carp "Usage: $meth_name(v1, v2)";
	    }

	    my ($v1, $v2) = @_;
	    my $ptr;

	    if (!ref $v1) {
		$v1 = $self->_const_var(int($v1));
	    }

	    if (ref $v2) {
		my $func = "Algorithm::CP::IZ::cs_Reif$n";

		no strict "refs";
		$ptr = &$func($v1->{_ptr}, $v2->{_ptr});
	    }
	    else {
		my $func = "Algorithm::CP::IZ::cs_Reif$ucn";

		no strict "refs";
		$ptr = &$func($v1->{_ptr}, int($v2));
	    }
	    my $ret = Algorithm::CP::IZ::Int->new($ptr);

	    $self->_register_variable($ret);
	    return $ret;
	};

	no strict "refs";
	*$meth_name = $meth;
    }
}


1;
__END__

=head1 NAME

Algorithm::CP::IZ - Perl interface for iZ-C library

=head1 SYNOPSIS

  use Algorithm::CP::IZ;

  my $iz = Algorithm::CP::IZ->new();

  my $v1 = $iz->create_int(1, 9);
  my $v2 = $iz->create_int(1, 9);
  $iz->Add($v1, $v2)->Eq(12);
  my $rc = $iz->search([$v1, $v2]);

  if ($rc) {
    print "ok\n";
    print "v1 = ", $v1->value, "\n";
    print "v2 = ", $v2->value, "\n";
  }
  else {
    print "fail\n";
  }

=head1 DESCRIPTION

Algorithm::CP::IZ is a simple interface of iZ-C constraint programming library.

Functions declared in iz.h are mapped to:

=over 2

=item methods of Algorithm::CP::IZ

initialize, variable constructor, most of constraints
and search related functions

=item methods of Algorithm::CP::IZ::Int

accessors of variable attributes and some constraints

=back

Please refer to iZ-C reference manual to see specific meaning of methods.


=head2 SIMPLE CASE

In most simple case, this library will be used like following steps:

  # initialize
  use Algorithm::CP::IZ;
  my $iz = Algorithm::CP::IZ->new();

  # construct variables
  my $v1 = $iz->create_int(1, 9);
  my $v2 = $iz->create_int(1, 9);

  # add constraints ("v1 + v2 = 12" in this case)
  $iz->Add($v1, $v2)->Eq(12);

  # search solution
  my $rc = $iz->search([$v1, $v2]);

  # you may get "v1 = 3, v2 = 9"
  print "v1 = $v1, v2 = $v2\n";

=head1 CONSTRUCTOR

=over 2

=item new

Initialize iZ-C library (cs_init is called).
For limitation of iZ-C, living instance of Algorithm::CP::IZ must be
only one per process.

=back

=head1 METHODS

=over 2

=item create_int(INT)

Create Algorithm::CP::IZ::Int instance. Its domain contains INT.

=item create_int(VALUES [, NAME])

Create Algorithm::CP::IZ::Int instance. Its domain contains values
specified by VALUES(arrayref).

=item create_int(MIN, MAX, [, NAME])

Create Algorithm::CP::IZ::Int instance. Its domain is {MIN..MAX}.

=item search(VARIABLES [, PARAMS])

Try to instantiate all VARIABLES(arrayref).

PARAMS will be hashref containning following keys.

=over 2

=item FindFreeVar

FindFreeVar specifies variable selection strategy.
Choose constants from Algorithm::CP::IZ::FindFreeVar or specify your own
function as coderef here.

Most simple function will be following. (select from first)

    sub simple_find_free_var{
	my $array = shift; # VARIABLES is in parameter
	my $n = scalar @$array;

	for my $i (0..$n-1) {
	    return $i if ($array->[$i]->is_free);
	}

	return -1; # no free variable
    };

=item Criteria

Criteria specifies value selection strategy.
Specify your own function as coderef here.

    sub sample_criteria {
      # position in VARIABLES, and candidate value
      my ($index, $val) = @_;

      # first value used in search is
      # minimum value returned by criteria.
      return $val;
    };


=item MaxFail

Upper limit of fail count while searching solutions.

=back

Returns 1 (success) or 0 (fail).

=item find_all(VARIABLES, CALLBACK [, PARAMS])

Find all solutions. CALLBACK(coderef) is called for each solution.
(First parameter of CALLBACK is VARIABLE)

    # this callback collects all solutions in @r
    my @r;
    sub callback {
      my $var_array = shift;
      push(@r, [map { $_->value } @$var_array]);
    };

PARAMS will be hashref containning following keys.

=over 2

=item FindFreeVar

Same as search method.

=back

Returns 1 (success) or 0 (fail).

=item get_nb_fails

Returns fail count while search solution.

=item get_nb_choice_points

Returns choice count while search solution.

=item save_context

Save current status of variables and constraints.

  my $v1 = $iz->create_int(1, 9);
  $iz->save_context;    # current status is saved.
  $v1->Le(5);           # $v1 is {1..5}
  $iz->restore_context; # $v1 is restored to {1..9}

Returns integer which will be used for restore_context_until.

=item restore_context

Restore status of variables and constraints to last point which
'save_context' is called.

=item restore_context_until(LABEL)

Restore status of variables and constraints to point of label
which 'save_context' returns.

=item restore_all

Restore status of variables and constraints to point of first
'save_context' call.

=item backtrack(VAR, INDEX, CALLBACK)

Set a callback function which will be called when context is restored to
current status.

VAR is an instance of Algorithm::CP::IZ::Int.

INDEX is an integer value.

CALLBACK is a coderef which takes parameters like:

  sub callback {
      # $var = VAR, $index = INDEX
      my ($var, $index) = @_;
  }

=item event_all_known(VARIABLES, CALLBACK, EXTRA)

Set a callback function which will be called when all variables in VARIABLES are
instantiated.

VARIABLES is an arrayref contains Create Algorithm::CP::IZ::Int.

CALLBACK is a coderef and takes parameters and must return like:

  sub callback {
      # $variables and $extra are same as parameter.
      my ($variables, $extra) = @_;

      # return 1(success) or 0(fail)
      return 1;
  }

EXTRA is a just a data passed to callbeck as parameter (it can be anything).

=item event_known(VARIABLES, CALLBACK, EXTRA)

Set a callback function which will be called when any variable in VARIABLES is
instantiated.

VARIABLES is an arrayref contains Create Algorithm::CP::IZ::Int.

CALLBACK is a coderef and takes parameters and must return like:

  sub callback {
      # $val is instantited now.
      # $index is position in $variables.
      # $variables and $extra are same as parameter.
      my ($val, $index, $variables, $extra) = @_;

      # return 1(success) or 0(fail)
      return 1;
  }

EXTRA is a just a data passed to callbeck as parameter (it can be anything).

=item event_new_min(VARIABLES, CALLBACK, EXTRA)

Set a callback function which will be called when lower bound of any variable
in VARIABLES is changed.

VARIABLES is an arrayref contains Create Algorithm::CP::IZ::Int.

CALLBACK is a coderef and takes parameters and must return like:

  sub callback {
      # minimum value of $var is changed from $old_min.
      # $var is same as $variables[$index].
      # $variables and $extra are same as parameter.
      my ($var, $index, $old_min, $variables, $extra) = @_;

      # return 1(success) or 0(fail)
      return 1;
  }

EXTRA is a just a data passed to callbeck as parameter (it can be anything).

=item event_new_max(VARIABLES, CALLBACK, EXTRA)

Set a callback function which will be called when upper bound of any variable
in VARIABLES is changed.

VARIABLES is an arrayref contains Create Algorithm::CP::IZ::Int.

CALLBACK is a coderef and takes parameters and must return like:

  sub callback {
      # maximum value of $var is changed from $old_max.
      # $var is same as $variables[$index].
      # $variables and $extra are same as parameter.
      my ($var, $index, $old_max, $variables, $extra) = @_;

      # return 1(success) or 0(fail)
      return 1;
  }

EXTRA is a just a data passed to callbeck as parameter (it can be anything).

=item event_neq(VARIABLES, CALLBACK, EXTRA)

Set a callback function which will be called when value of any variable is
removed in VARIABLES is changed.

VARIABLES is an arrayref contains Create Algorithm::CP::IZ::Int.

CALLBACK is a coderef and takes parameters and must return like:

  sub callback {
      # $val is removed from $var.
      # $var is same as $variables[$index].
      # $variables and $extra are same as parameter.
      my ($var, $index, $val, $variables, $extra) = @_;

      # return 1(success) or 0(fail)
      return 1;
  }

EXTRA is a just a data passed to callbeck as parameter (it can be anything).

=back

=head1 METHODS (Constraints)

=over 2

=item Add(VAR1, VAR2 [, VAR3....])

Create new Algorithm::CP::IZ::Int instance constrainted to be:

  CREATED = VAR1 + VAR2 + ....

=item Mul(VAR1, VAR2 [, VAR3....])

Create Algorithm::CP::IZ::Int instance constrainted to be:

  CREATED = VAR1 * VAR2 * ....

=item Sub(VAR1, VAR2)

Create Algorithm::CP::IZ::Int instance constrainted to be:

  CREATED = VAR1 - VAR2

=item Div(VAR1, VAR2)

Create Algorithm::CP::IZ::Int instance constrainted to be:

  CREATED = VAR1 / VAR2

=item ScalProd(VARIABLES, COEFFICIENTS)

Create Algorithm::CP::IZ::Int instance constrainted to be:

  CREATED = COEFFICIENTS[0]*VARIABLES[0] + COEFFICIENTS[1]*VARIABLES[1] + ...

VARIABLES is an arrayref contains Create Algorithm::CP::IZ::Int,
and COEFFICIENTS is an arreyref contains integer values.

=item AllNeq(VARIABLES)

Constraint all variables in VARIABLES to be different each other.

VARIABLES is an arrayref contains Create Algorithm::CP::IZ::Int.

Returns 1 (success) or 0 (fail).

=item Sigma(VARIABLES)

Create Algorithm::CP::IZ::Int instance constrainted to be:

  CREATED = VARIABLES[0] + VARIABLES[1] + ...

VARIABLES is an arrayref contains Create Algorithm::CP::IZ::Int.

=item Abs(VAR)

Create Algorithm::CP::IZ::Int instance constrainted to be:

  CREATED = abs(VAR)

=item Min(VARIABLES)

Create Algorithm::CP::IZ::Int instance constrainted to be:

  CREATED = minimum value of (VARIABLES[0], VARIABLES[1], ...)

VARIABLES is an arrayref contains Create Algorithm::CP::IZ::Int.

=item Max(VARIABLES)

Create Algorithm::CP::IZ::Int instance constrainted to be:

  CREATED = maximum value of (VARIABLES[0], VARIABLES[1], ...)

VARIABLES is an arrayref contains Create Algorithm::CP::IZ::Int.

=item IfEq(VAR1, VAR2, VAL1, VAL2)

Constraint VAR1 and VAR2 to be:

  VAR1 is instantiated to VAL1 and VAR2 is instantiated to VAL2.
  VAR2 is instantiated to VAL2 and VAR1 is instantiated to VAL1.

Returns 1 (success) or 0 (fail).

=item IfNeq(VAR1, VAR2, VAL1, VAL2)

Constraint VAR1 and VAR2 to be:

  pair (VAR1, VAR2) != pair (VAL1, VAL2)

Returns 1 (success) or 0 (fail).

=item OccurDomain(VAL, VARIABLES)

Create Algorithm::CP::IZ::Int instance represents count of VAL in VARIABLES.

VARIABLES is an arrayref contains Create Algorithm::CP::IZ::Int.

=item OccurConstraints(VAR, VAL, VARIABLES)

Constraint VAR to represent count of VAL in VARIABLES.

VARIABLES is an arrayref contains Create Algorithm::CP::IZ::Int.

Returns 1 (success) or 0 (fail).

=item Index(VARIABLES, VAL)

Create Algorithm::CP::IZ::Int instance represents position of VAL in VARIABLES.

  VAL = VARIABLES[CREATED]

VARIABLES is an arrayref contains Create Algorithm::CP::IZ::Int.

=item Element(VAR, VALUES)

Create Algorithm::CP::IZ::Int instance represents value at VAR in VARIABLES.

  CREATED = VARIABLES[VAR]

VARIABLES is an arrayref contains Create Algorithm::CP::IZ::Int.

=item ReifEq(VAR1, VAR2)

Create Algorithm::CP::IZ::Int instance represents VAR1 == VAR2.
Created variable will be instantiated to 1 when VAR1 == VAR2 otherwise to 0.

=item ReifNeq(VAR1, VAR2)

Create Algorithm::CP::IZ::Int instance represents VAR1 != VAR2.
Created variable will be instantiated to 1 when VAR1 != VAR2 otherwise to 0.

=item ReifLt(VAR1, VAR2)

Create Algorithm::CP::IZ::Int instance represents VAR1 < VAR2.
Created variable will be instantiated to 1 when VAR1 < VAR2 otherwise to 0.

=item ReifLe(VAR1, VAR2)

Create Algorithm::CP::IZ::Int instance represents VAR1 <= VAR2.
Created variable will be instantiated to 1 when VAR1 <= VAR2 otherwise to 0.

=item ReifGt(VAR1, VAR2)

Create Algorithm::CP::IZ::Int instance represents VAR1 > VAR2.
Created variable will be instantiated to 1 when VAR1 > VAR2 otherwise to 0.

=item ReifGe(VAR1, VAR2)

Create Algorithm::CP::IZ::Int instance represents VAR1 >= VAR2.
Created variable will be instantiated to 1 when VAR1 >= VAR2 otherwise to 0.

=back

=head1 SEE ALSO

L<Algorithm::CP::IZ::Int>
L<Algorithm::CP::IZ::FindFreeVar>

=head1 AUTHOR

Toshimitsu FUJIWARA, E<lt>tttfjw at gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Toshimitsu FUJIWARA

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

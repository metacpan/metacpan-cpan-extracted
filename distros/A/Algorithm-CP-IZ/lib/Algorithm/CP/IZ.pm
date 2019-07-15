package Algorithm::CP::IZ;

use 5.010000; # need Newx in XS
use strict;
use warnings;

use Carp;
use Scalar::Util qw(weaken blessed);

require Exporter;
use AutoLoader;

use Algorithm::CP::IZ::Int;
use Algorithm::CP::IZ::RefVarArray;
use Algorithm::CP::IZ::RefIntArray;
use Algorithm::CP::IZ::ParamValidator qw(validate);
use Algorithm::CP::IZ::ValueSelector;
use Algorithm::CP::IZ::CriteriaValueSelector;
use Algorithm::CP::IZ::NoGoodSet;
use Algorithm::CP::IZ::SearchNotify;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Algorithm::CP::IZ ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'value_selector' => [ qw(
    CS_VALUE_SELECTOR_MIN_TO_MAX
    CS_VALUE_SELECTOR_MAX_TO_MIN
    CS_VALUE_SELECTOR_LOWER_AND_UPPER
    CS_VALUE_SELECTOR_UPPER_AND_LOWER
    CS_VALUE_SELECTOR_MEDIAN_AND_REST
    CS_VALUE_SELECTION_EQ
    CS_VALUE_SELECTION_NEQ
    CS_VALUE_SELECTION_LE
    CS_VALUE_SELECTION_LT
    CS_VALUE_SELECTION_GE
    CS_VALUE_SELECTION_GT
) ]);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'value_selector'} } );

our $VERSION = '0.05';

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

sub _report_error {
    my $msg = shift;
    croak __PACKAGE__ . ": ". $msg;
}

sub new {
    my $class = shift;

    if ($Instances > 0) {
	_report_error("another instance is working.");
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
	_report_error("restore_context: bottom of context stack");
    }

    Algorithm::CP::IZ::cs_restoreContext();
}

sub restore_context_until {
    my $self = shift;
    my $label = shift;

    validate([$label], ["I"],
	     "Usage: restore_context_until(int_label)");

    my $cxt = $self->{_cxt};
    if (@$cxt == 0) {
	_report_error("restore_context_until: invalid label");
    }

    Algorithm::CP::IZ::cs_restoreContextUntil($label);
}

sub forget_save_context {
    my $self = shift;

    my $cxt = $self->{_cxt};
    if (@$cxt == 0) {
	_report_error("forget_save_context: bottom of context stack");
    }

    Algorithm::CP::IZ::cs_forgetSaveContext();
}

sub forget_save_context_until {
    my $self = shift;
    my $label = shift;

    validate([$label], ["I"],
	     "Usage: forget_save_context_until(int_label)");

    my $cxt = $self->{_cxt};
    if (@$cxt == 0) {
	_report_error("forget_save_context_until: invalid label");
    }

    Algorithm::CP::IZ::cs_forgetSaveContextUntil($label);
}

sub restore_all {
    my $self = shift;

    Algorithm::CP::IZ::cs_restoreAll();

    # pop must be after cs_restoreContext to save cs_backtrack context.
    $self->{_cxt} = [];
}


sub accept_context {
    my $self = shift;

    my $cxt = $self->{_cxt};
    if (@$cxt == 0) {
	_report_error("accept_context: bottom of context stack");
    }

    Algorithm::CP::IZ::cs_acceptContext();

    # pop must be after cs_acceptContext to save cs_backtrack context.
    pop(@$cxt);
}

sub accept_context_until {
    my $self = shift;
    my $label = shift;

    validate([$label], ["I"],
	     "Usage: accept_context_until(int_label)");

    my $cxt = $self->{_cxt};
    if (@$cxt == 0) {
	_report_error("accept_context_until: invalid label");
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

    validate([$var, $index, $handler], ["oV", "I", "C"],
	     "Usage: backtrack(variable, index, code_ref)");

    $var = _safe_var($var) if (defined($var));
    
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

    my $vptr = defined($var) ? $$var : 0;

    Algorithm::CP::IZ::cs_backtrack($vptr, $id,
				    $self->{_backtrack_code_ref});
}

sub _create_int_from_min_max {
    my ($self, $min, $max) = @_;
    validate([$min, $max], ["I", "I"], "Usage: create_int(min, max), create_int(constant), create_int([domain])");
    return Algorithm::CP::IZ::cs_createCSint(int($min), int($max));
}

sub _create_int_from_domain {
    my ($self, $int_array) = @_;
    validate([$int_array], ["iA1"], "Usage: create_int(min, max), create_int(constant), create_int([domain])");

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
	unless ($ptr) {
	    my $param_str = join(", ", @$p1);
	    _report_error("cannot create variable from [$param_str]");
	}
    }
    else {
	my $min = $p1;
	my $max = shift;
	$name = shift;

	$ptr = $self->_create_int_from_min_max($min, $max);
	unless ($ptr) {
	    my $param_str = join(", ", $min, $max);
	    _report_error("cannot create variable from ($param_str)");
	}
    }

    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    if (defined $name) {
	$ret->name($name);
    }

    my $vars = $self->{_vars};
    push(@$vars, $ret);

    return $ret;
}

sub _validate_search_params {
    my ($var_array, $params) = @_;
    return 1 unless (defined($params));
    return 0 unless (ref $params eq 'HASH');

    my %checker = (
	FindFreeVar => sub {
	    my $x = shift;
	    if (ref $x) {
		validate([$x], ["C"], "search: FindFreeVar must be a number or a coderef");
	    }
	    else {
		validate([$x], ["I"], "search: FindFreeVar must be a number or a coderef");
	    }
	},
	Criteria => sub {
	    my $x = shift;
	    validate([$x], ["C"], "search: Criteria must be a coderef");
	    return 1;
	},
	MaxFail => sub {
	    my $x = shift;
	    validate([$x], ["I"], "search: MaxFail must be an integer");
	},
	ValueSelectors => sub {
	    my $x = shift;
	    validate([$x], [
			 sub {
			     my $vs = shift;
			     return unless (ref $vs eq 'ARRAY'
					    && scalar @$vs == scalar @$var_array);
			     for my $obj (@$vs) {
				 return unless (blessed($obj)
						&& $obj->isa("Algorithm::CP::IZ::ValueSelector"));
			     }
			     1;
			 }], "search: ValueSelectos must be a arrayref of Algorithm::CP::IZ::ValueSelector instance for each variables");
	},
	MaxFailFunc => sub {
	    my $x = shift;
	    validate([$x], ["C"], "search: MaxFailFunc must be a coderef");
	},
	NoGoodSet => sub {
	    my $x = shift;
	    validate([$x], [
			 sub {
			     my $ngs = shift;
			     return blessed($ngs) && $ngs->isa("Algorithm::CP::IZ::NoGoodSet");
			 }], "search: NoGoodSet must be a instance of Algorithm::CP::IZ::NoGoodSet");
	},
	Notify => sub {
	    my $x = shift;
	    validate([$x], [
			 sub {
			     my $notify = shift;
			     return 1 if (ref $notify eq 'HASH');
			     return 1 if (blessed($notify));
			     return 0;
			 }], "search: Notify must be an hashref or object");
	},
    );

    my @keys = sort keys %$params;

    for my $k (@keys) {
	if (exists $checker{$k}) {
	    my $func = $checker{$k};
	    &$func($params->{$k});
	}
	else {
	    _report_error("search: Unknown Key $k in params");
	}
    }

    return 1;
}

sub search {
    my $self = shift;
    my $var_array = shift;
    my $params = shift;

    validate([$var_array, $params], ["vA0", sub {_validate_search_params($var_array, @_)}],
	     "Usage: search([variables], {key=>value,...}");

    my $array = [map { $$_ } @$var_array];
    my $max_fail = -1;
    my $find_free_var_id = 0;
    my $find_free_var_func = sub { die "search: Internal error"; };
    my $criteria_func;
    my $value_selectors;
    my $max_fail_func;
    my $ngs;
    my $notify;
    
    if ($params->{FindFreeVar}) {
	my $ffv = $params->{FindFreeVar};

	if (ref $ffv) {
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
	$criteria_func = $params->{Criteria};
    }

    if ($params->{MaxFail}) {
	$max_fail = int($params->{MaxFail});
    }

    if ($params->{ValueSelectors}) {
	$value_selectors = $params->{ValueSelectors};
    }

    if ($params->{MaxFailFunc}) {
	$max_fail_func = $params->{MaxFailFunc};
    }

    if ($params->{NoGoodSet}) {
	$ngs = $params->{NoGoodSet};
    }

    if ($params->{Notify}) {
	$notify = $params->{Notify};
	unless (ref $notify eq 'Algorithm::CP::IZ::SearchNotify') {
	    $notify = Algorithm::CP::IZ::SearchNotify->new($notify);
	}

	$notify->set_var_array($var_array);
    }

    my $is_search35 = $value_selectors || $max_fail_func || $ngs || $notify;

    if ($is_search35) {
	unless ($value_selectors) {
	    if ($criteria_func) {
		$Algorithm::CP::IZ::CriteriaValueSelector::CriteriaFunction = $criteria_func;
		
		$value_selectors = [
		    map {
			$self->create_value_selector_simple("Algorithm::CP::IZ::CriteriaValueSelector")
		    } (0..scalar(@$var_array)-1)];
	    }
	    else {
		$value_selectors = [
		    map {
			$self->get_value_selector(&CS_VALUE_SELECTOR_MIN_TO_MAX)
		    } (0..scalar(@$var_array)-1)];
	    }
	}
	
	my $i = 0;
	for my $v (@$array) {
	    my $vs = $value_selectors->[$i];
	    $vs->prepare($i);
	    $i++;
	}

	if ($max_fail_func) {
	    return Algorithm::CP::IZ::cs_searchValueSelectorRestartNG(
		$array,
		$value_selectors,
		$find_free_var_id,
		$find_free_var_func,
		$max_fail_func,
		$max_fail,
		defined($ngs) ? $ngs->{_ngs} : 0,
		defined($notify) ? $notify->{_ptr} : 0);
	}
	else {
	    return Algorithm::CP::IZ::cs_searchValueSelectorFail(
		$array,
		$value_selectors,
		$find_free_var_id,
		$find_free_var_func,
		$max_fail,
		defined($notify) ? $notify->{_ptr} : 0);
	}
    }
    else {
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

sub _validate_find_all_params {
    my $params = shift;
    return 1 unless (defined($params));
    return 0 unless (ref $params eq 'HASH');

    my %checker = (
	FindFreeVar => sub {
	    my $x = shift;
	    if (ref $x) {
		validate([$x], ["C"], "find_all: FindFreeVar must be a number or coderef");
	    }
	    else {
		validate([$x], ["I"], "search: FindFreeVar must be a number or coderef");
	    }
	},
    );

    my @keys = sort keys %$params;

    for my $k (@keys) {
	if (exists $checker{$k}) {
	    my $func = $checker{$k};
	    &$func($params->{$k});
	}
	else {
	    _report_error("find_all: Unknown Key $k in params");
	}
    }

    return 1;
}

sub find_all {
    my $self = shift;
    my $var_array = shift;
    my $found_func = shift;
    my $params = shift;

    validate([$var_array, $found_func, $params],
	     ["vA0", "C", \&_validate_find_all_params],
	     "find_all: usage: find_all([vars], &callback_func, {params})");

    my $array = [map { $$_ } @$var_array];

    my $find_free_var_id = 0;
    my $find_free_var_func = sub { die "find_all: Internal error"; };

    if ($params->{FindFreeVar}) {
	my $ffv = $params->{FindFreeVar};

	if (ref $ffv) {
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

    my $key = join(",", map { sprintf("%x", $$_) } @$var_array);
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

sub _safe_var {
    my ($vc) = @_;
    confess "undef cannot be used as variable" unless (defined($vc));

    return $vc if (ref $vc);
    return _const_var($vc);
}

sub get_version {
    my $self = shift;
    my ($err, $major) = constant('IZ_VERSION_MAJOR');

    if (defined($major)) {
	return sprintf("%d.%d.%d",
		       $major,
		       $self->IZ_VERSION_MINOR,
		       $self->IZ_VERSION_PATCH);
    }

    # not supported
    return;
}

sub get_value_selector {
    my $self = shift;
    my $id = shift;

    return Algorithm::CP::IZ::ValueSelector::IZ->new($self, $id);
}

sub create_value_selector_simple {
    my $self = shift;
    my $id = shift;

    return Algorithm::CP::IZ::ValueSelector::Simple->new($self, $id);
}

sub create_no_good_set {
    my $self = shift;
    my ($var_array, $prefilter, $max_no_good, $ext) = @_;
    $max_no_good ||= 0;
    validate([$var_array, $prefilter, $max_no_good], ["vA0", "C0", "I"],
	     "Usage: create_no_good_set([variables], prefilter, max_no_good, ext)");

    my $ngsObj = Algorithm::CP::IZ::NoGoodSet->new($var_array, $prefilter, $ext);
    my $ptr = Algorithm::CP::IZ::cs_createNoGoodSet($ngsObj->_parray->ptr,
						    scalar(@$var_array),
						    ($prefilter ? 1 : 0),
						    $max_no_good,
						    $ngsObj);
    $ngsObj->_init($ptr);
    return $ngsObj;
}

sub create_search_notify {
    my $iz = shift;
    my $obj = shift;
    return Algorithm::CP::IZ::SearchNotify->new($obj);
}

#####################################################
# Demon
#####################################################

sub event_all_known {
    my $self = shift;
    my ($var_array, $handler, $ext) = @_;

    validate([$var_array, $handler], ["vA0", "C"],
	     "Usage: event_all_known([variables], code_ref, ext)");

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

    validate([$var_array, $handler], ["vA0", "C"],
	     "Usage: event_known([variables], code_ref, ext)");

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

    validate([$var_array, $handler], ["vA0", "C"],
	     "Usage: event_new_min([variables], code_ref, ext)");

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

    validate([$var_array, $handler], ["vA0", "C"],
	     "Usage: event_new_max([variables], code_ref, ext)");

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

    validate([$var_array, $handler], ["vA0", "C"],
	     "Usage: event_eq([variables], code_ref, ext)");

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

    my $usage_msg = 'usage: Add(v1, v2, ...)';
    if (@params < 1) {
	_report_error($usage_msg);
    }
    for my $v (@params) {
	validate([$v], ["V"], $usage_msg);
    }

    if (@params == 1) {
	return $params[0] if (ref $params[0]);
	return $self->_const_var(int($params[0]));
    }

    my @v = map { ref $_ ? $_ : $self->_const_var(int($_)) } @params;

    my $ptr = _argv_func([map { $$_} @v], 10,
			 "Algorithm::CP::IZ::cs_Add",
			 "Algorithm::CP::IZ::cs_VAdd");

    my $ret = Algorithm::CP::IZ::Int->new($ptr);
    $self->_register_variable($ret);

    return $ret;
}

sub Mul {
    my $self = shift;
    my @params = @_;

    my $usage_msg = 'usage: Mul(v1, v2, ...)';
    if (@params < 1) {
	_report_error($usage_msg);
    }
    for my $v (@params) {
	validate([$v], ["V"], $usage_msg);
    }

    if (@params == 1) {
	return $params[0] if (ref $params[0]);
	return $self->_const_var(int($params[0]));
    }

    my @v = map { ref $_ ? $_ : $self->_const_var(int($_)) } @params;

    my $ptr = _argv_func([map { $$_ } @v], 10,
			 "Algorithm::CP::IZ::cs_Mul",
			 "Algorithm::CP::IZ::cs_VMul");

    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub Sub {
    my $self = shift;
    my @params = @_;

    my $usage_msg = 'usage: Sub(v1, v2, ...)';
    if (@params < 1) {
	_report_error($usage_msg);
    }
    for my $v (@params) {
	validate([$v], ["V"], $usage_msg);
    }

    if (@params == 1) {
	return $params[0] if (ref $params[0]);
	return $self->_const_var(int($params[0]));
    }

    my @v = map { ref $_ ? $_ : $self->_const_var(int($_)) } @params;

    my $ptr = _argv_func([map { $$_} @v], 10,
			 "Algorithm::CP::IZ::cs_Sub",
			 "Algorithm::CP::IZ::cs_VSub");

    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;

    $self->_register_variable($ret);

    return $ret;
}

sub Div {
    my $self = shift;
    my @params = @_;

    my $usage_msg = 'usage: Div(v1, v2)';
    if (@params != 2) {
	_report_error($usage_msg);
    }
    for my $v (@params) {
	validate([$v], ["V"], $usage_msg);
    }

    if (@params == 1) {
	return $params[0] if (ref $params[0]);
	return $self->_const_var(int($params[0]));
    }

    my @v = map { ref $_ ? $_ : $self->_const_var(int($_)) } @params;
    my $ptr = Algorithm::CP::IZ::cs_Div(map { $$_ } @v);

    # cannot divide number
    return undef if ($ptr == 0);

    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub ScalProd {
    my $self = shift;
    my $vars = shift;
    my $coeffs = shift;

    validate([$vars, $coeffs, 1], ["vA0", "iA0",
				   sub {
				       @$coeffs == @$vars
				   }],
	     "Usage: ScalProd([variables], [coeffs])");

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

    validate([$var_array], ["vA0"], "Usage: AllNeq([variables])");

    my $parray = $self->_create_registered_var_array($var_array);

    return Algorithm::CP::IZ::cs_AllNeq($$parray, scalar(@$var_array));
}

sub Sigma {
    my $self = shift;
    my $var_array = shift;;

    validate([$var_array], ["vA0"], "Usage: Sigma([variables])");

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

    validate([scalar @params, $params[0]],
	     [sub { shift == 1 }, "V"], "Usage: Abs(v)");

    my @v = map { ref $_ ? $_ : $self->_const_var(int($_)) } @params;
    my $ptr = Algorithm::CP::IZ::cs_Abs(map { $$_ } @v);
    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub Min {
    my $self = shift;
    my $var_array = shift;;

    validate([$var_array], ["vA1"],
	     "Usage: Min([variables])");

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

    validate([$var_array], ["vA1"],
	     "Usage: Max([variables])");

    @$var_array = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$var_array;

    my $parray = $self->_create_registered_var_array($var_array);

    my $ptr = Algorithm::CP::IZ::cs_Max($$parray, scalar(@$var_array));

    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub IfEq {
    my $self = shift;
    my ($vint1, $vint2, $val1, $val2) = @_;

    validate([scalar @_, $vint1, $vint2, $val1, $val2],
	     [sub { shift == 4 }, "V", "V", "I", "I"],
	     "Usage: IfEq(vint1, vint2, val1, val2)");

    return Algorithm::CP::IZ::cs_IfEq($$vint1, $$vint2,
				      int($val1), int($val2));
}

sub IfNeq {
    my $self = shift;
    my ($vint1, $vint2, $val1, $val2) = @_;

    validate([scalar @_, $vint1, $vint2, $val1, $val2],
	     [sub { shift == 4 }, "V", "V", "I", "I"],
	     "Usage: IfNeq(vint1, vint2, val1, val2)");

    return Algorithm::CP::IZ::cs_IfNeq($$vint1, $$vint2,
				       $val1, $val2);
}

sub OccurDomain {
    my $self = shift;
    my ($val, $var_array) = @_;

    validate([scalar @_, $val, $var_array],
	     [sub { shift == 2 }, "I", "vA0"],
	     "Usage: OccurDomain(val, [variables])");

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
    my ($vint, $val, $var_array) = @_;

    validate([scalar @_, $vint, $val, $var_array],
	     [sub { shift == 3 }, "V", "I", "vA0"],
	     "Usage: OccurConstraints(vint, val, [variables])");

    $vint = ref $vint ? $vint : $self->_const_var(int($vint));
    @$var_array = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$var_array;

    my $parray = $self->_create_registered_var_array($var_array);

    my $ret = Algorithm::CP::IZ::cs_OccurConstraints($$vint, int($val),
						     $$parray,
						     scalar(@$var_array));
    return $ret;
}

sub Index {
    my $self = shift;
    my ($var_array, $val) = @_;

    validate([scalar @_, $var_array, $val],
	     [sub { shift == 2 }, "vA0", "I"],
	     "Usage: Index([variables], val)");

    @$var_array = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$var_array;

    my $parray = $self->_create_registered_var_array($var_array);

    my $ptr = Algorithm::CP::IZ::cs_Index($$parray, scalar(@$var_array), $val);
    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub Element {
    my $self = shift;
    my ($index, $val_array) = @_;

    validate([scalar @_, $index, $val_array],
	     [sub { shift == 2 }, "V", "iA1"],
	     "Usage: Element(index_var, [values])");

    @$val_array = map { int($_) } @$val_array;
    $index = ref $index ? $index : $self->_const_var(int($index));

    my $parray = $self->_create_registered_int_array($val_array);

    my $ptr = Algorithm::CP::IZ::cs_Element($$index,
					    $$parray, scalar(@$val_array));
    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub VarElement {
    my $self = shift;
    my ($index, $var_array) = @_;

    validate([scalar @_, $index, $var_array],
	     [sub { shift == 2 }, "V", "vA1"],
	     "Usage: VarElement(index_var, [value_vars])");

    @$var_array = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$var_array;
    $index = ref $index ? $index : $self->_const_var(int($index));

    my $parray = $self->_create_registered_var_array($var_array);

    my $ptr = Algorithm::CP::IZ::cs_VarElement($$index,
					    $$parray, scalar(@$var_array));
    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub VarElementRange {
    my $self = shift;
    my ($index, $var_array) = @_;

    validate([scalar @_, $index, $var_array],
	     [sub { shift == 2 }, "V", "vA1"],
	     "Usage: VarElementRange(index_var, [value_vars])");

    @$var_array = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$var_array;
    $index = ref $index ? $index : $self->_const_var(int($index));

    my $parray = $self->_create_registered_var_array($var_array);

    my $ptr = Algorithm::CP::IZ::cs_VarElementRange($$index,
					    $$parray, scalar(@$var_array));
    my $ret = Algorithm::CP::IZ::Int->new($ptr);

    $self->_register_variable($ret);

    return $ret;
}

sub Cumulative {
    my $self = shift;
    my ($starts, $durations, $resources, $limit) = @_;

    validate([$starts, $durations, $resources, $limit, 1],
	     ["vA0", "vA0", "vA0", "V", sub {
		 @$starts == @$durations && @$durations == @$resources
	      }],
	     "Usage: Cumulative([starts], [durations], [resources], limit)");

    @$starts = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$starts;
    @$durations = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$durations;
    @$resources = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$resources;
    $limit = ref $limit ? $limit : $self->_const_var(int($limit));

    my $pstarts = $self->_create_registered_var_array($starts);
    my $pdurs = $self->_create_registered_var_array($durations);
    my $pres = $self->_create_registered_var_array($resources);

    my $ret = Algorithm::CP::IZ::cs_Cumulative($$pstarts, $$pdurs, $$pres,
					       scalar(@$starts), $$limit);
    return $ret;
}

sub Disjunctive {
    my $self = shift;
    my ($starts, $durations) = @_;

    validate([$starts, $durations, 1],
	     ["vA0", "vA0",  sub {
		 @$starts == @$durations
	      }],
	     "Usage: Disjunctive([starts], [durations])");

    @$starts = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$starts;
    @$durations = map { ref $_ ? $_ : $self->_const_var(int($_)) } @$durations;

    my $pstarts = $self->_create_registered_var_array($starts);
    my $pdurs = $self->_create_registered_var_array($durations);

    my $ret = Algorithm::CP::IZ::cs_Disjunctive($$pstarts, $$pdurs,
						scalar(@$starts));
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
	    my ($v1, $v2) = @_;
	    validate([scalar @_, $v1, $v2],
		     [sub { shift == 2 }, "V", "V"],
		     "Usage: $meth_name(v1, v2)");

	    my $ptr;

	    if (!ref $v1) {
		$v1 = $self->_const_var(int($v1));
	    }

	    if (ref $v2) {
		my $func = "Algorithm::CP::IZ::cs_Reif$n";

		no strict "refs";
		$ptr = &$func($$v1, $$v2);
	    }
	    else {
		my $func = "Algorithm::CP::IZ::cs_Reif$ucn";

		no strict "refs";
		$ptr = &$func($$v1, $v2);
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

accessors of variable attributes and some relationship constraints

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

Create an instance of Algorithm::CP::IZ::Int. Its domain contains INT.

=item create_int(VALUES [, NAME])

Create an instance of Algorithm::CP::IZ::Int. Its domain contains values
specified by VALUES(arrayref).

=item create_int(MIN, MAX, [, NAME])

Create an instance of Algorithm::CP::IZ::Int. Its domain is {MIN..MAX}.

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

(If ValueSelector is specified, this parameter is ignored.)

=item MaxFail

Upper limit of fail count while searching solutions.

=item ValueSelectors

Arrayref of Algorithm::CP::IZ::ValueSelector instances created via
get_value_selector or create_value_selector_simple method.

(If ValueSelector is specified, this parameter is ignored.)

=item MaxFailFunc

CodeRef of subroutine which returns maxfail for restart.

=item NoGoodSet

A Algorithm::CP::IZ::NoGoodSet instance which collects NoGoods.

=item Notify

Specify a notify object receives following notification by search function.

    search_start
    search_end
    before_value_selection
    after_value_selection
    enter
    leave
    found

if OBJECT is a object, method having notification name will be called.

if OBJECT is a hashref, notification name must be a key of hash and
value must be a coderef.

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

Returns fail count while searching solution.

=item get_nb_choice_points

Returns choice count while searching solution.

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

=item forget_save_context

Last save_context point is forgotten by calling this function.

=item forgest_save_context_until(LABEL)

save_context points until LABEL are forgotten by calling this function.

=item cancel_search

Cancel running search from other thread or signal handler.
Context will be restored using restore_context_until if needed.

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

VARIABLES is an arrayref contains instances of Algorithm::CP::IZ::Int.

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

VARIABLES is an arrayref contains instances of Algorithm::CP::IZ::Int.

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

VARIABLES is an arrayref contains instances of Algorithm::CP::IZ::Int.

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

VARIABLES is an arrayref contains instances of Algorithm::CP::IZ::Int.

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

VARIABLES is an arrayref contains instances Algorithm::CP::IZ::Int.

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

=item get_version

Returns version string like "3.5.0".
undef will be returned if getVersion() is not supported in iZ-C (old version).


=item get_value_selector(ID)

Get built-in value selector (instance of Algorithm::CP::IZ::ValueSelector) specifed by ID.
ID must be selected from following constants defined in package Algorithm::CP::IZ.

=over

=item CS_VALUE_SELECTOR_MIN_TO_MAX

=item CS_VALUE_SELECTOR_MAX_TO_MIN

=item CS_VALUE_SELECTOR_LOWER_AND_UPPER

=item CS_VALUE_SELECTOR_UPPER_AND_LOWER

=item CS_VALUE_SELECTOR_MEDIAN_AND_REST

=back

(These values are exported by Algorithm::CP::IZ and can be imported using tag 'value_selector')

Returned object will be used as a parameter ValueSelectors when calling "search" method.

  use Algorithm::CP::IZ qw(:value_selector);
  my $vs = $iz->get_value_selector(CS_VALUE_SELECTOR_MIN_TO_MAX);

  my $v1 = $iz->create_int(1, 9);
  my $v2 = $iz->create_int(1, 9);
  $iz->Add($v1, $v2)->Eq(12);
  my $rc = $iz->search([$v1, $v2], {
      ValueSelectors => [ $vs, $vs ],
  });


=item create_value_selector_simple(CLASS_NAME)

Create user defined value-seelctor defined by class named CLASS_NAME.
This class must have constructor named "new" and method namaed "next".

  use Algorithm::CP::IZ qw(:value_selector);
  
  package VSSample1;
  sub new {
    my $class = shift;
    my ($v, $index) = @_;

    my $self = {
      _pos => 0,
    };
    bless $self, $class;
  }

  sub next {
    my $self = shift;
    my ($v, $index) = @_;

    my $pos = $self->{_pos};
    my $domain = $v->domain;

    # return empty after enumerate all values
    return if ($pos >= @$domain);

    my @ret = (CS_VALUE_SELECTION_EQ, $domain->[$pos]);
    $self->{_pos} = ++$pos;

    # return pair of (CS_VALUE_SELECTION_*, value)
    return @ret;
  }

  my $v1 = $iz->create_int(1, 9);
  my $v2 = $iz->create_int(1, 9);
  $iz->Add($v1, $v2)->Eq(12);
  my $vs = $iz->create_value_selector_simple("VSSample1");
  my $rc = $iz->search([$v1, $v2], {
      ValueSelectors => [ $vs, $vs ],
  });

=item create_no_good_set(VARIABLES, PRE_FILTER, MAX_NO_GOOD, EXT)

Create an instance of Algorithm::CP::IZ::NoGoodSet. Returned object will be used as a
parameter NoGoodSet when calling "search" method.

=back


=head1 METHODS (Constraints)

=over 2

=item Add(VAR1, VAR2 [, VAR3....])

Create an instance of Algorithm::CP::IZ::Int constrainted to be:

  Created_instance  = VAR1 + VAR2 + ....

=item Mul(VAR1, VAR2 [, VAR3....])

Create an instance of Algorithm::CP::IZ::Int constrainted to be:

  Created_instance = VAR1 * VAR2 * ....

=item Sub(VAR1, VAR2)

Create an instance of Algorithm::CP::IZ::Int constrainted to be:

  Created_instance = VAR1 - VAR2

=item Div(VAR1, VAR2)

Create an instance of Algorithm::CP::IZ::Int constrainted to be:

  Created_instance = VAR1 / VAR2

=item ScalProd(VARIABLES, COEFFICIENTS)

Create an instance of Algorithm::CP::IZ::Int constrainted to be:

  Created_instance = COEFFICIENTS[0]*VARIABLES[0] + COEFFICIENTS[1]*VARIABLES[1] + ...

VARIABLES is an arrayref contains instances of Algorithm::CP::IZ::Int,
and COEFFICIENTS is an arreyref contains integer values.

=item AllNeq(VARIABLES)

Constraint all variables in VARIABLES to be different each other.

VARIABLES is an arrayref contains instances of Algorithm::CP::IZ::Int.

Returns 1 (success) or 0 (fail).

=item Sigma(VARIABLES)

Create an Algorithm::CP::IZ::Int instance constrainted to be:

  Created_instance = VARIABLES[0] + VARIABLES[1] + ...

VARIABLES is an arrayref contains instances of Algorithm::CP::IZ::Int.

=item Abs(VAR)

Create an instance of Algorithm::CP::IZ::Int constrainted to be:

  Created_instance = abs(VAR)

=item Min(VARIABLES)

Create an instance of Algorithm::CP::IZ::Int constrainted to be:

  Created_value = minimum value of (VARIABLES[0], VARIABLES[1], ...)

VARIABLES is an arrayref contains instances of Algorithm::CP::IZ::Int.

=item Max(VARIABLES)

Create an instance of Algorithm::CP::IZ::Int to be:

  Created_instance = maximum value of (VARIABLES[0], VARIABLES[1], ...)

VARIABLES is an arrayref contains instances of Algorithm::CP::IZ::Int.

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

Create instance of Algorithm::CP::IZ::Int represents count of VAL in VARIABLES.

VARIABLES is an arrayref contains instances of Algorithm::CP::IZ::Int.

=item OccurConstraints(VAR, VAL, VARIABLES)

Constraint VAR to represent count of VAL in VARIABLES.

VARIABLES is an arrayref contains instances of Algorithm::CP::IZ::Int.

Returns 1 (success) or 0 (fail).

=item Index(VARIABLES, VAL)

Create an instance of Algorithm::CP::IZ::Int represents position of VAL in VARIABLES.

  VAL = VARIABLES[CREATED]

VARIABLES is an arrayref contains instances Algorithm::CP::IZ::Int.

=item Element(VAR, VALUES)

Create an instance of Algorithm::CP::IZ::Int represents a value at VAR in VALUES. This relation is:

  Created_instance = VALUES[VAR]

VALUES is an arrayref contains integer values.

=item VarElement(VAR, VARIABLES)

Create an instance of Algorithm::CP::IZ::Int represents a value at VAR in VARIABLES. This relation is:

  Created_instance = VARIABLES[VAR]

VARIABLES is an arrayref contains instances of Algorithm::CP::IZ::Int.

=item VarElementRange(VAR, VARIABLES)

Create an instance of Algorithm::CP::IZ::Int represents a value at VAR in VARIABLES. This relation is:

  Created_instance = VARIABLES[VAR]

In contrast to VarElement, constraint propagation for variables in
VARIABLES will occur only when upper or lower bound is changed.

VARIABLES is an arrayref contains instances of Algorithm::CP::IZ::Int.

=item Cumulative(START_VARS, DURATION_VARS, RESOUCE_VARS, LIMIT_VAR)

Constraint variables as "Cumulative".

START_VARS, DURATION_VARS and RESOUCE_VARS are an arrayref contains instances of
Algorithm::CP::IZ::Int and LIMIT_VAR is an instance of Algorithm::CP::IZ::Int.

=item Disjunctive(START_VARS, DURATION_VARS)

Constraint variables as "Disjunctive".

START_VARS and DURATION_VARS are an arrayref contains instances of Algorithm::CP::IZ::Int.

=item ReifEq(VAR1, VAR2)

Create an instance of Algorithm::CP::IZ::Int represents state of VAR1 == VAR2.
Created variable will be instantiated to 1 when VAR1 == VAR2 otherwise to 0.

=item ReifNeq(VAR1, VAR2)

Create an instance of Algorithm::CP::IZ::Int represents state of VAR1 != VAR2.
Created variable will be instantiated to 1 when VAR1 != VAR2 otherwise to 0.

=item ReifLt(VAR1, VAR2)

Create an instance of Algorithm::CP::IZ::Int represents state of VAR1 < VAR2.
Created variable will be instantiated to 1 when VAR1 < VAR2 otherwise to 0.

=item ReifLe(VAR1, VAR2)

Create an instance of Algorithm::CP::IZ::Int represents state of VAR1 <= VAR2.
Created variable will be instantiated to 1 when VAR1 <= VAR2 otherwise to 0.

=item ReifGt(VAR1, VAR2)

Create an instance of Algorithm::CP::IZ::Int represents state of VAR1 > VAR2.
Created variable will be instantiated to 1 when VAR1 > VAR2 otherwise to 0.

=item ReifGe(VAR1, VAR2)

Create an instance of Algorithm::CP::IZ::Int represents state of VAR1 >= VAR2.
Created variable will be instantiated to 1 when VAR1 >= VAR2 otherwise to 0.

=back

=head1 SEE ALSO

L<Algorithm::CP::IZ::Int>
L<Algorithm::CP::IZ::FindFreeVar>

L<http://www.constraint.org/en/izc_download.html>
L<https://github.com/tofjw/Algorithm-CP-IZ/wiki>

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

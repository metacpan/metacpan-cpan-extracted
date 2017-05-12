package Class::ParmList;

use strict;
require Exporter;

BEGIN {
	$Class::ParmList::VERSION     = '1.05';
	@Class::ParmList::ISA         = qw (Exporter);
	@Class::ParmList::EXPORT      = ();
	@Class::ParmList::EXPORT_OK   = qw (simple_parms parse_parms);
	%Class::ParmList::EXPORT_TAGS = ();
}

#####################################

my $error = '';

#####################################

sub parse_parms {
	my $package = __PACKAGE__;
	my $parms = new($package,@_);
	return $parms;
}

#####################################

sub new {
	my $proto   = shift;
	my $package = __PACKAGE__;
	my $class;
    if (ref($proto)) {
        $class = ref($proto);
    } elsif ($proto) {
        $class = $proto;
    } else {
        $class = $package;
    }
	my $self    = bless {},$class;

	# Clear any outstanding errors
	$error = '';

	unless (-1 != $#_) { # It's legal to pass no parms.
		$self->{-name_list} = [];
		$self->{-parms}     = {};
		return $self;
	}

	my $raw_parm_list = {};
	my $reftype = ref $_[0];
	if ($reftype eq 'HASH') {
		($raw_parm_list) = @_;
	} else {
		%$raw_parm_list = @_;
	}

	# Transform to lowercase keys on our own parameters
	my $parms =  { map { (lc($_),$raw_parm_list->{$_}) } keys %$raw_parm_list };
	
	# Check for bad parms
	my @parm_keys     = keys %$parms;
	my @bad_parm_keys = grep(!/^-(parms|legal|defaults|required)$/,@parm_keys);
	unless (-1 == $#bad_parm_keys) {
		$error = "Invalid parameters (" . join(',',@bad_parm_keys) . ") passed to Class::ParmList->new\n";
		return;
	}


	# Legal Parameter names
	my ($check_legal, $legal_names);
	if (defined $parms->{-legal}) {
		%$legal_names = map { (lc($_),1) } @{$parms->{-legal}};
		$check_legal = 1;
	} else {
		$legal_names = {};
		$check_legal = 0;
	}

	# Required Parameter names
	my ($check_required, $required_names);
	if ($parms->{-required}) {
		foreach my $r_key (@{$parms->{-required}}) {
			my $lk = lc ($r_key);
			$required_names->{$lk} = 1;
			$legal_names->{$lk}    = 1;
		}
		$check_required = 1;
	} else {
		$required_names = {};
		$check_required = 0;
	}

	# Set defaults if needed
	my $parm_list;
	my $defaults = $parms->{-defaults};
	if (defined $defaults) {
		while (my ($d_key, $d_value) = each %$defaults) {
			my $lk              = lc ($d_key);
			$legal_names->{$lk} = 1;
			$parm_list->{$lk}   = $d_value;
		}
	} else {
		$parm_list = {};
	}

	# The actual list of parms
	my $base_parm_list = $parms->{-parms};

	# Unwrap references to ARRAY referenced parms
	while (defined($base_parm_list) && (ref($base_parm_list) eq 'ARRAY')) {
		my @data = @$base_parm_list;
		if ($#data == 0) {
			$base_parm_list = $data[0];
		} else {
			$base_parm_list = { @data };
		}
	}

	if (defined ($base_parm_list)) {
		while (my ($b_key, $b_value) = each %$base_parm_list) {
			$parm_list->{lc($b_key)} = $b_value;
		}
	}

	# Check for Required parameters
	if ($check_required) {
		foreach my $name (keys %$required_names) {
			unless (exists $parm_list->{$name}) {
				$error .= "Required parameter '$name' missing\n";
			}
		}
	}

	# Check for illegal parameters
	my $final_parm_names = [keys %$parm_list];
	if ($check_legal) {
		foreach my $name (@$final_parm_names) {
			unless (exists $legal_names->{$name}) {
				$error .= "Parameter '$name' not legal here.\n";
			}
		}
		$self->{-legal} = $legal_names;
	}

	return unless ($error eq '');

	# Save the parms for accessing
	$self->{-name_list} = $final_parm_names;
	$self->{-parms}     = $parm_list;

	return $self;	
}

#####################################

sub get {
	my $self = shift;

	my @parmnames = @_;
	if ($#parmnames == -1) {
        require Carp;
		Carp::croak(__PACKAGE__ . '::get() called without any parameters');
	}
	my (@results) = ();
	my $parmname;
	foreach $parmname (@parmnames) {
		my $keyname = lc ($parmname);
        require Carp;
		Carp::croak (__PACKAGE__ . "::get() called with an illegal named parameter: '$keyname'") if (exists ($self->{-legal}) and not exists ($self->{-legal}->{$keyname}));	
		push (@results,$self->{-parms}->{$keyname});
	}
	if (wantarray) {
		return @results;
	} else {
		return $results[$#results];
	}
}

#####################################

sub exists {
	my $self = shift;
	
	my ($name) = @_;

	$name = lc ($name);
	return CORE::exists ($self->{-parms}->{$name});
}

#####################################

sub list_parms {
	my $self = shift;

	my (@names) = @{$self->{-name_list}};

	return @names;
}

#####################################

sub all_parms {
	my $self = shift;

	my @parm_list = $self->list_parms;
	my $all_p = {};
	foreach my $parm (@parm_list) {
		$all_p->{$parm} = $self->get($parm);
	}
	return $all_p;
}

#####################################

sub error { return $error; }

#####################################

sub simple_parms {
	local $SIG{__DIE__} = ''; # Because SOME PEOPLE cause trouble
	my $parm_list = shift;
	unless (ref($parm_list) eq 'ARRAY') {
        require Carp;
		Carp::confess ('[' . localtime(time) . '] [error] ' . __PACKAGE__ . "::simple_parms() - The first parameter to 'simple_parms()' must be an anonymous list of parameter names.");
	}

	if (($#_ > 0) && (($#_ + 1) % 2)) {
        require Carp;
		Carp::confess ('[' . localtime(time) . '] [error] ' . __PACKAGE__ . "::simple_parms() - Odd number of parameter array elements");
	}

	# Read any other passed parms
	my $parm_ref;
	if ($#_ == 0) {
		$parm_ref  = shift;

	} elsif ($#_ > 0) {
		%$parm_ref = @_;
	} else {
		$parm_ref = {};
	}

	unless (ref ($parm_ref) eq 'HASH') {
		require Carp;
		Carp::confess ('[' . localtime(time) . '] [error] ' . __PACKAGE__ . "::simple_parms() - A bad parameter list was passed (not either an anon hash or an array)");
	}

	my @parm_keys = keys %$parm_ref;
	if ($#parm_keys != $#$parm_list) {
		require Carp;
		Carp::confess ('[' . localtime(time) . '] [error] ' .  __PACKAGE__ . ":simple_parms() - An incorrect number of parameters were passed");
	}
	if ($#parm_keys == -1) {
		require Carp;
		Carp::croak ('[' . localtime(time) . '] [error] ' . __PACKAGE__ . "::simple_parms() - At least one parameter is required to be requested");
	}

	my @parsed_parms   = ();
	my $errors         = '';
	foreach my $parm_name (@$parm_list) {
		unless (exists $parm_ref->{$parm_name}) {
			$errors .= "Parameter $parm_name was not found in passed parameter data.\n";
			next;
		}
		push (@parsed_parms,$parm_ref->{$parm_name});
	}
	if ($errors ne '') {
		require Carp;
		Carp::confess ('[' . localtime(time) . '] [error] ' . __PACKAGE__ . "::simple_parms() - $errors");
	}
	if (wantarray) {
		return @parsed_parms;
	}
	unless (0 == $#parsed_parms) {
		require Carp;
		Carp::croak ('[' . localtime(time) . '] [error] ' . __PACKAGE__ . "::simple_parms() - Requested multiple values in a 'SCALAR' context.");
	}
	return $parsed_parms[0];
}

#####################################

# Keeps 'AUTOLOAD' from sucking cycles during object destruction
# Don't laugh. It really happens.
sub DESTROY {}

#####################################

1;

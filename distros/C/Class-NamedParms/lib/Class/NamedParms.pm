package Class::NamedParms;

use strict;
use warnings;

BEGIN {
    $Class::NamedParms::VERSION = '1.08';
}

######################################################################

sub new {
    my $proto = shift;
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
    
    my $vars              = {};
    $self->{$package}     = $vars;
	$vars->{-legal_parms} = {};
	$vars->{-parm_values} = {};

    if ($#_ != -1) {
        $self->declare(@_);
    }

    $self;
}

######################################################################

sub list_declared_parms {
	my $self = shift;
    my $package = __PACKAGE__;
    my $vars    = $self->{$package} ? $self->{$package} : $self;

	my @parmnames = keys %{$vars->{-legal_parms}};
	return @parmnames;
}

######################################################################

sub list_initialized_parms {
	my $self = shift;

    my $package = __PACKAGE__;
    my $vars    = $self->{$package} ? $self->{$package} : $self;

	my @parmnames = keys %{$vars->{-parm_values}};
	return @parmnames;
}

######################################################################

sub declare {
	my $self = shift;

	my @parmnames  = @_;

    my $package = __PACKAGE__;
    my $vars    = $self->{$package} ? $self->{$package} : $self;

	foreach my $parmname (@parmnames) {
		$parmname = lc ($parmname);
		$vars->{-legal_parms}->{$parmname} = 1;
	}
    return;
}

######################################################################

sub undeclare {
	my $self = shift;

    my $package = __PACKAGE__;
    my $vars    = $self->{$package} ? $self->{$package} : $self;

	my @parmnames  = @_;

	foreach my $parmname (@parmnames) {
		$parmname = lc ($parmname);
		unless (CORE::exists $vars->{-legal_parms}->{$parmname}) {
			require Carp;
			Carp::confess (__PACKAGE__ . "::undeclare() - Attempted to undeclare a parameter name ($parmname) that was never declared\n");
        }
		delete $vars->{-legal_parms}->{$parmname};
		delete $vars->{-parm_values}->{$parmname};
	}
}

######################################################################

sub exists {
	my $self = shift;

    my $package = __PACKAGE__;
    my $vars    = $self->{$package} ? $self->{$package} : $self;

	my ($parmname) = @_;
	$parmname      = lc $parmname;
	return CORE::exists $vars->{-parm_values}->{$parmname};
}

######################################################################

sub set {
	my $self = shift;

	my $parm_ref;
	if ($#_ == 0) {
		$parm_ref = shift;
	} elsif ($#_ > 0) {
		$parm_ref =  { @_ };
	} else {
        $parm_ref = {};
    }
	
    my $package = __PACKAGE__;
    my $vars    = $self->{$package} ? $self->{$package} : $self;

	my @parmnames = keys %$parm_ref;
	foreach my $parmname (@parmnames) {
		my $keyname = lc ($parmname);
		my $value   = $parm_ref->{$parmname};
        unless (CORE::exists $vars->{-legal_parms}->{$keyname}) {
		    require Carp;
		    Carp::confess (__PACKAGE__ . "::set() - Attempted to set an undeclared named parameter: '$keyname'\n");
        }
		$vars->{-parm_values}->{$keyname} = $value;
	}
    return;
}

######################################################################

sub clear {
	my $self = shift;

	my @parmnames = @_;

    my $package = __PACKAGE__;
    my $vars    = $self->{$package} ? $self->{$package} : $self;

	foreach my $parmname (@parmnames) {
		my $keyname = lc ($parmname);
        unless (CORE::exists $vars->{-legal_parms}->{$keyname}) {
		    require Carp;
		    Carp::confess (__PACKAGE__ . "::clear() - Attempted to clear an undeclared named parameter: '$keyname'\n");
        }
		$vars->{-parm_values}->{$keyname} = undef;
	}
    return;
}

######################################################################

sub get {
	my $self = shift;

	if ($#_ == -1) {
        require Carp;
        Carp::confess(__PACKAGE__ . "::get() - Called without any parameters\n");
    }

    my $package = __PACKAGE__;
    my $vars    = $self->{$package} ? $self->{$package} : $self;

	my @results = ();
	foreach (@_) {
		my $keyname = lc ($_);
		unless (CORE::exists $vars->{-parm_values}->{$keyname}) {
			require Carp;
			Carp::confess (__PACKAGE__ . "::get() - Attempted to retrieve an undeclared or unitialized named parameter: '$keyname'\n");
		}
		push (@results,$vars->{-parm_values}->{$keyname});
	}
	if (wantarray) {
		return @results;
	}
    return $results[$#results];
}

################################################################

sub all_parms {
	my $self = shift;

	my @parm_list = $self->list_initialized_parms;
	my $all_p = {};
	foreach my $parm (@parm_list) {
		$all_p->{$parm} = $self->get($parm);
	}
	return $all_p;
}

#################################################################

1;

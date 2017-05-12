package Apache::Dispatch::Util;

use strict;
use warnings;

our $VERSION = '0.15';

=head1 NAME

  Apache::Dispatch::Util - methods for Apache::Dispatch and Apache2::Dispatch

=head1 DESCRIPTION

This package provides methods common to Apache::Dispatch and Apache2::Dispatch.

=head1 VARIABLES

=over 4

=item B<@_directives>

Private lexical array which contains the directives for configuration.  Used
by the directives() method.

=back

=cut

my @directives = (

    #------------------------------------------------------------------
    # DispatchPrefix defines the base class for a given <Location>
    #------------------------------------------------------------------
    {
     name         => 'DispatchPrefix',
     errmsg       => 'a class to be used as the base class',
     args_how     => 'TAKE1',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchExtras defines the extra dispatch methods to enable
    #------------------------------------------------------------------
    {
     name         => 'DispatchExtras',
     errmsg       => 'choose any of: Pre, Post, or Error',
     args_how     => 'ITERATE',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchStat enables module testing and subsequent reloading
    #------------------------------------------------------------------
    {
     name         => 'DispatchStat',
     errmsg       => 'choose one of On, Off, or ISA',
     args_how     => 'TAKE1',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchAUTOLOAD defines AutoLoader behavior
    #------------------------------------------------------------------
    {
     name         => 'DispatchAUTOLOAD',
     errmsg       => 'choose one of On or Off',
     args_how     => 'FLAG',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchDebug defines debugging verbosity
    #------------------------------------------------------------------
    {
     name         => 'DispatchDebug',
     errmsg       => 'numeric verbosity level',
     args_how     => 'TAKE1',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchISA is a list of modules your module should inherit from
    #------------------------------------------------------------------
    {
     name         => 'DispatchISA',
     errmsg       => 'a list of parent modules',
     args_how     => 'ITERATE',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchLocation allows you to redefine the <Location>
    #------------------------------------------------------------------
    {
     name         => 'DispatchLocation',
     errmsg       => 'a location to replace the current <Location>',
     args_how     => 'TAKE1',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchRequire require()s the class
    #------------------------------------------------------------------
    {
     name         => 'DispatchRequire',
     errmsg       => 'choose one of On or Off',
     args_how     => 'FLAG',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchFilter makes the dispatched handler Apache::Filter aware
    #------------------------------------------------------------------
    {
     name         => 'DispatchFilter',
     errmsg       => 'choose one of On or Off',
     args_how     => 'FLAG',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchUppercase converts the first char of a class to uppercase
    #------------------------------------------------------------------
    {
     name         => 'DispatchUpperCase',
     errmsg       => 'choose one of On or Off',
     args_how     => 'FLAG',
     req_override => 'OR_ALL',
    },
);

# create global hash to hold the modification times of the modules
my %stat = ();

=head1 METHODS

=over 4

=item C<directives>

Provides the configuration directives in an array or array reference

  $directives = Apache::Dispatch::Util->directives;
  @directives = Apache::Dispatch::Util->directives;

=over 4

=item class: C<Apache::Dispatch::Util> ( class )

The calling class

=item ret: C<$directives|@directives> ( ARRAY | ARRAY ref )

Returns the directives in an array or array reference depending on the context
in which it is called.

=back

=cut

sub directives {
    my $class = shift;
    return wantarray ? @directives : \@directives;
}

=item bogus_uri

=cut

sub bogus_uri {
	my ($class, $uri) = @_;
    if ($uri =~ m![^\w/-]!) {
		return 1;
	}
	return;
}
#*********************************************************************
# the below methods are not part of the external API
#*********************************************************************

sub _stat {
    
	#---------------------------------------------------------------------
    # stat and reload the module if it has changed...
    # this method is for internal use only
    #---------------------------------------------------------------------
	
	my $pkg = shift;
    my ($class, $log) = @_;

    (my $module = $class) =~ s!::!/!g;

    $module .= ".pm";

    $stat{$module} = $^T unless $stat{$module};

    if ($INC{$module}) {
        $log->debug("\tchecking $module for reload in pid $$...");

        my $mtime = (stat $INC{$module})[9];

        unless (defined $mtime && $mtime) {
            $log->error("Apache::Dispatch cannot find $module!");
            return 1;
        }

        if ($mtime > $stat{$module}) {

            # turn off warnings for this bit...
            local $^W;

            delete $INC{$module};
            eval { require $module };

            if ($@) {
                $log->error("Apache::Dispatch: $module failed reload! $@");
                return;
            }
            elsif (!$@) {
                $log->debug("\t$module reloaded");
            }
            $stat{$module} = $mtime;
        }
        else {
            $log->debug("\t$module not modified");
        }
    }
    else {
        $log->error("Apache::Dispatch: $module not in \%INC!");
    }

    return 1;
}

sub _recurse_stat {

    #---------------------------------------------------------------------
    # recurse through all the parent classes of the current class
    # and call _stat on each
    # this method is for internal use only
    #---------------------------------------------------------------------

    my ($class, $log) = @_;

    my $rc = _stat($class, $log);

    return unless $rc;

    # turn off strict here so we can get at the class @ISA
    no strict 'refs';

    foreach my $package (@{"${class}::ISA"}) {
        $rc = _recurse_stat($package, $log);
        last unless $rc;
    }

    return $rc;
}

sub _set_ISA {

    #---------------------------------------------------------------------
    # set the ISA array for the class
    # this method is for internal use only
    #---------------------------------------------------------------------
    my ($pkg, $class, $log, @parents) = @_;

    # turn off strict here so we can get at the class @ISA
    no strict 'refs';

    $log->debug("\t\@ISA for $class currently contains ",
                (join ", ", @{"${class}::ISA"}));
    $log->debug("\tabout to merge ", (join ", ", @parents));
    
	# only add classes to @ISA if they are not there already
    my %seen;

    @{"${class}::ISA"} = grep !$seen{$_}++, (@{"${class}::ISA"}, @parents);
	
	$log->debug("\t\@ISA for $class now contains ",
                (join ", ", @{"${class}::ISA"}));

    return 1;
}

#---------------------------------------------------------------------
# Apache configuration methods
#---------------------------------------------------------------------

sub _new {
    return bless {}, shift;
}

sub DIR_CREATE {
    my $class = shift;
    my $self  = $class->_new;

    $self->{_stat}     = "Off";    # no reloading by default
    $self->{_autoload} = 0;        # no autloading by default
    $self->{_require}  = 0;        # no require()ing by default

    #  warn "inside DIR_CREATE";
    return $self;
}

sub DIR_MERGE {
    my ($parent, $current) = @_;
    my %new = (%$parent, %$current);

    #  warn "inside DIR_MERGE";
    return bless \%new, ref($parent);
}

sub _translate_uri {

    #---------------------------------------------------------------------
    # take the uri and return a class and method
    # this method is for internal use only
    #---------------------------------------------------------------------

	my $pkg = shift;
    my ($r, $prefix, $newloc, $log, $debug) = @_;

    my $uri = $r->uri;
    
	my $location;

    # change all the / to ::
    (my $class_and_method = $r->uri) =~ s!/!::!g;
    
	if ($newloc) {
        $log->debug("\tmodifying location from ", $r->location, " to $newloc")
            if $debug > 1;
        ($location = $newloc) =~ s!/!::!g;
    }
    else {
        ($location = $r->location) =~ s!/!::!g;
    }

    # strip off the leading and trailing :: if any
    $class_and_method =~ s/^::|::$//g;
    $location         =~ s/^::|::$//g;

    # substitute the prefix for the location
    # <Location /> is a special case that we can deal with
    # (but not advertise :)
    my $times;

    if ($location) {
        $times = $class_and_method =~ s/^\Q$location/$prefix/e;
    }
    else {

        # <Location />
        $times = 1;
        $class_and_method = $prefix;
    }

    unless ($times) {
        $log->debug("\tLocation substitution failed - uri not translated")
          if $debug > 1;

        return (undef, undef);
    }

    my ($class, $method);

    if ($prefix eq $class_and_method) {
        $method = "dispatch_index";
        $class  = $prefix;
    }
    else {
        ($class, $method) = $class_and_method =~ m/(.*)::(.*)/;
        $method = "dispatch_$method";
    }

    return ($class, $method);
}

sub _check_dispatch {

    #---------------------------------------------------------------------
    # see if class->method() is a valid call
    # this method is for internal use only
    #---------------------------------------------------------------------
	
	my $pkg = shift;
	
	my ($object, $method, $autoload, $log, $debug) = @_;

    my $class = ref($object);

    my $coderef;

    $log->debug("\tchecking the validity of $class->$method...")
      if $debug > 1;

    if ($autoload) {
		$coderef = $object->can($method) || $object->can("AUTOLOAD");
    }
    else {
        $coderef = $object->can($method);
    }

    if ($coderef && $debug > 1) {
        $log->debug("\t$class->$method is a valid method call");
    }
    elsif ($debug > 1) {
        $log->debug("\t$class->$method is not a valid method call");
    }

    return $coderef;
}

sub DispatchLocation {
    my ($cfg, $parms, $arg) = @_;

    $cfg->{_newloc} = $arg;
}

sub DispatchPrefix {
    my ($cfg, $parms, $arg) = @_;

    $cfg->{_prefix} = $arg;
}

sub DispatchExtras {
    my ($cfg, $parms, $arg) = @_;

    if ($arg =~ m/^(Pre|Post|Error)$/i) {
        push @{$cfg->{_extras}}, uc($arg)
          unless grep /$arg/i, @{$cfg->{_extras}};
    }
    else {
        die "Invalid DispatchExtra $arg!";
    }
}

sub DispatchISA {
    my ($cfg, $parms, $arg) = @_;

    push @{$cfg->{_isa}}, $arg
      unless grep /$arg/, @{$cfg->{_isa}};
}

sub DispatchStat {
    my ($cfg, $parms, $arg) = @_;

    if ($arg =~ m/^(On|Off|ISA)$/i) {
        $cfg->{_stat} = uc($arg);
    }
    else {
        die "Invalid DispatchStat $arg!";
    }
}

sub DispatchRequire {
    my ($cfg, $parms, $arg) = @_;
    
	$cfg->{_require} = $arg;
}

sub DispatchFilter {
    my ($cfg, $parms, $arg) = @_;

    $cfg->{_filter} = $arg;
}

sub DispatchAUTOLOAD {
    my ($cfg, $parms, $arg) = @_;

    $cfg->{_autoload} = $arg;
}

sub DispatchUpperCase {
    my ($cfg, $parms, $arg) = @_;

    $cfg->{_uppercase} = $arg;
}

sub DispatchDebug {
    my ($cfg, $parms, $arg) = @_;

    $cfg->{_debug} = $arg;
}

=pod

=back

=cut

1;

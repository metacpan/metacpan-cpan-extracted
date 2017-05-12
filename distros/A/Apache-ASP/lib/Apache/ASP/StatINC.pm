
package Apache::ASP;

# quickly decomped out of Apache::ASP just to optionally load
# it at runtime for CGI programs ( which shouldn't need it anyway )
# will still precompile this for mod_perl

use strict;
use vars qw( $StatINCReady $StatINCInit %Stat $StatStartTime );

$StatStartTime = time();

# Apache::StatINC didn't quite work right, so writing own
sub StatINCRun {
    my $self = shift;
    my $stats = 0;

    # include necessary libs, without nice error message...
    # we only do this once if successful, to speed up code a bit,
    # and load success bool into global. otherwise keep trying
    # to generate consistent error messages
    unless($StatINCReady) {
	my $ready = 1;
	for('Devel::Symdump') {
	    eval "use $_";
	    if($@) {
		$ready = 0;
		$self->Error("You need $_ to use StatINC: $@ ... ".
			     "Please download it from your nearest CPAN");
	    }
	}
	$StatINCReady = $ready;
    }
    return unless $StatINCReady;
    
    # make sure that we have pre-registered all the modules before
    # this only happens on the first request of a new process
    unless($StatINCInit) {
	$StatINCInit = 1;
	$self->Debug("statinc init");
	$self->StatRegisterAll();	
    }

    while(my($key,$file) = each %INC) {
	if($self->{stat_inc_match} && defined $Stat{$file}) {
	    # we skip only if we have already registered this file
	    # we need to register the codes so we don't undef imported symbols
	    next unless ($key =~ /$self->{stat_inc_match}/);
	}

	next unless (-e $file); # sometimes there is a bad file in the %INC
	my $mtime = (stat($file))[9];

	# its ok if this block is CPU intensive, since it should only happen
	# when modules get changed, and that should be infrequent on a production site
	if(! defined $Stat{$file}) {
	    $self->{dbg} && $self->Debug("loading symbols first time", { $key => $file});
	    $self->StatRegister($key, $file, $mtime);	    
	} elsif($mtime > $Stat{$file}) {
	    $self->{dbg} && $self->Debug("reloading", {$key => $file});
	    $stats++; # count files we have reloaded
	    $self->StatRegisterAll();
	    
	    # we need to explicitly re-register a namespace that 
	    # we are about to undef, in case any imports happened there
	    # since last we checked, so we don't delete duplicate symbols
	    $self->StatRegister($key, $file, $mtime);

	    my $class = &File2Class($key);
	    my $sym = Devel::Symdump->new($class);

	    my $function;
	    my $is_global_package = $class eq $self->{GlobalASA}{'package'} ? 1 : 0;
	    my @global_events_list = $self->{GlobalASA}->EventsList;

	    for $function ($sym->functions()) {
		my $code = \&{$function};

		if($function =~ /::O_[^:]+$/) {
		    $self->Debug("skipping undef of troublesome $function");
		    next;
		}

		if($Apache::ASP::Codes{$code}{count} > 1) {
		    $self->Debug("skipping undef of multiply defined $function: $code");
		    next;
		}

		if($is_global_package) {
		    # skip undef if id is an include or script 
		    if($function =~ /::__ASP_/) {
			$self->Debug("skipping undef compiled ASP sub $function");
			next;
		    }

		    if(grep($function eq $class."::".$_, @global_events_list)) {
			$self->Debug("skipping undef global event $function");
			next;
		    }

		    if($Apache::ASP::ScriptSubs{$function}) {
			$self->Debug("skipping undef script subroutine $function");
			next;
		    }

		}

		$self->{dbg} && $self->Debug("undef code $function: $code");

		undef(&$code); # method for perl 5.6.1
		delete $Apache::ASP::Codes{$code};
		undef($code);  # older perls
	    }

	    # extract the lib, just incase our @INC went away
	    (my $lib = $file) =~ s/$key$//g;
	    push(@INC, $lib);

	    # don't use "use", since we don't want symbols imported into ASP
	    delete $INC{$key};
	    $self->Debug("loading $key with require");
	    eval { require($key); }; 
	    if($@) {
		$INC{$key} = $file; # make sure we keep trying to reload it
		$self->Error("can't require/reload $key: $@");
		next;
	    }

	    # if this was the same module as the global.asa package,
	    # then we need to reload the global.asa, since we just 
	    # undef'd the subs
	    if($is_global_package) {
		# we just undef'd the global.asa routines, so these too 
		# must be recompiled
		$self->Debug("reloading global.asa file after clearing package namespace");
		delete $Apache::ASP::Compiled{$self->{GlobalASA}{'id'}};
		&Apache::ASP::GlobalASA::new($self);
	    }

	    $self->StatRegister($key, $file, $mtime);

	    # we want to register INC now in case any new libs were
	    # added when this module was reloaded
	    $self->StatRegisterAll();
	}
    }

    $stats;
}

sub StatRegister {
    my($self, $key, $file, $mtime) = @_;

    # keep track of times
    $Stat{$file} = $mtime; 
    
    # keep track of codes, don't undef on codes
    # with multiple refs, since these are exported
    my $class = &File2Class($key);

    # we skip Apache stuff as on some platforms (RedHat 6.0)
    # Apache::OK seems to error when getting its code ref
    # these shouldn't be reloaded anyway, as they are internal to 
    # modperl and should require a full server restart
    if($class eq 'Apache' or $class eq 'Apache::Constants') {
	$self->Debug("skipping StatINC register of $class");
	return;
    }

    $self->{dbg} && $self->Debug("stat register of $key $file $class");
    if($class eq 'CGI') {
	# must compensate for its autoloading behavior, and 
	# precompile all the routines, so we can register them
	# and not delete them later
	CGI->compile(':all');
    }

    my $sym = Devel::Symdump->new($class);
    my $function;
    for $function ($sym->functions()) {
	my $code = \&{$function};
	unless($code =~ /CODE/) {
	    $self->Debug("no code ref for function $function");
	    next;
	}

	# don't update if we already have this code defined for this func.
	next if $Apache::ASP::Codes{$code}{funcs}{$function}; 

#	$self->Debug("code $code for $function");
	$Apache::ASP::Codes{$code}{count}++;
	$Apache::ASP::Codes{$code}{libs}{$key}++;
	$Apache::ASP::Codes{$code}{funcs}{$function}++;
    }

    1;
}

sub StatRegisterAll {
    my $self = shift;
    # we make sure that all modules that are loaded are registered
    # so we don't undef exported subroutines, when we reload 
    my($key, $file);
    while(($key,$file) = each %INC) {
	next if defined $Stat{$file};
	next unless -e $file;
	# we use the module load time to init, in case it was
	# pulled in with PerlModule, and has changed since,
	# so it won't break with a graceful restart
	$self->StatRegister($key, $file, $StatStartTime - 1);
    }

    1;
}

sub File2Class {
    my $file = shift;
    return $file unless $file =~ s,\.pm$,,;
    $file =~ s,/,::,g;
    $file;
}

1;

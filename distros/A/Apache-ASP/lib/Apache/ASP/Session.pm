
package Apache::ASP::Session;

use Apache::ASP::State;

use strict;
no strict qw(refs);
use vars qw(@ISA);
@ISA = qw(Apache::ASP::Collection);

# allow to pass in id so we can cleanup other sessions with 
# the session manager
sub new {
    my($asp, $id, $perms, $no_error) = @_;
    my($state, %self, $started);
    my $internal = $asp->{Internal};

    # if we are passing in the id, then we are doing a 
    # quick session lookup and can bypass the normal checks
    # this is useful for the session manager and such
    if($id) {
	$internal->LOCK;
	$state = Apache::ASP::State::new($asp, $id, undef, $perms, $no_error);
	#	$state->Set() || $asp->Error("session state get failed");
	if($state) {
	    tie %self, 'Apache::ASP::Session', 
	    {
	     state=>$state, 
	     asp=>$asp, 
	     id=>$id,
	    };
	    $internal->UNLOCK;
	    return bless \%self;
	} else {
	    $internal->UNLOCK;
	    return;
	}
    }

    # lock down so no conflict with garbage collection
    $internal->LOCK();
    if($id = $asp->SessionId()) {
	my $idata = $internal->{$id};
	#	$asp->Debug("internal data for session $id", $idata);
	if($idata && ! $idata->{'end'} ) {
	    # user is authentic, since the id is in our internal hash
	    if($idata->{timeout} > time()) {
		# refresh and unlock as early as possible to not conflict 
		# with garbage collection
		$asp->RefreshSessionId($id);
		$state = Apache::ASP::State::new($asp, $id);
		$internal->UNLOCK();

		# session not expired
		$asp->{dbg} && 
		  $asp->Debug("session not expired",{'time'=>time(), timeout=>$idata->{timeout}});

		if($asp->{paranoid_session}) {
		    local $^W = 0;
		    # by testing for whether UA was set to begin with, we 
		    # allow a smooth upgrade to ParanoidSessions
		    $state->WriteLock() if $asp->{session_serialize};
		    my $state_ua = $state->FETCH('_UA');
		    if(defined($state_ua) and $state_ua ne $asp->{'ua'}) {
			$asp->Log("[security] hacker guessed id $id; ".
				  "user-agent ($asp->{'ua'}) does not match ($state_ua); ".
				  "destroying session & establishing new session id"
				  );
			$state->Init();
			undef $state;
			goto NEW_SESSION_ID;		    
		    }
		}

		$started = 0;
	    } else {
		# expired, get & reset
		$internal->{$id} = { %{$internal->{$id}}, 'end' => 1 };
		$internal->UNLOCK();	      

		# remove this section, allow lazy cleanup, this caused a bug 
		# in which sessions cleared in this way, but didn't have their files cleaned up 
		# would have their timeout restored later
		#
#		$asp->Debug("session $id timed out, clearing");
#		$asp->{GlobalASA}->SessionOnEnd($id);
#		$internal->LOCK();
#		delete $internal->{$id};
#		$internal->UNLOCK();
		
		# we need to create a new state now after the clobbering
		# with SessionOnEnd
		goto NEW_SESSION_ID;
	    }
	} else {
	    # never seen before, maybe session garbage collected already
	    # or coming in from querystringed search engine

	    # wish we could do more 
	    # but proxying + nat prevents us from securing via ip address
	    goto NEW_SESSION_ID;
	}
    } else {
	# give user new session id, we must lock this portion to avoid
	# concurrent identical session key creation, this is the 
	# only critical part of the session manager

      NEW_SESSION_ID:
	my($trys);
	for(1..10) {
	    $trys++;
	    $id = $asp->Secret();

	    if($internal->{$id}) {
		$id = '';
	    } else {
		last;
	    }
	}

	$id && $asp->RefreshSessionId($id, {});
	$asp->{Internal}->UNLOCK();	

	$asp->Log("[security] secret algorithm is no good with $trys trys")
	    if ($trys > 3);
	$asp->Error("no unique secret generated")
	    unless $id;

	$asp->{dbg} && $asp->Debug("new session id $id");
	$asp->SessionId($id);

	$state = &Apache::ASP::State::new($asp, $id);
#	$state->Set() || $asp->Error("session state set failed");

	if($asp->{paranoid_session}) {
	    $asp->Debug("storing user-agent $asp->{'ua'}");
	    $state->STORE('_UA', $asp->{'ua'});
	}
	$started = 1;
    }

    if(! $state) {
	$asp->Error("can't get state for id $id");
	return;
    }

    $state->WriteLock() if $asp->{session_serialize};
    $asp->Debug("tieing session $id");
    tie %self, 'Apache::ASP::Session',
    {
	state=>$state, 
	asp=>$asp, 
	id=>$id,
	started=>$started,
    };

    if($started) {
	$asp->{dbg} && $asp->Debug("clearing starting session");
	if($state->Size > 0) {
	    $asp->{dbg} && $asp->Debug("clearing data in old session $id");
	    %self = ();
	}
    }

    bless \%self;
}	

sub TIEHASH { 
    my($package, $self) = @_;
    bless $self;
}       

# stub so we don't have to test for it in autoload
sub DESTROY {
    my $self = shift;

    # wrapped in eval to suppress odd global destruction error messages
    # in perl 5.6.0, --jc 5/28/2001
    return unless eval { $self->{state} };

    $self->{state}->DESTROY;
    undef $self->{state};
    %$self = ();
}

# don't need to skip DESTROY since we have it here
# return if ($AUTOLOAD =~ /DESTROY/);
sub AUTOLOAD {
    my $self = shift;
    my $AUTOLOAD = $Apache::ASP::Session::AUTOLOAD;
    $AUTOLOAD =~ s/^(.*)::(.*?)$/$2/o;
    $self->{state}->$AUTOLOAD(@_);
}

sub FETCH {
    my($self, $index) = @_;

    # putting these comparisons in a regexp was a little
    # slower than keeping them in these 'eq' statements
    if($index eq '_SELF') {
	$self;
    } elsif($index eq '_STATE') {
	$self->{state};
    } elsif($index eq 'SessionID') {
	$self->{id};
    } elsif($index eq 'Timeout') {
	$self->Timeout();
    } else {
	$self->{state}->FETCH($index);
    }
}

sub STORE {
    my($self, $index, $value) = @_;
    if($index eq 'Timeout') {
	$self->Timeout($value);
    } else {	
	$self->{state}->STORE($index, $value);
    }
}

# firstkey and nextkey skip the _UA key so the user 
# we need to keep the ua info in the session db itself,
# so we are not dependent on writes going through to Internal
# for this very critical informatioh. _UA is used for security
# validation / the user's user agent.
sub FIRSTKEY {
    my $self = shift;
    my $value = $self->{state}->FIRSTKEY();
    if(defined $value and $value eq '_UA') {
	$self->{state}->NEXTKEY($value);
    } else {
	$value;
    }
}

sub NEXTKEY {
    my($self, $key) = @_;
    my $value = $self->{state}->NEXTKEY($key);
    if(defined($value) && ($value eq '_UA')) {
	$self->{state}->NEXTKEY($value);
    } else {
	$value;
    }	
}

sub CLEAR {
    my $state = shift->{state};
    my $ua = $state->FETCH('_UA');
    my $rv = $state->CLEAR();
    $ua && $state->STORE('_UA', $ua);
    $rv;
}

sub SessionID {
    my $self = shift;
    tied(%$self)->{id};
}

sub Timeout {
    my($self, $minutes) = @_;

    if(tied(%$self)) {
	$self = tied(%$self);
    }

    if($minutes) {
	$self->{asp}{Internal}->LOCK;
	my($internal_session) = $self->{asp}{Internal}{$self->{id}};
	$internal_session->{refresh_timeout} = $minutes * 60;
	$internal_session->{timeout} = time() + $minutes * 60;
	$self->{asp}{Internal}{$self->{id}} = $internal_session;
	$self->{asp}{Internal}->UNLOCK;
    } else {
	my($refresh) = $self->{asp}{Internal}{$self->{id}}{refresh_timeout};
	$refresh ||= $self->{asp}{session_timeout};
	$refresh / 60;
    }
}    

sub Abandon {
    shift->Timeout(-1);
}

sub TTL {
    my $self = shift;
    $self = tied(%$self);
    # time to live is current timeout - time... positive means
    # session is still active, returns ttl in seconds
    my $timeout = $self->{asp}{Internal}{$self->{id}}{timeout};
    my $ttl = $timeout - time();
}

sub Started {
    my $self = shift;
    tied(%$self)->{started};
}

# we provide these, since session serialize is not 
# the default... locking around writes will also be faster,
# since there will be only one tie to the database and 
# one flush per lock set
sub Lock { tied(%{$_[0]})->{state}->WriteLock(); }
sub UnLock { tied(%{$_[0]})->{state}->UnLock(); }

1;

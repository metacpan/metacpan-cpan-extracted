
package Apache::ASP;

# quickly decomped out of Apache::ASP so we could load the routines only
# when we are managing State objects

use Apache::ASP::State;

use strict;
use vars qw(
  $CleanupGroups
 $SessionIDLength $SessionTimeout $StateManager
  $DefaultStateDB $DefaultStateSerializer
);

$SessionTimeout = 20;
$StateManager   = 10;

# Some OS's have hashed directory lookups up to 16 bytes, so we leave room
# for .lock extension ... nevermind, security is more important, back to 32
# $SessionIDLength = 11;
$SessionIDLength = 32;
$DefaultStateDB = 'SDBM_File';
$DefaultStateSerializer = 'Data::Dumper';

sub InitState {
    my $self = shift;
    my $r = $self->{r};
    my $global_asa = $self->{GlobalASA};

    ## STATE INITS
    # what percent of the session_timeout's time do we garbage collect
    # state files and run programs like Session_OnEnd and Application_OnEnd
    $self->{state_manager} = &config($self, 'StateManager', undef, $Apache::ASP::StateManager);

    # state is the path where state files are stored, like $Session, $Application, etc.
    $self->{state_dir}       = &config($self, 'StateDir', undef, $self->{global}.'/.state');
    $self->{state_dir}       =~ tr///; # untaint
    $self->{session_state}   = &config($self, 'AllowSessionState', undef, 1);
    $self->{state_serialize} = &config($self, 'ApplicationSerialize');

    if($self->{state_db} = &config($self, 'StateDB')) {
	# StateDB - Check StateDB module support 
	$Apache::ASP::State::DB{$self->{state_db}} ||
	  $self->Error("$self->{state_db} is not supported for StateDB, try: " . 
		       join(", ", keys %Apache::ASP::State::DB));
	$self->{state_db} =~ /^(.*)$/; # untaint
	$self->{state_db} = $1; # untaint
	# load the state database module && serializer
	$self->LoadModule('StateDB', $self->{state_db});
    }
    if($self->{state_serializer} = &config($self, 'StateSerializer')) {
	$self->{state_serializer} =~ tr///; # untaint
	$self->LoadModule('StateSerializer', $self->{state_serializer});
    }

    # INTERNAL tie to the application internal info
    my %Internal;
    tie(%Internal, 'Apache::ASP::State', $self, 'internal', 'server')
      || $self->Error("can't tie to internal state");
    my $internal = $self->{Internal} = bless \%Internal, 'Apache::ASP::State';
    $self->{state_serialize} && $internal->LOCK;

    # APPLICATION create application object
    $self->{app_state} = &config($self, 'AllowApplicationState', undef, 1);
    if($self->{app_state}) {
	# load at runtime for CGI environments, preloaded for mod_perl
	require Apache::ASP::Application;

	($self->{Application} = &Apache::ASP::Application::new($self)) 
	  || $self->Error("can't get application state");
	$self->{state_serialize} && $self->{Application}->Lock;

    } else {
	$self->{dbg} && $self->Debug("no application allowed config");
    }

    # SESSION if we are tracking state, set up the appropriate objects
    my $session;
    if($self->{session_state}) {
	## SESSION INITS
	$self->{cookie_path}       = &config($self, 'CookiePath', undef, '/');
	$self->{cookie_domain}     = &config($self, 'CookieDomain');
	$self->{paranoid_session}  = &config($self, 'ParanoidSession');
	$self->{remote_ip}         = $r->connection()->remote_ip();
	$self->{session_count}     = &config($self, 'SessionCount');
	
	# cookieless session support, cascading values
	$self->{session_url_parse_match} = &config($self, 'SessionQueryParseMatch');
	$self->{session_url_parse} = $self->{session_url_parse_match} || &config($self, 'SessionQueryParse');
	$self->{session_url_match} = $self->{session_url_parse_match} || &config($self, 'SessionQueryMatch');
	$self->{session_url} = $self->{session_url_parse} || $self->{session_url_match} || &config($self, 'SessionQuery');
	$self->{session_url_force} = &config($self, 'SessionQueryForce');
	
	$self->{session_serialize} = &config($self, 'SessionSerialize');
	$self->{secure_session}    = &config($self, 'SecureSession');
	# session timeout in seconds since that is what we work with internally
	$self->{session_timeout}   = &config($self, 'SessionTimeout', undef, $SessionTimeout) * 60;
	$self->{'ua'}              = $self->{headers_in}->get('User-Agent') || 'UNKNOWN UA';
	# refresh group by some increment smaller than session timeout
	# to withstand DoS, bruteforce guessing attacks
	# defaults to checking the group once every 2 minutes
	$self->{group_refresh}     = int($self->{session_timeout} / $self->{state_manager});
	
	# Session state is dependent on internal state

	# load at runtime for CGI environments, preloaded for mod_perl
	require Apache::ASP::Session;

	$session = $self->{Session} = &Apache::ASP::Session::new($self)
	  || $self->Die("can't create session");
	$self->{state_serialize} && $session->Lock();
	
    } else {
	$self->{dbg} && $self->Debug("no sessions allowed config");
    }

    # update after long state init, possible with SessionSerialize config
    $self->{Response}->IsClientConnected();

    # POSTPOSE STATE EVENTS, so we can delay the Response object creation
    # until after the state objects are created
    if($session) {
	my $last_session_timeout;
	if($session->Started()) {
	    # we only want one process purging at a time
	    if($self->{app_state}) {
		$internal->LOCK();
		if(($last_session_timeout = $internal->{LastSessionTimeout} || 0) < time()) {
		    $internal->{'LastSessionTimeout'} = $self->{session_timeout} + time;
		    $internal->UNLOCK();
		    $self->{Application}->Lock;
		    my $obj = tied(%{$self->{Application}});
		    if($self->CleanupGroups('PURGE')) {
			$last_session_timeout && $global_asa->ApplicationOnEnd();
			$global_asa->ApplicationOnStart();
		    }
		    $self->{Application}->UnLock;
		} 
		$internal->UNLOCK();
	    }
	    $global_asa->SessionOnStart();
	}

	if($self->{app_state}) {
	    # The last session timeout should only be updated every group_refresh period
	    # another optimization, rand() so not all at once either
	    $internal->LOCK();
	    $last_session_timeout ||= $internal->{'LastSessionTimeout'};
	    if($last_session_timeout < $self->{session_timeout} + time + 
	       (rand() * $self->{group_refresh} / 2)) 
	      {
		  $self->{dbg} && $self->Debug("updating LastSessionTimeout from $last_session_timeout");
		  $internal->{'LastSessionTimeout'} = 
		    $self->{session_timeout} + time() + $self->{group_refresh};
	      }
	    $internal->UNLOCK();
	}
    }

    $self;
}

# Cleanup a state group, by default the group of the current session
# We do this currently in DESTROY, which happens after the current
# script has been executed, so that cleanup doesn't happen until
# after output to user
#
# We always exit unless there is a $Session defined, since we only 
# cleanup groups of sessions if sessions are allowed for this script
sub CleanupGroup {
    my($self, $group_id, $force) = @_;
    return unless $self->{Session};

    my $asp = $self; # bad hack for some moved around code
    $force ||= 0;

    # GET GROUP_ID
    my $state;
    unless($group_id) {
	$state = $self->{Session}{_STATE};
	$group_id = $state->GroupId();
    }

    # we must have a group id to work with
    $asp->Error("no group id") unless $group_id;
    my $group_key = "GroupId" . $group_id;

    # cleanup timed out sessions, from current group
    my $internal = $asp->{Internal};
    $internal->LOCK();
    my $group_check = $internal->{$group_key} || 0;
    unless($force || ($group_check < time())) {
	$internal->UNLOCK();
	return;
    }
    
    # set the next group_check, randomize a bit to unclump the group checks,
    # for 20 minute session timeout, had rand() / 2 + .5, but it was still
    # too clumpy, going with pure rand() now, even if a bit less efficient

    my $next_check = int($asp->{group_refresh} * rand()) + 1;
    $internal->{$group_key} = time() + $next_check;
    $internal->UNLOCK();

    ## GET STATE for group
    $state ||= &Apache::ASP::State::new($asp, $group_id);
    my $ids = $state->GroupMembers() || [];

    # don't return so we can't delete the empty group later
#    return unless scalar(@$ids);

    $asp->{dbg} && $asp->Debug("group check $group_id, next in $next_check sec");
    my $id = $self->{Session}->SessionID();
    my $deleted = 0;
    $internal->LOCK();
    $asp->{dbg} && $asp->Debug("checking group ids", $ids);
    for my $id (@$ids) {
	eval {

	    #	if($id eq $_) {
	    #	    $asp->{dbg} && $asp->Debug("skipping delete self", {id => $id});
	    #	    next;
	    #	}
	    
	    # we lock the internal, so a session isn't being initialized
	    # while we are garbage collecting it... we release it every
	    # time so we don't starve session creation if this is a large
	    # directory that we are garbage collecting
	    my $idata = $internal->{$id};
	    
	    # do this check in case this data is corrupt, and not deserialized, correctly
	    unless(ref($idata) && (ref($idata) eq 'HASH')) {
		$idata = {};
	    }

	    my $timeout = $idata->{timeout} || 0;
	    
	    unless($timeout) {
		# we don't have the timeout always, since this session
		# may just have been created, just in case this is 
		# a corrupted session (does this happen still ??), we give it
		# a timeout now, so we will be sure to clean it up 
		# eventualy
		$idata->{timeout} = time() + $asp->{session_timeout};
		$internal->{$id} = $idata;
		$asp->Debug("resetting timeout for $id to $idata->{timeout}");
		return; # no next in eval {}
	    }	
	    # only delete sessions that have timed out
	    unless($timeout < time()) {
		$asp->{dbg} && $asp->Debug("$id not timed out with $timeout");
		return; # no next in eval {}
	    }
	    
	    # UPDATE & UNLOCK, as soon as we update internal, we may free it
	    # definately don't lock around SessionOnEnd, as it might take
	    # a while to process	
	    
	    # set the timeout for this session forward so it won't
	    # get garbage collected by another process
	    $asp->{dbg} && $asp->Debug("resetting timeout for deletion lock on $id");
	    $internal->{$id} = {
				%{$internal->{$id}},
				'timeout' => time() + $asp->{session_timeout},
				'end' => 1,
			  };
	    
	    
	    # unlock many times in case we are locked above this loop
	    for (1..3) { $internal->UNLOCK() }
	    $asp->{GlobalASA}->SessionOnEnd($id);
	    $internal->LOCK;
	    
	    # set up state
	    my($member_state) = Apache::ASP::State::new($asp, $id);	
	    if(my $count = $member_state->Delete()) {
		$asp->{dbg} && 
		  $asp->Debug("deleting session", {
						   session_id => $id, 
						   files_deleted => $count,
						  });
		$deleted++;
		delete $internal->{$id};
	    } else {
		$asp->Error("can't delete session id: $id");
		return; # no next in eval {}
	    }
	};
	if($@) {
	    $asp->Error("error for cleanup of session id $id: $@");
	}
    }
    $internal->UNLOCK();

    #### LEAVE DIRECTORIES, NASTY RACE CONDITION POTENTIAL
    ## NOW PRUNE ONLY DIRECTORIES THAT WE DON'T NEED TO KEEP
    ## FOR PERFORMANCE
    # REMOVE DIRECTORY, LOCK 
    # if the directory is still empty, remove it, lock it 
    # down so no new sessions will be created in it while we 
    # are testing
    if($deleted == @$ids) {
	if ($state->GroupId !~ /^[0]/) {
	    $asp->{Internal}->LOCK();
	    my $ids = $state->GroupMembers();
	    if(@{$ids} == 0) {
		$self->Log("purging stale group ".$state->GroupId.", which should only happen ".
			   "after Apache::ASP upgrade to beyond 2.09");
		$state->DeleteGroupId();
	    }
	    $asp->{Internal}->UNLOCK();
	}
    }

    $deleted;
}

sub CleanupGroups {
    my($self, $force) = @_;
    return unless $self->{Session};

    my $cleanup = 0;
    my $state_dir = $self->{state_dir};
    my $internal = $self->{Internal};
    $force ||= 0;

    $self->Debug("forcing groups cleanup") if ($self->{dbg} && $force);

    # each apache process has an internal time in which it 
    # did its last check, once we have passed that, we check
    # $Internal for the last time the check was done.  We
    # break it up in this way so that locking on $Internal
    # does not become another bottleneck for scripts
    if($force || ($Apache::ASP::CleanupGroups{$state_dir} || 0) < time()) {
	# /8 to keep it less bursty... since we check groups every group_refresh/2
	# we'll average 1/4 of the groups everytime we check them on a busy server
	$Apache::ASP::CleanupGroups{$state_dir} = time() + $self->{group_refresh}/8;
	$self->{dbg} && $self->Debug("testing internal time for cleanup groups");
	if($self->CleanupMaster) {
	    $internal->LOCK();
	    if($force || ($internal->{CleanupGroups} < (time - $self->{group_refresh}/8))) {
		$internal->{CleanupGroups} = time;
		$cleanup = 1;
	    }
	    $internal->UNLOCK;
	}
    }
    return unless $cleanup;

    # clean cache, so caching won't affect CleanupGroups() being called multiple times
    $self->{internal_cached_keys} = undef;

    # only one process doing CleanupGroup at a time now, so OK
    # lock around, necessary when keeping empty group directories
    my $groups = $self->{Session}{_SELF}{'state'}->DefaultGroups();
    $self->{dbg} && $self->Debug("groups ", $groups);
    my($sum_active, $sum_deleted);
    $internal->LOCK();
    my $start_cleanup = time;
    for(@{$groups}) {
	$sum_deleted = $self->CleanupGroup($_, $force);
	if ($start_cleanup > time) {
	    # every second, take a breather in the lock management
	    # so that sessions can be created, and the like, so for 
	    # long purges, the application will get sticky in 1 second
	    # bursts
	    $start_cleanup = time;
	    $internal->UNLOCK;
	    $internal->LOCK;
	    last unless $self->CleanupMaster;
	}
    }
    $internal->UNLOCK();
    $self->{dbg} && $self->Debug("cleanup groups", { deleted => $sum_deleted }) if $self->{dbg};

    # boolean true at least for master
    $sum_deleted || 1; 
}

sub CleanupMaster {
    my $self = shift;
    my $internal = $self->{Internal};
    
    $internal->LOCK;
    my $master = $internal->{CleanupMaster} || 
      {
       ServerID => '',
       PID => 0,
       Checked => 0,       
      };

    my $is_master = (($master->{ServerID} eq $ServerID) and ($master->{PID} eq $$)) ? 1 : 0;
    $self->{dbg} && $self->Debug(current_master => $master, is_master => $is_master );
    my $stale_time = $is_master ? $self->{group_refresh} / 4 : 
      $self->{group_refresh} / 2 + int($self->{group_refresh} * rand() / 2) + 1;
    $stale_time += $master->{Checked};
    
    if($stale_time < time()) {
	$internal->{CleanupMaster} =
	  {
	   ServerID => $ServerID,
	   PID => $$,
	   Checked => time()
	  };
	$internal->UNLOCK; # flush write
	$self->{dbg} && $self->Debug("$stale_time time is stale, is_master $is_master", $master);
	
	# we are only worried about multiprocess NFS here ... if running not
	# in mod_perl mode, probably just CGI mounted on local disk
	# Only do this while in DESTROY() mode too, so we avoid Application_OnStart
	# hang behavior.
	if($^O !~ /Win/ && $ENV{MOD_PERL} && $self->{DESTROY}) {
	    $self->Debug("sleep for acquire master check in case of shared state");
	    sleep(1);
	}
	
	my $master = $internal->{CleanupMaster}; # recheck after flush
	my $is_master = (($master->{ServerID} eq $ServerID) and ($master->{PID} eq $$)) ? 1 : 0;
	$self->{dbg} && $self->Debug("is_master $is_master after update $ServerID - $$");
	$is_master;
    } elsif($is_master) {
	$master->{Checked} = time();
	$internal->{CleanupMaster} = $master;
	$internal->UNLOCK;
	$self->{dbg} && $self->Debug("$stale_time time is fresh, is_master $is_master", $master);
	1; # is master
    } else {
	$internal->UNLOCK;
	$self->{dbg} && $self->Debug("$stale_time time is fresh, is_master $is_master", $master);
	0; # not master
    }
}

# combo get / set
sub SessionId {
    my($self, $id) = @_;

    if(defined $id) {
	unless($self->{session_url_force}) {
	    # don't set the cookie when we are just using SessionQuery* configs
	    my $secure = $self->{secure_session} ? '; secure' : '';
	    my $domain = $self->{cookie_domain}  ? '; domain='.$self->{cookie_domain} : '';
	    $self->{r}->err_headers_out->add('Set-Cookie', "$SessionCookieName=$id; path=$self->{cookie_path}".$domain.$secure);
	}
	$self->{session_id} = $id;
    } else {
	# if we have already parsed it out, return now
	# quick session_id caching, mostly for use with 
	# cookie less url building
	$self->{session_id} && return $self->{session_id};

	my $session_cookie = 0;

	unless($self->{session_url_force}) {
	    # don't read the cookie when we are just using SessionQuery* configs
	    my $cookie = $self->{r}->headers_in->{"Cookie"} || '';
	    my(@parts) = split(/\;\s*/, $cookie);
	    for(@parts) {	
		my($name, $value) = split(/\=/, $_, 2);
		if($name eq $SessionCookieName) {
		    $id = $value;
		    $session_cookie = 1;
		    $self->{dbg} && $self->Debug("session id from cookie: $id");
		    last;
		}
	    }
	}

	my $session_from_url;
	if(! defined($id) && $self->{session_url}) {
	    $id = delete $self->{Request}{QueryString}{$SessionCookieName};	    
	    # if there was more than one session id in the query string, then just
	    # take the first one
	    ref($id) =~ /ARRAY/ and ($id) = @$id;
	    $id && $self->{dbg} && $self->Debug("session id from query string: $id");
	    $session_from_url = 1;
	}

	# SANTIZE the id against hacking
	if(defined $id) {
	    if($id =~ /^[0-9a-z]{8,32}$/s) {
		# at least 8 bytes, but less than 32 bytes
		$self->{session_id} = $id;
	    } else {
		$self->Log("passed in session id $id failed checks sanity checks");
		$id = undef;		
	    }
	}

	if ($session_from_url && defined $id) {
	    $self->SessionId($id);
	}

	if(defined $id) {
	    $self->{session_id} = $id;
	    $self->{session_cookie} = $session_cookie;
	}
    }

    $id;
}

sub Secret {
    my $self = shift;
    # have enough data in here that even if srand() is seeded for the purpose
    # of debugging an external program, should have decent behavior.
    my $data = $self . $self->{remote_ip} . rand() . time() . 
      $self->{global} . $self->{'r'} . $self->{'filename'}.
	$$ . $ServerID;
    my $secret = substr(md5_hex($data), 0, $SessionIDLength);
    # by having [0-1][0-f] as the first 2 chars, only 32 groups now, which remains
    # efficient for inactive sites, even with empty groups
    $secret =~ s/^(.)/0/;
    $secret;
}

sub RefreshSessionId {
    my($self, $id, $reset) = @_;
    $id || $self->Error("no id for refreshing");
    my $internal = $self->{Internal};

    $internal->LOCK;
    my $idata = $internal->{$id};    
    my $refresh_timeout = $reset ? 
      $self->{session_timeout} : $idata->{refresh_timeout} || $self->{session_timeout};
    $idata->{'timeout'} = time() + $refresh_timeout;
    $internal->{$id} = $idata;	
    $internal->UNLOCK;
    $self->{dbg} && $self->Debug("refreshing $id with timeout $idata->{timeout}");

    1;
}

1;

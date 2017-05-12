
package Apache::ASP::GlobalASA;

# GlobalASA Object
# global.asa processes, whether or not there is a global.asa file.
# if there is not one, the code is left blank, and empty routines
# are filled in

use strict;
no strict qw(refs);
use vars qw(%stash *stash @ISA @Routines);

# these define the default routines that get parsed out of the 
# GLOBAL.ASA file
@Routines = 
    (
     "Application_OnStart", 
     "Application_OnEnd", 
     "Session_OnStart", 
     "Session_OnEnd",
     "Script_OnStart",
     "Script_OnEnd",
     "Script_OnParse",
     "Script_OnFlush"
     );
my $match_events = join('|', @Routines);

sub new {
    my $asp = shift || die("no asp passed to GlobalASA");

    my $filename = $asp->{global}.'/global.asa';
    my $id = &Apache::ASP::FileId($asp, $asp->{global}, undef, 1);
    my $package = $asp->{global_package} ? $asp->{global_package} : "Apache::ASP::Compiles::".$id;
    $id .= 'x'.$package; # need to recompile when either file or namespace changes

    # make sure that when either the file or package changes, that we 
    # update the global.asa compilation

    my $self = bless {
	asp => $asp,
	'package' => $package,
#	filename => $filename,
#	id => $id,
    };

    # assign early, since something like compiling reference the global asa,
    # and we need to do that in here
    $asp->{GlobalASA} = $self;

    $asp->{dbg} && $asp->Debug("GlobalASA package $self->{'package'}");
    my $compiled = $Apache::ASP::Compiled{$id};
    if($compiled && ! $asp->{stat_scripts}) {

#	$asp->{dbg} && $asp->Debug("no stat: GlobalASA already compiled");
	$self->{'exists'} = $compiled->{'exists'};
	$self->{'compiled'} = $compiled; # for event lookups
	return $self;
    }

    if($compiled) {
#	$asp->{dbg} && $asp->Debug("global.asa was cached for $id");
    } else {
	$asp->{dbg} && $asp->Debug("global.asa was not cached for $id");
	$compiled = $Apache::ASP::Compiled{$id} = { mtime => 0, 'exists' => 0 };
    }
    $self->{compiled} = $compiled;
    
    my $exists = $self->{'exists'} = -e $filename;
    my $changed = 0;
    if(! $exists && ! $compiled->{'exists'}) {
	# fastest exit for simple case of no global.asa
	return $self;
    } elsif(! $exists && $compiled->{'exists'}) {
	# if the global.asa disappeared
	$changed = 1;
    } elsif($exists && ! $compiled->{'exists'}) {
	# if global.asa reappeared
	$changed = 1;
    } else {
	$self->{mtime} = $exists ? (stat(_))[9] : 0;
	if($self->{mtime} > $compiled->{mtime}) {
	    # if the modification time is greater than the compile time
	    $changed = 1;
	}
    }
    $changed || return($self);

    my $code = $exists ? ${$asp->ReadFile($filename)} : "";
    my $strict = $asp->{use_strict} ? "use strict" : "no strict";

    if($code =~ s/\<script[^>]*\>((.*)\s+sub\s+($match_events).*)\<\/script\>/$1/isg) {
	$asp->Debug("script tags removed from $filename for IIS PerlScript compatibility");
    }
    $code = (
	     "\n#line 1 $filename\n".
	     join(" ;; ",
		  "package $self->{'package'};",
		  $strict,
		  "use vars qw(\$".join(" \$",@Apache::ASP::Objects).');',
		  "use lib qw($self->{asp}->{global});",
		  $code,
		  'sub exit { $main::Response->End(); } ',
		  "no lib qw($self->{asp}->{global});",
		  '1;',
		 )
	     );

    $asp->{dbg} && $asp->Debug("compiling global.asa $self->{'package'} $id exists $exists", $self, '---', $compiled);
    $code =~ /^(.*)$/s;
    $code = $1;

    # turn off $^W to suppress warnings about reloading subroutines
    # which is a valid use of global.asa.  We cannot just undef 
    # all the events possible in global.asa, as global.asa can be 
    # used as a general package library for the web application
    # --jc, 9/6/2002
    local $^W = 0;

    # only way to catch strict errors here    
    if($asp->{use_strict}) { 
	local $SIG{__WARN__} = sub { die("maybe use strict error: ", @_) };
	eval $code;
    } else {
	eval $code;
    }

    # if we have success compiling, then update the compile time
    if(! $@) {
	# if file mod times are bad, we need to use them anyway
	# for relative comparison, time() was used here before, but
	# doesn't work
	$compiled->{mtime} = $self->{mtime} || (stat($filename))[9];
	
	# remember whether the file really exists
	$compiled->{'exists'} = $exists;
	
	# we cache whether the code was compiled so we can do quick
	# lookups before executing it
	my $routines = {};
	local *stash = *{"$self->{'package'}::"};
	for(@Routines) {
	    if($stash{$_}) {
		$routines->{$_} = 1;
	    }
	}
	$compiled->{'routines'} = $routines;
	$asp->Debug('global.asa routines', $routines);
	$self->{'compiled'} = $compiled;
    } else {
	$asp->CompileErrorThrow($code, "errors compiling global.asa: $@");
    }

    $self;
}

sub IsCompiled {
    my($self, $routine) = @_;
    $self->{'compiled'}{routines}{$routine};
}

sub ExecuteEvent {
    my($self, $event) = @_;
    if($self->{'compiled'}{routines}{$event}) {
	$self->{'asp'}->Execute($event);
    }
}

sub SessionOnStart {
    my $self = shift;
    my $asp = $self->{asp};
    my $zero_sessions = 0;

    if($asp->{session_count}) {
	$asp->{Internal}->LOCK();
	my $session_count = $asp->{Internal}{SessionCount} || 0;
	if($session_count <= 0) {
	    $asp->{Internal}{SessionCount} = 1;	
	    $zero_sessions = 1;
	} else {
	    $asp->{Internal}{SessionCount} = $session_count + 1;
	}
	$asp->{Internal}->UNLOCK();
    }

    #X: would like to run application startup code here after
    # zero sessions is true, but doesn't seem to account for 
    # case of busy server, then 10 minutes later user comes in...
    # since group cleanup happens after session, Application
    # never starts.  Its only when a user times out his own 
    # session, and comes back that this code would kick in.
    
    $asp->Debug("Session_OnStart", {session => $asp->{Session}->SessionID});
    $self->ExecuteEvent('Session_OnStart');
}

sub SessionOnEnd {
    my($self, $id) = @_;
    my $asp = $self->{asp};
    my $internal = $asp->{Internal};

    # session count tracking
    if($asp->{session_count}) {
	$internal->LOCK();
	if((my $count = $internal->{SessionCount}) > 0) {
	    $internal->{SessionCount} = $count - 1;
	} else {
	    $internal->{SessionCount} = 0;
	}	    
	$internal->UNLOCK();
    }

    # only retie session if there is a Session_OnEnd event to execute
    if($self->IsCompiled('Session_OnEnd')) {
	my $old_session = $asp->{Session};
	my $dead_session;
	if($id) {
	    $dead_session = &Apache::ASP::Session::new($asp, $id);
	    $asp->{Session} = $dead_session;
	} else {
	    $dead_session = $old_session;
	}
	
	$asp->{dbg} && $asp->Debug("Session_OnEnd", {session => $dead_session->SessionID()});
	$self->ExecuteEvent('Session_OnEnd');
	$asp->{Session} = $old_session;
	
	if($id) {
	    untie %{$dead_session};
	}
    }

    1;
}

sub ApplicationOnStart {
    my $self = shift;
    $self->{asp}->Debug("Application_OnStart");
    %{$self->{asp}{Application}} = (); 
    $self->ExecuteEvent('Application_OnStart');
}

sub ApplicationOnEnd {
    my $self = shift;
    my $asp = $self->{asp};
    $asp->Debug("Application_OnEnd");
    $self->ExecuteEvent('Application_OnEnd');
    %{$self->{asp}{Application}} = (); 

    # PROBLEM, since we are not resetting ASP objects
    # every execute now, useless code anyway

    #    delete $asp->{Internal}{'application'};    
    #    local $^W = 0;
    #    my $tied = tied %{$asp->{Application}};
    #    untie %{$asp->{Application}};
    #    $tied->DESTROY(); # call explicit DESTROY
    #    $asp->{Application} = &Apache::ASP::Application::new($self->{asp})
    #      || $self->Error("can't get application state");
}

sub ScriptOnStart {
    my $self = shift;
    $self->{asp}{dbg} && $self->{asp}->Debug("Script_OnStart");
    $self->ExecuteEvent('Script_OnStart');
}

sub ScriptOnEnd {
    my $self = shift;
    $self->{asp}{dbg} && $self->{asp}->Debug("Script_OnEnd");
    $self->ExecuteEvent('Script_OnEnd');
}

sub ScriptOnFlush {
    my $self = shift;
    $self->{asp}{dbg} && $self->{asp}->Debug("Script_OnFlush");
    $self->ExecuteEvent('Script_OnFlush');
}

sub EventsList {
    @Routines;
}

1;

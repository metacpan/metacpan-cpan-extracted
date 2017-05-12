package Apache::ASP::State;

use MLDBM;
use MLDBM::Sync 0.25;
use MLDBM::Sync::SDBM_File;
use SDBM_File;
use Data::Dumper;

use strict;
no strict qw(refs);
use vars qw(%DB %CACHE $DefaultGroupIdLength);
use Fcntl qw(:flock O_RDWR O_CREAT);
$DefaultGroupIdLength = 2;

# Database formats supports and their underlying extensions
%DB = (
       SDBM_File => ['.pag', '.dir'],
       DB_File => [''],
       'MLDBM::Sync::SDBM_File' => ['.pag', '.dir'],
       GDBM_File => [''],
       'Tie::TextDir' => [''],
       );

# About locking, we use a separate lock file from the SDBM files
# generated because locking directly on the SDBM files occasionally
# results in sdbm store errors.  This is less efficient, than locking
# to the db file directly, but having a separate lock file works for now.
#
# If there is no $group given, then the $group will be extracted from
# the $id as the first 2 letters of that group.
#
# If the group and the id are the same length, then what was passed
# was just a group id, and the object is being created for informational
# purposes only.  So, we don't create a lock file in this case, as this
# is not a real State object
#
sub new {
    my($asp, $id, $group) = @_;

    if($id) {
	$id =~ tr///;
    } else {
	$asp->Error("no id: $id passed into new State");
	return;
    }

    # default group is first 2 characters of id, simple hashing
    if($group) {
	$group =~ tr///;
    } else {
	$group = substr($id, 0, $DefaultGroupIdLength)
    }

    unless($group) {
	$asp->Error("no group defined for id $id");
	return;
    }

    my $state_dir = $asp->{state_dir};
    my $group_dir = $state_dir.'/'.$group;
    my $lock_file = $group_dir.'/'.$id.'.lock';
    my $file = $group_dir.'/'.$id;

    # we only need SDBM_File for internal, and its faster so use it
    my($state_db, $state_serializer);
    if($id eq 'internal') {
	$state_db = $Apache::ASP::DefaultStateDB;
	$state_serializer = $Apache::ASP::DefaultStateSerializer;
    } elsif($asp->{Internal} && (length($id) > $DefaultGroupIdLength)) {
	# don't get data for dummy group id sessions
	my $internal = $asp->{Internal};
	my $idata = $internal->{$id};
	if(! $idata->{state_db} || ! $idata->{state_serializer}) {
	    $state_db = $idata->{state_db} || $asp->{state_db} || $Apache::ASP::DefaultStateDB;
	    $state_serializer = $idata->{state_serializer} || 
	      $asp->{state_serializer} || $Apache::ASP::DefaultStateSerializer;
	    
	    # INIT StateDB && StateSerializer if hitting for the first time
	    # only if real id like a session id or application
	    if(length($id) > $DefaultGroupIdLength) {
		my $diff = 0;
		if(($idata->{state_db} || $Apache::ASP::DefaultStateDB) ne $state_db) {
		    $idata->{state_db} = $state_db;
		    $diff = 1;
		}
		if(($idata->{state_serializer} || $Apache::ASP::DefaultStateSerializer) ne $state_serializer) {
		    $idata->{state_serializer} = $state_serializer;
		    $diff = 1;
		}

		if($diff) {
		    $asp->{dbg} && $asp->Debug("setting internal data for state $id", $idata);
		    $internal->{$id} = $idata;
		}
	    }
	} else {
	    # this state has already been created
	    $state_db = $idata->{state_db};
	    $state_serializer = $idata->{state_serializer};
	}
    } else {
	# cache layer doesn't need internal
	($state_db, $state_serializer) = ($asp->{state_db}, $asp->{state_serializer});
    }

    my $self = 
      bless {
	     asp=>$asp,
	     dbm => undef, 
	     'dir' => $group_dir,
	     id => $id, 
	     file => $file,
	     group => $group, 
	     group_dir => $group_dir,
	     reads => 0,
	     state_dir => $state_dir,
	     writes => 0,
	    };

    # short circuit before expensive directory tests for group stub
    if ($group eq $id) {
	return $self;
    }

    if($asp->config('StateAllWrite')) {
	$asp->{dbg} and $asp->{state_all_write} = 1;
	$self->{dir_perms} = 0777;
	$self->{file_perms} = 0666;
    } elsif($asp->config('StateGroupWrite')) {
	$asp->{dbg} and $asp->{state_group_write} = 1;
	$self->{dir_perms} = 0770;
	$self->{file_perms} = 0660;
    } else {
	$self->{dir_perms} = 0750;
	$self->{file_perms} = 0640;
    }

#    push(@{$self->{'ext'}}, @{$DB{$self->{state_db}}});    
#    $self->{asp}->Debug("db ext: ".join(",", @{$self->{'ext'}}));

    # create state directories
    my @create_dirs;
    unless(-d $state_dir) {
	push(@create_dirs, $state_dir);
    }
    # create group directory
    unless(-d $group_dir) {
	push(@create_dirs, $group_dir);
    }
    if(@create_dirs) {
	$self->UmaskClear;
	for my $create_dir (@create_dirs) {
#	    $create_dir =~ tr///; # this doesn't work to untaint with perl 5.6.1, use old method
	    $create_dir =~ /^(.*)$/s;
	    $create_dir = $1;
	    if(mkdir($create_dir, $self->{dir_perms})) {
		$asp->{dbg} && $asp->Debug("creating state dir $create_dir");
	    } else {
		my $error = $!;
		-d $create_dir || $self->{asp}->Error("can't create group dir $create_dir: $error");
	    }
	}
	$self->UmaskRestore;
    }

    # INIT MLDBM::Sync DBM
    { 
	local $MLDBM::UseDB = $state_db || 'SDBM_File';
	local $MLDBM::Serializer = $state_serializer || 'Data::Dumper';
	# clear current tied relationship first, if any
	$self->{dbm} = undef; 
	local $SIG{__WARN__} = sub {};
	
	my $error;
	$self->{file} =~ /^(.*)$/; # untaint
	$self->{file} = $1;
	local $MLDBM::RemoveTaint = 1;
	$self->{dbm} = &MLDBM::Sync::TIEHASH('MLDBM', $self->{file}, O_RDWR|O_CREAT, $self->{file_perms});
	$asp->{dbg} && $asp->Debug("creating dbm for file $self->{file}, db $MLDBM::UseDB, serializer: $MLDBM::Serializer");
	$error = $! || 'Undefined Error';


	if(! $self->{dbm}) {
	    $self->{asp}->Error(qq{
Cannot tie to file $self->{file}, $error !!
Make sure you have the permissions on the directory set correctly, and that your
version of Data::Dumper is up to date. Also, make sure you have set StateDir to 
to a good directory in the config file.  StateDir defaults to Global/.state
});
	}
    }

    $self;
}

sub Init   { shift->{dbm}->CLEAR(); }
sub Size   { shift->{dbm}->SyncSize; }
sub Delete { shift->{dbm}->CLEAR(); }
sub WriteLock { shift->{dbm}->Lock; }
sub ReadLock { shift->{dbm}->ReadLock; }
sub UnLock { shift->{dbm}->UnLock; }

sub DeleteGroupId {
    my $self = shift;

    my $group_dir = $self->{group_dir};
    if(-d $group_dir) {
	$self->{asp}{Internal}->LOCK;
	if(rmdir($group_dir)) {
	    $self->{asp}->Debug("deleting group dir $group_dir");
	} else {
	    $self->{asp}->Log("cannot delete group dir $group_dir: $!");
	}
	$self->{asp}{Internal}->UNLOCK;
    }
}

sub GroupId { shift->{group}; }

sub GroupMembers {
    my $self = shift;
    local(*DIR);
    my(%ids, @ids);

    unless(opendir(DIR, $self->{group_dir})) {
	$self->{asp}->Log("opening group $self->{group_dir} failed: $!");
	return [];
    }

    for(readdir(DIR)) {
	next if /^\.\.?$/;
	$_ =~ /^(.*?)(\.[^\.]+)?$/;
	next unless $1;
	$ids{$1}++;
    }

    # need to explicitly close directory, or we get a file
    # handle leak on Solaris
    closedir(DIR);

    # since not all sessions have their own dbms now, find session ids in $Internal too
    if(my $internal = $self->{asp}{Internal}) {
	my $cached_keys = {};
	unless($cached_keys = $self->{asp}{internal_cached_keys}) {
	    map {
		if(/^([0-9a-f]{2})/) { 
		    $cached_keys->{$1}{$_}++
		}
	    } keys %$internal;
	    $self->{asp}{internal_cached_keys} = $cached_keys;
	}
	if(my $group_keys = $cached_keys->{$self->{group}}) {
	    %ids = ( %ids, %$group_keys );
	}
    }

    @ids = keys %ids;

    \@ids;
}

sub DefaultGroups {
    my $self = shift;
    my(@ids);
    local *STATEDIR;

    opendir(STATEDIR, $self->{state_dir}) 
	|| $self->{asp}->Error("can't open state dir $self->{state_dir}");
    my $time = time;
    for(readdir(STATEDIR)) {
	next if /^\./;
	next unless (length($_) eq $DefaultGroupIdLength);
	push(@ids, $_);
    }
    closedir STATEDIR;

    \@ids;
}

sub UmaskClear {
    my $self = shift;
    return if $self->{asp}{win32};
    $self->{umask_restore} = umask(0000);
}

sub UmaskRestore {
    my $self = shift;
    return if $self->{asp}{win32};
    if(defined $self->{umask_restore}) {
	umask($self->{umask_restore});
    }
}

sub DESTROY {
    my $self = shift;
    return unless %{$self};
    return if $self->{destroyed}++;
    $self->{dbm} && eval { $self->{dbm}->DESTROY };
    $self->{dbm} = undef;
}

# don't need to skip DESTROY since we have it defined
# return if ($AUTOLOAD =~ /DESTROY/);
sub AUTOLOAD {
    my $self = shift;
    my $AUTOLOAD = $Apache::ASP::State::AUTOLOAD;
    $AUTOLOAD =~ s/^(.*)::(.*?)$/$2/o;

    my $value;
    $value = $self->{dbm}->$AUTOLOAD(@_);

    $value;
}

sub TIEHASH {
    my $type = shift;

    # dual tie contructor, if we receive a State object to tie
    # then just return it, otherwise construct a new object
    # before tieing
    if((ref $_[0]) =~ /State/) {
	$_[0];
    } else {	
	bless &new(@_), $type;
    }
}

sub FETCH {
    my($self, $index) = @_;
    my $value;

    if($index eq '_FILE') {
	$value = $self->{file};
    } elsif($index eq '_SELF') {
	$value = $self;
    } else {
	$value = $self->{dbm}->FETCH($index);
	$self->{reads}++;
    }

    $value;
}

sub STORE {
    my $self = shift;

    # don't worry about overhead of Umask* routines, the STORE
    # being called is much heavier
    $self->UmaskClear;
    my $rv = $self->{dbm}->STORE(@_);
    $self->UmaskRestore;
    $self->{writes}++;

    $rv;
}

sub LOCK { my $self = tied(%{$_[0]}); $self->{dbm}->Lock(); }
sub UNLOCK { my $self = tied(%{$_[0]}); $self->{dbm}->UnLock(); }

1;

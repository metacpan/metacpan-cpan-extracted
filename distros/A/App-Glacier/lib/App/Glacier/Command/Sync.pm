package App::Glacier::Command::Sync;

use strict;
use warnings;
use App::Glacier::Core;
use parent qw(App::Glacier::Command);
use App::Glacier::DateTime;
use App::Glacier::Timestamp;
use App::Glacier::Job::InventoryRetrieval;
use JSON;

=head1 NAME

glacier sync - synchronize vault inventory cache

=head1 SYNOPSIS

B<glacier sync>
[B<-df>]
[B<--delete>]    
[B<--force>]
I<VAULT>

=head1 DESCRIPTION

Retrieves inventory for I<VAULT> and incorporates it into the local
directory.  Use this command if the local directory went out of sync
or was otherwise clobbered.

=head1 OPTIONS

=over 4

=item B<-d>, B<--delete>

Deletes from the directory items that have no corresponding archive IDs in
the inventory.
    
=item B<-f>, B<--force>

Initiate new inventory retrieval job, even if one is already in progress.

=back

=head1 SEE ALSO

B<glacier>(1).    
    
=cut

sub new {
    my ($class, $argref, %opts) = @_;
    $class->SUPER::new(
	$argref,
	optmap => {
	    'force|f' => 'force',
	    'delete|d' => 'delete'
	},
	%opts);
}

sub run {
    my $self = shift;
    $self->abend(EX_USAGE, "one argument expected")
	unless $self->command_line == 1;
    unless ($self->sync(($self->command_line)[0], %{$self->{_options}})) {
	exit(EX_TEMPFAIL);
    }
}

sub sync {
    my ($self, $vault_name, %opts) = @_;

    my $dir = $self->directory($vault_name);
    my $job = new App::Glacier::Job::InventoryRetrieval(
	$self, $vault_name,
	invalidate => $opts{force});
    if ($job->is_completed) {
	my $res = $self->glacier->Get_job_output($vault_name, $job->id);
	if ($self->glacier->lasterr) {
	    if ($self->glacier->lasterr('code') == 404 && !$opts{force})  {
		if ($opts{restart}) {
		    $self->abend(EX_FAILURE,
				 "unexpected error after restart:",
				 $self->glacier->last_error_message);
		}
		# Job expired, delete it
		# ('mesg' => 'The job ID was not found...)
		$opts{force} = 1;
		return $self->sync($vault_name, %opts);
	    } else {
		# FIXME
		$self->abend(EX_FAILURE, "can't list vault $vault_name: ",
			     $self->glacier->last_error_message);
	    }
	}
	$res = decode_json($res);
	$self->_sync($dir, [map { timestamp_deserialize($_) }
			        @{$res->{ArchiveList}}], $opts{delete});
	return 1;
    } else {
	$self->error("inventory retrieval job for $vault_name initiated at " .
		     $job->get('CreationDate')->canned_format
		     . "; please retry later to get the listing");
	return 0;
    }	
}

sub _sync {
    my ($self, $dir, $invref, $delete) = @_;
    my %arch;

    $self->debug(1, "retrieved ".(@{$invref})." inventory records");
    @arch{map { $_->{ArchiveId} } @{$invref}} = @{$invref};

    # 1. Iterate over records in the invdb
    # 2. For each record, see if its ArchiveID is present in the input array
    # 2.1. If so, retain it, and remove the item from the input
    # 2.2. Otherwise, remove it
    # 3. For each remaining element in the input
    # 3.1. Add the record to the DB

    $dir->foreach(sub {
	my ($key, $val) = @_;
	my $mod = 0;
	for (my $i = 0; $i <= $#{$val}; ) {
	    if (exists($arch{$val->[$i]{ArchiveId}})) {
		$self->debug(1, "found $key;".($i+1));
		while (my ($k,$v) = each %{$arch{$val->[$i]{ArchiveId}}}) {
		    unless (exists($val->[$i]{$k})) {
			$self->debug(1, "$key;".($i+1).": updating $k");
			$val->[$i]{$k} = $v;
			$mod = 1;
		    }
		}
		delete $arch{$val->[$i]{ArchiveId}};
		$i++
	    } elsif ($delete) {
		$self->debug(1, "deleting $key;".($i+1));
		splice(@{$val}, $i, 1);
		$mod = 1;
	    } else {
		$self->debug(1, "$key;".($i+1),"not found");
		$i++;
	    }
	    unless ($self->dry_run) {
		$dir->store($key, $val) if $mod;
	    }
	}
	if ($delete && @{$val} == 0) {
	    $self->debug(1, "deleting $key");
	    $dir->delete($key) unless $self->dry_run;
	}
		  });

    while (my ($aid, $val) = each %arch) {
	my $file_name;
	
	if (exists($self->{_name_decoder})) {
	    $file_name = &{$self->{_name_decoder}}($val);
	} else {
	    $file_name = $val->{ArchiveDescription};
	}
	if ($file_name eq '') {
	    $file_name = $dir->tempname();
	}
	my $ver = $dir->add_version($file_name, $val) unless $self->dry_run;
	$self->debug(1, "incorporating $file_name;$ver");
    }
    $dir->update_sync_time unless $self->dry_run;
}
    
1;

    
    

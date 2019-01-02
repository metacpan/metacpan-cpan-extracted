package App::Glacier::Job;
use strict;
use warnings;
require Exporter;
use parent qw(Exporter);
use Carp;
use App::Glacier::Core;
use App::Glacier::Timestamp;

# new(CMD, VAULT, KEY, INIT)

sub new {
    croak "bad number of arguments" unless $#_ >= 4;
    my ($class, $cmd, $vault, $key, %opts) = @_;
    my $invalidate = delete $opts{invalidate};
    my $ttl = delete $opts{ttl};
    
    if (keys(%opts)) {
	croak "unrecognized parameters: ".join(', ', keys(%opts));
    }
    
    return bless { _cmd => $cmd,
		   _vault => $vault,
		   _key => $key,
		   _job => undef,
		   _ttl => $ttl,
		   _invalidate => $invalidate }, $class;
}

sub fromdb {
    my ($class, $cmd, $vault, $key, $job) = @_;
    return bless { _cmd => $cmd,
		   _vault => $vault,
		   _key => $key,
		   _job => $job }, $class;
}

sub command { shift->{_cmd} }
sub glacier { shift->command->glacier }
sub vault { shift->{_vault} };

sub _get_db {
    my ($self) = @_;
    return $self->command->jobdb();
}

sub _get_job {
    my ($self) = @_;
    my $db = $self->_get_db;

    if ($self->{_job}) {
	if ($self->{_invalidate}) {
	    $db->delete($self->{_key});
	    $self->{_job} = undef;
	}
    }
    
    unless ($self->{_job}) {
	my $job = $db->retrieve($self->{_key}) unless $self->{_invalidate};
	if (!$job) {
	    $self->debug(2, "initiating job $self->{_key}");
	    $job = { JobId => $self->init, Completed => 0 };
	    $db->store($self->{_key}, $job);
	}

	if (!$job->{Completed}
	    || ($self->{_ttl} 
		&& (time - $job->{CompletionDate}->epoch) > $self->{_ttl})) {
	    $self->debug(2, "checking status of job $self->{_key}");
	    my $res = $self->glacier->Describe_job($self->{_vault},
						   $job->{JobId});
	    if ($self->glacier->lasterr) {
		if ($self->glacier->lasterr('code') == 404) {
		    $self->debug(2, "job $self->{_key} expired");
		    $db->delete($self->{_key});
		    return $self->_get_job;
		} else {
		    $self->command->abend(EX_UNAVAILABLE,
					 "can't describe job $job->{JobId}: ",
					 $self->glacier->last_error_message);
		}
	    } elsif (ref($res) ne 'HASH') {
		croak "describe_job returned wrong datatype (".ref($res).") for \"$job->{JobId}\"";
	    } else {
		$res = timestamp_deserialize($res);
		$self->debug(2, $res->{StatusCode});
		$db->store($self->{_key}, $res);
		$job = $res;
	    }		
	}
	$self->{_job} = $job;
    }
    return $self->{_job};
}

sub debug { my $self = shift->command->debug(@_) }

sub id {
    my $self = shift;
    my $job = $self->_get_job;
    return $job->{JobId};
}

sub get {
    my ($self, $key) = @_;
    my $job = $self->_get_job;
    return undef unless exists $job->{$key};
    return $job->{$key};
}

sub as_string { shift->get('JobDescription') }

use overload
    '""' => \&as_string;

sub is_finished {
    my $self = shift;
    return defined($self->get('StatusCode'));
}

sub is_completed {
    my $self = shift;
    return ($self->get('StatusCode') || '') eq 'Succeeded';
}

sub status {
    my $self = shift;
    my $status = $self->get('StatusCode');
    return undef unless defined $status;
    return wantarray ? ($status, $self->get('StatusMessage')) : $status;
}

sub delete {
    my $self = shift;
    if (my $cache = $self->cache_file) {
	if (-f $cache) {
	    unlink($cache);
	}
    }
    my $db = $self->_get_db;
    $db->delete($self->{_key});
}

sub cache_file {
    my $self = shift;
    my $aid = $self->get('ArchiveId') or return;
    my $vault = $self->get('VaultARN') or return;
    $vault =~ s{.*:vaults/}{};
    return $self->command->archive_cache_filename($vault, $aid);
}

1;

    

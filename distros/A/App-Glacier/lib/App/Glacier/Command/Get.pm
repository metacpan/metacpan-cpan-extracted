package App::Glacier::Command::Get;
use strict;
use warnings;
use threads;
use threads::shared;
use App::Glacier::Core;
use App::Glacier::Job::FileRetrieval;
use App::Glacier::DateTime;
use App::Glacier::Progress;
use parent qw(App::Glacier::Command);
use Carp;
use Scalar::Util;
use File::Copy;

=head1 NAME

glacier get - download file from a vault

=head1 SYNOPSIS

B<glacier put>
[B<-fikqt>]
[B<--force>]    
[B<--interactive>]    
[B<-j> I<NJOBS>]
[B<--jobs=>I<NJOBS>]
[B<--no-clobber>]
[B<--keep>]    
[B<--quiet>]    
[B<--test>]    
I<VAULT>
I<FILE>
[I<LOCALNAME>]

=head1 DESCRIPTION

Downloads I<FILE> from the I<VAULT>.  The local file name for the file is
supplied by the I<LOCALNAME>.  If this argument is absent, the local name
is formed from I<FILE> with the eventual version number part removed.
See B<glacier>(1), section B<On file versioning>, for the
information about file versioning scheme.   
    
=head1 OPTION

=over 4
    
=item B<-f>, B<--force>

Silently overwrites existing local file.
    
=item B<-i>, B<--interactive>

If the local file already exists, asks for permission before overwriting
it.    
    
=item B<-j>, B<--jobs=>I<N>

Sets the number of concurrent download jobs for multiple-part downloads.
The default is configured by the B<transfer.download.jobs> configuration
statement.  If absent, the B<transfer.jobs> statement is used.  The
default value is 16.    
    
=item B<-k>, B<--keep>, B<--no-clobber>

Never overwrite existing files.
    
=item B<-q>, B<--quiet>

Don't display progress meter during multi-part downloads.
    
=item B<-t>, B<--test>

Test mode.  Don't download the file, display only the status of the
correspondig archive retrieval job.

=back    
    
=head1 SEE ALSO

B<glacier>(1).    
    
=cut

use constant {
    IFEXISTS_OVERWRITE => 0,
    IFEXISTS_KEEP => 1,
    IFEXISTS_ASK => 2,
};
    
sub new {
    my ($class, $argref, %opts) = @_;
    my $self = $class->SUPER::new(
	$argref,
	optmap => {
	    'interactive|i' => sub {
		$_[0]->{_options}{ifexists} = IFEXISTS_ASK
	    },
	    'force|f' => sub {
		$_[0]->{_options}{ifexists} = IFEXISTS_OVERWRITE
	    },
	    'no-clobber|keep|k' => sub {
		$_[0]->{_options}{ifexists} = IFEXISTS_KEEP
	    },
	    'quiet|q' => 'quiet',
	    'jobs|j=i' => 'jobs',
	    'test|t' => 'test'
	},
	%opts);
    $self->{_options}{ifexists} //= IFEXISTS_OVERWRITE;
    return $self;
}

sub run {
    my $self = shift;

    $self->abend(EX_USAGE, "two or three arguments expected")
	unless $self->command_line == 2 || $self->command_line == 3;
    my ($vaultname, $filespec, $localname) = $self->command_line;
    $filespec =~ /^(?<file>.+?)(?:(?<!\\);(?<ver>\d+))?$/
	or die "unexpected failure";

    my ($filename, $ver) = ($+{file}, $+{ver});
    # Reset $ver and $filespec for error reporting
    $ver = 1 unless defined $ver;
    $filespec = "$filespec;$ver";
    
    $localname = $filename unless defined($localname);

    if (-e $localname) {
	if ($self->{_options}{ifexists} == IFEXISTS_ASK) {
	    $self->{_options}{ifexists} =
		$self->getyn("\"$localname\" already exists, overwrite")
		  ? IFEXISTS_OVERWRITE : IFEXISTS_KEEP;
	}
	if ($self->{_options}{ifexists} == IFEXISTS_KEEP) {
	    exit(EX_NOPERM);
	}
    }

    my $job = new App::Glacier::Job::FileRetrieval($self, $vaultname,
						   $filename, $ver);

    if ($self->{_options}{test}) {
	print "downloading file $filename initialized on ",
	      $job->get('CreationDate')->canned_format('full-iso'),"\n";
	print "job id: ", $job->id, "\n";
	my ($status, $message) = $job->status;
	print "current status: $status\n";
	if ($message) {
	    print "status message: $message\n";
	}
	
	if ($job->is_completed) {
	    print "completed on ",
	          $job->get('CompletionDate')->canned_format('full-iso'),"\n";
	}
	exit(0);
    }
    
    if ($job->is_completed) {
	my $cache_file = $job->cache_file;
	if (-f $cache_file) {
	    $self->debug(1, "$job: copying from $cache_file");
	    return if $self->dry_run;
	    unless (copy($cache_file, $localname)) {
		$self->abend(EX_FAILURE,
			     "can't copy $cache_file to $localname: $!");
	    }
	} else {
	    my $tree_hash = $self->download($job, $localname);
	    if (!$self->dry_run
		&& $tree_hash ne $job->get('ArchiveSHA256TreeHash')) {
		unlink $localname;
		$self->abend(EX_SOFTWARE, "downloaded file is corrupt");
	    }
	}
    } else {
	my ($status, $message) = $job->status;
	if ($status eq 'InProgress') {
	    $self->abend(EX_TEMPFAIL,
			 "archive retrieval job for $vaultname:$filespec initiated at " .
			 $job->get('CreationDate')->canned_format
			 . "; please retry later to download the file");
	} else {  
	    $self->error("archive retrieval job for $vaultname:$filespec: $status: $message");
	    $self->error("deleting job", $job->id);
	    $job->delete;
	    exit (EX_FAILURE);
	}
    }
}

use constant MB => 1024*1024;
use constant TWOMB => 2*MB;

sub download {
    my ($self, $job, $localname) = @_;
    
    my $archive_size = $job->get('ArchiveSizeInBytes');
    if ($archive_size < $self->cf_transfer_param(qw(download single-part-size))) {
	# simple download 
	$self->_download_simple($job, $localname);
    } else {
	$self->_download_multipart($job, $localname);
    }
}

sub _open_output {
    my ($self, $localname) = @_;
    open(my $fd, '>', $localname)
	or $self->abort(EX_FAILURE, "can't open $localname: $!");
    binmode($fd);
    truncate($fd, 0);
    return $fd;
}

sub _download_simple {
    my ($self, $job, $localname) = @_;

    $self->debug(1, "$job: downloading in single part");
    return if $self->dry_run;
    my $fd = $self->_open_output($localname);
    my ($res, $tree_hash) = $self->glacier->Get_job_output($job->vault,
							   $job->id);
    if ($self->glacier->lasterr) {
	$self->abend(EX_FAILURE, "downoad failed: ",
		     $self->glacier->last_error_message);
    }
    syswrite($fd, $res);
    close($fd);
    return $tree_hash;
}

sub _download_multipart {
    my ($self, $job, $localname) = @_;
        
    my $glacier = $self->{_glacier};

    my $tree_hash;
    
    my $njobs = $self->{_options}{jobs}
                || $self->cf_transfer_param(qw(download jobs));

    my $archive_size = $job->get('ArchiveSizeInBytes');
    my $part_size;
    # Compute approximate part size
    $part_size = ($archive_size - 1) / 10000;
    if ($part_size < TWOMB) {
	$part_size = TWOMB;
    } else {
	# Make sure the chunk is Tree-Hash aligned
	# http://docs.aws.amazon.com/amazonglacier/latest/dev/checksum-calculations-range.html?shortFooter=true#checksum-calculations-upload-archive-with-ranges
	$part_size = TWOMB * 2 ** int(log($part_size / TWOMB) / log(2) + 1);
    }
    # Number of parts to download:
    my $total_parts = int(($archive_size + $part_size - 1) / $part_size);
    # Compute the number of parts per job
    my $job_parts = int(($total_parts + $njobs - 1) / $njobs);

    $self->debug(1, "$job: downloading in chunks of $part_size bytes, in $njobs jobs, with $job_parts parts per job");

    return if $self->dry_run;

    use Fcntl qw(SEEK_SET);

    my $fd = $self->_open_output($localname);
    my @part_hashes :shared = ();
    my $p = new App::Glacier::Progress($total_parts,
				       prefix => $localname)
	unless $self->{_options}{quiet};
    for (my $i = 0; $i < $njobs; $i++) {
	my ($thr) = threads->create(
	    sub {
		my ($job_idx) = @_;
		# Number of part to start from
		my $part_idx = $job_idx * $job_parts;
		# Offset in file
		my $off = $part_idx * $part_size;
		# Number of retries in case of failure
		my $retries = $self->cf_transfer_param(qw(download retries));
		Scalar::Util::weaken($p);
		for (my $j = 0; $j < $job_parts;
		     $j++, $part_idx++, $off += $part_size) {
		    last if $off >= $archive_size;
		    if ($part_size > $archive_size - $off) {
			$part_size = $archive_size - $off;
		    }
		    my $range = 'bytes=' . $off . '-' . ($off + $part_size - 1);
		    my ($res, $hash);
		    for (my $try = 0;;) {
			($res, $hash) =
			    $self->glacier->Get_job_output($job->vault,
							   $job->id, $range);
			if ($self->glacier->lasterr) {
			    if (++$try < $retries) {
				$self->debug(1, "part $part_idx: ",
					     $self->glacier->last_error_message);
				$self->debug(1, "retrying");
			    } else {
				$self->error("failed to download part $part_idx: ",
					     $self->glacier->last_error_message);
				return 0;
			    }
			} else {
			    last;
			}
		    }

		    lock @part_hashes;
		    seek($fd, $off, SEEK_SET);
		    syswrite($fd, $res);
		    $part_hashes[$part_idx] = $hash;
		    $p->update if $p;
		}
		return 1;
	    }, $i);
    }
    
    $self->debug(2, "waiting for download to finish");
    foreach my $thr (threads->list()) {
	# FIXME: error handling
	$thr->join() or croak "thread $thr failed";
    }
    $p->finish('downloaded') if $p;
    close($fd);
    return $glacier->_tree_hash_from_array_ref(\@part_hashes);
}
    
1;


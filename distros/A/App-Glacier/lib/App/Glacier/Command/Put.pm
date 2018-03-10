package App::Glacier::Command::Put;
use strict;
use warnings;
use App::Glacier::Core;
use App::Glacier::DateTime;
use App::Glacier::Job::InventoryRetrieval;
use App::Glacier::Progress;
use parent qw(App::Glacier::Command);
use File::Basename;
use File::stat;
use Fcntl ':mode';
use Scalar::Util;
use Carp;

=head1 NAME

glacier put - upload file to a vault

=head1 SYNOPSIS

B<glacier put>
[B<-q>]
[B<-j> I<NJOBS>]
[B<--jobs=>I<NJOBS>]
[B<--quiet>]    
I<VAULT>
I<FILE> [I<FILE>...]

B<glacier put> 
{ B<-r> | B<--rename> }
[B<-q>]
[B<-j> I<NJOBS>]
[B<--jobs=>I<NJOBS>]
[B<--quiet>]    
I<VAULT>
I<FILE> I<REMOTENAME>    


=head1 DESCRIPTION

Uploads I<FILE>s to I<VAULT>.  With B<--rename> option, uploads single
I<FILE> and assings I<REMOTENAME> to the copy in the vault.

=head1 OPTION

=over 4

=item B<-q>, B<--quiet>

Don't display progress meter during multi-part uploads.

=item B<-j>, B<--jobs=>I<N>

Sets the number of concurrent jobs for multiple-part uploads.
The default is configured by the B<transfer.upload.jobs> configuration
statement.  If absent, the B<transfer.jobs> statement is used.  The
default value is 16.    

=item B<-r>, B<--rename>

Uploads single file with a different remote name.  Exactly three arguments are
expected: the name of the vault, the name of the local file to upload and the
name to assign to the remote copy.

=back    

=head1 SEE ALSO

B<glacier>(1).
    
=cut    

sub new {
    my ($class, $argref, %opts) = @_;
    $class->SUPER::new(
	$argref,
	optmap => {
	    'jobs|j=i' => 'jobs',
	    'quiet|q' => 'quiet',
	    'rename|r' => 'rename'
	}, %opts);
}

sub run {
    my $self = shift;
    if ($self->{_options}{rename}) {
	$self->abend(EX_USAGE, "exactly three arguments expected")
	    unless $self->command_line == 3;
	my ($vaultname, $localname, $remotename) = $self->command_line;
	$self->_upload($vaultname, $localname, $remotename);
    } else {
	my @argv = $self->command_line;
	$self->abend(EX_USAGE, "too few arguments") if @argv < 2;
	my $vaultname = shift @argv;
	my @failed_uploads;
	foreach my $filename (@argv) {
	    eval {
		$self->_upload($vaultname, $filename);
	    };
	    if ($@) {
		if ($@ =~ /^__UPLOAD_FAILED__/) {
		    push @failed_uploads, $filename;
		    next
		}
		die $@;
	    }
	}
	if (@failed_uploads) {
	    if (@failed_uploads == @argv) {
		exit(EX_FAILURE);
	    } else {
		$self->error("the following files failed to upload: "
			     . join(', ', @failed_uploads));
		exit(EX_UNAVAILABLE);
	    }
	}
    }
}

sub abend {
    my ($self, $code, @msg) = @_;
    $self->error(@msg);
    if ($self->{_options}{multiple}) {
	die "__UPLOAD_FAILED__";
    } else {
	exit $code;
    }
}

sub _upload {
    my ($self, $vaultname, $localname, $remotename) = @_;

    $remotename = basename($localname) unless defined($remotename);

    my $st = stat($localname)
	or $self->abend(EX_NOINPUT, "can't stat \"$localname\": $!");
    unless (S_ISREG($st->mode)) {
	$self->abend(EX_NOPERM, "\"$localname\" is not a regular file");
    }
    my $size = $st->size;
    if ($size == 0) {
	$self->abend(EX_NOPERM, "\"$localname\": file has zero size");
    }
    
    my $dir = $self->directory($vaultname);
    my $id = ($size < $self->cf_transfer_param(qw(upload single-part-size)))
	       ? $self->_upload_simple($vaultname, $localname, $remotename)
               : $self->_upload_multipart($vaultname, $localname, $remotename);
    return if $self->dry_run;
    $self->debug(1, "ID $id\n");
    $dir->add_version($remotename, { ArchiveId => $id,
				     Size => $size,
				     CreationDate => new App::Glacier::DateTime,
				     ArchiveDescription => $remotename });
    $dir->invalidate;
}

sub _upload_simple {
    my ($self, $vaultname, $localname, $remotename) = @_;

    $self->debug(1, "uploading $localname in single part");
    return if $self->dry_run;

    my $p = new App::Glacier::Progress(1,
				       prefix => $localname,
				       show_none => 1)
	unless $self->{_options}{quiet};
    my $archive_id = $self->glacier_eval('upload_archive',
					 $vaultname,
					 $localname,
					 $remotename);
    $p->finish('uploaded') if $p;
    
    if ($self->lasterr) {
	$self->abend(EX_FAILURE, "upload failed: ",
		     $self->last_error_message);
    }
    return $archive_id;
}

sub _upload_multipart {
    my ($self, $vaultname, $localname, $remotename) = @_;
    my $glacier = $self->{_glacier};
    
    use threads;
    use threads::shared;

    my $archive_size = -s $localname;
    my $part_size =
	$glacier->calculate_multipart_upload_partsize($archive_size);
    
    $self->abend(EX_FAILURE, "$localname is too big for upload")
	if $part_size == 0;

    # Number of parts to upload:
    my $total_parts = int(($archive_size + $part_size - 1) / $part_size);
    
    # Compute number of threads
    my $njobs = $self->{_options}{jobs}
                || $self->cf_transfer_param(qw(upload jobs));

    # Number of parts to upload by each job;
    my $job_parts = int(($total_parts + $njobs - 1) / $njobs);
    
    $self->debug(1,
	 "uploading $localname in chunks of $part_size bytes, in $njobs jobs");
    return if $self->dry_run;
    
    open(my $fd, '<', $localname)
	or $self->abort(EX_FAILURE, "can't open $localname: $!");
    binmode($fd);
    my $upload_id = $glacier->multipart_upload_init($vaultname, $part_size,
						    $remotename);
    $self->debug(1, "Upload ID: $upload_id");

    use Fcntl qw(SEEK_SET);
    
    my @part_hashes :shared = ();
    my $p = new App::Glacier::Progress($total_parts,
				       prefix => $localname)
	unless $self->{_options}{quiet};
    
    for (my $i = 0; $i < $njobs; $i++) {
	my $thr = threads->create(
	    sub {
		my ($job_idx) = @_;
		# Number of part to start from
		my $part_idx = $job_idx * $job_parts;
		# Offset in file
		my $off = $part_idx * $part_size;
		# Number of retries in case of failure
		my $retries = $self->cf_transfer_param(qw(upload retries));
		
		for (my $j = 0; $j < $job_parts;
		     $j++, $part_idx++, $off += $part_size) {
		    last if $off >= $archive_size;
		    my $part;
		    {
			lock @part_hashes;
			seek($fd, $off, SEEK_SET);
			my $rb = sysread($fd, $part, $part_size);
			if ($rb == 0) {
			    $self->abend(EX_OSERR,
					 "failed to read part $part_idx: $!");
			}
		    }
		
		    my $res;
		    for (my $try = 0;;) {
			$res = $self->glacier_eval(
			                 'multipart_upload_upload_part',
			                 $vaultname,
			                 $upload_id,
			                 $part_size,
			                 $part_idx,
			                 \$part);
			if ($self->lasterr) {
			    if (++$try < $retries) {
				$self->debug(1, "part $part_idx: ",
					     $self->last_error_message);
				$self->debug(1, "retrying");
			    } else {
				$self->error("failed to upload part $part_idx: ",
					     $self->last_error_message);
				return 0;
			    }
			} else {
			    last;
			}
		    }
			
		    $part_hashes[$part_idx] = $res;
		    $p->update if $p;		    
		}
		return 1;
	    }, $i);
    }    

    $self->debug(2, "waiting for dowload to finish");
    foreach my $thr (threads->list) {
	# FIXME: better error handling
	$thr->join() or croak "thread $thr failed";
    }
    $p->finish('uploaded') if $p;
    
    # Capture archive id or error code
    $self->debug(2, "finalizing the upload");
    my $archive_id = $self->glacier_eval('multipart_upload_complete',
					 $vaultname, $upload_id,
					 \@part_hashes,
					 $archive_size);

    if ($self->lasterr) {
	$glacier->multipart_upload_abort($vaultname, $upload_id);
	$self->abend(EX_FAILURE, "upload failed: ",
		     $self->last_error_message);
    }
    
    # Check if we have a valid $archive_id
    unless ($archive_id =~ /^[a-zA-Z0-9_\-]{10,}$/) {
	$glacier->multipart_upload_abort($vaultname, $upload_id);
	$self->abend(EX_FAILURE, "upload completion failed");
    }

    return $archive_id;
}

1;

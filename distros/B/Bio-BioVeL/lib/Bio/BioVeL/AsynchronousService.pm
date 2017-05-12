package Bio::BioVeL::AsynchronousService;
use strict;
use warnings;
use File::Path 'make_path';
use Scalar::Util 'refaddr';
use Bio::BioVeL::Service;
use Digest::MD5 'md5_hex';
use Apache2::Const '-compile' => qw'OK REDIRECT';
use Proc::ProcessTable;
use base 'Bio::BioVeL::Service';

# status constants
use constant RUNNING => 'running';
use constant DONE    => 'done';
use constant ERROR   => 'error';

=head1 NAME

Bio::BioVeL::AsynchronousService - base class for asynchronous web services

=head1 SYNOPSIS

 use Bio::BioVeL::AsynchronousService::Mock; # example class
 
 # this static method returns a writable directory into which
 # service objects are persisted between request/response cycles
 my $wd = Bio::BioVeL::AsynchronousService::Mock->workdir;

 # when instantiating objects, values for the 'parameters' that are defined
 # in their constructors can be provided as named arguments
 my $mock = Bio::BioVeL::AsynchronousService::Mock->new( 'seconds' => 1 );

 # every async service has a record of when it started
 my $epoch_time = $mock->timestamp;

 # can be RUNNING, ERROR or DONE
 if ( $mock->status eq Bio::BioVeL::AsynchronousService::DONE ) {
 	print $mock->response_body;
 }

=head1 DESCRIPTION

Asynchronous services need to subclass this class and implement at least the following
methods: C<launch> and C<response_body>. The parent class makes sure that launch()
forks off a process and returns immediately with enough information, stored as object
properties, so that update() can check how things are going and update the status(). 
Once the status set to C<DONE>, C<response_body> is executed to generate the output.

Successful implementations are likely going to have simple, serializable object properties
that allow a newly de-serialized object (i.e. during the next polling cycle) to probe
the process table or the job directory to check the status.

=head1 METHODS

=over

=item new

The constructor may or may not be passed the named argument 'jobid', which is used to
deserialize the job object and check on its status. If no job ID is provided, a new
object is created and launched.

=cut

sub new {
	my $class = shift;
	my $log   = $class->logger;
	my %args  = @_;
	my $self;
	if ( my $id = $args{'jobid'} ) {
	
		# unfreeze from file
		$log->info("instantiating existing $class job: $id");
		$self = $class->from_file( $class->workdir . '/' . $id . '.yml' );
		
		# check the service status
		eval { $self->update };
		if ( $@ ) {
			my $msg = "$@";		
			$log->error("problem updating $self: $msg");
			$self->lasterr( $msg );
			$self->status( ERROR );
		}
	}
	else {
		
		# create new instance
		$log->info("launching new $class job");
		$self = $class->SUPER::new( 'timestamp' => time(), %args );
		
		# generate UID: {pointer address}.{epoch time}
		$self->jobid( refaddr($self) . '.' . timestamp($self) );
		
		# launch the service
		eval { $self->launch_wrapper };
		if ( $@ ) {
			if ( $@ !~ /ModPerl::Util::exit/ ) {
				my $msg = "$@";
				$log->error("problem launching $self: $msg");
				$self->lasterr( $msg );
				$self->status( ERROR );
			}
			else {
				$log->info("ModPerl::Util::exit was trapped, assume we are done");
				$self->status( DONE );
			}
		}
		else {
			$log->info("launched $self successfully");
			$self->status( RUNNING );
		}		
	}
	return $self;
}

=item launch

The concrete child class needs to implement the launch() method, which presumably
will fork off a process, e.g. using system("command &"), such that it will be able
to keep track of its status, e.g. by knowing the PID of the child processes.

=cut

sub launch { 
	die "The launch() method needs to be implemented by the concrete child class\n" 
}

=item launch_wrapper

Wraps the service launch() inside a fork() to keep track of the PID.

=cut

sub launch_wrapper {
	my $self = shift;
	my $log  = $self->logger;
	my $pid  = fork();
	if ( $pid == 0 ) {
		
		# we're in the child process
		$log->info("launching the child process");
		$self->launch;
		exit(0);
	}
	else {
	
		# we're in the parent
		$log->info("launched service job with PID $pid");
		$self->pid($pid);
	}
}

=item update 

The concrete child class needs to implement the update() method, which will check on
the process that was launched by launch(), and will update the status, e.g. from RUNNING
to DONE or ERROR.

=cut

sub update { 
	my $self   = shift;
	my $log    = $self->logger;
	my $status = DONE;
	if ( my $pid = $self->pid ) {
		my $timestamp = $self->timestamp;
		my $pt = Proc::ProcessTable->new;
		PROC: for my $proc ( @{ $pt->table } ) {
			if ( $proc->pid == $pid ) {
				if ( abs( $timestamp - $proc->start ) < 2 ) {
					$log->info("still running: ".$proc->cmndline);
					$status = RUNNING;
					last PROC;
				}
			}
		}
	}
	$self->status($status);
}

=item jobid

The unique ID of the service job.

=cut

sub jobid {
	my $self = shift;
	$self->{'jobid'} = shift if @_;
	return $self->{'jobid'};
}

=item pid

The process ID of the service job.

=cut

sub pid {
	my $self = shift;
	$self->{'pid'} = shift if @_;
	return $self->{'pid'};
}

=item timestamp

The launch timestamp of the job.

=cut

sub timestamp { 
	my $self = shift;
	$self->{'timestamp'} = shift if @_;
	return $self->{'timestamp'};
}

=item lasterr

The last error string that occurred.

=cut

sub lasterr {
	my $self = shift;
	$self->{'lasterr'} = shift if @_;
	return $self->{'lasterr'};
}

=item status

The job status, either RUNNING, DONE or ERROR.

=cut

sub status {
	my $self = shift;
	$self->{'status'} = shift if @_;
	return $self->{'status'};
}

=item handler

The mod_perl handler. Tries to rebuild the job object, checks its status, returns
either a status report or the response body.

=cut

sub handler {
	my $r = shift;
	my $request = Apache2::Request->new($r);
	my $subclass = __PACKAGE__ . '::' . $request->param('service');
	eval "require $subclass";
	my $self = $subclass->new( 
		'request' => $request, 
		'jobid'   => ( $request->param('jobid') || 0 ),
	);
	if ( $self->status eq DONE ) {
		if ( my $loc = $self->response_location ) {
			my $docroot = $r->doc_root;
			my $path    = $r->location;
			my $server  = $r->get_server_name;
			$loc =~ s/^\Q$docroot\E//;
			my $url = 'http://' . $server . $path . $loc;
			$r->headers_out->set('Location' => $url);
			$r->status(Apache2::Const::REDIRECT);			
		}
		else {
			print $self->response_body;
		}
	}
	else {
		my $template = <<'TEMPLATE';
<response>
	<jobid>%s</jobid>
	<status>%s</status>
	<error>%s</error>
	<timestamp>%i</timestamp>
</response>
TEMPLATE
		no warnings 'uninitialized';
		printf $template, $self->jobid, $self->status, $self->lasterr, $self->timestamp;
	}
	return Apache2::Const::OK;
}

=item workdir

This static method returns a directory inside $ENV{BIOVEL_HOME}, which consequently needs 
to be defined, for example by specifying it with PerlSetEnv inside httpd.conf. See:
L<http://modperlbook.org/html/4-2-10-PerlSetEnv-and-PerlPassEnv.html>. This dir is used 
for serializing the job object, so its location can be generated/pulled out of the air by 
static methods (as the object might not exist yet). For job-specific output (e.g. analysis
result files), use outdir().

=cut

sub workdir {
	my $class = shift;
	my $name = ref($class) || $class;
	$name =~ s|::|/|g;
	my $dir = $ENV{'BIOVEL_HOME'} . '/' . $name;
	make_path($dir) if not -d $dir;
	return $dir;
}

=item outdir

This object method returns a directory location where the child class can write its output

=cut

sub outdir {
	my $self = shift;
	my $dir  = $self->workdir . '/' . $self->jobid;
	make_path($dir) if not -d $dir;
	return $dir;
}

=item DESTROY

The object destructor automatically serializes the dying object inside workdir.

=cut

sub DESTROY {
	my $self  = shift;
	my $wdir  = $self->workdir;
	my $jobid = $self->jobid;
	my $file  = "${wdir}/${jobid}.yml";
	my $log = $self->logger;
	$log->info("writing $self as $jobid to file $file");
	$self->to_file( $file );
}

=back

=cut

1;
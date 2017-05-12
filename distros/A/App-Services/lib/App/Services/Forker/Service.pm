package App::Services::Forker::Service;
{
  $App::Services::Forker::Service::VERSION = '0.002';
}

use Moose;

with 'App::Services::Logger::Role';

has child_objects => (
	is       => 'rw',
	isa      => 'ArrayRef',
	required => 1,
);

has child_actions => (
	is       => 'rw',
	isa      => 'CodeRef',
	required => 1,
);

has child_labels => (
	is      => 'rw',
	isa     => 'ArrayRef[Str]',
	default => sub { [] },
);

has no_waitpid => (
	is      => 'rw',
	isa     => 'Bool',
	default => 0,
);

has max_procs => (
	is      => 'rw',
	isa     => 'Int',
	default => 45,
);

has timeout => (
	is      => 'rw',
	isa     => 'Int',
	default => 15,
);

has no_fork => (
	is      => 'rw',
	isa     => 'Bool',
	default => 0,
);

has chunks => (
	is      => 'rw',
	isa     => 'Int',
	default => 0,
);

has before_waitpid => (
	is  => 'rw',
	isa => 'CodeRef',
);

sub forker {
	my $s = shift;

	my $log = $s->log;
	$log->info("Begin Forker");

	my $ra = $s->child_objects;    #-- reference to an array
	my $rs = $s->child_actions;    #-- reference to a sub

	$s->timeout(0);

	$s->no_fork(0);

	$log->logconfess("Max procs too high!")
	  if scalar( @{$ra} ) > $s->max_procs;

	$log->info("Using pseudo-fork") if $s->no_fork;

	my @child_pids;
	my @child_labels_by_pid;
	my $child_number = 0;
	my $pid;

	foreach my $obj ( @{$ra} ) {

		my $child_name = ${ $s->{child_labels} }[$child_number] // "${child_number}";    #//

		if ( $s->no_fork ) {
			$log->debug("Pseudo $child_name: Spawned");

			my $result;

			if ( $s->timeout ) {
				eval {
					local $SIG{ALRM} = sub { die "Process timed out"; };
					alarm $s->timeout;
					$result = $rs->($obj);
					alarm 0;
				};

				if ( $@ && $@ =~ 'Process timed out' ) {    #-- if there is an error and the error message is from the alarm signal handler...
					$log->logconfess( "Pseudo ${child_name}: Timed out (" . $s->timeout . "s)" );    # propagate unexpected errors
					                                                                                 # timed out
				} elsif ($@) {                                                                       #-- Else there was an error in the eval block, but it wasn't from 'alarm'
					alarm 0;                                                                         #-- Turn off alarm
					$log->error("Pseudo ${child_name}: $@");
					exit 1;
				}

			} else {
				$result = $rs->($obj);

			}

			$log->debug("Pseudo-child ${child_name}: Exiting");

		} else {
			$pid = fork;

			$log->logconfess("Child $child_name: Fork failed!")
			  unless defined $pid;

			if ( $pid == 0 ) {

				$child_name .= " ($$)";    #-- add process id to child label

				#-- I'm a child
				$log->debug("Child $child_name: Spawned");

				my $result;

				if ( $s->timeout ) {
					eval {
						local $SIG{ALRM} = sub { die "Process timed out"; };
						alarm $s->timeout;
						$result = $rs->($obj);
						alarm 0;
					};

					alarm 0;    #-- Turn off alarm when eval breaks for a different reason than timeout

					if ( $@ && $@ =~ 'Process timed out' ) {
						$log->logconfess( "Child $child_name: Timed out (" . $s->timeout . "s)" );    # propagate unexpected errors
						                                                                              # timed out
					} elsif ($@) {
						$log->error("Child $child_name: $@");
						exit 1;

					}

				} else {
					$result = $rs->($obj);

				}

				my $rc = defined $result ? 0 : 1;                                                     #-- perl convention (undef = error) => shell convention (>0 = error)

				$result = '' unless defined $result;                                                  #-- turn undef into a string

				$log->debug("Child $child_name: Exiting with result=<$result>,rc=<$rc>");
				exit $rc;                                                                             #-- Critical! Don't forget!

			} elsif ( $pid >= 0 ) {

				#-- I'm the parent, keep track of my children
				push @child_pids, $pid;
				$child_labels_by_pid[$pid] = $child_name;
				
				$s->log->debug("Forked child: $child_name");

				$child_number++;

			} else {
				$s->log->error("$child_name: fork returned invalid pid=$pid");

			}

		}

	}

	if ( $s->before_waitpid ) {
		my $result = $s->before_waitpid->( $ra );

		return unless $result;

	}

	my $forker_rc = 1;

	unless ( $s->no_fork ) {
		$log->debug("Parent: Waiting for children to exit");

		foreach my $pid (@child_pids) {
			waitpid( $pid, 0 );
			my $child_name = "$child_labels_by_pid[$pid] ($pid)";

			if ( $? & 127 ) {
				undef($forker_rc);
				$s->log->error( "Child $child_name: fork reports exited with value " . ( $? >> 8 ) );
				$s->log->warn("Child $child_name: Core dumped") if $? & 128;

			} else {
				my $rc = $? >> 8;
				if ($rc) {
					undef($forker_rc) if $rc;    #-- if any exit is non-zero, return undef for the whole fork op
					$s->log->error("Child $child_name: completed with error value $rc");

				} else {
					$s->log->debug("Child $child_name: completed successfully with value $rc");

				}

			}

		}

		$log->debug("Parent: Finished waiting. All children exited");
	}

	if ( $forker_rc ) {
		$s->log->info( "End Forker: Success" );
	
	} else {
		$s->log->info( "End Forker: Failed" );

	}
	

	return $forker_rc;
}

no Moose;

1;

__END__

=pod

=head1 NAME

App::Services::Forker::Service

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Project::Util::Forker;

 my @children = (1,2,3,4,5);   #-- The children. Each element will be passed
                                #   to the subroutine below in one child process

 sub child_actions {           #-- What you want the children to do
   my $i = shift;              #-- One of the elements of @children 
   print "I'm child #$i!\n";
 }
		
 my $fkr = ChopperTrading::Project::Util::Forker->new(  #-- The ctor
   child_objects => \@children,
   child_actions => \&child_actions,
 );
	
 $fkr->forker;                 #-- Commence forking

=head1 DESCRIPTION

Simply calls the fork perl command in a safe, reusable way. Loops over
each element of a list and forks a process, passing the list element to
the specified forked subroutine.

A more interesting example is to have each child object be an actual
object like for a machine and then call a method like 'start_server' or
something like:

 sub child_actions {
   my $machine = shift;
   $machine->start_server
 }

This can be condensed further in the constructor and chained with
the forker method for a compact call:

 ChopperTrading::Project::Util::Forker->new(
   child_objects => \@children,
   child_actions => sub { $_[0]->start_server },
 )->forker;

Currently there is a a default maximum of 60 processes allowed. If the size of @children
is greater than 60, forker will fail before any forking.

=head1 NAME

App::Services::Forker::Service

=head1 AUTHORS

Sean Blanton

=head1 To Do

1. Add Chunking to keep the max # of processes under a fixed amount, but accomplish a greater number of forked tasks via iteration. In order to start 80 servers, with a max process amount equal to 60, chunking would allow execution first of 60 forked processes, then after waiting for all of those to complete, execute the remaining 20. A queuing mechanism could possibly be implemented so a new process is forked as soon as one as reaped...just thinking out loud.

2. Make this module obsolete by finding a way to use AnyEvent:: with Net::OpenSSH. Possibly an easy job. (Thanks to Jon Rockway)

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

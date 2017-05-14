#!/usr/bin/perl

##
# Agent.pm v3.2
# Patchlevel: 00
# Steve Purkis <spurkis@engsoc.carleton.ca>
# December 15, 1998
##

package Agent;

use strict;
use UNIVERSAL;
use Class::Tom qw( cc repair );
use Data::Dumper;			# for argument passing
use Agent::Message;			# load message handling routines
use Agent::Transport;			# load the autoloader

use vars qw($VERSION $MAJORVERSION $MINORVERSION $MICROVERSION $thread $Debug);

$MAJORVERSION = '3';
$MINORVERSION = '20';
$MICROVERSION = '00';	# aka patchlevel

# I realize with this scheme it's possible to have conflicting version
# numbers, but CPAN doesn't like tuples.  Solution, MINOR < 100.  If it
# hits 100 it's prolly time for an increase in MAJOR anyway.
$VERSION = "$MAJORVERSION.$MINORVERSION$MICROVERSION";

BEGIN {
	# Check for Thread.pm...
	eval "use Thread qw( async );";
	if ($@) { $Agent::thread = 0; }
	else    { $Agent::thread = 1; }
}


sub new {
	my ($class, %args) = @_;

	my $self = {};
	my ($stored, $fh, $name, $code, $cpt, $tom, $method) =
	   delete @args{'Stored', 'File', 'Name', 'Code', 'Compartment'};

	# first get the code...
	if ($stored) {
		if (ref($stored) eq 'ARRAY') { $code = join('', @$stored); }
		else { $code = $stored; }
		$method = 'repair';
	} else {
		if ($fh) {
			unless ($fh->isa('IO::Handle')) {
				warn "File argument was not of IO::Handle!";
				return;
			}
			local $/ = undef;
			$code = <$fh>;
		} elsif ($name) {
			$code = _find_agent($name);
		} elsif ($code) {
			if (ref($stored) eq 'ARRAY') {
				$code = join('', @$code);
			}
		} else {
			my ($pkg, $fl, $ln) = caller();
			warn "$fl:$ln passed no valid arguments!";
			return;
		}
		unless (defined($code)) {
			warn "agent's source code could not be resolved!";
			return;
		}
		$method = 'cc';
	}

	# then make the Tom object.
	if ($method eq 'repair') {
		# use Tom's repair() to produce container:
		unless ($tom = repair($code, $cpt)) {	# Tom doesn't support this yet
			warn "Discarding a corrupted agent!" if $Debug;
			return ();
		}
	} elsif ($method eq 'cc') {
		# use Tom's cc() to get container.  Note that since we're
		# only interested in the first container returned, parens
		# are about $tom.  Agent does not support multi-class agent
		# definitions yet (sorry).
		unless (($tom) = cc($code, $cpt)) {	# Tom doesn't support this yet
			warn "Tom didn't return a container!" if $Debug;
			return;
		}
	}

	# now register it:
	if ($cpt) { $tom->register(Compartment => $cpt); }
	else      { $tom->register(); }
	if ($@) {
		warn "Unsafe agent trapped: $@\n";
		return;
	}

	# and extract the object:
	if ($cpt) {
		# use $self as a wrapper object...
		$self->{Compartment} = $cpt;

		# get the object into the safe compartment...
		$self->{AgentVar} = $tom->put_object($cpt);
		if ($@) {
			warn "Unsafe agent trapped: $@\n";
			return;
		}
		unless ($self->{AgentVar}) {
			$self->{AgentVar} = '$agent';
			my $agentclass = $tom->class;
			my $str =
			   "if ('$agentclass' && (\${$agentclass\:\:}{new})) {\n" .
			   "   \$agent = new $agentclass(" . %args . ");\n" .
			   "} else {\n" .
			   "   \$agent = {}; bless \$agent, $agentclass;\n" .
			   "}";

			$cpt->reval($str);
			print "AGENT: ", ${$cpt->varglob('agent')}, "\n";

			if ($@) {
				warn "Unsafe agent trapped: $@\n" if $Debug;
				return;
			}
		}
		# store the agent's class in the agent itself:
		${$cpt->varglob($self->{AgentVar})}->{Tom} = $tom;
		bless $self, $class;	# bless wrapper into Agent!
	} else {
		unless ($self = $tom->get_object) {
			no strict;
			# got no object, so create one:
			my $agentclass = $tom->class();
			if (($agentclass) && (${"$agentclass\:\:"}{new})) {
				$self = new $agentclass(%args);
			} else {
				print STDERR "$agentclass\:\:new() not found!\n" if $Debug;
				# we'll just bless $self into the agent's class:
				$self = {};
				bless $self, $agentclass;
			}
		}
		# store the agent's class in the agent itself:
		$self->{Tom} = $tom;
	}
	# this is not true for wrapped agents:
	print "agent's class is: " . ref($self) . "\n" if $Debug > 1;

	return $self;	# blessed into owning agent's class!
}


##
# Inherited methods safe for use by agent objects.
##

sub run {
	my ($self, %args) = @_;

	if (delete $args{Thread}) {
		if ($Agent::thread) {
			return async { _run($self, %args); };
		} else {
			print "Threads not available on this system!\n" if $Debug;
		}
	}
	_run($self, %args);
}

sub store {
	my $self = shift;

	# temporarily remove the Tom container:
	my $tom = delete( $self->{Tom} );

	# insert the agent & store it:
	$tom->insert( $self );
	my $stored = $tom->store();

	# restore the Tom container:
	$self->{Tom} = $tom;

	return $stored;
}

sub identity {
	my $self = shift;

	# temporarily remove the Tom container:
	my $tom = delete( $self->{Tom} );

	# insert the agent & store it:
	$tom->insert( $self );
	my $id = $tom->checksum();
		
	# restore the Tom container:
	$self->{Tom} = $tom;

 	return $id;
}


##
# Private subroutines
##

# searches @INC and '.' for "$name" and "$name.pa".
sub _find_agent {
	my ($name, @dirs) = @_;

	if ($name !~ /.*\.pa$/) { $name .= '.pa'; }	# add extension if needed
	push (@dirs, '.', @INC);			# search local dir & @INC too.
	# adapted from Class::Tom::insert:
	foreach $_ (@dirs) {
		print "Agent: Looking in $_ for $name\n" if $Debug > 1;
		if (-e "$_/$name") {
			print "Agent: Found $name!\n" if $Debug;
			unless ( open(PAFILE, "$_/$name") ) {
				warn "Agent: could not open $_/$name!";
				return;
			}
			local $/ = undef;
			my $code = <PAFILE>;
			close PAFILE;
			return $code;
		}
	}
	return;
}

sub _run {
	my ($self, %args) = @_;
	my $cpt = $self->{Compartment};		# is this a wrapper object?
	if ($cpt) {
		my $var = $self->{AgentVar};	# get the varname
		my $str = $var . '->agent_main(';
		if (%args) {
			# get something to pass into $cpt
			my $d = Dumper(\%args);
			my @d = split(/\n/, $d);
			shift @d; pop @d;
			$str .= join('', @d);
		}
		$str .= ');';
		print STDERR "running $str in Safe\n" if $Debug;
		$cpt->reval($str);
		if ($@) {
			warn "Unsafe agent trapped! $@\n" if $Debug;
			# should probably beef this up some
			return;
		}
	} else {
		eval { $self->agent_main(%args) };
	}
}


##
# Destructor
##

sub DESTROY {
	my $self = shift;
	print ref($self), " agent being destroyed.\n" if $Debug;
}

1;

__END__

=head1 NAME

Agent - the Transportable Agent Perl module

=head1 SYNOPSIS

  use Agent;

  my $a = new Agent( Name => 'path_to_agent.pa', %args );

  $a->run();

=head1 DESCRIPTION

Agent Perl is meant to be a multi-platform interface for writing and using
transportable perl agents.

=over 4

=item A Perl Agent

Is any chunk of Perl code that can accomplish some user-defined objective
by communicating with other agents, and manipulating any data it obtains.

A Perl Agent consists of a knowledge base (variables), a reasoning
procedure (code), and access to one or more languages coupled with
methods of communication.  These languages remain largely undefined, or
rather, user-defined; support for KQML/KIF is under development.

=item Developing An Agent

Note that the developer must devise the reasoning procedure and knowledge
base described above.  Agent Perl does not place any restrictions on what
you may do; it only tries to make the 'doing' part easier.

An agent is written as an inheriting sub-class of I<Agent>.  Each agent's
class should be stored in a '.pa' file (I<p>erl I<a>gent), and must contain
an C<agent_main()> method.  All agents are objects.  See the examples for
more details, and learn how Agent.pm works so you won't step on its toes!

=back

=head1 CONVENTIONS

I<Arguments> to subroutines are passed in hashes unless otherwise noted.

Capital-a I<Agent> refers to C<Agent.pm> unless the context is obvious.
Lowercase I<agent> refers to I<an> agent.

=head1 CONSTRUCTOR

=over 4

=item new()

Creates a new agent object.  You must tell new() where to get
the agent by passing in I<one> of the following arguments (in a hash):

I<Stored>: The agent stored in a Tom object.

I<File>: An IO::Handle (or any subclass) file handle from which the
agent can be read.

I<Name>: The agent's name.  This prompts new to search @INC and './'
for the agent's '.pa' source file.

I<Code>: The agent's source code.

These are listed in order of precedence.  To handle security issues,
new() also groks this argument:

I<Compartment>: A Safe Compartment within which the agent will be
registered, and later executed.  See the C<Safe> pod for details.

Developers should note that these keywords are I<reserved>.  Any additional
arguments are passed to the agent being created.

=back

=head1 METHODS

=over 4

=item store()

Returns the agent object in stringified form, suitable for network
transfer or storage.

=item run()

Executes the agent.  If the I<Thread> argument is passed and your system has
Thread.pm, run() tries to execute the agent in an asynchronous thread via
Thread's async() command (see the Thread pod for more details).  Additional
arguments are passed to the agent being run.

=item identity()

Returns a unique string identifying the agent I<in its present state>.

=back

=head1 SEE ALSO

C<Agent::Message> and C<Agent::Transport> for agent developers.

=head1 AUTHOR

Steve Purkis E<lt>F<spurkis@engsoc.carleton.ca>E<gt>

=head1 COPYRIGHT

Copyright (c) 1997, 1998 Steve Purkis.  All rights reserved.  This package
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 THANKS

James Duncan for the C<Tom> module and I<many> ideas; the people of the 
Perl5-Agents mailing list for their support.

=cut

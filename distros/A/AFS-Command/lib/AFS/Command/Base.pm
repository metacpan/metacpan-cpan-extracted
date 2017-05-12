#
# $Id$
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

package AFS::Command::Base;

require 5.6.0;

use strict;
use English;
use Carp;
use File::Basename qw(basename);
use Date::Format;

use IO::File;
use IO::Pipe;

our $AUTOLOAD	= "";
our $VERSION = '1.99';

our %Carp =
  (
   carp		=> \&Carp::carp,
   croak	=> \&Carp::croak,
  );

sub setCarp {

    my $class = shift;
    my (%args) = @_;

    foreach my $key ( keys %args ) {
	unless ( $Carp{$key} ) {
	    croak("Unsupported argument: '$key'");
	}
	unless ( ref $args{$key} eq 'CODE' ) {
	    croak("Not a code reference: '$args{$key}'");
	}
	$Carp{$key} = $args{$key};
    }

    return AFS::Object->_setCarp(@_);

}

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;

    my $self = {};

    foreach my $key ( qw( localtime noauth localauth encrypt quiet timestamps ) ) {
	$self->{$key}++ if $args{$key};
    }

    # AFS::Command::VOS -> vos
    if ( $args{command} ) {
        my @commands = (split /\s+/,$args{command});
        push (@{$self->{command}},@commands);
    } else {
        @{$self->{command}} = lc((split(/::/,$class))[2]);
    }

    bless $self, $class;

    return $self;

}

sub errors {
    my $self = shift;
    return $self->{errors};
}

sub supportsOperation {
    my $self = shift;
    my $operation = shift;
    return $self->_operations($operation);
}

sub supportsArgument {
    my $self = shift;
    my $operation = shift;
    my $argument = shift;
    return unless $self->_operations($operation);
    return unless $self->_arguments($operation);
    return exists $self->{_arguments}->{$operation}->{$argument};
}

sub _Carp {
    my $self = shift;
    $Carp{carp}->(@_);
}

sub _Croak {
    my $self = shift;
    $Carp{croak}->(@_);
}

sub _operations {

    my $self = shift;
    my $operation = shift;

    my $class = ref $self;

    unless ( $self->{_operations} ) {

	my %operations = ();

	#
	# This hack is necessary to support the offline/online "hidden"
	# vos commands.  These won't show up in the normal help output,
	# so we have to check for them individually.  Since offline and
	# online are implemented as a pair, we can just check one of
	# them, and assume the other is there, too.
	#

	foreach my $type ( qw(default hidden) ) {

	    if ( $type eq 'hidden' ) {
		next unless $self->isa("AFS::Command::VOS");
	    }

	    my $pipe = IO::Pipe->new() || do {
		$self->_Carp("Unable to create pipe: $ERRNO\n");
		return;
	    };

	    my $pid = fork();

	    unless ( defined $pid ) {
		$self->_Carp("Unable to fork: $ERRNO\n");
		return;
	    }

	    if ( $pid == 0 ) {

		STDERR->fdopen( STDOUT->fileno(), "w" ) ||
		  $self->_Croak("Unable to redirect stderr: $ERRNO\n");
		STDOUT->fdopen( $pipe->writer()->fileno(), "w" ) ||
		  $self->_Croak("Unable to redirect stdout: $ERRNO\n");

		if ( $type eq 'default' ) {
		    exec @{$self->{command}}, 'help';
		} else {
		    exec @{$self->{command}}, 'offline', '-help';
		}
		die "Unable to exec @{$self->{command}} help: $ERRNO\n";

	    } else {

		$pipe->reader();

		while ( defined($_ = $pipe->getline()) ) {
		    if ( $type eq 'default' ) {
			next if /Commands are:/;
			my ($command) = split;
			next if $command =~ /^(apropos|help)$/;
			$operations{$command}++;
		    } else {
			if ( /^Usage:/ ) {
			    $operations{offline}++;
			    $operations{online}++;
			}
		    }
		}

	    }

	    unless ( waitpid($pid,0) ) {
		$self->_Carp("Unable to get status of child process ($pid)");
		return;
	    }

	    if ( $? ) {
		$self->_Carp("Error running @{$self->{command}} help.  Unable to configure $class");
		return;
	    }

	}

	$self->{_operations} = \%operations;

    }

    return $self->{_operations}->{$operation};

}

sub _arguments {

    my $self		= shift;
    my $operation 	= shift;

    my $arguments =
      {
       optional		=> {},
       required		=> {},
       aliases		=> {},
      };

    my @command;
    push (@command, @{$self->{command}});

    unless ( $self->_operations($operation) ) {
	$self->_Carp("Unsupported @command operation '$operation'\n");
	return;
    }

    return $self->{_arguments}->{$operation}
      if ref $self->{_arguments}->{$operation} eq 'HASH';

    my $pipe = IO::Pipe->new() || do {
	$self->_Carp("Unable to create pipe: $ERRNO");
	return;
    };

    my $pid = fork();

    my $errors = 0;

    unless ( defined $pid ) {
	$self->_Carp("Unable to fork: $ERRNO");
	return;
    }

    if ( $pid == 0 ) {

	STDERR->fdopen( STDOUT->fileno(), "w" ) ||
	  die "Unable to redirect stderr: $ERRNO\n";
	STDOUT->fdopen( $pipe->writer()->fileno(), "w" ) ||
	  die "Unable to redirect stdout: $ERRNO\n";
	exec @command, $operation, '-help';
	die "Unable to exec @command help $operation: $ERRNO\n";

    } else {

	$pipe->reader();

	while ( <$pipe> ) {

	    if ( /Unrecognized operation '$operation'/ ) {
		$self->_Carp("Unsupported @command operation '$operation'\n");
		$errors++;
		last;
	    }

	    next unless s/^Usage:.*\s+$operation\s+//;

	    while ( $_ ) {
		if ( s/^\[\s*-(\w+?)\s*\]\s*//  ) {
		    $arguments->{optional}->{$1} = 0
		      unless $1 eq 'help'; # Yeah, skip it...
		} elsif ( s/^\[\s*-(\w+?)\s+<[^>]*?>\+\s*]\s*// ) {
		    $arguments->{optional}->{$1} = [];
		} elsif ( s/^\[\s*-(\w+?)\s+<[^>]*?>\s*]\s*// ) {
		    $arguments->{optional}->{$1} = 1;
		} elsif ( s/^\s*-(\w+?)\s+<[^>]*?>\+\s*// ) {
		    $arguments->{required}->{$1} = [];
		} elsif ( s/^\s*-(\w+?)\s+<[^>]*?>\s*// ) {
		    $arguments->{required}->{$1} = 1;
		} elsif ( s/^\s*-(\w+?)\s*// ) {
		    $arguments->{required}->{$1} = 0;
		} else {
		    $self->_Carp("Unable to parse @command help for $operation\n" .
				 "Unrecognized string: '$_'");
		    $errors++;
		    last;
		}
	    }

	    last;

	}

    }

    #
    # XXX -- Hack Alert!!!
    #
    # Because some asshole decided to change the force option to vos
    # release from -f to -force, you can't use the API tranparently
    # with 2 different vos binaries that support the 2 different options.
    #
    # If we need more of these, we can add them, as this let's us
    # alias one argument to another.
    #
    if ( $self->isa("AFS::Command::VOS") && $operation eq 'release' ) {
	if ( exists $arguments->{optional}->{f} ) {
	    $arguments->{aliases}->{force} = 'f';
	} elsif ( exists $arguments->{optional}->{force} ) {
	    $arguments->{aliases}->{f} = 'force';
	}
    }

    unless ( waitpid($pid,0) ) {
	$self->_Carp("Unable to get status of child process ($pid)");
	$errors++;
    }

    if ( $? ) {
	$self->_Carp("Error running @command $operation -help.  Unable to configure @command $operation");
	$errors++;
    }

    return if $errors;
    return $self->{_arguments}->{$operation} = $arguments;

}

sub _save_stderr {

    my $self = shift;

    $self->{olderr} = IO::File->new(">&STDERR") || do {
	$self->_Carp("Unable to dup stderr: $ERRNO");
	return;
    };

    my $command = basename((split /\s+/,@{$self->{command}})[0]);

    $self->{tmpfile} = "/tmp/.$command.$self->{operation}.$$";

    my $newerr = IO::File->new(">$self->{tmpfile}") || do {
	$self->_Carp("Unable to open $self->{tmpfile}: $ERRNO");
	return;
    };

    STDERR->fdopen( $newerr->fileno(), "w" ) || do {
	$self->_Carp("Unable to reopen stderr: $ERRNO");
	return;
    };

    $newerr->close() || do {
	$self->_Carp("Unable to close $self->{tmpfile}: $ERRNO");
	return;
    };

    return 1;

}

sub _restore_stderr {

    my $self = shift;

    STDERR->fdopen( $self->{olderr}->fileno(), "w") || do {
	$self->_Carp("Unable to restore stderr: $ERRNO");
	return;
    };

    $self->{olderr}->close() || do {
	$self->_Carp("Unable to close saved stderr: $ERRNO");
	return;
    };

    delete $self->{olderr};

    my $newerr = IO::File->new($self->{tmpfile}) || do {
	$self->_Carp("Unable to reopen $self->{tmpfile}: $ERRNO");
	return;
    };

    $self->{errors} = "";

    while ( <$newerr> ) {
	$self->{errors} .= $_;
    }

    $newerr->close() || do {
	$self->_Carp("Unable to close $self->{tmpfile}: $ERRNO");
	return;
    };

    unlink($self->{tmpfile}) || do {
	$self->_Carp("Unable to unlink $self->{tmpfile}: $ERRNO");
	return;
    };

    delete $self->{tmpfile};

    return 1;

}

sub _parse_arguments {

    my $self = shift;
    my $class = ref($self);
    my (%args) = @_;

    my $arguments = $self->_arguments($self->{operation});

    unless ( defined $arguments ) {
	$self->_Carp("Unable to obtain arguments for $class->$self->{operation}");
	return;
    }

    $self->{errors} = "";

    $self->{cmds} = [];

    if ( $args{inputfile} ) {

	push( @{$self->{cmds}}, [ 'cat', $args{inputfile} ] );

    } else {

	my @argv = ( @{$self->{command}}, $self->{operation} );

	foreach my $key ( keys %args ) {
	    next unless $arguments->{aliases}->{$key};
	    $args{$arguments->{aliases}->{$key}} = delete $args{$key};
	}

	foreach my $key ( qw( noauth localauth encrypt ) ) {
	    next unless $self->{$key};
	    $args{$key}++ if exists $arguments->{required}->{$key};
	    $args{$key}++ if exists $arguments->{optional}->{$key};
	}

	unless ( $self->{quiet} ) {
	    $args{verbose}++ if exists $arguments->{optional}->{verbose};
	}

	foreach my $type ( qw( required optional ) ) {

	    foreach my $key ( keys %{$arguments->{$type}} ) {

		my $hasvalue = $arguments->{$type}->{$key};

		if ( $type eq 'required' ) {
		    unless ( exists $args{$key} ) {
			$self->_Carp("Required argument '$key' not provided");
			return;
		    }
		} else {
		    next unless exists $args{$key};
		}

		if ( $hasvalue ) {
		    if ( ref $args{$key} eq 'HASH' || ref $args{$key} eq 'ARRAY' ) {
			unless ( ref $hasvalue eq 'ARRAY' ) {
			    $self->_Carp("Invalid argument '$key': can't provide a list of values");
			    return;
			}
			push(@argv,"-$key");
			foreach my $value ( ref $args{$key} eq 'HASH' ? %{$args{$key}} : @{$args{$key}} ) {
			    push(@argv,$value);
			}
		    } else {
			push(@argv,"-$key",$args{$key});
		    }
		} else {
		    push(@argv,"-$key") if $args{$key};
		}

		delete $args{$key};

	    }

	}

	if ( %args ) {
	    $self->_Carp("Unsupported arguments: " . join(' ',sort keys %args));
	    return;
	}

	push( @{$self->{cmds}}, \@argv );

    }

    return 1;

}

sub _exec_cmds {

    my $self = shift;

    my %args = @_;

    my @cmds = @{$self->{cmds}};

    $self->{pids} = {};

    for ( my $index = 0 ; $index <= $#cmds ; $index++ ) {

	my $cmd = $cmds[$index];

	my $pipe = IO::Pipe->new() || do {
	    $self->_Carp("Unable to create pipe: $ERRNO");
	    return;
	};

	my $pid = fork();

	unless ( defined $pid ) {
	    $self->_Carp("Unable to fork: $ERRNO");
	    return;
	}

	if ( $pid == 0 ) {

	    if ( $index == $#cmds &&
		 exists $args{stdout} && $args{stdout} ne 'stdout' ) {
		my $stdout = IO::File->new(">$args{stdout}") ||
		  $self->_Croak("Unable to open $args{stdout}: $ERRNO");
		STDOUT->fdopen( $stdout->fileno(), "w" ) ||
		  $self->_Croak("Unable to redirect stdout: $ERRNO");
	    } else {
		STDOUT->fdopen( $pipe->writer()->fileno(), "w" ) ||
		  $self->_Croak("Unable to redirect stdout: $ERRNO");
	    }

	    if ( exists $args{stderr} && $args{stderr} eq 'stdout' ) {
		STDERR->fdopen( STDOUT->fileno(), "w" ) ||
		  $self->_Croak("Unable to redirect stderr: $ERRNO");
	    }

	    if ( $index == 0 ) {
		if ( exists $args{stdin} && $args{stdin} ne 'stdin' ) {
		    my $stdin = IO::File->new("<$args{stdin}") ||
		      $self->_Croak("Unable to open $args{stdin}: $ERRNO");
		    STDIN->fdopen( $stdin->fileno(), "r" ) ||
		      $self->_Croak("Unable to redirect stdin: $ERRNO");
		}
	    } else {
		STDIN->fdopen( $self->{handle}->fileno(), "r" ) ||
		  $self->_Croak("Unable to redirect stdin: $ERRNO");
	    }

	    $ENV{TZ} = 'GMT' unless $self->{localtime};

	    exec( { $cmd->[0] } @{$cmd} ) ||
	      $self->_Croak("Unable to exec @{$cmd}: $ERRNO");

	}

	$self->{handle} = $pipe->reader();

	$self->{pids}->{$pid} = $cmd;

    }

    return 1;

}

sub _parse_output {

    my $self = shift;

    $self->{errors} = "";

    while ( defined($_ = $self->{handle}->getline()) ) {
	$self->{errors} .= time2str("[%Y-%m-%d %H:%M:%S] ",time,'GMT') if $self->{timestamps};
	$self->{errors} .= $_;
    }

    return 1;

}

sub _reap_cmds {

    my $self = shift;
    my (%args) = @_;

    my $errors = 0;

    $self->{handle}->close() || do {
	$self->_Carp("Unable to close pipe handle: $ERRNO");
	$errors++;
    };

    delete $self->{handle};
    delete $self->{cmds};

    $self->{status} = {};

    my %allowstatus = ();
    if ( $args{allowstatus} ) {
	if ( ref $args{allowstatus} eq 'ARRAY' ) {
	    foreach my $status ( @{$args{allowstatus}} ) {
		$allowstatus{$status}++;
	    }
	} else {
	    $allowstatus{$args{allowstatus}}++;
	}
    }

    foreach my $pid ( keys %{$self->{pids}} ) {

	$self->{status}->{$pid}->{cmd} =
	  join(' ', @{delete $self->{pids}->{$pid}} );

	if ( waitpid($pid,0) ) {

	    $self->{status}->{$pid}->{status} = $?;
	    if ( $? ) {
		if ( %allowstatus ) {
		    $errors++ unless $allowstatus{$? >> 8};
		} else {
		    $errors++;
		}
	    }


	} else {
	    $self->{status}->{$pid}->{status} = undef;
	    $errors++;
	}

    }

    return if $errors;
    return 1;

}

sub AUTOLOAD {

    my $self = shift;
    my (%args) = @_;

    $self->{operation} = $AUTOLOAD;
    $self->{operation} =~ s/.*:://;

    return unless $self->_parse_arguments(%args);

    return unless $self->_exec_cmds( stderr => 'stdout' );

    my $errors = 0;

    $errors++ unless $self->_parse_output();
    $errors++ unless $self->_reap_cmds();

    return if $errors;
    return 1;

}

sub DESTROY {}

1;


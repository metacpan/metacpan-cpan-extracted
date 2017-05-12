#
# $Id$
#
# (c) 2003-2004 Morgan Stanley and Co.
# See ..../src/LICENSE for terms of distribution.
#

package AFS::Command::BOS;

require 5.6.0;

use strict;
use English;

use AFS::Command::Base;
use AFS::Object;
use AFS::Object::BosServer;
use AFS::Object::Instance;

our @ISA = qw(AFS::Command::Base);
our $VERSION = '1.99';

sub getdate {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::BosServer->new();

    $self->{operation} = "getdate";

    my $directory = $args{dir} || '/usr/afs/bin';

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {

	chomp;

	next unless m:File $directory/(\S+) dated ([^,]+),:;

	my $file = AFS::Object->new
	  (
	   file			=> $1,
	   date			=> $2,
	  );

	if ( /\.BAK dated ([^,]+),/ ) {
	    $file->_setAttribute( bak => $1 );
	}

	if ( /\.OLD dated ([^,\.]+)/ ) {
	    $file->_setAttribute( old => $1 );
	}

	$result->_addFile($file);

    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub getlog {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::BosServer->new();

    $self->{operation} = "getlog";

    my $redirect = undef;
    my $redirectname = undef;

    if ( $args{redirect} ) {
	$redirectname = delete $args{redirect};
	$redirect = IO::File->new(">$redirectname") || do {
	    $self->_Carp("Unable to write to $redirectname: $ERRNO");
	    return;
	};
    }

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    my $log = "";

    while ( defined($_ = $self->{handle}->getline()) ) {
	next if /^Fetching log file/;
	if ( $redirect ) {
	    $redirect->print($_);
	} else {
	    $log .= $_;
	}
    }

    if ( $redirect ) {
	$redirect->close()|| do {
	    $self->_Carp("Unable to close $redirectname: $ERRNO");
	    $errors++
	};
	$result->_setAttribute( log => $redirectname );
    } else {
	$result->_setAttribute( log => $log );
    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub getrestart {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::BosServer->new();

    $self->{operation} = "getrestart";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {

	if ( /restarts at (.*)/ || /restarts (never)/ ) {
	    $result->_setAttribute( restart => $1 );
	} elsif ( /binaries at (.*)/ || /binaries (never)/ ) {
	    $result->_setAttribute( binaries => $1 );
	}

    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub listhosts {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::BosServer->new();

    $self->{operation} = "listhosts";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    my @hosts = ();

    while ( defined($_ = $self->{handle}->getline()) ) {

	chomp;

	if ( /Cell name is (\S+)/i ) {
	    $result->_setAttribute( cell => $1 );
	}

	if ( /Host \d+ is (\S+)/i ) {
	    push(@hosts,$1);
	}

    }

    $result->_setAttribute( hosts => \@hosts );

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub listkeys {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::BosServer->new();

    $self->{operation} = "listkeys";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {

	chomp;

	if ( /key (\d+)/ ) {

	    my $key = AFS::Object->new( index => $1 );

	    if ( /has cksum (\d+)/ ) {
		$key->_setAttribute( cksum => $1 );
	    } elsif ( /is \'([^\']+)\'/ ) {
		$key->_setAttribute( value => $1 );
	    }

	    $result->_addKey($key);

	}

	if ( /last changed on (.*)\./ ) {
	    $result->_setAttribute( keyschanged => $1 );
	}

    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

sub listusers {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::BosServer->new();

    $self->{operation} = "listusers";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    while ( defined($_ = $self->{handle}->getline()) ) {

	chomp;

	if ( /^SUsers are: (.*)/ ) {
	    $result->_setAttribute( susers => [split(/\s+/,$1)] );
	}

    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}

#
# XXX -- we might want to provide parsing of the bos salvage output,
# but for now, this is a non-parsed command.
#

# sub salvage {

#     my $self = shift;
#     my (%args) = @_;

#     my $result = AFS::Object::BosServer->new();

#     $self->{operation} = "salvage";

#     return unless $self->_parse_arguments(%args);

#     return unless $self->_save_stderr();

#     my $errors = 0;

#     $errors++ unless $self->_exec_cmds();

#     while ( defined($_ = $self->{handle}->getline()) ) {

	

#     }

#     $errors++ unless $self->_reap_cmds();
#     $errors++ unless $self->_restore_stderr();

#     return if $errors;
#     return $result;

# }

sub status {

    my $self = shift;
    my (%args) = @_;

    my $result = AFS::Object::BosServer->new();

    $self->{operation} = "status";

    return unless $self->_parse_arguments(%args);

    return unless $self->_save_stderr();

    my $errors = 0;

    $errors++ unless $self->_exec_cmds();

    my $instance = undef;

    while ( defined($_ = $self->{handle}->getline()) ) {

	chomp;

	if ( /inappropriate access/ ) {
	    $result->_setAttribute( access => 1 );
	    next;
	}

	if ( /Instance (\S+),/ ) {

	    if ( defined $instance ) {
		$result->_addInstance($instance);
	    }

	    $instance = AFS::Object::Instance->new( instance => $1 );

	    #
	    # This is ugly, since the order and number of these
	    # strings varies.
	    #
	    if ( /\(type is (\S+)\)/ ) {
		$instance->_setAttribute( type => $1 );
	    }

	    if ( /(disabled|temporarily disabled|temporarily enabled),/ ) {
		$instance->_setAttribute( state => $1 );
	    }

	    if ( /stopped for too many errors/ ) {
		$instance->_setAttribute( errorstop => 1 );
	    }

	    if ( /has core file/ ) {
		$instance->_setAttribute( core => 1 );
	    }

	    if ( /currently (.*)\.$/ ) {
		$instance->_setAttribute( status => $1 );
	    }

	}

	if ( /Auxiliary status is: (.*)\.$/ ) {
	    $instance->_setAttribute( auxiliary => $1 );
	}

	if ( /Process last started at (.*) \((\d+) proc starts\)/ ) {
	    $instance->_setAttribute
	      (
	       startdate		=> $1,
	       startcount		=> $2,
	      );
	}

	if ( /Last exit at (.*)/ ) {
	    $instance->_setAttribute( exitdate => $1 );
	}

	if ( /Last error exit at ([^,]+),/ ) {

	    $instance->_setAttribute( errorexitdate => $1 );

	    if ( /due to shutdown request/ ) {
		$instance->_setAttribute( errorexitdue => 'shutdown' );
	    }

	    if ( /due to signal (\d+)/ ) {
		$instance->_setAttribute
		  (
		   errorexitdue 	=> 'signal',
		   errorexitsignal	=> $1,
		  );
	    }

	    if ( /by exiting with code (\d+)/ ) {
		$instance->_setAttribute
		  (
		   errorexitdue 	=> 'code',
		   errorexitcode	=> $1,
		  );
	    }

	}

	if ( /Command\s+(\d+)\s+is\s+\'(.*)\'/ ) {
	    my $command = AFS::Object->new
	      (
	       index			=> $1,
	       command			=> $2,
	      );
	    $instance->_addCommand($command);
	}

	if ( /Notifier\s+is\s+\'(.*)\'/ ) {
	    $instance->_setAttribute( notifier => $1 );
	}

    }

    if ( defined $instance ) {
	$result->_addInstance($instance);
    }

    $errors++ unless $self->_reap_cmds();
    $errors++ unless $self->_restore_stderr();

    return if $errors;
    return $result;

}


1;

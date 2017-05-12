package Apache::Voodoo::Debug::FirePHP;

$VERSION = "3.0200";

use strict;
use warnings;
no warnings 'uninitialized';

use base("Apache::Voodoo::Debug::Common");

use JSON::DWIW;

use constant {
	DEBUG     => 'LOG',
	INFO      => 'INFO',
	WARN      => 'WARN',
	ERROR     => 'ERROR',
	DUMP      => 'DUMP',
	TRACE     => 'TRACE',
	EXCEPTION => 'EXCEPTION',
	TABLE     => 'TABLE'
};

use constant GROUP_START => 'GROUP_START';
use constant GROUP_END   => 'GROUP_END';

use constant WF_VERSION    => "2.00";
use constant WF_PROTOCOL   => 'http://meta.wildfirehq.org/Protocol/JsonStream/0.2';
use constant WF_PLUGIN     => 'http://meta.firephp.org/Wildfire/Plugin/FirePHP/Library-FirePHPCore/'.WF_VERSION;
use constant WF_STRUCTURE1 => 'http://meta.firephp.org/Wildfire/Structure/FirePHP/FirebugConsole/0.1';
use constant WF_STRUCTURE2 => 'http://meta.firephp.org/Wildfire/Structure/FirePHP/Dump/0.1';

use constant BLOCK_LENGTH => 5000;

sub new {
	my $class = shift;
	my $id    = shift;
	my $conf  = shift;

	my $self = {};
	bless $self,$class;

	$self->{json} = JSON::DWIW->new({bad_char_policy => 'convert'});

	$self->{setHeader} = sub { return; };
	$self->{userAgent} = sub { return; };

	my @flags = qw(debug info warn error exception table trace);

	$self->{enabled} = 0;
	if ($conf eq "1" || (ref($conf) eq "HASH" && $conf->{all})) {
		$self->{conf}->{LOG}       = 1;
		$self->{conf}->{INFO}      = 1;
		$self->{conf}->{WARN}      = 1;
		$self->{conf}->{ERROR}     = 1;
		$self->{conf}->{DUMP}      = 1;
		$self->{conf}->{TRACE}     = 1;
		$self->{conf}->{EXCEPTION} = 1;
		$self->{conf}->{TABLE}     = 1;
		$self->{conf}->{GROUP_START} = 1;
		$self->{conf}->{GROUP_END}   = 1;

		$self->{enabled} = 1;
	}
	elsif (ref($conf) eq "HASH") {
		$self->{conf}->{LOG}       = 1 if $conf->{debug};
		$self->{conf}->{INFO}      = 1 if $conf->{info};
		$self->{conf}->{WARN}      = 1 if $conf->{warn};
		$self->{conf}->{ERROR}     = 1 if $conf->{error};
		$self->{conf}->{DUMP}      = 1 if $conf->{dump};
		$self->{conf}->{TRACE}     = 1 if $conf->{trace};
		$self->{conf}->{EXCEPTION} = 1 if $conf->{exception};
		$self->{conf}->{TABLE}     = 1 if $conf->{table};

		if (scalar keys %{$self->{'conf'}}) {
			$self->{enabled} = 1;
			$self->{conf}->{GROUP_START} = 1;
			$self->{conf}->{GROUP_END}   = 1;
		}
	}

	return $self;
}

sub init {
	my $self = shift;

	$self->{mp} = shift;

	$self->{enabled} = 0;

	return unless $self->_detectClientExtension();

	$self->{enable} = $self->{conf};
	$self->{messageIndex} = 1;
}

sub shutdown { return; }

sub setProcessorUrl {
	my $self = shift;
	my $URL  = shift;

	$self->setHeader('X-FirePHP-ProcessorURL' => $URL);
}

sub setRendererUrl {
	my $self = shift;
	my $URL  = shift;

	$self->setHeader('X-FirePHP-RendererURL' => $URL);
}

sub debug     { return $_[0]->_fb($_[1], $_[2], DEBUG);     }
sub info      { return $_[0]->_fb($_[1], $_[2], INFO);      }
sub warn      { return $_[0]->_fb($_[1], $_[2], WARN);      }
sub error     { return $_[0]->_fb($_[1], $_[2], ERROR);     }
sub exception { return $_[0]->_fb($_[1], $_[2], EXCEPTION); }
sub trace     { return $_[0]->_fb($_[1], undef, TRACE);     }
sub table     { return $_[0]->_fb($_[1], $_[2], TABLE);     }

sub _group    { return $_[0]->_fb($_[1], undef, GROUP_START); }
sub _groupEnd { return $_[0]->_fb(undef, undef, GROUP_END);   }

#
# At some point in the future we might push this info out
# through FirePHP, but not right now.
#
sub mark          { return; }
sub return_data   { return; }
sub session_id    { return; }
sub url           { return; }
sub status        { return; }
sub params        { return; }
sub template_conf { return; }
sub session       { return; }

# This is here for API compliance.
# FirePHP has no finalize step
sub finalize { return (); }

#
# Relies on having a callback setup in the constructor that returns the user agent
#
sub _detectClientExtension {
	my $self = shift;

	my $useragent = $self->{mp}->header_in('User-Agent');

	if ($useragent =~ /\bFirePHP\/([.\d]+)/ && $self->_compareVersion($1,'0.0.6')) {
		return 1;
	}
	else {
		return 0;
	}
}

sub _compareVersion {
	my $self   = shift;

	my @f = split(/\./,shift);
	my @s = split(/\./,shift);

	my $c = (scalar(@f) > scalar(@s))?scalar(@f):scalar(@s);

	for (my $i=0; $i < $c; $i++) {
		if ($f[$i] < $s[$i] || (!defined($f[$i]) && defined($s[$i]))) {
			return 0;
		}
		elsif ($f[$i] > $s[$i] || (defined($f[$i]) && !defined($s[$i]))) {
			return 1;
		}
	}
	return 1;
}

sub _fb {
	my $self = shift;

	my $Label  = shift;
	my $Object = shift;
	my $Type   = shift;

	return unless $self->{enable}->{$Type};

	unless (defined($Object) || $Type eq GROUP_START) {
		$Object = $Label;
		$Label = undef;
	}

	my %meta = ();

	if ($Type eq EXCEPTION || $Type eq TRACE) {
		my @trace = $self->stack_trace(1);

		my $t = shift @trace;

		$meta{'File'} = $t->{class}.$t->{type}.$t->{function};
		$meta{'Line'} = $t->{line};

		$Object = {
			'Class'   => $t->{class},
			'Type'    => $t->{type},
			'Function'=> $t->{function},
			'Message' => $Object,
			'File'    => $t->{file},
			'Line'    => $t->{line},
			'Args'    => $t->{args},
			'Trace'   => \@trace
		};
	}
	else {
		my @trace = $self->stack_trace(1);

		$meta{'File'} = $trace[0]->{class}.$trace[0]->{type}.$trace[0]->{function};
		$meta{'Line'} = $trace[0]->{line};
	}

	my $structure_index = 1;
	if ($self->{messageIndex} == 1) {
		$self->setHeader('X-Wf-Protocol-1',WF_PROTOCOL);
		$self->setHeader('X-Wf-1-Plugin-1',WF_PLUGIN);

		if ($Type eq DUMP) {
			$structure_index = 2;
			$self->setHeader('X-Wf-1-Structure-2',WF_STRUCTURE2);
		}
		else {
			$self->setHeader('X-Wf-1-Structure-1',WF_STRUCTURE1);
		}
	}

	my $msg;
	if ($Type eq DUMP) {
		$msg = '{"'.$Label.'":'.$self->jsonEncode($Object).'}';
	}
	else {
		$meta{'Type'}  = $Type;
		$meta{'Label'} = $Label;

		$msg = '['.$self->jsonEncode(\%meta).','.$self->jsonEncode($Object).']';
	}

	# FirePHP wants the number of bytes, not characters.  So we can't use length() here, a 2 or 3 byte
	# character counts as 1 as far as length is concerned.
	my $l = length(unpack('b*',$msg))/8;

	if ($l < BLOCK_LENGTH) {
		# The message can be send in one block
		$self->setHeader(
			'X-Wf-1-'.$structure_index.'-1-'.$self->{'messageIndex'},
			$l . '|' . $msg . '|'
		);

		$self->{'messageIndex'}++;
	}
	else {
		# Message needs to be split into multiple parts
		my $c = ($l % BLOCK_LENGTH)?int($l/BLOCK_LENGTH)+1:$l/BLOCK_LENGTH;

		foreach (my $i=0; $i < $c; $i++) {
			my $part = substr($msg, $i*BLOCK_LENGTH, BLOCK_LENGTH);

			my $v;
			# length prefix on the first part
			$v .= $l if ($i==0);

			# the data
			$v .= '|'.$part.'|';

			# \ on the end of the line, on all but the last part
			$v .= '\\' if ($i < ($c-1));

			$self->setHeader('X-Wf-1-'.$structure_index.'-1-'.$self->{'messageIndex'}, $v);

			$self->{'messageIndex'}++;

			if ($self->{'messageIndex'} > 99999) {
				#throw new Exception('Maximum number (99,999) of messages reached!');
			}
		}
	}

	#$self->setHeader('X-Wf-1-Index',$self->{'messageIndex'}-1);

	return 1;
}

sub setHeader() {
	my $self  = shift;
	my $name  = shift;
	my $value = shift;

	$self->{mp}->header_out($name,$value);
}

sub jsonEncode {
	my $self   = shift;
	my $Object = shift;

	return $self->{'json'}->to_json($Object);
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################

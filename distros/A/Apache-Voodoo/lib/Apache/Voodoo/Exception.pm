###########################################################################
#
# Exception class definitions for Apache Voodoo.
#
###########################################################################
package Apache::Voodoo::Exception;

$VERSION = "3.0200";

use strict;
use warnings;

use Exception::Class (
	'Apache::Voodoo::Exception',

	'Apache::Voodoo::Exception::Compilation' => {
		isa => 'Apache::Voodoo::Exception',
		description => 'Module compilation failed',
		fields => ['module']
	},
	'Apache::Voodoo::Exception::RunTime' => {
		isa => 'Apache::Voodoo::Exception',
		description => 'Run time exception from perl'
	},
	'Apache::Voodoo::Exception::RunTime::Thrown' => {
		isa => 'Apache::Voodoo::Exception::RunTime',
		description => 'Module threw an exception'
	},
	'Apache::Voodoo::Exception::RunTime::BadConfig' => {
		isa => 'Apache::Voodoo::Exception::RunTime',
		description => "Configuration Error",
	},
	'Apache::Voodoo::Exception::RunTime::BadCommand' => {
		isa => 'Apache::Voodoo::Exception::RunTime',
		description => "Controller returned an unsupported command",
		fields => ['module', 'method', 'command']
	},
	'Apache::Voodoo::Exception::RunTime::BadReturn' => {
		isa => 'Apache::Voodoo::Exception::RunTime',
		description => "Controller didn't return a hash reference",
		fields => ['module', 'method', 'data']
	},
	'Apache::Voodoo::Exception::ParamParse' => {
		isa => 'Apache::Voodoo::Exception',
		description => 'Parameters failed to parse'
	},
	'Apache::Voodoo::Exception::DBIConnect' => {
		isa => 'Apache::Voodoo::Exception',
		description => 'Failed to connect to the database'
	},
	'Apache::Voodoo::Exception::Application' => {
		isa => 'Apache::Voodoo::Exception',
		description => 'Application Error'
	},
	'Apache::Voodoo::Exception::Application::SessionTimeout' => {
		isa => 'Apache::Voodoo::Exception::Application',
		description => "Session has expired",
		fields => ['target']
	},
	'Apache::Voodoo::Exception::Application::Redirect' => {
		isa => 'Apache::Voodoo::Exception::Application',
		description => "Controller redirected the request to another location",
		fields => ['target']
	},
	'Apache::Voodoo::Exception::Application::DisplayError' => {
		isa => 'Apache::Voodoo::Exception::Application',
		description => "Controller request the display of an error message",
		fields => ['code','target','detail']
	},
	'Apache::Voodoo::Exception::Application::AccessDenied' => {
		isa => 'Apache::Voodoo::Exception::Application',
		description => "Access to the requested resource has been denied",
		fields => ['target','detail']
	},
	'Apache::Voodoo::Exception::Application::Unauthorized' => {
		isa => 'Apache::Voodoo::Exception::Application',
		description => "Access to the requested resource has been denied"
	},
	'Apache::Voodoo::Exception::Application::RawData' => {
		isa => 'Apache::Voodoo::Exception::Application',
		description => "Controller returned a raw data stream",
		fields => ['headers','content_type','data']
	},
);

Apache::Voodoo::Exception::RunTime->Trace(1);
Apache::Voodoo::Exception::RunTime->NoRefs(0);

sub parse_stack_trace {
	my $trace = shift;

	unless (ref($trace) eq "Devel::StackTrace") {
		return [];
	}

	my @trace;
	my $i = 1;
	while (my $frame = $trace->frame($i++)) {
		last if ($frame->package =~ /^Apache::Voodoo::Engine/);
		next if ($frame->package =~ /^Apache::Voodoo/);
		next if ($frame->package =~ /(eval)/);

		my $nf = $trace->frame($i);
		my $subroutine;
		my @args;
		if ($nf) {
			$subroutine = $nf->subroutine;
			@args       = $nf->args;
		}

		my $f = {
			'class'    => $frame->package,
			'function' => $subroutine || '',
			'file'     => $frame->filename,
			'line'     => $frame->line,
		};
		$f->{'function'} =~ s/^$f->{'class'}:://;

		# if the first item is a reference to same class, then this was a method call
		if (ref($args[0]) eq $f->{'class'}) {
			shift @args;
			$f->{'type'} = '->';
		}
		else {
			$f->{'type'} = '::';
		}
		$f->{'args'} = join(",",@args);

		push(@trace,$f);

	}
	return \@trace;
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

################################################################################
#
# Apache::Voodoo::Debug::Common
#
# Base class for all debugging plugins
#
################################################################################
package Apache::Voodoo::Debug::Common;

$VERSION = "3.0200";

use strict;
use warnings;

use Devel::StackTrace;

sub new {
	my $class = shift;

	my $self = {};

	bless($self,$class);

	return $self;
}

sub bootstrapped { return; }

sub init      { return; }
sub shutdown  { return; }
sub debug     { return; }
sub info      { return; }
sub warn      { return; }
sub error     { return; }
sub exception { return; }
sub trace     { return; }
sub table     { return; }

sub mark          { return; }
sub return_data   { return; }
sub session_id    { return; }
sub url           { return; }
sub status        { return; }
sub params        { return; }
sub template_conf { return; }
sub session       { return; }

sub finalize { return (); }

sub stack_trace {
	my $self = shift;
	my $full = shift;

	my @trace;
	my $i = 1;

	my $st = Devel::StackTrace->new();
	while (my $frame = $st->frame($i++)) {
		last if ($frame->package =~ /^Apache::Voodoo::Engine/);
		next if ($frame->package =~ /^Apache::Voodoo/);
		next if ($frame->package =~ /(eval)/);

		my $f = {
			'class'    => $frame->package,
			'function' => defined($st->frame($i))?$st->frame($i)->subroutine:'',
			'file'     => $frame->filename,
			'line'     => $frame->line,
		};
		$f->{'function'} =~ s/^$f->{'class'}:://;

		my @a = defined($st->frame($i))?$st->frame($i)->args:'';

		# if the first item is a reference to same class, then this was a method call
		if (ref($a[0]) eq $f->{'class'}) {
			shift @a;
			$f->{'type'} = '->';
		}
		else {
			$f->{'type'} = '::';
		}
		$f->{'instruction'} = $f->{'class'}.$f->{'type'}.$f->{'function'};

		push(@trace,$f);

		if ($full) {
			$f->{'args'} = \@a;
		}
	}
	return @trace;
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

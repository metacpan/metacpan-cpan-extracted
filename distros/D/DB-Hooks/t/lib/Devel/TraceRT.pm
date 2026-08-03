package Devel::TraceRT;



BEGIN {
	$DB::dbg //=  __PACKAGE__;
	push @ISA, 'Devel::DebugHooks';
}

sub import {
	my $self =  shift;

	$self->SUPER::import( @_ );
}

sub trace_load {
	my $self =  shift;

	print $self->SUPER::trace_load( @_ );
}

sub trace_subs {
	my $self =  shift;

	print $self->SUPER::trace_subs( @_ );
}

sub trace_returns {
	my $self =  shift;

	print $self->SUPER::trace_returns( @_ );
}


use Devel::DebugHooks();
1;

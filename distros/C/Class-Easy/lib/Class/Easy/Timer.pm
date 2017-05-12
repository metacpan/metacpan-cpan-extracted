package Class::Easy::Timer;
# $Id: Timer.pm,v 1.3 2009/07/20 18:00:10 apla Exp $

use Class::Easy::Import;
use Class::Easy::Log ();

use Time::HiRes qw(gettimeofday tv_interval);

sub new {
	my $class = shift;
	
	my $logger = Class::Easy::Log::logger ('default');
	
	if (ref $_[-1] eq 'Class::Easy::Log') {
		$logger = pop @_;
	}
	
	my $msg   = join (' ', @_) || '';
	
	return bless [], $class
		unless $logger->{tied};
	
	my $t = [gettimeofday];
	
	bless [$msg, $t, $t, undef, $logger], $class;
}

sub lap {
	my $self = shift;
	my $msg  = shift || '';
	
	return 0
		unless $self->[4]->{tied};
	
	my $interval = tv_interval ($self->[1]);
	
	my $caller1  = [caller (1)];
	my $caller0  = [caller];

	Class::Easy::Log::_wrapper (
		$self->[4]->{category}, $self->[4], $caller1, $caller0,
		"$self->[0]: " . $interval*1000 . 'ms'
	);
	
	$self->[0] = $msg;
	
	$self->[1] = [gettimeofday];
	
	return $interval;
	
}

sub end {
	my $self = shift;
	
	return 0
		unless $self->[4]->{tied};

	my $interval = tv_interval ($self->[1]);
	
	$self->[3] = $interval;
	
	my $caller1  = [caller (1)];
	my $caller0  = [caller];

	Class::Easy::Log::_wrapper (
		$self->[4]->{category}, $self->[4], $caller1, $caller0,
		"$self->[0]: " . $interval*1000 . 'ms'
	);
	
	return $interval;
}

sub total {
	my $self = shift;
	
	return 0
		unless $self->[4]->{tied};

	return $self->[3]
		unless $self->[2];
	
	my $interval = tv_interval ($self->[2], $self->[1]) + $self->[3];

	my $caller1  = [caller (1)];
	my $caller0  = [caller];

	Class::Easy::Log::_wrapper (
		$self->[4]->{category}, $self->[4], $caller1, $caller0,
		"total time: " . $interval*1000 . 'ms'
	);
	
	return $interval;
}


1;

=head1 NAME

Class::Easy::Timer - really easy timer

=head1 ABSTRACT

=head1 SYNOPSIS

SYNOPSIS

	use Class::Easy;
	
	# timer doesn't run without properly configured logger
	logger ('default')->appender (*STDERR);

	$t = timer ('sleep one second');

	sleep (1);

	my $interval = $t->lap ('one more second'); # $interval == 1

	warn "your system have bad timer: 1s = ${interval}s"
		if $interval < 1;

	sleep (1);

	$interval = $t->end; # $interval == 1

	warn "your system have bad timer: 1s = ${interval}s"
		if $interval < 1;

	$interval = $t->total; # $interval == 2
	

=head1 METHODS

=head2 new

create timer, start new lap and return timer object

=cut

=head2 lap

get lap duration and start a new lap

=cut

=head2 end

get duration for last lap

=cut

=head2 total

get duration between timer creation and end call

=cut

=head1 AUTHOR

Ivan Baktsheev, C<< <apla at the-singlers.us> >>

=head1 BUGS

Please report any bugs or feature requests to my email address,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Easy>. 
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT



=head1 ACKNOWLEDGEMENTS



=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 Ivan Baktsheev

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

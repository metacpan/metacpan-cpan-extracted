package Crypt::Chimera::World;

use strict;
use vars qw(@ISA);
use Data::Dumper;
use Crypt::Chimera::Object;

@ISA = qw(Crypt::Chimera::Object);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	die "No name for world" unless $self->{Name};
	$self->{Round} = 0;
	$self->{Verbose} = 5 unless exists $self->{Verbose};

	$self->display(1, "new world, verbosity " . $self->{Verbose}, "");

	return $self;
}

sub register {
	my $self = shift;
	push(@{ $self->{Users} }, @_);
}

sub init {
	my $self = shift;
	return map { $_->init(@_) } @{ $self->{Users} };
}

sub fini {
	my $self = shift;
	return map { $_->fini(@_) } @{ $self->{Users} };
}

sub round {
	my $self = shift;
	$self->display(1, "round", $self->{Round});
	my @out = map { $_->round(@_) } @{ $self->{Users} };
	map { $_->clean } @{ $self->{Users} };
	$self->{Round} = $self->{Round} + 1;
	return @out;
}

sub event {
	my $self = shift;
	my $event = shift;
	$event->{Round} = $self->{Round};
	return map { $_->event($event) } @{ $self->{Users} };
}

sub run {
	my $self = shift;
	die "No Rounds in world" unless $self->{Rounds};

	$self->init;

	foreach (1..$self->{Rounds}) {
		$self->round;
	}

	$self->fini;
}

1;

package Aion::Emitter;
# Диспетчер 

use common::sense;

our $VERSION = "0.1.0";

use Aion::Pleroma;

use Aion;

use config {
	INI => 'etc/annotation/listen.ann',
	EVENT => {},
};

# Путь к собранным из аннотаций методам
has ini => (is => 'ro', isa => Str, default => INI);

# Список слушателей
has event => (is => 'ro', isa => HashRef[ArrayRef[Dict[pkg => Str, sub => Str, line => Nat, nice => Option[Num], remark => Option[Str]]]], default => sub {
	my ($self) = @_;
	my %event = %{EVENT()};
	
	if(defined $self->ini and -e $self->ini) {
		open my $f, "<:utf8", $self->ini or die "Not open ${\$self->ini}";
		while(<$f>) {
			close($f), die "${\$self->ini}:$. corrupt!" unless /^([\w:]+)#(\w*),(\d+)=(?:(-?\d+(?:\.\d+)?)\s+)?([a-z][\w:]*(?:#[\w.:-]+)?)(?:\s+(.*?))??\s*$/i;
			my ($pkg, $sub, $line, $nice, $evt, $remark) = ($1, $2, $3, $4, $5, $6);
			push @{$event{$evt}}, {
				pkg => $pkg,
				sub => $sub,
				line => $line,
				$nice? (nice => $nice): (),
				$remark ne ''? (remark => $remark): (),
			};
		}
		close $f;
	}

	for my $listens (values %event) {
		@$listens = sort {
			$a->{nice} <=> $b->{nice}
			or $a->{pkg} cmp $b->{pkg}
			or $a->{sub} cmp $b->{sub}
		} @$listens;
	}
	
	\%event
});

# Плерома
has pleroma => (is => 'ro', isa => 'Aion::Pleroma', eon => 1);

# Излучить
sub emit {
	my ($self, $event, $key) = @_;
	
	my $listeners = $self->event->{defined($key)? "${\ref $event}#$key": ref $event};
	return $self unless $listeners;
	
	for my $listener_bag (@$listeners) {
		my ($pkg, $sub) = @$listener_bag{qw/pkg sub/};
		my $listener = $self->pleroma->get($pkg) // $self->pleroma->autoware($pkg)->resolve($pkg);
		$listener->$sub($event);
	}
	
	$self
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Emitter - event dispatcher

=head1 VERSION

0.1.0

=head1 SYNOPSIS

File lib/Event/BallEvent.pm:

	package Event::BallEvent;
	
	use Aion;
	
	has radius => (is => 'rw', isa => Num);
	has weight => (is => 'rw', isa => Num);
	
	1;

File lib/Listener/RadiusListener.pm:

	package Listener::RadiusListener;
	
	use Aion;
	
	#@listen Event::BallEvent
	sub listen {
		my ($self, $event) = @_;
		
		$event->radius(10);
	}
	
	1;

File lib/Listener/WeightListener.pm:

	package Listener::WeightListener;
	
	use Aion;
	
	#@listen Event::BallEvent
	sub listen {
		my ($self, $event) = @_;
		
		$event->weight(12);
	}
	
	#@listen Event::BallEvent#mini „Minimize version”
	sub minimize {
		my ($self, $event) = @_;
		
		$event->weight(3);
	}
	
	1;

File etc/annotation/listen.ann:

	Listener::RadiusListener#listen,6=Event::BallEvent
	Listener::WeightListener#listen,6=Event::BallEvent
	Listener::WeightListener#minimize,6=Event::BallEvent#mini „Minimize version”



	use lib 'lib';
	
	use Aion::Emitter;
	use Event::BallEvent;
	
	my $emitter = Aion::Emitter->new;
	my $ballEvent = Event::BallEvent->new;
	
	$emitter->emit($ballEvent);
	
	$ballEvent->radius # -> 10
	$ballEvent->weight # -> 12
	
	$ballEvent->radius(0);
	
	$emitter->emit($ballEvent, "mini");
	
	$ballEvent->weight # -> 3
	$ballEvent->radius # -> 0

=head1 DESCRIPTION

This event dispatcher implements the B<Event Dispatcher> pattern in which an event is defined by the class of the event object (event).

The listener is registered as an aeon in the pleroma and will always be represented by one object.

The event processing method is marked with the C<#@listen> annotation.

=head1 SUBROUTINES

=head2 emit ($event, [$key])

Emits an event: calls all listeners associated with the C<$event> event.

The additional parameter C<$key> allows you to specify a qualifying event. Imagine that we have many controllers and we want to emit an event not for all, but for each specific controller. Writing a class that extends the request class for each controller is wasteful.

C<$key> can contain letters, numbers, underscores, dashes, colons and periods.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Emitter module is copyright (c) 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.

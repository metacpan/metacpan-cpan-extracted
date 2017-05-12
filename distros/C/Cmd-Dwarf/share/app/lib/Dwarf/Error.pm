package Dwarf::Error;
use Dwarf::Pragma;
use Dwarf::Message::Error;

use overload '""' => \&stringify;

use Dwarf::Accessor {
	rw => [qw/autoflush messages/],
};

sub new {
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = bless {
		autoflush => 0,
		messages  => [],
		@_
	}, $class;
	return $self;
}

sub message { $_[0]->messages->[0] }
sub body    { $_[0]->message ? $_[0]->message->body : [] }

sub throw {
	my $self = shift;

	my $m = Dwarf::Message::Error->new;
	$m->data([@_]);

	if ($self->autoflush) {
		$self->{messages} = [$m];
		$self->flush;
	} else {
		push @{ $self->{messages} }, $m;
	}

	return $self;
}

sub flush {
	my $self = shift;
	if (@{ $self->messages }) {
		die $self;
	}
}

sub stringify {
	my $self = shift;
	return join "\n", @{ $self->messages };
}

1;

package Amethyst;

use strict;
use warnings;
use vars qw(@ISA $VERSION);
use Exporter;
use POE;
use Amethyst::Connection;

$VERSION = '1.00';
@ISA = qw(Exporter);

sub new {
	my $class = shift;
	my $args = ($#_ == 0) ? { %{ (shift) } } : { @_ };

	my %states = map { $_ => "handler_$_" } qw(
					_start _stop _child signal
					add_connection register_connection connect
					add_brain think
					);
	POE::Session->create(
			package_states	=> [ $class => \%states ],
			args			=> [ $args ],
			);
}

sub handler__start {
	my ($kernel, $session, $heap, $args) = @_[KERNEL, SESSION, HEAP, ARG0];
	$heap->{Args} = $args;
	my $name = $args->{Name} || 'amethyst';
	$kernel->alias_set($name);

	print STDERR "Starting Amethyst '$name'\n";

	$heap->{Connections} = { };
	$heap->{Brains} = { };

	$kernel->sig('INT', 'signal');
	$kernel->sig('TERM', 'signal');
}

sub handler_signal {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	my $signame = $_[ARG0];
	print STDERR "Exiting on signal $signame\n";
	exit;
}

sub handler__stop {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
}

sub handler__child {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
}

sub handler_register_connection {
	my ($kernel, $session, $sender, $heap, $name) =
					@_[KERNEL, SESSION, SENDER, HEAP, ARG0];
	die "No name for connection $sender\n" unless $name;
	$heap->{Connections}->{$name} = $sender->ID;
	print STDERR "Registered connection $name as " . $sender->ID . "\n";
}

sub handler_add_connection {
	my ($kernel, $session, $heap, $package, $args)
			= @_[KERNEL, SESSION, HEAP, ARG0, ARG1];
	eval qq{ require $package; };
	die $@ if $@;
	$package->new($args);
}

# This no longer creates a POE::Session
sub handler_add_brain {
	my ($kernel, $session, $heap, $package, $args)
			= @_[KERNEL, SESSION, HEAP, ARG0, ARG1];
	my $name = $args->{Name} || $package;
	my $priority = $args->{Priority} || 1;

	eval qq{ require $package; };
	if ($@) {
		print STDERR "Amethyst: Failed to add brain $name ($package)\n";
		$heap->{BrainsFailed}->{$name} = 1;
	}
	else {
		my $brain = $package->new($args);
		$heap->{Brains}->{$name} = [ $brain, $name, $priority, ];
		$brain->init();
	}
}

sub handler_connect {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];

	print STDERR "Amethyst: connecting\n";

	unless (%{ $heap->{Brains} }) {
		print STDERR "Amethyst: Warning: No brains!\n";
	}

	foreach (values %{$heap->{Connections}}) {
		print STDERR "Amethyst: Connecting $_\n";
		$kernel->post($_, 'connect');
	}
}

sub handler_think {
	my ($kernel, $session, $heap, $message, $brains, @args) =
			@_[KERNEL, SESSION, HEAP, ARG0 .. $#_];

	my @brains = $brains ? @$brains : keys %{$heap->{Brains}};

	foreach my $name (@brains) {
		if ($heap->{BrainsFailed}->{$name}) {
			print STDERR "Amethyst: Cannot think in brain $name: " .
							"it failed to load at startup\n";
			next;
		}
		my $brain = $heap->{Brains}->{$name};
		if ($heap->{BrainsFailed}->{$name}) {
			print STDERR "Amethyst: Cannot think in brain $name: " .
							"no such brain!\n";
			next;
		}
		last if $brain->[0]->think($message, @args);
	}
}

1;

__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Amethyst - Perl extension for blah blah blah

=head1 SYNOPSIS

	use POE;
	use Amethyst;
	new Amethyst;
	$poe_kernel->post('amethyst', 'add_brain',
			'Amethyst::Brain::Infobot', \%infobot_params);
	$poe_kernel->post('amethyst', 'add_brain',
			'Amethyst::Brain::Eliza', \%eliza_params);
	$poe_kernel->post('amethyst', 'add_connection',
			'Amethyst::Connection::IRC', \%irc_params);
	$poe_kernel->post('amethyst', 'connect');
	$poe_kernel->run;

=head1 DESCRIPTION

Amethyst is a bot core capable of handling parsing and routing
of messages between connections and brains. Amethyst can handle
an arbitrary number of connections of arbitrary types (given an
appropriate module in Amethyst::Connection::*), routing these messages
fairly arbitrarily through multiple processing cores (brains, live
in Amethyst::Brain::*), and responding to these messages on other
arbitrary connections.

The included script example.pl gives an example of the usage of
the script.

=head2 EXPORT

Nothing.

=head1 AUTHOR

Shevek, E<lt>cpan@anarres.orgE<gt>

=head1 SEE ALSO

L<perl>, L<POE>.

=cut


package Amethyst::Brain::Infobot;

use strict;
use vars qw(@ISA);
use POE;
use Amethyst::Brain;

@ISA = qw(Amethyst::Brain);

sub init {
	my $self = shift;

	my @modules = ();

	foreach my $name (@{$self->{Modules}}) {
		print STDERR "Loading module $name\n";
		my $class = __PACKAGE__ . "::Module::" . $name;
		eval qq{ require $class; };
		if ($@) {
			print STDERR "Amethyst: Failed to load Infobot module " .
					"$class: $@\n";
			next;
		}

		my $module = $class->new(
					Infobot	=> $self,
				);
		push(@modules, $module);
		$module->init;
	}

	$self->{Modules} = \@modules;
}

sub think {
	my ($self, $message, @args) = @_;

MODULE:
	{
		foreach my $module (@{$self->{Modules}}) {
			return 1 if $module->process($message);
		}
	}
}

1;

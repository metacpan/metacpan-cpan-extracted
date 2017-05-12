package Amethyst::Brain::Markov;

use strict;
use vars qw(@ISA);
use URI;
use Amethyst::Store;
use Amethyst::Brain;
use Amethyst::Message;
use Algorithm::MarkovChain;

@ISA = qw(Amethyst::Brain);

BEGIN {
	use Data::Dumper;
	print Dumper(\%INC);
}

sub init {
	my $self = shift;
	$self->{Store} = new Amethyst::Store(
					Source	=> 'markov',
						);
	$self->{Chain} = $self->{Store}->get('chain');
	if (!$self->{Chain}) {
		print STDERR "No chain loaded from file. Creating new.\n";
		$self->{Chain} = new Algorithm::MarkovChain;
	}
	else {
		print STDERR "Chain loaded from file.\n";
	}
	$self->{Saved} = time;
}

sub DESTROY {
	my $self = shift;
	$self->save(1);
}

sub save {
	my $self = shift;
	my $force = shift;
	return undef unless ($self->{Saved} < (time() - 1800)) || $force;
	print STDERR "Saving Markov data\n";
	$self->{Saved} = time;
	$self->{Store}->set('chain', $self->{Chain});
	return 1;
}

sub think {
	my $self = shift;
	my $message = shift;

	# return undef if $message->user eq 'amethyst';

	my $content = $message->content;

	$content =~ s/[^A-Za-z\s]//g;

	if (($content =~ /\bspew\b/i) && ($message->channel eq 'spam')) {
		print STDERR "Spewing...\n";
		$content =~ s/\bspew\b/ /g;
		my @tokens = split(/\s+/, $content);
		my $token = $tokens[int rand($#tokens)];
		my @new = $self->{Chain}->spew(
						length			=> rand(10) + 5,
						# length			=> 3,
						# force_length	=> 5,
						complete		=> [ $token ],
							);

		my $data = join(' ', @new);
		$data =~ s/\s*amethyst\s*/ /ig;
		print STDERR "Spew output is $data\n";

		my $reply = $message->reply($data);
		# $reply->channel('spam');
		$reply->send;

		return 1;
	}

	my @tokens = split(/\s+/, $content);

	$self->{Chain}->seed(
					symbols	=> \@tokens,
					longest	=> 6,
						);

	$self->save(0);

	return undef;
}

1;

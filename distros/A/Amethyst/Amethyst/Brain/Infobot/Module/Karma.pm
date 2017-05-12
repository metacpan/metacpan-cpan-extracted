package Amethyst::Brain::Infobot::Module::Karma;

use strict;
use vars qw(@ISA);
use Amethyst::Message;
use Amethyst::Store;
use Amethyst::Brain::Infobot;
use Amethyst::Brain::Infobot::Module;

@ISA = qw(Amethyst::Brain::Infobot::Module);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(
					Name		=> 'Karma',
					Regex		=> qr/(?:karma|\+\+|--)/i,
					Usage		=> '<foo>++|<foo>--|karma <foo>',
					Description	=> "Karma handler",
					@_
						);

	$self->{Store} = new Amethyst::Store(
					Source	=> 'karma',
						);

	return bless $self, $class;
}

sub karma_get { return $_[0]->{Store}->get($_[1]); }

# These two can warn about undef
sub karma_inc {
	my ($self, $term) = @_;
	my $store = $self->{Store};
	my $val = $store->get($term);
	$store->set($term, $val ? ($val + 1) : 1);	# Avoid warning
}

sub karma_dec {
	my ($self, $term) = @_;
	my $store = $self->{Store};
	$store->set($term, $store->get($term) - 1);
}

sub action {
    my ($self, $message) = @_;

	my $content = $message->content;

	$content =~ s/\s+/ /g;

	my $re = qr/(\(.*?\)|[^(++)(--)\s]+)(\+\+|--)/;

	if ($content =~ /^\s*karma (.*)/) {
		my $term = lc $1;
		$term =~ s/^[ (]*//g;
		$term =~ s/[ )]*$//g;

		my $karma = $self->karma_get($term);

		my $reply = $self->reply_to($message, "$term has " .
						($karma ? "a karma of $karma" : "no karma"));
		$reply->send;

		return 1;
	}
	else {
		my $retval = undef;

		my %seen = ();

		# Regex stolen from original InfoBot.
		while ($content =~ s/(\(.*?\)|[^(++)(--)\s]+)(\+\+|--)//) {
			my ($term, $inc) = (lc $1, $2);

			$retval = 1;

			$term =~ s/^[ (]*//g;
			$term =~ s/[ )]*$//g;

			next if $seen{$term};
			$seen{$term} = 1;

			# Require public

			if ($message->channel eq CHAN_PRIVATE) {
				my $reply = $self->reply_to($message, "Karma must " .
								"be altered in public.");
				$reply->channel(CHAN_PRIVATE);
				$reply->send;
				return 1;
			}
			elsif ($term eq lc $message->user) {
				my $reply = $self->reply_to($message, "You cannot " .
								"alter your own karma");
				$reply->channel(CHAN_PRIVATE);
				$reply->send;
			}
			elsif ($inc eq '++') {
				$self->karma_inc($term);
			}
			else {
				$self->karma_dec($term);
			}
		}

		return $retval;
	}
}

1;

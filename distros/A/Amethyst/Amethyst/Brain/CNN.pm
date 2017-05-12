package Amethyst::Brain::CNN;

use strict;
use vars qw(@ISA);
use URI;
use Amethyst::Brain;
use Amethyst::Message;

@ISA = qw(Amethyst::Brain);

sub init {
	my $self = shift;
	$self->{Content} = '';
}

sub think {
	my $self = shift;
	my $message = shift;

	my $content = $message->content;

	if ($content !~ /[\.?!]\s*$/) {
		$self->{Content} .= ' ' . $content;
		return;
	}

	$content = lc $self->{Content} . ' ' . $content;
	$self->{Content} = '';

	# $content =~ s/\b(\w)\b/\u$1/g;
	$content =~ s/\s+/ /g;
	$content =~ s/^ //;
	$content =~ s/ $//;

	local *::connections = $self->{Output};

	foreach my $connection (keys %::connections) {
		my $reply = new Amethyst::Message(
						Connection	=> $connection,
						Channel		=> $::connections{$connection},
						User		=> 'Amethyst',
						Action		=> ACT_SAY,
						Content		=> ucfirst $content,
							);
		$reply->send;
	}

	return undef;
}

1;

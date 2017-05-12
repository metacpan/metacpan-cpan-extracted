package Amethyst::Brain::Infobot::Module::Help;

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
					Name		=> 'Help',
					Regex		=> qr/^\s*help\b/i,
					Usage		=> 'help [<module>]',
					Description	=> "Help handler",
					@_
						);

	return bless $self, $class;
}

sub action {
    my ($self, $message) = @_;

	my $content = $message->content;

	$content =~ s/\s+/ /g;

	my $re = qr/(\(.*?\)|[^(++)(--)\s]+)(\+\+|--)/;

	my $infobot = $self->{Infobot};
	my @modules = @{$infobot->{Modules}};

	if ($content =~ /^\s*help (.*)/) {
		my $rq = lc $1;
		foreach my $module (@modules) {
			if (lc $module->{Name} eq $rq) {
				my $msg = $module->{Name};
				$msg .= " ($module->{Description})"
								if $module->{Description};
				$msg .= ": $module->{Usage}"
								if $module->{Usage};
				my $reply = $self->reply_to($message, $msg);
				$reply->send;
				return 1;
			}
		}

		my $reply = $self->reply_to($message, "Module $rq not found");
		$reply->send;
		return 1;
	}
	elsif ($content =~ /^\s*help\b/i) {
		my @names = map { $_->{Name} } @modules;
		my $reply = $self->reply_to($message, "Available modules: " .
						join(", ", @names));
		$reply->send;
		return 1;
	}

	return undef;
}

1;

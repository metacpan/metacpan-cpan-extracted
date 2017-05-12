package Amethyst::Brain::Infobot::Module::BabyTime;

use strict;
use vars qw(@ISA $ZONEDIR);
use Date::Format;
use Text::Soundex;
use Amethyst::Brain::Infobot::Module;
use Acme::Time::Baby; # (language => 'swedish chef');

@ISA = qw(Amethyst::Brain::Infobot::Module);

sub new {
	my $class = shift;

	my $self  = $class->SUPER::new(
					Name		=> 'BabyTime',
					# Regex		=> qr/^(what is the? )?babytime/i,
					Usage		=> '(what is the )? babytime in <language>',
					Description	=> "Print the time for babies.",
					@_
						);
	return bless $self, $class;
}

sub process {
    my ($self, $message) = @_;

	my $content = lc $message->content;
	$content =~ s/\s+/ /g;

	$content =~ s/^what is the //;
	return undef unless $content =~ /^babytime/;

	my $reply = $self->reply_to($message, babytime);
	$reply->send;

	return 1;
}

1;

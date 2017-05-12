package Bot::BasicBot::Pluggable::Module::Eliza;

use warnings;
use strict;

use Chatbot::Eliza;

use base qw(Bot::BasicBot::Pluggable::Module);

our $VERSION = '0.05';

sub init {
	my ($self) = shift;
	my %args;
	$args{'scripfile'} = $self->get("user_scriptfile") if defined($self->get("user_scriptfile"));
	$self->{eliza} = Chatbot::Eliza->new(%args);
	return;
}

sub set {
	my ($self,$key,$val) = @_;

	if ($key eq 'user_scriptfile') {
		if ( -e $val ) {
			if ($self->{eliza} = Chatbot::Eliza->new(scriptfile => $val)) {
				## Just save the new value for scriptfile if restarting was successful
				$self->SUPER::set($key,$val);
			}
		} 
		else {
			return "Can't change scriptfile: $val is not readable";
		}
	} 
	else {
		## just do the normal stuff unless scriptfile is called
		$self->SUPER::set($key,$val);
	}
	return;
}

sub unset {
	my ($self,$key,$val) = @_;
	$self->SUPER::unset($key,$val);
	if ($key eq 'user_scriptfile') {
		## We're just reloading the default script here
		$self->{eliza} = Chatbot::Eliza->new();
	};
	return;
}

sub help {
	return "Implements the classic Eliza algorithm.";
}

sub fallback {
	my ($self,$message) = @_;
	if ($message->{address}) {
		return $self->{eliza}->transform($message->{body});
	}
	return;
}

1; # End of Bot::BasicBot::Pluggable::Module::Eliza

__END__

=pod

=head1 NAME

Bot::BasicBot::Pluggable::Module::Eliza - Eliza for Bot::BasicBot::Pluggable

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

This module is a simple wrapper around L<http://search.cpan.org/dist/Chatbot-Eliza>.

    $bot->load('Eliza');

=head1 FUNCTIONS

=head2 help

Prints a helpful message.

=head2 fallback

Replies to messages directed to the bot instance. We are using fallback
just to make sure that this very talkative module does not interfere
with any other module.

=head2 init

Initializes the eliza module. Please refer to the documentation section VARIABLES for configuration settings.


=head2 set / unset

These functions are subclassed to reload the eliza instance after the
scriptfile is changed. The normal beaviour of Chatbot::Eliza is to simply
add the rules of the new scriptfile to the current scriptfile rules,
which is often not the expected behaviour (at least by the expectations
of the author). In case scriptfile is unset, we reload the eliza instance
to access it's default Rogerian psychotherapist.

Both functions reset the phrases remembered by the %reasmblist_for_memory
structure.

=head1 VARIABLES

=head2 scriptfile

The chatbot uses the tranformation rules in this file to reply. Please
refer to L<http://search.cpan.org/dist/Chatbot-Eliza> for its syntax.

=head1 AUTHOR

Mario Domgoergen, C<< <dom at math.uni-bonn.de> >>

=head1 BUGS

Please report any bugs or feature requests
to C<bug-bot-basicbot-pluggable-module-eliza
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bot-BasicBot-Pluggable-Module-Eliza>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bot::BasicBot::Pluggable::Module::Eliza


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-BasicBot-Pluggable-Module-Eliza>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bot-BasicBot-Pluggable-Module-Eliza>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bot-BasicBot-Pluggable-Module-Eliza>

=item * Search CPAN

L<http://search.cpan.org/dist/Bot-BasicBot-Pluggable-Module-Eliza>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Mario Domgoergen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


package Bot::BasicBot::Pluggable::Module::Abuse::YourMomma;
use strict;
use base 'Bot::BasicBot::Pluggable::Module';
use vars qw($VERSION);


$VERSION = 0.02;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Abuse::YourMomma - maturity is overrrated;

=head1 DESCRIPTION

Randomly throw in "your momma" jokes when someone says something the bot can
respond to with an incredibly witty and original "your momma"-type response.

(No guarantee is provided as to the wittyness or originality of the jokes.)

=head1 USAGE

Load the module like you would any other L<Bot::BasicBot::Pluggable> module.

That's about it.

=head1 FAQs

=over 4

=item Isn't this remarkably childish, silly and immature?

Erm... yes.

=item Shouldn't this be under the C<Acme::> namespace?

Probably, except L<Bot::BasicBot::Pluggable> modules go under the
C<Bot::BasicBot::Pluggable::Module> namespace, so, here it is.

=item Were you bored when you wrote this?

Whatever would make you think that?

=item Who is the fat controller?

Why, it's Ross, of course.  *waves*

=back



=head1 AUTHOR 

David Precious C<< davidp@preshweb.co.uk >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011 David Precious.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

sub said {
    my ($self,$mess,$pri) = @_;
    return unless $pri == 2;

    if ($mess->{body} =~ m{
        (is|it's) \s+
        (ugly|dirty|smelly|filthy|nasty|horrible|minging)
    }xmi) {
        return random_response(
            "So's your momma",
            "So is your momma",
            "So's yer mum",
            "So's yer momma, bitch",
            "Yeah, just like your momma",
            "Yeah, just like your mum",
        );
    }

    if ($mess->{body} =~ m{
        \b
        (smells|sucks)
        \b
    }xmi) {
        return random_response(
            "Yeah, so does your momma",
            "Yeah, just like your momma",
            "Yeah, like your mum",
        );
    }
}


# Some of the time, return one of the possible responses at random.  Other
# times, just return undef.  We want to be unpredictable :)
sub random_response {
    my @responses = shift;

    return if rand 10 < 3;
    return $responses[rand @responses];
}


1;


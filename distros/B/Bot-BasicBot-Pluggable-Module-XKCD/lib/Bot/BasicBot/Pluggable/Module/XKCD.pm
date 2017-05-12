package Bot::BasicBot::Pluggable::Module::XKCD;

use warnings;
use strict;

use base qw(Bot::BasicBot::Pluggable::Module);

use URI::Title qw(title);
use LWP::Simple;

=head1 NAME

Bot::BasicBot::Pluggable::Module::XKCD - Get xkcd comic links and titles

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';


=head1 SYNOPSIS

Searches for xkcd comics by name or number and outputs a link and title

=head1 IRC USAGE

=over 4

=item xkcd [<id|regex>]

Return the title and link to a comic matching the id or regex given. If
nothing is given, use the latest comic.

=back

=cut

sub help {
    return "xkcd [id|regex] - give title and link for matching comic";
}

sub told {
    my ($self, $mess) = @_;
    my $body = $mess->{body};

    my ($command, $param) = split /\s+/, $body, 2;
    $command = lc $command;

    if ($command eq "xkcd") {
	my $url;
	if (!defined $param) {
	    $url = 'http://xkcd.com/';
	} elsif ($param =~ /^\d+$/) {
	    $url = "http://xkcd.com/$param/";
	} else {
	    my $num = eval { # just in case someone gives us some horrific RE
		local $_ = get "http://xkcd.com/archive/";
		local $SIG{ALRM} = sub { die "timed out\n" };
		alarm 10; # XXX: \o/ magic numbers
		m{href="/(\d+)/".*$param}i;
		alarm 0;
		return $1;
	    };
	    if ($@) {
		die unless $@ eq "timed out\n";
		return "Timed out.";
	    }
	    $url = "http://xkcd.com/$num/" if $num;
	}

	my $title = title($url);

	return "Couldn't get comic" unless defined $title;

	$title =~ s/^xkcd: //;

	return "$title - $url";
    }
}


=head1 AUTHOR

Josh Holland, C<< <jrh at joshh.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bot-basicbot-pluggable-module-xkcd at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bot-BasicBot-Pluggable-Module-XKCD>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bot::BasicBot::Pluggable::Module::XKCD


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-BasicBot-Pluggable-Module-XKCD>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bot-BasicBot-Pluggable-Module-XKCD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bot-BasicBot-Pluggable-Module-XKCD>

=item * Search CPAN

L<http://search.cpan.org/dist/Bot-BasicBot-Pluggable-Module-XKCD/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Josh Holland.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Bot::BasicBot::Pluggable::Module::XKCD

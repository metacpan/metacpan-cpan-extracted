package Bot::BasicBot::Pluggable::Module::SubReddit;

use base qw(Bot::BasicBot::Pluggable::Module);

use strict;
use warnings;

use URI::Title qw/title/;

=head1 NAME

Bot::BasicBot::Pluggable::Module::SubReddit - a simple reddit-related helper plugin for Bot::BasicBot::Pluggable

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Spots likely subreddit links (e.g. "r/perl" or "/r/dailyprogrammer") and replies with the URL and description of the subreddit.

    $bot->load('SubReddit');

No, really, that's it.

=cut

=head1 IRC Usage

Just mention the a subreddit and the bot will offer a link and some details.

	01:38:12 <jkg> r/AskReddit
	01:38:12 <hadaly> Reddit: http://www.reddit.com/r/AskReddit -- Ask Reddit...
	01:38:25 <jkg> r/IAmA
	01:38:26 <hadaly> Reddit: http://www.reddit.com/r/IAmA -- I Am A, where the mundane becomes fascinating and the outrageous suddenly seems normal.
	01:38:36 <jkg> /r/bifl
	01:38:36 <hadaly> Reddit: http://www.reddit.com/r/bifl -- Buy it for life

=cut

sub help {
    return "Links to, and describes, subreddits mentioned as /r/subname";
}

sub init {
    my $self = shift;
    $self->config(
        {} # nothing to configure yet; might add API-fu later though
    );
}

sub told {

    my ( $self, $mess ) = @_;

    for ( split / /, $mess->{body} ) {

        next unless $_ =~ m!^/?(r/[A-Za-z0-9_]+)[;,]?!; # does this look like a subreddit name?

        my $url = "http://www.reddit.com/$1";

        my $title = title($url);
        #next unless defined $title;

        my $result = "Reddit: $url -- $title";
        $self->reply( $mess, $result );
    }

    return;    # Title.pm is passive, and doesn't intercept things.
               # and we want to be just like Title.pm when we grow up
}

=head1 AUTHOR

James Green, C<< <jkg at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bot-basicbot-pluggable-module-subreddit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bot-BasicBot-Pluggable-Module-SubReddit>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bot::BasicBot::Pluggable::Module::SubReddit


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-BasicBot-Pluggable-Module-SubReddit>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bot-BasicBot-Pluggable-Module-SubReddit>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bot-BasicBot-Pluggable-Module-SubReddit>

=item * Search CPAN

L<http://search.cpan.org/dist/Bot-BasicBot-Pluggable-Module-SubReddit/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 James Green.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

42; # End of Bot::BasicBot::Pluggable::Module::SubReddit

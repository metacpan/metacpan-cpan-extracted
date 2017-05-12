package Bot::BasicBot::Pluggable::Module::WikiLink;

use base qw(Bot::BasicBot::Pluggable::Module);

use warnings;
use strict;

use WWW::Wikipedia;
use URI::Title qw/title/;

=head1 NAME

Bot::BasicBot::Pluggable::Module::WikiLink - a simple Wikipedia helper plugin for Bot::BasicBot::Pluggable

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Spots wiki-markup style links e.g. [[Wikipedia]] and provides a URI and title from
(currently, only the English language version of) Wikipedia.

    $bot->load('WikiLink');

No, really, that's it.

=cut

=head1 IRC Usage

It should follow redirects, and make limited use of search, but if there's no obviously-correct result
you won't get a response at all. Some examples

	00:31:27 <jkg> I <3 [[Perl]]!
	00:31:29 <hadaly> http://en.wikipedia.org/wiki/Perl -- Perl - Wikipedia, the free encyclopedia
	00:31:38 <jkg> [[Perl programming language]] is awesome!
	00:31:40 <hadaly> http://en.wikipedia.org/wiki/Perl -- Perl - Wikipedia, the free encyclopedia

=cut

sub help {
    return "Speaks the wikipedia URLs of things mentioned [[Like This]]";
}

=head1 Vars

None currently. I'll add an override for the wikipedia language version in a future release.

=cut

sub init {
    my $self = shift;
    $self->config(
        {} # nothing to configure yet
    );
}

sub told {

    my ( $self, $mess ) = @_;

    my @pages = ( $mess->{body} =~ m/(?<=\[\[)(.*?)(?=\]\])/g );

    return unless @pages;

    my $wiki = WWW::Wikipedia->new();

    for ( @pages ) {

        my $result = $wiki->search( $_ );

        next unless defined $result->{title};

        my $url = "http://en.wikipedia.org/wiki/" . $result->{title};

        my $title = title($url);

        next unless $title;
        
        my $reply = "$url -- $title";
        $self->reply( $mess, $reply );

    }

    return;  # be passive here; this may not be the only desired plugin for this line
}

=head1 AUTHOR

James Green, C<< <jkg at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bot-basicbot-pluggable-module-wikilink at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bot-BasicBot-Pluggable-Module-WikiLink>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bot::BasicBot::Pluggable::Module::WikiLink

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-BasicBot-Pluggable-Module-WikiLink>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bot-BasicBot-Pluggable-Module-WikiLink>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bot-BasicBot-Pluggable-Module-WikiLink>

=item * MetaCPAN

L<http://metacpan.org/dist/Bot::BasicBot::Pluggable::Module::WikiLink>

=back

=head1 See Also

=over 4

=item * C<Bot::BasicBot::Pluggable>

=item * C<WWW::Wikipedia>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Chris Chapman for suggesting the feature.

=item * Wikipedia for containing the entirety of human knowledge.

=back

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

42; # End of Bot::BasicBot::Pluggable::Module::WikiLink

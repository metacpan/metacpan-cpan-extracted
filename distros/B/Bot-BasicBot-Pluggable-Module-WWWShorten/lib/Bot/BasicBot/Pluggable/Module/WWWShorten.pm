package Bot::BasicBot::Pluggable::Module::WWWShorten;

use warnings;
use strict;
use parent 'Bot::BasicBot::Pluggable::Module';
use URI::Find::Rule;
use Try::Tiny;
use Module::Load;
use LWP::UserAgent;

our $VERSION = '0.03';

sub init {
    my $self = shift;
    $self->config(
        {
            user_service    => 'TinyURL',
            user_min_length => 0,
            user_addressed  => 0,
        }
    );
}

sub admin {
    my ( $self, $message ) = @_;

    my $body = $message->{body};
    return if !$body;
    return if $self->get('user_addressed') && ! $message->{address};

    my @uris = map { $_->[1] } URI::Find::Rule->http->in($body);
    return if !@uris;

    my $service = $self->get('user_service');
    my $module  = "WWW::Shorten::$service";
    try { load $module } catch { die "Can't load service $service: $@" };

    $module->import('makeashorterlink');
    for my $uri (@uris) {
        next if length $uri < $self->get('user_min_length');
        my ( $short_link, $title );
        try {
            $short_link = makeashorterlink($uri);

            my $ua = LWP::UserAgent->new(
                env_proxy => 1,
                timeout   => 30,    # seconds
                max_size =>
                  8192,    # bytes ... lets hope title is in the first bytes
            );

            my $response = $ua->get($uri);
            if (   $response->is_success
                && $response->content_type eq 'text/html' )
            {
                $title = $response->title;
            }

        }
        catch {
            die "Can't generate short link: $_";
        };

        my $reply = $short_link;
        $reply .= " [ $title ]" if $title;
        $self->reply( $message, $reply );
    }
}

1;    # End of Bot::BasicBot::Pluggable::Module::WWWShorten

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::WWWShorten - Shorten all urls

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

By loading this module your bot will check all messages for an url and
will reply with an shortened url and its title if the url links to an
html document. The bot will use TinyURL as default to generate a shorter
uri but the module supports all services provided by L<WWW::Shorten>.

 user> !load WWWShorten
 bot > Okay.
 user> http://www.heise.de
 bot > http://tinyurl.com/48z [ heise online - Home ]

=head1 VARIABLES

=head2 user_min_length

If this variable is set to a true value, only urls that are longer than
C<user_min_length> are processed by this module. All shorter urls are
ignored. Default to zero (aka false).

=head2 user_addressed

Ignore all messages that are not directly addressed for the bot. Defaults
to false.

=head2 user_service

Specifies which service to use to actually shorten all urls. Accepts
the last part of the module name of all modules compatible with
L<WWW::Shorten>, for example TinyURL, TinyClick or Shorl. Defaults
to TinyUrl.

=head1 AUTHOR

Mario Domgoergen, C<< <mdom at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bot-basicbot-pluggable-module-www-shorten at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bot-BasicBot-Pluggable-Module-WWWShorten>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bot::BasicBot::Pluggable::Module::WWWShorten


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bot-BasicBot-Pluggable-Module-WWWShorten>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bot-BasicBot-Pluggable-Module-WWWShorten>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bot-BasicBot-Pluggable-Module-WWWShorten>

=item * Search CPAN

L<http://search.cpan.org/dist/Bot-BasicBot-Pluggable-Module-WWWShorten/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Mario Domgoergen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

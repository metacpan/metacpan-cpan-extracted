package Bot::IRC::X::UriTitle;
# ABSTRACT: Bot::IRC plugin to parse and print URI titles

use strict;
use warnings;

use LWP::UserAgent;
use LWP::Protocol::https;
use Text::Unidecode 'unidecode';
use URI::Title 'title';

our $VERSION = '1.02'; # VERSION

sub init {
    my ($bot) = @_;

    $bot->hook(
        {
            command => 'PRIVMSG',
            text    => qr|https?://\S+|,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            my %urls;
            $urls{$1} = 1 while ( $in->{text} =~ m|(https?://\S+)|g );
            $bot->reply("[ $_ ]") for ( grep { defined } map { unidecode( title($_) ) } keys %urls );
            return;
        },
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::X::UriTitle - Bot::IRC plugin to parse and print URI titles

=head1 VERSION

version 1.02

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/Bot-IRC-X-UriTitle.svg)](https://travis-ci.org/gryphonshafer/Bot-IRC-X-UriTitle)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/Bot-IRC-X-UriTitle/badge.png)](https://coveralls.io/r/gryphonshafer/Bot-IRC-X-UriTitle)

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['UriTitle'],
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin makes the bot parse and print URI titles.

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<Bot::IRC>

=item *

L<GitHub|https://github.com/gryphonshafer/Bot-IRC-X-UriTitle>

=item *

L<CPAN|http://search.cpan.org/dist/Bot-IRC-X-UriTitle>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bot::IRC::X::UriTitle>

=item *

L<AnnoCPAN|http://annocpan.org/dist/Bot-IRC-X-UriTitle>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/Bot-IRC-X-UriTitle>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/Bot-IRC-X-UriTitle>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bot-IRC-X-UriTitle>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/T/Bot-IRC-X-UriTitle.html>

=back

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

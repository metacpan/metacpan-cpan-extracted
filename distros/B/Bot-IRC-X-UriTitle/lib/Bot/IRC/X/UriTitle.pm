package Bot::IRC::X::UriTitle;
# ABSTRACT: Bot::IRC plugin to parse and print URI titles

use 5.014;
use exact;

use LWP::UserAgent;
use LWP::Protocol::https;
use Text::Unidecode 'unidecode';
use URI::Title 'title';

our $VERSION = '1.06'; # VERSION

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

version 1.06

=for markdown [![test](https://github.com/gryphonshafer/Bot-IRC-X-UriTitle/workflows/test/badge.svg)](https://github.com/gryphonshafer/Bot-IRC-X-UriTitle/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Bot-IRC-X-UriTitle/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Bot-IRC-X-UriTitle)

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

L<MetaCPAN|https://metacpan.org/pod/Bot::IRC::X::UriTitle>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Bot-IRC-X-UriTitle/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Bot-IRC-X-UriTitle>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bot-IRC-X-UriTitle>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/T/Bot-IRC-X-UriTitle.html>

=back

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

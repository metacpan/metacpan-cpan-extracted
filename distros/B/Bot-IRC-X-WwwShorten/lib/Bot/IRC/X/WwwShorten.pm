package Bot::IRC::X::WwwShorten;
# ABSTRACT: Bot::IRC plugin for automatic URL shortening

use 5.014;
use exact;

use WWW::Shorten qw( TinyURL makeashorterlink );

our $VERSION = '1.05'; # VERSION

sub init {
    my ($bot) = @_;

    $bot->hook(
        {
            to_me => 1,
            text  => qr/^tiny\s+(?<url>\S+)/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;
            $bot->reply_to( makeashorterlink( $m->{url} ) );
        },
    );

    $bot->helps( 'tiny' => 'Shorten URLs. Usage: <bot nick> tiny <url>.' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::X::WwwShorten - Bot::IRC plugin for automatic URL shortening

=head1 VERSION

version 1.05

=for markdown [![test](https://github.com/gryphonshafer/Bot-IRC-X-WwwShorten/workflows/test/badge.svg)](https://github.com/gryphonshafer/Bot-IRC-X-WwwShorten/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Bot-IRC-X-WwwShorten/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Bot-IRC-X-WwwShorten)

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['WwwShorten'],
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin for automatic URL shortening. It uses
L<TinyURL|http://tinyurl.com> for shortening through L<WWW::Shorten>.

    <user> bot tiny http://perl.org
    <bot> user: http://tinyurl.com/9om78

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<Bot::IRC>

=item *

L<GitHub|https://github.com/gryphonshafer/Bot-IRC-X-WwwShorten>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bot::IRC::X::WwwShorten>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Bot-IRC-X-WwwShorten/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Bot-IRC-X-WwwShorten>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bot-IRC-X-WwwShorten>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/T/Bot-IRC-X-WwwShorten.html>

=back

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

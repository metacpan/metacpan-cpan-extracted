package Bot::IRC::X::MetarTaf;
# ABSTRACT: Bot::IRC plugin for METAR and TAF reporting

use strict;
use warnings;

use LWP::Simple 'get';

our $VERSION = '1.01'; # VERSION

sub init {
    my ($bot) = @_;

    $bot->hook(
        {
            to_me => 1,
            text  => qr/^(?<type>metar|taf)\s+(?<code>\S+)/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;
            my $code = uc( $m->{code} );
            $code = 'K' . $code if ( length $code == 3 );

            if ( lc( $m->{type} ) eq 'taf' ) {
                my $content = get(
                    'http://tgftp.nws.noaa.gov/data/forecasts/taf/stations/' . $code . '.TXT',
                );

                if ($content) {
                    my @content = split( /\r?\n/, $content );
                    shift @content for ( 0 .. 1 );
                    $bot->reply_to( join( '; ', map { s/^\s+|\s+$//g; $_ } @content ) );
                }
                else {
                    $bot->reply_to("Unable to find TAF data for $code.");
                }
            }
            else {
                my $content = get(
                    'http://tgftp.nws.noaa.gov/data/observations/metar/stations/' . $code . '.TXT',
                );
                if ($content) {
                    $bot->reply_to( ( split( /\r?\n/, $content ) )[1] );
                }
                else {
                    $bot->reply_to("Unable to find METAR data for $code.");
                }
            }
        },
    );

    $bot->helps(
        metartaf =>
            'Get airport weather from NOAA. ' .
            'Usage: <bot> metar <airport code>; <bot> taf <airport code>.',
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::X::MetarTaf - Bot::IRC plugin for METAR and TAF reporting

=head1 VERSION

version 1.01

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/Bot-IRC-X-MetarTaf.svg)](https://travis-ci.org/gryphonshafer/Bot-IRC-X-MetarTaf)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/Bot-IRC-X-MetarTaf/badge.png)](https://coveralls.io/r/gryphonshafer/Bot-IRC-X-MetarTaf)

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['MetarTaf'],
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin is for METAR and TAF reporting.

    bot metar <airport code>
    bot taf <airport code>

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<Bot::IRC>

=item *

L<GitHub|https://github.com/gryphonshafer/Bot-IRC-X-MetarTaf>

=item *

L<CPAN|http://search.cpan.org/dist/Bot-IRC-X-MetarTaf>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bot::IRC::X::MetarTaf>

=item *

L<AnnoCPAN|http://annocpan.org/dist/Bot-IRC-X-MetarTaf>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/Bot-IRC-X-MetarTaf>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/Bot-IRC-X-MetarTaf>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bot-IRC-X-MetarTaf>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/T/Bot-IRC-X-MetarTaf.html>

=back

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

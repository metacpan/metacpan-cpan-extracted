package Bot::IRC::X::ManagementSpeak;
# ABSTRACT: Bot::IRC plugin for rendering management-speak

use strict;
use warnings;

use Lingua::ManagementSpeak;

our $VERSION = '1.01'; # VERSION

sub init {
    my ($bot) = @_;

    my $ms = Lingua::ManagementSpeak->new;

    $bot->hook(
        {
            to_me => 1,
            text  => qr/^mspeak/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;
            $bot->reply( $ms->paragraph(4) );
        },
    );

    $bot->helps( mspeak => 'Return managerial-sounding text. Usage: <bot> mspeak.' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::X::ManagementSpeak - Bot::IRC plugin for rendering management-speak

=head1 VERSION

version 1.01

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/Bot-IRC-X-ManagementSpeak.svg)](https://travis-ci.org/gryphonshafer/Bot-IRC-X-ManagementSpeak)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/Bot-IRC-X-ManagementSpeak/badge.png)](https://coveralls.io/r/gryphonshafer/Bot-IRC-X-ManagementSpeak)

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['ManagementSpeak'],
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin is for rendering management-speak.

    <bot> mspeak

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<Bot::IRC>

=item *

L<GitHub|https://github.com/gryphonshafer/Bot-IRC-X-ManagementSpeak>

=item *

L<CPAN|http://search.cpan.org/dist/Bot-IRC-X-ManagementSpeak>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bot::IRC::X::ManagementSpeak>

=item *

L<AnnoCPAN|http://annocpan.org/dist/Bot-IRC-X-ManagementSpeak>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/Bot-IRC-X-ManagementSpeak>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/Bot-IRC-X-ManagementSpeak>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bot-IRC-X-ManagementSpeak>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/T/Bot-IRC-X-ManagementSpeak.html>

=back

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

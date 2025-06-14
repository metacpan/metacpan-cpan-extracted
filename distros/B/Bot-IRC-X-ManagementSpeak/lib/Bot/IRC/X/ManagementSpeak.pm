package Bot::IRC::X::ManagementSpeak;
# ABSTRACT: Bot::IRC plugin for rendering management-speak

use 5.014;
use exact;

use Lingua::ManagementSpeak;

our $VERSION = '1.05'; # VERSION

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

version 1.05

=for markdown [![test](https://github.com/gryphonshafer/Bot-IRC-X-ManagementSpeak/workflows/test/badge.svg)](https://github.com/gryphonshafer/Bot-IRC-X-ManagementSpeak/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Bot-IRC-X-ManagementSpeak/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Bot-IRC-X-ManagementSpeak)

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

L<MetaCPAN|https://metacpan.org/pod/Bot::IRC::X::ManagementSpeak>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Bot-IRC-X-ManagementSpeak/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Bot-IRC-X-ManagementSpeak>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bot-IRC-X-ManagementSpeak>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/T/Bot-IRC-X-ManagementSpeak.html>

=back

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

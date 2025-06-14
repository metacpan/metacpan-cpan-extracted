package Bot::IRC::X::Dice;
# ABSTRACT: Bot::IRC plugin for dice rolling

use 5.014;
use exact;

use Games::Dice 'roll';

our $VERSION = '1.07'; # VERSION

sub init {
    my ($bot) = @_;

    $bot->hook(
        {
            command => 'PRIVMSG',
            text    => qr/^roll\s+(?<expr>\d*d[\d%]+(?:[+\-*\/]\d+)?)/,
        },
        sub {
            my ( $bot, $in, $m ) = @_;
            $bot->reply( roll( $m->{expr} ) );
        },
    );

    $bot->helps( dice => 'Simulated dice rolls. Usage: roll <dice expression like "2d6+2">.' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::X::Dice - Bot::IRC plugin for dice rolling

=head1 VERSION

version 1.07

=for markdown [![test](https://github.com/gryphonshafer/Bot-IRC-X-Dice/workflows/test/badge.svg)](https://github.com/gryphonshafer/Bot-IRC-X-Dice/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/Bot-IRC-X-Dice/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/Bot-IRC-X-Dice)

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['Dice'],
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin provides the means for the bot to perform simulated
dice rolls.

    roll <dice expression like "2d6+2">

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<Bot::IRC>

=item *

L<GitHub|https://github.com/gryphonshafer/Bot-IRC-X-Dice>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bot::IRC::X::Dice>

=item *

L<GitHub Actions|https://github.com/gryphonshafer/Bot-IRC-X-Dice/actions>

=item *

L<Codecov|https://codecov.io/gh/gryphonshafer/Bot-IRC-X-Dice>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bot-IRC-X-Dice>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/T/Bot-IRC-X-Dice.html>

=back

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

package Bot::IRC::X::Dice;
# ABSTRACT: Bot::IRC plugin for dice rolling

use strict;
use warnings;

use Games::Dice 'roll';

our $VERSION = '1.03'; # VERSION

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

version 1.03

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/Bot-IRC-X-Dice.svg)](https://travis-ci.org/gryphonshafer/Bot-IRC-X-Dice)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/Bot-IRC-X-Dice/badge.png)](https://coveralls.io/r/gryphonshafer/Bot-IRC-X-Dice)

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

L<CPAN|http://search.cpan.org/dist/Bot-IRC-X-Dice>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bot::IRC::X::Dice>

=item *

L<AnnoCPAN|http://annocpan.org/dist/Bot-IRC-X-Dice>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/Bot-IRC-X-Dice>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/Bot-IRC-X-Dice>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bot-IRC-X-Dice>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/T/Bot-IRC-X-Dice.html>

=back

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

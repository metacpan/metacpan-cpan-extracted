package Bot::IRC::Convert;
# ABSTRACT: Bot::IRC convert units of amounts

use 5.012;
use strict;
use warnings;

use Math::Units qw(convert);

our $VERSION = '1.25'; # VERSION

sub init {
    my ($bot) = @_;

    $bot->hook(
        {
            command => 'PRIVMSG',
            text    => qr/^(?<amount>[\d,\.]+)\s+(?<in_unit>\S+)\s+(?:in|as|to|into)\s+(?<out_unit>\S+)/,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            ( my $amount = $m->{amount} ) =~ s/,//g;
            my $value;
            eval { $value = convert( $amount, $m->{in_unit}, $m->{out_unit} ) };

            $bot->reply("$m->{amount} $m->{in_unit} is $value $m->{out_unit}") if ($value);
        },
    );

    $bot->helps( convert => 'Convert units of value. Usage: <amount> <input unit> as <output unit>.' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::Convert - Bot::IRC convert units of amounts

=head1 VERSION

version 1.25

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['Convert'],
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin allows the bot to convert various values of units.
Unit types must match, which is to say you can't convert length to volume.

=head2 SEE ALSO

L<Bot::IRC>

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

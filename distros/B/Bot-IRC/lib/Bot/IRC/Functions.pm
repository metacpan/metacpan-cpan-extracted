package Bot::IRC::Functions;
# ABSTRACT: Bot::IRC add maybe helpful functions to the bot

use 5.014;
use exact;

our $VERSION = '1.42'; # VERSION

sub init {
    my ($bot) = @_;

    my $alphabet = 'abcdefghijklmnopqrstuvwxyz';
    my $start    = uc($alphabet) . $alphabet;
    my @alphabet = split( '', $alphabet );

    $bot->hook(
        {
            command => 'PRIVMSG',
            text    => qr/^(?<function>ord|chr|ascii|rot\d+|crypt)\s+(?<input>.+)/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            my $function = lc( $m->{function} );
            my $text     = '';

            if ( $function eq 'ord' ) {
                $text =
                    "\"$m->{input}\" has a numerical value of " .
                    join( ' ', map { ord($_) } split( '', $m->{input} ) ) . '.';
            }
            elsif ( $function eq 'chr' or $function eq 'ascii' and $m->{input} =~ /^\d+$/ ) {
                $text =
                    "$m->{input} has a character value of \"" .
                    chr( $m->{input} ) . '".';
            }
            elsif ( $function =~ /rot(\d+)/ ) {
                my $rot = $1;
                my @this_alphabet = @alphabet;
                push( @this_alphabet, splice( @this_alphabet, 0, $rot ) );
                my $end = uc( join( '', @this_alphabet ) ) . join( '', @this_alphabet );
                ( $text = $m->{input} ) =~ tr/$start/$end/;
                $text = "The ROT$rot of your input is \"$text\".";
            }
            elsif ( $function eq 'crypt' ) {
                my $salt = ( $m->{input} =~ s/(\w+)\s+(\w{2})\s*$/$1/ )
                    ? $2
                    : join( '', map { $alphabet[ int( rand() * @alphabet ) ] } 0 .. 1 );
                $text = 'The crypt value of your input is "' . crypt( $m->{input}, $salt ) . '".';
            }

            $bot->reply($text) if ($text);
        },
    );

    $bot->helps( functions =>
        'A set of maybe useful functions. ' .
        'Usage: ord <character>; (chr|ascii) <number>; rot<number> <string>; crypt <string> [<salt>].'
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::Functions - Bot::IRC add maybe helpful functions to the bot

=head1 VERSION

version 1.42

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['Functions'],
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin adds what might be helpful functions to the bot.
Commands include:

=head2 ord <character>

Convert a character into its ASCII number equivalent.

=head2 (chr|ascii) <number>

Convert a number into its ASCII character equivalent.

=head2 rot<number> <string>

Inspired by ROT13, this function will transpose letters based on the sequence
of the alphabet and by the number provided.

    rot13 hello
    rot42 hello again

ROT13 is a simple letter substitution cipher that replaces a letter with the
letter 13 letters after it in the alphabet.

=head2 crypt <string> [<salt>]

This method will encrypt using C<crypt> a string. If the salt is not provided,
it will be randomly generated.

=head2 SEE ALSO

L<Bot::IRC>

=for Pod::Coverage init

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2050 by Gryphon Shafer.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

package Bot::IRC::Infobot;
# ABSTRACT: Bot::IRC add classic "infobot" functionality to the bot

use 5.014;
use exact;

use DateTime;
use DateTime::Format::Human::Duration;

our $VERSION = '1.42'; # VERSION

sub init {
    my ($bot) = @_;
    $bot->load('Store');

    $bot->hook(
        {
            command => 'PRIVMSG',
            text    => qr/^(?<term>\([^\)]+\)|\S+)\s+(?:is|=)\s+(?<fact>.+?)$/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            ( my $term = lc( $m->{term} ) ) =~ s/[\(\)]+//g;
            my @facts = @{ $bot->store->get($term) || [] };

            push( @facts, $m->{fact} );

            $bot->store->set( $term => \@facts );
            return;
        },
    );

    $bot->hook(
        {
            command => 'PRIVMSG',
            text    => qr/^(?<term>\([^\)]+\)|\S+)\?/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            ( my $display_term = $m->{term} ) =~ s/[\(\)]+//g;
            my $term = lc($display_term);

            my @facts = map {
                if ( /\|/ ) {
                    my @terms = split(/\|/);
                    $terms[ int( rand() * @terms ) ];
                }
                else {
                    $_;
                }
            } @{ $bot->store->get($term) || [] };

            return unless (@facts);

            my $text;
            if ( grep { /^<(?:action|reply)>/i } @facts ) {
                my $fact = $facts[ int( rand() * @facts ) ];
                $text = $fact if ( $fact =~ s|^<\s*action\s*>\s*|/me |i or $fact =~ s|^<\s*reply\s*>\s*||i );
            }
            $bot->reply(
                $text //
                "$display_term is " . $bot->list( ', ', 'and', map { s/[.,;:?!]+$//; $_ } @facts ) . '.'
            );
        },
    );

    $bot->hook(
        {
            to_me => 1,
            text  => qr/^no\W+(?<term>\([^\)]+\)|\S+)\s+(?:is|=)\s+(?<fact>.+?)$/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            ( my $term = lc( $m->{term} ) ) =~ s/[\(\)]+//g;

            $bot->store->set( $term => [ $m->{fact} ] );
            $bot->reply_to('OK.');
        },
    );

    $bot->hook(
        {
            to_me => 1,
            text  => qr/^forget\W+(?<term>\([^\)]+\)|[^.,:;?!\s]+)/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            ( my $term = lc( $m->{term} ) ) =~ s/[\(\)]+//g;

            $bot->store->set( $term => [] );
            $bot->reply_to('OK.');
        },
    );

    $bot->hook(
        {
            to_me => 1,
            text  => qr/^info\s+on\s+(?<term>\([^\)]+\)|[^.,:;?!\s]+)/i,
        },
        sub {
            my ( $bot, $in, $m ) = @_;

            ( my $term = lc( $m->{term} ) ) =~ s/[\(\)]+//g;
            my @facts = @{ $bot->store->get($term) || [] };

            $bot->reply_to(
                (@facts)
                    ? "\"$m->{term}\" is " . $bot->list( ', ', 'and', @facts )
                    : "I have no information on \"$m->{term}\"."
            );
        },
    );

    $bot->helps( infobot =>
        'Mimics the factoid functionality of the classic infobot. ' .
        'Usage: https://metacpan.org/pod/Bot::IRC::Infobot'
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::Infobot - Bot::IRC add classic "infobot" functionality to the bot

=head1 VERSION

version 1.42

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['Infobot'],
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin adds classic "infobot" functionality to the bot.

=head2 Remembering Factoids

    <user> thing is great
    <user> thing is awesome
    <user> thing is wonderful

=head2 Recalling Factoids

    <user> thing?
    <bot> thing is great, awesome, and wondeful.

=head2 Overwriting Factoids

    <user> bot no thing is terrible
    <bot> user: OK.
    <user> thing?
    <bot> thing is terrible.

=head2 Forgetting Factoids

    <user> bot forget thing
    <bot> user: OK.

=head2 Reply Factoids

A factiod that begins with "<reply>" will have the "<noun> is" missing in the
reply.

    <user> stuff is <reply> What stuff?
    <user> stuff?
    <bot> What stuff?

=head2 Action Factoids

A factoid that begins "<action>" will be emoted as a response.

    <user> sad is <action> cries in a corner.
    <user> sad?
    <bot> * bot cries in a corner.

=head2 Multiple Answers

Pipes ("|") indicate different possible answers selected at random.

    <user> d6 is 1|2|3|4|5|6
    <user> d6?
    <bot> 5
    <user> d6?
    <bot> 3

=head2 Learning What the Bot Knows

    <user> bot info on d6
    <bot>user: d6 is 1|2|3|4|5|6

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

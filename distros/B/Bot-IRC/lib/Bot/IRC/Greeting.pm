package Bot::IRC::Greeting;
# ABSTRACT: Bot::IRC greet joining users to channels

use 5.012;
use strict;
use warnings;

use DateTime;
use DateTime::Format::Human::Duration;

our $VERSION = '1.25'; # VERSION

sub init {
    my ($bot)    = @_;
    my $vars     = $bot->vars;
    my $greeting = ( not ref $vars ) ? $vars : $vars->{greeting} // 'greetings';
    my $channels = ( ref $vars ) ? $vars->{channels} : undef;

    $bot->hook(
        {
            command => 'JOIN',
        },
        sub {
            my ( $bot, $in ) = @_;

            unless ( ref $channels and not grep { $_ eq $in->{forum} } @$channels ) {
                $bot->reply_to( greeting_based_on_nick( $greeting, $in->{nick} ) );
                return;
            }
        },
    ) unless ( defined $channels and not ref $channels and $channels == 0 );
}

sub greeting_based_on_nick {
    my ( $greeting, $nick ) = @_;

    if ( $nick !~ /[a-z]/ ) {
        $greeting = uc($greeting);
    }
    else {
        for ( my $i = 0; $i < length($greeting) and $i < length( $nick ); $i++ ) {
            my $letter = substr( $nick, $i, 1 );
            substr( $greeting, $i, 1, uc( substr( $greeting, $i, 1 ) ) ) if ( $letter =~ /[A-Z]/ );
        }
    }
    $greeting =~ tr/oi/01/ if ( $nick =~ /[0-9]/ );
    $greeting .= $1 if ( $nick =~ /(_+)$/ );

    return $greeting;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::Greeting - Bot::IRC greet joining users to channels

=head1 VERSION

version 1.25

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['Greeting'],
        vars    => {
            greeting => {
                greeting => 'morning',
                channels => [ '#perl', '#perl-help' ],
            },
        },
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin causes the bot to greet joining users to channels.
By default, it will say something like "greetings" to whomever joins. The bot
will change the style of "greetings" to somewhat match the user's nick style.
For example, if "John" joins, the bot will say "Greetings" to him. If
"joan_" joins, the bot will say "greetings_" to her.

You can specify the greeting word and channel list with C<vars>.

    greeting => 'morning',
    channels => [ '#perl', '#perl-help' ],

If greeting isn't specified, the bot will use "greetings" as the greeting. If
a channel list isn't supplied, the bot will greet on all channels it's on. If
you specify a greeting of empty string or some other false value, the greeting
will get skipped.

=head2 SEE ALSO

L<Bot::IRC>

=for Pod::Coverage init greeting_based_on_nick

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

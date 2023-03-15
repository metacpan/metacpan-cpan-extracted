package Bot::BasicBot::Pluggable::Module::Title;
$Bot::BasicBot::Pluggable::Module::Title::VERSION = '1.30';
use base qw(Bot::BasicBot::Pluggable::Module);
use warnings;
use strict;

use Text::Unidecode;
use URI::Title qw(title);
use URI::Find::Simple qw(list_uris);
use URI;

sub help {
    return "Speaks the title of URLs mentioned.";
}

sub init {
    my $self = shift;
    $self->config(
        {
            user_asciify   => 1,
            user_ignore_re => '',
            user_be_rude   => 0,
        }
    );
}

sub admin {

    # do this in admin so we always get a chance to see titles
    my ( $self, $mess ) = @_;

    # If the message was from the bot (for e.g. another module announcing the
    # title of an URL we just said, etc), go no further, to avoid loops
    return if $mess->{who} eq $self->bot->nick;

    my $ignore_regexp = $self->get('user_ignore_re');

    my $reply = "";
    for ( list_uris( $mess->{body} ) ) {
        next if $ignore_regexp && /$ignore_regexp/;
        my $uri = URI->new($_);
        next unless $uri;
        if ( $uri->scheme eq "file" ) {
            next unless $self->get("user_be_rude");
            my $who = $mess->{who};
            $self->reply( $mess, "Nice try $who, you tosser" );
            return;
        }

        my $title = title("$_");
        next unless defined $title;
        $title = unidecode($title) if $self->get("user_asciify");
        $reply .= "[ $title ] ";
    }

    if ($reply) { $self->reply( $mess, $reply ) }

    return;    # Title.pm is passive, and doesn't intercept things.
}

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::Title - speaks the title of URLs mentioned

=head1 VERSION

version 1.30

=head1 IRC USAGE

None. If the module is loaded, the bot will speak the titles of all URLs mentioned.

=head1 VARS

=over 4

=item asciify

Defaults to 1; whether or not we should convert all titles to ascii from Unicode

=item ignore_re

If set to a nonempty string, ignore URLs matching this re

=back

=head1 REQUIREMENTS

L<URI::Title>

L<URI::Find::Simple>

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

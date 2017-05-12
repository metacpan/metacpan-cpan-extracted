package Bot::targa;

our $VERSION = '0.01';

1;

__END__

=encoding utf8

=head1 NAME

Bot::targa - yet another italian bot

=begin HTML

<p><a href="https://metacpan.org/pod/Bot::targa" target="_blank"><img alt="CPAN version" src="https://badge.fury.io/pl/Bot-targa.svg"></a></p>

=end HTML

=head1 INSTALLATION

    cpan Bot::targa

=head1 CONFIGURATION

Create a C<.bottargarc> file, something like

    [server]
    hostname=chat.freenode.net
    port=6667
    channel=#linux-it
    nick=bottarga
    username=bottarga
    name=https://it.wikipedia.org/wiki/Bottarga

    [google]
    key=
    cx=

=cut


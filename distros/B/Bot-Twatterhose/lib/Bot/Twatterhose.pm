package Bot::Twatterhose;
BEGIN {
  $Bot::Twatterhose::VERSION = '0.04';
}
use 5.010;
use autodie;
use Any::Moose;
use Any::Moose 'X::Getopt';
use Any::Moose 'X::Types::'.any_moose() => [qw/Int Str Bool HashRef/];
use JSON;
use Hailo;
use Net::Twitter::Lite;
use Scalar::Util qw(blessed);
use namespace::clean -except => 'meta';

with any_moose('X::Getopt::Dashes');

has help => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'h',
    isa           => Bool,
    is            => 'ro',
    documentation => "You're soaking it in",
);

has username => (
    traits        => [ qw/ Getopt / ],
    isa           => Str,
    is            => 'ro',
    cmd_aliases   => 'u',
    documentation => "Your Twitter username",
);

has password => (
    traits        => [ qw/ Getopt / ],
    isa           => Str,
    is            => 'ro',
    cmd_aliases   => 'p',
    documentation => "Your Twitter password",
);

has brain => (
    traits        => [ qw/ Getopt / ],
    isa           => Str,
    is            => 'ro',
    cmd_aliases   => 'b',
    documentation => "The Hailo brain to use",
);

has limit => (
    traits        => [ qw/ Getopt / ],
    isa           => Int,
    default       => 1000,
    is            => 'ro',
    cmd_aliases   => 'l',
    documentation => "The number of twats to consume from the firehose",
);

has _twatter => (
    traits        => [ qw/ NoGetopt / ],
    isa           => 'Net::Twitter::Lite',
    is            => 'ro',
    documentation => "Net::Twatter::Lite instance",
    lazy_build    => 1,
);

sub _build__twatter {
    my ($self) = @_;

    my $twatter = Net::Twitter::Lite->new(
        username   => $self->username,
        password   => $self->password,
        source     => 'twatterhose',
        traits     => ['API::REST'],
        clientname => 'Twatterhose twatterbot',
        clienturl  => 'http://github.com/avar/bot-twatterhose',
    );

    return $twatter;
}

sub run {
    my ($self) = @_;

    my $hailo = Hailo->new(brain => $self->brain);

    my $callback = sub {
        my ($twat, $data) = @_;

        my $text = $twat->{text};
        return unless $text;
        return unless length $text >= 70;
        # Twitter sucks
        $text =~ s/&gt;/</g;
        $text =~ s/&lt;/>/g;

        if ($data->{count}++ >= $self->limit) {
            # Say something on Twatter
            my $reply = $self->get_reply($hailo);
            my $twatter = $self->_twatter;
            local $@;
            eval {
                $twatter->update($reply);
            };
            if ($@) {
                if (!blessed($@) || !$@->isa('Net::Twitter::Error::Lite')) {
                    die "Unknown Net::Twitter::Lite error: $@";
                }
            } else {
                # Updated status, all OK
                say "Twatted: $reply";
                exit 0;
            }
        } else {
            if ($text =~ /^[[:ascii:]]+$/ and $text !~ /\n/ and $text !~ m[://]) {
                $hailo->learn($text);
                say sprintf "Got twat %d/%d: %s", $data->{count}, $self->limit, $text;
            } else {
                say sprintf "NOT twat %d/%d: %s", $data->{count}, $self->limit, $text;
            }
        }
    };

    $self->twatterhose($callback);
}

sub get_reply {
    my ($self, $hailo) = @_;

    while (1) {
        my $reply = $hailo->reply();
        return $reply if length $reply <= 140;
    }
}

sub twatterhose {
    my ($self, $callback) = @_;

    my ($username, $password) = map { $self->$_ } qw(username password);
    my $cmd = "curl -s http://stream.twitter.com/1/statuses/sample.json -u${username}:${password}";
    open my $twitter, "$cmd |";

    my $data = {};
    while (my $line = <$twitter>) {
        chomp $line;

        my $twat = from_json($line);
        $callback->($twat, $data);
    }
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bot::Twatterhose - Consume the Twitter firehose and babble to Twitter with L<Hailo>

=head1 SYNOPSIS

    # Consume 500 tweets and twat one based on those
    twatterhose --username someuser --password somepass --brain twatterhose.brn --limit 500

    # Put this in cron, wait a few years and a cult will have formed
    # around your bot:
    */30 * * * * (sleep $(($RANDOM % 3600))) && twatterhose --username someuser --password somepass --brain ~/twatterhose.brn

=head1 DESCRIPTION

Uses the L<twitter streaming
API|http://apiwiki.twitter.com/Streaming-API-Documentation> to get
tweets from the firehose, feeds those to L<Hailo> and tweets a random
permutation of the previous input to Twitter.

The author is trying to start a religion larger than L. Ron Hubbard's.

=head1 AUTHOR

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

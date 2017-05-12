use strict;
use Test::More 0.82 tests => 1;
use Test::Output qw(output_from);
use IO::Socket::INET;
use App::Pastebin::sprunge;

BEGIN {
    $^W = 0; # Disable warnings because HTTP::Request::Common warns spuriously
    *STDIN = *DATA; # Fake out the library being tested - how sneaky!
    @ARGV = ();
}
use warnings;

my $sock = IO::Socket::INET->new(
    PeerHost => 'sprunge.us',
    PeerPort => 80,
    Timeout  => 5,
    Type     => SOCK_STREAM,
);

SKIP: {
    skip "Couldn't connect to sprunge.us: $!", 1
        unless defined $sock;
    $sock->close;

    my ($out, $err) = output_from {
        eval { App::Pastebin::sprunge->new->run };
        print STDERR $@;
    };

    skip 'Test needs to be updated; email doherty@cpan.org'
        if $err and $err =~ /No such paste/;
    like $out => qr{http://sprunge.us/[a-zA-Z]+},
        'Paste created - and done correctly';
}

__DATA__
text
more text

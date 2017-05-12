use strict;
use warnings;

use Test::Is qw(extended);
use Test::More 0.82 tests => 1;
use Test::Output qw(output_from);
use IO::Socket::INET;
use App::Pastebin::sprunge;

BEGIN {
    @ARGV = qw(ILSD);
}

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
    skip 'Test needs to be updated; email doherty@cpan.org', 1
        if $err and $err =~ /No such paste/;
    like $out => qr/ohaithar/, 'Paste retrieved - and done correctly';
}

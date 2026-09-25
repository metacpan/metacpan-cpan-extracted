use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

# Without real root: unshare --user --map-auto --map-root-user prove -b xt/foreign_owner.t
plan skip_all => 'needs root (or a user namespace) to give a file to another user'
    unless $> == 0;

my $other = 65534;
my $dir   = tempdir(CLEANUP => 1);

my @kinds = (
    [ 'Str', sub { Data::ReqRep::Shared->new($_[0], 16, 4, 256) },
             sub { Data::ReqRep::Shared::Client->new($_[0]) } ],
    [ 'Int', sub { Data::ReqRep::Shared::Int->new($_[0], 16, 4) },
             sub { Data::ReqRep::Shared::Int::Client->new($_[0]) } ],
);

for my $k (@kinds) {
    my ($name, $server, $client) = @$k;
    my $path = "$dir/$name.shm";
    { my $s = $server->($path) }
    chown $other, $other, $path or plan skip_all => "cannot chown to $other: $!";
    chmod 0666, $path or die $!;

    ok !eval { $client->($path); 1 }, "$name: a client refuses a world-writable file another user owns";
    like $@, qr/world-writable file owned by another user/, '  and says why';
    ok !eval { $server->($path); 1 }, "$name: so does a server attaching to it";
    like $@, qr/world-writable file owned by another user/, '  and says why';

    chmod 0660, $path or die $!;
    ok eval { $client->($path); 1 }, "$name: the same file shared by group mode attaches"
        or diag $@;
    ok eval { $server->($path); 1 }, "$name: for a server too" or diag $@;
}

done_testing;

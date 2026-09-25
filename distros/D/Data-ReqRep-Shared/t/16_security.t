use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

my $dir = tempdir(CLEANUP => 1);
my $n   = 0;

my %kind = (
    Str => { new    => sub { Data::ReqRep::Shared->new($_[0], 4, 2, 64, undef, @_[1 .. $#_]) },
             client => 'Data::ReqRep::Shared::Client' },
    Int => { new    => sub { Data::ReqRep::Shared::Int->new($_[0], 4, 2, @_[1 .. $#_]) },
             client => 'Data::ReqRep::Shared::Int::Client' },
);

sub mode_of { (stat $_[0])[2] & 07777 }

for my $name (sort keys %kind) {
    my $k = $kind{$name};
    for my $umask (0, 022, 077) {
        my $old = umask $umask;
        my $p = "$dir/m" . ++$n;
        $k->{new}->($p);
        is sprintf('%04o', mode_of($p)), '0600', sprintf "$name: owner-only by default under umask %03o", $umask;
        $p = "$dir/m" . ++$n;
        $k->{new}->($p, 0660);
        is sprintf('%04o', mode_of($p)), '0660', sprintf "$name: an explicit 0660 is exact under umask %03o", $umask;
        umask $old;
    }

    my $channel = "$dir/other" . ++$n;
    $k->{new}->($channel);
    my $link = "$dir/link" . ++$n;
    symlink $channel, $link or die $!;
    ok !eval { $k->{new}->($link); 1 }, "$name: new refuses a symlink to another channel";
    ok !eval { $k->{client}->new($link); 1 }, "$name: a client refuses it too";

    my $empty = "$dir/empty" . ++$n;
    open my $fh, '>', $empty or die $!;
    close $fh;
    $link = "$dir/link" . ++$n;
    symlink $empty, $link or die $!;
    ok !eval { $k->{new}->($link); 1 }, "$name: new refuses a symlink to an empty file";
    is -s $empty, 0, '  and does not initialize the file behind it';

    my $dangling = "$dir/link" . ++$n;
    symlink "$dir/absent$n", $dangling or die $!;
    ok !eval { $k->{new}->($dangling); 1 }, "$name: new refuses a dangling symlink";
    ok !-e "$dir/absent$n", '  and creates nothing at its target';
}

subtest 'a mode the owner cannot open, or with bits beyond 07777, croaks' => sub {
    my $n = 0;
    for my $bad ([Str => sub { Data::ReqRep::Shared->new("$dir/mode" . ++$n, 4, 2, 64, undef, $_[0]) }],
                 [Int => sub { Data::ReqRep::Shared::Int->new("$dir/mode" . ++$n, 4, 2, $_[0]) }]) {
        my ($name, $make) = @$bad;
        for my $mode (0, 0400, 4096, 0200600) {
            ok !eval { $make->($mode); 1 }, sprintf "%s: mode %#o croaks", $name, $mode;
        }
        ok eval { $make->(0660); 1 }, "$name: 0660 is fine" or diag $@;
    }
};

subtest 'a handle unlinks only the file it has, not a newer one at its path' => sub {
    for my $v ([Str => 'Data::ReqRep::Shared', 'Data::ReqRep::Shared::Client', [64]],
               [Int => 'Data::ReqRep::Shared::Int', 'Data::ReqRep::Shared::Int::Client', []]) {
        my ($name, $sc, $cc, $extra) = @$v;
        my $path = "$dir/restart$name";
        my $old = $sc->new($path, 4, 2, @$extra);
        $sc->unlink($path);
        my $new = $sc->new($path, 4, 2, @$extra);
        $old->unlink;
        ok -e $path, "$name: the old handle leaves the new file in place";
        ok eval { $cc->new($path); 1 }, '  and clients still attach to it' or diag $@;
        $new->unlink;
        ok !-e $path, '  while the new handle removes its own';
    }
};

subtest 'setting a handle\'s own eventfd keeps it open' => sub {
    use POSIX ();
    for my $v ([eventfd => 'eventfd_set'], [reply_eventfd => 'reply_eventfd_set']) {
        my ($get, $set) = @$v;
        my $srv = Data::ReqRep::Shared->new(undef, 4, 2, 64);
        my $fd = $srv->$get;
        $srv->$set($fd);
        ok defined POSIX::dup($fd), "$set with the handle's own descriptor leaves it open";
    }
};

done_testing;

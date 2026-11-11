use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use IO::Select ();
use ClamAV::Clamd;
use FakeClamd;

# start_scan takes bytes, a path or a descriptor, and each kind has its own
# refusals. All of it against the fake.

plan skip_all => 'needs UNIX sockets' unless ClamAV::Clamd::_sun_path_max();

my $dir = File::Temp->newdir();
my $path = "$dir/f.bin";
{
    open my $fh, '>:raw', $path or die $!;
    print {$fh} 'z' x 70_000;
    close $fh;
}

sub drive {
    my ($s) = @_;
    my $guard = 0;
    until ($s->is_done) {
        die 'drive() ran away' if ++$guard > 100_000;
        my $fd   = $s->fd;
        my $want = $s->want // '';
        if (defined $fd && $want) {
            my $set = IO::Select->new($fd);
            $want eq 'read'
                ? IO::Select->select($set, undef, undef, 0.5)
                : IO::Select->select(undef, $set, undef, 0.5);
        }
        $s->step;
    }
    return $s;
}

my $want = ClamAV::Clamd->have_fd_passing ? 'fildes' : 'instream';

# --- over a UNIX socket --------------------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok');
    my $c   = ClamAV::Clamd->new(socket => $srv->path);

    my $s = drive($c->start_scan($path, 'path'));
    is $s->verdict->state, 'clean', 'a path';
    is $s->verdict->transport, $want, "  over $want";

    $s = $c->start_scan("$dir/nope", 'path');
    ok $s->is_done, 'a path that cannot be opened is finished at once';
    is $s->verdict->state, 'error', '  as an error';
    like $s->verdict->error, qr/open/, '  from the open';

    open my $fh, '<:raw', $path or die $!;
    $s = drive($c->start_scan($fh, 'fd'));
    is $s->verdict->state, 'clean', 'a filehandle';
    is $s->verdict->transport, $want, "  over $want";
    close $fh;

    $s = $c->start_scan('nope', 'fd');
    ok $s->is_done, 'a word is not a descriptor';
    like $s->verdict->error, qr/start_scan needs an open filehandle/, '  and says so';

    $s = $c->start_scan(undef);
    ok $s->is_done, 'undef is not bytes';
    like $s->verdict->error, qr/start_scan needs bytes/, '  and says so';

    $s = $c->start_scan("\x{263A}");
    ok $s->is_done, 'wide characters are not bytes';
    like $s->verdict->error, qr/wide characters/, '  and say so';

    my $m = ClamAV::Clamd->new(socket => $srv->path, max_size => 3);
    $s = $m->start_scan('four');
    ok $s->is_done, 'bytes over max_size are refused at once';
    is $s->verdict->state, 'unscannable', '  as unscannable';
    is $s->verdict->reason, 'max_size', '  naming the ceiling';

    $srv->stop;
}

# --- over TCP, where a descriptor is streamed ---------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok', tcp => 1);
    my $c   = ClamAV::Clamd->new($srv->target);

    open my $fh, '<:raw', $path or die $!;
    my $s = drive($c->start_scan($fh, 'fd'));
    is $s->verdict->state, 'clean', 'a filehandle over TCP';
    is $s->verdict->transport, 'instream', '  is streamed';
    close $fh;

    $s = drive($c->start_scan($path, 'path'));
    is $s->verdict->state, 'clean', 'a path over TCP';
    is $s->verdict->transport, 'instream', '  is streamed';

    $srv->stop;
}

done_testing;

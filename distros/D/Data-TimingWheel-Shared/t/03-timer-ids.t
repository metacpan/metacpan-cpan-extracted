use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::TimingWheel::Shared;

my $tw = Data::TimingWheel::Shared->new(undef, 8, 1);
for my $release (qw(cancel fire clear)) {
    my $old = $tw->add(1, 10);
    if ($release eq 'cancel') { $tw->cancel($old) }
    elsif ($release eq 'fire') { $tw->advance }
    else { $tw->clear }
    my $new = $tw->add(1, 20);
    isnt $new, $old, "$release changes the reused slot's id";
    is $tw->cancel($old), 0, "$release leaves the old id inactive";
    is_deeply [$tw->advance], [20], "$release: stale cancel preserves the new timer";
}

my $dir = tempdir(CLEANUP => 1);
my $path = "$dir/wrap.tw";
{ my $wheel = Data::TimingWheel::Shared->new($path, 8, 1); }

# Start the free slot two leases before wrap without billions of operations.
open my $fh, '+<', $path or die $!;
binmode $fh;
seek $fh, 48, 0 or die $!;
read($fh, my $offset, 8) == 8 or die "read timer offset: $!";
seek $fh, unpack('Q<', $offset) + 28, 0 or die $!;
print {$fh} pack('L<', 0xfffffffc) or die $!;
close $fh or die $!;

$tw = Data::TimingWheel::Shared->new($path, 8, 1);
my $old;
for my $phase (qw(before at after)) {
    my $id = $tw->add(2, 30);
    ok $id, "$phase wrap: timer id is nonzero";
    is $tw->cancel(0), 0, "$phase wrap: zero sentinel never cancels a timer";
    is $tw->cancel($old), 0, "$phase wrap: previous id stays inactive" if defined $old;
    is $tw->cancel($id), 1, "$phase wrap: returned id cancels its timer";
    is $tw->count, 0, "$phase wrap: cancellation frees the slot";
    $old = $id;
}
$tw->add(2, 40);
is_deeply [$tw->advance(2)], [40], 'timer still fires correctly after generation wrap';

done_testing;

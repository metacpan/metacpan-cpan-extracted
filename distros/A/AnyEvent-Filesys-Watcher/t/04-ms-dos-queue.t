use strict;

use Test::More;

# FIXME! This test should later run on MS-DOS only because it is not needed
# for other systems.

use_ok 'AnyEvent::Filesys::Watcher';
use_ok 'AnyEvent::Filesys::Watcher::ReadDirectoryChanges::Queue';

my $q = AnyEvent::Filesys::Watcher::ReadDirectoryChanges::Queue->new;
ok $q, 'instantiated';
isa_ok $q, 'AnyEvent::Filesys::Watcher::ReadDirectoryChanges::Queue';

my $handle = $q->handle;
ok $handle, 'handle';
isa_ok $handle, 'IO::Handle';

my $select = IO::Select->new($handle);

$q->enqueue('foo', 'bar', 'baz');

is $q->pending, 3, '3 items pending';
ok $select->can_read(0), '3 items available, can read';

my @items = $q->dequeue(2);
is $items[0], 'foo', 'dequeued foo';
is $items[1], 'bar', 'dequeued bar';

is $q->pending, 1, '1 item pending';
ok $select->can_read(0), '1 item available, can read';

my ($item) = $q->dequeue(1);
is $item, 'baz', 'dequeued baz';

is $q->pending, 0, 'no item pending';
ok !$select->can_read(0), 'no item available, cannot read';

$q->enqueue('foobarbaz');
is $q->pending, 1, '1 new item pending';
ok $select->can_read(0), '1 new item available, can read';

done_testing;

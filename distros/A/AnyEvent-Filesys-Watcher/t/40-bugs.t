use strict;
use warnings;

use Test::More tests => 2;

use AnyEvent::Filesys::Watcher::Event;

my $e = AnyEvent::Filesys::Watcher::Event->new(
	path => 'some/path',
	type => 'modified',
	is_directory => undef,
);

isa_ok $e, "AnyEvent::Filesys::Watcher::Event";
ok !$e->isDirectory, 'isDirectory';

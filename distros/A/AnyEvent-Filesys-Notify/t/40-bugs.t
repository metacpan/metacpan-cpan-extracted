use Test::More tests => 2;

use strict;
use warnings;

use AnyEvent::Filesys::Notify::Event;

my $e = AnyEvent::Filesys::Notify::Event->new(
    path   => 'some/path',
    type   => 'modified',
    is_dir => undef,
);

isa_ok( $e, "AnyEvent::Filesys::Notify::Event" );
ok( !$e->is_dir, 'is_dir' );

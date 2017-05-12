use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

# Test the behavior used by Catalyst::Engine::HTTP::Restarter::Watcher
use Test::More tests => 2;

use B::Hooks::OP::Check::StashChange;

my @stashes;
my $expected_stashes = [
    [ 'main' => undef ],
    [ 'Foo' => 'main' ],
    [ 'Foo::Bar' => 'Foo' ],
    [ 'Foo::Bar::Baz' => 'Foo::Bar'],
    [ 'main' => 'Foo::Bar::Baz' ],
];
my $fn = "$Bin/lib/Foo.pm";

stash_changes_loading_foo();
is_deeply \@stashes, $expected_stashes, 'runtime require in eval';

@stashes = ();
delete $INC{$fn};
stash_changes_loading_foo();
shift(@$expected_stashes); # We no longer see the undef => main transition
is_deeply \@stashes, $expected_stashes,
    'runtime require in eval after delete from %INC';

sub stash_changes_loading_foo {
    my $id = B::Hooks::OP::Check::StashChange::register(sub {
        push @stashes, [@_];
    });

    eval "require '$fn';";

    B::Hooks::OP::Check::StashChange::unregister($id);
}

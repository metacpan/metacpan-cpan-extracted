package t::OwnFieldEntity;
use strict;
use warnings;
use Class::Accessor::TrackDirty;

Class::Accessor::TrackDirty->mk_tracked_accessors(qw(key1 key2));
Class::Accessor::TrackDirty->mk_accessors(qw(mtime));
Class::Accessor::TrackDirty->mk_new;

sub dummy {
    return $_[0]->{dummy} if @_ == 1;
    $_[0]->{dummy} = $_[1];
}


package main;
use strict;
use warnings;
use Test::More;

my $now = time;
{
    my $entity = t::OwnFieldEntity->new(
        key1 => 10, dummy => 20, mtime => $now,
    );
    is $entity->dummy, 20;

    $entity->dummy(undef);
    is $entity->dummy, undef;

    $entity->dummy(30);
    is $entity->dummy, 30;

    my $hash_ref = $entity->is_dirty ? $entity->to_hash : {};
    is $hash_ref->{key1}, 10;
    is $hash_ref->{mtime}, $now;
    ok ! exists $hash_ref->{dummy}, "Don't store undefined fields.";

    ok ! $entity->is_dirty, "Cleaned";
    is $entity->mtime, $now, "Don't break normal fields.";
    is $entity->dummy, 30, "Don't touch to my private field.";
}

{
    my $entity = t::OwnFieldEntity->from_hash(key1 => 10, dummy => 20);
    is $entity->dummy, 20;

    $entity->dummy(undef);
    is $entity->dummy, undef;

    $entity->dummy(30);
    is $entity->dummy, 30;
}

done_testing;

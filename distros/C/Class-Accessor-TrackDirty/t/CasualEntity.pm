package t::CasualEntity;
use strict;
use warnings;
use Class::Accessor::TrackDirty;

Class::Accessor::TrackDirty->mk_tracked_accessors(qw(key1 key2));
Class::Accessor::TrackDirty->mk_accessors(qw(mtime));

sub new {
    my $class = shift;

    # I don't need any checks :)
    bless {@_ == 1 ? %{$_[0]} : @_} => $class;
}

1;

package Data::CompactReadonly::V0::TiedArray;
our $VERSION = '0.0.4';

use strict;
use warnings;

sub TIEARRAY {
    my($class, $object) = @_;
    return bless([ $object ], $class);
}

sub EXISTS    { shift()->[0]->exists(shift()); }
sub FETCH     { shift()->[0]->element(shift()); }
sub FETCHSIZE { shift()->[0]->count(); }

sub STORE     { die("Illegal access: store: this is a read-only database\n"); }
sub STORESIZE { shift()->STORE() }
sub DELETE    { shift()->STORE() }
sub CLEAR     { shift()->STORE() }
sub PUSH      { shift()->STORE() }
sub POP       { shift()->STORE() }
sub SHIFT     { shift()->STORE() }
sub UNSHIFT   { shift()->STORE() }
sub SPLICE    { shift()->STORE() }

1;

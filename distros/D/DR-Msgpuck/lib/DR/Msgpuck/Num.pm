use utf8;
use strict;
use warnings;

package DR::Msgpuck::Num;
use Carp;
use Scalar::Util ();
use overload
    bool        => sub { ${ $_[0] } ? 1 : 0 },
    int         => sub { int ${ $_[0] } },
    '""'        => sub { ${ $_[0] } },
;

sub new {
    my ($class, $v) = @_;
    croak "Argument doesn't look like number"
        unless Scalar::Util::looks_like_number $v;
    bless \$v => ref($class) || $class;
}

sub TO_MSGPACK {
    require DR::Msgpuck;
    my ($self) = @_;
    DR::Msgpuck::msgpack($$self);
}

1;

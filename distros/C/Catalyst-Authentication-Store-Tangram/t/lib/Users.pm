package Users;
use strict;
use warnings;
use Carp qw/confess/;
use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors(qw/username password groups/);

sub new {
    my ($class, %p) = @_;
    bless { %p }, $class;
}

package Roles;
use strict;
use warnings;
use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors(qw/name/);

sub new {
    my ($class, %p) = @_;
    bless { %p }, $class;
}

1;

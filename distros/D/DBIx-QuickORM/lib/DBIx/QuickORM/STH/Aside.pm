package DBIx::QuickORM::STH::Aside;
use strict;
use warnings;

our $VERSION = '0.000014';

use Carp qw/croak/;

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::STH';
with 'DBIx::QuickORM::Role::Async';

use parent 'DBIx::QuickORM::STH::Async';
use DBIx::QuickORM::Util::HashBase;

sub clear { $_[0]->{+CONNECTION}->clear_aside($_[0]) }

1;

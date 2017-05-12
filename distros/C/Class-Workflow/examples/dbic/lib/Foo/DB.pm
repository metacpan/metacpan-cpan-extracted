#!/usr/bin/perl

package # hide from pause
Foo::DB;

use strict;
use warnings;

use base qw(DBIx::Class::Schema);

__PACKAGE__->load_classes();

__PACKAGE__

__END__

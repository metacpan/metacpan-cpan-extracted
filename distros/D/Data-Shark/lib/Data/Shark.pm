#
# Data::Shark.pm
#
# Copyright (C) 2007 William Walz. All Rights Reserved
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
#

package Data::Shark;

use version; our $VERSION = qv('2.1');

use strict;

sub import {
    my $class = shift;
    $class->VERSION (@_);

    my @l = @_ ? @_ : qw(DBI FIO DIO Util);

    eval join("", map { "require Data::Shark::" . (/(\w+)/)[0] . ";\n" } @l)
	or croak $@;
}

1;

__END__

=head1 NAME

Data::Shark - load various Data::Shark modules

=head1 SYNOPSIS

use Data::Shark;

=head1 DESCRIPTION

B<Data::Shark> provides a simple mechanism to load some of the Data::Shark
modules at one go.

Currently this includes:

      Data::Shark::DB
      Data::Shark::DIO
      Data::Shark::FIO
      Data::Shark::Util

Plese see the Google Code page for more documentation. It will eventually
be rolled into the POD.

L<http://code.google.com/p/sharkapi-perl/>

=head2 Data::Shark::DBI

The database layer provides some simple wrappers around the DBI.  By
using the simple wrappers a single point of error/status logging can
be achieved, along with code size reduction.

=head2 Data::Shark::DIO

The DIO module generates data access functions.  This allows a simple
consistant interface for all data interaction, the functions can be read
into memory or placed in file.  Each function is defined by a namespace,
group, name, type, statement, return type, etc.  And has a set of input
keys and output keys.  Currently SQL access is supported, but others will
be added.  This modules removes any data access dependencies from
a program.  There is also support for caching, replication and
profiling.

The attributes can be stored in a RDBMS for easy administration.

Example:

    my $result = MyNameSpace::MyGroup::get_customer(
      {'customer_id' => $cid});

If the return type is a hash, then the results are placed in a hash
reference.

    $result->{'name'}, $result->{'address'}, etc.

=head2 Data::Shark::FIO

The module FIO generates a form access that class that handles
validation and events, etc. Like the DIO module these attributes can
be stored in a RDBMS for easy administration.

NOTE: This module is under construntion.

=head2 Data::Shark::Util

The Util module contains a collection of helper methods.

=head1 SEE ALSO

L<perl>

L<DBI>

=head1 DEPENDENCIES

This module requires these other modules and libraries:

  perl >= 5.8.0
  DBI
  File::FileCache
  SQL::Abstract

=head1 AUTHORS

    William Walz (Jack)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 William Walz. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

#!/usr/bin/perl

package DBIx::POS::Test;

use strict;
use base qw{DBIx::POS};
__PACKAGE__->instance (__FILE__);

=name testing

=desc test the DBI::POS module

=param

Some arbitrary parameter

=sql

There is really no syntax checking done on the content of the =sql section.

=cut

package main;

use strict;
use warnings;
use Test::More tests => 3;
use YAML qw{Dump};

ok (my $sql = DBIx::POS::Test->instance, "Get an instance of the SQL");

is ($sql->{testing}->{sql}, "There is really no syntax checking done on the content of the =sql section.\n", "Make sure our SQL came through");

is ("$sql->{testing}", "There is really no syntax checking done on the content of the =sql section.\n", "Make sure our SQL stringifies");

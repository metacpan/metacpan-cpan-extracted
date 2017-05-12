#!/usr/bin/perl -I. -w
use strict;

use Test::More tests => 1;

sub set_sql
{ }

BEGIN { use_ok( 'Class::DBI::Plugin::AbstractCount' ) }

__END__

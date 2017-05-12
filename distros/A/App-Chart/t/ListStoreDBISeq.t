#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2012 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Test::More 0.82 tests => 1;

require App::Chart::Gtk2::Ex::ListStoreDBISeq;


# DBI::_new_dbh() and DBI::_new_sth() use substr() lvalue assignments which
# seems to keep the lexical target $imp_class alive, until the next call to
# each function, and that looks like a leak of the $imp_class values stored
# into $dbh->{'ImplementorClass'} and $sth->{'ImplementorClass'}, or rather
# in the underlying tied hash object.  Dunno if this is some perl 5.10.0
# thing, but as a hack make a new run of _new_dbh() and _new_sth() here to
# clear out the scratchpad.
#
sub hack_clear_new_handle_scratchpad {
  my $fh = File::Temp->new (TEMPLATE => 'dbh-scratchpad-XXXXXX',
                            SUFFIX => '.sqdb',
                            TMPDIR => 1);
  my $filename = $fh->filename;
  my $dbh = DBI->connect ("dbi:SQLite:dbname=$filename",
                          '', '', {RaiseError=>1});
  $dbh->prepare ('CREATE TABLE foo (bar INT)');
  $dbh->disconnect;
}


#------------------------------------------------------------------------------

# Test::Weaken 2.002 for leaks() style
my $have_test_weaken = eval "use Test::Weaken 2.002; 1";
if (! $have_test_weaken) { diag "Test::Weaken 2.002 not available -- $@"; }

# Test::Weaken::ExtraBits
my $have_test_weaken_extrabits = eval "use Test::Weaken::ExtraBits; 1";
if (! $have_test_weaken_extrabits) {
  diag "Test::Weaken::ExtraBits not available -- $@";
}

SKIP: {
  $have_test_weaken or skip 'due to no Test::Weaken available', 1;
  $have_test_weaken_extrabits
    or skip 'due to Test::Weaken::ExtraBits not available', 1;

  require File::Temp;
  require DBI;
  my $fh = File::Temp->new (TEMPLATE => 'ListStoreDBISeq-test-XXXXXX',
                            SUFFIX => '.sqdb',
                            TMPDIR => 1);
  my $filename = $fh->filename;
  diag "temp file $filename";

  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $dbh = DBI->connect ("dbi:SQLite:dbname=$filename",
                                 '', '', {RaiseError=>1});
         $dbh->do ('CREATE TABLE mytable (
                      seq        INT      NOT NULL,
                      data       TEXT     DEFAULT NULL
                    )');
         $dbh->do ('INSERT INTO mytable (seq, data) VALUES (0, "hello")');

         my $ls = App::Chart::Gtk2::Ex::ListStoreDBISeq->new
           (dbh => $dbh,
            table => 'mytable',
            columns => ['data']);
         my $iter = $ls->get_iter_first;
         diag ($ls->get_value($iter,0));

         hack_clear_new_handle_scratchpad();
         return [ $ls, $dbh ];
       },
       ignore => \&Test::Weaken::ExtraBits::ignore_DBI_globals,
     }
    );
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  if ($leaks) {
    diag "Test-Weaken ", explain $leaks;

    foreach my $ref (@{$leaks->unfreed_proberefs}) {
      diag "seeking unfreed: ", explain $ref;
      MyTestHelpers::findrefs ($ref);
    }
  }
}

exit 0;

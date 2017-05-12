#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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


use 5.008;
use strict;
use warnings;

use Test::More 0.82 tests => 2;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use AppChartTestHelpers;

# uncomment this to run the ### lines
#use Smart::Comments;

require App::Chart::Gtk2::Ticker;


# use DBI;
# ### connect: DBI->can('connect')
# {
#   my $orig = \&DBI::connect;
#   *DBI::connect = sub {
#     my $ret = &$orig(@_);
#     ### DBI connect(): "$ret"
#     return $ret;
#   };
# }
# ### disconnect: DBI->can('disconnect')
# {
#   my $orig = \&DBI::disconnect;
#   *DBI::disconnect = sub {
#     my $ret = &$orig(@_);
#     ### DBI disconnect(): "$ret"
#     return $ret;
#   };
# }


#------------------------------------------------------------------------------

require App::Chart::Gtk2::SymlistListModel;
{
  my $model = App::Chart::Gtk2::SymlistListModel->new;
  require Scalar::Util;
  Scalar::Util::weaken ($model);
  is ($model, undef, 'garbage collect after weaken');
}

#------------------------------------------------------------------------------

# Test::Weaken 2.002 for "ignore"
my $have_test_weaken = eval "use Test::Weaken 2.002; 1";
if (! $have_test_weaken) { diag "Test::Weaken 2.002 not available -- $@"; }

# Test::Weaken::ExtraBits
my $have_test_weaken_extrabits = eval "use Test::Weaken::ExtraBits; 1";
if (! $have_test_weaken_extrabits) {
  diag "Test::Weaken::ExtraBits not available -- $@";
}

sub my_ignores {
  my ($ref) = @_;
  ### check ignore: "$ref"

  # Class_Singleton for App::Chart::Gtk2::SymlistList
  return (Test::Weaken::ExtraBits::ignore_Class_Singleton($ref)
          || AppChartTestHelpers::ignore_symlists($ref)
          || AppChartTestHelpers::ignore_global_dbi($ref)
          || AppChartTestHelpers::ignore_all_dbi($ref)
         );
}

# use Scalar::Util 'reftype';
# sub my_contents {
#   my ($ref) = @_;
#   ### contents: "$ref ".reftype($ref)
#   if (reftype($ref) eq 'HASH') {
#     # my @keys = keys %$ref;
#     my $keys = join(' ',map {"$_=$ref->{$_}"} keys %$ref);
#     ### $keys
#   }
#   return;
# }

SKIP: {
  $have_test_weaken
    or skip 'due to Test::Weaken 2.002 not available', 1;
  $have_test_weaken_extrabits
    or skip 'due to Test::Weaken::ExtraBits not available', 1;

  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $model = App::Chart::Gtk2::SymlistListModel->new;
         ### dbh: "$model->{'dbh'}"
         return $model->{'sth'};
       },
       # contents => \&my_contents,
       ignore => \&my_ignores,
     });
  is ($leaks, undef, 'Test::Weaken deep garbage collection');
  if ($leaks) {
    diag "Test-Weaken ", explain $leaks;

    my $unfreed = $leaks->unfreed_proberefs;
    foreach my $proberef (@$unfreed) {
      diag "  unfreed $proberef";
    }
    foreach my $proberef (@$unfreed) {
      diag "  search $proberef";
      MyTestHelpers::findrefs($proberef);
    }
  }
}
exit 0;

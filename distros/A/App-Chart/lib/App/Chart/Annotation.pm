# Copyright 2008, 2009, 2010, 2011, 2015 Kevin Ryde

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


package App::Chart::Annotation;
use 5.010;
use strict;
use warnings;
use Carp 'carp';

use App::Chart::Database;

use constant DEBUG => 0;

sub delete {
  my ($self) = @_;
  if (DEBUG) { print "Annotation delete ",$self->table,
                 " symbol ",$self->{'symbol'}," id ",$self->{'id'},"\n"; }
  my $table = $self->table;
  my $symbol = $self->{'symbol'};
  my $id = $self->{'id'};

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $rows = $dbh->do ("DELETE FROM $table WHERE symbol=? AND id=?",
                       undef, $symbol, $id);
  if ($rows != 1) {
    carp ("Annotation delete: oops, affected $rows\n");
  }
  App::Chart::chart_dirbroadcast()->send ('data-changed', { $symbol => 1 });
}

sub clone {
  my ($self) = @_;
  return bless { %$self }, ref ($self);
}

sub ensure_id {
  my ($self, $symbol) = @_;
  return ($self->{'id'} ||= do {
    my $table = $self->table;
    my $last_id = App::Chart::Database::read_notes_single
      ("SELECT id FROM $table WHERE symbol=?
        ORDER BY id DESC LIMIT 1",
       $symbol);
    ($last_id||0) + 1;
  });
}

sub next_id {
  my ($table, $symbol) = @_;
  my $last_id = App::Chart::Database::read_notes_single
    ("SELECT id FROM $table WHERE symbol=? ORDER BY id DESC LIMIT 1",
     $symbol);
  return ($last_id || 0) + 1;
}

sub swap_ends {
}

#------------------------------------------------------------------------------

package App::Chart::Annotation::Alert;
use strict;
use warnings;
use base 'App::Chart::Annotation';

use constant DEBUG => 0;

sub new {
  my ($class, %self) = @_;
  return bless \%self, $class;
}

sub table { return 'alert'; }

sub t {
  my ($self, $new_t) = @_;
  if (@_ < 2) { return $self->{'t'}||0; }
  $self->{'t'} = $new_t;
}

sub price {
  my ($self, $newprice) = @_;
  if (@_ < 2) { return $self->{'price'}; }
  $self->{'price'} = $newprice;
}

sub write {
  my ($self) = @_;
  my $symbol = $self->{'symbol'};

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  App::Chart::Database::call_with_transaction
      ($dbh, sub {
         my $id = $self->ensure_id ($symbol);

         $dbh->do ('INSERT OR REPLACE INTO alert
                   (symbol, id, price, above)
                   VALUES (?,?, ?,?)',
                   undef, # DBI options
                   $symbol,
                   $id,
                   $self->{'price'},
                   $self->{'above'});
         update_alert ($symbol);
       });
  App::Chart::chart_dirbroadcast()->send ('data-changed', { $symbol => 1 });
}

sub delete {
  my ($self) = @_;
  $self->SUPER::delete;
  App::Chart::Annotation::Alert::update_alert ($self->{'symbol'});
}

sub draw {
  my ($self, $graph, $region) = @_;
  App::Chart::Gtk2::Graph::Plugin::Alerts->draw ($graph, $region, [ $self ]);
}

sub update_alert {
  my ($symbol) = @_;
  require App::Chart::Gtk2::Symlist::Alerts;
  my $symlist = App::Chart::Gtk2::Symlist::Alerts->instance;
  if (want_alert ($symbol)) {
    $symlist->insert_symbol ($symbol);
  } else {
    $symlist->delete_symbol ($symbol);
  }
}

# return true if $symbol should be in the Alerts list
sub want_alert {
  my ($symbol) = @_;
  if (DEBUG) { print "want_alert $symbol\n"; }

  # must be in all list, so not historical and not symbols deleted but with
  # user notes remaining
  require App::Chart::Gtk2::Symlist::All;
  my $symlist = App::Chart::Gtk2::Symlist::All->instance;
  $symlist->contains_symbol($symbol) or return 0;

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached ('SELECT price,above FROM alert
                                   WHERE symbol=?');
  my $alert_list = $dbh->selectall_arrayref ($sth, {Slice=>{}}, $symbol);
  $sth->finish;
  if (! @$alert_list) { return 0; } # no levels

  require App::Chart::Latest;
  my $latest = App::Chart::Latest->get ($symbol);

  foreach my $alert (@$alert_list) {
    if ($alert->{'above'}) {
      # look at bid, but if crossed to offer<bid then use only the offer,
      # ie. the lesser of the two
      my $above_price = App::Chart::max_maybe
        ($latest->{'last'},
         App::Chart::min_maybe ($latest->{'bid'}, $latest->{'offer'}))
          // return 0; # if nothing in latest record

      if (DEBUG) { print "  compare $above_price above ",
                     $alert->{'price'},"\n"; }
      if ($above_price >= $alert->{'price'}) { return 1; }

    } else {
      # look at offer, but if crossed to bid>offer then use only the bid,
      # ie. the greater of the two
      my $below_price = App::Chart::min_maybe
        ($latest->{'last'},
         App::Chart::max_maybe ($latest->{'bid'},
                                $latest->{'offer'}))
          // return 0; # if nothing in latest record

      if (DEBUG) { print "  compare $below_price below ",
                     $alert->{'price'},"\n"; }
      if ($below_price <= $alert->{'price'}) { return 1; }
    }
  }
}

package App::Chart::Annotation::Line;
use strict;
use warnings;
use Carp 'croak';
use Math::Round;
use base 'App::Chart::Annotation';

sub table { return 'line'; }

sub new_for_graph {
  my ($class, $graph, $x, $y) = @_;
  my $series = $graph->get('series_list')->[0] || return;
  my $symbol = $series->symbol
    || croak 'Cannot add line to non-database series';
  my $timebase = $series->timebase;
  my $t = $graph->x_to_date ($x);
  my $p = $graph->y_to_value ($y);
  my $date = $timebase->to_iso ($t);
  return bless { symbol  => $symbol,
                 id      => undef,
                 date1   => $date,
                 price1  => $p,
                 date2   => $date,
                 price2  => $p,
                 horizontal => 0,

                 timebase => $timebase,
                 t1      => $t,
                 t2      => $t }, $class;
}

sub App::Chart::Series::Database::AnnLines_arrayref {
  my ($series) = @_;
  return ($series->{__PACKAGE__.'.array'} ||= do {
    my $symbol = $series->symbol || '';
    require App::Chart::DBI;
    my $dbh = App::Chart::DBI->instance;

    my $sth = $dbh->prepare_cached ('SELECT * FROM line WHERE symbol=?');
    my $aref = $dbh->selectall_arrayref ($sth, {Slice=>{}}, $symbol);
    $sth->finish;
    my $timebase = $series->timebase;
    foreach my $elem (@$aref) {
      $elem->{'timebase'} = $timebase;
      $elem->{'t1'} = $timebase->from_iso_floor ($elem->{'date1'});
      $elem->{'t2'} = $timebase->from_iso_floor ($elem->{'date2'});
      bless $elem, __PACKAGE__;
    }
    $aref;
  });
}

sub t {
  my ($self, $new_t) = @_;
  if (@_ < 2) { return $self->{'t1'}; }
  $new_t = Math::Round::round ($new_t);
  $self->{'t1'} = $new_t;
  my $timebase = $self->{'timebase'};
  $self->{'date1'} = $timebase->to_iso ($new_t);
}

sub price {
  my ($self, $newprice) = @_;
  if (@_ < 2) { return $self->{'price1'}; }
  $self->{'price1'} = $newprice;
}

sub swap_ends {
  my ($self) = @_;
  swap ($self->{'date1'}, $self->{'date2'});

  { my $tmp = $self->{'t1'};
    $self->{'t1'} = $self->{'t2'};
    $self->{'t2'} = $tmp;
  }
  { my $tmp = $self->{'price1'};
    $self->{'price1'} = $self->{'price2'};
    $self->{'price2'} = $tmp;
  }
  return $self;
}

sub swap {
  my $tmp = $_[0]; $_[0] = $_[1]; $_[1] = $tmp;
}

sub write {
  my ($self) = @_;
  my $symbol = $self->{'symbol'};

  if ($self->{'horizontal'}) {
    $self->{'price2'} = $self->{'price1'};
  }

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  App::Chart::Database::call_with_transaction
      ($dbh, sub {
         my $id = $self->ensure_id ($symbol);

         $dbh->do ('INSERT OR REPLACE INTO line
                    (symbol,id, date1,price1,date2,price2,horizontal)
                    VALUES (?,?, ?,?,?,?,?)',
                   undef, # DBI options
                   $symbol,
                   $id,
                   $self->{'date1'},
                   $self->{'price1'},
                   $self->{'date2'},
                   $self->{'price2'},
                   $self->{'horizontal'});
       });
  App::Chart::chart_dirbroadcast()->send ('data-changed', { $symbol => 1 });
}

sub draw {
  my ($self, $graph, $region) = @_;
  App::Chart::Gtk2::Graph::Plugin::AnnLines->draw ($graph, $region, [ $self ]);
}

1;
__END__

# Copyright 2008, 2009, 2010, 2011, 2013, 2014, 2016 Kevin Ryde

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

package App::Chart::Vacuum;
use 5.010;
use strict;
use warnings;
use Carp;
use File::stat;
use Locale::TextDomain ('App-Chart');

use PerlIO::via::EscStatus;

use App::Chart::Annotation;
use App::Chart::Database;
use App::Chart::DBI;
use App::Chart::Download;
use App::Chart::Gtk2::Symlist::Alerts;
use App::Chart::Gtk2::Symlist::All;
use App::Chart::Gtk2::Symlist::Historical;

use constant VACUUM_AGE_DAYS => 14;

my $verbose = 0;

sub command_line_vacuum {
  my ($class, $output, $args) = @_;

  if ($output eq 'tty') {
    if (-t STDOUT) {
      binmode (STDOUT, ':via(EscStatus)')
        or die 'Cannot push EscStatus';
    } else {
      require PerlIO::via::EscStatus::ShowNone;
      binmode (STDOUT, ':via(EscStatus::ShowNone)')
        or die 'Cannot push EscStatus::ShowNone';
    }
  } elsif ($output eq 'all-status') {
    require PerlIO::via::EscStatus::ShowAll;
    binmode (STDOUT, ':via(EscStatus::ShowAll)')
      or die 'Cannot push EscStatus::ShowAll';
  }

  my %option;
  foreach my $arg (@$args) {
    if ($arg =~ /^no-?/ip) {
      $option{${^POSTMATCH}} = 0;
    } else {
      $option{$arg} = 1;
    }
  }
  vacuum(%option);
}

sub vacuum {
  my %option = @_;
  if (! exists $option{'compact'})     { $option{'compact'} = 1; }
  if (! exists $option{'consistency'}) { $option{'consistency'} = 1; }

  $verbose = $App::Chart::option{'verbose'};
  if (exists $option{'verbose'}) { $verbose = $option{'verbose'}; }

  App::Chart::Download::status (__('Vacuuming database'));

  expire_latest();
  expire_intraday();

  if ($option{'consistency'}) {
    check_listseq();
    check_alerts();
    check_historical();
    check_alphabetical();
  }
  if ($option{'compact'}) {
    vacuum_database();
    vacuum_notes();
  }
}

sub vacuum_notes {
  my $notes_filename = App::Chart::DBI::notes_filename();
  my $notes_oldsize = -s $notes_filename;
  App::Chart::Download::status (__x('VACUUM notes.sqdb ({oldsize} bytes)',
                                   oldsize => $notes_oldsize));

  require DBI;
  my $nbh = DBI->connect ("dbi:SQLite:dbname=$notes_filename",
                          '', '', {RaiseError=>1});
  $nbh->func(90_000, 'busy_timeout');  # 90 seconds
  $nbh->{sqlite_unicode} = 1;
  $nbh->do ('VACUUM');
  my $notes_newsize = -s $notes_filename;
  print __x("Notes was {oldsize} now {newsize} bytes\n",
            oldsize => $notes_oldsize,
            newsize => $notes_newsize);
}

sub vacuum_database {
  my $dbh = App::Chart::DBI->instance;
  my $database_filename = App::Chart::DBI::database_filename();
  my $database_oldsize = -s $database_filename;
  App::Chart::Download::status (__x('VACUUM database.sqdb ({oldsize} bytes)',
                                   oldsize => $database_oldsize));
  $dbh->do ('VACUUM');
  my $database_newsize = -s $database_filename;
  print __x("Database was {oldsize} now {newsize} bytes\n",
            oldsize => $database_oldsize,
            newsize => $database_newsize);
}

# old latest records discarded, except symbols in the database kept
# indefinitely, which in particular is for when the latest in fact comes
# from the daily data
#
sub expire_latest {
  App::Chart::Download::status (__('Delete old "latest" quotes'));

  my $dbh = App::Chart::DBI->instance;
  my $age_seconds = 86400 * VACUUM_AGE_DAYS;
  my @timestamp_range = App::Chart::Download::timestamp_range ($age_seconds);

  # "0+" avoids 0E0 when no records deleted
  my $n = 0 + $dbh->do
    ('DELETE FROM latest
      WHERE fetch_timestamp < ? OR fetch_timestamp > ?
      AND NOT EXISTS (SELECT * FROM info WHERE info.symbol=latest.symbol)',
     undef,
     @timestamp_range);
  my ($kept) = $dbh->selectrow_array ('SELECT COUNT(*) FROM latest');

  print __nx("deleted {n} old latest record (leaving {kept})\n",
             "deleted {n} old latest records (leaving {kept})\n",
             $n,
             n => $n,
             kept => $kept);
}

sub expire_intraday {
  App::Chart::Download::status (__('Delete old intraday images'));

  my $dbh = App::Chart::DBI->instance;
  my $age_seconds = 86400 * VACUUM_AGE_DAYS;
  my @timestamp_range = App::Chart::Download::timestamp_range ($age_seconds);

  # "0+" avoids 0E0 when no records deleted
  my $n = 0 + $dbh->do
    ('DELETE FROM intraday_image
      WHERE fetch_timestamp < ? OR fetch_timestamp > ?',
     undef,
     @timestamp_range);
  my ($kept) = $dbh->selectrow_array ('SELECT COUNT(*) FROM intraday_image');

  print __nx("deleted {n} old intraday image (leaving {kept})\n",
             "deleted {n} old intraday images (leaving {kept})\n",
             $n,
             n => $n,
             kept => $kept);
}

sub check_listseq {
  foreach my $symlist (App::Chart::Gtk2::Symlist->all_lists) {
    $symlist->fixup (verbose => $verbose,
                     message => sub {
                       my ($message) = @_;
                       print $symlist->name, ": $message\n";
                     });
  }
}

sub check_alerts {
  App::Chart::Download::status (__('Check Alerts list contents'));

  my $symlist = App::Chart::Gtk2::Symlist::Alerts->instance;

  my @symbol_list = $symlist->interested_symbols;
  if ($verbose) {
    print "Alerts interested:", join(' ',@symbol_list),"\n";
  }

  foreach my $symbol (@symbol_list) {
    my $want = App::Chart::Annotation::Alert::want_alert ($symbol);
    my $got = $symlist->contains_symbol ($symbol);
    if ($want && ! $got) {
      if ($verbose) {
        print "  $symbol: should be in Alerts, fixing\n";
      }
    } elsif (! $want && $got) {
      if ($verbose) {
        print "  $symbol: should not be in Alerts, fixing\n";
      }
    }
    App::Chart::Annotation::Alert::update_alert ($symbol);
  }

  @symbol_list = $symlist->symbols;
  if ($verbose) {
    print "Alerts now: ", join(' ',@symbol_list),"\n";
  }
}

sub check_historical {
  App::Chart::Download::status (__('Check Historical list contents'));

  my $symlist = App::Chart::Gtk2::Symlist::Historical->instance;

  my @symbol_list = App::Chart::Database->symbols_list();
  if ($verbose) {
    print "Historical check:", join(' ',@symbol_list),"\n";
  }

  foreach my $symbol (@symbol_list) {
    my $want = App::Chart::Download::want_historical ($symbol);
    my $got = $symlist->contains_symbol ($symbol);
    if (defined $want && ! $got) {
      if ($verbose) {
        print "  $symbol: should be historical: $want\n";
      }
      App::Chart::Download::consider_historical ([$symbol]);

    } elsif (! defined $want && $got) {
      if ($verbose) {
        print "  $symbol: should not be historical, fixing\n";
      }
      # Symbol not historical exists, so let add_symbol() do its raising out
      # of historical (like in App::Chart::Download::download()).
      App::Chart::Database->add_symbol ($symbol);
    }
  }

  @symbol_list = $symlist->symbols;
  if ($verbose) {
    print "Historical now: ", join(' ',@symbol_list),"\n";
  }
}

sub check_alphabetical {
  App::Chart::Download::status (__('Check alphabetical symlists order'));

  foreach my $symlist (App::Chart::Gtk2::Symlist::all_lists()) {
    next unless $symlist->isa('App::Chart::Gtk2::Symlist::Alphabetical');

    if ($verbose) {
      print $symlist->key, " ", $symlist->name, "\n";
      my @symbol_list = $symlist->symbols;
      print "  ",join(' ', @symbol_list), "\n";
    }

    if (! symlist_is_alphabetical_ok ($symlist)) {
      symlist_re_alphabetize ($symlist);
    }
  }
}
sub symlist_is_alphabetical_ok {
  my ($symlist) = @_;
  my @symbol_list = $symlist->symbols;

  foreach my $i (1 .. $#symbol_list) {
    my $prev = $symbol_list[$i-1];
    my $this = $symbol_list[$i];
    my $order = App::Chart::symbol_cmp ($this, $prev);
    if ($order < 0) {
      print $symlist->name," '$this' should be before '$prev', fixing whole list\n";
      return 0;
    }
    if ($order == 0) {
      print $symlist->name," '$this' duplicated, fixing whole list\n";
      return 0;
    }
  }
  if ($verbose) {
    print "  good\n";
  }
  return 1;
}
sub symlist_re_alphabetize {
  my ($symlist) = @_;
  my @symbol_list = $symlist->symbols;
  if ($verbose) {
    print "  ",join(' ', @symbol_list), "\n";
  }
  my $dbh = App::Chart::DBI->instance;
  App::Chart::Database::call_with_transaction
      ($dbh, sub {
         foreach my $symbol (reverse @symbol_list) {
           $symlist->delete_symbol ($symbol);
         }
         foreach my $symbol (@symbol_list) {
           $symlist->insert_symbol ($symbol);
         }
       });

  @symbol_list = $symlist->symbols;
  if ($verbose) {
    print "  Now: ",join(' ', @symbol_list), "\n";
  }
}

1;
__END__

=for stopwords intraday SQLite

=head1 NAME

App::Chart::Vacuum -- compact and cleanup the database

=head1 FUNCTIONS

=over 4

=item App::Chart::Vacuum::vacuum (key=>value, ...)

Run the vacuum cleaner over the database.

Latest price and intraday image records older than 14 days are deleted and
the SQLite C<VACUUM> command is run to compact the F<database.sqdb> and
F<notes.sqdb> files.  Consistency checks on the symbol list contents are
applied.  Status messages and compacted sizes are printed.

This is the operative part of the C<--vacuum> command line option and the
Vacuum dialog box.

=back

=head1 SEE ALSO

L<App::Chart::Gtk2::VacuumDialog>,
L<App::Chart>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011, 2013, 2014, 2016 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut

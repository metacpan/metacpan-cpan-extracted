# Copyright 2007, 2008, 2009, 2010, 2011, 2016, 2017 Kevin Ryde

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

package App::Chart::Database;
use 5.010;
use strict;
use warnings;
use Carp;

use App::Chart;
use App::Chart::DBI;

# uncomment this to run the ### lines
#use Devel::Comments;


#------------------------------------------------------------------------------

# return true if $dbh contains a table called $table
sub dbh_table_exists {
  my ($dbh, $table) = @_;
  my $sth = $dbh->table_info (undef, undef, $table, undef);
  my $exists = $sth->fetchrow_arrayref ? 1 : 0;
  $sth->finish;
  return $exists;
}


sub read_single {
  return App::Chart::DBI->read_single (@_);
  #   my ($sql, @args) = @_;
  #   my $dbh = App::Chart::DBI->instance;
  #   my $sth = $dbh->prepare_cached ($sql);
  #   my $row = $dbh->selectrow_arrayref($sth, undef, @args);
  #   $sth->finish;
  #   if (! defined $row) { return undef; }
  #   return $row->[0];
}

sub read_notes_single {
#   my ($sql, @args) = @_;
#   if (DEBUG) { print "read_notes_single(): $sql\n"; }
  return App::Chart::DBI->read_single (@_);
  #   my $nbh = App::Chart::DBI->instance;
  #   my $sth = $nbh->prepare_cached ($sql);
  #   my $row = $nbh->selectrow_arrayref($sth, undef, @args);
  #   $sth->finish;
  #   if (! defined $row) { return undef; }
  #   return $row->[0];
}

# might prefer some sort of "INSERT WHERE NOT EXISTS", but sqlite doesn't
# seem to take that (only it's own extension "INSERT OR IGNORE")
#
sub add_symbol {
  my ($class, @symbol_list) = @_;
  ### Database add_symbol(): @symbol_list
  require App::Chart::Gtk2::Symlist::All;
  require App::Chart::Gtk2::Symlist::Historical;
  require App::Chart::Annotation;
  my $all_symlist = App::Chart::Gtk2::Symlist::All->instance;
  my $historical_symlist = App::Chart::Gtk2::Symlist::Historical->instance;

  my $dbh = App::Chart::DBI->instance;
  call_with_transaction
    ($dbh, sub {
       my $sth = $dbh->prepare_cached
         ('UPDATE info SET historical=0 WHERE symbol=?');
       foreach my $symbol (@symbol_list) {
         if ($class->symbol_exists ($symbol)) {
           $sth->execute ($symbol);
           $sth->finish;
         } else {
           $dbh->do ('INSERT INTO info (symbol) VALUES (?)', {}, $symbol);
         }
         $all_symlist->insert_symbol ($symbol);
         $historical_symlist->delete_symbol ($symbol);
         # possible existing alert levels
         App::Chart::Annotation::Alert::update_alert($symbol);
       }
     });
}


sub delete_symbol {
  my ($class, $symbol, $notes_too) = @_;
  ### Database delete_symbol(): $symbol
  ### $notes_too

  # sqlite allows multiple statements in one handle, but that's apparently
  # not always so in DBI

  require App::Chart::Gtk2::Symlist::All;
  require App::Chart::Gtk2::Symlist::Historical;
  require App::Chart::Annotation;
  my $all_symlist = App::Chart::Gtk2::Symlist::All->instance;
  my $historical_symlist = App::Chart::Gtk2::Symlist::Historical->instance;

  my $dbh = App::Chart::DBI->instance;
  call_with_transaction
    ($dbh, sub {
       foreach my $statement
         ('DELETE FROM daily        WHERE symbol=?',
          'DELETE FROM info         WHERE symbol=?',
          'DELETE FROM dividend     WHERE symbol=?',
          'DELETE FROM split        WHERE symbol=?',
          'DELETE FROM extra        WHERE symbol=?') {
         $dbh->do($statement, undef, $symbol);
       }
       if ($notes_too) {
         foreach my $statement
           ('DELETE FROM annotation WHERE symbol=?',
            'DELETE FROM line       WHERE symbol=?',
            'DELETE FROM alert      WHERE symbol=?') {
           $dbh->do($statement, undef, $symbol);
         }
       }
       $all_symlist       ->delete_symbol ($symbol);
       $historical_symlist->delete_symbol ($symbol);
       # delete from alerts list
       App::Chart::Annotation::Alert::update_alert($symbol);
     });

  App::Chart::chart_dirbroadcast()->send ('delete-symbol', $symbol);
  App::Chart::chart_dirbroadcast()->send ('data-changed', { $symbol => 1 });
  App::Chart::chart_dirbroadcast()->send ('delete-notes', $symbol);
}

sub symbol_exists {
  my ($class, $symbol) = @_;
  return read_single ('SELECT symbol FROM info WHERE symbol=?', $symbol);
}

# return a hashref which has for its keys all the symbols in the database
# (the daily data, not quotes or intraday)
sub database_symbols_hash {
  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached('SELECT symbol FROM info');
  my $aref = $dbh->selectcol_arrayref ($sth, { });
  $sth->finish();
  my %hash = ();
  @hash{@$aref} = 1;
  return \%hash;
}

sub symbols_list {
  # my ($class) = @_;
  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached('SELECT symbol FROM info');
  my $aref = $dbh->selectcol_arrayref ($sth);
  $sth->finish();
  return @$aref;
}

sub symbol_is_historical {
  my ($class, $symbol) = @_;
  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached('SELECT historical FROM info WHERE symbol=?');
  my $aref = $dbh->selectrow_arrayref ($sth, undef, $symbol);
  return ($aref && $aref->[0]);
}

sub symbol_name {
  my ($class, $symbol) = @_;
  return read_single ('SELECT name FROM info WHERE symbol=?', $symbol);
}

sub symbol_decimals {
  my ($class, $symbol) = @_;
  return (read_single ('SELECT decimals FROM info WHERE symbol=?', $symbol)
          || 0);
}

sub write_extra {
  my ($class, $symbol, $key, $value) = @_;
  if (! defined $key) { croak 'write_extra() key cannot be undef'; }

  my $dbh = App::Chart::DBI->instance;
  if (defined $value) {
    my $sth = $dbh->prepare_cached
      ('INSERT OR REPLACE INTO extra (symbol, key, value) VALUES (?,?,?)');
    $sth->execute ($symbol, $key, $value);
    $sth->finish;
  } else {
    $dbh->do ('DELETE FROM extra WHERE symbol=? AND key=?',
              undef,
              $symbol, $key);
  }
}

sub read_extra {
  my ($class, $symbol, $key) = @_;
  return read_single ('SELECT value FROM extra WHERE symbol=? AND key=?',
                      $symbol, $key);
}

# An eval isn't backtrace friendly, but a __DIE__ handler would be reached
# by possible normal errors caught by a handler in $subr.
#
# rollback() can get errors too, like database gone away.  They end up
# thrown in preference to the original error.
#
sub call_with_transaction {
  my ($dbh, $subr) = @_;
  my $hold = App::Chart::chart_dirbroadcast()->hold;

  if ($dbh->{AutoCommit}) {
    my $ret;
    $dbh->begin_work;
    if (eval { $ret = $subr->(); 1 }) {
      $dbh->commit;
      return $ret;
    } else {
      my $err = $@;
      $dbh->rollback;
      die $err;
    }

  } else {
    $subr->();
  }
}

sub preference_get {
  my ($class, $key, $default) = @_;
  my $value = read_notes_single
    ('SELECT value FROM preference WHERE key=?', $key);
  if (defined $value) {
    return $value;
  } else {
    return $default;
  }
}


1;
__END__

=for stopwords delisted

=head1 NAME

App::Chart::Database -- database functions

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Database->add_symbol ($symbol) >>

Add C<$symbol> to the database.  If C<$symbol> is already in the database
then remove its "historical" marker.

=item C<< App::Chart::Database->delete_symbol ($symbol, $notes_too) >>

Delete all data relating to C<$symbol> from the database.  If C<$notes_too>
is given and it's true then delete user notes and annotations too.

=back

=head2 Symbol Info

=over 4

=item C<< App::Chart::Database->symbol_exists ($symbol) >>

Return true if C<$symbol> exists in the database.

=item App::Chart::Database->symbol_is_historical ($symbol)

Return true if C<$symbol> is marked as historical, meaning it's delisted, or
renamed, or whatever, but in any case is no longer actively trading.

=item C<< App::Chart::Database->symbol_name ($symbol) >>

Return the stock or commodity name for C<$symbol>, obtained from the
database.

=item C<< App::Chart::Database->symbol_decimals ($symbol) >>

Return the number of decimal places normally shown on prices for C<$symbol>.
For example prices in dollars might have this as 2 to show dollars and
cents.

It's possible particular prices in the database or a quote might have more
than this many places.  The return is 0 if there's no information on
C<$symbol>.

=back

=head2 Other

=over 4

=item C<< $value = App::Chart::Database->read_extra ($symbol, $key) >>

=item C<< App::Chart::Database->write_extra ($symbol, $key, $value) >>

Read or write extra data associated with C<$symbol>.  C<$key> is a string
describing the data, C<$value> is a string or C<undef>.  C<undef> means
delete the data.

C<$symbol> can be the empty string "" for global extra data.  Some data
sources cache information this way.

=back

=head1 SEE ALSO

L<App::Chart>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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


# =item C<App::Chart::Database::call_with_transaction ($dbh, $subr)>
# 
# Call C<$subr> with a transaction setup on C<$dbh>.  If C<$dbh> doesn't
# already have a transaction active then one is started, C<$subr> is called,
# and it's then committed.  Otherwise if C<$dbh> is already in a transaction
# then C<$subr> is simply called with no other action, part of that existing
# transaction.


# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::Intraday;
use 5.010;
use strict;
use warnings;

use App::Chart;

# uncomment this to run the ### lines
#use Smart::Comments;

sub command_line_download {
  my ($class, $args) = @_;

  ## no critic (ProhibitExit, ProhibitExitInSubroutines)
  my ($symbol, $mode) = @$args;
  if (@$args != 2 || ref($symbol) || ref($mode)) {
    print "Expect symbol and mode arguments for --intraday\n";
    exit 1;
  }
  require App::Chart::IntradayHandler;
  my $handler = App::Chart::IntradayHandler->handler_for_symbol_and_mode
    ($symbol, $mode);
  if (! $handler) {
    print "No intraday handler for symbol \"$symbol\" and mode \"$mode\"\n";
    exit 1;
  }
  $handler->download ($symbol);
}


#------------------------------------------------------------------------------

sub write_intraday_image {
  my %args = @_;

  require App::Chart::DBI;
  my $dbh = App::Chart::DBI->instance;
  my $sth = $dbh->prepare_cached
    ('INSERT OR REPLACE INTO intraday_image (symbol, mode, image, error, fetch_timestamp, url, etag, last_modified)
      VALUES (?,?,?,?,?,?,?,?)');

  my $image = $args{'image'};
  if (defined $image && length($image) == 0) { $image = undef; }
  my $resp = $args{'resp'};
  my $etag = (defined $resp ? scalar $resp->header('ETag') : undef);
  my $last_modified = (defined $resp ? $resp->last_modified : undef);

  my $symbol = $args{'symbol'};
  my $mode   = $args{'mode'};
  $sth->bind_param (1, $symbol);
  $sth->bind_param (2, $mode);
  $sth->bind_param (3, $image, DBI::SQL_BLOB());
  $sth->bind_param (4, $args{'error'});
  $sth->bind_param (5, App::Chart::Download::timestamp_now());
  $sth->bind_param (6, $args{'url'});
  $sth->bind_param (7, $etag);
  $sth->bind_param (8, $last_modified);
  $sth->execute;
  $sth->finish;

  ### send intraday-changed
  ### $symbol
  ### $mode
  App::Chart::chart_dirbroadcast()->send ('intraday-changed', $symbol, $mode);
}

1;
__END__

# =for stopwords intraday
# 
# =head1 NAME
# 
# App::Chart::Intraday -- intraday image functions
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::Intraday;
# 
# =head1 FUNCTIONS
# 
# =over 4
# 
# =item App::Chart::Intraday::write_intraday_image (key=>value, ...)
# 
# The parameters are taken in key/value style
# 
#     symbol   string
#     mode     string
#     image    raw bytes
#     url      string (optional)
#     resp     HTTP::Response object (optional)
# 
# The C<image> bytes are stored in the database under C<symbol> and C<mode>.
# Optional C<url> and C<resp> can be given to record C<ETag> and
# C<Last-Modified> headers to possibly avoid a re-download next time.
# 
# =back

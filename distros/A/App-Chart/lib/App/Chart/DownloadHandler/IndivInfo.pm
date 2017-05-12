# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

package App::Chart::DownloadHandler::IndivInfo;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
# use Locale::TextDomain ('App-Chart');

use base 'App::Chart::DownloadHandler';
use App::Chart;
use App::Chart::Database;
use App::Chart::DBI;


use constant DEFAULT_INFO_CHECK_DAYS => 10;

sub new {
  my ($class, %options) = @_;
  $options{'name'} or croak "missing name for ".__PACKAGE__;
  $options{'key'} or croak "missing key for ".__PACKAGE__;
  $options{'url_func'} or croak "missing chunk_size for ".__PACKAGE__;
  $options{'recheck_days'} ||= DEFAULT_INFO_CHECK_DAYS;

  return $class->SUPER::new (%options,
                             proc => \&indivinfo_download,
                             proc_with_self => 1,
                             recheck_key => $options{'key'} . '-timestamp',
                             max_symbols => 1);
}

sub indivinfo_download {
  my ($self, $symbol_list) = @_;
  my $symbol = $symbol_list->[0];

  my $dbh = App::Chart::DBI->instance;
  my $recheck_key = $self->{'recheck_key'};
  my $timestamp = App::Chart::Download::timestamp_now();

  App::Chart::Download::status ($self->{'name'}, $symbol);

  my $url = $self->{'url_func'}->($symbol);
  my $resp = App::Chart::Download->get ($url, allow_404 => 1);

  my $h;
  if ($resp->is_success) {
    $h = $self->{'parse'}->($symbol, $resp);
  } else {
    $h = {};
  }
  my $changed = 0;
  App::Chart::Database::call_with_transaction
      ($dbh, sub {
         if (exists $h->{'name'}) {
           App::Chart::Download::set_symbol_name ($symbol, $h->{'name'});
           $changed = 1;
         }
         if (exists $h->{'currency'}) {
           App::Chart::Download::set_currency ($symbol, $h->{'currency'});
           $changed = 1;
         }
         App::Chart::Database->write_extra
             ($symbol, $recheck_key, $timestamp);
       });
  if ($changed) {
    App::Chart::chart_dirbroadcast()->send ('data-changed', { $symbol => 1 });
  }
}

1;
__END__

# =head1 NAME
# 
# App::Chart::DownloadHandler::IndivInfo -- individual symbols in date range chunks
# 
# =for test_synopsis my ($pred)
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::DownloadHandler::IndivInfo;
#  App::Chart::DownloadHandler::IndivInfo->new
#      (name  => __('FooEX'),
#       pred  => $pred,
#       url_func => \&my_url,
#       parse    => \&my_page_parser);
# 
# =head1 DESCRIPTION
# 
# This module downloads and processes daily data in date range chunks for one
# symbol at a time.  This is the style required for Yahoo Finance for
# instance.
# 
# =head1 SEE ALSO
# 
# L<App::Chart::DownloadHandler>
# 
# =cut

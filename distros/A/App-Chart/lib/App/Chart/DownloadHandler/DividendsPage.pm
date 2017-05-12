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

package App::Chart::DownloadHandler::DividendsPage;
use 5.010;
use strict;
use warnings;
use Carp;
# use Locale::TextDomain ('App-Chart');

use base 'App::Chart::DownloadHandler';
use App::Chart;
use App::Chart::Database;
use App::Chart::Download;


use constant DEFAULT_DIVIDENDS_CHECK_DAYS => 3;

sub new {
  my ($class, %options) = @_;
  $options{'name'} or croak "missing name for ".__PACKAGE__;
  $options{'key'} or croak "missing key for ".__PACKAGE__;
  $options{'url'} or croak "missing url for ".__PACKAGE__;
  $options{'recheck_days'} ||= DEFAULT_DIVIDENDS_CHECK_DAYS;
  return $class->SUPER::new (%options,
                             proc => \&dividends_download,
                             proc_with_self => 1,
                             recheck_key => $options{'key'} . '-timestamp');
}

sub dividends_download {
  my ($self, $symbol_list) = @_;
  my $pred = $self->{'pred'};

  my $key = $self->{'key'};
  my $etag_key = $key . '-etag';
  my $lastmod_key = $key . '-last-modified';
  my $etag = App::Chart::Database->read_extra ('', $etag_key);
  my $lastmod = App::Chart::Database->read_extra ('', $lastmod_key);

  App::Chart::Download::status ($self->{'name'});
  my $resp = App::Chart::Download->get ($self->{'url'},
                                       etag => $etag,
                                       last_modified => $lastmod);

  my $h;
  if ($resp->is_success) {
    # got data
    $h = $self->{'parse'}->($resp);
    $h->{'url_tags_key'} = $key;
  } else {
    # no data, 304 unmodified, empty to just update times
    $h = { dividends => [] };
  }
  $h->{'recheck_key'}  = $self->{'recheck_key'};
  $h->{'recheck_pred'} = $self->{'pred'};

  App::Chart::Download::write_daily_group ($h);
}

1;
__END__

# =head1 NAME
# 
# App::Chart::DownloadHandler::DividendsPage -- single page of dividends
# 
# =for test_synopsis my ($pred)
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::DownloadHandler::DividendsPage;
#  App::Chart::DownloadHandler::DividendsPage-> new
#      (name  => __('FooEX'),
#       pred  => $pred,
#       url   => 'http://fooex.com/dividends.html',
#       parse => \&my_page_parser,
#       key   => 'FEX-dividends');
# 
# =head1 DESCRIPTION
# 
# This module downloads and processes dividends found on a single page
# covering all shares on a given exchange.  Usually such a page is just for
# current or upcoming dividends (as opposed to historical dividend
# information).
# 
# =head1 SEE ALSO
# 
# L<App::Chart::DownloadHandler>
# 
# =cut

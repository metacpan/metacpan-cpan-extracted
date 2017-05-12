# Web page download and cache.

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

package App::Chart::Pagebits;
use 5.010;
use strict;
use warnings;
use Carp;
use Data::Dumper;

use App::Chart;
use App::Chart::Database;
use App::Chart::Download;

sub get {
  my %options = @_;

  $options{'name'} or croak "Pagebits missing 'name'\n";
  my $url    = $options{'url'} || croak "Pagebits missing 'url'\n";
  my $method = $options{'method'} || 'GET';
  my $data   = $options{'data'};
  my $key    = $options{'key'} || croak "Pagebits missing 'key'\n";
  my $parse  = $options{'parse'} || croak "Pagebits missing 'parse'\n";
  my $freq_days = $options{'freq_days'}
    || croak "Pagebits missing 'freq_days'\n";

  my $str = App::Chart::Database->read_extra ('', $key);
  my $h = eval ($str || '{}');
  if (! App::Chart::Download::timestamp_within ($h->{'timestamp'},
                                               $freq_days * 86400)) {
    App::Chart::Download::status ($options{'name'});
    my $resp = App::Chart::Download->get
      ($url,
       method        => $method,
       data          => $data,
       etag          => $h->{'ETag'},
       last_modified => $h->{'Last-Modified'});

    if ($resp->is_success) {
      my $content = $resp->decoded_content (raise_error=>1);
      $h = $parse->($content);
      $h->{'ETag'} = scalar $resp->header('ETag');
      $h->{'Last-Modified'} = $resp->last_modified;
    }
    $h->{'timestamp'} = App::Chart::Download::timestamp_now();

    my $dumper = Data::Dumper->new ([$h], ['var']);
    $dumper->Indent(1);
    $dumper->Terse(1);
    $dumper->Sortkeys(1);
    $str = $dumper->Dump;
    App::Chart::Database->write_extra ('', $key, $str);
  }

  return $h;
}

1;
__END__

# =head1 NAME
# 
# App::Chart::Pagebits -- web page download, parse and cache
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::Pagebits;
#  my $hashref = App::Chart::Pagebits::get (url => 'http://...',
#                                          key => 'foo',
#                                          parse => \&func,
#                                          frequency => 5); # days
# 
# =head1 FUNCTIONS
# 
# =over 4
# 
# =item App::Chart::Pagebits::get (key=>value,...)
# 
# =back
# 
# =cut

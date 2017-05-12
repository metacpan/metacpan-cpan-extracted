# Intraday graphs.

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

package App::Chart::IntradayHandler;
use 5.006;
use strict;
use warnings;
use Locale::TextDomain ('App-Chart');

use App::Chart;

# uncomment this to run the ### lines
#use Smart::Comments;

our @handler_list = ();

sub new {
  my $class = shift;
  my $self = bless ({ @_ }, $class);
  App::Chart::Sympred::validate ($self->{'pred'});
  push @handler_list, $self;
  @handler_list = sort { $a->{'name'} cmp $b->{'name'} } @handler_list;
  return $self;
}

sub handlers_for_symbol {
  my ($class, $symbol) = @_;
  App::Chart::symbol_setups ($symbol);
  return grep { $_->{'pred'}->match($symbol) } @handler_list;
}

sub handler_for_symbol_and_mode {
  my ($class, $symbol, $mode) = @_;
  my @found
    = grep {$_->{'mode'} eq $mode} $class->handlers_for_symbol ($symbol);
  return $found[0];
}

sub download {
  my ($self, $symbol) = @_;
  ### IntradayHandler download: $symbol
  my ($image, $error, $resp);

  my $mode = $self->{'mode'};
  my $proc = $self->{'proc'};
  my ($url, %options);
  if (! eval { ($url, %options) = $proc->($self, $symbol, $mode); 1 }) {
    # mainly errors downloading procs like Barchart.pm
    $error = $@;
  } else {
    require App::Chart::Download;
    require App::Chart::Intraday;

    App::Chart::Download::status
        (__x('Intraday image {symbol} {mode}',
             symbol => $symbol,
             mode   => $mode));
    App::Chart::Download::verbose_message ("Intraday image", $url);

    require App::Chart::UserAgent;
    my $ua = App::Chart::UserAgent->instance;

    if (exists $options{'cookie_jar'}) {
      ### IntradayHandler cookie_jar: $options{'cookie_jar'}->as_string
      $ua->cookie_jar ($options{'cookie_jar'});
    } else {
      $ua->cookie_jar ({});
    }

    require HTTP::Request;
    my @headers = (Referer => $options{'referer'});
    my $req = HTTP::Request->new ('GET', $url, \@headers);
    $ua->prepare_request ($req);
    ### IntradayHandler request: $req->as_string

    my $resp = $ua->request
      ($req,
       sub {
         my ($chunk, $resp, $protobj) = @_;
         $resp->add_content($chunk);

         # if the message is deflate/gzip/etc compressed then decoded_content
         # returns undef until the whole image -- but don't worry about that
         # until we get a server sending us compressed images
         #
         my $image = $resp->decoded_content(charset=>'none');
         if ($image && length $image >= 256) {
           App::Chart::Intraday::write_intraday_image (symbol => $symbol,
                                                       mode   => $mode,
                                                       image  => $image);
         }
       });

    if ($resp->is_success) {
      $image = $resp->decoded_content(charset=>'none',raise_error=>1);
    } else {
      $error = __x('Error: {status_line}',
                   status_line => $resp->status_line);
    }
  }
  require App::Chart::Intraday;
  App::Chart::Intraday::write_intraday_image (symbol => $symbol,
                                              mode   => $mode,
                                              image  => $image,
                                              resp   => $resp,
                                              error  => $error);
  ### response: $resp->status_line
}


sub name_sans_mnemonic {
  my ($self) = @_;
  my $name = $self->{'name'};
  $name =~ s/_//;
  return $name;
}

sub name_as_markup {
  my ($self) = @_;
  my $name = $self->{'name'};
  $name =~ s{_(.)}{<u>$1</u>};
  return $name;
}
sub name_mnemonic_key {
  my ($self) = @_;
  my $name = $self->{'name'};
  $name =~ s/__//;
  return ($name =~ /_(.)/ && $1);
}

1;
__END__

# =for stopwords intraday
# 
# =head1 NAME
# 
# App::Chart::IntradayHandler -- intraday download handlers
# 
# =for test_synopsis my (@handlers)
# 
# =head1 SYNOPSIS
# 
#  use App::Chart::IntradayHandler;
# 
#  # register new
#  App::Chart::IntradayHandler->new ();
# 
#  # find
#  @handlers = App::Chart::IntradayHandler->handlers_for_symbol ('GM');
# 
# =head1 FUNCTIONS
# 
# =over 4
# 
# =item C<< App::Chart::IntradayHandler->new (...) >>
# 
# Create and register a new intraday image handler.  The return is a new
# C<App::Chart::IntradayHandler> object, though usually this is not of interest
# (only all the handlers later with C<handlers_for_symbol> below).
# 
#     my $pred = App::Chart::Sympred::Suffix->new ('.NZ');
# 
#     sub intraday_url {
#       my ($self, $symbol, $mode) = @_;
#       return 'http://ichart.finance.yahoo.com/z?s='
#         . URI::Escape::uri_escape ($symbol)
#         . '&t=' . $mode
#         . '&l=off&z=m&q=l&a=v';
#     }
# 
#     App::Chart::IntradayHandler->new
#       (pred => $pred,
#        proc => \&intraday_url,
#        mode => '1d',
#        name => '1 Day');
# 
# =item C<< @handler_list = App::Chart::IntradayHandler->handlers_for_symbol ($symbol) >>
# 
# Return a list of C<App::Chart::IntradayHandler> objects which are available
# for use with C<$symbol>.  This is an empty list if there's nothing available.
# 
# =item C<< $handler = App::Chart::IntradayHandler->handler_for_symbol_and_mode ($symbol, $mode) >>
# 
# Return a C<App::Chart::IntradayHandler> object for use on the given
# C<$symbol> and C<$mode>.  C<$mode> is a string matched against the C<mode>
# specified in the handlers available for C<$symbol>.
# 
# =item $handler->download ($symbol)
# 
# Do a download on C<$handler> for C<$symbol>.  The result is written to the
# database.
# 
# =back
# 
# =head1 SEE ALSO
# 
# L<App::Chart::Intraday>
# 
# =cut

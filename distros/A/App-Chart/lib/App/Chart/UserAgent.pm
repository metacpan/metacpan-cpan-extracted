# Copyright 2008, 2009, 2010, 2011, 2016, 2018, 2024 Kevin Ryde

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

package App::Chart::UserAgent;
use 5.006;
use strict;
use warnings;
use App::Chart;
use Locale::TextDomain ('App-Chart');
use HTTP::Message 5.814;  # for decodable()
use base 'LWP::UserAgent';

use Class::Singleton 1.03; # 1.03 for _new_instance()
use base 'Class::Singleton';
*_new_instance = \&new;

# Crib notes:
#
# URIs:
#     Current RFC3986
#
#     Past RFC2396 -- previous URI spec
#          RFC1808 -- relative URI spec
#          RFC1738 -- previous again
#          RFC1736, RFC1737 -- functional specs
#
# Proxies:
#     /usr/share/doc/libwww-doc/html/Library/User/Using/Proxy.html
#         http_proxy, no_proxy
#         Eg. http_proxy=http://proxy.zipworld.com.au:8080/
#
#     /usr/share/doc/lynx/lynx_help/keystrokes/environments.html
#         shows spaces in no_proxy
#
#     wget.info Proxies
#
#
# something ...
# @LWP::Protocol::http::EXTRA_SOCK_OPTS = (PeerAddr => "foo.com");
#

# LWP::Protocol::http::EXTRA_SOCK_OPTS is used by LWP::Protocol::http
# when creating its I/O socket class.  That class is
# LWP::Protocol::http::Socket, which is a subclass Net::HTTP.
#
# Net::HTTP made an incompatible change, circa its version 6.23,
# to its default MaxLineLength, dropping from 32 kbytes to 8 kbytes.
# This breaks on some long header lines from finance.yahoo.com in
# App::Chart::Yahoo data downloads.  Those lines are somewhere up
# 6 kbytes, maybe more depending on the share symbol or something.
# That's a foolish amount to have in a header line, but want it to
# work here.
#
# MaxLineLength => 0 here means no length limit.
# Would have preferred to get this in via the UserAgent instance
# or class here, but looks like no way to get through to that
# protocol bits.
#
use LWP::Protocol::http;
push @LWP::Protocol::http::EXTRA_SOCK_OPTS, MaxLineLength => 0;


sub new {
  my ($class, %options) = @_;
  if (! exists $options{'keep_alive'}
      && ! exists $options{'conn_cache'}) {
    $options{'keep_alive'} = 1;  # connection cache 1 sock
  }
  if (! exists $options{'agent'}) {
    # not given, use our default
    $options{'agent'} = $class->_agent;
  } elsif (defined $options{'agent'} && $options{'agent'} =~ / $/) {
    # ends in space, append our default
    $options{'agent'} .= $class->_agent;
  }
  my $self = $class->SUPER::new (timeout => 60,  # seconds, default
                                 %options);

  # with lwp bit appended
  # $self->agent ();

  # ask for everything decoded_content() accepts
  $self->default_header ('Accept-Encoding' => scalar HTTP::Message::decodable());

  # trace on redirect ...

  return $self;
}

sub _agent {
  my ($class) = @_;
  return "Chart/$App::Chart::VERSION " . $class->SUPER::_agent;
}

sub redirect_ok {
  my ($self, $prospective_request, $response) = @_;
  my $ret = $self->SUPER::redirect_ok ($prospective_request, $response);
  if ($ret) {
    print "Redirect to ",$prospective_request->uri,"\n";
  }
  return $ret;
}

sub request {
  my ($self, @args) = @_;
  $self->{__PACKAGE__.'.last_time'} = time() - 1;  # provoke initial display
  return $self->SUPER::request (@args);
}

# method call up from LWP::UserAgent
sub progress {
  my ($self, $status, $response) = @_;

  my $str = $status;
  if ($status eq 'begin') {
    $str = __('connect');

  } elsif ($response && $status ne 'end') {
    my $time = time();
    if ($time != $self->{__PACKAGE__.'.last_time'}) {
      $self->{__PACKAGE__.'.last_time'} = $time;

      my $got = length ($response->content);
      my $total = $response->content_length;
      if (defined $total) {
        $str = __x('{got} of {total} bytes',
                   got => $got, total => $total);
      } else {
        $str = __x('{got} bytes', got => $got);
      }
    } else {
      $str = undef;
    }
  }
  if (defined $str) {
    require App::Chart::Download;
    App::Chart::Download::substatus ($str);
  }

  return $self->SUPER::progress ($status, $response);
}

sub run_handlers {
  my ($self, $phase, $o) = @_;
  if ($phase eq 'request_send') {
    if ($App::Chart::option{'verbose'} >= 2) {
      print $o->as_string,"\n";
    } elsif ($App::Chart::option{'verbose'} >= 1) {
      print $o->method," ",$o->url,"\n";
    }
  }
  if ($phase eq 'response_done') {
    if ( $App::Chart::option{'verbose'} >= 1) {
      print $o->status_line,"\n";
    }
    if ( $App::Chart::option{'verbose'} >= 2) {
      print $o->headers->as_string,"\n";
      my $content = $o->decoded_content;
      if (length $content <= 1000) {
        print "content:\n", $content, "\n\n";
      }
    }
  }
  return $self->SUPER::run_handlers ($phase, $o);
}

# use Data::Dumper;
# *LWP::Protocol::http::SocketMethods::configure = sub {
#   my $self = shift;
#   print Dumper (\@_);
#   $self->SUPER::configure (@_);
# };


1;
__END__

=for stopwords LWP useragent gzip eg

=head1 NAME

App::Chart::UserAgent -- LWP useragent subclass

=head1 SYNOPSIS

 use App::Chart::UserAgent;
 my $ua = App::Chart::UserAgent->instance;

=head1 CLASS HIERARCHY

    LWP::UserAgent
      App::Chart::UserAgent

=head1 DESCRIPTIONS

This is a small subclass of C<LWP::UserAgent> which sets up, by default,

=over 4

=item *

Connection caching, currently just 1 kept open at any time.

=item *

C<User-Agent> identification header.

=item *

C<Accept-Encoding> header with C<HTTP::Message::decodable()> to let the
server send gzip etc.  This means all responses should be accessed with
C<< $resp->decoded_content() >>, not raw C<content()>.

=item *

Progress and redirection messages (back through C<App::Chart::Download>).

=back

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::UserAgent->instance >>

Return a shared C<App::Chart::UserAgent> object.  This shared instance is
meant for all normal use.

=item C<< App::Chart::UserAgent->new (key => value, ...) >>

Create and return a new C<App::Chart::UserAgent> object.

=item C<< App::Chart::UserAgent->_agent >>

=item C<< $ua->_agent >>

Return the default C<User-Agent> header string.  This is Chart plus the LWP
default, eg.

    Chart/100 libwww-perl/5.814

=back

=head1 SEE ALSO

L<LWP::UserAgent>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011, 2016, 2018, 2024 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<@chartdatadir@/COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut

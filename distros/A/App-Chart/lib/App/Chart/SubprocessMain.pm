# Copyright 2008, 2009, 2010, 2011, 2013 Kevin Ryde

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

package App::Chart::SubprocessMain;
use 5.010;
use strict;
use warnings;
use Storable;
use IO::Handle;

use App::Chart::Download;

# set this to 1 for development debugging prints
use constant { DEBUG => 0,
               DEBUG_TTY_FILENAME => '/dev/tty' };

sub main {
  my ($class) = @_;
  ## no critic (ProhibitExplicitStdin, ProhibitExit)

  # subprocess unbuffered and utf8
  binmode (STDIN, ':raw') or die;
  *STDOUT->autoflush(1);
  *STDERR->autoflush(1);

  if (DEBUG) {
    ## no critic (ProhibitBarewordFileHandles RequireBriefOpen)
    open TTY, '>', DEBUG_TTY_FILENAME or die;
    print TTY "SubprocessMain\n";
    *TTY->autoflush(1);
  }

  for (;;) {
    my $len = <STDIN>;
    if (DEBUG) { print "SubprocessMain: length $len\n"; }
    my $data;
    my $got = read STDIN, $data, $len;
    if (! defined $got) {
      print STDERR "Read error: ",Glib::strerror($!),"\n";
      exit 1;
    }
    if ($got != $len) {
      print STDERR "Read $got wanted $len\n";
      exit 1;
    }
    $data = Storable::thaw ($data);

    if (DEBUG) { require Data::Dumper;
                 print "SubprocessMain: ",Data::Dumper::Dumper($data);
                 print TTY "SubprocessMain ", Data::Dumper::Dumper($data); }
    if (! $data) { last; }

    my ($jobclass, @args) = @$data;

    # use Module::Load;
    #     Module::Load::load ($jobclass);
    #     $jobclass->run (@args);

    if ($jobclass eq 'intraday') {
      require App::Chart::Intraday;
      App::Chart::Intraday->command_line_download (\@args);

    } elsif ($jobclass eq 'latest') {
      require App::Chart::LatestHandler;
      App::Chart::LatestHandler->download (@args);

    } elsif ($jobclass eq 'download') {
      require App::Chart::Download;
      if ($args[0] =~ /^--/p) {
        my $key = ${^POSTMATCH};
        require App::Chart::Gtk2::Symlist;
        $args[0] = App::Chart::Gtk2::Symlist->new_from_key ($key);
      }
      App::Chart::Download->command_line_download ('subprocess', \@args);

    } elsif ($jobclass eq 'vacuum') {
      require App::Chart::Vacuum;
      App::Chart::Vacuum::vacuum (@args);

    } elsif ($jobclass eq 'exit') {
      last;

    } else {
      print "Unknown job type $_\n";
    }
    #     App::Chart::Download::status ('Foo');
    #     sleep (2);

    App::Chart::Download::status ('Idle');
    *STDOUT->flush;
  }

  if (DEBUG) { print TTY "SubprocessMain exit\n"; }
  exit 0;
}

1;
__END__

=for stopwords subprocesses

=head1 NAME

App::Chart::SubprocessMain -- main loop for subprocesses

=head1 SYNOPSIS

 use App::Chart::SubprocessMain;
 App::Chart::SubprocessMain->main ();

=cut

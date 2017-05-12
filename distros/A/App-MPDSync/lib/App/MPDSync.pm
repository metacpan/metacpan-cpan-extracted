package App::MPDSync;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.02';

use Getopt::Long;
use Net::MPD;
use Proc::Daemon;

sub new {
  my ($class, @options) = @_;

  my $self = bless {
    from    => '',
    to      => 'localhost',
    daemon  => 1,
    verbose => 0,
    source  => undef,
    @options,
  }, $class;
}

sub parse_options {
  my ($self, @args) = @_;

  local @ARGV = @args;

  Getopt::Long::Configure('bundling');
  Getopt::Long::GetOptions(
    'D|daemon!' => \$self->{daemon},
    'V|version' => \&show_version,
    'f|from=s'  => \$self->{from},
    't|to=s'    => \$self->{to},
    'h|help'    => \&show_help,
    'v|verbose' => \$self->{verbose},
  );
}

sub vprint {
  my ($self, @message) = @_;
  say @message if $self->{verbose};
}

sub show_help {
  print <<'HELP';
Usage: mpd-sync [options] --from source [--to dest]

Options:
  -f,--from     Source MPD instance (required)
  -t,--to       Destination MPD instance (default localhost)
  -v,--verbose  Be noisy
  --no-daemon   Do not fork to background
  -V,--version  Show version and exit
  -h,--help     Show this help and exit
HELP

  exit;
}

sub show_version {
  say "mpd-sync (App::MPDSync) version $VERSION";
  exit;
}

sub execute {
  my ($self) = @_;

  local @SIG{qw{ INT TERM HUP }} = sub {
    exit 0;
  };

  unless ($self->{from}) {
    say STDERR 'Source MPD not provided';
    show_help;
  }

  my $source = Net::MPD->connect($self->{from});

  if ($self->{daemon}) {
    $self->vprint('Forking to background');
    Proc::Daemon::Init;
  }

  {
    $self->vprint('Syncrhonizing initial playlist');

    my $dest = Net::MPD->connect($self->{to});
    $dest->stop;
    $dest->clear;
    $dest->add($_->{uri}) for $source->playlist_info;

    $source->update_status;
    $dest->play;
    $dest->seek($source->song, int $source->elapsed);
  }

  while (1) {
    $source->idle('playlist');

    $self->vprint('Source playlist changed');

    $source->update_status;
    my @playlist = $source->playlist_info;

    my $dest = Net::MPD->connect($self->{to});
    foreach my $item ($dest->playlist_info) {
      if (@playlist) {
        if ($item->{uri} eq $playlist[0]{uri}) {
          shift @playlist;
        } else {
          $self->vprint("Removing $item->{uri} from destination playlist");
          $dest->delete_id($item->{Id});
        }
      } else {
        $self->vprint('Out of entries from source!');
      }
    }

    foreach (@playlist) {
      $self->vprint("Adding $_->{uri} to destination");
      $dest->add($_->{uri});
    }
  }
}

1;
__END__

=encoding utf-8

=head1 NAME

App::MPDSync - Synchronize MPD with another instance

=head1 SYNOPSIS

  mpd-sync --from otherhost --to localhost

=head1 DESCRIPTION

C<App::MPDSync> will keep an instance of C<MPD> synced with another instance.
This can be useful for having failover for an online radio station.

=head1 REQUIREMENTS

Both MPD instances have to have the exact same files in their libraries or the
destination server will get out of sync since it will not be able to play some
of the files from the source server.

Specifying the same server for both the source and the destination will simply
stop C<MPD> and clear the playlist.

If another program modifies the playlist of the destination server, C<mpd-sync>
will not try to fix this until it is restarted.  As such, the servers will then
be out of sync.

=head1 AUTHOR

Alan Berndt E<lt>alan@eatabrick.orgE<gt>

=head1 COPYRIGHT

Copyright 2014 Alan Berndt

=head1 LICENSE

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 SEE ALSO

L<Net::MPD>

=cut

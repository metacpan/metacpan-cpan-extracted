package App::MPDJ;

use strict;
use warnings;
use 5.010;

our $VERSION = '1.09';

use Net::MPD;
use Proc::Daemon;
use Log::Dispatch;
use AppConfig;

sub new {
  my ($class, @options) = @_;

  my $self = bless {
    last_call     => 0,
    config_errors => [],
    @options
  }, $class;
}

sub mpd    { shift->{mpd} }
sub log    { shift->{log} }
sub config { shift->{config} }

sub parse_options {
  my ($self, @args) = @_;

  $self->{config} = AppConfig->new({
      ERROR => sub { push @{ $self->{config_errors} }, \@_; },
      CASE  => 1,
    },
    'conf|f=s' => {
      VALIDATE => sub { -e shift }
    },
    'before|b=i'   => { DEFAULT => 2 },
    'after|a=i'    => { DEFAULT => 2 },
    'calls-path=s' => { DEFAULT => 'calls' },
    'calls-freq=i' => { DEFAULT => 3600 },
    'daemon|D!'    => { DEFAULT => 1 },
    'mpd=s'        => { DEFAULT => 'localhost' },
    'music-path=s' => { DEFAULT => 'music' },
    'syslog|s=s'   => { DEFAULT => '' },
    'conlog|l=s'   => { DEFAULT => '' },
    'help|h'       => { ACTION  => \&help, },
    'version|V'    => { ACTION  => \&version, });

  $self->_getopt(@args);    # to get --conf option, if any

  my @configs =
    $self->config->get('conf') || ('/etc/mpdj.conf', "$ENV{HOME}/.mpdjrc");
  foreach my $config (@configs) {
    if (-e $config) {
      say "Loading config ($config)" if $self->config->get('conlog');
      $self->config->file($config);
    } else {
      say "Config file skipped ($config)" if $self->config->get('conlog');
    }
  }

  $self->_getopt(@args);    # to override config file
}

sub _getopt {
  my ($self, @args) = @_;

  $self->config->getopt([@args]);    # do not consume @args

  if (@{ $self->{config_errors} }) {
    foreach my $err (@{ $self->{config_errors} }) {
      printf STDERR @$err;
      print STDERR "\n";
    }
    $self->help;
  }
}

sub connect {
  my ($self) = @_;

  $self->{mpd} = Net::MPD->connect($self->config->get('mpd'));
}

sub execute {
  my ($self) = @_;

  local @SIG{qw( INT TERM HUP )} = sub {
    $self->log->notice('Exiting');
    exit 0;
  };

  my @loggers;
  push @loggers,
    ([ 'Screen', min_level => $self->config->get('conlog'), newline => 1 ])
    if $self->config->get('conlog');
  push @loggers,
    ([ 'Syslog', min_level => $self->config->get('syslog'), ident => 'mpdj' ])
    if $self->config->get('syslog');

  $self->{log} = Log::Dispatch->new(outputs => \@loggers);

  if ($self->config->get('daemon')) {
    $self->log->notice('Forking to background');
    Proc::Daemon::Init;
  }

  $self->connect;
  $self->configure;

  $self->mpd->subscribe('mpdj');

  $self->update_cache;

  while (1) {
    $self->log->debug('Waiting');
    my @changes =
      $self->mpd->idle(qw(database player playlist message options));
    $self->mpd->update_status();

    foreach my $subsystem (@changes) {
      my $function = $subsystem . '_changed';
      $self->$function();
    }
  }
}

sub configure {
  my ($self) = @_;

  $self->log->notice('Configuring MPD server');

  $self->mpd->repeat(0);
  $self->mpd->random(0);

  if ($self->config->get('calls-freq')) {
    my $now = time;
    $self->{last_call} = $now - $now % $self->config->get('calls-freq');
    $self->log->notice("Set last call to $self->{last_call}");
  }
}

sub update_cache {
  my ($self) = @_;

  $self->log->notice('Updating music and calls cache...');

  foreach my $category (('music', 'calls')) {

    @{ $self->{$category} } = grep { $_->{type} eq 'file' }
      $self->mpd->list_all($self->config->get("${category}-path"));

    my $total = scalar(@{ $self->{$category} });
    if ($total) {
      $self->log->notice(sprintf 'Total %s available: %d', $category, $total);
    } else {
      $self->log->warning(
        "No $category available.  Path should be mpd path not file system.");
    }
  }
}

sub remove_old_songs {
  my ($self) = @_;

  my $song = $self->mpd->song || 0;
  my $count = $song - $self->config->get('before');
  if ($count > 0) {
    $self->log->info("Deleting $count old songs");
    $self->mpd->delete("0:$count");
  }
}

sub add_new_songs {
  my ($self) = @_;

  my $song = $self->mpd->song || 0;
  my $count =
    $self->config->get('after') + $song - $self->mpd->playlist_length + 1;
  if ($count > 0) {
    $self->log->info("Adding $count new songs");
    $self->add_song for 1 .. $count;
  }
}

sub add_song {
  my ($self) = @_;

  $self->add_random_item_from_category('music');
}

sub add_call {
  my ($self) = @_;

  $self->log->info('Injecting call');

  $self->add_random_item_from_category('calls', 'immediate');

  my $now = time;
  $self->{last_call} = $now - $now % $self->config->get('calls-freq');
  $self->log->info('Set last call to ' . $self->{last_call});
}

sub add_random_item_from_category {
  my ($self, $category, $next) = @_;

  my @items = @{ $self->{$category} };

  my $index = int rand scalar @items;
  my $item  = $items[$index];

  my $uri  = $item->{uri};
  my $song = $self->mpd->song || 0;
  my $pos  = $next ? $song + 1 : $self->mpd->playlist_length;
  $self->log->info('Adding ' . $uri . ' at position ' . $pos);

  $self->mpd->add_id($uri, $pos);
}

sub time_for_call {
  my ($self) = @_;

  return unless $self->config->get('calls-freq');
  return time - $self->{last_call} > $self->config->get('calls-freq');
}

sub version {
  say "mpdj (App::MPDJ) version $VERSION";
  exit;
}

sub help {
  print <<'HELP';
Usage: mpdj [options]

Options:
  --mpd             MPD connection string (password@host:port)
  -s,--syslog       Turns on syslog output (debug, info, notice, warn[ing], error, etc)
  -l,--conlog       Turns on console output (same choices as --syslog)
  --no-daemon       Turn off daemonizing
  -b,--before       Number of songs to keep in playlist before current song
  -a,--after        Number of songs to keep in playlist after current song
  -c,--calls-freq   Frequency to inject call signs in seconds
  --calls-path      Path to call sign files
  --music-path      Path to music files
  -f,--conf         Config file to use
  -V,--version      Show version information and exit
  -h,--help         Show this help and exit
HELP

  exit;
}

sub database_changed {
  my ($self) = @_;

  $self->update_cache;
}

sub player_changed {
  my ($self) = @_;

  $self->add_call() if $self->time_for_call();
  $self->add_new_songs();
  $self->remove_old_songs();
}

sub playlist_changed {
  my ($self) = @_;

  $self->player_changed();
}

sub message_changed {
  my $self = shift;

  my @messages = $self->mpd->read_messages();

  foreach my $message (@messages) {
    my $function = 'handle_message_' . $message->{channel};
    $self->$function($message->{message});
  }
}

sub options_changed {
  my $self = shift;

  $self->log->notice('Resetting configuration');

  $self->mpd->repeat(0);
  $self->mpd->random(0);
}

sub handle_message_mpdj {
  my ($self, $message) = @_;

  my ($option, $value) = split /\s+/, $message, 2;

  if ($option eq 'before' or $option eq 'after' or $option eq 'calls-freq') {
    return unless $value =~ /^\d+$/;
    $self->log->info(sprintf 'Setting %s to %s (was %s)',
      $option, $value, $self->config->get($option));
    $self->config->set($option, $value);
    $self->player_changed();
  }
}

1;

__END__

=encoding utf-8

=head1 NAME

App::MPDJ - MPD DJ.

=head1 SYNOPSIS

  > mpdj
  > mpdj --before 2 --after 6
  > mpdj --no-daemon --conlog info

=head1 DESCRIPTION

C<App::MPDJ> is an automatic DJ for your C<MPD> server.  It will manage a queue
of random songs for you just like a real DJ.

=head1 OPTIONS

=over 4

=item --mpd

Sets the MPD connection details.  Should be a string like password@host:port.
The password and port are both optional.

=item -s, --syslog

Turns on sending of log information to syslog at specified level.  Level is a
required parameter can be one of debug, info, notice, warn[ing], err[or],
crit[ical], alert or emerg[ency].

=item -l, --conlog

Turns on sending of log information to console at specified level.  Level is a
required parameter can be one of debug, info, notice, warn[ing], err[or],
crit[ical], alert or emerg[ency].

=item --no-daemon

Run in the foreground instead of trying to fork and exit.

=item -b, --before

Number of songs to keep in the playlist before the current song.  The default
is 2.

=item -a, --after

Number of songs to queue up in the playlist after the current song.  The
default is 2.

=item -c, --calls-freq

Frequency in seconds for call signs to be injected.  The default is 3600 (one
hour).  A value of 0 will disable call sign injection.

=item --calls-path

Path to call sign files.  The default is 'calls'.

=item --music-path

Path to music files.  The default is 'music'.

=item -f --conf

Config file to use

=item -V, --version

Show the current version of the script installed and exit.

=item -h, --help

Show this help and exit.

=back

=head1 CONFIGURATION FILES

The configuration file is formatted as an INI file.  See L<AppConfig> for
details.  If no configuration file is given, the file C</etc/mpdj.conf> will be
read (if it exists) followed by the file C<~/.mpdjrc> (if it exists).  The
values in the latter file will override anything in the first file.  Command
line parameters will override anything given in any configuration file.

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

L<Net::MPD>>

=cut

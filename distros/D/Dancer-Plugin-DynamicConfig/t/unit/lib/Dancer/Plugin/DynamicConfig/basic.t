use strict;
use warnings;

use lib 't/unit/lib';

use Dancer::Test;
use Encode qw(decode);
use File::Temp;
use IO::File;
use Test::Most;
use Time::HiRes;

my $class = 'Dancer::Plugin::DynamicConfig';
use_ok $class;

# {
#   "this": "that",
#   "array": [ "these", "are", "some", "items" #   ],
#   "hash": { "key1": "val1", "key2": "val2"
#   },
#   "aofh": [
#     { "k1a": "v1a", "k1b": "v1b" },
#     { "k2a": "k2b" }
#   ]
# }

cmp_deeply(
  dynamic_config('example_file'),
  {
    this => "that",
    array => [ qw(these are some items) ],
    hash => { key1 => "val1", key2 => "val2" },
    aofh => [
      { k1a => "v1a", k1b => "v1b" },
      { k2a => "k2b" }
    ]
  }
);

cmp_deeply(
  dynamic_config('example_valcaps'),
  {
    this => "THAT",
    array => [ qw(these are some items) ],
    hash => { key1 => "VAL1", key2 => "VAL2" },
    aofh => [
      { k1a => "V1A", k1b => "V1B" },
      { k2a => "K2B" }
    ]
  }
);

sub update_dynamic_config {
  my ($key, $val) = @_;

  my $plugins = Dancer::Config::setting('plugins');
  $plugins->{DynamicConfig}{$key} = $val;
  set plugins => $plugins;

  Dancer::Plugin::DynamicConfig->reinitialize; # pick up change to $plugins
}

# we pick up on changes to the file without having to explicitly reinitialize things
{
  my $path = path_for('scratch_valcaps', 1);
  write_file($path, '{ "a": 1 }');
  cmp_deeply(dynamic_config('scratch_valcaps'), { a => 1 }, 'scratch file');

  write_file($path, '{ "b": 2 }');
  cmp_deeply(dynamic_config('scratch_valcaps'), { b => 2 }, 'scratch file after rewrite');
}

{
  # Add a test file to our dynamic config that we can scribble on:
  my $fh = File::Temp->new(SUFFIX => '.json');
  my $path = $fh->filename;
  write_file($path, '{}');

  update_dynamic_config(config_test => $path);
  cmp_deeply(dynamic_config('config_test'), {}, 'sanity: initial config_test as expected');

  # we're going to change the file contents on disk, but want to keep the mtime of the file just as
  # it was when we initially created it. So here's a song and dance, and a sanity test to show we got style.
  my $old_mtime = ($fh->stat)[9];
  write_file($path, '{"a": 1}');
  utime $old_mtime, $old_mtime, $path;
  cmp_deeply(dynamic_config('config_test'), {}, "no change to mtime: we don't pick up new contents");

  # THIS IS THE EVENT UNDER TEST
  utime undef, undef, $path;
  cmp_deeply(dynamic_config('config_test'), { a => 1 }, 'modified config_test as expected');
}

# Check UTF-8
{
  # Add a test file to our dynamic config that we can scribble on:
  my $fh = File::Temp->new(SUFFIX => '.json');
  my $path = $fh->filename;
  my $japanese_text = "最もお得な月間または年間購入プランをご利用ください。";
  write_file($path, qq[{"ja":"$japanese_text"}]);

  update_dynamic_config(config_test => $path);
  cmp_deeply(dynamic_config('config_test'), {ja => decode('UTF-8', $japanese_text)}, 'UTF-8');
}

# Check bad config type
{
  # Add a test file to our dynamic config that we can scribble on:
  my $fh = File::Temp->new(SUFFIX => '.unworldly-promulgation');
  my $path = $fh->filename;
  write_file($path, 'test');

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  update_dynamic_config(config_test => $path);
  cmp_deeply(dynamic_config('config_test'), '', 'blank config for unknown filetype');
  cmp_deeply(\@warnings, [ re('ignoring.*unknown filetype') ], 'warn on unknown filetype');
}

sub write_file {
  my ($path, @data) = @_;
  my $mtime0 = (best_stat($path))[9];
  my $fh = IO::File->new($path, '>');

  $fh->seek(0, 0);
  $fh->printflush(@data);

  # Make sure that the mtime has actually changed.
  # On some sub-par filesystems (e.g., Apple HFS), timestamps have one-second granularity.
  # On most modern filesystems, there is a much higher timestamp resolution (e.g., typically 10 ms
  # or so), and the likelihood of failing the race is much lower.
  #
  # In these unit tests, this fails regularly on Mac OS, and only *very* occasionally on ext4fs.
  #
  # For this to be tickled in real-world code,
  # somebody would have to update the file in question twice in one timestamp-tick,
  # and we would have to have fetched the contents of the file sometime between those two updates.
  my $waited = 0;
  for (1 .. 4) {
    last if (best_stat($fh))[9] > $mtime0;
    utime undef, undef, $path;
    best_sleep(.6);
    ++$waited;
  }

  diag "write_file():  waited $waited times on your yicky filesystem" if $waited > 2;
}

sub path_for {
  my ($tag) = @_;

  my $data =  Dancer::Config->settings->{plugins}{DynamicConfig}{$tag};

  return ref($data) ? $data->{path} : $data;
}

sub best_stat {
    my ($filething) = @_;

    if (defined &Time::HiRes::stat) {
        Time::HiRes::stat($filething);
    } else {
        stat($filething);
    }
}

sub best_sleep {
    my ($seconds) = @_;

    if (defined &Time::HiRes::sleep) {
        Time::HiRes::sleep($seconds);
    } else {
        sleep(int($seconds + 1));
    }
}

done_testing;


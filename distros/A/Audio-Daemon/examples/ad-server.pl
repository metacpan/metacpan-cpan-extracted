#!/usr/local/bin/perl

use Audio::Daemon::Shout;
# or use Audio::Daemon::MPG123;
# or use Audio::Daemon::Xmms;

sub log {
  # this could use some cleaning up, but make it whatever you like.
  my $type = shift;
  my $msg = shift;
  my ($line, $function) = (@_)[2,3];
  $function = (split '::', $function)[-1];
  printf("%6s:%12s %7s:%s\n", $type, $function, '['.$line.']', $msg);
}

# Here the "Pass" argument is not a Password, but it's something
# passed through to the underlying player, in this case, libshout.
# it let it know various bits of information that it needs to run.
# Be sure to keep me posted how this is going!

my $daemon = new Audio::Daemon::Shout( Port => 9101, Log => \&log, 
                                       Allow => '10.10.10.0/24, 127.0.0.1',
                                       Pass => { bitrate => 64, ip => '10.10.10.1',
                                                 name => 'Jay\'s List', 
                                                 port => 18000, mountpoint => 'admin',
                                                 password => 'secret', chunk => 4096}
                                     );
                                                 # if lame is specified it will downsample
                                                 # lame => '/usr/local/bin/lame' }

$daemon->mainloop;

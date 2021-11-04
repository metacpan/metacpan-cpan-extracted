# -*- mode: perl -*-
# Copyright (C) 2021  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.

=head1 NAME

App::Phoebe::Ijirait - a Gemini-based MUSH running on Phoebe

=head1 DESCRIPTION

The ijirait are red-eyed shape shifters, and a game one plays via the Gemini
protocol, and Ijiraq is also one of the moons of Saturn.

The Ijirait game is modelled along traditional MUSH games ("multi-user shared
hallucination"), that is: players have a character in the game world; the game
world consists of rooms; these rooms are connected to each other; if two
characters are in the same room, they see each other; if one of them says
something, the other hears it.

When you visit the URL using your Gemini browser, you're asked for a client
certificate. The common name of the certificate is the name of your character in
the game.

As the server doesn't know whether you're still active or not, it assumes a
10min timout. If you were active in the last 10min, other people in the same
"room". Similarly, if you "say" something, whatever you said hangs on the room
description for up to 10min as long as your character is still in the room.

There is no configuration. Simply add it to your F<config> file:

    use App::Phoebe::Ijirait;

In a virtual host setup, this extension serves all the hosts. Here's how to
serve just one of them:

    package App::Phoebe::Ijirait;
    our $host = "campaignwiki.org";
    use App::Phoebe::Ijirait;

The help file, if you have one, is F<ijirait-help.gmi> in your wiki data
directory. Feel free to get a copy of
L<gemini://transjovian.org/ijiraq/page/Help>.

=cut

package App::Phoebe::Ijirait;
use App::Phoebe qw(@extensions $log $server @request_handlers success result);
use Modern::Perl;
use Encode qw(encode_utf8 decode_utf8);
use File::Slurper qw(read_binary write_binary read_text);
use Mojo::JSON qw(decode_json encode_json);
use Mojo::Util qw(gzip);
use List::Util qw(first none any);
use URI::Escape;
use utf8;

# See "load world on startup" for the small world generated if no save file is
# available.
my $data;

# By default, /play/ijirait on all hosts is the same game.
our $host = App::Phoebe::host_regex();

# Streamers are people connecting to /stream/ijirait.
my @streamers;

Mojo::IOLoop->next_tick(sub {
  $log->info("Serving Ijirait on $host") });

# global commands
our $commands = {
  help     => \&help,
  look     => \&look,
  type     => \&type,
  save     => \&save,
  backup   => \&backup,
  say      => \&speak, # can't use say!
  who      => \&who,
  go       => \&go,
  examine  => \&examine,
  describe => \&describe,
  name     => \&name,
  create   => \&create,
  delete   => \&delete,
  rooms    => \&rooms,
  connect  => \&connect,
  emote    => \&emote,
  hide     => \&hide,
  reveal   => \&reveal,
  secrets  => \&secrets,
  home     => \&home,
  find     => \&find,
  id       => \&id,
  forget   => \&forget,
};

our $ijrait_commands_without_cert = {
  who      => \&who,
};

# load world on startup
Mojo::IOLoop->next_tick(sub {
  my $dir = $server->{wiki_dir};
  if (-f "$dir/ijirait.json") {
    my $bytes = read_binary("$dir/ijirait.json");
    $data = decode_json $bytes;
  } else {
    init();
  } } );

sub init {
  my $next = 1;
  $data = {
    people => [
      {
	id => $next++, # 1
	name => "Ijiraq",
	description => "A shape-shifter with red eyes.",
	fingerprint => "",
	location => $next, # 2
	seen => [],
	ts => time,
      } ],
    rooms => [
      {
	id => $next++, # 2
	name => "The Tent",
	description => "This is a large tent, illuminated by candles.",
	exits => [
	  {
	    id => $next++, # 3
	    name => "An exit leads outside.",
	    direction => "out",
	    destination => $next,
	  } ],
	things => [],
	words => [
	  {
	    text => "Welcome!",
	    by => 1, # Ijirait
	    ts => time,
	  } ],
      },
      {
	id => $next++, # 4
	name => "Outside The Tent",
	description => "You’re standing in a rocky hollow, somewhat protected from the wind. There’s a large tent, here.",
	exits => [
	  {
	    id => $next++, # 5
	    name => "A tent flap leads inside.",
	    direction => "tent",
	    destination => 2, # The Tent
	  } ],
      	things => [],
	words => [],
      } ] };
  $data->{next} = $next;
};

# Save the world every half hour.
Mojo::IOLoop->recurring(1800 => \&save_world);

# Streaming needs a special handler because the stream never closes.
unshift(@request_handlers, "^gemini://(?:$host)(?:\\d+)?/play/ijirait/stream" => \&add_streamer);

sub add_streamer {
  my $stream = shift;
  my $data = shift;
  $log->debug("Handle streaming request");
  $log->debug("Discarding " . length($data->{buffer}) . " bytes")
      if $data->{buffer};
  my $url = $data->{request};
  my $port = App::Phoebe::port($stream);
  if ($url =~ m!^(?:gemini:)?//($host)(?::$port)?/play/ijirait/stream$!) {
    my $p = login($stream);
    if ($p) {
      # 1h timeout
      $stream->timeout(3600);
      # remove from channel members if an error happens
      $stream->on(close => sub { my $stream = shift; logout($stream, $p, "Connection closed") });
      $stream->on(error => sub { my ($stream, $err) = @_; logout($stream, $p, $err) });
      push(@streamers, { stream => $stream, person => $p });
      success($stream);
      $stream->write(encode_utf8 "# Streaming $p->{name}\n");
      $stream->write(encode_utf8 "Make sure you connect to game using a different client "
		     . "(with the same client certificate!) in order to play $p->{name}.\n");
      $stream->write(encode_utf8 "=> /play/ijirait Play $p->{name}.");
      # don't close the stream!
    } else {
      $stream->close_gracefully();
    }
  } else {
    result($stream, "59", "Don't know how to handle $url");
    $stream->close_gracefully();
  }
}

sub logout {
  my ($stream, $p, $msg) = @_;
  $log->debug("Disconnected $p->{name}: $msg");
  @streamers = grep { $_->{stream} ne $stream and $_->{person} ne $p } @streamers;
}

# run every minute and print a timestamp every 5 minutes
Mojo::IOLoop->recurring(60 => sub {
  my $loop = shift;
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
  return unless $min % 5 == 0;
  return unless @streamers > 0;
  $log->debug("Ijirait streamer ping");
  my $ts = sprintf("%02d:%02d UTC\n", $hour, $min);
  for (@streamers) {
      $_->{stream}->write($ts);
  }});

# notify every streamer in the same room
sub notify {
  my ($p, $msg) = @_;
  eval {
    for my $s (grep { $_->{person}->{location} == $p->{location} } @streamers) {
      my $stream = $s->{stream};
      next unless $stream;
      $stream->write(encode_utf8 $msg);
      $stream->write("\n");
    }
  };
  $log->error("Error notifying people of '$msg': $@") if $@;
}

# main loop
push(@extensions, \&main);

sub main {
  my $stream = shift;
  my $url = shift;
  my $port = App::Phoebe::port($stream);
  if ($url =~ m!^gemini://(?:$host)(?::$port)?/play/ijirait(?:/([a-z]+))?(?:\?(.*))?!) {
    my $command = ($1 || "look") . ($2 ? " " . decode_utf8 uri_unescape($2) : "");
    $log->debug("Handling $url - $command");
    # some commands require no client certificate (and no person argument!)
    my $routine = $ijrait_commands_without_cert->{$command};
    if ($routine) {
      $log->debug("Running $command");
      $routine->($stream);
      return 1;
    }
    # regular commands
    my $p = login($stream);
    if ($p) {
      type($stream, $p, $command);
    }
    return 1;
  }
  return 0;
}

sub login {
  my ($stream) = @_;
  # you need a client certificate
  my $fingerprint = $stream->handle->get_fingerprint();
  if (!$fingerprint) {
    $log->info("Requested client certificate");
    result($stream, "60", "You need a client certificate to play");
    return;
  }
  # find the right person
  my $p = first { $_->{fingerprint} eq $fingerprint} @{$data->{people}};
  if (!$p) {
    # create a new person if we can't find one
    $log->info("New client certificate $fingerprint");
    $p = new_person($fingerprint);
  } else {
    $log->info("Successfully identified client certificate: " . $p->{name});
  }
  return $p;
}

sub new_person {
  my $fingerprint = shift;
  my $p = {
    id => $data->{next}++,
    name => person_name(),
    description => "A shape-shifter with red eyes.",
    fingerprint => $fingerprint,
    location => 2, # The Tent
    seen => [],
    ts => time,
  };
  push(@{$data->{people}}, $p);
  return $p;
}

sub person_name {
  my $digraphs = "..lexegezacebisousesarmaindire.aeratenberalavetiedorquanteisrion";
  my $max = length($digraphs);
  my $length = 4 + rand(7); # 4-8
  my $name = '';
  while (length($name) < $length) {
    $name .= substr($digraphs, 2*int(rand($max/2)), 2);
  }
  $name =~ s/\.//g;
  return ucfirst $name;
}

sub look {
  my ($stream, $p) = @_;
  success($stream);
  my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
  $stream->write(encode_utf8 "# " . $room->{name} . "\n");
  $stream->write(encode_utf8 $room->{description} . "\n") if $room->{description};
  my @things = grep { my $thing = $_;
		      not $thing->{hidden}
		      or $thing->{seen}
		      and any { $_ eq $thing->{seen} } @{$p->{seen}}} @{$room->{things}};
  $stream->write("## Things\n") if @things > 0;
  for my $thing (@things) {
    my $name = uri_escape_utf8 $thing->{short};
    $stream->write(encode_utf8 "=> /play/ijirait/examine?$name $thing->{name} ($thing->{short})\n");
  }
  my @exits = grep { my $exit = $_;
		     not $exit->{hidden}
		     or $exit->{seen}
		     and any { $_ eq $exit->{seen} } @{$p->{seen}} } @{$room->{exits}};
  $stream->write("## Exits\n") if @exits > 0;
  for my $exit (@exits) {
    my $direction = uri_escape_utf8 $exit->{direction};
    $stream->write(encode_utf8 "=> /play/ijirait/go?$direction $exit->{name} ($exit->{direction})\n");
  }
  $stream->write("## People\n"); # there is always at least the observer!
  my $n = 0;
  my $now = time;
  for my $o (@{$data->{people}}) {
    next unless $o->{location} == $p->{location};
    next if $now - $o->{ts} > 600;      # don't show people inactive for 10min or more
    $n++;
    my $name = uri_escape_utf8 $o->{name};
    if ($o->{id} == $p->{id}) {
      $stream->write(encode_utf8 "=> /play/ijirait/examine?$name $o->{name} (you)\n");
    } else {
      $stream->write(encode_utf8 "=> /play/ijirait/examine?$name $o->{name}\n");
    }
  }
  my $title = 0;
  for my $word (@{$room->{words}}) {
    next if $now - $word->{ts} > 600; # don't show messages older than 10min
    $stream->write("## Words\n") unless $title++;
    if ($word->{by}) {
      my $o = first { $_->{id} == $word->{by} } @{$data->{people}};
      $stream->write(encode_utf8 ucfirst timespan($now - $word->{ts})
		     . ", " . $o->{name} . " said “" . $word->{text} . "”\n");
    } elsif ($word->{text}) {
      # emotes
      $stream->write(encode_utf8 $word->{text} . "\n");
    }
  }
  menu($stream);
}

sub timespan {
  my $seconds = shift;
  return "some time ago" if not defined $seconds;
  return "just now" if $seconds == 0;
  return sprintf("%d days ago", int($seconds/86400)) if abs($seconds) > 172800; # 2d
  return sprintf("%d hours ago", int($seconds/3600)) if abs($seconds) > 7200; # 2h
  return sprintf("%d minutes ago", int($seconds/60)) if abs($seconds) > 120; # 2min
  return sprintf("%d seconds ago", $seconds);
}

sub menu {
  my $stream = shift;
  $stream->write("## Commands\n");
  $stream->write("=> /play/ijirait/look look\n");
  $stream->write("=> /play/ijirait/say say\n");
  $stream->write("=> /play/ijirait/emote emote\n");
  $stream->write("=> /play/ijirait/help help\n");
  $stream->write("=> /play/ijirait/type type\n");
}

sub help {
  my ($stream, $p) = @_;
  success($stream);
  $stream->write("## Help\n");
  my $dir = $server->{wiki_dir};
  my $file = "$dir/ijirait-help.gmi";
  if (-f $file) {
    $stream->write(encode_utf8 read_text($file));
  } else {
    $stream->write("The help file does not exist.\n");
  }
  $stream->write("## Automatically Generated Command List\n");
  for my $command (sort keys %$commands) {
    $stream->write("* $command\n");
  }
  $stream->write("=> /play/ijirait Back\n");
}

sub type {
  my ($stream, $p, $str) = @_;
  if (!$str) {
    result($stream, "10", "Type your command");
    return;
  }
  # mark activity
  my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
  $p->{ts} = $room->{ts} = time;
  # parse commands
  my ($command, $arg) = split(/\s+/, $str, 2);
  $arg =~ s/\s+$// if defined $arg; # trim
  my $routine = $commands->{$command};
  if ($routine) {
    $log->debug("Running $command");
    $routine->($stream, $p, $arg);
    return;
  }
  # using exits instead of go
  if (first { $_->{direction} eq $str } @{$room->{exits}}) {
    go($stream, $p, $str);
    return;
  }
  # using the name of a person or thing instead of examine
  if (first { $_->{location} eq $p->{location} and $_->{name} eq $str } @{$data->{people}}
      or first { $_->{short} eq $str } @{$room->{things}}) {
    examine($stream, $p, $str);
    return;
  }
  $log->debug("Unknown command '$command'");
  success($stream);
  $stream->write("# Unknown command\n");
  $stream->write(encode_utf8 "“$command” is an unknown command.\n");
  menu($stream);
}

sub home {
  my ($stream, $p) = @_;
  $log->debug("Going home");
  notify($p, "$p->{name} turns to yellow mist and disappears.");
  $p->{location} = 2; # The Tent
  notify($p, "$p->{name} arrives.");
  result($stream, "30", "/play/ijirait/look");
}

sub go {
  my ($stream, $p, $direction) = @_;
  my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
  my $exit = first { $_->{direction} eq $direction } @{$room->{exits}};
  if ($exit) {
    $log->debug("Taking the exit $direction");
    notify($p, "$p->{name} leaves ($direction).");
    $exit->{ts} = time;
    $p->{location} = $exit->{destination};
    push(@{$p->{seen}}, $p->{location}) if none { $_ == $p->{location} } @{$p->{seen}};
    notify($p, "$p->{name} arrives.");
    result($stream, "30", "/play/ijirait/look");
  } else {
    success($stream);
    $log->debug("Unknown exit '$direction'");
    $stream->write(encode_utf8 "# Unknown exit “$direction”\n");
    $stream->write("The exit does not exist.\n");
    $stream->write("=> /play/ijirait Back\n");
  }
}

sub examine {
  my ($stream, $p, $name) = @_;
  success($stream);
  my $o = first { $_->{location} eq $p->{location} and $_->{name} eq $name } @{$data->{people}};
  if ($o) {
    $log->debug("Looking at $name");
    notify($p, "$p->{name} examines $o->{name}.") unless $p->{id} == $o->{id};
    $stream->write(encode_utf8 "# $o->{name}\n");
    $stream->write(encode_utf8 "$o->{description}\n");
    $stream->write("=> /play/ijirait Back\n");
    return;
  }
  my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
  my $thing = first { $_->{short} eq $name } @{$room->{things}};
  if ($thing) {
    $log->debug("Looking at $name");
    notify($p, "$p->{name} examines $thing->{name}.");
    $thing->{ts} = time;
    push(@{$p->{seen}}, $thing->{id}) if none { $_ == $thing->{id} } @{$p->{seen}};
    $stream->write(encode_utf8 "# $thing->{name}\n");
    $stream->write(encode_utf8 "$thing->{description}\n");
    $stream->write("=> /play/ijirait Back\n");
    return;
  }
  $log->debug("Unknown target '$name'");
  $stream->write(encode_utf8 "# Unknown target “$name”\n");
  $stream->write("No such person or object is visible.\n");
  $stream->write("=> /play/ijirait Back\n");
}

sub speak {
  my ($stream, $p, $text) = @_;
  if ($text) {
    $text =~ s/^["“„«]//;
    $text =~ s/["”“»]$//;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
  }
  if (not $text) {
    result($stream, "10", "You say");
    return;
  }
  my $w = {
    text => $text,
    by => $p->{id},
    ts => time,
  };
  my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
  push(@{$room->{words}}, $w);
  notify($p, "$p->{name} says: “$text”");
  look($stream, $p);
}

sub save {
  my ($stream, $p) = @_;
  save_world();
  success($stream);
  $stream->write("# World Save\n");
  $stream->write("Data was saved.\n");
  $stream->write("=> /play/ijirait Back\n");
}

sub save_world {
  cleanup();
  my $bytes = encode_json $data;
  my $dir = $server->{wiki_dir};
  write_binary("$dir/ijirait.json", $bytes);
}

sub cleanup() {
  my $now = time;
  my %people = map { $_->{location} => 1 } @{$data->{people}};
  for my $room (@{$data->{rooms}}) {
    my @words;
    for my $word (@{$room->{words}}) {
      next if $now - $word->{ts} > 600; # don't show messages older than 10min
      push(@words, $word);
    }
    $room->{words} = \@words;
  }
}

sub backup() {
  my $stream = shift;
  my $bytes = encode_json $data;
  $bytes =~ s/"fingerprint":"[^"]+"/"fingerprint":""/g;
  success($stream, "application/json+gzip");
  $stream->write(gzip $bytes);
}

sub who {
  my ($stream) = @_;
  my $now = time;
  success($stream);
  $stream->write("# Who are the shape shifters?\n");
  for my $o (sort { $b->{ts} <=> $a->{ts} } @{$data->{people}}) {
    $stream->write(encode_utf8 "* $o->{name}, active " . timespan($now - $o->{ts}) . "\n");
  }
  $stream->write("=> /play/ijirait Back\n");
}

sub describe {
  my ($stream, $p, $text) = @_;
  if ($text) {
    my ($obj, $description) = split(/\s+/, $text, 2);
    if ($obj eq "me") {
      $log->debug("Describing $p->{name}");
      notify($p, "$p->{name} changes appearance.");
      $p->{description} = $description;
      my $name = uri_escape_utf8 $p->{name};
      result($stream, "30", "/play/ijirait/examine?$name");
      return;
    }
    my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
    if ($obj eq "room") {
      $log->debug("Describing $room->{name}");
      notify($p, "$p->{name} changes the room’s description.");
      $room->{description} = $description;
      result($stream, "30", "/play/ijirait/look");
      return;
    }
    my $thing = first { $_->{short} eq $obj } @{$room->{things}};
    if ($thing) {
      $log->debug("Describe $thing->{name}");
      notify($p, "$p->{name} changes the description of $thing->{name}.");
      $thing->{description} = $description;
      my $name = uri_escape_utf8 $thing->{short};
      result($stream, "30", "/play/ijirait/examine?$name");
      return;
    }
    # No description of exits.
  }
  success($stream);
  $log->debug("Describing unknown object");
  $stream->write(encode_utf8 "# I don’t know what to describe\n");
  $stream->write(encode_utf8 "The description needs to start with what to describe, e.g. “describe me A shape-shifter with red eyes.”\n");
  $stream->write(encode_utf8 "You can describe yourself (“me”), the room you are in (“room”), or a thing (using its shortcut). You cannot describe exits.\n");
  $stream->write("=> /play/ijirait Back\n");
}

sub name {
  my ($stream, $p, $text) = @_;
  if ($text) {
    my ($obj, $name) = split(/\s+/, $text, 2);
    if ($obj eq "me" and $name !~ /\s/) {
      $log->debug("Name $p->{name}");
      notify($p, "$p->{name} changes their name to $name.");
      $p->{name} = $name;
      my $nm = uri_escape_utf8 $p->{name};
      result($stream, "30", "/play/ijirait/examine?$nm");
      return;
    } elsif ($obj eq "room") {
      my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
      $log->debug("Name $room->{name}");
      notify($p, "$p->{name} changes the room’s name to $name.");
      $room->{name} = $name;
      result($stream, "30", "/play/ijirait/look");
      return;
    } else {
      my $short;
      if ($name =~ /(^.*) \((\w+)\)$/) {
	$name = $1;
	$short = $2;
      }
      my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
      my $exit = first { $_->{direction} eq $obj } @{$room->{exits}};
      if ($exit) {
	$log->debug("Name $exit->{name}");
	notify($p, "$p->{name} renames $exit->{direction} to $name ($short).");
	$exit->{name} = $name;
	$exit->{direction} = $short if $short;
	result($stream, "30", "/play/ijirait/look");
	return;
      }
      my $thing = first { $_->{short} eq $obj } @{$room->{things}};
      if ($thing) {
	$log->debug("Name $thing->{short}");
	notify($p, "$p->{name} renames $thing->{name} to $name ($short).");
	$thing->{name} = $name;
	$thing->{short} = $short if $short;
	result($stream, "30", "/play/ijirait/look");
	return;
      }
    }
  }
  success($stream);
  $log->debug("Naming unknown object");
  $stream->write(encode_utf8 "# I don’t know what to name\n");
  $stream->write(encode_utf8 "The command needs to start with what to name, e.g. “name me Sogeeran.”\n");
  $stream->write("=> /play/ijirait Back\n");
}

sub create {
  my ($stream, $p, $obj) = @_;
  if ($obj eq "room") {
    $log->debug("Create room");
    my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
    my $dest = new_room();
    my $exit = new_exit($room, $dest, $p);
    new_exit($dest, $room, $p);
    notify($p, "$p->{name} creates a new room.");
    result($stream, "30", "/play/ijirait");
  } elsif ($obj eq "thing") {
    $log->debug("Create thing");
    my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
    new_thing($room, $p);
    notify($p, "$p->{name} creates a new thing.");
    result($stream, "30", "/play/ijirait");
  } else {
    success($stream);
    $log->debug("Cannot create '$obj'");
    $stream->write(encode_utf8 "# Cannot create new “$obj”\n");
    $stream->write(encode_utf8 "Currently, all you can create is a room, or a thing: “create room” or  “create thing”.\n");
    $stream->write(encode_utf8 "Use the “name” and “describe” commands to customize it.\n");
    $stream->write("=> /play/ijirait Back\n");
  }
}

sub new_room {
  my $r = {
    id => $data->{next}++,
    name => "Lost in fog",
    description => "Dense fog surrounds you. Nothing can be discerned in this gloom.",
    things => [],
    exits => [],
    ts => time,
  };
  push(@{$data->{rooms}}, $r);
  return $r;
}

sub new_exit {
  # $from and $to are rooms
  my ($from, $to, $owner) = @_;
  my $e = {
    id => $data->{next}++,
    name => "A tunnel",
    direction => "tunnel",
    destination => $to->{id},
    owner => $owner->{id},
    ts => time,
  };
  push(@{$from->{exits}}, $e);
  return $e;
}

sub new_thing {
  my ($room, $owner) = @_;
  my $t = {
    id => $data->{next}++,
    short => "stone",
    name => "A small stone",
    description => "It’s round.",
    owner => $owner->{id},
    ts => time,
  };
  push(@{$room->{things}}, $t);
  return $t;
}

sub delete {
  my ($stream, $p, $str) = @_;
  my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
  # try to delete an exit
  my $exit = first { $_->{direction} eq $str } @{$room->{exits}};
  if ($exit) {
    $log->debug("Delete '$str'");
    @{$room->{exits}} = grep { $_->{direction} ne $str } @{$room->{exits}};
    notify($p, "$p->{name} deletes $exit->{name}");
    result($stream, "30", "/play/ijirait");
    return;
  }
  # try to delete a thing
  my $thing = first { $_->{short} eq $str } @{$room->{things}};
  if ($thing) {
    $log->debug("Delete '$str'");
    @{$room->{things}} = grep { $_->{short} ne $str } @{$room->{things}};
    notify($p, "$p->{name} deletes $thing->{name}");
    result($stream, "30", "/play/ijirait");
    return;
  }
  $log->debug("Cannot delete '$str'");
  success($stream);
  $stream->write(encode_utf8 "# Cannot delete “$str”\n");
  $stream->write(encode_utf8 "Only things and exits can be deleted.\n");
  menu($stream);
}

sub rooms {
  my ($stream, $p, $option) = @_;
  $option //= "";
  $log->debug("Listing all rooms");
  success($stream);
  $stream->write("# Rooms\n");
  $stream->write("=> /play/ijirait/rooms?ghosts Rooms with ghosts (rooms ghosts)\n") unless $option eq "ghosts";
  my %location;
  my $now = time;
  foreach my $o (@{$data->{people}}) {
    # mark active people
    push(@{$location{$o->{location}}}, $o->{name} . ($now - $o->{ts} < 600 ? "*" : ""))
  }
  for my $room (sort { ($b->{ts}||0) <=> ($a->{ts}||0) } @{$data->{rooms}}) {
    $stream->write(encode_utf8 "* $room->{name}");
    $stream->write(", last activity " . timespan($now - $room->{ts})) if $room->{ts};
    $stream->write(" (" . join(", ", @{$location{$room->{id}}}) . ")") if $option eq "ghosts" and $location{$room->{id}};
    $stream->write("\n");
  }
  $stream->write("=> /play/ijirait Back\n");
}

sub connect {
  my ($stream, $p, $name) = @_;
  if ($name) {
    my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
    my $dest = first { $_->{name} eq $name } @{$data->{rooms}};
    if ($dest) {
      $log->debug("Connecting $name");
      new_exit($room, $dest, $p);
      new_exit($dest, $room, $p);
      notify($p, "$p->{name} creates an exit to $dest->{name}.");
      result($stream, "30", "/play/ijirait");
      return;
    }
  }
  success($stream);
  $log->debug("Cannot connect '$name'");
  $stream->write(encode_utf8 "# Cannot connect “$name”\n");
  $stream->write(encode_utf8 "You need to provide the name of an existing room: “connect <room>”.\n");
  $stream->write(encode_utf8 "You can get a list of all existing rooms using “rooms”.\n");
  $stream->write("=> /play/ijirait Back\n");
}

sub emote {
  my ($stream, $p, $text) = @_;
  if (not $text) {
    result($stream, "10", "What happens");
    return;
  }
  my $w = {
    text => $text,
    author => $p->{id},
    ts => time,
  };
  my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
  push(@{$room->{words}}, $w);
  notify($p, $text);
  look($stream, $p);
}

sub hide {
  my ($stream, $p, $obj) = @_;
  if ($obj) {
    my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
    my $thing = first { $_->{short} eq $obj } @{$room->{things}};
    if ($thing) {
      $log->debug("Hide '$obj'");
      notify($p, "$p->{name} hides $thing->{name}.");
      $thing->{hidden} = 1;
      result($stream, "30", "/play/ijirait/look");
      return;
    }
    my $exit = first { $_->{direction} eq $obj } @{$room->{exits}};
    if ($exit) {
      $log->debug("Hide '$obj'");
      notify($p, "$p->{name} hides $exit->{name}.");
      $exit->{hidden} = 1;
      result($stream, "30", "/play/ijirait");
      return;
    }
  }
  success($stream);
  $log->debug("Hiding unknown object");
  $stream->write(encode_utf8 "# I don’t know what to hide\n");
  $stream->write(encode_utf8 "The command needs to use the shortcut of a thing, e.g. “hide stone”\n");
  $stream->write("=> /play/ijirait Back\n");
}

sub reveal {
  my ($stream, $p, $str) = @_;
  my ($obj, $cond, $id) = split(/\s+/, $str);
  if ($cond and $cond ne "for") {
    success($stream);
    $log->debug("Revealing object with unknown condition");
    $stream->write(encode_utf8 "# I don’t know how to reveal “$cond” something\n");
    $stream->write(encode_utf8 "The command needs to use the shortcut of a hidden thing, e.g. “reveal bird”.\n");
    $stream->write(encode_utf8 "You can add an option to that, by using “for” and a number."
		   . " The number must be the id of a thing or a room, e.g. “reveal bird for 123”."
		   . " Then the thing or exit you’re naming is revelead only if the character has"
		   . " examined the thing or been to the room with that id."
		   . " Use the “id” to show the id of things and of the room you’re in.\n");
    $stream->write("=> /play/ijirait Back\n");
    return;
  }
  if ($id and none { $_->{id} == $id } map { $_, @{$_->{things}} } @{$data->{rooms}}) {
    success($stream);
    $log->debug("Revealing object with impossible condition");
    $stream->write(encode_utf8 "# I don’t know how to reveal that\n");
    $stream->write(encode_utf8 "$id does not refer to a known room or thing.\n");
    $stream->write("=> /play/ijirait Back\n");
    return;
  }
  if ($obj) {
    my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
    my $thing = first { $_->{short} eq $obj } @{$room->{things}};
    if ($thing) {
      if ($thing->{hidden}) {
	$log->debug("Reveal '$obj'" . ($id ? " for $id" : ""));
	notify($p, "$p->{name} reveals $thing->{name}." . ($id ? " Maybe." : ""));
	if ($id) {
	  $thing->{seen} = $id;
	} else {
	  delete $thing->{hidden};
	  delete $thing->{seen};
	}
      }
      result($stream, "30", "/play/ijirait/look");
      return;
    }
    my $exit = first { $_->{direction} eq $obj } @{$room->{exits}};
    if ($exit) {
      if ($exit->{hidden}) {
	$log->debug("Reveal '$obj'" . ($id ? " for $id" : ""));
	notify($p, "$p->{name} reveals $exit->{name}." . ($id ? " Maybe." : ""));
	if ($id) {
	  $exit->{seen} = $id;
	} else {
	  delete $exit->{hidden};
	  delete $exit->{seen};
	}
      }
      result($stream, "30", "/play/ijirait");
      return;
    }
  }
  success($stream);
  $log->debug("Revealing unknown object");
  $stream->write(encode_utf8 "# I don’t know what to reveal\n");
  $stream->write(encode_utf8 "The command needs to use the shortcut of a hidden thing, e.g. “reveal bird”.\n");
  $stream->write(encode_utf8 "To list all the hidden things: “secrets”.\n");
  $stream->write("=> /play/ijirait Back\n");
}

sub secrets {
  my ($stream, $p, $phrase) = @_;
  if ($phrase and $phrase eq "are something I do not care for!") {
    $log->debug("Secrets");
    my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
    my @things = grep { $_->{hidden} } @{$room->{things}};
    my @exits = grep { $_->{hidden} } @{$room->{exits}};
    if (@things > 0) {
      $stream->write("## Hidden Things\n");
      for my $thing (@things) {
	my $name = uri_escape_utf8 $thing->{short};
	$stream->write(encode_utf8 "=> /play/ijirait/examine?$name $thing->{name} ($thing->{short})\n");
      }
    }
    if (@exits > 0) {
      $stream->write("## Hidden Exits\n");
      for my $exit (@exits) {
	my $direction = uri_escape_utf8 $exit->{direction};
	$stream->write(encode_utf8 "=> /play/ijirait/go?$direction $exit->{name} ($exit->{direction})\n");
      }
    }
    if (@things + @exits == 0) {
      $stream->write("## No secrets\n");
      $stream->write("There are neither hidden things nor hidden exists, here\n");
    }
    $stream->write("=> /play/ijirait Back\n");
    return;
  }
  success($stream);
  $log->debug("Secrets without a passphrase");
  $stream->write(encode_utf8 "# Secrets\n");
  $stream->write(encode_utf8 "Are you sure you want all the secrets to be revealed? If you are, please use the full command: “secrets are something I do not care for!”\n");
  $stream->write("=> /play/ijirait Back\n");
}

sub find {
  my ($stream, $p, $name) = @_;
  if (not $name) {
    success($stream);
    $log->debug("Missing a name in route finding");
    $stream->write(encode_utf8 "# Missing a name\n");
    $stream->write(encode_utf8 "You need to provide the name of an existing person: “find <name>”.\n");
    $stream->write(encode_utf8 "You can get a list of all existing persons using “who”.\n");
    $stream->write("=> /play/ijirait/who Who\n");
    $stream->write("=> /play/ijirait Back\n");
    return;
  }
  my $to;
  my $o = first { $_->{name} eq $name } @{$data->{people}};
  if ($o) {
    $to = $o->{location};
  } else {
    my $room = first { $_->{name} eq $name } @{$data->{rooms}};
    $to = $room->{id} if $room;
  }
  if (not $to) {
    success($stream);
    $log->debug("Cannot find '$name'");
    $stream->write(encode_utf8 "# Cannot find “$name”\n");
    $stream->write(encode_utf8 "You need to provide the name of an existing room or person: “find <name>”.\n");
    $stream->write(encode_utf8 "You can get a list of all existing rooms using “rooms”.\n");
    $stream->write(encode_utf8 "You can get a list of all existing persons using “who”.\n");
    $stream->write("=> /play/ijirait/rooms Rooms\n");
    $stream->write("=> /play/ijirait/who Who\n");
    $stream->write("=> /play/ijirait Back\n");
    return;
  }
  my $route = find_route($p->{location}, $to);
  if (not @$route) {
    success($stream);
    $log->debug("Cannot find a route to '$name'");
    $stream->write(encode_utf8 "# Cannot find a way\n");
    $stream->write(encode_utf8 "There seems to be no way to get from here to $name.\n");
    $stream->write(encode_utf8 "One of you must use the “connect” command to connect back to the rest of the game.\n");
    $stream->write("=> /play/ijirait Back\n");
    return;
  }
  success($stream);
  $log->debug("Find '$name'");
  $stream->write(encode_utf8 "# How to find $name\n");
  my $room = uri_escape_utf8 $route->[0]->{direction};
  $stream->write(encode_utf8 "=> /play/ijirait/$room $route->[0]->{name} ($route->[0]->{direction})\n");
  for (1 .. $#$route) {
    $stream->write(encode_utf8 "* $route->[$_]->{name} ($route->[$_]->{direction})\n");
  }
  $stream->write("=> /play/ijirait Back\n");
}

sub find_route {
  my ($from, $to) = @_;
  my %rooms = map { $_->{id} => $_ } @{$data->{rooms}};
  # breadth first!
  my @routes = map { [ $_ ] } @{$rooms{$from}->{exits}};
  my $route;
  while ($route = shift(@routes)) {
    my $last = $route->[$#$route];
    return $route if $last->{destination} == $to;
    for my $exit (@{$rooms{$last->{destination}}->{exits}}) {
      push(@routes, [@$route, $exit]) if none { $exit == $_ } @$route;
    }
  }
  return [];
}

sub id {
  my ($stream, $p, $obj) = @_;
  success($stream);
  if ($obj) {
    my $room = first { $_->{id} == $p->{location} } @{$data->{rooms}};
    if ($obj eq "room") {
      $log->debug("Id $obj");
      $stream->write($room->{id} . "\n");
      return;
    }
    my $thing = first { $_->{short} eq $obj } @{$room->{things}};
    if ($thing) {
      $log->debug("Id '$obj'");
      $stream->write($thing->{id} . "\n");
      return;
    }
  }
  $log->debug("Id unknown thing");
  $stream->write(encode_utf8 "# I don’t know what to id\n");
  $stream->write(encode_utf8 "The command needs to use the shortcut of a thing, e.g. “id bird”, or just “id room”.\n");
  $stream->write("=> /play/ijirait Back\n");
}

sub forget {
  my ($stream, $p, $id) = @_;
  $log->debug("Forget");
  success($stream);
  my %seen = map { $_->{id} => $_->{name}, map { $_->{id} => $_->{name} } @{$_->{things}} } @{$data->{rooms}};
  if ($id and $seen{$id}) {
    $stream->write("# Forgetting\n");
    $stream->write(encode_utf8 "You forget ever having seen: $seen{$id} ($id)\n");
    $p->{seen} = [grep { $_ != $id } @{$p->{seen}}];
    $stream->write("=> /play/ijirait/forget List all the other things you could forget\n");
  } elsif ($id) {
    $stream->write("# Forgetting the impossible\n");
    $stream->write(encode_utf8 "You can’t forget what you haven’t seen ($id).\n");
  } else {
    $stream->write(encode_utf8 "# Things you might want to forget:\n");
    for my $id (@{$p->{seen}}) {
      $stream->write(encode_utf8 "=> /play/ijirait/forget?$id $seen{$id} ($id)\n");
    }
  }
  $stream->write("=> /play/ijirait Back\n");
}

1;

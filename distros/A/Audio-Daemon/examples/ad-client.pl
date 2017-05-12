
use Audio::Daemon::Client;

sub log {
  my $type = shift;
  my $msg = shift;
  # return if ($type eq 'debug');
  my ($line, $function) = (@_)[2,3];
  $function = (split '::', $function)[-1];
  printf("%6s:%12s %7s:%s\n", $type, $function, '['.$line.']', $msg);
}

my $player = new Audio::Daemon::Client(Server => '127.0.0.1', Port => 9101, Log => \&log);

my $prompt = "Cmd > ";
syswrite(STDOUT, $prompt, length($prompt));

# loop getting lines and sending commands to the server specified above.

while (my $line = <STDIN>) {
  chop $line;
  if ($line eq 'add') {
    #
    # Right now, the "Add" command exists to just stick something in the playlist.
    # 
    #
    # $player->add(qw(stick.mp3 some.mp3 songs.mp3 here.mp3 to.mp3 play.mp3 with.mp3));
    $player->add(qw(/mp3/Rock/Fiona_Apple/Tidal/07-Never_Is_a_Promise.mp3 /mp3/Rock/Cracker/Kerosene_Hat/69-Eurotrash_Girl.mp3));
  } elsif ($line eq 'next') {
    $player->next;
  } elsif ($line=~/^play\s*/) {
    if ($line=~/play (\d+)/) {
      $player->play($1);
    } else {
      $player->play;
    }
  } elsif ($line eq 'prev') {
    $player->prev;
  } elsif ($line eq 'list') {
    $player->list;
    my $status = $player->{status};
    if (ref $status->{list}) {
      foreach my $i (0..$#{$status->{list}}) {
        printf("  %4s:%s\n", $i, $status->{list}[$i]);
      }
    }
  } elsif ($line eq 'info') {
    $player->info;
  } elsif ($line eq 'stop') {
    $player->stop;
  } elsif ($line eq 'pause') {
    $player->pause;
  } elsif ($line eq 'ff') {
    $player->jump('+10s');
  } elsif ($line=~/^jump (.+)/) {
    $player->jump($1);
  } elsif ($line eq 'rw') {
    $player->jump('-10s');
  } elsif ($line eq 'random on') {
    $player->random(1);
  } elsif ($line eq 'random off') {
    $player->random(0);
  } elsif ($line eq 'repeat on') {
    $player->repeat(1);
  } elsif ($line eq 'repeat off') {
    $player->repeat(0);
  } elsif ($line=~/^vol (\d+)/) {
    $player->vol($1);
  } elsif ($line=~/^del (.+)/) {
    $player->del(split /\s+/, $1);
  }
  my $status = $player->status;
  if (0) {
    foreach my $k (keys %{$status}) {
      print "$k => ".$status->{$k}."\n";
    }
  }
    
  # print "Sending ".($status->{frame})."\n";

  my $tdisplay = format_time($status->{frame});
  my @state = ('Stopped', 'Paused', 'Playing');
  print "   ".$state[$status->{state}]." $tdisplay\n";
  print "   \"".$status->{title}.'" by '.$status->{artist}."\n";

  syswrite(STDOUT, $prompt, length($prompt));
}

sub format_time {
  my $frame = shift;
  my ($pf,$rf,$ps,$rs) = split ',', $frame;
  return (gimme_time($ps).'/'.gimme_time($ps+$rs));
}

sub gimme_time {
  my $time = shift;
  my $mins = int($time/60);
  return $mins.':'.sprintf("%02.2f", $time - ($mins*60));
}
__END__

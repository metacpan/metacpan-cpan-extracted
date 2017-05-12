
use Audio::Daemon::MPG123::Client;

sub log {
  my $type = shift;
  my $msg = shift;
  my ($line, $function) = (@_)[2,3];
  $function = (split '::', $function)[-1];
  printf("%6s:%12s %7s:%s\n", $type, $function, '['.$line.']', $msg);
}

my $player = new Audio::Daemon::MPG123::Client(Server => 'localhost', Port => 9101, Log => \&log);

my $prompt = "Cmd > ";
syswrite(STDOUT, $prompt, length($prompt));
while (my $line = <STDIN>) {
  chop $line;
  if ($line eq 'add') {
    # $player->add(qw(stick.mp3 some.mp3 songs.mp3 here.mp3 to.mp3 play.mp3 with.mp3));
    $player->add(qw(/home/jay/Dave/11-Mr._Noah.mp3 /home/jay/Dave/06-Long_John.mp3 /home/jay/Dave/01-Samson_And_Delilah.mp3 /home/jay/Dave/23-Silver_Dagger.mp3 /home/jay/Dave/20-Fair_And_Tender_Ladies.mp3 /home/jay/Dave/04-Fixin'_To_Die.mp3));

  } elsif ($line eq 'next') {
    $player->next;
  } elsif ($line eq 'play') {
    $player->play;
  } elsif ($line eq 'prev') {
    $player->prev;
  } elsif ($line eq 'list') {
    $player->list;
  } elsif ($line eq 'info') {
    $player->info;
  } elsif ($line eq 'stop') {
    $player->stop;
  } elsif ($line eq 'pause') {
    $player->pause;
  } elsif ($line eq 'ff') {
    $player->jump('+5s');
  } elsif ($line eq 'rw') {
    $player->jump('-5s');
  } elsif ($line eq 'random on') {
    $player->random(1);
  } elsif ($line eq 'random off') {
    $player->random(0);
  } elsif ($line eq 'repeat on') {
    $player->repeat(1);
  } elsif ($line eq 'repeat off') {
    $player->repeat(0);
  }
  my $status = $player->status;
  foreach my $k (keys %{$status}) {
    print "$k => ".$status->{$k}."\n";
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

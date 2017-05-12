#test harness for DBD::iPod
BEGIN {
  use strict;
  use Test::More;
  plan tests => 7;
  use_ok('DBI');
  use_ok('DBD::iPod');
  use_ok('File::Spec::Functions');
}

$ENV{IPOD_ROOT} ||= '/mnt/ipod';

SKIP: {
  skip("no ipod found at $ENV{IPOD_ROOT}\n",4) unless
    -d catfile($ENV{IPOD_ROOT},'iPod_Control');

  ok(my $dbh = DBI->connect("dbi:iPod:".$ENV{IPOD_ROOT}), "connected to iPod");
  ok(my $sth = $dbh->prepare("SELECT * FROM iPod"));
  ok($sth->execute());

  my(%artist,$c,$count);

  print STDERR "\nGenerating stats from iPod, this may take a few minutes...\n";

  while(my $row = $sth->fetchrow_hashref){
    $artist{ $row->{artist} }++;
    $c += $row->{time};
    $count++;
  }

  my($h,$m,$s,$u) = (0,0,0,0);

  $c /= 1000; #milliseconds to seconds
  $cs = $c;
  $cm = int($c / 60);
  $cs %= 60;
  $ch = int($cm / 60);
  $cm %= 60;
  $cu = $c % 1;

  $cs += $cu;
  #how to 0pad float with sprintf()?
  $cs = sprintf("%.3f",$cs);
  $cs = '0'.$cs if $cs < 10;
  my $hmsu = sprintf('%02d:%02d:%s',$ch,$cm,$cs);

  print STDERR "\n\n".
  "=======================================\n".
  "         This iPod contains:\n".
  "  Artists:         ".scalar(keys(%artist))."\n".
  "  Tracks:          ".$count."\n".
  "  Total Play Time: ".$hmsu."\n".
  "=======================================\n\n".

  ok(1);
}

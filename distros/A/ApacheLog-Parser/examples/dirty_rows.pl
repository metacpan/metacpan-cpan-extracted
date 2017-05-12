#!/usr/bin/perl

use warnings;
use strict;

use ApacheLog::Parser qw(parse_line_to_hash);

my %rep = map({$_ => 0} qw(
  norequest noproto
  spaces_in_file spaces_in_params
  quotes_in_agent
));

my $count = 0;
my $max_pr = 0;
my $dirties = 0;
my $bad_rows = 0;

while(my $line = <>) {
  chomp($line);
  $count++;

  my %v = parse_line_to_hash($line);

  my $nok = 0;
  foreach my $bit (qw(request proto)) {
    unless($v{$bit}) {
      $rep{"no$bit"}++;
      $nok++;
    }
  }

  foreach my $bit (qw(file params)) {
    if($v{$bit} =~ m/ /) {
      $rep{"spaces_in_$bit"}++;
      $nok++;
    }
  }

  if($v{agent} =~ m/"/) {
    $rep{"quotes_in_agent"}++;
    $nok++;
  }

  if($nok) {
    $max_pr = $nok if($nok > $max_pr);
    $dirties += $nok;
    $bad_rows++;
  }
}

unless($dirties) {
  print "An amazingly clean logfile ($count lines)\n";
  exit;
}

my $buf = (sort({$b<=>$a} map({length($_)}
  grep({$rep{$_}} keys(%rep)))))[0];
$buf++;
print "report:\n";
foreach my $key (sort(keys(%rep))) {
  $rep{$key} or next;
  printf("  %-${buf}s $rep{$key}\n", $key . ':');
}

print "$dirties dirty bits in $bad_rows rows of $count total ",
  "(max: $max_pr/row)\n";

# vim:ts=2:sw=2:et:sta

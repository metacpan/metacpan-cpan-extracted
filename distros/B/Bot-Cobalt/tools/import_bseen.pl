#!/usr/bin/env perl

# Cheap tool for merging eggdrop bseen data to a Bot::Cobalt::Plugin::Seen DB

use feature 'say';
use strictures 2;

use Bot::Cobalt::Common;
use Bot::Cobalt::DB;

my $ctxt = 'Main';
my $casemap = 'rfc1459';
my ($bseen_path, $target_path);

use Getopt::Long;
GetOptions(
  help => sub {
    say
      "Usage: $0 --from=PATH --to=PATH [ --context=Main --casemap=rfc1459 ]";
    exit 0
  },

  'from=s' => \$bseen_path,
  'to=s'   => \$target_path,
  'context=s' => \$ctxt,
  'casemap=s' => \$casemap,
);

die "Expected 'from' and 'to' paths\n"
  unless $bseen_path and $target_path;
die "No such file: $bseen_path" unless -e $bseen_path;

open my $inputfh, '<', $bseen_path
  or die "Failed to open '${bseen_path}': $!";
my $seendb = Bot::Cobalt::DB->new(file => $target_path);
$seendb->dbopen or die "dbopen failure";

my ($count, $skip) = (0,0);
LINE: while (my $line = readline $inputfh) {
  chomp $line;
  next LINE if index($line, '#') == 0;

  my ($nick, $host, $ts, $action, $chan) = split ' ', $line;
  $nick = lc_irc $nick, $casemap;
  my $tag = join '%', $ctxt, $nick;

  if ( $seendb->get($tag) ) {
    # FIXME keep whichever is most recent perhaps?
    ++$skip;
    next LINE
  }

  my ($username, $hostname) = parse_user($host);
  my $ref = +{
    TS       => $ts,
    Host     => $host,
    Username => $username,
    Channel  => $chan,
    Action   => 'quit',  # OK, cheating
  };

  $seendb->put($tag, $ref);
  ++$count;
}

$seendb->dbclose;
close $inputfh or warn "close: $!";

say "Done! (merged $count, skipped $skip)";

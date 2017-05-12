# -*- perl -*-

# t/013.skip_env.t - changes to a file with a local SKIP env set

use strict;
use warnings;
use Test::Routine::Util;
use Test::More;

use FindBin '$Bin';
use lib "$Bin/lib";
use TestEnv;

my $log = TestEnv->vardir->file('log.txt');

{
  package FileRoutine;
  use Moose;
  with 'Routine::OneSkips', 'Routine::AuditAny';
}


run_tests('Tracking to a file' => 'FileRoutine' => {
  track_params => { 
    track_immutable => 1,
    track_all_sources => 1,
    collect => sub {
      # Notice this simple collector is *not* pulling any data via
      # datapoints. Datapoints are optional sugar that are only
      # pulled when called from a -Collector-
      my $ChangeSet = shift;
      open LOG, ">> $log" or die $!;
      print LOG join("\t",
        $_->ChangeContext->action,
        $_->column_name,
        $_->old_value || '<undef>',
        $_->new_value || '<undef>'
      ) . "\n" for ($ChangeSet->all_column_changes);
      close LOG;
    }
  }
});





my $d = {};
ok(open(LOG, "< $log"), "Open the log file for reading");
while(<LOG>) {
  chomp $_;
  my @cols = split(/\t/,$_,4);
  $d->{$cols[0]}->{$cols[1]} = { 
    old => $cols[2], 
    new => $cols[3]
  }
}
close LOG;

ok(
  (
    $d->{insert}->{first}->{new} eq 'John' and
    $d->{insert}->{last}->{new} eq 'Smith'
  ), 
  "Log contains expected INSERT entries"
);

ok(
  (not exists $d->{update}),
  "Log has no UPDATE entries"
);

ok(
  (
    $d->{delete}->{first}->{old} eq 'John' and
    $d->{delete}->{last}->{old} eq 'Doe'
  ), 
  "Log contains expected DELETE entries"
);


done_testing;

package BugCli::Summaries;

push @Term::Shell::ISA, __PACKAGE__
  unless grep { $_ eq __PACKAGE__ } @Term::Shell::ISA;

sub smry_changelog { "Display closed bugs for specified range" }

sub smry_delete { "Wipes a bug from database" }

sub smry_config { "Program configuration" }

sub smry_show { "Display bug information by it's bug_id or regexp on subject"; }

sub smry_bugs { "Executes SQL query on the databse" }

sub smry_history { "Shows last executed commands" }

sub smry_fix { "Update bug's status to FIXED and add comment to bug" }

sub smry_take { "Update bug's status to ASSIGNED and add comment to bug" }

sub smry_comment { "Add comment to bug" }

1;

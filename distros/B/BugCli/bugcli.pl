#!/usr/bin/perl -w
use Term::ANSIColor qw(:constants);
# vi:fdm=marker fdl=0:

$Term::ANSIColor::AUTORESET = 1;


my($path) = $0 =~ /^(.*)\//;
push @INC,$path;
require BugCli;


my ($shell) = BugCli->new;
print BLUE . ">> " . GREEN
  . "Welcome to BugZilla CLI by Reflog v$shell->{API}{version}"
  . BLUE . " <<"
  . CLEAR . "\n";
if (not $shell->read_config() ) {
    $shell->run_config();
    $shell->unload_defaults();
}
$shell->init_mysql();
if ( not @ARGV ) {    # no params, start interactive mode
    $shell->cmdloop;
}
else {                #got params. parse and start working.
    my (@commands) = split /;/, $ARGV[0];
    print RED
      . " WARNING: "
      . RESET
      . "All commands are your responsibility!\n";
    foreach (@commands) {
        print BLUE . ">> " . GREEN
          . "Executing: "
          . RESET
          . $_
          . BLUE . " <<"
          . RESET . "\n";
        $shell->cmd($_);
    }
}

$shell->write_config();

1;

__END__

=head1 NAME

BugCli - Command line interface for BugZilla server

=head1 SYNOPSIS

 >  bugcli
 >  bugcli command
 >  bugcli "command1 ; command2 ; command with params"

=head1 DESCRIPTION

This little baby is a tool for people who make tons of bugfixes each day, want to do it
more efficently, i.e. do not use the freaking browser!



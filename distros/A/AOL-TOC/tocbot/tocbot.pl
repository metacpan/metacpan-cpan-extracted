#!/bin/perl

use AOL::TOC;

if ( ! -f "tocbot.config" ) {
  die "tocbot: no config file!\n";
}

require "tocbot.config";

for $name (@tocbot_modules) {
  print "tocbot: loading module $name\n";
  require "$name".".pl";
  eval { &{$name . "_init"} };
}

open(client_config, "toc.config");
$client_config = join('', <client_config>);
close(client_config);

$toc = AOL::TOC::new($tocbot_config{tochost}, $tocbot_config{authorizer},
                     $tocbot_config{port},
                     $tocbot_config{nickname}, $tocbot_config{password});
#$toc->set_debug(9);
$toc->connect();

$toc->register_callback("ERROR", \&client_error);
$toc->register_callback("CLOSED", \&client_closed);
$toc->register_callback("SIGN_ON", \&client_signon);
$toc->register_callback("IM_IN", \&client_im);
$toc->register_callback("UPDATE_BUDDY", \&client_buddy);

while (1) {
  $toc->dispatch();
}


sub client_im {
  my ($self, $nickname, $autoresponse, $message) = @_;
  my $cmd, $args;

  print "tocbot: $nickname says \"$message\"\n";

  if ($autoresponse eq "T") {
    print "tocbot: $nickname is away, ignoring.\n";
    return;
  }

  ($cmd, $args) = ($message =~ /bot\((\w+)\b(.*)\)/i);
  if ($cmd && do_command($nickname, $cmd, $args)) {
    return;
  }

  if ($message =~ /HELP/i) {
    send_help($nickname);
    return;
  }

  $toc->send_im($nickname, "Hi, I'm a bot. Do you need 'HELP'?");
}


sub send_help {
  my ($nickname) = @_;

  $toc->send_im($nickname, "I'm a bot. I have the following modules installed:");
  sleep(1);
  $toc->send_im($nickname, "    @tocbot_modules");
  sleep(1);
  $toc->send_im($nickname, "You can invoke a module by telling me 'bot(module ...)'");
}


sub do_command {
  my ($nickname, $cmd, $args) = @_;
  my @eargs = split(' ', $args);

  tocbot_exec_command($cmd, $nickname, @eargs);

  return 1;
}


sub client_signon {
  $toc->add_buddy("jamersepoo", "jamers20VA");
  $toc->send_im("jamersepoo", "tocbot online");
}


sub client_error {
  my ($self, $code) = @_;

  print "tocbot: TOC error $code.\n";
}


sub client_closed {
  my ($self) = @_;

  print "tocbot: connection closed, exiting.\n";
  exit (0);
}


sub client_buddy {
  my ($self, $nickname, $online, $evil, $signon_time, $idle_time, $class) = @_;

  print "tocbot: buddy $nickname signed on\n";
}


sub tocbot_register_command {
  my ($cmd, $func, @args) = @_;

  print "Registered command '$cmd'\n";
  $tocbot_commands{$cmd}  = $func;
}

sub tocbot_exec_command {
  my ($cmd, @args) = @_;

  eval { &{$tocbot_commands{$cmd}} (@args) };
}

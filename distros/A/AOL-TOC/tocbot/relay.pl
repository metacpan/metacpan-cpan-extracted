#
# relay.pl
#

sub relay_init {
  tocbot_register_command("relay", \&relay_func);
}

sub relay_func {
  my ($nickname, $relayto, @message) = @_;

  print "tocbot: relay: relay message \"@message\" to $relayto\n";

  $toc->send_im($relayto, "Message relayed from $nickname: @message");
}

1;

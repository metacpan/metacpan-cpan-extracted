#
# fortune.pl
#

sub fortune_init {
  tocbot_register_command("fortune", \&fortune_func);
}

sub fortune_func {
  my ($nickname, $relayto, @message) = @_;
  my @fortune;

  print "tocbot: fortune: $nickname requested a fortune!\n";

  open (ff, "/bin/fortune|");
  @fortune = <ff>;
  close (ff);

  $toc->send_im($nickname, "Your fortune is:");
  sleep(1);
  $toc->send_im($nickname, "<i> @fortune </i>");
}

1;

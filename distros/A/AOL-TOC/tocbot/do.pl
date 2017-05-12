#
# do.pl
#

sub do_init {
  tocbot_register_command("do", \&do_func);
}

sub do_func {
  my ($nickname, $cmd, @args) = @_;

  if ($cmd eq "send_im") {
    ($nickname, @message) = @args;
    print "tocbot: do: send_im($nickname, @message)\n";
    $toc->send_im($nickname, "@message");
  }

  if ($cmd eq "add_buddy") {
    print "tocbot: do: add_buddy(@args)\n";
    $toc->add_buddy("@args");
  }

  if ($cmd eq "remove_buddy") {
    print "tocbot: do: remove_buddy(@args)\n";
    $toc->remove_buddy("@args");
  }

  if ($cmd eq "evil") {
    ($nickname, $mode) = @args;
    print "tocbot: do: evil($nickname, $mode)\n";
    $toc->evil($nickname, $mode);
  }

  if ($cmd eq "add_permit") {
    print "tocbot: do: add_permit(@args)\n";
    $toc->add_permit("@args");
  }

  if ($cmd eq "add_deny") {
    print "tocbot: do: add_deny(@args)\n";
    $toc->add_deny("@args");
  }

  if ($cmd eq "chat_join") {
    print "tocbot: do: chat_join(@args)\n";
    $toc->chat_join("@args");
  }

  if ($cmd eq "chat_send") {
    my ($room, @message) = @args;
    print "tocbot: do: chat_send($room, @message)\n";
    $toc->chat_send($room, "@message");
  }

  if ($cmd eq "chat_whisper") {
    my ($room, $nickname, @message) = @args;
    print "tocbot: do: chat_whisper($room, $nickname, @message)\n";
    $toc->chat_whisper($room, $nickname, "@message");
  }

  if ($cmd eq "chat_evil") {
    my ($room, $nickname, $mode) = @args;
    print "tocbot: do: chat_evil($room, $nickname, $mode)\n";
    $toc->chat_evil($room, $nickname, $mode);
  }

  if ($cmd eq "chat_invite") {
    my ($room, $message, @buddies) = @args;
    print "tocbot: do: chat_invite($room, $message, @buddies)\n";
    $toc->chat_invite($room, $message, "@buddies");
  }

  if ($cmd eq "chat_leave") {
    my ($room) = @args;
    print "tocbot: do: chat_leave($room)\n";
    $toc->chat_leave($room);
  }

  if ($cmd eq "chat_accept") {
    my ($room) = @args;
    print "tocbot: do: chat_accept($room)\n";
    $toc->chat_accept($room);
  }

  if ($cmd eq "get_info") {
    my ($nickname) = @args;
    print "tocbot: do: get_info($nickname)\n";
    $toc->get_info($nickname);
  }

  if ($cmd eq "set_info") {
    print "tocbot: do: set_info(@args)\n";
    $toc->set_info("@args");
  }
}

1;

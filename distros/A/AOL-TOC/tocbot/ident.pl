#
# ident.pl
#

sub ident_init {
  tocbot_register_command("ident", \&ident_identify);
  tocbot_register_command("unident", \&ident_unidentify);
}

sub ident_identify {
  my ($nickname, @args) = @_;

  print "tocbot: ident: identified user $nickname\n";
  $toc->add_buddy($nickname);
}

sub ident_unidentify {
  my ($nickname, @args) = @_;

  print "tocbot: ident: unidentified user $nickname\n";
  $toc->remove_buddy($nickname);
}

1;

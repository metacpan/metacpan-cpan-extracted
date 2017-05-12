package Apache::DumpHeaders;
use strict;
use Apache;
use Apache::Constants qw(DECLINED OK);
use vars qw($VERSION);

$VERSION = "0.94";

sub handler {
  my $r = shift;
  my $note = $r->notes("DumpHeaders");
  if ($r->dir_config("DumpHeaders_Conditional")) {
    return DECLINED unless $note;
  }
  if ($r->dir_config("DumpHeaders_Percent")) {
    return DECLINED unless rand(100) < $r->dir_config("DumpHeaders_Percent");
  }
  if ($r->dir_config("DumpHeaders_IP")) {
    my $remote_ip = $r->connection->remote_ip;
    return DECLINED unless grep { /\Q$remote_ip\E/ }
      split (/\s+/, $r->dir_config("DumpHeaders_IP"));
  }
  my $filename = $r->dir_config("DumpHeaders_File") or return DECLINED;
  unless (open OUT, ">>$filename") {
    warn "Failed to open $filename: $!";
    return DECLINED;
  }
  my $msg = ($note and $note =~ /\D/) ? "$note " : "";
  print OUT "\n======= ", scalar localtime, " $msg=======\n";
  print OUT $r->as_string;
  close OUT;
  return OK;
}

1;

__END__

=head1 NAME

Apache::DumpHeaders - Watch HTTP transaction via headers

=head1 SYNOPSIS

 #httpd.conf or some such
 PerlLogHandler  Apache::DumpHeaders
 PerlSetVar      DumpHeaders_File -
 PerlSetVar      DumpHeaders_IP "1.2.3.4 1.2.3.5"
 #PerlSetVar     DumpHeaders_Conditional 1
 #PerlSetVar     DumpHeaders_Percent 5

=head1 DESCRIPTION

This module is used to watch an HTTP transaction, looking at the
client and servers headers.

With Apache::ProxyPassThru configured, you are able to watch your browser
talk to any server besides the one with this module living inside.

=head1 PARAMETERS

This module is configured with PerlSetVar's. All the "only dump if
..." options are "AND" conditions. If not all of them matches we won't
dump the headers. 

If you need some more complicated logic you could use the
DumpHeaders_Conditional parameter alone and have another module do the
"dump or dump not" logic with r->notes("DumpHeaders").

=head2 DumpHeaders_File

Required parameter to specify which file you want to dump the headers
to.

=head2 DumpHeaders_IP

Optional parameter to specify which one or more IP addresses you want
to dump traffic from.

=head2 DumpHeaders_Conditional 

If this is set to a true value we'll only dump the headers if another
module have set r->notes("DumpHeaders") to a true value.

=head2 DumpHeaders_Percent

If this is set, we'll only dump the specified percent of the requests.

=head1 SUPPORT

The latest version of this module can be found at CPAN and at
L<http://develooper.com/code/Apache::DumpHeaders/>. Send questions and
suggestions to the modperl mailinglist (see L<http://perl.apache.org/>
for information) or directly to the author (see below).

=head1 SEE ALSO

mod_perl(3), Apache(3), Apache::ProxyPassThru(3)

=head1 AUTHOR

Ask Bjoern Hansen <ask@develooper.com>.

Originally by Doug MacEachern.



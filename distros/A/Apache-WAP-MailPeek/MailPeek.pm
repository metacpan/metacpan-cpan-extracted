package Apache::WAP::MailPeek;
use strict;
use Apache::Constants qw(:common);
use Mail::Cclient;

our $VERSION = '0.01';
our $mail_server = 'brians.org';

Mail::Cclient::parameters(
  'NIL',
  RSHTIMEOUT     => 0,
  OPENTIMEOUT    => 1,
  READTIMEOUT    => 1,
  CLOSETIMEOUT   => 1,
  MAXLOGINTRIALS => 1,
);

sub handler {
  my $r      = shift;
  my @msgnos = ();
  my %params = $r->method eq 'POST' ? $r->content : $r->args;

  Mail::Cclient::set_callback
        login    => sub {
            return $params{'username'}, $params{'password'}
        },
        searched   => sub {
            push (@msgnos, $_[1]);
        },
        log => sub { print @_ }, dlog => sub { print @_};

  my $mail = Mail::Cclient->new("{$mail_server/imap}") or die $!;

  $r->content_type('text/vnd.wap.wml');
  $r->send_http_header;

  $r->print(<<END);
    <?xml version="1.0" encoding="iso-8859-1"?>
      <!DOCTYPE wml PUBLIC "-//WAPFORUM//DTD WML 1.1//EN"
                    "http://www.wapforum.org/DTD/wml_1.1.xml">
    <wml><card id="mail">
END

  $mail->search("UNSEEN");
  foreach my $msgno (@msgnos) {
      my ($envelope,$body) = $mail->fetchstructure($msgno);
      my $subject = $envelope->subject;
      my $from    = ${$envelope->{from}}[0]->{personal} ||
              ${$envelope->{from}}[0]->{mailbox} . "@" .
              ${$envelope->{from}}[0]->{host};
      $from =~ s/\&/\&amp\;/g; $subject =~ s/\&/\&amp\;/g;
      $from =~ s/\$/\$\$/g; $subject =~ s/\$/\$\$/g;
      $r->print ("<p><b>", $from, "</b>: ", $subject, "</p>\n");
  }
  $mail->close;
  $r->print("</card></wml>");
}
1;

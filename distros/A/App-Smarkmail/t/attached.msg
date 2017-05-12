From rjbs@manxome.org Wed Feb 20 07:17:46 2008
Date: Wed, 20 Feb 2008 07:17:46 -0500
From: Ricardo SIGNES <rjbs@manxome.org>
To: rjbs@cpan.org
Subject: example msg with attachment
Message-ID: <20080220121746.GA13105@knight.local>
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="a8Wt8u1KmwUX3Y2C"
Content-Disposition: inline
X-Message-Flag: Warning: This sender thinks he is better than you.
X-Planet: Planet of the Apes
User-Agent: Mutt/1.5.17 (2007-11-01)


--a8Wt8u1KmwUX3Y2C
Content-Type: text/plain; charset=us-ascii
Content-Disposition: inline


This is a *Markdown*-like text message with [links](http://rjbs.manxome.org/)
and so on.

-- 
rjbs

--a8Wt8u1KmwUX3Y2C
Content-Type: application/x-perl
Content-Disposition: attachment; filename="Smarkmail.pm"
Content-Transfer-Encoding: quoted-printable

use strict;=0Ause warnings;=0Apackage App::Smarkmail;=0A=0Ause Email::MIME;=
=0Ause Email::MIME::Creator;=0Ause Email::MIME::Modifier;=0Ause Text::Markd=
own;=0A=0Asub markdown_email {=0A  my ($self, $msg, $arg) =3D @_;=0A=0A  my=
 $to_send =3D eval { ref $msg and $msg->isa('Email::MIME') }=0A            =
  ? $msg=0A              : Email::MIME->new($msg);=0A=0A  if ($to_send->con=
tent_type =3D~ m{^text/plain}) {=0A    my ($text, $html) =3D $self->_parts_=
=66rom_text($to_send);=0A=0A    $to_send->content_type_set('multipart/alter=
native');=0A    $to_send->parts_set([ $html, $text ]);=0A  } elsif ($to_sen=
d->content_type =3D~ m{^multipart/related}) {=0A    my @parts =3D $to_send-=
>subparts;=0A    if ($parts[0]->content_type =3D~ m{^text/plain}) {=0A     =
 my ($text, $html) =3D $self->_parts_from_text($parts[0]);=0A      $to_send=
->content_type_set('multipart/alternative');=0A      $to_send->parts_set([ =
$html, $text ]);=0A    }=0A  }=0A=0A  return $to_send;=0A}=0A=0Asub _parts_=
=66rom_text {=0A  my ($self, $email) =3D @_;=0A=0A  my $text =3D $email->bo=
dy;=0A  my $html =3D Text::Markdown::markdown($text, { tab_width =3D> 2 });=
=0A=0A  my $html_part =3D Email::MIME->create(=0A    attributes =3D> { cont=
ent_type =3D> 'text/html', },=0A    body       =3D> $html,=0A  );=0A=0A  my=
 $text_part =3D Email::MIME->create(=0A    attributes =3D> { content_type =
=3D> 'text/plain', },=0A    body       =3D> $text,=0A  );=0A=0A  return ($t=
ext_part, $html_part);=0A}=0A=0A1;=0A
--a8Wt8u1KmwUX3Y2C
Content-Type: application/x-troff
Content-Disposition: attachment; filename="basic.t"
Content-Transfer-Encoding: quoted-printable

use strict;=0Ause warnings;=0Ause App::Smarkmail;=0Ause Email::MIME;=0Ause =
Test::More 'no_plan';=0A=0Amy $email =3D <<'END_EMAIL';=0ASubject: this is =
an email=0AFrom: X. Ample <xample@example.com>=0ATo: Reginald E. Cipient <r=
ecipient@example.net>=0AMIME-Version: 1.0=0AContent-Type: text/plain=0A=0AT=
his is plain text.=0AEND_EMAIL=0A=0Amy $marked_mail =3D App::Smarkmail->mar=
kdown_email($email);=0A=0Adiag $marked_mail->as_string;=0A=0Aok(1);=0A
--a8Wt8u1KmwUX3Y2C--

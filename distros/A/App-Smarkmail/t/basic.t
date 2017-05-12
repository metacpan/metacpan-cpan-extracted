use strict;
use warnings;
use App::Smarkmail;
use Email::MIME;
use Test::More 'no_plan';

{
  my $email = <<'END_EMAIL';
Subject: this is an email
From: X. Ample <xample@example.com>
To: Reginald E. Cipient <recipient@example.net>
MIME-Version: 1.0
Content-Type: text/plain

This is plain text.

-- 
the amazing x-man
END_EMAIL

  my $marked_mail = App::Smarkmail->markdown_email($email);

}

{
  my $email = do { local $/; open my $fh, 't/attached.msg'; <$fh> };

  my $marked_mail = App::Smarkmail->markdown_email($email);
}

ok(1);

package CAM::EmailTemplate;

=head1 NAME

CAM::EmailTemplate - Template-based email message sender

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

There are many, many other templating and emailing modules on CPAN.
Unless you have a specific reason for using this one, you may have
better searching for a different one.

This module is a bit clumsy in the way it sends email (relying on
Sendmail), and doesn't thoroughly ensure that the outgoing emails are
valid, but it is very handy in its integration with a templating
engine.

=head1 SYNOPSIS

  use CAM::EmailTemplate;
  
  my $template = new CAM::EmailTemplate($filename);
  $template->setParams(recipient => 'user@foo.com',
                       bar => 'baz', kelp => 'green');
  if ($template->send()) {
     print 'Sent.';
  } else {
     print 'Doh!  ' . $template->{sendError};
  }

=head1 DESCRIPTION

CAM::EmailTemplate extends CAM::Template for sending template-based
email messages.  The mechanism for sending is 'sendmail -i -t' so this
module requires that the computer is a Unixish machine set up for
sending.  Many simple but handy sanity tests are performed by the
send() function.

The template itself must contain all of the requisite mail header
info, including 'To:' and 'From:' lines.  Read the EXAMPLES section
below to see demos of what this looks like.

=cut

require 5.005_62;
use strict;
use warnings;
use Carp;
use CAM::Template;

our @ISA = qw(CAM::Template);
our $VERSION = '0.92';

# Package globals

my @global_possible_paths = (
                             "/usr/bin/sendmail", 
                             "/usr/lib/sendmail", 
                             "/usr/ucblib/sendmail",
                             );
my $global_sendmail_path = "";  # cache the path when we find it


=head1 INSTANCE METHODS

=over 4

=cut

=item setEnvelopSender ADDRESS

Changed the sender as reported by sendmail to the remote host.  Note
that this may be visible to the end recipient.

=cut

sub setEnvelopSender
{
   my $self = shift;
   my $sender = shift;

   $self->{envelopSender} = $sender;
}

=item send

Fill the template and send it out.  If there is an error (badly
formatted message, sendmail error, etc), this function returns undef.
In this case, an explanatory string for the error can be obtained from
the $template->{sendError} property.

=cut

sub send
{
   my $self = shift;

   $self->{sendError} = undef;

   my $content = $self->toString();
   if (!$content)
   {
      $self->{sendError} = "Did not find the template.";
      return undef;
   }

   if ($content !~ /\n$/s)
   {
      &carp("Appending a newline to the end of the email message");
      $content .= "\n";
   }

   if ($content !~ /^(.*\n)\n/s)
   {
      $self->{sendError} = "Did not find the end of the email header.";
      return undef;
   }

   my $header = $1;
   foreach my $fieldname ("To:", "From:")
   {
      if ($header !~ /^$fieldname\s+(\S+.*?)$/m)
      {
         $self->{sendError} = "There is no '$fieldname' field in the email header.";
         return undef;
      }
      my @addrs = split /,/, $1;
      foreach my $addr (@addrs) {
         if ($addr !~ /^\s*[^@]+@[^@]+\s*$/ &&
             $addr !~ /^\s*[^,<@]*<[^@]+@[^@]+>\s*/)
         {
            $self->{sendError} = "Invalid email address in '$addr' in the $fieldname header field.";
            return undef;
         }
      }
   }
   if ($header !~ /^Subject: /m)
   {
         $self->{sendError} = "There is no 'Subject:' field in the email header.";
         return undef;
   }
   
   # Do the actual delivery now
   my ($success, $error) = $self->deliver($content);
   if ($success)
   {
      return $self;
   }
   else
   {
      $self->{sendError} = $error;
      return undef;
   }
}

=item deliver MSG

Delivers the message.  This function assumes that the message is
properly formatted.

This function should ONLY be called from with the send() method.  It
is provided here so that it can be overridden by subclasses.  

It should return an array of two values: either (true, undef) or
(false, errormessage) indicating success or failure.

This particular implementation relies on the existance of a sendmail
binary on the host machine.

=cut

sub deliver
{
   my $self = shift;
   my $content = shift;

   my $error = undef;
   my $sendmail = $self->_getSendmailPath();
   if (!$sendmail)
   {
      $error = "Could not find the mail agent program.";
   }
   else
   {
      local $ENV{PATH} = "";
      local *MAIL;
      my $cmd = "$sendmail -i -t";
      if ($self->{envelopeSender})
      {
         $cmd .= " -f".$self->{envelopeSender};
      }
      if (!open (MAIL, "| $cmd"))
      {
         $error = "Failed to contact the mail agent";
      }
      else
      {
         print MAIL $content;
         
         if (!close(MAIL))
         {
            $error = "The mail agent did not complete the message delivery";
         }
      }
   }
   return $error ? (undef, $error) : ($self, undef);
}

## Internal function
# find the sendmail executable
sub _getSendmailPath
{
   my $self = shift;

   if (!$global_sendmail_path)
   {
      foreach my $try (@global_possible_paths) {
         if (-x $try)
         {
            $global_sendmail_path = $try;
            last;
         }
      }

   }
   return $global_sendmail_path;
}

1;
__END__

=back

=head1 EXAMPLES

Here is an example template, formatted for consumption by sendmail:

  To: ::recipient::
  From: "Emailer Script" <emailer@somehost.clotho.com>
  Subject: A sample template
  MIME-Version: 1.0
  Content-Type: text/plain
  X-Sender: CAM::EmailTemplate
  
  This is a sample CAM::EmailTemplate file.  The blank line between
  the header and the body is crucial.  The 'To:', 'From:' and
  'Subject:' lines are required.  The others are optional.
  
  Although this example is indented in the documentation, the real
  template should have no indentation in the mail header.
  
  Best wishes,
  Chris

Here is another example, with both HTML and plain text versions of the
message:

  To: "::firstname:: ::lastname::" <::recipient::>
  From: "::myName::" <::myEmailAddr::>
  Subject: ::subject::
  MIME-Version: 1.0
  Content-Type: multipart/alternative; boundary="----_=_AnotherMIMEPiece"
  
  This message is in MIME format. You will only see this message if
  your mail program does not speak MIME.
  
  ------_=_AnotherMIMEPiece
  Content-Type: text/plain; charset=us-ascii
  Content-Transfer-Encoding: 7bit
  
  This is a sample CAM::EmailTemplate message.  This part is
  _plain_text_.  Generally, you should have the same message in both
  parts, but this demo breaks that convention.
  
  ::myName::
  ------_=_AnotherMIMEPiece
  Content-Type: text/html; charset=us-ascii
  Content-Transfer-Encoding: 7bit
  
  This is a sample CAM::EmailTemplate message.  This part is <u>html</u>.
  Generally, you should have the same message in both parts, but this
  demo breaks that convention  slightly.<br><br>::myName::
  ------_=_AnotherMIMEPiece--

Note that MIME messages are split by the 'boundary' string which can
be anything unique.  The final boundary should be suffixed with '--',
as shown above.

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

package CAM::EmailTemplate::SMTP;

=head1 NAME

CAM::EmailTemplate::SMTP - Net::SMTP based email message sender

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

  use CAM::EmailTemplate::SMTP;
  
  CAM::EmailTemplate::SMTP->setHost("mail.foo.com");
  my $template = new CAM::EmailTemplate::SMTP($filename);
  $template->setParams(recipient => 'user@foo.com',
                       bar => "baz", kelp => "green");
  if ($template->send()) {
     print "Sent.";
  } else {
     print "Doh!  " . $template->{sendError};
  }

=head1 DESCRIPTION

This package is exactly like CAM::EmailTemplate except that it uses
the Perl Net::SMTP package to deliver mail instead of a local sendmail
executable.

To accomplish this, the programmer must configure the mailhost before
attempting to send.

See README for a comparison with other CPAN modules.

=cut

require 5.005_62;
use strict;
use warnings;
use CAM::EmailTemplate;
use Net::SMTP;

our @ISA = qw(CAM::EmailTemplate);
our $VERSION = '0.91';

# Package globals

my $global_mailhost = undef;


=head1 FUNCTIONS

=over 4

=cut


=item setHost HOST

Create a new template object.  The parameters are the same as the
CAM::Template constructor.

This can be called as a class method or an instance method.  If used
as a class method, all subsequent instances use the specified host.
If used as an instance method, the host only applies to this one
instance.

=cut

sub setHost
{
   my $pkg_or_self = shift;
   my $mailhost = shift;

   if (ref($pkg_or_self))
   {
      my $self = $pkg_or_self;
      $self->{mailhost} = $mailhost
   }
   else
   {
      $global_mailhost = $mailhost
   }
   return $pkg_or_self;
}


=item deliver MSG

Delivers the message.  This function assumes that the message is
properly formatted.

This method overrides the deliver() method in CAM::EmailTemplate,
implementing the Net::SMTP functionality.

=cut

sub deliver
{
   my $self = shift;
   my $content = shift;

   my $error = undef;
   my $mailhost = $self->{mailhost} || $global_mailhost;
   if (!$mailhost)
   {   
      $error = "No mail host specified";
   }
   else
   {
      my $smtp = Net::SMTP->new($mailhost, 
                                Debug => ($ENV{SMTPTemplate_Debug} || 0));
      if (!$smtp)
      {
         $error = "Failed to connect to the mail server";
      }
      else
      {
         my $header = $content;
         $header =~ s/\n\n.*/\n/s;

         my $headerlength = length($header);

         my %fields = ();
         while ($header)
         {
            if ($header =~ s/^([^:\n]+):[ \t]*([^\n]*)\n//)
            {
               my $fieldname = $1;
               my $value = $2;

               # Special case: Clean up address lines
               if ($fieldname =~ /^To|From|Cc|Bcc$/)
               {
                  foreach my $email (split /\s*,\s*/, $value)
                  {
                     $email =~ s/^[^<]*<([^>]*)>.*$/$1/s;
                     push @{$fields{$fieldname}}, $email;
                  }
               }
               else
               {
                  push @{$fields{$fieldname}}, $value;
               }
            }
            else
            {
               my $line = substr($header, 0, 40) . "...";
               $line =~ s/\n.*//s;
               $error = "Problem parsing header: $line";
               last;
            }
         }

         # Remove BCCs
         substr($content, 0, $headerlength) =~ s/^Bcc: .*$//gm;
         # Add in the mailer agent field to the header
         $content =~ s/\n\n/\nX-Mailer: CAM::EmailTemplate::SMTP[v$VERSION] Net::SMTP[v$Net::SMTP::VERSION]\n\n/s;

         if (!$error)
         {
            if (!$smtp->mail($fields{From}->[0]))
            {
               $error = "Failed to send the 'From:' field, aborting";
               $smtp->reset();
            }
            elsif (!$smtp->to(@{$fields{To}}))
            {
               $error = "Failed to send to '@{$fields{To}}', aborting";
               $smtp->reset();
            }
            elsif(!$smtp->data($content))
            {
               $error = "Failed to send message, aborting";
               $smtp->reset();
            }

            if (!$smtp->quit())
            {
               $error = "The mail agent did not complete the message delivery";
            }
         }
      }
   }
   return $error ? (undef, $error) : ($self, undef);
}

1;
__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

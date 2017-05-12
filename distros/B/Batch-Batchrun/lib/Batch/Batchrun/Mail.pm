#
# File: Batch::Batchrun::Mail.pm
#
# Usage: Subroutine
#
# Purpose: Provide mail services to Batchrun
#
# Author: DL Anderson 4/14/98
#
# Version: 1.03
#
# Why use Mail.pm?  Using a standard mail utility will allow us to make
# enhancements without rewriting every piece of code that sends mail!
#
# Below are the fields to pass Mail.pm and how to do it.  POD documentation
# at the bottom.
#
#  ADDRESS     List of addresses to send the message(Required)
#  SUBJECT     What the message is about
#  MESSAGE     The text of what you want to say
#  PRIORITY    Usually URGENT or NORMAL or LOW
#  FROM        Who do you want the message from or where should a user reply?
#  CC          List of addresses to send a copy of the message
#  HTML        HTML version of the message
#  SMTPSERVER  A list of servers to use for SMTP
#  ATTACHMENTS File attachments
#***************************************************************************
#  Revision History
#
#   Author         Date        Modification
#
#  Daryl Anderson  11/12/97    Added support for html and x-priority
#  John Burke      1/9/98      Added defined() checks to ensure clean run with -w flag
#  Daryl Anderson  04/14/98    Made into perl5 module.
#  Daryl Anderson  01/06/99    Added file attachments for NT.
#  Carol Chan      07/21/99    Uses MIME::Lite
#                              Some of the code taken from:
#                                   The Perl Journal
#                                   Issue #14 (Vol. 4, No. 2), Summer 1999
#                                   E-mail with Attachments, by Dan Sugalski (p29)
#--------------------------------------------------------------------------

package Batch::Batchrun::Mail;

use strict;
no strict 'vars';
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA     = qw(Exporter);
@EXPORT     = qw(mail);
$VERSION = '1.03';

# Preloaded methods go here.
use strict;
use MIME::Lite;
sub mail
{

    my ($failure) = 0;

    #------------------------------------------------------------------------
    #  Get passed parameters and make upper case
    #------------------------------------------------------------------------

    my(@tmpparms) = @_;
    my($i,$tmpdir);
    my($newfile,$oldfile) = ("","");
    my($tmptextfile,$tmpcmdfile,$tmphtmlfile);

    for ($i=0;$i<@tmpparms;$i+=2)
    {
        $tmpparms[$i]=~tr/a-z/A-Z/; # Parameters are upper case
    }

    my(%Mail) = @tmpparms;

    if ( $Mail{ADDRESS} eq '')
    {
        warn("No mail address specified!  \n") ;
        return (0);
    }


    #------------------------------------------------------------------------
    #  Initialize any undefined arguments
    #------------------------------------------------------------------------

    $Mail{SUBJECT}        = ""  if (not $Mail{SUBJECT});
    $Mail{MESSAGE}        = ""  if (not $Mail{MESSAGE});
    $Mail{FROM}           = ""  if (not $Mail{FROM});
    $Mail{CC}             = ""  if (not $Mail{CC});
    $Mail{HTML}           = ""  if (not $Mail{HTML});
    $Mail{ATTACHMENTS}    = ""  if (not $Mail{ATTACHMENTS});
    $Mail{SMTPSERVER}     = ""  if (not $Mail{SMTPSERVER});


    #------------------------------------------------------------------------
    # Get Type for attachment
    #------------------------------------------------------------------------

    my %ending_map  =
    (
        crt         => ['application/x-x509-ca-cert' , 'base64'],
        aiff        => ['audio/x-aiff' , 'base64'],
        gif         => ['image/gif' , 'base64'],
        txt         => ['text/plain' , '8bit'],
        com         => ['text/plain' , '8bit'],
        class       => ['application/octet-stream' , 'base64'],
        htm         => ['text/html' , '8bit'],
        html        => ['text/html' , '8bit'],
        htmlx       => ['text/html' , '8bit'],
        htx         => ['text/html' , '8bit'],
        jpg         => ['image/jpeg' , 'base64'],
        dat         => ['text/plain' , '8bit'],
        hlp         => ['text/plain' , '8bit'],
        ps          => ['application/postscript' , '8bit'],
        'ps-z'      => ['application/postscript' , 'base64'],
        dvi         => ['application/x-dvi' , 'base64'],
        pdf         => ['application/pdf' , 'base64'],
        mcd         => ['application/mathcad' , 'base64'],
        mpeg        => ['video/mpeg' , 'base64'],
        mov         => ['video/quicktime' , 'base64'],
        exe         => ['application/octet-stream' , 'base64'],
        zip         => ['application/zip' , 'base64'],
        bck         => ['application/VMSBACKUP' , 'base64'],
        au          => ['audio/basic' , 'base64'],
        mid         => ['audio/midi' , 'base64'],
        midi        => ['audio/midi' , 'base64'],
        bleep       => ['application/bleeper' , '8bit'],
        wav         => ['audio/x-wav' , 'base64'],
        xmb         => ['audio/x-xbm' , '7bit'],
        tar         => ['application/tar' , 'base64'],
        imagemap    => ['application/imagemap' , '8bit'],
        sit         => ['application/x-stuffit' , 'base64'],
        bin         => ['application/x-macbase64'],
        hqx         => ['application/mac-binhex40' , 'base64']
    );


    #------------------------------------------------------------------------
    #
    # Build the mail
    #
    #------------------------------------------------------------------------

    # The MIME object
    my $mime;

    # Slurp in the message text and build up the main part of the mail
    {
        $mime = new MIME::Lite(
            From        => $Mail{FROM},
            To          => $Mail{ADDRESS},
            Cc          => $Mail{CC},
            Subject     => $Mail{SUBJECT},
            Priority    => $Mail{PRIORITY},
            Type        => 'multipart/mixed');
    }


    #------------------------------------------------------------------------
    #
    # Attach Message
    # HTML specified, must attach the message (data) separately (away from header)
    #
    #------------------------------------------------------------------------

    # HTML exists, attach the HTML first (order matters in Outlook) and then the message
    if ($Mail{HTML})
    {
        attach $mime
        Encoding    => '8bit',
        Type        => 'text/html',
        Data        => $Mail{HTML};
    }

    attach $mime
    Encoding    => '7bit',
    Type        => 'text/plain',
    Data        => $Mail{MESSAGE};


    #------------------------------------------------------------------------
    #
    # Add the Priority/X-Priority
    # X-Priority is the key
    # High X-Priority = "1" or "2"
    # Low X-Priority = "4" or "5"
    # Normal X-Priority = Any other number  ("3")
    #
    #------------------------------------------------------------------------

    if ( uc($Mail{PRIORITY}) eq 'URGENT')
    {
        $mime->add("X-Priority" => "1");
        $mime->add("Priority" => "URGENT");
    }
    elsif ( uc($Mail{PRIORITY}) eq 'LOW' )
    {
        $mime->add("X-Priority" => "4");
    }
    else
    {
        $mime->add("X-Priority" => "3");
        $mime->add("Priority" => "NORMAL");
    }


    #------------------------------------------------------------------------
    #
    # If Running on Windows and attachments then add them but with a full path.
    # If Running on Unix and attachments then add them.
    #
    #------------------------------------------------------------------------

    my($attachment);
    chomp($Mail{ATTACHMENTS});
    if ($Mail{ATTACHMENTS} ne '')
    {
        foreach $attachment (split(/,/,$Mail{ATTACHMENTS}))
        {
            my($type, $ending);
            $attachment =~ /.*\.(.+)$/;             # snag the ending
            $ending = $1;

            if (exists($ending_map{$ending}))       # Is it in our list?
            {
                $type = $ending_map{$ending};
            }
            else
            {
                $type = ['text/plain', '8bit'];     # default
            }

            # attach attachment with media type and encoding from the list
            # Note:  Windows requires full path
            attach $mime
                Type        => $type->[0],
                Encoding    => $type->[1],
                Path        => $attachment;
        }
    }


    #------------------------------------------------------------------------
    #
    # Send the mail message
    #
    #------------------------------------------------------------------------

    # Tell MIME::Lite to use Net::SMTP instead of sendmail (for UNIX)
        # Get Server list
        my ($server);
        my (@smtp_array);
        chomp($Mail{SMTPSERVER});

        # Grab server(s) and stick in an array
        if ($Mail{SMTPSERVER})
        {
            @smtp_array = (split(/,/,$Mail{SMTPSERVER}));
            foreach $server (@smtp_array)
            {
                if ( MIME::Lite->send('smtp', $server, Timeout => 20) )
                {
                    last;
                }
                else
                {
                    $failure = 1;
                }
            }
            if ( $failure )
            {
                die "Could not send mail message to \n '$Mail{SMTPSERVER}' \n";
            }

        }

    # Send mail
    $mime->send || die "you do not have mail!";
}
1;

__END__

=head1 NAME


Batch::Batchrun::Mail - send mail message for Batchrun


=head1 SYNOPSIS


use Batch::Batchrun::Mail;

mail( ADDRESS=>'test@somewhere.net',
     SUBJECT=>'Mail test',
     MESSAGE=>$somemsg,
     PRIORITY=>Urgent,
     FROM=>'user@host',
     CC=>'ccuser@host',
     SMTPSERVER=>'mailhost.net',
     ATTACHMENTS=>'d:\temp\attachment.text',
     HTML=>'htmltextmsg' );

=head1 DESCRIPTION

The C<mail> function provides a convenient way to send a mail message. Arguments are
passed using named parameters.  Each name is case insensitive. Of the several parameters
only ADDRESS is required.

This module uses MIME::LITE.  On unix systems the default is to use Sendmail to send the
message.  On Windows NT, Net::SMTP gets called by MIME::Lite. As of version 1.135 of
MIME::Lite there is a bug that does which causes CC addresses to be ignored when sending
messages via SMTP.  The author is aware of this and this will hopefully be fixed it in a
future release.

=head2 REQUIRED PARAMETERS

=over 4

=item B<ADDRESS>

the mail address of the person to send the message


=back

=head2 OPTIONAL PARAMETERS

=over 4

=item B<SUBJECT>

the subject of the mail message

=item B<MESSAGE>

the body of the mail message (text)

=item B<PRIORITY>

priority to send the message (Urgent or Normal or Low )

=item B<FROM>

the mail address of the user that is sending the message

=item B<CC>

one or more mail addresses of the users to send a copy of the message

=item B<HTML>

an html version of the mail message

=item B<SMTPSERVER>

a comma delimited list of servers to use for SMTP

=item B<ATTACHMENTS>

a comma delimited list of file attachments.

=back
B<NOTE:> C<mail> returns 1 or 0 to determine completion status.

=head1 TESTED PLATFORMS

=over 4

=item Solaris 2.5.1, 2.6

=item WinNT 4.0

=back

=head1 AUTHOR

=over 4

=item Daryl Anderson <F<batchrun@pnl.gov>>

=back

=head1 REVISION

Current $VERSION is 1.03.

=cut
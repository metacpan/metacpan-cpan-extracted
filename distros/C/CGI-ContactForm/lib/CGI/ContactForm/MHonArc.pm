package CGI::ContactForm::MHonArc;

$VERSION = '1.02';
# $Id: MHonArc.pm,v 1.7 2006/12/07 00:39:31 gunnarh Exp $

=head1 NAME

CGI::ContactForm::MHonArc - Contact the message authors in a MHonArc archive

=head1 SYNOPSIS

    use CGI::ContactForm;
    use CGI::ContactForm::MHonArc;

    my $msg = getmsgvalues();

    contactform (
        recname         => $msg->{fromname},
        recmail         => $msg->{fromaddr},
        styleurl        => '/style/ContactForm.css',
        returnlinktext  => 'Messages by Date',
        returnlinkurl   => '/archive/maillist.html',
        subject         => $msg->{subject},
        bouncetosender  => 1,
    );

=head1 DESCRIPTION

This module makes it easy to use L<CGI::ContactForm|CGI::ContactForm> for
contacting the message authors in a mail archive that was created by the
L<MHonArc|mhonarc> Email-to-HTML converter. Out from the message ID and the path
to the archive, it retrieves the necessary data from the archive database.

The converted messages are supposed to include an HTML form for the purpose, so
you need to set one of the MHonArc page layout resources. This is an example:

    <form action="/cgi-bin/mhacontact.pl" method="get">
    <input type="hidden" name="msgid" value="$MSGID$">
    <input type="hidden" name="outdir" value="$OUTDIR$">
    <input type="submit" value="Contact Author">
    </form>

The form controls shall be named C<msgid> and C<outdir> (case matters), and their
values are set dynamically via the MHonArc C<$MSGID$> respective C<$OUTDIR$>
resource variables when the messages are converted.

Note that it is a C<GET> request that shall be submitted.

The C<SYNOPSIS> section above is an example of what the CGI script, here named
C<mhacontact.pl>, may contain. The C<getmsgvalues()> function returns a reference
to a hash with the keys C<fromname>, C<fromaddr> and C<subject>, and the hash
values are passed to L<CGI::ContactForm|CGI::ContactForm> when the
C<contactform()> function is called.

If the name of the archive database is not the default name, you need to pass
the database name to C<CGI::ContactForm::MHonArc>:

    my $msg = getmsgvalues('myfilename');
    my $msg = getmsgvalues('/absolute/path/to/myfilename');

If you pass the absolute pathname, the C<outdir> control can be excluded from
the HTML form.

The C<Return-Path> message header controls where bounced messages are sent.
By default, L<CGI::ContactForm|CGI::ContactForm> sets the C<Return-Path> to
the recipient address. However, when sending messages to archived addresses,
there is an obvious risk that they are no longer valid, and it makes more sense
that possible bounces are sent to the sender address instead. That is
accomplished by passing a true value to C<contactform()> with the
C<bouncetosender> argument (see the C<SYNOPSIS> example).

=head1 AUTHOR, COPYRIGHT AND LICENSE

  Copyright (c) 2004-2006 Gunnar Hjalmarsson
  http://www.gunnar.cc/cgi-bin/contact.pl

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::ContactForm|CGI::ContactForm>, L<MHonArc|mhonarc>

=cut

use strict;
use CGI::ContactForm 1.40 'CFdie';
use vars qw($VERSION @ISA @EXPORT %MsgId %From %Subject);
use Exporter;
@ISA = 'Exporter';
@EXPORT = 'getmsgvalues';

sub getmsgvalues {
    local $^W = 1;
    my %msg;

    if ($ENV{REQUEST_METHOD} eq 'GET') {
        my $q = new CGI;
        my $id = $q->param('msgid') or CFdie("Message ID is missing.\n");
        my %nodot;
        @nodot{ qw/MSWin32 dos os2 VMS/ } = ();
        my $defaultdb = exists $nodot{$^O} ? 'mhonarc.db' : '.mhonarc.db';
        my $dbfile = (shift or $defaultdb);
        unless ( File::Spec->file_name_is_absolute($dbfile) ) {
            my $outdir = $q->param('outdir')
              or CFdie("Path to the archive directory is missing.\n");
            $outdir = $1 if $outdir =~ /^([-+@\w.\/\\: \[\]]+)$/;
            $dbfile = File::Spec->catfile($outdir, $dbfile);
        }

        eval { require $dbfile };
        CFdie( CGI::escapeHTML(my $msg = $@) ) if $@;

        my $from = $From{ $MsgId{$id} }
          or CFdie("Message ID \"$id\" not found in database.\n");
        if ( $from =~ /("?)(.+)\1 <([^>]+)>/ ) {
            @msg{ qw/fromname fromaddr/ } = ($2, $3);
        } else {
            ( $msg{fromname} ) = $from =~ /(.+)@/;
            $msg{fromaddr} = $from;
        }
        ( $msg{subject} = $Subject{ $MsgId{$id} } ) =~ s/^Re:\s+//i;
        $msg{subject} = "Re: $msg{subject}" if $msg{subject};

        print 'Set-cookie: M2H=', ( join ':',
          map { (my $elem = $_) =~ s/([^-\w.!~*'()])/sprintf '%%%02X', ord $1/eg; $elem }
          @msg{ qw/fromname fromaddr subject/ } ), "\n";

    } else {
        $ENV{HTTP_COOKIE} && ( (my $cookie) = $ENV{HTTP_COOKIE} =~ /\bM2H=([^;]+)/ )
          or CFdie("Your browser is set to refuse cookies.<br>\n"
         ."Change that setting to accept at least session cookies, and try again.\n");
        @msg{ qw/fromname fromaddr subject/ } =
          map { s/%(..)/chr(hex $1)/eg; $_ } split /:/, $cookie;
    }

    \%msg;
}

1;


package CGI::ContactForm;

$VERSION = '1.50';
# $Id: ContactForm.pm,v 1.76 2009/03/03 22:46:53 gunnarh Exp $

=head1 NAME

CGI::ContactForm - Generate a web contact form

=head1 SYNOPSIS

    use CGI::ContactForm;

    contactform (
        recname         => 'John Smith',
        recmail         => 'john.smith@example.com',
        styleurl        => '/style/ContactForm.css',
    );

=head1 DESCRIPTION

This module generates a contact form for the web when the routine C<contactform()>
is called from a CGI script. Arguments are passed to the module as a list of
key/value pairs.

C<CGI::ContactForm> sends a well formated (plain text format=flowed in accordance
with RFC 2646) email message, with the sender's address in the C<From:> header.

By default the sender gets a C<bcc> copy. If the email address stated by the
sender is invalid, by default the failure message is sent to the recipient address,
through which you know that you don't need to bother with a reply, at least not to
that address...  However, by setting the C<nocopy> argument you can prevent the
sender copy from being sent.

=head2 Arguments

C<CGI::ContactForm> takes the following arguments:

                        Default value
                        =============
    Compulsory
    ----------
    recname             (none)
    recmail             (none)

    Optional
    --------
    smtp                'localhost'
    styleurl            (none)
    returnlinktext      'Main Page'
    returnlinkurl       '/'
    subject             (none)
    nocopy              0
    bouncetosender      0
    formtmplpath        (none)
    resulttmplpath      (none)
    maxsize             100 (KiB)
    maxperhour          5 (messages per hour per host)
    tempdir             (none)
    spamfilter          '(?is:</a>|\[/url]|https?:/(?:.+https?:/){3})' (Perl regex)

    Additional arguments, intended for forms at non-English sites
    -------------------------------------------------------------
    title               'Send email to'
    namelabel           'Your name:'
    emaillabel          'Your email:'
    subjectlabel        'Subject:'
    msglabel            'Message:'
    reset               'Reset'
    send                'Send'
    erroralert          'Fields with %s need to be filled or corrected.'
    marked              'marked labels'
    thanks              'Thanks for your message!'
    sent_to             'The message was sent to %s with a copy to %s.'
    sent_to_short       'The message was sent to %s.'
    encoding            'ISO-8859-1'

=head2 Customization

There are only two compulsory arguments. The example CGI script
C<contact.pl>, that is included in the distribution, also uses the C<styleurl>
argument, assuming the use of the enclosed style sheet C<ContactForm.css>.
That results in a decently styled form with a minimum of effort.

If the default value C<localhost> isn't sufficient to identify the local SMTP
server, you may need to explicitly state its host name or IP address via the
C<smtp> argument.

As you can see from the list over available arguments, all the text strings
can be changed, and as regards the presentation, you can of course edit the
style sheet to your liking.

If you want to modify the HTML markup, you can have C<CGI::ContactForm> make
use of one or two templates. The enclosed example templates
C<ContactForm_form.tmpl> and C<ContactForm_result.tmpl> can be activated via
the C<formtmplpath> respective C<resulttmplpath> arguments, and used as a
starting point for a customized markup.

=head2 Spam prevention

Behind the scenes C<CGI::ContactForm> performs a few checks aiming to complicate
and/or discourage abuse in the form of submitted spam messages.

=over 4

=item *

The number of messages that can be sent from the same host is restricted. The
default is 5 messages per hour.

=item *

A customizable spamfilter is applied to the body of the message. By default it
allows max 3 URLs that start with C<http://> or C<https://>, and it rejects
submissions with C<E<lt>/aE<gt>> or C<[/url]> in the message body.

=item *

When sending a message, the request must include a cookie.

=back

The thought is that normal use, i.e. establishing contact with somebody,
should typically not be affected by those checks.

=head1 INSTALLATION

=head2 Installation with Makefile.PL

Type the following:

    perl Makefile.PL
    make
    make install

=head2 Manual Installation

=over 4

=item *

Download the distribution file and extract the contents.

=item *

Designate a directory as your local library for Perl modules, for instance

    /www/username/cgi-bin/lib

=item *

Create the directory C</www/username/cgi-bin/lib/CGI>, and upload
C<ContactForm.pm> to that directory.

=item *

Create the directory C</www/username/cgi-bin/lib/CGI/ContactForm>, and
upload C<MHonArc.pm> to that directory.

=item *

In the CGI scripts that use this module, include a line that tells Perl
to look for modules also in your local library, such as

    use lib '/www/username/cgi-bin/lib';

=back

=head2 Other Installation Matters

If you have previous experience from installing CGI scripts, making
C<contact.pl> (or whichever name you choose) work should be easy.
Otherwise, this is a B<very> short lesson:

=over 4

=item 1.

Upload the CGI file in ASCII transfer mode to your C<cgi-bin>.

=item 2.

Set the file permission 755 (chmod 755).

=back

If that doesn't do it, there are many CGI tutorials for beginners
available on the web. This is one example:

    http://my.execpc.com/~keithp/bdlogcgi.htm

On some servers, the CGI file must be located in the C<cgi-bin> directory
(or in a C<cgi-bin> subdirectory). At the same time it's worth noting,
that the style sheet typically needs to be located somewhere outside the
C<cgi-bin>.

=head1 DEPENDENCY

C<CGI::ContactForm> requires the non-standard module
L<Mail::Sender|Mail::Sender>. If C<Mail::Sender> needs to be installed
manually, you shall create C</www/username/cgi-bin/lib/Mail> and upload
C<Sender.pm> to that directory.

=head1 AUTHENTICATION

If you have access to a mail server that is configured to automatically
accept sending messages from a CGI script to any address, you don't need
to worry about authentication. Otherwise you need to somehow authenticate
to the server, for instance by adding something like this right after the
C<use CGI::ContactForm;> line in C<contact.pl>:

    %Mail::Sender::default = (
        auth      => 'LOGIN',
        authid    => 'username',
        authpwd   => 'password',
    );

C<auth> is the SMTP authentication protocol. Common protocols are C<LOGIN>
and C<PLAIN>. You may need help from the mail server's administrator to
find out which protocol and username/password pair to use.

If there are multiple forms, a more convenient way to deal with a need
for authentication may be to make use of the C<Sender.config> file that
is included in the distribution. You just edit it and upload it to the
same directory as the one where C<Sender.pm> is located.

See the L<Mail::Sender|Mail::Sender> documentation for further guidance.

=head1 AUTHOR, COPYRIGHT AND LICENSE

  Copyright (c) 2003-2009 Gunnar Hjalmarsson
  http://www.gunnar.cc/cgi-bin/contact.pl

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::ContactForm::MHonArc|CGI::ContactForm::MHonArc>,
L<Mail::Sender|Mail::Sender>

=cut

use strict;
use CGI 'escapeHTML';
use File::Basename;
use File::Spec;
use Fcntl qw(:DEFAULT :flock);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Exporter;
@ISA = 'Exporter';
@EXPORT = 'contactform';
@EXPORT_OK = 'CFdie';

BEGIN {
    sub CFdie($) {
        print "Status: 400 Bad Request\n";
        print "Content-type: text/html\n\n<h1>Error</h1>\n<tt>", shift;
        if ( $ENV{MOD_PERL} ) {
            if ( $] < 5.006 ) {
                require Apache;
                Apache::exit();
            }
        }
        exit 1;
    }

    eval "use Mail::Sender";
    CFdie($@) if $@;
}

sub contactform {
    local $^W = 1;  # enables warnings
    my ($error, $in) = {};
    my $time = time;
    my $host = $ENV{'REMOTE_ADDR'} or die "REMOTE_ADDR not set\n";
    umask 0;
    my $args = &arguments;
    if ($ENV{REQUEST_METHOD} eq 'POST') {
        checktimestamp( $args->{tempdir}, $time );
        $in = formdata( $args->{maxsize} );
        if (formcheck($in, $args->{subject}, $error) == 0) {
            checkspamfilter( $in->{message}, $args->{spamfilter} );
            checkmaxperhour($args, $time, $host);
            eval { mailsend($args, $in, $host) };
            CFdie( escapeHTML(my $msg = $@) ) if $@;
            return;
        }
    } else {
        settimestamp( $args->{tempdir}, $time );
    }
    formprint($args, $in, $error);
}

sub arguments {
    my %defaults = (
        recname        => '',
        recmail        => '',
        smtp           => 'localhost',
        styleurl       => '',
        returnlinktext => 'Main Page',
        returnlinkurl  => '/',
        subject        => '',
        nocopy         => 0,
        bouncetosender => 0,
        formtmplpath   => '',
        resulttmplpath => '',
        maxsize        => 100,
        maxperhour     => 5,
        tempdir        => '',
        spamfilter     => '(?is:</a>|\[/url]|https?:/(?:.+https?:/){3})',
        title          => 'Send email to',
        namelabel      => 'Your name:',
        emaillabel     => 'Your email:',
        subjectlabel   => 'Subject:',
        msglabel       => 'Message:',
        reset          => 'Reset',
        send           => 'Send',
        erroralert     => 'Fields with %s need to be filled or corrected.',
        marked         => 'marked labels',
        thanks         => 'Thanks for your message!',
        sent_to        => 'The message was sent to %s with a copy to %s.',
        sent_to_short  => 'The message was sent to %s.',
        encoding       => 'ISO-8859-1',
    );
    my $error;
    if ( @_ % 2 ) {
        $error .= "Odd number of elements in argument list:\n"
         . "  The contactform() function expects a number of key/value pairs.\n";
    }
    my %args = ( %defaults, @_ );
    for (qw/recname recmail/) {
        $error .= "The compulsory argument '$_' is missing.\n" unless $args{$_};
    }
    for (keys %args) {
        $error .= "Unknown argument: '$_'\n" unless defined $defaults{$_};
    }
    if ($args{recmail} and emailsyntax($args{recmail})) {
        $error .= "'$args{recmail}' is not a valid email address.\n";
    }
    unless ($args{tempdir}) {
        unless (-d $CGITempFile::TMPDIRECTORY and -w _ and -x _) {
            $error .= "You need to state a temporary directory via the 'tempdir' argument.\n";
        }
    } elsif (!(-d $args{tempdir} and -w _ and -x _)) {
        $error .= "'$args{tempdir}' is not a writable directory.\n";
    }
    for ('formtmplpath', 'resulttmplpath') {
        if ($args{$_} and !-f $args{$_}) {
            $error .= "Argument '$_': Can't find the file $args{$_}\n";
        }
    }
    {
        local $SIG{__WARN__} = sub { die $_[0] };
        eval { $args{spamfilter} = qr($args{spamfilter}) };
        if ( $@ ) {
            my $mod_path = $INC{'CGI/ContactForm.pm'};
            $@ =~ s/ at $mod_path.+//;
            $error .= "Argument 'spamfilter': " . escapeHTML(my $err = $@);
        }
    }

    CFdie("<pre>$error" . <<'EXAMPLE'

Example:

    contactform (
        recname => 'John Smith',
        recmail => 'john.smith@example.com',
    );
EXAMPLE

    ) if $error;

    \%args;
}

sub formdata {
    my $max = shift;
    if ($ENV{CONTENT_LENGTH} > 1024 * $max) {
        CFdie("The message size exceeds the $max KiB limit.\n"
              . '<p><a href="javascript:history.back(1)">Back</a>');
    }

    # create hash reference to the form data
    my $in = new CGI->Vars;

    # trim whitespace in message headers
    for (qw/name email subject/) {
        $in->{$_} =~ s/^\s+//;
        $in->{$_} =~ s/\s+$//;
        $in->{$_} =~ s/\s+/ /g;
    }

    $in;
}

sub formcheck {
    my ($in, $defaultsubject, $error) = @_;
    for (qw/name message/) { $error->{$_} = ' class="error"' unless $in->{$_} }
    $error->{subject} = ' class="error"' unless $in->{subject} or $defaultsubject;
    $error->{email} = ' class="error"' if emailsyntax( $in->{email} );
    %$error ? 1 : 0;
}

sub emailsyntax {
    return 1 unless my ($localpart, $domain) = shift =~ /^(.+)@(.+)/;
    my $atom = '[^[:cntrl:] "(),.:;<>@\[\\\\\]]+';
    my $qstring = '"(?:\\\\.|[^"\\\\\s]|[ \t])*"';
    my $word = qr($atom|$qstring);
    return 1 unless $localpart =~ /^$word(?:\.$word)*$/;
    $domain =~ /^$atom(?:\.$atom)+$/ ? 0 : 1;
}

sub mailsend {
    my ($args, $in, $host) = @_;

    # Extra headers
    my @extras = "X-Originating-IP: [$host]";
    if ( my $agent = $ENV{'HTTP_USER_AGENT'} ) {
        my @lines;
        while ( $agent =~ /(.{1,66})(?:\s+|$)/g ) {
            push @lines, $1;
        }
        push @extras, 'User-Agent: ' . join("\r\n\t", @lines);
    }
    push @extras, "Referer: $ENV{'HTTP_REFERER'}" if $ENV{'HTTP_REFERER'};
    push @extras, "X-Mailer: CGI::ContactForm $VERSION at $ENV{HTTP_HOST}";

    # Make message format=flowed (RFC 2646)
    eval "use Encode 2.23 ()";
    my $convert = $@ ? 0 : 1;
    $in->{message} = Encode::decode( $args->{encoding}, $in->{message} ) if $convert;
    $in->{message} = reformat( $in->{message}, { max_length => 66, opt_length => 66 } );
    $in->{message} = Encode::encode( $args->{encoding}, $in->{message} ) if $convert;
    push @extras, "Content-type: text/plain; charset=$args->{encoding}; format=flowed";

    # Send message
    $Mail::Sender::NO_X_MAILER = 1;
    $Mail::Sender::SITE_HEADERS = join "\r\n", @extras;
    ref (new Mail::Sender -> MailMsg( {
        smtp      => $args->{smtp},
        encoding  => ( $in->{message} =~ /[[:^ascii:]]/ ? 'quoted-printable' : '7bit' ),
        from      => ( $args->{bouncetosender} ? $in->{email} : $args->{recmail} ),
        fake_from => namefix( $in->{name}, $args->{encoding} ) . " <$in->{email}>",
        to        => namefix( $args->{recname}, $args->{encoding} ) . " <$args->{recmail}>",
        bcc       => ( $args->{nocopy} ? '' : $in->{email} ),
        subject   => mimeencode( $in->{subject}, $args->{encoding} ),
        msg       => $in->{message},
    } )) or die "Cannot send mail. $Mail::Sender::Error\n";

    # Print resulting page
    my @resultargs = qw/recname returnlinktext returnlinkurl title thanks/;
    $args->{$_} = escapeHTML( $args->{$_} ) for @resultargs;
    my $sent_to = sprintf escapeHTML( $args->{nocopy} ? $args->{sent_to_short} : $args->{sent_to} ),
      "<b>$args->{recname}</b>", '<b>' . escapeHTML( $in->{email} ) . '</b>';
    $args->{returnlinkurl} =~ s/ /%20/g;
    if ( $args->{resulttmplpath} ) {
        my %result_vars;
        $result_vars{style} = stylesheet( $args->{styleurl} );
        $result_vars{sent_to} = \$sent_to;
        $result_vars{$_} = \$args->{$_} for @resultargs;
        templateprint($args->{resulttmplpath}, $args->{encoding}, %result_vars);
    } else {
        headprint($args);

        print <<RESULT;
<h1>$args->{thanks}</h1>
<p>$sent_to</p>
<p class="returnlink"><a href="$args->{returnlinkurl}">$args->{returnlinktext}</a></p>
</body>
</html>
RESULT
    }
}

sub formprint {
    my ($args, $in, $error) = @_;
    my $scriptname = basename( $0 or $ENV{SCRIPT_FILENAME} );
    my $erroralert = %$error ? '<p class="erroralert">'
      . sprintf( escapeHTML( $args->{erroralert} ), '<span class="error">'
      . "\n" . escapeHTML( $args->{marked} ) . '</span>' ) . '</p>' : '';
    my @formargs = qw/recname returnlinktext returnlinkurl title namelabel
                      emaillabel subjectlabel msglabel reset send/;
    $args->{$_} = escapeHTML( $args->{$_} ) for @formargs;
    $args->{returnlinkurl} =~ s/ /%20/g;
    $in->{subject} ||= $args->{subject};
    for (qw/name email subject message/) {
        $in->{$_} = $in->{$_} ? escapeHTML( $in->{$_} ) : '';
        $error->{$_} ||= '';
    }

    # Prevent horizontal scrolling in NS4
    my $softwrap = ($ENV{HTTP_USER_AGENT} and $ENV{HTTP_USER_AGENT} =~ /Mozilla\/[34]/
      and $ENV{HTTP_USER_AGENT} !~ /MSIE|Opera/) ? ' wrap="soft"' : '';

    if ( $args->{formtmplpath} ) {
        my %form_vars;
        $form_vars{style} = stylesheet( $args->{styleurl} );
        $form_vars{scriptname} = \$scriptname;
        $form_vars{erroralert} = \$erroralert;
        $form_vars{$_} = \$args->{$_} for @formargs;
        for (qw/name email subject message/) {
            $form_vars{$_} = \$in->{$_};
            $form_vars{$_.'error'} = \$error->{$_};
        }
        $form_vars{softwrap} = \$softwrap;
        templateprint($args->{formtmplpath}, $args->{encoding}, %form_vars);
    } else {
        headprint($args);

        print <<FORM;
<form action="$scriptname" method="post">
<table cellpadding="3">
<tr>
<td colspan="4"><h1 class="halign">$args->{title} $args->{recname}</h1></td>
</tr><tr>
<td><p$error->{name}>$args->{namelabel}</p></td><td><input type="text" name="name"
 value="$in->{name}" size="20" />&nbsp;</td>
<td><p$error->{email}>$args->{emaillabel}</p></td><td><input type="text" name="email"
 value="$in->{email}" size="20" /></td>
</tr><tr>
<td><p$error->{subject}>$args->{subjectlabel}</p></td>
<td colspan="3"><input type="text" name="subject" value="$in->{subject}" size="55" /></td>
</tr><tr>
<td colspan="4"><p$error->{message}>$args->{msglabel}</p></td>
</tr><tr>
<td colspan="4">
<textarea name="message" rows="8" cols="65"$softwrap>$in->{message}</textarea>
</td>
</tr><tr>
<td colspan="4" class="halign">
$erroralert
<input class="button" type="reset" value="$args->{reset}" />&nbsp;&nbsp;
<input class="button" type="submit" value="$args->{send}" /></td>
</tr><tr>
<td colspan="4"><p class="returnlink"><a href="$args->{returnlinkurl}">
$args->{returnlinktext}</a></p></td>
</tr>
</table>
</form>
</body>
</html>
FORM
    }
}

sub headprint {
    my $args = shift;
    print "Content-type: text/html; charset=$args->{encoding}\n\n";
    print <<HEAD;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
                      "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>$args->{title} $args->{recname}</title>
<style type="text/css">
.error { font-weight: bold }
</style>
${ stylesheet( $args->{styleurl} ) }
</head>
<body>
HEAD
}

sub stylesheet {
    my $url = shift || return \'';
    $url =~ s/ /%20/g;
    \('<link rel="stylesheet" type="text/css" href="' . $url . '" />');
}

sub templateprint {
    my ($template, $encode, %tmpl_vars) = @_;
    my $error;
    open FH, "< $template" or die "Can't open $template\n$!";
    my $output = do { local $/; <FH> };
    close FH;
    $output =~ s[<(?:!--\s*)?tmpl_var\s*(?:name\s*=\s*)?
                 (?:"([^">]*)"|'([^'>]*)'|([^\s=>]*))
                 \s*(?:--)?>][
        if ( $tmpl_vars{lc $+} ) {
            ${ $tmpl_vars{lc $+} };
        } else {
            $error .= "Unknown template variable: '$+'\n";
        }
    ]egix;
    CFdie("<pre>$error") if $error;
    print "Content-type: text/html; charset=$encode\n\n";
    print $output;
}

sub namefix {
    my $name = $_[0];
    if ($name =~ /[[:^ascii:]]/) {
        return &mimeencode;
    }
    if ($name =~ /[^ \w]/) {
        $name =~ tr/"/'/;
        $name = qq{"$name"};
    }
    $name;
}

sub mimeencode {
    my ($str, $enc) = @_;
    return $str unless $str =~ /[[:^ascii:]]/;
    my @parts;
    while ( $str =~ /(.{1,40}.*?(?:\s|$))/g ) {
        my $part = $1;
        push @parts, MIME::QuotedPrint::encode($part, '');
    }
    join "\r\n\t", map { "=?$enc?Q?$_?=" } @parts;
}

sub reformat {
# This subroutine was initially copied from Text::Flowed v0.14, written by
# Philip Mak. It has undergone a couple of changes since.

    # Help functions in Text::Flowed nested into this copy of reformat()
    sub _num_quotes { $_[0] =~ /^(>*)/; length $1 }
    sub _unquote { my $line = shift; $line =~ s/^(>+)//g; $line }
    sub _flowed {
        my $line = shift;
        # Lines with only spaces in them are not considered flowed
        # (heuristic to recover from sloppy user input)
        return 0 if $line =~ /^ *$/;
        $line =~ / $/;
    }
    sub _trim { local *_ = \shift; s/ +$//g; $_ }
    sub _stuff {
        my ($text, $num_quotes) = @_;
        if ($text =~ /^ / || $text =~ /^>/ || $text =~ /^From / || $num_quotes > 0) {
            return " $text";
        }
        $text;
    }
    sub _unstuff { local *_ = \shift; s/^ //; $_ }

    my @input = split "\n", $_[0];
    my $args = $_[1];
    $args->{max_length} ||= 79;
    $args->{opt_length} ||= 72;
    my @output = ();

    # Process message line by line
    while (@input) {
        # Count and strip quote levels
        my $line = shift @input;
        my $num_quotes = _num_quotes($line);
        $line = _unquote($line);

        # Should we interpret this line as flowed?
        if ( !$args->{fixed} || ( $args->{fixed} == 1 && $num_quotes ) ) {
            $line = _unstuff($line);
            # While line is flowed, and there is a next line, and the
            # next line has the same quote depth
            while (_flowed($line) && @input && _num_quotes($input[0]) == $num_quotes) {
                # Join the next line
                $line .= _unstuff(_unquote(shift @input));
            }
        }
        # Ensure line is fixed, since we joined all flowed lines
        $line = _trim($line);

        # Increment quote depth if we're quoting
        $num_quotes++ if $args->{quote};

        if ( !( defined $line and length $line ) ) {
            # Line is empty
            push @output, '>' x $num_quotes;
        } elsif (length($line) + $num_quotes <= $args->{max_length} - 1) {
            # Line does not require rewrapping
            push @output, '>' x $num_quotes . _stuff($line, $num_quotes);
        } else {
            # Rewrap this paragraph
            while ( defined $line and length $line ) {
                # Stuff and re-quote the line
                $line = '>' x $num_quotes . _stuff($line, $num_quotes);

                # Set variables used in regexps
                my $min = $num_quotes + 1;
                my $opt1 = $args->{opt_length} - 1;
                my $max1 = $args->{max_length} - 1;
                if ( length($line) <= $args->{opt_length} ) {
                    # Remaining section of line is short enough
                    push @output, $line;
                    last;
                } elsif ( $line =~ /^(.{$min,$opt1}) (.*)/ ||
                  $line =~ /^(.{$min,$max1}) (.*)/ || $line =~ /^(.{$min,}) (.*)/ ) {
                    # 1. Try to find a string as long as opt_length.
                    # 2. Try to find a string as long as max_length.
                    # 3. Take the first word.
                    push @output, "$1 ";
                    $line = $2;
                } else {
                    # One excessively long word left on line
                    push @output, $line;
                    last;
                }
            }
        }
    }

    join("\n", @output)."\n";
}

sub checktimestamp {
    my ($tempdir, $time) = @_;
    $tempdir ||= $CGITempFile::TMPDIRECTORY;
    my $cookie;
    unless ( $ENV{HTTP_COOKIE} and ($cookie) = $ENV{HTTP_COOKIE} =~ /\bContactForm_time=(\d+)/ ) {
        CFdie("Your browser is set to refuse cookies.<br>\n"
          . "Change that setting to accept at least session cookies, and try again.\n");
    }
    open FH, File::Spec->catfile( $tempdir, 'ContactForm_time' )
      or die "Couldn't open timestamp file: $!";
    chomp( my @timestamps = <FH> );
    close FH or die $!;
    if ( $cookie + 7200 < $time or ! grep $cookie eq $_, @timestamps ) {
        settimestamp($tempdir, $time);
        CFdie("Timeout due to more than an hour of inactivity.\n"
          . '<p><a href="javascript:history.back(1)">Go back one page</a> and try again.');
    }
}

sub settimestamp {
    my ($tempdir, $time) = @_;
    $tempdir ||= $CGITempFile::TMPDIRECTORY;

    sysopen FH, File::Spec->catfile( $tempdir, 'ContactForm_time' ), O_RDWR|O_CREAT
      or die "Couldn't open timestamp file: $!";
    flock FH, LOCK_EX or die $!;
    chomp( my @timestamps = <FH> );
    sysseek FH, 0, 0 or die $!;
    if ( @timestamps == 2 && $time > $timestamps[0] + 3600 or @timestamps == 1 ) {
        truncate FH, 0 or die $!;
        print FH join( "\n", $time, $timestamps[0] ), "\n";
        print "Set-cookie: ContactForm_time=$time\n";
    } elsif ( @timestamps == 0 ) {
        truncate FH, 0 or die $!;
        print FH "$time\n";
        print "Set-cookie: ContactForm_time=$time\n";
    } else {
        print "Set-cookie: ContactForm_time=$timestamps[0]\n";
    }
    close FH or die $!;
}

sub checkspamfilter {
    my ($msg, $filter) = @_;
    if ( $filter and $msg =~ /$filter/ ) {
        CFdie("The message was trapped in a spam filter and not sent.\n"
          . "You may want to try again with a modified message body.\n"
          . '<p><a href="javascript:history.back(1)">Back</a>');
    }
}

sub checkmaxperhour {
    my ($args, $time, $host) = @_;
    my $tempdir = $args->{tempdir} || $CGITempFile::TMPDIRECTORY;
    my (@senders, %senders);

    sysopen FH, File::Spec->catfile( $tempdir, 'ContactForm_sent' ), O_RDWR|O_CREAT
      or die "Couldn't open request file: $!";
    flock FH, LOCK_EX or die $!;
    while ( <FH> ) {
        my ($timestamp, $ip) = /^(\d+)\t(.+)/;
        next if $timestamp < $time - 3600;
        push @senders, $_;
        $senders{$ip}++;
    }
    push @senders, "$time\t$host\n";
    $senders{$host}++;
    seek FH, 0, 0 or die $!;
    truncate FH, 0 or die $!;
    print FH @senders;
    close FH or die $!;

    if ( $senders{$host} > $args->{maxperhour} ) {
        CFdie('Too many send attempts from the same host. You may want to try later.');
    }
}

1;


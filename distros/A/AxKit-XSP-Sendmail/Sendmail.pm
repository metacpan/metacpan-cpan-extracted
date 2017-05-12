# $Id: Sendmail.pm,v 1.15 2005/04/13 16:04:21 kjetil Exp $

package AxKit::XSP::Sendmail;
use strict;
use Apache::AxKit::Language::XSP;
use Mail::Sendmail;
use Email::Valid;
use Carp;
use Apache::AxKit::CharsetConv;

use vars qw/@ISA $NS $VERSION $ForwardXSPExpr $TRIM_FIELD/;

@ISA = ('Apache::AxKit::Language::XSP');
$NS = 'http://axkit.org/NS/xsp/sendmail/v1';

$VERSION = "1.5";

## Taglib subs

# send mail
sub send_mail {
    my ($document, $parent, $mailer_args) = @_;
    my $address_errors;

    foreach my $addr_type ('To', 'Cc', 'Bcc') {
        if ($mailer_args->{$addr_type}) {
            foreach my $addr (@{$mailer_args->{$addr_type}}) {
                next if Email::Valid->address($addr);
                $address_errors .=  "Address $addr in '$addr_type' element failed $Email::Valid::Details check. ";
            }
            $mailer_args->{$addr_type}  = join (', ', @{$mailer_args->{$addr_type}});
        }
    }

    # we want a bad "from" header to be caught as a user error so we'll trap it here.
    $mailer_args->{From} ||= $Mail::Sendmail::mailcfg{from};

    unless ( Email::Valid->address($mailer_args->{From}) ) { 
        $address_errors .= "Address '$mailer_args->{From}' in 'From' element failed $Email::Valid::Details check. ";
    }

    # set the content-type
    $mailer_args->{'Content-Type'} = ($mailer_args->{'Content-Type'})? $mailer_args->{'Content-Type'} : 'text/plain';
    $mailer_args->{'Content-Type'} .= '; charset=';
    $mailer_args->{'Content-Type'} .= ($mailer_args->{'charset'})?      $mailer_args->{'charset'} : 'utf-8';

    # munge the text if it needs to be
    if ($mailer_args->{'charset'} and lc($mailer_args->{'charset'}) ne 'utf-8') {
        my $conv = Apache::AxKit::CharsetConv->new('utf-8',$mailer_args->{'charset'})
                or croak "No such charset: $mailer_args->{'charset'}";
        $mailer_args->{'message'} = $conv->convert($mailer_args->{'message'});
    }


    if ($address_errors) {
        croak "Invalid Email Address(es): $address_errors";
    }

    # all addresses okay? if so, send.
    
    sendmail( %{$mailer_args} ) || croak $Mail::Sendmail::error;
}

## Parser subs
        
sub parse_start {
    my ($e, $tag, %attribs) = @_; 
    #warn "Checking: $tag\n";
    
    # check for trimming
    $TRIM_FIELD = ($attribs{trim} eq 'no' ? 0 : 1);

    if ($tag eq 'send-mail') {
        return qq| {# start mail code\n | .
                q| my (%mail_args, @to_addrs, @cc_addrs, @bcc_addrs);| . qq|\n|;
    }
    elsif ($tag eq 'to') {
        return q| push (@to_addrs, ''|;
    }
    elsif ($tag eq 'cc') {
        return q| push (@cc_addrs, ''|;
    }
    elsif ($tag eq 'bcc') {
        return q| push (@bcc_addrs, ''|;
    }
    elsif ($tag eq 'content-type') {
        return q| $mail_args{'Content-Type'} = ''|;
    }
    elsif ($tag eq 'content-transfer-encoding') {
        return q| $mail_args{'Content-Transfer-Encoding'} = ''|;
    }
    elsif ($tag eq 'charset') {
        return q| $mail_args{'charset'} = ''|;
    }
    elsif ($tag =~ /^(subject|message|from|body)$/) {
        $tag = "From" if $tag eq 'from';
        $tag = "message" if $tag eq 'body';
        return qq| \$mail_args{'$tag'} = "" |;
    }
    elsif ($tag eq 'smtphost') {
        return q| $mail_args{'smtp'} = "" |;
    }
    elsif ($tag eq 'header') {
        return qq| \$mail_args{'$attribs{name}'} = ''|;
    }
    else {
        die "Unknown sendmail tag: $tag";
    }
}

sub parse_char {
    my ($e, $text) = @_;
    my $element_name = $e->current_element();


    if ($element_name ne 'body' and $TRIM_FIELD) {
	$text =~ s/^\s*//;
	$text =~ s/\s*$//;
    }

    return '' unless $text;

    $text =~ s/\|/\\\|/g;
    $text =~ s/\\$/\\\\/gsm;
    return " . q|$text| ";
}


sub parse_end {
    my ($e, $tag) = @_;

    $TRIM_FIELD = 1;
    
    if ($tag eq 'send-mail') {
        return <<'EOF';
AxKit::XSP::Sendmail::send_mail(
    $document, $parent,
    {
        %mail_args,
        To => \@to_addrs, 
        Cc => \@cc_addrs, 
        Bcc => \@bcc_addrs,
    },
    );
} # end mail code
EOF
    }
    elsif ($tag =~ /to|bcc|cc/) {
        return ");\n";
    }
    return ";";
}

sub parse_comment {
    # compat only
}

sub parse_final {
   # compat only
}

1;
                
__END__

=head1 NAME

AxKit::XSP::Sendmail - Simple SMTP mailer tag library for AxKit eXtensible Server Pages.

=head1 SYNOPSIS

Add the sendmail: namespace to your XSP C<<xsp:page>> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:sendmail="http://axkit.org/NS/xsp/sendmail/v1"
    >

And add this taglib to AxKit (via httpd.conf or .htaccess):

    AxAddXSPTaglib AxKit::XSP::Sendmail

=head1 DESCRIPTION

The XSP sendmail: taglib adds a simple SMTP mailer to XSP via Milivoj
Ivkovic's platform-neutral Mail::Sendmail module. In addition, all
email addresses are validated before sending using Maurice Aubrey's
Email::Valid package. This taglib is identical to the Cocoon taglib
of the same name, albeit in a different namespace..

=head1 Tag Reference

=head2 C<E<lt>sendmail:send-mailE<gt>>

This is the required 'wrapper' element for the sendmail taglib branch.

=head2 C<E<lt>sendmail:smtphostE<gt>>

The this element sets the outgoing SMTP server for the current message.
If omitted, the default set in L<Mail::Sendmail>'s %mailcfg hash will be
used instead. 

=head2 C<E<lt>sendmail:fromE<gt>>

Defines the 'From' field in the outgoing message. If omitted, this
field defaults to value set in L<Mail::Sendmail>'s %mailcfg hash. Run
C<perldoc Mall:Sendmail> for more detail.

=head2 C<E<lt>sendmail:toE<gt>>

Defines a 'To' field in the outgoing message. Multiple instances are
allowed. By default this taglib will remove leading and trailing
spaces from the value C<E<lt>sendmail:toE<gt>> contains. If you need
to turn this off, simply set the C<trim> attribute to 'no'. The same
can be done for all header fields.

=head2 C<E<lt>sendmail:ccE<gt>>

Defines a 'Cc' field in the outgoing message. Multiple instances are
allowed.

=head2 C<E<lt>sendmail:bccE<gt>>

Defines a 'Bcc' field in the outgoing message. Multiple instances are
allowed.

=head2 C<E<lt>sendmail:subjectE<gt>>

Defines the subject of the message.

=head2 C<E<lt>sendmail:content-typeE<gt>>

Defines the content-type of the body of the message (default: text/plain).

=head2 C<E<lt>sendmail:content-transfer-encodingE<gt>>

Defines the content-transfer-encoding of the body of the message. The
default depends on whether you have MIME::QuotedPrint available or not.
If you do, it defaults to 'quoted-printable', and if you don't to '8bit';

=head2 C<E<lt>sendmail:charsetE<gt>>

Defines the charset of the body of the message (default: utf-8). Your
system's iconv implementation needs to support converting from utf-8
to that character set otherwise sending email will fail.

=head2 C<E<lt>sendmail:headerE<gt>>

Allows you to add headers to the outgoing mail with the name specified
in the C<name> attribute.

=head2 C<E<lt>sendmail:bodyE<gt>>

Defines the body of the outgoing message.

=head2 C<E<lt>sendmail:messageE<gt>>

This tag is interchangable with C<E<lt>sendmail:bodyE<gt>>.

=head1 EXAMPLE

  my $mail_message = 'I\'m a victim of circumstance!';

  <sendmail:send-mail>
    <sendmail:from>curly@localhost</sendmail:from>
    <sendmail:to>moe@spreadout.org</sendmail:to>
    <sendmail:cc>larry@porcupine.com</sendmail:cc>
    <sendmail:bcc>shemp@alsoran.net</sendmail:cc>
    <sendmail:body><xsp:expr>$mail_message</xsp:expr></sendmail:body>
  </sendmail:send-mail>

=head1 ERRORS

When sending email fails, or an address is invalid, this taglib will
throw an exception, which you can catch with the AxKit exceptions
taglib.

=head1 AUTHOR

Kip Hampton, khampton@totalcinema.com

Kjetil Kjernsmo, kjetilk@cpan.org has taken over maintainership of
this module as of 1.41.

=head1 COPYRIGHT

Copyright (c) 2001 Kip Hampton. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 SEE ALSO

L<AxKit>, L<Mail::Sendmail>, L<Email::Valid>

=cut

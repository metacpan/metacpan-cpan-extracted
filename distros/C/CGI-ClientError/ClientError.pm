package CGI::ClientError;
use vars qw($VERSION @EXPORT);
use Exporter;
@ISA=qw(Exporter);

@EXPORT=qw(cgi_report_error);

$VERSION=0.03;

=head1 NAME

  CGI::ClientError - send minimalistic error messages to the browser

=head1 SYNOPSIS

    use CGI::ClientError;
    &CGI::ClientError::setheaderfile('/path/to/some/header');
    &CGI::ClientError::setfooterfile('/path/to/some/footer');
    &CGI::ClientError::setheader("Content-Type: text/plain\n\nYou've done something wrong: ");
    &CGI::ClientError::setfooter("If this is unclear, go hang yourself.");

    &CGI::ClientError::sethandler(sub { die; });

    (...)

    if (clientisadork) { &CGI::ClientError::error("You are a dork!");
    # or
    if (clientisadork) { &cgi_report_error("You are a dork!");

=head1 DESCRIPTION

Errors might appear in a CGI.  If the script knows what is wrong, it
should tell what is wrong.  But I think it's important to separate
between when it should tell the client, and when it should tell the
webmaster.  The user/client shouldn't be get error messages that are
irrelevant or meaningless or even possibly exploitable - as "out of
disk", "out of memory", "core dumped", etc.  Instead, the script
should die, the error should be logged, and perhaps even sent by mail
to the webmaster - and perhaps even to his cellphone.  The user should
get an 500 and a clear, friendly message that the problem is at the
server side and probably will be dealt with ("try again later, or mail
webmaster").

Anyway, sometimes the client is to blame for the error.  He has typed
in a text string in a number box, he claims beeing born in 2019-14-14,
he has been typing in a long URL with illegal parameters, etc. Then
the client should get an informative error message.  That's what this
small module is for.

Three variables might be set by the caller program, header, footer and
handler. The header and footer is what to output before and after the
error message. The default header is:
  Content-Type: text/html
  E<lt>H1E<gt>ErrorE<lt>/h1E<gt>
  Here is an error message for you:E<lt>brE<gt>
  E<lt>iE<gt>

The default footer is:
  E<lt>/iE<gt>E<lt>brE<gt>
  If something is unclear, feel free to contact the
  webmaster.

The default handler is ... do nothing.

Somebody has probably written scientific papers about how to be
respectfully and pedagogic when telling a user that he has done an
error.  I think it is wise to be humble, don't expect too much -
remember, the average web user of today is not a typical unix user.  I
don't know.  I don't care.

This module probably stinks - but the idea itself doesn't; I think
it's proper to use "die" if it's a real server error, and some other
sub / method if it's actually a client error.

=head1 AUTHOR

Tobias Brox <tobix@irctos.org>

=cut

sub setheaderfile {
    $CGI::ClientError::headerfile=shift;
}

sub setfooterfile {
    $CGI::ClientError::footerfile=shift;
}

sub setheader {
    $CGI::ClientError::header=shift;
}

sub setfooter {
    $CGI::ClientError::footer=shift;
}

sub sethandler {
    $CGI::ClientError::handler=shift;
}

sub printfile {
    my $filename=shift;
    $filename || return 0;
    open(FILE, "<$filename") || return 0;
    while (<FILE>) {print;}
    close(FILE);
    return 1;
}

sub cgi_report_error {
    error(@_);
}

sub error {
    &printfile($CGI::ClientError::headerfile) or
	print $CGI::ClientError::header;

    # In case we're called as a class method:
    if (ref $_[0] || $_[0] =~ /^((\w+)\:\:(\w+))$/) { shift; }

    print shift;

    &printfile($CGI::ClientError::footerfile) or 
	print $CGI::ClientError::footer;

    defined $CGI::handler && &$CGI::Handler;
}

$CGI::ClientError::header="Content-Type: text/html

                    <H1>Error</h1>
     		    Here is an error message for you:<br>
		    <i>";

$CGI::ClientError::footer="</i><br>
                    If something is unclear, feel free to contact the
                    webmaster.\n";








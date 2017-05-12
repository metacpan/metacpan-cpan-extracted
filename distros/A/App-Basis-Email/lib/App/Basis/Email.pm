# ABSTRACT: Simple email sending, nothing special

=head1 NAME

App::Basis::Email

=head1 SYNOPSIS

    use Text::Markdown qw(markdown);
    use App::Basis::Email ;

    my $markdown = <<EOD ;
    # Basic Markdown

    ![BBC Logo](http://static.bbci.co.uk/frameworks/barlesque/2.60.6/orb/4/img/bbc-blocks-light.png)

    That was an inlined image

    ## level2 header

    * bullet
        * sub-bullet

    ### level3 header

    EOD
    my $html = markdown($markdown);

    my $mail = App::Basis::Email->new( hostname => 'my.email.server', port => 25 ) ;
    my $status = $mail->send(
        from    => 'fred@fred.test.fred',
        to      => 'fred@fred.test.fred',
        subject => 'test HTML email, with inline images',
        html    => $html
    );

=head1 DESCRIPTION
 
Sending email should be simple, sending formatted email should be simple too.
I just want to be able to say send this thing via this process.

This module provides that, a way to simply send email (plain/html or markdown) via
either a SMTP or sendmail target.

Obviously I do nothing new, just wrap around existing modules, to make life simple.

=head1 AUTHOR

kevin mulholland

=head1 Notes

if you want templating then do it outside of this module and pass the formatted
HTML/markdown in

=head1 See Also

To create email I use L<Email::MIME::CreateHTML>, you may need to force this to 
install it as there is a slight test bug
To send email I use L<Email::Sender::Simple> with L<Email::Sender::Transport::SMTP> and L<Email::Sender::Transport::Sendmail>
Markdown processing is done with L<Text::Markdown>

=over 4

=cut

package App::Basis::Email;
$App::Basis::Email::VERSION = '0.3';
use 5.010;
use warnings;
use strict;
use Moo;
use Try::Tiny;

use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP qw();
use Email::Sender::Transport::Sendmail;

use Email::MIME::CreateHTML;
use Text::Markdown 'markdown';
use HTML::Restrict;

# ----------------------------------------------------------------------------

# what host name are we connecting to, defaults to localhost
has host => ( is => 'ro', );

# on what port
has port => (
    is      => 'ro',
    default => sub { 25 },
);

# do we want to use SSL
has ssl => (
    is      => 'ro',
    default => sub { 0 },
);

# SSL needs a user
has user => (
    is      => 'ro',
    default => sub { '' },
);
# SSL user needs a password
has passwd => (
    is      => 'ro',
    default => sub { '' },
);

# how should we send things, either SMTP or Sendmail (default)
has transport => (
    is     => 'ro',
    writer => '_set_transport'
);

# if using sendmail having the path to the binary would help
has sendmail_path => ( is => 'ro' );

# we want a testing mode that will not send email, so that we can get output
# and use it for validation in our test scripts
has testing => ( is => 'ro' );

# ----------------------------------------------------------------------------
has sender => (
    is       => 'ro',
    init_arg => undef,          # dont allow setting in constructor
    writer   => '_set_sender'
);

# ----------------------------------------------------------------------------

=item new

Create a new instance of the email 

    my $mail = App::Basis::Email->new( host => "email.server.fred", port => 25 );

B<Parameters>
  host      ip address or hotsname of your SMTP server
  port      optional port number for SMTP, defaults to 25 
  ssl       use SSL mode
  user      user for ssl
  passwd    password for ssl
  testing   flag to show testing mode, prevents sending of email

=cut

sub BUILD {
    my $self = shift;
    my $sender;
    my $transport = $self->transport;

    $transport = 'SMTP' if ( $self->host );

    die "You need either host or transport Sendmail defined" if ( !$transport );
    die "You need username/password for SSL" if ( $self->ssl && !( $self->user && $self->passwd ) );

    # its sendmail or SMTP
    if ( $transport =~ /sendmail/i ) {
        die "sendmail_path should be passed to new when using transport => 'sendmail" if( !$self->sendmail_path) ;
        $sender = Email::Sender::Transport::Sendmail->new( { sendmail => $self->sendmail_path } );
    }
    else {
        $sender = Email::Sender::Transport::SMTP->new(
            {
                host          => $self->host,
                port          => $self->port,
                ssl           => $self->ssl,
                sasl_username => $self->user,
                sasl_password => $self->passwd
            }
        );
    }
    # make sure we set this, as it can be tested for in our test code
    $self->_set_transport($transport);
    # this too
    $self->_set_sender($sender);
}

# ----------------------------------------------------------------------------

=item send

send the required email

    my $mail = App::Basis::Email->new( hostname => 'my.email.server', port => 25 ) ;
    my $status = $mail->send(
        from    => 'fred@fred.test.fred',
        to      => 'fred@fred.test.fred',
        subject => 'test HTML email, with inline images',
        html    => $html
    );

Any data that is in the hash is passed to the server, though some may be re-interpreted
as mentioned in the DESCRIPTION

B<Parameters>
    to          email address to (can be array of email addresses)
    cc          email cc list (can be array of email addresses)
    from        email address from
    subject     subject for the email
    text        teset message to send, for email clients that do not do html
    html        html message to send
    markdown    markdown message to send, converted to html and replaces it
    css_file    link to a css file to use for HTML/markdown files

B<Returns>
    status - true = Sent, false = Failed (string of email message if testing flag used)

=cut    

sub send {
    my $self   = shift;
    my %params = @_;
    my $status = 0;
    my $to_str;

    # if we have markdown, then this replaces the HTML
    if ( $params{markdown} ) {
        $params{html} = markdown( $params{markdown} );
    }
    # if we do markdown or HTML and the user has not supplied alternative text
    # then we should strip all the HTML formatting from the html text and
    # use that
    if ( $params{html} && !$params{text} ) {

        my $hr = HTML::Restrict->new();

        # use default rules to start with (strip away all HTML)
        $params{text} = $hr->process( $params{html} );
    }
    if ( !$params{html} ) {
        $params{html} = "<p>$params{text}</p>";
    }

    if ( ref( $params{to} ) eq 'ARRAY' ) {
        $to_str = join( ', ', @{ $params{to} } );
    }
    else {
        $to_str = $params{to};
    }

    my $email = Email::MIME->create_html(
        header => [
            From    => $params{from},
            To      => $to_str,
            Subject => $params{subject},
        ],
        body       => $params{html},
        text_body  => $params{text},
        inline_css => 1
    );

    if ( ref( $params{to} ) eq 'ARRAY' ) {
        $email->header_str_set( To => @{ $params{to} } );
    }

    if ( $params{cc} ) {
        if ( ref( $params{cc} eq 'ARRAY' ) ) {
            $email->header_str_set( CC => @{ $params{cc} } );
        }
        else {
            $email->header_str_set( CC => $params{cc} );
        }
    }

    my $success;
    if ( $self->testing ) {
        # when we are testing we will not attempt the send
        # but we will return what would have been sent
        # we must assume that the send aspect works as this is built on
        # other peoples code and considered sound.
        # We don't do anything particularly fancy with it.
        return $email->as_string;
    }
    else {
        try {
            $success = sendmail(
                $email,
                {
                    # from      => $params{from},
                    transport => $self->sender
                }
            );
        }
        catch {
            warn "email sending failed: $_";
        };
    }

    if ($success) {
        $status = 1;
    }
    return $status;
}

# ----------------------------------------------------------------------------

=back

=cut

# ----------------------------------------------------------------------------

1;

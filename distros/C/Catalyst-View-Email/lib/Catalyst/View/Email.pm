package Catalyst::View::Email;

use Moose;
use Carp;

use Encode qw(encode decode);
use Email::Sender::Simple qw/ sendmail /;
use Email::MIME::Creator;
use Module::Runtime;
extends 'Catalyst::View';

our $VERSION = '0.36';
$VERSION = eval $VERSION;

has 'mailer' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { "sendmail" }
);

has '_mailer_obj' => (
    is      => 'rw',
    does    => 'Email::Sender::Transport',
    lazy    => 1,
    builder => '_build_mailer_obj',
);

has 'stash_key' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { "email" }
);

has 'default' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { { content_type => 'text/plain' } },
    lazy    => 1,
);

has 'sender' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { { mailer => shift->mailer } }
);

has 'content_type' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { shift->default->{content_type} },
    lazy    => 1,
);

=head1 NAME

Catalyst::View::Email - Send Email from Catalyst

=head1 SYNOPSIS

This module sends out emails from a stash key specified in the
configuration settings.

=head1 CONFIGURATION

WARNING: since version 0.10 the configuration options slightly changed!

Use the helper to create your View:
    
    $ script/myapp_create.pl view Email Email

In your app configuration:

    __PACKAGE__->config(
        'View::Email' => {
            # Where to look in the stash for the email information.
            # 'email' is the default, so you don't have to specify it.
            stash_key => 'email',
            # Define the defaults for the mail
            default => {
                # Defines the default content type (mime type). Mandatory
                content_type => 'text/plain',
                # Defines the default charset for every MIME part with the 
                # content type text.
                # According to RFC2049 a MIME part without a charset should
                # be treated as US-ASCII by the mail client.
                # If the charset is not set it won't be set for all MIME parts
                # without an overridden one.
                # Default: none
                charset => 'utf-8'
            },
            # Setup how to send the email
            # all those options are passed directly to Email::Sender::Simple
            sender => {
                # if mailer doesn't start with Email::Sender::Simple::Transport::,
                # then this is prepended.
                mailer => 'SMTP',
                # mailer_args is passed directly into Email::Sender::Simple 
                mailer_args => {
                    host     => 'smtp.example.com', # defaults to localhost
                    sasl_username => 'sasl_username',
                    sasl_password => 'sasl_password',
            }
          }
        }
    );

=head1 NOTE ON SMTP

If you use SMTP and don't specify host, it will default to localhost and
attempt delivery. This often means an email will sit in a queue and
not be delivered.

=cut

=head1 SENDING EMAIL

Sending email is just filling the stash and forwarding to the view:

    sub controller : Private {
        my ( $self, $c ) = @_;

        $c->stash->{email} = {
            to      => 'jshirley@gmail.com',
            cc      => 'abraxxa@cpan.org',
            from    => 'no-reply@foobar.com',
            subject => 'I am a Catalyst generated email',
            body    => 'Body Body Body',
        };
        
        $c->forward( $c->view('Email') );
    }

Alternatively you can use a more raw interface and specify the headers as
an array reference like it is passed to L<Email::MIME::Creator>.
Note that you may also mix both syntaxes if you like ours better but need to
specify additional header attributes.
The attributes are appended to the header array reference without overwriting
contained ones.

    $c->stash->{email} = {
        header => [
            To      => 'jshirley@gmail.com',
            Cc      => 'abraxxa@cpan.org',
            Bcc     => join ',', qw/hidden@secret.com hidden2@foobar.com/,
            From    => 'no-reply@foobar.com',
            Subject => 'Note the capitalization differences',
        ],
        body => qq{Ain't got no body, and nobody cares.},
        # Or, send parts
        parts => [
            Email::MIME->create(
                attributes => {
                    content_type => 'text/plain',
                    disposition  => 'attachment',
                    charset      => 'US-ASCII',
                },
                body => qq{Got a body, but didn't get ahead.},
            )
        ],
    };

You can set the envelope sender and recipient as well:

  $c->stash->{email} = {

    envelope_from => 'envelope-from@example.com',
    from          => 'header-from@example.com',

    envelope_to   => [ 'foo@example.com', 'bar@example.com' ],
    to            => 'Undisclosed Recipients:;',

    ...
  };

=head1 HANDLING ERRORS

If the email fails to send, the view will die (throw an exception).
After your forward to the view, it is a good idea to check for errors:
    
    $c->forward( $c->view('Email') );
    
    if ( scalar( @{ $c->error } ) ) {
        $c->error(0); # Reset the error condition if you need to
        $c->response->body('Oh noes!');
    } else {
        $c->response->body('Email sent A-OK! (At least as far as we can tell)');
    }

=head1 USING TEMPLATES FOR EMAIL

Now, it's no fun to just send out email using plain strings.
Take a look at L<Catalyst::View::Email::Template> to see how you can use your
favourite template engine to render the mail body.

=head1 METHODS

=over 4

=item new

Validates the base config and creates the L<Email::Sender::Simple> object for later use
by process.

=cut

sub BUILD {
    my $self = shift;

    my $stash_key = $self->stash_key;
    croak "$self stash_key isn't defined!"
      if ( $stash_key eq '' );

}

sub _build_mailer_obj {
    my ($self) = @_;
    my $transport_class = ucfirst $self->sender->{mailer};

    # borrowed from Email::Sender::Simple -- apeiron, 2010-01-26
    if ( $transport_class !~ /^Email::Sender::Transport::/ ) {
        $transport_class = "Email::Sender::Transport::$transport_class";
    }

    Module::Runtime::require_module($transport_class);

    return $transport_class->new( $self->sender->{mailer_args} || {} );
}

=item process($c)

The process method does the actual processing when the view is dispatched to.

This method sets up the email parts and hands off to L<Email::Sender::Simple> to handle
the actual email delivery.

=cut

sub process {
    my ( $self, $c ) = @_;

    croak "Unable to send mail, bad mail configuration"
      unless $self->sender->{mailer};

    my $email = $c->stash->{ $self->stash_key };
    croak "Can't send email without a valid email structure"
      unless $email;

    # Default content type
    if ( $self->content_type and not $email->{content_type} ) {
        $email->{content_type} = $self->content_type;
    }

    my $header = $email->{header} || [];
    push @$header, ( 'To' => delete $email->{to} )
      if $email->{to};
    push @$header, ( 'Cc' => delete $email->{cc} )
      if $email->{cc};
    push @$header, ( 'From' => delete $email->{from} )
      if $email->{from};
    push @$header,
      ( 'Subject' => Encode::encode( 'MIME-Header', delete $email->{subject} ) )
      if $email->{subject};
    push @$header, ( 'Content-type' => $email->{content_type} )
      if $email->{content_type};

    my $parts = $email->{parts};
    my $body  = $email->{body};

    unless ( $parts or $body ) {
        croak "Can't send email without parts or body, check stash";
    }

    my %mime = ( header => $header, attributes => {} );

    if ( $parts and ref $parts eq 'ARRAY' ) {
        $mime{parts} = $parts;
    }
    else {
        $mime{body} = $body;
    }

    $mime{attributes}->{content_type} = $email->{content_type}
      if $email->{content_type};
    if (    $mime{attributes}
        and not $mime{attributes}->{charset}
        and $self->{default}->{charset} )
    {
        $mime{attributes}->{charset} = $self->{default}->{charset};
    }

    $mime{attributes}->{encoding} = $email->{encoding} 
        if $email->{encoding};

    my $message = $self->generate_message( $c, \%mime );

    if ($message) {
        my $return = sendmail( $message,
          {
            exists $email->{envelope_from} ? ( from => $email->{envelope_from} ) : (),
            exists $email->{envelope_to}   ? ( to   => $email->{envelope_to}   ) : (),
            transport => $self->_mailer_obj,
          } );

        # return is a Return::Value object, so this will stringify as the error
        # in the case of a failure.
        croak "$return" if !$return;
    }
    else {
        croak "Unable to create message";
    }
}

=item setup_attributes($c, $attr)

Merge attributes with the configured defaults. You can override this method to
return a structure to pass into L<generate_message> which subsequently
passes the return value of this method to Email::MIME->create under the
C<attributes> key.

=cut

sub setup_attributes {
    my ( $self, $c, $attrs ) = @_;

    my $default_content_type = $self->default->{content_type};
    my $default_charset      = $self->default->{charset}; 
    my $default_encoding     = $self->default->{encoding};

    my $e_m_attrs = {};

    if (   exists $attrs->{content_type}
        && defined $attrs->{content_type}
        && $attrs->{content_type} ne '' )
    {
        $c->log->debug( 'C::V::Email uses specified content_type '
              . $attrs->{content_type}
              . '.' )
          if $c->debug;
        $e_m_attrs->{content_type} = $attrs->{content_type};
    }
    elsif ( defined $default_content_type && $default_content_type ne '' ) {
        $c->log->debug(
            "C::V::Email uses default content_type $default_content_type.")
          if $c->debug;
        $e_m_attrs->{content_type} = $default_content_type;
    }

    if (   exists $attrs->{charset}
        && defined $attrs->{charset}
        && $attrs->{charset} ne '' )
    {
        $e_m_attrs->{charset} = $attrs->{charset};
    }
    elsif ( defined $default_charset && $default_charset ne '' ) {
        $e_m_attrs->{charset} = $default_charset;
    }

    if ( exists $attrs->{encoding}
         && defined $attrs->{encoding}
         && $attrs->{encoding} ne '' )
    {
        $c->log->debug(
        'C::V::Email uses specified encoding '
        . $attrs->{encoding}
        . '.' )
         if $c->debug;
         $e_m_attrs->{encoding} = $attrs->{encoding};
    }
     elsif ( defined $default_encoding && $default_encoding ne '' ) {
         $c->log->debug(
         "C::V::Email uses default encoding $default_encoding.")
         if $c->debug;
         $e_m_attrs->{encoding} = $default_encoding;
     }

    return $e_m_attrs;
}

=item generate_message($c, $attr)

Generate a message part, which should be an L<Email::MIME> object and return it.

Takes the attributes, merges with the defaults as necessary and returns a
message object.

=cut

sub generate_message {
    my ( $self, $c, $attr ) = @_;

    # setup the attributes (merge with defaults)
    $attr->{attributes} = $self->setup_attributes( $c, $attr->{attributes} );
    Email::MIME->create( %$attr );
}

=back


=head1 TROUBLESHOOTING

As with most things computer related, things break.  Email even more so.  
Typically any errors are going to come from using SMTP as your sending method,
which means that if you are having trouble the first place to look is at
L<Email::Sender::Transport::SMTP>.  This module is just a wrapper for L<Email::Sender::Simple>,
so if you get an error on sending, it is likely from there anyway.

If you are using SMTP and have troubles sending, whether it is authentication
or a very bland "Can't send" message, make sure that you have L<Net::SMTP> and,
if applicable, L<Net::SMTP::SSL> installed.

It is very simple to check that you can connect via L<Net::SMTP>, and if you
do have sending errors the first thing to do is to write a simple script
that attempts to connect.  If it works, it is probably something in your
configuration so double check there.  If it doesn't, well, keep modifying
the script and/or your mail server configuration until it does!

=head1 SEE ALSO

=head2 L<Catalyst::View::Email::Template> - Send fancy template emails with Cat

=head2 L<Catalyst::Manual> - The Catalyst Manual

=head2 L<Catalyst::Manual::Cookbook> - The Catalyst Cookbook

=head1 AUTHORS

J. Shirley <jshirley@gmail.com>

Alexander Hartmaier <abraxxa@cpan.org>

=head1 CONTRIBUTORS

(Thanks!)

Matt S Trout

Daniel Westermann-Clark

Simon Elliott <cpan@browsing.co.uk>

Roman Filippov

Lance Brown <lance@bearcircle.net>

Devin Austin <dhoss@cpan.org>

Chris Nehren <apeiron@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 - 2009
the Catalyst::View::Email L</AUTHORS> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

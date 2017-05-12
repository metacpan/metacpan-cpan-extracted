package Dancer2::Plugin::Email;

our $VERSION = '0.0202'; # VERSION

use strict;
use warnings;

use Dancer2::Core::Types qw/HashRef/;
use Dancer2::Plugin;
use Email::Sender::Simple 'sendmail';
use Email::Date::Format 'email_date';
use File::Type;
use MIME::Entity;
use Module::Runtime 'use_module';

has headers => (
    is          => 'ro',
    isa         => HashRef,
    from_config => sub { +{} },
);

has transport => (
    is          => 'ro',
    isa         => HashRef,
    from_config => sub { +{} },
);

plugin_keywords 'email';

sub email {
    my ($plugin, $params) = @_;
    $params ||= {};
    my $multipart = delete $params->{multipart};
    my $extra_headers = delete($params->{headers}) || {};
    my %headers = ( %{ $plugin->headers }, %$params, %$extra_headers );
    my $attach = $headers{attach};
    my $sender = delete $headers{sender};
    if (my $type = $headers{type}) {
        $headers{Type} = $type eq 'html' ? 'text/html' : 'text/plain';
    }
    $headers{Type}   ||= 'text/plain';
    $headers{Format} ||= 'flowed' if $headers{Type} eq 'text/plain';
    $headers{Date}   ||= email_date();
    delete $headers{$_} for qw(body message attach type);

    my $email = MIME::Entity->build(
        Charset  => 'utf-8',
        Encoding => 'quoted-printable',
        %headers, # %headers may overwrite type, charset, and encoding
        Data => $params->{body} || $params->{message},
    );
    if ($attach) {
        if ($multipart) {
            # by default, when you add an attachment,
            # C<make_multipart> will be called by MIME::Entity, but
            # defaults to 'mixed'. Thunderbird doesn't like this for
            # embedded images, so we have a chance to set it to
            # 'related' or anything that the user wants
            $email->make_multipart($multipart);
        }
        my @attachments = ref($attach) eq 'ARRAY' ? @$attach : $attach;
        for my $attachment (@attachments) {
            my %mime;
            if (ref($attachment) eq 'HASH') {
                %mime = %$attachment;
                unless ($mime{Path} || $mime{Data}) {
                    $plugin->app->log('warning', "No Path or Data provided for this attachment!");
                    next;
                };
                if ( $mime{Path} ) {
                    $mime{Encoding} ||= 'base64';
                    $mime{Type} ||= File::Type->mime_type( $mime{Path} ),;
                }
            } else {
                %mime = (
                    Path     => $attachment,
                    Type     => File::Type->mime_type($attachment),
                    Encoding => 'base64',
                );
            }
            $email->attach(%mime);
        }
    }

    my $transport;
    if (my ($transport_name) = keys %{ $plugin->transport }) {
        my $transport_params = $plugin->transport->{$transport_name} || {};
        my $transport_class = "Email::Sender::Transport::$transport_name";
        my $transport_redirect = $transport_params->{redirect_address};
        $transport = use_module($transport_class)->new($transport_params);

        if ($transport_redirect) {
            $transport_class = 'Email::Sender::Transport::Redirect';
            $plugin->app->log('debug', "Redirecting email to $transport_redirect.");
            $transport = use_module($transport_class)->new(
                transport        => $transport,
                redirect_address => $transport_redirect
            );
        }
    }
    my %sendmail_arg = ( transport => $transport );
    $sendmail_arg{from} = $sender if defined $sender;
    return sendmail $email, \%sendmail_arg;
};

# ABSTRACT: Simple email sending for Dancer2 applications


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Email - Simple email sending for Dancer2 applications

=head1 VERSION

version 0.0202

=head1 SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::Email;
    
    post '/contact' => sub {
        email {
            from    => 'bob@foo.com',
            to      => 'sue@foo.com',
            subject => 'allo',
            body    => 'Dear Sue, ...',
            attach  => '/path/to/attachment',
        };
    };

=head1 DESCRIPTION

This plugin tries to make sending emails from L<Dancer2> applications as simple
as possible.
It uses L<Email::Sender> under the hood.
In a lot of cases, no configuration is required.
For example, if your app is hosted on a unix-like server with sendmail
installed, calling C<email()> will just do the right thing.

IMPORTANT: Version 1.x of this module is not backwards compatible with the
0.x versions.
This module was originally built on Email::Stuff which was built on
Email::Send which has been deprecated in favor of Email::Sender.
Versions 1.x and on have be refactored to use Email::Sender.
I have tried to keep the interface the same as much as possible.
The main difference is the configuration.
If there are features missing that you were using in older versions,
then please let me know by creating an issue on 
L<github|https://github.com/ironcamel/Dancer2-Plugin-Email>.

=head1 FUNCTIONS

This module by default exports the single function C<email>.

=head2 email

This function sends an email.
It takes a single argument, a hashref of parameters.
Default values for the parameters may be provided in the headers section of
the L</CONFIGURATION>.
Paramaters provided to this function will override the corresponding
configuration values if there is any overlap.
An exception is thrown if sending the email fails,
so wrapping calls to C<email> with try/catch is recommended.

    use Dancer2;
    use Dancer2::Plugin::Email;
    use Try::Tiny;

    post '/contact' => sub {
        try {
            email {
                sender  => 'bounces-here@foo.com', # optional
                from    => 'bob@foo.com',
                to      => 'sue@foo.com, jane@foo.com',
                subject => 'allo',
                body    => 'Dear Sue, ...<img src="cid:blabla">',
                multipart => 'related', # optional, see below
                attach  => [
                    '/path/to/attachment1',
                    '/path/to/attachment2',
                    {
                        Path => "/path/to/attachment3",
                        # Path is required when passing a hashref.
                        # See Mime::Entity for other optional values.
                        Id => "blabla",
                    }
                ],
                type    => 'html', # can be 'html' or 'plain'
                # Optional extra headers
                headers => {
                    "X-Mailer"          => 'This fine Dancer2 application',
                    "X-Accept-Language" => 'en',
                }
            };
        } catch {
            error "Could not send email: $_";
        };
    };

=head1 CONFIGURATION

No configuration is necessarily required.
L<Email::Sender::Simple> tries to make a good guess about how to send the
message.
It will usually try to use the sendmail program on unix-like systems
and SMTP on Windows.
However, you may explicitly configure a transport in your configuration.
Only one transport may be configured.
For documentation for the parameters of the transport, see the corresponding
Email::Sender::Transport::* module.
For example, the parameters available for the SMTP transport are documented
here L<Email::Sender::Transport::SMTP/ATTRIBUTES>.

You may also provide default headers in the configuration:

    plugins:
      Email:
        # Set default headers (OPTIONAL)
        headers:
          sender: 'bounces-here@foo.com'
          from: 'bob@foo.com'
          subject: 'default subject'
          X-Mailer: 'MyDancer2 1.0'
          X-Accept-Language: 'en'
        # Explicity set a transport (OPTIONAL)
        transport:
          Sendmail:
            sendmail: '/usr/sbin/sendmail'

Example configuration for sending mail via Gmail:

    plugins:
      Email:
        transport:
          SMTP:
            ssl: 1
            host: 'smtp.gmail.com'
            port: 465
            sasl_username: 'bob@gmail.com'
            sasl_password: 'secret'

Use the Sendmail transport using the sendmail program in the system path:

    plugins:
      Email:
        transport:
          Sendmail:

Use the Sendmail transport with an explicit path to the sendmail program:

    plugins:
      Email:
        transport:
          Sendmail:
            sendmail: '/usr/sbin/sendmail'

=head2 Multipart messages

You can embed images in HTML messages this way: first, set the C<type>
to C<html>. Then pass the attachments as hashrefs, setting C<Path> and
C<Id>. In the HTML body, refer to the attachment using the C<Id>,
prepending C<cid:> in the C<src> attribute. This works for popular
webmail clients like Gmail and OE, but is not enough for Thunderbird,
which wants a C<multipart/related> mail, not the default
C<multipart/mixed>. You can fix this adding the C<multipart> parameter
set to C<related>, which set the desired subtype when you pass
attachments.

Example:

    email {
        from      => $from,
        to        => $to,
        subject   => $subject,
        body      => q{<p>Image embedded: <img src="cid:mycid"/></p>},
        type      => 'html',
        attach    => [ { Id => 'mycid', Path => '/path/to/file' }],
        multipart => 'related'
    };

The C<attach> value accepts either a single attachment or an arrayref
of attachment. Each attachment may be a scalar, with the path of the
file to attach, or an hashref, in which case the hashref is passed to
the L<Mime::Entity>'s C<attach> method.

=head1 SEE ALSO

=over

=item L<Email::Sender>

=item L<MIME::Entity>

=back

=head1 AUTHOR

Naveed Massjouni <naveed@vt.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

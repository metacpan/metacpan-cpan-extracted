package Dancer::Plugin::EmailSender;
{
  $Dancer::Plugin::EmailSender::VERSION = '0.002';
}
#ABSTRACT: Easily use Email::Sender from Dancer

use Carp qw{croak};
use Dancer ':syntax';
use Dancer::Plugin;
use Email::MIME;
use Email::Sender::Simple qw{sendmail};
use Module::Load 'load';
use Scalar::Util 'blessed';
use Test::More import => ['!pass'];
use strict;
use warnings;


register sendemail => sub {
    my ($args) = @_ or croak 'You must pass me information on what to send';
    ref $args eq "HASH" or croak 'You must pass me a hashref to describe the email';

    my $config = plugin_setting;

    my $email;

    if ($args->{email}) {
        $email = Email::Abstract->new ($args->{email});
    } else {
        my $headers = {%{ref $config->{headers} eq 'HASH' ? $config->{headers} : {}}, %{ref $args->{headers} eq 'HASH' ? $args->{headers} : {}}, From => $args->{from}, To => join ",", ref $args->{to} eq 'ARRAY' ? @{$args->{to}} : ()};
        $email = Email::Abstract->new (Email::MIME->create (header_str => [%{$headers}], body => $args->{body}));
    }

    croak 'Could not extract or construct an email from our parameters' unless ($email);

    my $params = {};
    ($params->{from} = $args->{'envelope-from'}) or $email->get_header ('from') or croak 'You must tell me who the email is from';
    ($params->{to} = $args->{'envelope-to'}) or $email->get_header ('to') or croak 'You must tell me to whom to send the email';

    if (blessed $args->{transport}) {
        $params->{transport} = $args->{transport};
    } elsif (!defined $args->{transport} and blessed $config->{transport}) {
        $params->{transport} = $config->{transport};
    } else {
        my $transport = {%{ref $config->{transport} eq 'HASH' ? $config->{transport} : {}}, %{ref $args->{transport} eq 'HASH' ? $args->{transport} : {}}};
        if (my $choice = delete $transport->{class}) {
            my $class = "Email::Sender::Transport::$choice";
            load $class;
            $params->{transport} = $class->new ($transport);
        }
    }

    return sendmail $email, $params;
};

register_plugin;


1;

__END__
=pod

=head1 NAME

Dancer::Plugin::EmailSender - Easily use Email::Sender from Dancer

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::EmailSender;

    post '/signup' => sub {
        sendemail {
            body            => '...',
            'envelope-from' => 'signup-@ironicdesign.com-@[]' # Allows VERP-handling with postfix
            from            => 'mdorman@ironicdesign.com',
            subject         => 'Welcome to our site',
            to              => param ('email')
        };
    };

=head1 DESCRIPTION

This plugin makes constructing and sending emails from L<Dancer>
applications as simple and flexible as possible.  Since it uses
L<Email::Sender|Email::Sender>, in many cases, no explicit configuration may be
required, though several configuration options are available.

=head1 CONFIGURATION

You can configure a number of defaults for the plugin in the your
C<config.yml> or appropriate C<environment> config file.  Anything
that you configure in this way can be overridden at the time
C<sendemail> is called.

=head2 Transport

C<Dancer::Plugin::EmailSender> allows you to choose and configure a
particular transport, should you not wish to use the one that
C<Email::Sender> would choose by default (as discussed in
L<the Email::Sender manual|Email::Sender::Manual::QuickStart/Picking_a_Transport>).

Simply add a C<transport> key, pointing to a set of options that must
include a C<class> entry (stating the name of the subclass of
L<Email::Sender::Transport:*|Email::Sender::Transport> to be used for the transport), while any
additional entries will be used as parameters for instantiating the
transport:

For example, to send mail using SMTPS via Gmail:

    plugins:
      EmailSender:
        transport:
          class: SMTP:
          ssl: 1
          host: 'smtp.gmail.com'
          port: 465
          sasl_username: 'mdorman@ironicdesign.com'
          sasl_password: 'NotMuchOfASecret'

Or perhaps to use the default Sendmail transport, but give an explicit
path to the sendmail program:

    plugins:
      EmailSender:
        transport:
          class: Sendmail
          sendmail: '/usr/sbin/sendmail'

=head2 Headers

You may also provide a set of default headers in the configuration:

    plugins:
      EmailSender:
        headers:
          From: 'noreply@ironicdesign.com'
          X-Mailer: 'Degronkulator 3.14'
          X-Accept-Language: 'en'

=head1 sendemail

This function will optionally construct, and then send, an email.  It
takes a hashref of parameters.  They can be divided up as to their
purpose:

=head2 Specifying the content to send

To specify the content of the email to send, you may either:

=head3 Provide a complete email to be sent

If a completed email (in a format that is acceptable to
C<Email::Abstract> is provided in an C<email> parameter, that is the
email that will be sent.

=head3 Provide parameters to construct an email

These parameters include:

=over

=item from

The address from which the email should be sent.

=item to

An arrayref od address to which the email should be sent.

=item headers

A hashref of additional headers to add to the email.

=item body

The body of the actual email to be sent.

=back

=head2 Specifying how the email is sent

You may optionally specify the transport here, overriding any defaults
or settings in your application configuration.  All configuration will
appear under a C<transport> key.

From there you can specify the transport to use two different ways.

=head3 Provide a set of construction parameters

The parameters you hand in will be used just as if they had appeared
in the configuration to create a new transport, which will then be
used for this transaction.

=head3 Provide a constructed Transport

You may construct your own transport and simply hand that in to the
C<sendemail> routine.

=head2 Specifying the sending and retrieving addresses

You may independently set the sending and receiving addresses for the
SMTP transaction, allowing them to be different from the values in the
headers of your email.  To do this you can include either or both of:

=head3 envelope-from

This is the address that will be used as the sending address during
the SMTP transaction.

=head3 envelope-to

This is the list of addresse that will be used as recipients during
the SMTP transaction.

=head2 Error Handling

An exception will be thrown if sending the email fails, so plan
appropriately.

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

Although I started out just wanting to fix things in
L<Dancer::Plugin::Email>, I ended up rewriting everything.  Still,
Naveed Massjouni <naveedm9@gmail.com> and Al Newkirk
<awncorp@cpan.org> deserve credit for writing
C<Dancer::Plugin::Email>.

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


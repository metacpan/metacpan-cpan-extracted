package Daje::Tools::Mail::Sender;
use Mojo::Base  -base;
use v5.42;

# NAME
# ====
#
# Daje::Tools::Mail::Sender - A mail sender
#
# SYNOPSIS
# ========
#;
#
# DESCRIPTION
# ===========
#
# Daje::Tools::Mail::Sender sends one or a collection of mails
#
# METHODS
# =======
#
#           my $sender = Daje::Tools::Mail::Sender->new(
#               smtp        => 'smtp server',
#               account     => 'username',
#               password      => 'password'
#           );
#
#           $sender->send_mail($mail)
#
#           $mail->{recipients} = "comma separated list";
#           $mail->{subject} = "Whatever subject for this mail";
#           $mail->{message} = "Probably a HTML message";
#
#           $sender->send_mails($mails)
#
#           $mails a list of $mail
#
# SEE ALSO
# ========
#
# Mojolicious, Mojolicious::Guides, https://mojolicious.org.
#
# LICENSE
# =======
#
# Copyright (C) janeskil1525.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# AUTHOR
# ======
#
# janeskil1525 E<lt>janeskil1525@gmail.com
#

use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use Email::MIME;

has 'host';
has 'account';
has 'password';

sub send_mail($self, $mail){
    return $self->_send_mail($mail);
}

sub send_mails($self, $mails){
    if($mails->rows){
        my $collection = $mails->hashes;
        $collection->each(sub{
            my $coll = shift;
            $self->_send_mail($coll);
        });
    }
}

sub _send_mail{
    my ($self, $mail) = @_;

    my @parts;

    push @parts,  Email::MIME->create(
        attributes => {
            content_type => "text/html",
            disposition  => "attachment",
            charset      => "ISO-8859-1",
            encoding     => 'base64',
            encode_check => 0,
        },
        body_str => $mail->{message},
    );


    my $email = Email::MIME->create(
        header_str     => [
            From           => $self->account,
            To             => $mail->{recipients},
            Subject        => $mail->{subject},
        ],
        parts => [@parts],
    );

    my $transport = Email::Sender::Transport::SMTP->new({
        host          => $self->host,
        port          => 587,
        ssl           => 'starttls',
        sasl_username => $self->account,
        sasl_password => $self->password,
    });

    sendmail($email, {
        transport => $transport
    });

    return 1;
}

1;
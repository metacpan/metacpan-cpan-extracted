package Daje::Tools::Mail::Manager;
use Mojo::Base  -base, -signatures;
use v5.42;


# NAME
# ====
#
# Daje::Tools::Mail::Manager - A mail manager
#
# SYNOPSIS
# ========
#;
#
# DESCRIPTION
# ===========
#
# Daje::Tools::Mail::Manager is a Daje workflow activity.
#
# METHODS
# =======
#
#
# activity
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
use Daje::Database::View::vMailFallbackSettings;
use Daje::Document::Builder;
use Daje::Tools::Mail::Sender;

has 'db';
has 'error';

sub verify_simple($self, $recipient, $code) {
    my $data->{code} = $code;
    my $mail->{message} = @{$self->_build_mail(
        'Daje::Documents::Templates::Mail::Verify::VerifyLogin',
        'verify_simple',
        $data
    )}[0]->{document};
    $mail->{recipients} = $recipient;
    $mail->{subject} = "Daje login";
    $self->_send_mail($mail);

}

sub _send_mail($self, $mail)  {
    my $settings = Daje::Database::View::vMailFallbackSettings->new(
        db => $self->db
    )->load_mail_fallback_settings_pkey(1)->{data};

    my $sender = Daje::Tools::Mail::Sender->new(
        host    => $settings->{host},
        account => $settings->{username},
        password  => $settings->{password},
    )->send_mail($mail);

}

sub _build_mail ($self, $source, $data_sections, $data) {

    my $builder = Daje::Document::Builder->new(
        source        => $source,
        data_sections => $data_sections,
        data          => $data,
        error         => $self->error()
    );

    $builder->process();

    return $builder->output();
}
1;
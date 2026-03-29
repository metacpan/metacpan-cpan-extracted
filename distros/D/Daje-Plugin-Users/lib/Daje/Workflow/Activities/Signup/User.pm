package Daje::Workflow::Activities::Signup::User;
use Mojo::Base 'Daje::Workflow::Common::Activity::Base', -base, -signatures;
use v5.42;

# NAME
# ====
#
# Daje::Workflow::Activity::Signup::User - It signs up a new client
#
# SYNOPSIS
# ========
#
#     use Daje::Workflow::Activity::Signup::User
#
# DESCRIPTION
# ===========
#
# Daje::Workflow::Activity::Signup::User is a module that generates perl code
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
# janeskil1525 E<lt>janeskil1525@gmail.comE<gt>
#

use Data::Dumper;
use Digest::SHA qw{sha512_base64};
use Daje::Database::Model::UsersUsers;
use Daje::Helper::Users::Login;
use Daje::Tools::Mail::Manager;

sub signup($self) {

    $self->model->insert_history(
        "New client",
        "Daje::Workflow::Activities::Signup::User::signup",
        1
    );

    my $data = $self->context->{context}->{payload};
    $data->{password} = sha512_base64($data->{password});
    try {
        my $dbclass = Daje::Database::Model::UsersUsers->new(db => $self->db);
        my $hist = $data;
        #delete $hist->{password};
        $self->model->insert_history(
            "New client " . $dbclass->table_name() . Dumper($hist), " insert", 2
        );

        $data->{$dbclass->workflow()} = $self->context->{context}->{workflow}->{workflow_fkey}
            if($dbclass->workflow());

        my $pkey = $dbclass->insert($data)->{data}->{$dbclass->primary_key_name()};
        $self->context->{context}->{payload}->{$dbclass->table_name()} = $pkey;

    } catch ($e) {
        $self->error->add_error($e);
    };
}

sub verify($self) {

    my $data = $self->context->{context}->{payload};
    $self->model->insert_history(
        "Verify user",
        "Daje::Workflow::Activities::Signup::User::verify " . $data->{mail},
        1
    );

    try {
        my $code = Daje::Helper::Users::Login->new(
            db => $self->db
        )->verify(
            $data->{mail}
        );

        Daje::Tools::Mail::Manager->new(
            db    => $self->db,
            error => $self->error(),
        )->verify_simple(
            $data->{mail}, $code
        );
    } catch ($e) {
        $self->error->add_error($e);
    }
}
1;
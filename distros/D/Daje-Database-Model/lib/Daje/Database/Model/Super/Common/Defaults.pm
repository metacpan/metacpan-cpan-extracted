package Daje::Database::Model::Super::Common::Defaults;
use Mojo::Base -base, -signatures;
use v5.40;

# NAME
# ====
#
# Daje::Database::Model::Super::Common::Defaults - It's the Daje database classes
#
# SYNOPSIS
# ========
#
#     use Daje::Database::Model::Super::Common::Defaults;
#
# DESCRIPTION
# ===========
#
# Daje::Database::Model::Super::Common::Defaults is ...
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
#

use POSIX qw {strftime};

has 'users_pkey' => 'System';

sub update_defaults($self, $data) {
    $data->{editnum}++;
    $data->{moddatetime} = strftime("%F %T", localtime);
    $data->{modby} = $self->users_pkey();

    return $data;
}

sub insert_defaults($self, $data) {
    delete %$data{$self->primary_key_name()} if exists $data->{$self->primary_key_name()};
    delete %$data{editnum} if exists $data->{editnum};
    delete %$data{insby} if exists $data->{insby};
    delete %$data{insdatetime} if exists $data->{insdatetime};
    delete %$data{modby} if exists $data->{modby};
    delete %$data{moddatetime} if exists $data->{moddatetime};
    return $data;
}

1;
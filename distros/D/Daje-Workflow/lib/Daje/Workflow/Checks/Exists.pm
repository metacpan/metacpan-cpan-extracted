package Daje::Workflow::Checks::Exists;
use Mojo::Base 'Daje::Workflow::Checks::Super::Base', -base, -signatures;
use v5.42;



# NAME
# ====
#
# Daje::Workflow::Checks::Exists  - Checks for mandatory fields
#
# SYNOPSIS
# ========
#
#    exists($self)
#
#    Checks can either come from the workflow checks tag as a comma separated string of fields
#
#               {
#                 "name": "Record already exists",
#                 "class": "Daje::Workflow::Checks::Exists",
#                 "checks": {
#                   "fields": "mail",
#                   "table": "users_users",
#                   "err_text": "This user already exists, maybe you should try to change password instead ?"
#               }
#
#    Assumed format of data $self->context->{context}->{payload}->{field(s) to be checked for existence)
#
#
# DESCRIPTION
# ===========
#
# Daje::Workflow::Checks::Mandatory is used to check and make sure
# mandatory fields are included in the context
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
# janeskil1525 E<lt>janeskil1525@gmail.comE<gt>
#

sub check($self) {
    my $result = 1;

    if (exists $self->checks->{fields}) {
        my @fields = ();
        my $condition = {};
        @fields = split(',', $self->checks()->{fields});
        my $table = $self->checks()->{table};

        my $length = scalar @fields;
        my $temp = $self->context();
        for (my $i = 0; $i < $length; $i++) {
            if (exists $self->context->{context}->{payload}->{$fields[$i]}) {
                $condition->{$fields[$i]} = $self->context->{context}->{payload}->{$fields[$i]}
            }
        }
        my $data;
        my $load = $self->db->select($table, '*', $condition);
        $data = $load->hash if $load and $load->rows > 0;
        if(defined $data) {
            $self->error->add_error($self->checks()->{err_text});
            $result = 0;
        }
    }

    return $result;
}

1;
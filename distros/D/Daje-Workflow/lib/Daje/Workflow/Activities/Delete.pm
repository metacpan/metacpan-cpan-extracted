package Daje::Workflow::Activities::Delete;
use Mojo::Base 'Daje::Workflow::Common::Activity::Base', -base, -signatures;
use v5.42;

# NAME
# ====
#
# Daje::Workflow::Activities::Delete - It deletes database objects
#
# SYNOPSIS
# ========
#
#     use Daje::Workflow::Activities::Delete
#
#     use Mojo::Loader qw(load_class);
#
#     Expected input from workflow
#
#     "activity_data": {
#         "class": "Model to use"
#     }
#
# DESCRIPTION
# ===========
#
# Daje::Workflow::Activities::Delete just deletes a record in a table
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
use Mojo::Loader qw(load_class);

sub delete ($self) {

    my $data = $self->context->{context}->{payload};
    my $class = $self->activity_data->{class};
    if (my $e = load_class $class) {
        $self->error->add_error($e);
        $self->error->add_error($class . " Not found ");
    }
    return 0 if $self->error->has_error();
    say "Class = " . $class;

    try {
        my $dbclass = $class->new(db => $self->db);
        say $dbclass->primary_key_name . " " . Dumper($data);
        if (exists $data->{$dbclass->primary_key_name} and $data->{$dbclass->primary_key_name} > 0) {
            $self->model->insert_history(
                "Delete object " . Dumper($data), " $class->delete", 1
            );

            my $result = $dbclass->delete($data->{$dbclass->primary_key_name});
            if($result->{result} == 0) {
                $self->error->add_error($result->{error});
            }
        };
    } catch ($e) {
        $self->error->add_error($e);
    };

    return 1;
}
1;
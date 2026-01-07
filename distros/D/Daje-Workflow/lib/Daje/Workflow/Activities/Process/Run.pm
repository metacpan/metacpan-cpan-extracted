package Daje::Workflow::Activities::Process::Run;
use Mojo::Base 'Daje::Workflow::Common::Activity::Base', -base, -signatures;
use v5.42;

# NAME
# ====
#
# Daje::Workflow::Activities::Process::Run - It's a tool to run a process
#
# SYNOPSIS
# ========
#
#     use Daje::Workflow::Activities::Process::Run;
#
#      "activity_data": {
#               "process" : {
#                 "program": "program to run"
#               }
#             }
#
#      Mandatory meta data
#
#      - program to run
#
#
#
# DESCRIPTION
# ===========
#
# Daje::Workflow::Activities::Process::Run is a process runner
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

sub execute($self) {

    $self->model->insert_history(
        "Run process",
        "Daje::Workflow::Activities::Process::Run::execute",
        1
    );

    try {
        my $program = $self->activity_data->{process}->{program};
        system $program;
    } catch($e) {
        $self->error->add_error($e);
    };


}
1;
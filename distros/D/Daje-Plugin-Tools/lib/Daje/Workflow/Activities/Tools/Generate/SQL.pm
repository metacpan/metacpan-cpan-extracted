package Daje::Workflow::Activities::Tools::Generate::SQL;
use Mojo::Base 'Daje::Workflow::Activities::Tools::Generate::Base', -base, -signatures;
use v5.42;

# NAME
# ====
#
# Daje::Workflow::Activities::Tools::Generate::SQL - Generate SQL
# migration files for Mojo::Pg
#
# SYNOPSIS
# ========
#
#     use Daje::Workflow::Activities::Tools::Generate::SQL
#
# DESCRIPTION
# ===========
#
# Daje::Workflow::Activities::Tools::Generate::SQL is a module that generates SQL
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
use Daje::Document::Builder;


sub generate_sql($self) {

    # $self->model->insert_history(
    #     "New project",
    #     "Daje::Workflow::Activity::Tools::Generate::SQL::generate_sql",
    #     1
    # );

    try {
        my $tools_projects_pkey = $self->context->{context}->{payload}->{tools_projects_pkey};
        if ($self->load_generate_data($tools_projects_pkey)) {
            $self->build_documents($tools_projects_pkey);
        }
    } catch ($e) {
        say $e
        #$self->error->add_error($e);
    };
}

sub build_documents ($self, $tools_projects_pkey) {
    my $source = $self->get_parameter('Sql', 'Template Source', $tools_projects_pkey);

    my $builder = Daje::Document::Builder->new(
        source        => $source,
        data_sections => 'sql',
        data          => $self->versions(),
        error         => $self->error()
    );

    my $data = $self->versions();
    say Dumper($data);

    $builder->process();

    my $documents = $builder->output();
    my $test = 1;
}



1;
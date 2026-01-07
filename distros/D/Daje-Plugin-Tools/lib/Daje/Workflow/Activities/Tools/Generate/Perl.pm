package Daje::Workflow::Activities::Tools::Generate::Perl;
use Mojo::Base 'Daje::Workflow::Activities::Tools::Generate::Base', -base, -signatures;
use v5.42;

use POSIX;
use Mojo::Util qw { camelize };
use String::Util 'trim';

sub generate_perl($self) {
    $self->model->insert_history(
        "Generate Perl",
        "Daje::Workflow::Activities::Tools::Generate::Perl::generate_perl",
        1
    );

    my $tools_projects_pkey = $self->context->{context}->{payload}->{tools_projects_fkey};
    my @outputs = split /,/,  $self->get_parameter('Perl', 'Outputs', $tools_projects_pkey);;
    try {
        my $documents;
        my $source = $self->get_parameter('Perl', 'Template Source', $tools_projects_pkey);
        foreach my $output (@outputs) {
            my $generate = "generate_" . trim($output);
            my $doc = $self->$generate($tools_projects_pkey, $source);
            if (ref $doc eq 'ARRAY') {
                my $length = scalar @{ $doc };
                for (my $i = 0; $i < $length; $i++) {
                    push @{$documents}, @{ $doc }[$i];
                }
            } else {
                push @{$documents}, $doc;
            }

        }
        my @data;
        my $length = scalar @{$documents};
        for (my $i = 0; $i < $length; $i++) {
            my $data->{data} = @{$documents}[$i]->{document};
            $data->{file} = @{ $documents }[$i]->{file};
            $data->{new_only} = @{ $documents }[$i]->{new_only}
                if exists @{ $documents }[$i]->{new_only};
            $data->{path} = 1;
            push(@data, $data);
        }
        $self->context->{context}->{payload}->{perl} = \@data;

    } catch($e) {
        say $e
            $self->error->add_error($e);
    };
}

sub generate_controller($self, $tools_projects_pkey, $source) {
    my $docs;
    my $project_name = $self->load_project_name($tools_projects_pkey);
    if($self->load_active_tables($tools_projects_pkey)) {
        my $length = scalar @{$self->tables};
        for (my $i = 0; $i < $length; $i++) {
            my $table->{table} = @{$self->tables}[$i];
            $table->{project_name} = $project_name;
            $table->{class_name} = camelize $table->{project_name} . "_" . $table->{table}->{table_name};
            $table->{date_time} = strftime "%Y-%m-%d %H:%M:%S", localtime time;
            $self->versions($table);
            my $documents = $self->build_documents($source,'controller');
            @{ $documents }[0]->{class_name} = $table->{class_name};
            @{ $documents }[0]->{file} = $self->get_parameter('Perl', 'Controller file path', $tools_projects_pkey) .  $table->{class_name} . '.pm';
            @{ $documents }[0]->{new_only} = 1;
            push @{$docs}, @{ $documents }[0];
            $documents = $self->build_documents($source,'tests_controller');
            @{ $documents }[0]->{class_name} = $table->{class_name};
            @{ $documents }[0]->{file} = $self->get_parameter('Perl', 'Test file path', $tools_projects_pkey) . $table->{table}->{table_name} . '.controller.t';
            @{ $documents }[0]->{new_only} = 0;
            push @{$docs}, @{ $documents }[0];
        }
    }

    return $docs;
}

sub generate_super_controller($self, $tools_projects_pkey, $source) {
    my $docs;
    my $project_name = $self->load_project_name($tools_projects_pkey);
    if($self->load_active_tables($tools_projects_pkey)) {
        my $length = scalar @{$self->tables};
        for (my $i = 0; $i < $length; $i++) {
            my $table->{table} = @{$self->tables}[$i];
            $table->{project_name} = $project_name;
            $table->{fields} = $self->load_active_table_fields($table->{table}->{tools_objects_pkey});
            $table->{class_name} = camelize $table->{project_name} . "_" . $table->{table}->{table_name};
            $table->{date_time} = strftime "%Y-%m-%d %H:%M:%S", localtime time;
            $self->versions($table);
            my $documents = $self->build_documents($source,'super_controller');
            @{ $documents }[0]->{class_name} = $table->{class_name};
            @{ $documents }[0]->{file} = $self->get_parameter('Perl', 'Controller file path', $tools_projects_pkey) . 'Super/' . $table->{class_name} . '.pm';
            @{ $documents }[0]->{new_only} = 0;
            push @{$docs}, @{ $documents }[0];
        }
    }

    return $docs;
}

sub generate_helpers($self, $tools_projects_pkey, $source) {
    my $docs;
    my $tables;
    my $project_name = $self->load_project_name($tools_projects_pkey);
    my $class_name = camelize $project_name;
    if($self->load_active_tables($tools_projects_pkey)) {
        $tables->{project_name} = $project_name;
        $tables->{class_name} = $class_name;
        $tables->{date_time} = strftime "%Y-%m-%d %H:%M:%S", localtime time;
        my $length = scalar @{$self->tables};
        for (my $i = 0; $i < $length; $i++) {
            my $table = @{$self->tables}[$i];
            $table->{class_name} = camelize $project_name . "_" . $table->{table_name};
            $table->{fields} = $self->load_active_table_fields($table->{tools_objects_pkey});
            push @{$tables->{tables}}, $table;
        }
        $self->versions($tables);
        my $documents = $self->build_documents($source,'helpers');
        @{ $documents }[0]->{file} = $self->get_parameter('Perl', 'Helpers file path', $tools_projects_pkey) . "Helpers.pm";
        @{ $documents }[0]->{new_only} = 0;
        push @{$docs}, @{ $documents }[0];
    }
    return $docs;
}

sub generate_routes($self, $tools_projects_pkey, $source) {
    my $docs;
    my $tables;
    my $project_name = $self->load_project_name($tools_projects_pkey);
    my $class_name = camelize $project_name;
    if($self->load_active_tables($tools_projects_pkey)) {
        $tables->{project_name} = $project_name;
        $tables->{class_name} = $class_name;
        $tables->{date_time} = strftime "%Y-%m-%d %H:%M:%S", localtime time;
        my $length = scalar @{$self->tables};
        for (my $i = 0; $i < $length; $i++) {
            my $table = @{$self->tables}[$i];
            $table->{class_name} = camelize $project_name . "_" . $table->{table_name};
            $table->{fields} = $self->load_active_table_fields($table->{tools_objects_pkey});
            push @{$tables->{tables}}, $table;
        }
        $self->versions($tables);
        my $documents = $self->build_documents($source,'routes');
        @{ $documents }[0]->{file} = $self->get_parameter('Perl', 'Routes file path', $tools_projects_pkey) . "Routes.pm";
        @{ $documents }[0]->{new_only} = 0;
        push @{$docs}, @{ $documents }[0];
    }
    return $docs;
}

sub generate_db_model($self, $tools_projects_pkey, $source) {
    my $docs;
    my $project_name = $self->load_project_name($tools_projects_pkey);
    if($self->load_active_tables($tools_projects_pkey)) {
        my $length = scalar @{$self->tables};
        for (my $i = 0; $i < $length; $i++) {
            my $table->{table} = @{$self->tables}[$i];
            $table->{class_name} = camelize $project_name . "_" . $table->{table}->{table_name};
            $table->{date_time} = strftime "%Y-%m-%d %H:%M:%S", localtime time;
            $self->versions($table);
            my $documents = $self->build_documents($source,'db_model');
            @{ $documents }[0]->{class_name} = $table->{class_name};
            @{ $documents }[0]->{file} = $self->get_parameter('Perl', 'Model file path', $tools_projects_pkey) . $table->{class_name} . '.pm';
            @{ $documents }[0]->{new_only} = 0;
            push @{$docs}, @{ $documents }[0];
            $documents = $self->build_documents($source,'tests_database_model');
            @{ $documents }[0]->{class_name} = $table->{class_name};
            @{ $documents }[0]->{file} = $self->get_parameter('Perl', 'Test file path', $tools_projects_pkey) . $table->{table}->{table_name} . '.model.t';
            @{ $documents }[0]->{new_only} = 0;
            push @{$docs}, @{ $documents }[0];
        }
    }
    return $docs;
}

sub generate_db_model_super($self, $tools_projects_pkey, $source) {
    my $docs;
    my $project_name = $self->load_project_name($tools_projects_pkey);
    if($self->load_active_tables($tools_projects_pkey)) {
        my $length = scalar @{$self->tables};
        for (my $i = 0; $i < $length; $i++) {
            my $table->{table} = @{$self->tables}[$i];
            $table->{project_name} = $project_name;
            $table->{fields} = $self->load_active_table_fields($table->{table}->{tools_objects_pkey});
            $table->{class_name} = camelize $table->{project_name} . "_" . $table->{table}->{table_name};
            $table->{date_time} = strftime "%Y-%m-%d %H:%M:%S", localtime time;
            $self->versions($table);
            my $documents = $self->build_documents($source,'db_model_super');
            @{ $documents }[0]->{class_name} = $table->{class_name};
            @{ $documents }[0]->{file} = $self->get_parameter('Perl', 'Model file path', $tools_projects_pkey) . 'Super/' . $table->{class_name} . '.pm';
            @{ $documents }[0]->{new_only} = 0;
            push @{$docs}, @{ $documents }[0];
        }
    }

    return $docs;
}

sub generate_plugin($self, $tools_projects_pkey, $source) {

    my $versions->{project_name} = $self->load_project_name($tools_projects_pkey);

    $versions->{plugin_name} = camelize $versions->{project_name};
    $versions->{date_time} = strftime "%Y-%m-%d %H:%M:%S", localtime time;
    $self->versions($versions);
    my $documents = $self->build_documents($source,'plugin');
    @{ $documents }[0]->{file} = $self->get_parameter('Perl', 'Plugin file path', $tools_projects_pkey) .  $versions->{plugin_name} . '.pm';
    @{ $documents }[0]->{new_only} = 1;

    return @{$documents}[0];
}
1;
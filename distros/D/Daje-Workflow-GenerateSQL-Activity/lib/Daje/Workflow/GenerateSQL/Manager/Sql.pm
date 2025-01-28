package Daje::Workflow::GenerateSQL::Manager::Sql;
use Mojo::Base 'Daje::Workflow::GenerateSQL::Base::Common', -base, -signatures;

# Daje::Generate::Sql::SqlManager  Generatee Database and table related SQL scripts from JSON file
#
# Synopsis
# ========
#
# use Daje::Generate::Sql::SqlManager;
#
# my $table = Daje::Generate::Sql::SqlManager->new(
#       json        => $json,
#       template    => $template,
# );
#
# METHODS
# =======
# $table->generate_table();
# my $script = $table->sql();
#
#
# LICENSE
# =======
# Daje::Generate::Sql::SqlManager  (the distribution) is licensed under the same terms as Perl.
#
# AUTHOR
# ======
# Jan Eskilsson
#
# COPYRIGHT
# =========
# Copyright (C) 2024 Jan Eskilsson.
#

our $VERSION = '0.01';

has 'context';


use Daje::Workflow::GenerateSQL::Script::Fields;
use Daje::Workflow::GenerateSQL::Script::Index;
use Daje::Workflow::GenerateSQL::Script::ForeignKey;
use Daje::Workflow::GenerateSQL::Script::Sql;

sub generate_table($self) {
    my $sections = "";
    my $json_arr = $self->json;
    my $length = scalar @{$json_arr};
    for (my $i = 0; $i < $length; $i++) {
        my $json = @{$json_arr}[$i];
        if (exists($json->{version})) {
            $sections .= $self->_version($json->{version});
        }
    }
    $self->set_sql($self->create_file($sections));
    return ;
}

sub _version($self, $version) {
    my $sql = "";
    my $sections = "";
    my $length = scalar @{$version};
    for (my $i = 0; $i < $length; $i++) {
        if(exists(@{$version}[$i]->{tables})) {
            my $tables = @{$version}[$i]->{tables};
            my $len = scalar @{$tables};
            for(my $j = 0; $j < $len; $j++){
                my $table = $self->shift_section($tables);
                $sql .= $self->create_table_sql($table);
            }
            $sections .= $self->create_section($sql, @{$version}[$i]->{number});
        }
    }
    return $sections
}

sub create_file($self, $sections) {
    my $file = $self->templates->get_data_section('file');
    my $date = localtime();
    $file =~ s/<<date>>/$date/ig;
    $file =~ s/<<sections>>/$sections/ig;

    return $file;
}

sub create_section($self, $sql, $number) {
    my $section = $self->templates->get_data_section('section');
    $section =~ s/<<version>>/$number/ig;
    $section =~ s/<<table>>/$sql/ig;
    return $section;
}

sub create_table_sql($self, $table) {
    my $result = "";
    my $fields = '';
    my $indexes = '';
    my $foreignkeys = "";
    my $sql = "";

    my $name = $table->{table}->{name};
    if (exists($table->{table}->{fields})) {
        $fields = $self->create_fields($table->{table});
        $foreignkeys = $self->create_fkeys($table->{table}, $name);
    }
    my $test = $table->{table}->{index};
    if (exists($table->{table}->{index})) {
        $indexes = $self->create_index($table->{table})
    }

    if (exists($table->{table}->{sql})) {
        $sql = $self->create_sql($table->{table}, $name)
    }

    my $template = $self->fill_template($name, $fields, $foreignkeys, $indexes, $sql);

    return $template;

}

sub create_sql($self, $json, $tablename) {
    my $sql_stmt = Daje::Workflow::GenerateSQL::Manager::Sql->new(
        json      => $json,
        templates  => $self->templates,
        tablename => $tablename,
    );
    my $result = $sql_stmt->create_sql();
    return $result;
}

sub fill_template($self, $name, $fields, $foreignkeys, $indexes, $sql) {
    my $template = $self->templates->get_data_section('table');
    $template =~ s/<<fields>>/$fields/ig;
    $template =~ s/<<tablename>>/$name/ig;
    if(exists($foreignkeys->{template_fkey})) {
        $template =~ s/<<foregin_keys>>/$foreignkeys->{template_fkey}/ig;
    } else {
        $template =~ s/<<foregin_keys>>//ig;
    }
    if(exists($foreignkeys->{template_ind})) {
        $indexes .= "" . $foreignkeys->{template_ind};
    }

    $template =~ s/<<indexes>>/$indexes/ig;
    $template =~ s/<<sql>>/$sql/ig;

    return $template;
}

sub create_fields($self, $json) {
    my $fields = Daje::Workflow::GenerateSQL::Script::Fields->new(
        json     => $json,
        templates => $self->templates,
        error    => $self->error,
    );

    $fields->create_fields();
    my $sql = $fields->sql;

    return $sql;
}

sub create_index($self, $json) {
    my $test = 1;
    my $templates= $self->templates;
    my $index = Daje::Workflow::GenerateSQL::Script::Index->new(
        json      => $json,
        templates  => $templates,
        tablename => $json->{name},
        error    => $self->error,
    );

    $index->create_index();
    my $sql = $index->sql;
    return $sql;
}

sub create_fkeys($self, $json, $table_name) {
    my $foreign_keys = {};
    my $foreign_key = Daje::Workflow::GenerateSQL::Script::ForeignKey->new(
        json      => $json,
        templates  => $self->templates,
        tablename => $table_name,
        error    => $self->error,
    );
    $foreign_key->create_foreign_keys();
    if ($foreign_key->created() == 1) {
        $foreign_keys = $foreign_key->templates();
    }
    return $foreign_keys;
}




1;












#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

Daje::Workflow::GenerateSQL::Manager::Sql


=head1 DESCRIPTION

Daje::Generate::Sql::SqlManager  Generatee Database and table related SQL scripts from JSON file



=head1 REQUIRES

L<Daje::Generate::Sql::SqlManager> 

L<Daje::Workflow::GenerateSQL::Script::Sql> 

L<Daje::Workflow::GenerateSQL::Script::ForeignKey> 

L<Daje::Workflow::GenerateSQL::Script::Index> 

L<Daje::Workflow::GenerateSQL::Script::Fields> 

L<Mojo::Base> 


=head1 METHODS

$table->generate_table();
my $script = $table->sql();




=head1 Synopsis


use Daje::Generate::Sql::SqlManager;

my $table = Daje::Generate::Sql::SqlManager->new(
      json        => $json,
      template    => $template,
);



=head1 AUTHOR

Jan Eskilsson



=head1 COPYRIGHT

Copyright (C) 2024 Jan Eskilsson.



=head1 LICENSE

Daje::Generate::Sql::SqlManager  (the distribution) is licensed under the same terms as Perl.



=cut


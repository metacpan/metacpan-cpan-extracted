use v5.40;
use feature 'class';
no warnings 'experimental::class';

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

class Daje::Generate::Sql::SqlManager :isa(Daje::Generate::Sql::Base::Common) {
use Daje::Generate::Sql::Script::Fields;
use Daje::Generate::Sql::Script::Index;
use Daje::Generate::Sql::Script::ForeignKey;
use Daje::Generate::Sql::Script::Sql;

    method generate_table() {
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

    method _version($version) {
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

    method create_file($sections) {
        my $file = $self->template->get_data_section('file');
        my $date = localtime();
        $file =~ s/<<date>>/$date/ig;
        $file =~ s/<<sections>>/$sections/ig;

        return $file;
    }

    method create_section($sql, $number) {
        my $section = $self->template->get_data_section('section');
        $section =~ s/<<version>>/$number/ig;
        $section =~ s/<<table>>/$sql/ig;
        return $section;
    }

    method create_table_sql($table) {
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

    method create_sql($json, $tablename) {
        my $sql_stmt = Daje::Generate::Sql::SqlManager::Sql->new(
            json      => $json,
            template  => $self->template,
            tablename => $tablename,
        );
        my $result = $sql_stmt->create_sql();
        return $result;
    }

    method fill_template($name, $fields, $foreignkeys, $indexes, $sql) {
        my $template = $self->template->get_data_section('table');
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

    method create_fields($json) {
        my $fields = Daje::Generate::Sql::Script::Fields->new(
            json     => $json,
            template => $self->template,
        );

        $fields->create_fields();
        my $sql = $fields->sql;

        return $sql;
    }

    method create_index($json) {
        my $test = 1;
        my $template = $self->template;
        my $index = Daje::Generate::Sql::Script::Index->new(
            json      => $json,
            template  => $template,
            tablename => $json->{name},
        );

        $index->create_index();
        my $sql = $index->sql;
        return $sql;
    }

    method create_fkeys($json, $table_name) {
        my $foreignkeys = {};
        my $foreign_key = Daje::Generate::Sql::Script::ForeignKey->new(
            json      => $json,
            template  => $self->template,
            tablename => $table_name,
        );
        $foreign_key->create_foreign_keys();
        if ($foreign_key->created() == 1) {
            $foreignkeys = $foreign_key->templates();
        }
        return $foreignkeys;
    }
}




1;









#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME

lib::Daje::Generate::Sql::SqlManager - lib::Daje::Generate::Sql::SqlManager


=head1 DESCRIPTION

Daje::Generate::Sql::SqlManager  Generatee Database and table related SQL scripts from JSON file



=head1 REQUIRES

L<Daje::Generate::Sql::SqlManager> 

L<Daje::Generate::Sql::Script::Sql> 

L<Daje::Generate::Sql::Script::ForeignKey> 

L<Daje::Generate::Sql::Script::Index> 

L<Daje::Generate::Sql::Script::Fields> 

L<feature> 

L<v5.40> 


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


package Daje::Workflow::GenerateSQL::Script::View;
use Mojo::Base 'Daje::Workflow::GenerateSQL::Base::Common', -base, -signatures;


sub generate($self) {

    my $data = $self->json;
    my $name = $data->{name};
    my $fields = $self->_fields($data);
    my $tables = $self->_tables($data);
    my $conditions = $self->_conditions($data);

    my $template = $self->templates->get_data_section('view');
    $template =~ s/<<<name>>>/$name/;
    $template =~ s/<<<tables>>>/$tables/;
    $template =~ s/<<<fields>>>/$fields/;
    $template =~ s/<<<conditions>>>/$conditions/;

    return $template;
}

sub _conditions($self, $data) {
    my $conditions = "";
    my $length = scalar @{$data->{conditions}};
    for(my $i = 0; $i < $length; $i++) {
        if(!length($conditions)) {
            $conditions = @{$data->{conditions}}[$i]->{condition};
            if($i < $length - 1 and length(@{$data->{conditions}}[$i]->{conditionals})) {
                $conditions .= ' ' . @{$data->{conditions}}[$i]->{conditionals}
            }
        } else {
            $conditions .= ' ' . @{$data->{conditions}}[$i]->{condition};
            if($i < $length - 1 and length(@{$data->{conditions}}[$i]->{conditionals})) {
                $conditions .= ' ' . @{$data->{conditions}}[$i]->{conditionals}
            }
        }
    }
    return $conditions;
}

sub _tables($self, $data) {
    my $tables = "";
    my $length = scalar @{$data->{tables}};
    for(my $i = 0; $i < $length; $i++) {
        if(!length($tables)) {
            $tables = @{$data->{tables}}[$i]->{table_name};
        } else {
            $tables .= ', ' . @{$data->{tables}}[$i]->{table_name};;
        }
    }
    return $tables;
}

sub _fields($self, $data) {

    my $fields = "";
    while(my($key, $value) = each %{$data->{fields}}) {
        if(!length($fields)) {
            if($value eq $key) {
                $fields = $key;
            } else {
                $fields = $value . ' as ' . $key;
            }
        } else {
            if($value eq $key) {
                $fields .= ', ' . $key;
            } else {
                $fields .= ', ' . $value . ' as ' . $key;
            }
        }
    }
    return $fields;
}

1;
package DB::Introspector::ForeignKeyPath;


use strict;


sub new {
    my $class = shift;

    return bless([], ref($class) || $class);
}

sub get_foreign_key_list {
    my $self = shift;
    return @$self;
}

sub clone {
    my $self = shift;
    my @new_path = @$self;
    return bless(\@new_path, ref($self) || $self);
}

sub append_foreign_key {
    my $self = shift;
    my $foreign_key = shift;

    push(@$self, $foreign_key);
}

sub prepend_foreign_key {
    my $self = shift;
    my $foreign_key = shift;

    unshift(@$self, $foreign_key);
}


sub append_path {
    my $self = shift;
    my $path = shift;
    push(@$self, $path->_to_array);
}

sub prepend_path {
    my $self = shift;
    my $path = shift;
    unshift(@$self, $path->_to_array);
}

sub length {
    my $self = shift;
    return scalar(@$self);
}

sub head {
    my $self = shift;
    return $self->[0];
}

sub tail {
    my $self = shift;
    return $self->[$#$self];
}

sub _to_array {
    my $self = shift;
    return @$self;
}

sub head_table {
    my $self = shift;
    return ($self->head->is_dependency) 
                ? $self->head->local_table : $self->head->foreign_table;
}

sub head_columns {
    my $self = shift;
    $self->head->foreign_column_names;
}

sub tail_table {
    my $self = shift;
    return ($self->tail->is_dependency) 
                ? $self->tail->foreign_table : $self->tail->local_table;
}

sub tail_columns {
    my $self = shift;
    $self->tail->local_column_names;
}


1;

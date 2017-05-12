package DB::Introspector::MappedPath;

use strict;
use base qw( DB::Introspector::ForeignKeyPath );

sub head_column_names {
    my $self = shift;

    my @foreign_keys = $self->get_foreign_key_list;
    return $foreign_keys[0]->foreign_column_names;
}

sub tail_column_names {
    my $self = shift;

    my @foreign_keys = $self->get_foreign_key_list;
    return $foreign_keys[$#foreign_keys]->local_column_names;
}

sub head_table {
    my $self = shift;

    my @foreign_keys = $self->get_foreign_key_list;
    return $foreign_keys[0]->foreign_table;
}

sub tail_table {
    my $self = shift;

    my @foreign_keys = $self->get_foreign_key_list;
    return $foreign_keys[$#foreign_keys]->local_table;
}


sub head_for_tail_column {
    my $self = shift;
    my $tail_column_name = shift;

    foreach my $foreign_key (reverse $self->get_foreign_key_list) {
        $tail_column_name = 
            $foreign_key->foreign_for_local_column($tail_column_name);
        return undef unless(defined $tail_column_name);
    }

    return $tail_column_name;
}

sub tail_for_head_column {
    my $self = shift;
    my $head_column_name = shift;

    foreach my $foreign_key ($self->get_foreign_key_list) {
        $head_column_name = 
            $foreign_key->local_for_foreign_column($head_column_name);
        return undef unless(defined $head_column_name);
    }

    return $head_column_name;
}

1;

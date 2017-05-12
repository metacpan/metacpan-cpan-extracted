package DB::Introspector::SQLGen::Oracle::TypeMapper;

use strict;
use base qw( DB::Introspector::SQLGen::TypeMapper );


sub stringify_integer {
    my $self = shift;
    my $column = shift;


    # oracle integers can be limited by the number of characters in its decimal
    # representation.
    my $max_length = $column->max;

    # TODO: add support for providing further limitations on the acceptable
    # integers

    return 'NUMBER'. (defined($max_length) ? '('.length($max_length).')' : '');
}

sub stringify_string {
    my $self = shift;
    my $column = shift;

    my $max_length = $column->max_length;

    # TODO: add support for providing further limitations on the acceptable
    # integers

    return 'VARCHAR2'. (defined($max_length) ? "($max_length)" : '');
}

sub stringify_date {
    my $self = shift;
    my $column = shift;

    return 'DATE';
}

sub stringify_clob {
    my $self = shift;
    my $column = shift;

    return 'CLOB';
}


sub stringify_char {
    my $self = shift;
    my $column = shift;

    # TODO: add support for a specific set of characters
    return 'CHAR';
}

sub stringify_boolean {
    my $self = shift;
    my $column = shift;

    # TODO: add support for better boolean simulation
    return 'CHAR';
}


1;

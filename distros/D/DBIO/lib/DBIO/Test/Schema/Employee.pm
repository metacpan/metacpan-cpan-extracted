package DBIO::Test::Schema::Employee;
# ABSTRACT: Test result class for the employee table with ordering

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->load_components(qw( Ordered ));

__PACKAGE__->table('employee');

__PACKAGE__->add_columns(
    employee_id => {
        data_type => 'integer',
        is_auto_increment => 1
    },
    position => {
        data_type => 'integer',
        position  => 1,
    },
    group_id => {
        data_type => 'integer',
        is_nullable => 1,
    },
    group_id_2 => {
        data_type => 'integer',
        is_nullable => 1,
    },
    group_id_3 => {
        data_type => 'integer',
        is_nullable => 1,
    },
    name => {
        data_type => 'varchar',
        size      => 100,
        is_nullable => 1,
    },
    encoded => {
        data_type => 'integer',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('employee_id');

# Do not add unique constraints here - different groups are used throughout
# the ordered tests

__PACKAGE__->belongs_to (secretkey => 'DBIO::Test::Schema::Encoded', 'encoded', {
  join_type => 'left'
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Employee - Test result class for the employee table with ordering

=head1 VERSION

version 0.900001

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

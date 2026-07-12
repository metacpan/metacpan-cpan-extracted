package DBIO::Test::Schema::Dummy;
# ABSTRACT: Test result class for the dummy table

use strict;
use warnings;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('dummy');
__PACKAGE__->add_columns(
    'id' => {
        data_type => 'integer',
        is_auto_increment => 1
    },
    'gittery' => {
        data_type => 'varchar',
        size      => 100,
        is_nullable => 1,
    },
);
__PACKAGE__->set_primary_key('id');

# part of a test, do not remove
__PACKAGE__->sequence('bogus');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Dummy - Test result class for the dummy table

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

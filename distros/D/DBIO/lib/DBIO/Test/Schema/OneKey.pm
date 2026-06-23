package DBIO::Test::Schema::OneKey;
# ABSTRACT: Test result class for the onekey table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('onekey');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'artist' => {
    data_type => 'integer',
  },
  'cd' => {
    data_type => 'integer',
  },
);
__PACKAGE__->set_primary_key('id');


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::OneKey - Test result class for the onekey table

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

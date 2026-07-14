package DBIO::Test::Schema::FourKeys;
# ABSTRACT: Test result class for the fourkeys table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('fourkeys');
__PACKAGE__->add_columns(
  'foo' => { data_type => 'integer' },
  'bar' => { data_type => 'integer' },
  'hello' => { data_type => 'integer' },
  'goodbye' => { data_type => 'integer' },
  'sensors' => { data_type => 'character', size => 10 },
  'read_count' => { data_type => 'int', is_nullable => 1 },
);
__PACKAGE__->set_primary_key(qw/foo bar hello goodbye/);

__PACKAGE__->has_many(
  'fourkeys_to_twokeys', 'DBIO::Test::Schema::FourKeys_to_TwoKeys', {
    'foreign.f_foo' => 'self.foo',
    'foreign.f_bar' => 'self.bar',
    'foreign.f_hello' => 'self.hello',
    'foreign.f_goodbye' => 'self.goodbye',
});

__PACKAGE__->many_to_many(
  'twokeys', 'fourkeys_to_twokeys', 'twokeys',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::FourKeys - Test result class for the fourkeys table

=head1 VERSION

version 0.900002

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

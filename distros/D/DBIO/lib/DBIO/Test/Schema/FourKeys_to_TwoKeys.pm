package DBIO::Test::Schema::FourKeys_to_TwoKeys;
# ABSTRACT: Test result class for the fourkeys_to_twokeys table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('fourkeys_to_twokeys');
__PACKAGE__->add_columns(
  'f_foo' => { data_type => 'integer' },
  'f_bar' => { data_type => 'integer' },
  'f_hello' => { data_type => 'integer' },
  'f_goodbye' => { data_type => 'integer' },
  't_artist' => { data_type => 'integer' },
  't_cd' => { data_type => 'integer' },
  'autopilot' => { data_type => 'character' },
  'pilot_sequence' => { data_type => 'integer', is_nullable => 1 },
);
__PACKAGE__->set_primary_key(
  qw/f_foo f_bar f_hello f_goodbye t_artist t_cd/
);

__PACKAGE__->belongs_to('fourkeys', 'DBIO::Test::Schema::FourKeys', {
  'foreign.foo' => 'self.f_foo',
  'foreign.bar' => 'self.f_bar',
  'foreign.hello' => 'self.f_hello',
  'foreign.goodbye' => 'self.f_goodbye',
});

__PACKAGE__->belongs_to('twokeys', 'DBIO::Test::Schema::TwoKeys', {
  'foreign.artist' => 'self.t_artist',
  'foreign.cd' => 'self.t_cd',
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::FourKeys_to_TwoKeys - Test result class for the fourkeys_to_twokeys table

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

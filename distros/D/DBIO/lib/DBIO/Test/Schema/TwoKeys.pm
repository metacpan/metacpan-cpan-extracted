package DBIO::Test::Schema::TwoKeys;
# ABSTRACT: Test result class for the twokeys table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('twokeys');
__PACKAGE__->add_columns(
  'artist' => { data_type => 'integer' },
  'cd' => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key(qw/artist cd/);

__PACKAGE__->belongs_to(
    artist => 'DBIO::Test::Schema::Artist',
    {'foreign.artistid'=>'self.artist'},
);

__PACKAGE__->belongs_to( cd => 'DBIO::Test::Schema::CD', undef, { is_deferrable => 0, on_update => undef, on_delete => undef, add_fk_index => 0 } );

__PACKAGE__->has_many(
  'fourkeys_to_twokeys', 'DBIO::Test::Schema::FourKeys_to_TwoKeys', {
    'foreign.t_artist' => 'self.artist',
    'foreign.t_cd' => 'self.cd',
});

__PACKAGE__->many_to_many(
  'fourkeys', 'fourkeys_to_twokeys', 'fourkeys',
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::TwoKeys - Test result class for the twokeys table

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

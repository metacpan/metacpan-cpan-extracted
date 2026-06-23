package DBIO::Test::Schema::Artwork;
# ABSTRACT: Test result class for the cd_artwork table

use warnings;
use strict;

use base 'DBIO::Test::BaseResult';
use DBIO::Test::Util 'check_customcond_args';

__PACKAGE__->table('cd_artwork');
__PACKAGE__->add_columns(
  'cd_id' => {
    data_type => 'integer',
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key('cd_id');
__PACKAGE__->belongs_to('cd', 'DBIO::Test::Schema::CD', 'cd_id');
__PACKAGE__->has_many('images', 'DBIO::Test::Schema::Image', 'artwork_id');

__PACKAGE__->has_many('artwork_to_artist', 'DBIO::Test::Schema::Artwork_to_Artist', 'artwork_cd_id');
__PACKAGE__->many_to_many('artists', 'artwork_to_artist', 'artist');

# both to test manytomany with custom rel
__PACKAGE__->many_to_many('artists_test_m2m', 'artwork_to_artist', 'artist_test_m2m');
__PACKAGE__->many_to_many('artists_test_m2m_noopt', 'artwork_to_artist', 'artist_test_m2m_noopt');

# other test to manytomany
__PACKAGE__->has_many('artwork_to_artist_test_m2m', 'DBIO::Test::Schema::Artwork_to_Artist',
  sub {
    # This is for test purposes only. A regular user does not
    # need to sanity check the passed-in arguments, this is what
    # the tests are for :)
    my $args = &check_customcond_args;

    return (
      { "$args->{foreign_alias}.artwork_cd_id" => { -ident => "$args->{self_alias}.cd_id" },
      },
      $args->{self_result_object} && {
        "$args->{foreign_alias}.artwork_cd_id" => $args->{self_result_object}->cd_id,
      }
    );
  }
);
__PACKAGE__->many_to_many('artists_test_m2m2', 'artwork_to_artist_test_m2m', 'artist');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Artwork - Test result class for the cd_artwork table

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

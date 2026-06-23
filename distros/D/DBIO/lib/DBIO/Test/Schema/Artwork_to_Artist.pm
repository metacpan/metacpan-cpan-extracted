package DBIO::Test::Schema::Artwork_to_Artist;
# ABSTRACT: Test result class for the artwork_to_artist table

use warnings;
use strict;

use base 'DBIO::Test::BaseResult';
use DBIO::Test::Util 'check_customcond_args';

__PACKAGE__->table('artwork_to_artist');
__PACKAGE__->add_columns(
  'artwork_cd_id' => {
    data_type => 'integer',
    is_foreign_key => 1,
  },
  'artist_id' => {
    data_type => 'integer',
    is_foreign_key => 1,
  },
);
__PACKAGE__->set_primary_key(qw/artwork_cd_id artist_id/);
__PACKAGE__->belongs_to('artwork', 'DBIO::Test::Schema::Artwork', 'artwork_cd_id');
__PACKAGE__->belongs_to('artist', 'DBIO::Test::Schema::Artist', 'artist_id');

__PACKAGE__->belongs_to('artist_test_m2m', 'DBIO::Test::Schema::Artist',
  sub {
    # This is for test purposes only. A regular user does not
    # need to sanity check the passed-in arguments, this is what
    # the tests are for :)
    my $args = &check_customcond_args;

    return (
      { "$args->{foreign_alias}.artistid" => { -ident => "$args->{self_alias}.artist_id" },
        "$args->{foreign_alias}.rank"     => { '<' => 10 },
      },
      $args->{self_result_object} && {
        "$args->{foreign_alias}.artistid" => $args->{self_result_object}->artist_id,
        "$args->{foreign_alias}.rank"   => { '<' => 10 },
      }
    );
  }
);

__PACKAGE__->belongs_to('artist_test_m2m_noopt', 'DBIO::Test::Schema::Artist',
  sub {
    # This is for test purposes only. A regular user does not
    # need to sanity check the passed-in arguments, this is what
    # the tests are for :)
    my $args = &check_customcond_args;

    return (
      { "$args->{foreign_alias}.artistid" => { -ident => "$args->{self_alias}.artist_id" },
        "$args->{foreign_alias}.rank"     => { '<' => 10 },
      }
    );
  }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Artwork_to_Artist - Test result class for the artwork_to_artist table

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

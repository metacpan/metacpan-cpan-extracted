package DBIO::Test::Schema::Artist;
# ABSTRACT: Test result class for the artist table

use warnings;
use strict;

use base 'DBIO::Test::BaseResult';
use DBIO::Test::Util 'check_customcond_args';

__PACKAGE__->table('artist');
__PACKAGE__->source_info({
    "source_info_key_A" => "source_info_value_A",
    "source_info_key_B" => "source_info_value_B",
    "source_info_key_C" => "source_info_value_C",
});
__PACKAGE__->add_columns(
  'artistid' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
    is_nullable => 1,
  },
  rank => {
    data_type => 'integer',
    default_value => 13,
  },
  charfield => {
    data_type => 'char',
    size => 10,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('artistid');
__PACKAGE__->add_unique_constraint(['name']);
__PACKAGE__->add_unique_constraint(artist => ['artistid']); # do not remove, part of a test
__PACKAGE__->add_unique_constraint(u_nullable => [qw/charfield rank/]);


__PACKAGE__->mk_classdata('field_name_for', {
    artistid    => 'primary key',
    name        => 'artist name',
});

# the undef condition in this rel is *deliberate*
# tests oddball legacy syntax
__PACKAGE__->has_many(
    cds => 'DBIO::Test::Schema::CD', undef,
    { order_by => { -asc => 'year'} },
);

__PACKAGE__->has_many(
  cds_cref_cond => 'DBIO::Test::Schema::CD',
  sub {
    # This is for test purposes only. A regular user does not
    # need to sanity check the passed-in arguments, this is what
    # the tests are for :)
    my $args = &check_customcond_args;

    return (
      { "$args->{foreign_alias}.artist" => { '=' => { -ident => "$args->{self_alias}.artistid"} },
      },
      $args->{self_result_object} && {
        "$args->{foreign_alias}.artist" => $args->{self_rowobj}->artistid,  # keep old rowobj syntax as a test
      }
    );
  },
);

__PACKAGE__->has_many(
  cds_80s => 'DBIO::Test::Schema::CD',
  sub {
    # This is for test purposes only. A regular user does not
    # need to sanity check the passed-in arguments, this is what
    # the tests are for :)
    my $args = &check_customcond_args;

    return (
      { "$args->{foreign_alias}.artist" => { '=' => \ "$args->{self_alias}.artistid" },
        "$args->{foreign_alias}.year"   => { '>' => 1979, '<' => 1990 },
      },
      $args->{self_result_object} && {
        "$args->{foreign_alias}.artist" => { '=' => \[ '?',  $args->{self_result_object}->artistid ] },
        "$args->{foreign_alias}.year"   => { '>' => 1979, '<' => 1990 },
      }
    );
  },
);


__PACKAGE__->has_many(
  cds_84 => 'DBIO::Test::Schema::CD',
  sub {
    # This is for test purposes only. A regular user does not
    # need to sanity check the passed-in arguments, this is what
    # the tests are for :)
    my $args = &check_customcond_args;

    return (
      { "$args->{foreign_alias}.artist" => { -ident => "$args->{self_alias}.artistid" },
        "$args->{foreign_alias}.year"   => 1984,
      },
      $args->{self_result_object} && {
        "$args->{foreign_alias}.artist" => $args->{self_result_object}->artistid,
        "$args->{foreign_alias}.year"   => 1984,
      }
    );
  }
);


__PACKAGE__->has_many(
  cds_90s => 'DBIO::Test::Schema::CD',
  sub {
    # This is for test purposes only. A regular user does not
    # need to sanity check the passed-in arguments, this is what
    # the tests are for :)
    my $args = &check_customcond_args;

    return (
      { "$args->{foreign_alias}.artist" => { -ident => "$args->{self_alias}.artistid" },
        "$args->{foreign_alias}.year"   => { '>' => 1989, '<' => 2000 },
      }
    );
  }
);


__PACKAGE__->has_many(
    cds_unordered => 'DBIO::Test::Schema::CD'
);
__PACKAGE__->has_many(
    cds_very_very_very_long_relationship_name => 'DBIO::Test::Schema::CD'
);

__PACKAGE__->has_many( twokeys => 'DBIO::Test::Schema::TwoKeys' );
__PACKAGE__->has_many( onekeys => 'DBIO::Test::Schema::OneKey' );

__PACKAGE__->has_many(
  artist_undirected_maps => 'DBIO::Test::Schema::ArtistUndirectedMap',
  [ {'foreign.id1' => 'self.artistid'}, {'foreign.id2' => 'self.artistid'} ],
  { cascade_copy => 0 } # this would *so* not make sense
);

__PACKAGE__->has_many(
    artwork_to_artist => 'DBIO::Test::Schema::Artwork_to_Artist' => 'artist_id'
);
__PACKAGE__->many_to_many('artworks', 'artwork_to_artist', 'artwork');

__PACKAGE__->has_many(
    cds_without_genre => 'DBIO::Test::Schema::CD',
    sub {
        # This is for test purposes only. A regular user does not
        # need to sanity check the passed-in arguments, this is what
        # the tests are for :)
        my $args = &check_customcond_args;

        return (
          {
            "$args->{foreign_alias}.artist" => { -ident => "$args->{self_alias}.artistid" },
            "$args->{foreign_alias}.genreid" => undef,
          }, $args->{self_result_object} && {
            "$args->{foreign_alias}.artist" => $args->{self_result_object}->artistid,
            "$args->{foreign_alias}.genreid" => undef,
          }
        ),
    },
);

sub sqlt_deploy_hook {
  my ($self, $sqlt_table) = @_;

  if ($sqlt_table->schema->translator->producer_type =~ /SQLite$/ ) {
    $sqlt_table->add_index( name => 'artist_name_hookidx', fields => ['name'] )
      or die $sqlt_table->error;
  }
}

sub store_column {
  my ($self, $name, $value) = @_;
  $value = 'X '.$value if ($name eq 'name' && $value && $value =~ /(X )?store_column test/);
  $self->next::method($name, $value);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Artist - Test result class for the artist table

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

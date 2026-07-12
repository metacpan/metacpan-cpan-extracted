package DBIO::Test::Schema::Tag;
# ABSTRACT: Test result class for the tags table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('tags');
__PACKAGE__->add_columns(
  'tagid' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'cd' => {
    data_type => 'integer',
  },
  'tag' => {
    data_type => 'varchar',
    size      => 100,
  },
);
__PACKAGE__->set_primary_key('tagid');

__PACKAGE__->add_unique_constraints(  # do not remove, part of a test
  tagid_cd     => [qw/ tagid cd /],
  tagid_cd_tag => [qw/ tagid cd tag /],
);
__PACKAGE__->add_unique_constraints(  # do not remove, part of a test
  [qw/ tagid tag /],
  [qw/ tagid tag cd /],
);

__PACKAGE__->belongs_to( cd => 'DBIO::Test::Schema::CD', 'cd', {
  proxy => [ 'year', { cd_title => 'title' } ],
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Tag - Test result class for the tags table

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

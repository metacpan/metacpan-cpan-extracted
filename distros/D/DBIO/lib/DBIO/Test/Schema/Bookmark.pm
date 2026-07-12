package DBIO::Test::Schema::Bookmark;
# ABSTRACT: Test result class for the bookmark table

use strict;
use warnings;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('bookmark');
__PACKAGE__->add_columns(
    'id' => {
        data_type => 'integer',
        is_auto_increment => 1
    },
    'link' => {
        data_type => 'integer',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');

require DBIO::Test::Schema::Link; # so we can get a columnlist
__PACKAGE__->belongs_to(
    link => 'DBIO::Test::Schema::Link', 'link', {
    on_delete => 'SET NULL',
    join_type => 'LEFT',
    proxy => { map { join('_', 'link', $_) => $_ } DBIO::Test::Schema::Link->columns },
});

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Schema::Bookmark - Test result class for the bookmark table

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

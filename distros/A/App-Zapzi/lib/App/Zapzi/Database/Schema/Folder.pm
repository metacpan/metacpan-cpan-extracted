package App::Zapzi::Database::Schema::Folder;
# ABSTRACT: zapzi folder table

use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use base 'DBIx::Class::Core';


__PACKAGE__->table("folders");


__PACKAGE__->add_columns
(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "name",
    { data_type => "text", default_value => "Unknown", is_nullable => 0 },
);


__PACKAGE__->set_primary_key("id");


__PACKAGE__->add_unique_constraint("name_unique", ["name"]);


__PACKAGE__->has_many(articles =>
                      'App::Zapzi::Database::Schema::Article',
                      'folder');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Database::Schema::Folder - zapzi folder table

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This module defines the schema for the folders table in the Zapzi
database.

=head1 ACCESSORS

=head2 id

  Unique ID for this folder
  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  Name of this folder
  data_type: 'text'
  default_value: 'Unknown'
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=head1 UNIQUE CONSTRAINTS

=head2 C<name_unique>

=over 4

=item * L</name>

=back

=head1 RELATIONSHIPS

=head2 Has many

=over 4

=item * articles (-> Article)

=back

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

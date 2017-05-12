package App::Zapzi::Database::Schema::Article;
# ABSTRACT: zapzi article table

use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use base 'DBIx::Class::Core';
use DateTime::Format::SQLite;
__PACKAGE__->load_components(qw/InflateColumn::DateTime/);


__PACKAGE__->table("articles");


__PACKAGE__->add_columns
(
    "id",
    { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
    "title",
    { data_type => "text", default_value => "Unknown", is_nullable => 0 },
    "folder",
    { data_type => "integer", is_nullable => 0 },
    "created",
    { data_type => 'datetime', is_nullable => 0,
      default_value => \"(datetime('now', 'localtime'))" },
    "source",
    { data_type => "text", default_value => "", is_nullable => 0 },
);


__PACKAGE__->set_primary_key("id");


__PACKAGE__->belongs_to(folder => 'App::Zapzi::Database::Schema::Folder',
                        'folder');

__PACKAGE__->might_have(article_text =>
                        'App::Zapzi::Database::Schema::ArticleText',
                        'id');
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Database::Schema::Article - zapzi article table

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This module defines the schema for the articles table in the Zapzi
database.

=head1 ACCESSORS

=head2 id

  Unique ID for this article
  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  Title of this book.
  data_type: 'text'
  default_value: 'Unknown'
  is_nullable: 0

=head2 folder

  FK to folders
  data_type: 'integer'
  is_nullable: 0

=head2 created

  Date/time article was created
  data_type: 'datetime'
  default_value: datetime('now','localtime')
  is_nullable: 0

=head2 source

  Source of the article, eg filename or URL
  data_type: 'text'
  default_value: ''
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=head1 RELATIONSHIPS

=head2 Belongs to

=over 4

=item * folder (-> Folder)

=back

=head2 Might have

=over 4

=item * article_text (-> ArticleText)

=back

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

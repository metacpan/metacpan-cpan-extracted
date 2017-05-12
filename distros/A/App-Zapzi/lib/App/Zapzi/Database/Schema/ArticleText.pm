package App::Zapzi::Database::Schema::ArticleText;
# ABSTRACT: zapzi article_text table

use utf8;
use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use base 'DBIx::Class::Core';


__PACKAGE__->table("article_text");


__PACKAGE__->add_columns
(
    "id",
    { data_type => "integer", is_nullable => 0 },
    "text",
    { data_type => "blob", default_value => "", is_nullable => 0 },
);


__PACKAGE__->set_primary_key("id");


__PACKAGE__->belongs_to(article => 'App::Zapzi::Database::Schema::Article',
                        'id');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Database::Schema::ArticleText - zapzi article_text table

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This module defines the schema for the article_text table in the Zapzi
database.

=head1 ACCESSORS

=head2 id

  FK to articles
  data_type: 'integer'
  is_nullable: 0

=head2 text

  Body of the article
  data_type: 'blob'
  default_value: ''
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</article_id>

=back

=head1 RELATIONSHIPS

=head2 Has one

=over 4

=item * article (-> Article)

=back

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

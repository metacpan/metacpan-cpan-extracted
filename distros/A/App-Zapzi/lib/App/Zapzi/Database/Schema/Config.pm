package App::Zapzi::Database::Schema::Config;
# ABSTRACT: zapzi config table

use strict;
use warnings;

our $VERSION = '0.017'; # VERSION

use base 'DBIx::Class::Core';


__PACKAGE__->table("config");


__PACKAGE__->add_columns
(
    "name",
    { data_type => "text", is_nullable => 0 },
    "value",
    { data_type => "text", default_value => '', is_nullable => 0 },
);


__PACKAGE__->set_primary_key("name");



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Zapzi::Database::Schema::Config - zapzi config table

=head1 VERSION

version 0.017

=head1 DESCRIPTION

This module defines the schema for the config table in the Zapzi
database.

=head1 ACCESSORS

=head2 name

  Unique ID for this config item
  data_type: 'text'
  is_nullable: 0

=head2 value

  Value of this config item
  data_type: 'text'
  default_value: ''
  is_nullable: 0

=head1 PRIMARY KEY

=over 4

=item * L</name>

=back

=head1 UNIQUE CONSTRAINTS

None

=head1 RELATIONSHIPS

None

=head1 AUTHOR

Rupert Lane <rupert@rupert-lane.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rupert Lane.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package DBIx::Class::Helper::Row::RelationshipDWIM;
$DBIx::Class::Helper::Row::RelationshipDWIM::VERSION = '2.036000';
# ABSTRACT: Type less for your relationships!

use strict;
use warnings;

use parent 'DBIx::Class::Row';

sub default_result_namespace {
   die 'you forgot to set your default_result_namespace'
}

sub belongs_to {
  my ( $self, @args ) = @_;

  $args[1] =~ s/^::/$self->default_result_namespace . '::'/e;

  $self->next::method(@args);
}

sub has_many {
  my ( $self, @args ) = @_;

  $args[1] =~ s/^::/$self->default_result_namespace . '::'/e;

  $self->next::method(@args);
}

sub might_have {
  my ( $self, @args ) = @_;

  $args[1] =~ s/^::/$self->default_result_namespace . '::'/e;

  $self->next::method(@args);
}

sub has_one {
  my ( $self, @args ) = @_;

  $args[1] =~ s/^::/$self->default_result_namespace . '::'/e;

  $self->next::method(@args);
}

1;

__END__

=pod

=head1 NAME

DBIx::Class::Helper::Row::RelationshipDWIM - Type less for your relationships!

=head1 SYNOPSIS

Base clase:

 package MyApp::Schema::Result;

 use parent 'DBIx::Class::Core';

 __PACKAGE__->load_components('Helper::Row::RelationshipDWIM');

 sub default_result_namespace { 'MyApp::Schema::Result' }

 1;

Result class:

 package MyApp::Schema::Result::Foo;

 use parent 'MyApp::Schema::Result';

 # Define various class bits here

 # succinct relationship definition yeah!

 __PACKAGE__->has_many(friends => '::Person', 'foo_id');

 # or with DBIx::Class::Candy:
 has_many friends => '::Person', 'foo_id';

 1;

=head1 DESCRIPTION

This module prepends your C<default_result_namespace> to related objects if they
begin with C<::>.  Simple but handy.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

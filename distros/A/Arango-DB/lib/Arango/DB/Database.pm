# ABSTRACT: ArangoDB Database object

package Arango::DB::Database;
$Arango::DB::Database::VERSION = '0.002';
use warnings;
use strict;

sub new {
    my ($class, %opts) = @_;
    return bless {%opts} => $class;
}

sub list_collections {
    my ($self) = @_;
    return $self->{arango}->list_collections($self->{name});
}

sub create_collection {
    my ($self, $name) = @_;
    return $self->{arango}->_create_collection($self->{name}, $name);
}

sub delete_collection {
    my ($self, $name) = @_;
    return $self->{arango}->_delete_collection($self->{name}, $name);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Arango::DB::Database - ArangoDB Database object

=head1 VERSION

version 0.002

=head1 USAGE

This class should not be created directly. The L<Arango::DB> module is responsible for
creating instances of this object.

C<Arango::DB::Database> answers to the following methods:

=head2 C<list_collections>

   my $cols = $database->list_collections;

Returns an array reference to the collections available in the database.

=head2 C<create_collection>

   my $col = $database->create_collection("col_name");

Creates a new collection and returns the object representing it (L<Arango::DB::Collection>).

=head2 C<delete_collection>

   $database->delete_collection("col_name");

Deletes a collection.

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

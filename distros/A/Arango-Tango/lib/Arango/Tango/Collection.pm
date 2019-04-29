# ABSTRACT: ArangoDB Collection object
package Arango::Tango::Collection;
$Arango::Tango::Collection::VERSION = '0.009';
use warnings;
use strict;

sub _new {
    my ($class, %opts) = @_;
    return bless {%opts} => $class;
}

sub create_document {
    my ($self, $body) = @_;
    die "Arango::Tango | Refusing to store undefined body" unless defined($body);
    return $self->{arango}->_api('create_document', { database => $self->{database}, collection => $self->{name}, body => $body})
}

sub document_paths {
    my ($self) = @_;
    return $self->{arango}->_api('all_keys', { database => $self->{database}, collection => $self->{name}, type => "path"})->{result}
}

sub get_access_level {
    my ($self, $username) = @_;
    return $self->{arango}->get_access_level($self->{database}, $self->{name}, $username );
}

sub clear_access_level {
    my ($self, $username) = @_;
    return $self->{arango}->clear_access_level($self->{database}, $self->{name}, $username );
}

sub set_access_level {
    my ($self, $username, $grant) = @_;
    return $self->{arango}->set_access_level($self->{database}, $self->{name}, $username, $grant);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Arango::Tango::Collection - ArangoDB Collection object

=head1 VERSION

version 0.009

=head1 USAGE

This class should not be created directly. The L<Arango::Tango> module is responsible for
creating instances of this object.

C<Arango::Tango::Collection> answers to the following methods:

=head2 C<create_document>

   $collection->create_document( { 'Hello' => 'World' } );
   $collection->create_document( q!"{ "Hello": "World" }! );

Stores a document in specified collection

=head2 C<document_paths>

   my $paths = $collection->document_paths;

Lists all collection document as their paths in the database. Returns a hash reference.

=head2 C<get_access_level>

    my $perms = $db->get_access_level($user)

Fetch the collection access level for a specific user.

=head2 C<set_access_level>

    $db->set_access_level($user, 'none')

Sets the collection access level for a specific user.

=head2 C<clear_access_level>

    $db->clear_access_level($user, 'none')

Clears the collection access level for a specific user.

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

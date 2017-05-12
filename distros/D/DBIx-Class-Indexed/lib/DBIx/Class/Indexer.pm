package DBIx::Class::Indexer;

use strict;
use warnings;

=head1 NAME

DBIx::Class::Indexer - Base class for all indexers compatible with
DBIx::Class::Indexed.

=head1 SYNOPSIS
      
    package MySchema::Foo;
    
    use base qw( DBIx::Class );
    
    __PACKAGE__->load_components( qw( Indexed Core ) );
    __PACKAGE__->set_indexer( 'WebService::Lucene', { server => 'http://localhost:8080/lucene/' } );
    
    
=head1 DESCRIPTION

=head1 METHODS

=head2 new( \%connection_info, $class )

Constructs a new instance of this indexer. Passes the index connection
information and the table class driving the indexing.

=cut

sub new {
    die 'Need to implement new() subroutine';
}

=head2 insert( $object )

Handles the insert operation.

=cut

sub insert {
    die 'Need to implement insert() subroutine';
}

=head2 update( $object )

Handles the update operation.

=cut

sub update {
    die 'Need to implement update() subroutine';
}

=head2 delete( $object )

Handles the delete operation.

=cut

sub delete {
    die 'Need to implement delete() subroutine';
}

=head1 AUTHOR

=over 4

=item * Adam Paynter E<lt>adapay@cpan.orgE<gt>

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Adam Paynter, 2007-2011 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;

package DBIx::Changeset::Collection;

use warnings;
use strict;

use base qw/Class::Factory DBIx::Changeset/;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::Collection - Factory Interface to a collection of changeset files

=head1 SYNOPSIS

Factory Interface to a collection of changeset files

Perhaps a little code snippet.

    use DBIx::Changeset::Collection;

    my $foo = DBIx::Changeset::Collection->new('type', $opts);
    ...
	$foo->find_all();

=head1 ATTRIBUTES

=cut

my @ATTRS = qw/files current_index/;

__PACKAGE__->mk_accessors(@ATTRS);


=head1 INTERFACE

=head2 retrieve_all
	This is the find_all interface to implement in your own class
=cut
sub retrieve_all {
}



=head2 retrieve_like
	This is the find_like interface to implement in your own class
=cut
sub retrieve_like {
}

=head2 add_changeset
	This is the add_changeset interface implement in your own class
	creates a new record based on uri and adds to end of current file list
=cut
sub add_changeset {
}

=head1 METHODS

=head2 init
 Called automatically to intialise the factory objects takes params passed to new and assigns them to
 accessors if they exist
=cut

sub init {
	my ( $self, $params ) = @_;
	
	DBIx::Changeset::Exception::ObjectCreateException->throw( error => 'Attempt to create Collection Object without a changeset_location.' ) unless defined $params->{'changeset_location'};
	
	foreach my $field ( keys %{$params} ) {
		$self->{ $field } = $params->{ $field } if ( $self->can($field) );
	}
	return $self;
}

=head2 retrieve
	Retrieve a name file	
=cut
sub retrieve {
	my ($self, $uri) = @_;

	$self->retrieve_like(qr/$uri/xm);

	return;
}

=head2 next
	The next file
=cut
sub next {
	my $self = shift;
	if ( not defined $self->current_index ) {
		$self->current_index(0);
	} else {
		$self->current_index($self->current_index + 1);
	}
	return $self->files->[$self->current_index];
}

=head2 next_outstanding
	Returns the next file with an outstanding flag set
=cut
sub next_outstanding {
	my $self = shift;
	
	my $outstanding;
	while ( $outstanding = $self->next() ) {
		last if ( (defined $outstanding->outstanding()) && ($outstanding->outstanding() == 1) );
	}
	return $outstanding;
}

=head2 next_valid
	Returns the next file with a valid flag set
=cut
sub next_valid {
	my $self = shift;

	my $valid;
	while ( $valid = $self->next() ) {
		last if $valid->valid() == 1;
	}
	return $valid;

}

=head2 next_skipped
	Returns the next file with a skipped flag set
=cut
sub next_skipped {
	my $self = shift;

	my $skipped;
	while ( $skipped = $self->next() ) {
		last if $skipped->skipped() == 1;
	}
	return $skipped;
}

=head2 reset
	Returns to the first record in the collection
=cut
sub reset {
	my $self = shift;

	$self->current_index(undef);
	return;
}

=head2 total
	The total number of records
=cut
sub total {
	my $self = shift;

	return scalar(@{$self->files});
}

=head2 total_outstanding
	Returns the total number of records with outstanding flag set
=cut
sub total_outstanding {
	my $self = shift;

	my @total = grep { defined $_->outstanding && $_->outstanding == 1 } @{$self->files};

	return scalar(@total);
}

=head2 total_valid
	Returns the total number of records with valid flag set
=cut
sub total_valid {
	my $self = shift;

	my @total = grep { $_->valid == 1 } @{$self->files};

	return scalar(@total);
}

=head2 total_skipped
	Returns the total number of records with skipped flag set
=cut
sub total_skipped {
	my $self = shift;

	my @total = grep { defined $_->skipped && $_->skipped == 1 } @{$self->files};

	return scalar(@total);
}

=head1 TYPES
 Default types included

=head2 disk
	Simply reads files from disk expects a changeset_location of directories
=cut
__PACKAGE__->register_factory_type( disk => 'DBIx::Changeset::Collection::Disk' );

=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1; # End of DBIx::Changeset

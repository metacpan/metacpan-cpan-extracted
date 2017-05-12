package DataStore::CAS::FS::Dir;
use 5.008;
use strict;
use warnings;
use Carp;
use Try::Tiny;

our $VERSION= '0.010000';

# ABSTRACT: Object representing a directory of file entries, indexed by filename.


sub file     { $_[0]{file} }
sub store    { $_[0]{file}->store }
sub hash     { $_[0]{file}->hash }
sub size     { $_[0]{file}->size }

sub format   { $_[0]{format} }

sub metadata { $_[0]{metadata} } 


sub new {
	my $class= shift;
	my %p= (1 == @_ && ref $_[0] eq 'HASH')? %{$_[0]} : @_;
	defined $p{file} or croak "Attribute 'file' is required";
	defined $p{format} or croak "Attribute 'format' is required";
	$p{metadata} ||= {};
	$p{_entries}= delete $p{entries} || [];
	bless \%p, $class;
}


sub iterator {
	my $list= $_[0]{_entries};
	my ($i, $n)= (0, scalar @$list);
	return sub { $i < $n? $list->[$i++] : undef };
}

sub get_entry {
	my ($self, $name, $flags)= @_;
	return $flags->{case_insensitive}?
		($self->{_entry_name_map_caseless} ||= do {
			my (%lookup, $ent, $iter);
			for ($iter= $self->iterator; defined ($ent= $iter->()); ) {
				$lookup{uc $ent->name}= $ent
			}
			\%lookup;
		})->{uc $name}
		:
		($self->{_entry_name_map} ||= do {
			my (%lookup, $ent, $iter);
			for ($iter= $self->iterator; defined ($ent= $iter->()); ) {
				$lookup{$ent->name}= $ent
			}
			\%lookup;
		})->{$name};
}

1;

__END__

=pod

=head1 NAME

DataStore::CAS::FS::Dir - Object representing a directory of file entries, indexed by filename.

=head1 VERSION

version 0.011000

=head1 SYNOPSIS

  my $dir= DataStore::CAS::FS::Dir->new(
    file => $cas_file,
    format => $codec_name,
    entries => \@entries,
    metadata => $metadata
  );

=head1 DESCRIPTION

Directory objects have a very basic API of being able to fetch an entry by
name (optionally case-insensitive, as the user chooses), and iterate all
entries.

Directory objects are B<IMMUTABLE>, as are the L<DirEnt|DataStore::CAS::FS::DirEnt> objects they return.

=head1 ATTRIBUTES

=head2 file

Read-only, Required.  The L<DataStore::CAS::File> this directory was deserialized
from.

=head2 store

Alias for file->store

=head2 hash

Alias for file->hash

=head2 size

Alias for file->size

=head2 format

The format string that identifies this directory encoding.

=head2 metadata

A hashref of arbitrary name/value pairs attached to the directory at the time
it was written.  DO NOT MODIFY.  (In the future, this might be protected by
Perl's internal const mechanism)

=head1 METHODS

=head2 new

  $dir= $class->new( %params | \%params )

Create a new basic Dir object.  The required parameters are C<file>, and
C<format>.  C<metadata> will default to an empty hashref, and C<entries> will
default to an empty list.

The C<entries> parameter is not a public attribute, and is stored internally
as C<_entries>.  This is because not all subclasses will have an array of
entries available.  Use the method C<iterator> instead.

=head2 iterator

  $i= $dir->iterator;
  while (my $next= $i->()) { ... }

Returns an iterator over the entries in the directory.

The iterator is a coderef where each successive call returns the next L<DirEnt|DataStore::CAS::FS::DirEnt>.
Returns undef at the end of the list. Entries are not guaranteed to be in any
order, or even to be unique names.  (in particular, because of case
sensitivity rules)

=head2 get_entry

  $dirEnt= $dir->get_entry($name, %flags)

Get a directory entry by name.

If C<$flags{case_insensitive}> is true, then the directory will attempt to do a
case-folding lookup on the given name.  Note that all directories are
case-sensitive when written, and the case-insensitive feature is meant to help
emulate Windows-like behavior.  In other words, you might have two entries
that differ only by case, and the caseless lookup will pick one arbitrarily.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Conrad, and IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

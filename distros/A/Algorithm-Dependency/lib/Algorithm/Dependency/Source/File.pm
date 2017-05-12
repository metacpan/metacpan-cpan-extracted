package Algorithm::Dependency::Source::File;

=pod

=head1 NAME

Algorithm::Dependency::Source::File - File source for dependency heirachys

=head1 DESCRIPTION

Algorithm::Dependency::Source::File implements a
L<source|Algorithm::Dependency::Source> where the items are stored in a flat
file or a relatively simple format.

=head2 File Format

The file should be an ordinary text file, consisting of a series of lines,
with each line completely containing the information for a single item.
Blank lines, or lines beginning with the hash character '#' will be
ignored as comments.

For a single item line, only word characters will be used. A 'word character'
consists of all letters and numbers, and the underscore '_' character.
Anything that is not a word character will be assumed to be a seperator.

The first word will be used as the name or id of the item, and any further
words in the line will be used as other items that this one depends on. For
example, all of the following are legal.

  # A single item with no dependencies
  Foo

  # Another item that depends on the first one
  Bar Foo

  # Depending on multiple others
  Bin Foo Bar

  # We can use different seperators
  One:Two|Three-Four+Five=Six Seven

  # We can also use multiple non-word characters as seperators
  This&*&^*&File:  is& & & :::REALLY()Neat

From the examples above, it should be easy to create your own files.

=head1 METHODS

This documents the methods differing from the ordinary
L<Algorithm::Dependency::Source> methods.

=cut

use 5.005;
use strict;
use Algorithm::Dependency::Source ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.110';
	@ISA     = 'Algorithm::Dependency::Source';
}





#####################################################################
# Constructor

=pod

=head2 new $filename

When constructing a new Algorithm::Dependency::Source::File object, an
argument should be provided of the name of the file to use. The constructor
will check that the file exists, and is readable, returning C<undef>
otherwise.

=cut

sub new {
	my $class    = shift;
	my $filename = shift or return undef;
	return undef unless -r $filename;

	# Get the basic source object
	my $self = $class->SUPER::new() or return undef;

	# Add our arguments
	$self->{filename} = $filename;

	$self;
}





#####################################################################
# Private Methods

sub _load_item_list {
	my $self = shift;

	# Load the contents of the file
	local $/ = undef;
	open( FILE, $self->{filename} ) or return undef;
	defined(my $source = <FILE>)    or return undef;
	close( FILE )                   or return undef;

	# Split, trim, clean and remove comments
	my @content = grep { ! /^\s*(?:\#|$)/ } 
		split /\s*[\015\012][\s\015\012]*/, $source;

	# Parse and build the item list
	my @Items = ();
	foreach my $line ( @content ) {
		# Split the line by non-word characters
		my @sections = grep { length $_ } split /\W+/, $line;
		return undef unless scalar @sections;

		# Create the new item
		my $Item = Algorithm::Dependency::Item->new( @sections ) or return undef;
		push @Items, $Item;
	}

	\@Items;
}

1;

=pod

=head1 SUPPORT

To file a bug against this module, use the CPAN bug tracking system

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Dependency>

For other comments, contact the author.

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 SEE ALSO

L<Algorithm::Dependency>

=head1 COPYRIGHT

Copyright 2003 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

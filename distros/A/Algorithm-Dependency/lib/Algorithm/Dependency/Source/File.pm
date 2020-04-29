package Algorithm::Dependency::Source::File;
# ABSTRACT: File source for dependency hierarchies

#pod =pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod Algorithm::Dependency::Source::File implements a
#pod L<source|Algorithm::Dependency::Source> where the items are stored in a flat
#pod file or a relatively simple format.
#pod
#pod =head2 File Format
#pod
#pod The file should be an ordinary text file, consisting of a series of lines,
#pod with each line completely containing the information for a single item.
#pod Blank lines, or lines beginning with the hash character '#' will be
#pod ignored as comments.
#pod
#pod For a single item line, only word characters will be used. A 'word character'
#pod consists of all letters and numbers, and the underscore '_' character.
#pod Anything that is not a word character will be assumed to be a separator.
#pod
#pod The first word will be used as the name or id of the item, and any further
#pod words in the line will be used as other items that this one depends on. For
#pod example, all of the following are legal.
#pod
#pod   # A single item with no dependencies
#pod   Foo
#pod
#pod   # Another item that depends on the first one
#pod   Bar Foo
#pod
#pod   # Depending on multiple others
#pod   Bin Foo Bar
#pod
#pod   # We can use different separators
#pod   One:Two|Three-Four+Five=Six Seven
#pod
#pod   # We can also use multiple non-word characters as separators
#pod   This&*&^*&File:  is& & & :::REALLY()Neat
#pod
#pod From the examples above, it should be easy to create your own files.
#pod
#pod =head1 METHODS
#pod
#pod This documents the methods differing from the ordinary
#pod L<Algorithm::Dependency::Source> methods.
#pod
#pod =cut

use 5.005;
use strict;
use Algorithm::Dependency::Source ();

our $VERSION = '1.112';
our @ISA     = 'Algorithm::Dependency::Source';




#####################################################################
# Constructor

#pod =pod
#pod
#pod =head2 new $filename
#pod
#pod When constructing a new Algorithm::Dependency::Source::File object, an
#pod argument should be provided of the name of the file to use. The constructor
#pod will check that the file exists, and is readable, returning C<undef>
#pod otherwise.
#pod
#pod =cut

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::Dependency::Source::File - File source for dependency hierarchies

=head1 VERSION

version 1.112

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
Anything that is not a word character will be assumed to be a separator.

The first word will be used as the name or id of the item, and any further
words in the line will be used as other items that this one depends on. For
example, all of the following are legal.

  # A single item with no dependencies
  Foo

  # Another item that depends on the first one
  Bar Foo

  # Depending on multiple others
  Bin Foo Bar

  # We can use different separators
  One:Two|Three-Four+Five=Six Seven

  # We can also use multiple non-word characters as separators
  This&*&^*&File:  is& & & :::REALLY()Neat

From the examples above, it should be easy to create your own files.

=head1 METHODS

This documents the methods differing from the ordinary
L<Algorithm::Dependency::Source> methods.

=head2 new $filename

When constructing a new Algorithm::Dependency::Source::File object, an
argument should be provided of the name of the file to use. The constructor
will check that the file exists, and is readable, returning C<undef>
otherwise.

=head1 SEE ALSO

L<Algorithm::Dependency>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Algorithm-Dependency>
(or L<bug-Algorithm-Dependency@rt.cpan.org|mailto:bug-Algorithm-Dependency@rt.cpan.org>).

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package CPAN::PackageDetails::Entry;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.26';

use Carp;

=head1 NAME

CPAN::PackageDetails::Entry - Handle a single record of 02packages.details.txt.gz

=head1 SYNOPSIS

Used internally by CPAN::PackageDetails

=head1 DESCRIPTION

An entry is a single line from F<02packages.details.txt> that maps a
package name to a source. It's a whitespace-separated list that
has the values for the column identified in the "columns" field
in the header.

By default, there are three columns: package name, version, and path.

Inside a CPAN::PackageDetails object, the actual work and
manipulation of the entries are handled by delegate classes specified
in C<entries_class> and C<entry_class>). At the moment these are
immutable, so you'd have to subclass this module to change them.

=head2 Methods

=over 4

=item new( FIELD1 => VALUE1 [, FIELD2 => VALUE2] )

Create a new entry

=cut

sub new {
	my( $class, %args ) = @_;

	bless { %args }, $class
	}

=item path

=item author

=item version

=item package_name

Access values of the entry.

=cut

sub path         { $_[0]->{path}                    }
sub author       { ( split m|/|, $_[0]->{path} )[2] }
sub version      { $_[0]->{version}                 }
sub package_name { $_[0]->{'package name'}          }

=item as_string( @column_names )

Formats the Entry as text. It joins with whitespace the values for the
column names you pass it. You get the newline automatically.

Any values that are not defined (or the empty string) turn into the
literal string 'undef' to preserve the columns in the output.

=cut

sub as_string {
	my( $self, @columns ) = @_;

	no warnings 'uninitialized';
	# can't check defined() because that let's the empty string through

	return sprintf "%-34s %5s  %s\n",
		map { length $self->{$_} ? $self->{$_} : 'undef' } @columns;
	}

=back

=head1 TO DO

=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/cpan-packagedetails

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;



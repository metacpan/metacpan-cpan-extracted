package BoutrosLab::TSVStream::Format::None::Dyn;

# safe Perl
use warnings;
use strict;
use Carp;
use BoutrosLab::TSVStream::IO::Role::Dyn;


use Moose;
use namespace::autoclean;
use MooseX::ClassAttribute;

class_has '_fields' => (
	is => 'ro',
	isa => 'ArrayRef',
	default => sub { [ ] }
);

with 'BoutrosLab::TSVStream::IO::Role::Dyn';

=head1 NAME

    BoutrosLab::TSVStream::Format::None::Dyn

=cut

=head1 SYNOPSIS

	use BoutrosLab::TSVStream::Format::None::Dyn;

	# you know ./myfile1 has a valid header line
	my $reader1 = BoutrosLab::TSVStream::Format::None::Dyn->reader(
		file => "./myfile1" );

	my $flds;
	while (my $rec1 = $reader1->read) {
		$flds //= $rec->dyn_fields; # first time, get the field names
		$vals   = $rec->dyn_values;   # get the field values
		# use the record: $flds: [f1,f2,f3,...], $vals: [v1,v2,v3,...]
		}

	# ./myfile2 has no header line
	my $reader2 = BoutrosLab::TSVStream::Format::None::Dyn->reader(
		file       => "./myfile2",
		dyn_fields => [ qw(foo bar baz) ],
	);
	while (my $rec = $reader2->read) {
		$vals = $rec->dyn_values;   # get the field values
		# use the record: flds: [foo,bar,baz], $vals: [v1,v2,v3]
		}

	my $writer1 = BoutrosLab::TSVStream::Format::None::Dyn->writer(
		file       => "myoutfile",
		dyn_fields => [ qw(name address ],
		);

	$writer1->write( 'Larry Wall', 'Republic of Perl' );
	# myfile will contain 2 lines:
	# name<TAB>address
	# Larry Wall<TAB>Republic of Perl

	my $writer2 = BoutrosLab::TSVStream::Format::None::Dyn->writer(
		file   => "myoutfile",
		header => 'skip',
		);

	$writer2->write( 'Larry Wall', 'Republic of Perl' );
	# myfile will contain 1 line:
	# Larry Wall<TAB>Republic of Perl

=head1 DESCRIPTION

This class provides methods to read or write streams of tab
separated fields, with no compile-time plan for the nummber of
fields or their names.

A reader will determine the name of the fields (and thus their
number) either from an explicit list, or from the first line of
the input stream (in which case, that stream must have been written
with a header line providing the names).

The returned reader will have a B<read> method - each time it is
invoked, it returns a record for the next item in the stream (or
undef at end of the stream).  The returned record will have two
attributes - B<dyn_fields> is a ArrayRef[Str] with the names of
the fields (possibly 'extra1', 'extra2', ... if no names or header
were provided), and - B<dyn_values> is a ArrayRef[Str] containing
the valules of the fields for this record.

A writer should be provided the names of the fields, otherwise it
will set the names to be 'extra1', 'extra2', ... and write those
names (unless you have specified that header writting is to be
skipped).

It will provide a B<write> method that can take an array of
strings, or a ist of strings or an Object that is a subclass of
BoutrosLab::TSVStream::Format.  After the number of fields has been
determined (either from a provided B<dyn_fields> in the B<writer>
call, or by reading a header line, or by couting the number of
fields in the first B<write>; all subsequent B<write> calls must
provide the same number of fields.

=head1 SEE ALSO

=over

=item BoutrosLab::TSVStream::IO

for a description of reader and writer objects.  This module only
allows for the dynamic fields, internally providing an empty list
for the fixed fields.

=item BoutrosLab::TSVStream::Format::*

for objects that include a known set of fields, and can provide
explicit type validation for those fields.  If you are using the
same set of fields in many places, it would be well-advised to
define a sub-class that describes your set in better detail.
As well as providing the ability to type-check the fields, that
also gets you the ability to retrieve the field values by name.

=back

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;


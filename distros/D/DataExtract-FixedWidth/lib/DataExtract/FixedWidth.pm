package DataExtract::FixedWidth;
use Moose;
use Carp;

our $VERSION = '0.09';

sub BUILD {
	my $self = shift;

	confess 'You must either send either a "header_row" or data for "heuristic"'
		unless $self->has_header_row || $self->has_heuristic
	;
	confess 'You must send a "header_row" if you send "cols"'
		if $self->has_cols && !$self->has_header_row && !$self->has_heuristic
	;

}

has 'unpack_string' => (
	isa          => 'Str'
	, is         => 'rw'
	, lazy_build => 1
);

has 'cols' => (
	isa            => 'ArrayRef'
	, is           => 'rw'
	, auto_deref   => 1
	, lazy_build   => 1
);

has 'colchar_map' => (
	isa          => 'HashRef'
	, is         => 'rw'
	, lazy_build => 1
);

has 'header_row' => (
	isa          => 'Maybe[Str]'
	, is         => 'rw'
	, predicate  => 'has_header_row'
);

has 'first_col_zero' => (
	isa       => 'Bool'
	, is      => 'ro'
	, default => 1
);

has 'fix_overlay' => (
	isa       => 'Bool'
	, is      => 'ro'
	, default => 0
);

has 'trim_whitespace' => (
	isa       => 'Bool'
	, is      => 'ro'
	, default => 1
);

has 'sorted_colstart' => (
	isa          => 'ArrayRef'
	, is         => 'ro'
	, lazy_build => 1
	, auto_deref => 1
);

has 'null_as_undef' => (
	isa       => 'Bool'
	, is      => 'ro'
	, default => 0
);

has 'heuristic' => (
	isa          => 'ArrayRef'
	, is         => 'rw'
	, predicate  => 'has_heuristic'
	, auto_deref => 1
	, trigger    => \&_heuristic_trigger
);

has 'skip_header_data' => (
	isa       => 'Bool'
	, is      => 'rw'
	, default => 1
);

has 'verbose' => ( isa => 'Bool', 'is' => 'ro', default => 0 );

sub _heuristic_trigger {
	my ( $self, $data ) = @_;

	chomp @$data;

	my $maxLength = 0;
	for ( @$data ) {
		$maxLength = length if length > $maxLength
	}

	$self->header_row( $data->[0] )
		unless $self->has_header_row
	;

	{
		my @unpack;
		my $mask = ' ' x $maxLength;
		$mask |= $_ for @$data;

		## The (?=\S) fixes a bug that creates null columns in the event any
		## one column has trailing whitespace (because you'll have '\S\s  '
		## this was a bug revealed in the dataset NullFirstRow.txt
		#
		## the ^\s+ makes it so that right alligned tables
		## spaces on the left of the first non-whitespace character in
		## the first col work
		push @unpack, length($1)
			while $mask =~ m/((?:^\s+)?\S+\s+(?=\S))/g
		;

		$self->unpack_string( $self->_helper_unpack( \@unpack ) );
	}

}

sub _build_cols {
	my $self = shift;

	my @cols;

	## If we have the unpack string and the header_row parse it all out on our own
	## Here we have two conditionals because the unpack_string comes into existance in
	## build_unpack_string and not the heuristic_trigger
	if (
		( $self->has_header_row && $self->has_unpack_string )
		|| ( $self->has_header_row && $self->has_heuristic )
	) {
		my $skd = $self->skip_header_data;
		$self->skip_header_data( 0 );

		@cols = @{ $self->parse( $self->header_row ) };

		$self->skip_header_data( $skd );
	}

	## We only the header_row
	elsif ( $self->header_row ) {
		@cols = split ' ', $self->header_row;
	}

	else {
		croak 'Need some method to calculate cols';
	}

	\@cols;

}

sub _build_colchar_map {
	my $self = shift;
	my $ccm = {};

	## If we can generate from heurisitic data and don't have a header_row
	if (
		$self->has_header_row
		&& !defined $self->header_row
		&& $self->has_heuristic
		&& $self->has_cols
	) {
		my @cols = $self->cols;
		foreach my $idx ( 0 .. $#cols ) {
			$ccm->{$idx} = $cols[$idx];
		}
	}

	## Generate from header_row
	else {
		croak 'Can not render the map of columns to start-chars without the header_row'
			unless defined $self->has_header_row
		;

		foreach my $col ( $self->cols ) {

			my $pos = 0;
			$pos = index( $self->header_row, $col, $pos );

			croak "Failed to find a column '$col' in the header row"
				unless defined $pos
			;

			unless ( exists $ccm->{ $pos } ) {
				$ccm->{ $pos } = $col;
			}

			## We have two like-named columns
			else {

				## possible inf loop here
				until ( not exists $ccm->{$pos} ) {
					$pos = index( $self->header_row, $col, $pos+1 );

					croak "Failed to find another column '$col' in the header row"
						unless defined $pos
					;

				}

				$ccm->{ $pos } = $col;

			}

		}

	}

	$ccm;

}

sub _build_unpack_string {
	my $self = shift;

	my @unpack;
	my @startcols = $self->sorted_colstart;
	$startcols[0] = 0 if $self->first_col_zero;
	foreach my $idx ( 0 .. $#startcols ) {

		if ( exists $startcols[$idx+1] ) {
			push @unpack, ( $startcols[$idx+1] - $startcols[$idx] );
		}

	}

	$self->_helper_unpack( \@unpack );

}

## Takes ArrayRef of startcols and returns the unpack string.
sub _helper_unpack {
	my ( $self, $startcols ) = @_;

	my $format;
	if ( @$startcols ) {
		$format = 'a' . join 'a', @$startcols;
	}
	$format .= 'A*';

	$format;

}

sub parse {
	my ( $self, $data ) = @_;

	return undef if !defined $data;

	chomp $data;

	## skip_header_data
	if (
		$self->skip_header_data
		&& ( defined $self->header_row && $data eq $self->header_row )
	) {
		warn "Skipping duplicate header row\n" if $self->verbose;
		return undef
	}

	#printf "\nData:|%s|\tHeader:|%s|", $data, $self->header_row;

	my @cols = unpack ( $self->unpack_string, $data );

	## If we bleed over a bit we can fix that.
	if ( $self->fix_overlay ) {
		foreach my $idx ( 0 .. $#cols ) {
			if (
				$cols[$idx] =~ m/\S+$/
				&& exists $cols[$idx+1]
				&& $cols[$idx+1] =~ s/^(\S+)//
			) {
					$cols[$idx] .= $1;
			}
		}
	}

	## Get rid of whitespaces
	if ( $self->trim_whitespace ) {
		for ( @cols ) { s/^\s+//; s/\s+$//; }
	}

	## Swithc nulls to undef
	if ( $self->null_as_undef ) {
		croak 'This ->null_as_undef option mandates ->trim_whitespace be true'
			unless $self->trim_whitespace
		;
		for ( @cols ) { undef $_ unless length($_) }
	}

	\@cols;

}

sub parse_hash {
	my ( $self, $data ) = @_;

	my $row = $self->parse( $data );

	my $colstarts = $self->sorted_colstart;

	my $results;
	foreach my $idx ( 0 .. $#$row ) {
		my $col = $self->colchar_map->{ $colstarts->[$idx] };
		$results->{ $col } = $row->[$idx];
	}

	$results;

}

sub _build_sorted_colstart {
	my $self = shift;

	my @startcols = map { $_->[0] }
		sort { $a->[1] <=> $b->[1] }
		map { [$_, sprintf( "%10d", $_ ) ] }
		keys %{ $self->colchar_map }
	;

	\@startcols;

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

DataExtract::FixedWidth - The one stop shop for parsing static column width text tables!

=head1 SYNOPSIS

	## We assume the columns have no spaces in the header.
	my $de = DataExtract::FixedWidth->new({ header_row => $header_row });
	
	## We explicitly tell what column names to pick out of the header.
	my $de = DataExtract::FixedWidth->new({
		header_row => $header_row
		cols       => [qw/COL1NAME COL2NAME COL3NAME/, 'COL WITH SPACE IN NAME']
	});
	
	## We supply data to heuristic and assume
	## * first row is the header (to avoid this assumption
	##   set the header_row to undef. )
	## * heurisitic's unpack_string is correct
	## * unpack_string applied to header_row will tell us the columns
	my $de = DataExtract::FixedWidth->new({ heuristic => \@datarows });
	
	## We supply data to heuristic, say we have no header, and the set columns
	## just like the above except ->parse_hash will be be indexed by the
	## provided columns and no row is designated as the header.
	my $de = DataExtract::FixedWidth->new({
		heuristic    => \@datarows
		, header_row => undef
		, columns    => [qw/ foo bar baz/]
	});
	
	## We supply data to heuristic, and we explicitly add the header_row
	## with this method it doesn't have to occur in the data.
	## The unpack string rendered will be applied to the first row to get
	## the columns
	my $de = DataExtract::FixedWidth->new({
		heuristic    => \@datarows
		, header_row => $header_row
	});
	
	## We explicitly add the header_row, with this method it doesn't have
	## to occur in the data. The unpack string rendered will be applied
	## to the provided header_row to get the columns
	my $de = DataExtract::FixedWidth->new({
		unpack_string => $template
		, header_row  => $header_row
	});
	
	$de->parse( $data_row );
	
	$de->parse_hash( $data_row );

=head1 DESCRIPTION

This module parses any type of fixed width table -- these types of tables are often outputed by ghostscript, printf() displays with string padding (i.e. %-20s %20s etc), and most screen capture mechanisms. This module is using Moose all methods can be specified in the constructor.

In the below example, this module can discern the column names from the header. Or, you can supply them explicitly in the constructor; or, you can supply the rows in an ArrayRef to heuristic and pray for the best luck. This module is pretty abstracted and will deduce what it doesn't know in a decent fashion if all of the information is not provided.

	SAMPLE FILE
	HEADER:  'COL1NAME       COL2NAME       COL3NAMEEEEE'
	DATA1:   'FOOBARBAZ      THIS IS TEXT   ANHER COL   '
	DATA2:   'FOOBAR FOOBAR  IS TEXT        ANOTHER COL '

After you have constructed, you can C<-E<gt>parse> which will return an ArrayRef
	$de->parse('FOOBARBAZ THIS IS TEXT    ANOTHER COL');

Or, you can use C<-E<gt>parse_hash()> which returns a HashRef of the data indexed by the column headers. They can be determined in many ways with the data you provide.

=head2 Constructor

The class constructor, C<-E<gt>new>, has numerious forms. Some options it has are:

=over 12

=item heuristics => \@lines

This will deduce the unpack format string from data. If you opt to use this method, and need parse_hash, the first row of the heurisitic is assumed to be the header_row. The unpack_string that results for the heuristic is applied to the header_row to determine the columns.

=item cols => \@cols

This will permit you to explicitly list the columns in the header row. This is especially handy if you have spaces in the column header. This option will make the C<header_row> mandatory.

=item header_row => $string

If a C<cols> option is not provided the assumption is that there are no spaces in the column header. The module can take care of the rest. The only way this column can be avoided is if we deduce the header from heuristics, or if you explicitly supply the unpack string and only use C<-E<gt>parse($line)>. If you are not going to supply a header, and you do not want to waste the first line on a header assumption, set the C<header_row =E<gt> undef> in the constructor.

=item verbose => 1|0

Right now, it simply display's warnings when it does something that might at first seem awkward. Like returning undef when it encouters a duplicate copy of a header row.

=back

=head2 Methods

B<An astrisk, (*) in the option means that is the default.>

=over 12

=item ->parse( $data_line )

Parses the data and returns an ArrayRef

=item ->parse_hash( $data_line )

Parses the data and returns a HashRef, indexed by the I<cols> (headers)

=item ->first_col_zero(1*|0)

This option forces the unpack string to make the first column assume the characters to the left of the header column. So, in the below example the first column also includes the first char of the row, even though the word stock begins at the second character.

	CHAR NUMBERS: |1|2|3|4|5|6|7|8|9|10
	HEADER ROW  : | |S|T|O|C|K| |V|I|N

=item ->trim_whitespace(*1|0)

Trim the whitespace for the elements that C<-E<gt>parse($line)> outputs.

=item ->fix_overlay(1|0*)

Fixes columns that bleed into other columns, move over all non-whitespace characters preceding the first whitespace of the next column. This does not work with heurisitic because the unpack string makes the assumption the data is not mangeled.

So if ColumnA as is 'foob' and ColumnB is 'ar Hello world'

* ColumnA becomes 'foobar', and ColumnB becomes 'Hello world'

=item ->null_as_undef(1|0*)

Simply undef all elements that return C<length(element) = 0>, requires C<-E<gt>trim_whitespace>.

=item ->skip_header_data(1*|0)

Skips duplicate copies of the header_row if found in the data.

=item ->colchar_map

Returns a HashRef that displays the results of each column header and relative character position the column starts at. In the case of heuristic this is a simple ordinal number. In the case of non-heuristic provided data it is currently a cardinal character position.

=item ->unpack_string

Returns the C<CORE::unpack()> template string that will be used internally by C<-E<gt>parse($line)>

=back

=head1 AVAILABILITY

CPAN.org

Git repo at L<http://repo.or.cz/w/DataExtract-FixedWidth.git>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Evan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=head1 AUTHOR

	Evan Carroll <me at evancarroll.com>
	System Lord of the Internets

=head1 BUGS

Please report any bugs or feature requests to C<bug-dataexract-fixedwidth at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DataExtract-FixedWidth>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=cut

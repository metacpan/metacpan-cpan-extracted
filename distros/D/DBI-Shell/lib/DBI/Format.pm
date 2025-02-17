# -*- perl -*-
# vim:ts=2:sw=2:aw:ai:sta:nows
#
#   DBI::Format - a package for displaying result tables
#
#   Copyright (c) 1998  Jochen Wiedmann
#   Copyright (c) 1998  Tim Bunce
#
#   The DBI::Shell:Result module is free software; you can redistribute
#   it and/or modify it under the same terms as Perl itself.
#
#   Author: Jochen Wiedmann
#           Am Eisteich 9
#           72555 Metzingen
#           Germany
# 
#           Email: joe@ispsoft.de
#           Phone: +49 7123 14881
# 

use strict;

package DBI::Format;

our $VERSION = '11.98'; # VERSION

use Text::Abbrev;

sub available_formatters {
    my ($use_abbrev) = @_;
    my @fmt;
    my @dir = grep { -d "$_/DBI/Format" } @INC;
    foreach my $dir (@dir) {
		opendir DIR, "$dir/DBI/Format" or warn "Unable to read $dir/DBI: $!\n";
		push @fmt, map { m/^(\w+)\.pm$/i ? ($1) : () } readdir DIR;
		closedir DIR;
    }
    my %fmt = map { (lc($_) => "DBI::Format::$_") } @fmt;
		$fmt{box}  = "DBI::Format::Box";
		$fmt{partbox}  = "DBI::Format::PartBox";
		$fmt{neat} = "DBI::Format::Neat";
		$fmt{raw} = "DBI::Format::Raw";
		$fmt{string} = "DBI::Format::String";
		$fmt{html} = "DBI::Format::HTML";
    my $formatters = \%fmt;
    if ($use_abbrev) {
	$formatters = abbrev(keys %fmt);
		foreach my $abbrev (sort keys %$formatters) {
			$formatters->{$abbrev} = $fmt{ $formatters->{$abbrev} } || die;
		}
    }
    return $formatters;
}


sub formatter {
    my ($class, $mode, $use_abbrev) = @_;
    $mode = lc($mode);
    my $formatters = available_formatters($use_abbrev);
    my $fmt = $formatters->{$mode};
    if (!$fmt) {
		$formatters = available_formatters(0);
		die "Format '$mode' unavailable. Available formats: ".
			join(", ", sort keys %$formatters)."\n";
    }
	{
		# Attempt to determine if format mode is in the base class.
    	no strict 'refs';
		eval "$fmt->new()";
		if ( $@ and $@ =~ m/locate/ ) {
			eval "use $fmt";
			die "$@\n" if $@;
		} elsif ($@) {
			die "$@\n" if $@;
    	}
	}
    return $fmt;
}


package DBI::Format::Base;

use DBI qw(:sql_types);

# DBI::Format::Foo objects are presently copies of the parent DBI::Shell
# session hashref at the time of instantiation, and so are not aware of
# `/option' updates to the parent thereafter.  Check the ->{parent} member
# for any session-specific /option values.

sub new {
    my $class = shift;
    my $self = (@_ == 1) ? { %{$_[0]}, parent => $_[0] } : { @_ };
    bless ($self, (ref($class) || $class));
    $self;
}

# Basic preparation for output, setting up 'fh', 'sth', 'rows' and possibly
# 'sep' members.  Also caches SQL type information and sets up BOOLEAN
# formatting, if needed.
sub header {
    my ($self, $sth, $fh, $sep) = @_;
	my $types;

    $self->{fh}   = $self->setup_fh($fh);
    $self->{sth}  = $sth;
    $self->{rows} = 0;
    $self->{sep}  = $sep if defined $sep;

	$self->{__dbi_format_sql_types} = $types = $sth->{TYPE};

	# Parent DBI::Shell session may have changed `/option bool_format'
	# since the last query we formatted, so update our internal bool
	# display data if needed.
	for my $t (@$types) {
		next unless $t == SQL_BOOLEAN;
		$self->{__dbi_format_bool_alterns} =
		    [ split(',', $self->{parent}->{bool_format}, 2) ];
		last;
	}

	$self;
}

# $fmt->encode_value( $value_reference, $sql_type )
#
# Do not call directly.  This method is called by DBI::Format::Base::row.
#
# Apply output encoding to a single, textual representation of a field
# value.  This method is called _after_ NULLs and BOOLEANs have been
# stringified.
#
# Base implementation escapes \n, \t and \r and translates ASCII
# non-printables without regard to $sql_type (SQL_NUMERIC, SQL_VARCHAR,
# etc.).  This is *not* ``safe'' for all terminals in all locales --
# the default is merely simple encoding.
#
# Subclasses may override to URI- or XML-encode certain data, for example.
#

sub encode_value {
	my ($self, $value_ref, $sql_type) = @_;

	for ($$value_ref) {
		last unless defined;
		s/\n/\\n/g;
		s/\t/\\t/g;
		s/\r/\\r/g;
		s/[\000-\037\177-\237]/./g;
	}
}

# $fmt->row( $row_ref )
#
# Basic preparation of row data, responsible for formatting NULLs and
# BOOLEANs according to `/option' values, and calling encode_value() on
# fields.  As a convenience, also increments $fmt->{rows}.
#
# All subclasses should call this function from their overridden row()
# methods.
#
# Note that row() modifies its argument in place, so $row_ref should be
# a _copy_ of the (presumptively read-only) row from the active $sth.
#
sub row {
    my ($self, $row) = @_;

	my $i = 0;
	for my $value (@$row) {
        unless (defined $value) {
            $value = $self->{parent}->{null_format};
        }

		my $sql_type = $self->{__dbi_format_sql_types}->[$i];
		if ($sql_type == SQL_BOOLEAN) {
            $value = $self->{__dbi_format_bool_alterns}->[ $value ? 0 : 1 ];
        }

		$self->encode_value(\$value, $sql_type);
    } continue {
        $i++;
	}

	$self->{rows}++;
    return wantarray ? @$row : $row;
}

sub setup_fh {
    my ($self, $fh) = @_;

    # This method has grown confused as to what it's trying to do and why
    # Partly because this module was written in pre-perl5.3 days
    # the code in other methods originally did: $fh->print(...)
    # because C<print $fh ...> didn't work reliably as a method call.
    # Now the code uses C<print $fh ...> some of this may no longer be
    # required. It's important that things like IO::Scalar handles work.

    return $self->{fh} if !$fh && $self->{fh};

    $fh ||= \*STDOUT;

    return $fh if ref($fh) =~ m/GLOB/;

    unless (UNIVERSAL::can($fh,'print')) {	# not blessed
	require FileHandle;
	bless $fh => "FileHandle";
    }

    return $fh;
}


sub trailer {
    my($self) = @_;
    my $fh   = delete $self->{'fh'};
    my $sth  = delete $self->{'sth'};
    my $rows = delete $self->{'rows'};
    print $fh ("[$rows rows of $sth->{NUM_OF_FIELDS} fields returned]\n");
		delete $self->{'sep'};
}

sub _determine_width {
	my($self , $type, $precision) = @_;

	my $width = 
		(!defined($type)) ? 0 :		# Is type defined?
		($type == SQL_DATE)	? 8 :		# Is type a Date?
			($type == SQL_INTEGER 		# Is type an Integer?
				and defined $precision
				and $precision > 15 ) ? 10 :
				($type == SQL_NUMERIC 	# Is type a Numeric?
					and defined $precision
					and $precision > 15 ) ? 10 :
						defined($precision) ?  $precision: 0; # Default 0

	return $width;
}


package DBI::Format::Neat;

@DBI::Format::Neat::ISA = qw(DBI::Format::Base);

sub header {
    my ($self, $sth, $fh, $sep) = @_;
	$self->SUPER::header($sth, $fh, $sep);
    print {$self->{fh}} (join($self->{sep}, @{$sth->{'NAME'}}), "\n");
}

sub row {
    my($self, $rowref) = @_;
    my @row = $self->SUPER::row([@$rowref]);
    my $fh = $self->{'fh'};
    print $fh (DBI::neat_list(\@row, 9999, $self->{sep}),"\n");
}



package DBI::Format::Box;

use DBI qw(:sql_types);

@DBI::Format::Box::ISA = qw(DBI::Format::Base);

sub header {
    my($self, $sth, $fh, $sep) = @_;
	$self->SUPER::header($sth, $fh, $sep);
    my $types = $sth->{'TYPE'};
    my @right_justify;
    my @widths;
    my $names = $sth->{'NAME'};
    my $type;
    for (my $i = 0;  $i < $sth->{'NUM_OF_FIELDS'};  $i++) {
		push(@widths, defined($names->[$i]) ? length($names->[$i]) : 0);
		$type = $types->[$i];
		push(@right_justify,
			 (defined($type) and ($type == SQL_NUMERIC   ||
			  $type == SQL_DECIMAL   ||
			  $type == SQL_INTEGER   ||
			  $type == SQL_SMALLINT  ||
			  $type == SQL_FLOAT     ||
			  $type == SQL_REAL      ||
			  $type == SQL_TINYINT))
		);
    }
    $self->{'widths'} = \@widths;
    $self->{'right_justify'} = \@right_justify;
}


sub row {
    my($self, $orig_row) = @_;
    my $i = 0;
    my $col;
    my $widths = $self->{'widths'};
	my @row = $self->SUPER::row([@$orig_row]); # don't mess with the original row
    for (@row) {
        if (length > $widths->[$i]) {
            $widths->[$i] = length;
        }
        ++$i;
    }
    push @{$self->{data}}, \@row;
}


sub trailer {
    my $self = shift;
    my $widths = delete $self->{'widths'};
    my $right_justify = delete $self->{'right_justify'};
    my $sth  = $self->{'sth'};
    my $data = $self->{'data'};
    $self->{'rows'} = @$data;

    my $format_sep = '+';
    my $format_names = '|';
    my $format_rows = '|';
    for (my $i = 0;  $i < $sth->{'NUM_OF_FIELDS'};  $i++) {
	$format_sep   .= ('-' x $widths->[$i]) . '+';
	$format_names .= sprintf("%%-%ds|", $widths->[$i]);
	$format_rows  .= sprintf("%%"
			. ($right_justify->[$i] ? "" : "-") . "%ds|",
			$widths->[$i]);
    }
    $format_sep   .= "\n";
    $format_names .= "\n";
    $format_rows  .= "\n";

    my $fh = $self->{'fh'};
    print $fh ($format_sep);
    print $fh (sprintf($format_names, @{$sth->{'NAME'}}));
    foreach my $row (@$data) {
	print $fh ($format_sep);
	print $fh (sprintf($format_rows, @$row));
    }
    print $fh ($format_sep);

    $self->SUPER::trailer(@_);
}

package DBI::Format::PartBox;

use DBI qw(:sql_types);

@DBI::Format::PartBox::ISA = qw(DBI::Format::Base);

sub header {
    my ($self, $sth, $fh, $sep) = @_;
	$self->SUPER::header($sth, $fh, $sep);
    my $types = $sth->{'TYPE'};
    my @right_justify;
    my @widths;
    my $names = $sth->{'NAME'};
    my $type;
    for (my $i = 0;  $i < $sth->{'NUM_OF_FIELDS'};  $i++) {
	push(@widths, defined($names->[$i]) ? length($names->[$i]) : 0);
	$type = $types->[$i];
	push(@right_justify,
	     ($type == SQL_NUMERIC   ||
	      $type == SQL_DECIMAL   ||
	      $type == SQL_INTEGER   ||
	      $type == SQL_SMALLINT  ||
	      $type == SQL_FLOAT     ||
	      $type == SQL_REAL      ||
	      $type == SQL_TINYINT));
    }
    $self->{'widths'} = \@widths;
    $self->{'right_justify'} = \@right_justify;
}


sub row {
    my($self, $orig_row) = @_;
    my $i = 0;
    my $col;
    my $widths = $self->{'widths'};
    my @row = $self->SUPER::row([@$orig_row]); # don't mess with the original row
    for (@row) {
        if (length > $widths->[$i]) {
            $widths->[$i] = length;
        }
        ++$i;
    }
    push @{$self->{data}}, \@row;
}


sub trailer {
    my $self = shift;
    my $widths = delete $self->{'widths'};
    my $right_justify = delete $self->{'right_justify'};
    my $sth  = $self->{'sth'};
    my $data = $self->{'data'};
    $self->{'rows'} = @$data;

    my $format_sep = '+';
    my $format_names = '|';
    my $format_rows = '|';
    for (my $i = 0;  $i < $sth->{'NUM_OF_FIELDS'};  $i++) {
	$format_sep   .= ('-' x $widths->[$i]) . '+';
	$format_names .= sprintf("%%-%ds|", $widths->[$i]);
	$format_rows  .= sprintf("%%"
			. ($right_justify->[$i] ? "" : "-") . "%ds|",
			$widths->[$i]);
    }
    $format_sep   .= "\n";
    $format_names .= "\n";
    $format_rows  .= "\n";

    my $fh = $self->{'fh'};
    print $fh ($format_sep);
    print $fh (sprintf($format_names, @{$sth->{'NAME'}}));
    print $fh ($format_sep);
    foreach my $row (@$data) {
	# print $fh ($format_sep);
	print $fh (sprintf($format_rows, @$row));
    }
    print $fh ($format_sep);

    $self->SUPER::trailer(@_);
}

package DBI::Format::Raw;

@DBI::Format::Raw::ISA = qw(DBI::Format::Base);

sub header {
    my ($self, $sth, $fh, $sep) = @_;
	$self->SUPER::header($sth, $fh, $sep);
    print {$self->{fh}} (join($self->{sep}, @{$sth->{'NAME'}}), "\n");
}

sub row {
    my($self, $rowref) = @_;
		local $^W = 0;
    my @row = @$rowref;
	my $fh = $self->{'fh'};
	print $fh (join($self->{sep}, @row), "\n");
}

package DBI::Format::String;

@DBI::Format::String::ISA = qw(DBI::Format::Base);

sub header {
    my ($self, $sth, $fh, $sep) = @_;
	$self->SUPER::header($sth, $fh, $sep);
    my $types = $sth->{'TYPE'};
    my @right_justify;
    my @widths;
    my $names = $sth->{'NAME'};
    my $type;
    for (my $i = 0;  $i < $sth->{'NUM_OF_FIELDS'};  $i++) {
		$type = $types->[$i];
		push(@widths, $self->_determine_width( 
			$type, $sth->{PRECISION}->[$i] ));

		push(@right_justify,
	     (defined($type) and ($type == DBI::SQL_NUMERIC()   ||
	      $type == DBI::SQL_DECIMAL()   ||
	      $type == DBI::SQL_INTEGER()   ||
	      $type == DBI::SQL_SMALLINT()  ||
	      $type == DBI::SQL_FLOAT()     ||
	      $type == DBI::SQL_REAL()      ||
	      $type == DBI::SQL_TINYINT()))
		);
    	my $format_names;
		$format_names .= sprintf("%%-%ds ", $widths[$i]);
    	print {$self->{fh}} (sprintf($format_names, $names->[$i]));
    }
    $self->{'widths'} = \@widths;
    $self->{'right_justify'} = \@right_justify;
    print {$self->{fh}} "\n";

}


sub row {
    my($self, $orig_row) = @_;
    my $i = 0;
    my $col;
    my $widths = $self->{'widths'};
    my $right_justify = $self->{'right_justify'};
    my @row = $self->SUPER::row([@$orig_row]); # don't mess with the original row

    my $sth  = $self->{'sth'};
    my $format_rows  = ' ';
    for (my $i = 0;  $i < $sth->{'NUM_OF_FIELDS'};  $i++) {
	$format_rows  .= sprintf("%%"
			. ($right_justify->[$i] ? "" : "-") . "%ds ",
			$widths->[$i]);
    }
    $format_rows  .= "\n";

    my $fh = $self->{'fh'};
    print $fh (sprintf($format_rows, @row));
}


sub trailer {
    my $self = shift;
    my $widths = delete $self->{'widths'};
    my $right_justify = delete $self->{'right_justify'};
    $self->SUPER::trailer(@_);
} 

package DBI::Format::HTML;

@DBI::Format::HTML::ISA = qw(DBI::Format::Base);

sub header {
    my($self, $sth, $fh) = @_;
	$self->SUPER::header($sth, $fh);
    $self->{'data'} = [];
    my $types = $sth->{'TYPE'};
    my @right_justify;
    my @widths;
    my $names = $sth->{'NAME'};
    my $type;
    for (my $i = 0;  $i < $sth->{'NUM_OF_FIELDS'};  $i++) {
		push(@widths, defined($names->[$i]) ? length($names->[$i]) : 0);
		$type = $types->[$i];
		push(@right_justify,
			 (defined $type and ($type == DBI::SQL_NUMERIC()   ||
			  $type == DBI::SQL_DECIMAL()   ||
			  $type == DBI::SQL_INTEGER()   ||
			  $type == DBI::SQL_SMALLINT()  ||
			  $type == DBI::SQL_FLOAT()     ||
			  $type == DBI::SQL_REAL()      ||
			  $type == DBI::SQL_TINYINT()))
		);
    }
    $self->{'widths'} = \@widths;
    $self->{'right_justify'} = \@right_justify;
}


sub row {
    my($self, $orig_row) = @_;
    my $i = 0;
    my $col;
    my $widths = $self->{'widths'};
    my @row = $self->SUPER::row([@$orig_row]); # don't mess with the original row
    for (@row) {
        if (length($_) > $widths->[$i]) {
            $widths->[$i] = length($_);
        }
        ++$i;
    }
    push @{$self->{data}}, \@row;
}


sub trailer {
    my $self = shift;
    my $widths = delete $self->{'widths'};
    my $right_justify = delete $self->{'right_justify'};
    my $sth  = $self->{'sth'};
    my $data = $self->{'data'};
    $self->{'rows'} = @$data;

    my $format_sep = '+';
    my $format_names = '<TR>';
    my $format_rows = '<TR>';
    for (my $i = 0;  $i < $sth->{'NUM_OF_FIELDS'};  $i++) {
	$format_names .= sprintf("<TH>%%-%ds</TH>", $widths->[$i]);
	$format_rows  .= sprintf("<TD>%%"
			. ($right_justify->[$i] ? "" : "-") . "%ds</TD>",
			$widths->[$i]);
    }
    $format_sep   .= "\n";
    $format_names .= "</TR>\n";
    $format_rows  .= "</TR>\n";

    my $fh = $self->{'fh'};
    print $fh("<TABLE>\n");
    print $fh(sprintf($format_names, @{$sth->{'NAME'}}));
    foreach my $row (@$data) {
	print $fh (sprintf($format_rows, @$row));
    }
    print $fh ("</TABLE>\n");

    $self->SUPER::trailer(@_);
}


1;

=head1 NAME

DBI::Format - A package for displaying result tables

=head1 SYNOPSIS

  # create a new result object
  $r = DBI::Format->new('var1' => 'val1', ...);

  # Prepare it for output by creating a header
  $r->header($sth, $fh);

  # In a loop, display rows
  while ($ref = $sth->fetchrow_arrayref()) {
    $r->row($ref);
  }

  # Finally create a trailer
  $r->trailer();


=head1 DESCRIPTION

THIS PACKAGE IS STILL VERY EXPERIMENTAL. THINGS WILL CHANGE.

This package is used for making the output of DBI::Shell configurable.
The idea is to derive a subclass for any kind of output table you might
create. Examples are

=over 8

=item *

a very simple output format as offered by DBI::neat_list().
L<"AVAILABLE SUBCLASSES">.

=item *

a box format, as offered by the Data::ShowTable module.

=item *

HTML format, as used in CGI binaries

=item *

postscript, to be piped into lpr or something similar

=back

In the future the package should also support interactive methods, for
example tab completion.

These are the available methods:

=over 8

=item new(@attr)

=item new(\%attr)

(Class method) This is the constructor. You'd rather call a subclass
constructor. The construcor is accepting either a list of key/value
pairs or a hash ref.

=item header($sth, $fh)

(Instance method) This is called when a new result table should be
created to display the results of the statement handle B<$sth>. The
(optional) argument B<$fh> is an IO handle (or any object supporting
a I<print> method), usually you use an IO::Wrap object for STDIN.

The method will query the B<$sth> for its I<NAME>, I<NUM_OF_FIELDS>,
I<TYPE>, I<SCALE> and I<PRECISION> attributes and typically print a
header. In general you should not assume that B<$sth> is indeed a DBI
statement handle and better treat it as a hash ref with the above
attributes.

=item row($ref)

(Instance method) Prints the contents of the array ref B<$ref>. Usually
you obtain this array ref by calling B<$sth-E<gt>fetchrow_arrayref()>.

=item trailer

(Instance method) Once you have passed all result rows to the result
package, you should call the I<trailer> method. This method can, for
example print the number of result rows.

=back


=head1 AVAILABLE SUBCLASSES

First of all, you can use the DBI::Format package itself: It's
not an abstract base class, but a very simple default using
DBI::neat_list().


=head2 Ascii boxes

This subclass is using the I<Box> mode of the I<Data::ShowTable> module
internally. L<Data::ShowTable(3)>.

=head2 Raw

Row is written without formating.  Columns returned in comma or user defined
separated list.

=head2 String

Row is written using a string format.  Future releases will include th ability
set the string format.


=head1 AUTHOR AND COPYRIGHT

This module is Copyright (c) 1997, 1998

    Jochen Wiedmann
    Am Eisteich 9
    72555 Metzingen
    Germany

    Email: joe@ispsoft.de
    Phone: +49 7123 14887

The DBD::Proxy module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<DBI::Shell(3)>, L<DBI(3)>, L<dbish(1)>

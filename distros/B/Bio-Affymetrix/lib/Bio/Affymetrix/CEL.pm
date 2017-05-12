#!/usr/bin/perl

# A package for parsing CEL files

# Docs come before the code

=head1 NAME

Bio::Affymetrix::CEL- parse Affymetrix CEL files

=head1 SYNOPSIS

use Bio::Affymetrix::CEL;

# Parse the CDF file

my $cel=new Bio::Affymetrix::CEL();

$cel->parse_from_file("foo.cel");

# Print out all of the intensities for each square

for (my $x=0;$x<scalar(@{$cel->intensity_map()});$x++) {
	for (my $y=0;$y<scalar(@{cel->intensity_map()->[$x]});$y++) {
		print join(",",($x,$y,$cel->intensity_map->[$x][$y]->[0])."\n";
	}
}



=head1 DESCRIPTION

The Affymetrix microarray system produces files in a variety of
formats. If this means nothing to you, these modules are probably not
for you :). This module parses CEL files. Use this module if you want
to find out about the results for individual probes on an array.

All of the Bio::Affymetrix modules parse a file entirely into
memory. You therefore need enough memory to hold these objects. For
some applications, parsing as a stream may be more appropriate-
hopefully the source to these modules will give enough clues to make
this an easy task. This module takes lots of memory due to the way
Perl stores arrays. If you are writing a program that uses many CEL
files, delete each CEL file once you have the information you need
from it.

=head2 HINTS

You fill the object filled with data using the
parse_from_filehandle, parse_from_string or parse_from_file
routines. You can get/set various statistics using methods on the
object.

The key method is intensity_map. This returns a reference to a 2D
array of parameters for each square.


=head1 NOTES

=head2 REFERENCE

Modules were written with the official Affymetrix documentation, which
can be located at http://www.affymetrix.com/support/developer/AffxFileFormats.ZIP

=head2 COMPATIBILITY

This module can parse the CEL files produced by the Affymetrix software
MAS 5 and GCOS.

=head1 TODO

Writing CEL files as well as reading them. 

=head1 COPYRIGHT

Copyright (C) 2005 by Nick James, David J Craigon, NASC, The
University of Nottingham

This module is free software. You can copy or redistribute it under the same terms as Perl itself. 

Affymetrix is a registered trademark of Affymetrix Inc., Santa
Clara, California, USA.

=head1 AUTHORS
    
Nick James (nick at arabidopsis.info)

David J Craigon (david at arabidopsis.info)

Nottingham Arabidopsis Stock Centre (http://arabidopsis.info), University of Nottingham.

=head1 METHODS

=cut


package Bio::Affymetrix::CEL;


use Carp;
use warnings;
use strict;
our $VERSION=0.5;

=head2 new

  Arg [0]    : none
  Example    : my $cel=new Bio::Affymetrix::CEL();
  Description: constructor for CEL object
  Returntype : new Bio::Affmetrix::CEL object
  Exceptions : none
  Caller     : general

=cut

sub new {
    my $class=shift;
    my $q=shift;
    my $self={};

    bless $self,$class;
    return $self;
}

# Getter/setters

# CEL file trivia
=head2 original_version
  Arg [0]    : 	none
  Example    : 	my $version=$cel->original_version()
  Description: 	Returns the version of the CEL file parsed. Encoded in file.
  Returntype : string
  Exceptions : none
  Caller     : general
=cut

sub original_version {
    my $self=shift;
    return $self->{"VERSION"};
}

=head2 original_format
  Arg [0]    : 	none
  Example    : 	my $format=$cel->original_format()
  Description:	Returns the format of the CEL file parsed. Currently MAS5 or XDA
  Returntype : 	string ("MAS5" or "XDA")
  Exceptions : 	none
  Caller     : 	general

=cut


sub original_format {
    my $self=shift;
    return $self->{"FORMAT"};
}

=head2 original_rows
  Arg [0]    : 	none
  Example    : 	my $rows=$cel->orignal_rows()
  Description: 	Get the number of rows originally reported on this chip
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut

sub original_rows {
    my $self=shift;

    return $self->{"ROWS"};
}

=head2 original_cols
  Arg [0]    : 	none
  Example    : 	my $cols=$cel->original_cols()
  Description: 	Get the number of cols originally reported on this chip
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut

sub original_cols {
    my $self=shift;

    return $self->{"COLS"};
}

=head2 x_offset
  Arg [1]    : 	integer $x_offset (optional)
  Example    : 	my $x_offset=$cel->x_offset()
  Description: 	Get/Set the x offset. This is always 0 when parsed
from a genuine CEL file. Only available in MAS5 CEL files
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut

sub x_offset {
    my $self=shift;
    if (my $q=shift) {
	$self->{"OFFSETX"}=$q;
    }
    return $self->{"OFFSETX"};
}


=head2 y_offset
  Arg [1]    : 	integer $y_offset (optional)
  Example    : 	my $y_offset=$cel->y_offset()
  Description: 	Get/Set the y offset. This is always 0 when parsed
from a genuine CEL file. Only available in MAS5 CEL files.
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut

sub y_offset {
    my $self=shift;
    if (my $q=shift) {
	$self->{"OFFSETY"}=$q;
    }
    return $self->{"OFFSETY"};
}


=head2 grid_corner_ul
  Arg [1]    : 	integer $grid_corner_ul (optional)
  Example    : 	my $grid_corner_ul=$cel->grid_corner_ul()
  Description: 	Get/set the XY coordinates of the upper left grid corner in pixel coordinates. Only available in MAS5 CEL files.
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut

sub grid_corner_ul {
    my $self=shift;
    if (my $q=shift) {
	$self->{"GRIDCORNERUL"}=$q;
    }
    return $self->{"GRIDCORNERUL"};
}

=head2 grid_corner_ur
  Arg [1]    : 	integer $grid_corner_ur (optional)
  Example    : 	my $grid_corner_ur=$cel->grid_corner_ur()
  Description: 	Get/set the XY coordinates of the upper right grid corner in pixel coordinates. Only available in MAS5 CEL files.
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut

sub grid_corner_ur {
    my $self=shift;
    if (my $q=shift) {
	$self->{"GRIDCORNERUR"}=$q;
    }
    return $self->{"GRIDCORNERUR"};
}

=head2 grid_corner_lr
  Arg [1]    : 	integer $grid_corner_lr (optional)
  Example    : 	my $grid_corner_lr=$cel->grid_corner_lr()
  Description: 	Get/set the XY coordinates of the lower right grid corner in pixel coordinates. Only available in MAS5 CEL files.
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut

sub grid_corner_lr {
    my $self=shift;
    if (my $q=shift) {
	$self->{"GRIDCORNERLR"}=$q;
    }
    return $self->{"GRIDCORNERLR"};
}


=head2 grid_corner_ll
  Arg [1]    : 	integer $grid_corner_ll (optional)
  Example    : 	my $grid_corner_ll=$cel->grid_corner_ll()
  Description: 	Get/set the XY coordinates of the lower left grid corner in pixel coordinates. Only available in MAS5 CEL files.
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut

sub grid_corner_ll {
    my $self=shift;
    if (my $q=shift) {
	$self->{"GRIDCORNERLL"}=$q;
    }
    return $self->{"GRIDCORNERLL"};
}

=head2 axis_invert_x
  Arg [1]    : 	boolean $axis_invert_x (optional)
  Example    : 	my $axis_invert_x=$cel->axis_invert_x()
  Description: 	Get/set whether the X axis is inverted. Always false in genuine CEL files Only available in MAS5 CEL files.
  Returntype : boolean
  Exceptions : none
  Caller     : general
=cut

sub axis_invert_x {
    my $self=shift;
    if (my $q=shift) {
	$self->{"AXIS-INVERTX"}=$q;
    }
    return $self->{"AXIS-INVERTX"};
}

=head2 axis_invert_x
  Arg [1]    : 	boolean $axis_invert_y (optional)
  Example    : 	my $axis_invert_y=$cel->axis_invert_y()
  Description: 	Get/set whether the Y axis is inverted. Always false in genuine CEL files Only available in MAS5 CEL files.
  Returntype : boolean
  Exceptions : none
  Caller     : general
=cut

sub axis_invert_y {
    my $self=shift;
    if (my $q=shift) {
	$self->{"AXISINVERTY"}=$q;
    }
    return $self->{"AXISINVERTY"};
}



=head2 swap_xy
  Arg [1]    : 	boolean $swap_xy (optional)
  Example    : 	my $swap_xy=$cel->swap_xy()
  Description: 	Get/set whether the X and Y axis are swapped. Always false in genuine CEL files Only available in MAS5 CEL files.
  Returntype : boolean
  Exceptions : none
  Caller     : general
=cut
sub swap_xy {
    my $self=shift;
    if (my $q=shift) {
	$self->{"SWAPXY"}=$q;
    }
    return $self->{"SWAPXY"};
}

=head2 original_file_name

  Arg [0]    : 	none
  Example    : 	my $cel_file_name=$cel->original_file_name();
  Description:	If this object was created using parse_from_file, the original filename. Otherwise undef.
  Returntype :	string
  Exceptions : 	none
  Caller     : 	general

=cut

sub original_file_name {
    my $self=shift;

    return $self->{"file_name"};
}


# Algorithm name

=head2 algorithm_name

  Arg [1]    : 	string $algorithm_name (optional)
  Example    : 	my $algorithm_name=$cel->algorithm_name();
  Description:	Get/set the algorithm name that created this CEL file.
  Returntype :	string
  Exceptions : 	none
  Caller     : 	general

=cut
sub algorithm_name {
    my $self=shift;
    if (my $q=shift) {
	$self->{"ALGORITHM"}=$q;
    }

    return $self->{"ALGORITHM"};
}

=head2 algorithm_params

  Arg [1]    : 	hashref $algorithm_params (optional)
  Example    : 	my %algorithm_params=%{$cel->algorithm_params()};

# Print margin of cells ignored for calculating signal

print $algorithm_params("CellMargin");

  Description:	Get/set the algorithm parameters for the CEL file creation
  Returntype :	hashref
  Exceptions : 	none
  Caller     : 	general

=cut


sub algorithm_params {
    my $self=shift;
    if (my $q=shift) {
	$self->{"ALGORITHMPARAMS"}=$q;
    }

    return $self->{"ALGORITHMPARAMS"};
}


=head2 intensity_map
  Arg [1]    : 	optional arrayref
  Example    : 	print $cel->intensity_map()->[0][0]->[0]
  Description: 	Returns an reference to a 2D array. Each value in this array is another arrayref containing (in order):
    Mean intensity, Standard Deviation of intensity, number of pixels
  used in the calculation, a flag stating whether the user has masked
  this square, a flag stating whether the software has called this
  square an outlier.
  Returntype : 2d arrayref
  Exceptions : none
  Caller     : general
=cut

sub intensity_map {
    my $self=shift;
    if (my $q=shift) {
	$self->{"_INTENSITY"}=$q;
    }

    return $self->{"_INTENSITY"};
}


=head2 parse_from_string

  Arg [1]    : 	string
  Example    : 	$cel->parse_from_string($cel_file_in_a_string);
  Description:	Parse a CEL file from a buffer in memory
  Returntype :	none
  Exceptions : 	none
  Caller     : 	general

=cut


sub parse_from_string {
    my $self=shift;
    my $string=shift;


    open CEL,"<",\$string or die "Cannot open string stream";

    $self->parse_from_filehandle(\*CEL);

    close CEL;
}

=head2 parse_from_file

  Arg [1]    : 	string
  Example    : 	$cel->parse_from_file($cel_filename);
  Description:	Parse a CEL file from a file
  Returntype :	none
  Exceptions : 	dies if cannot open file
  Caller     : 	general

=cut

sub parse_from_file {
    my $self=shift;
    my $filename=shift;

    $self->{"file_name"}=$filename;

    open CDF,"<".$filename or die "Cannot open file ".$filename;

    $self->parse_from_filehandle(\*CDF);

    close CDF;
}

=head2 parse_from_filehandle

  Arg [1]    : 	reference to filehandle
  Example    : 	$cel->parse_from_filehandle(\*STDIN);
  Description:	Parse a CEL file from a filehandle
  Returntype :	none
  Exceptions : 	none
  Caller     : 	general

=cut

sub parse_from_filehandle {
    my $self=shift;
    $self->{"FH"}=shift;

    binmode $self->{"FH"};

    # First step- detect whether it's a GCOS or MAS5 file
    
    # A buffer for reading things into
    my $buffer; 

    # XDA files have their first feature as a magic number, 64

    read ($self->{"FH"}, $buffer, 4) or die "Cannot read from file";
    my $magic_number = unpack("V", $buffer);


    if ($magic_number==64) {
	# It's a GCOS v1.2 "v4 file", XDA file! Hurrah!
	$self->_parse_xda($self->{"FH"});
	delete $self->{"FH"};
	return;
    }

    binmode $self->{"FH"},":crlf";

    $buffer.=readline($self->{"FH"});

    if ($buffer eq "[CEL]\n") {
	# It's a MAS5/GCOS v1.0 "v3 file"! Yippee!
	$self->_parse_mas5();
	delete $self->{"FH"};

	return;
    }

    croak "This doesn't look like a CEL file to me.";
}

sub _parse_xda {
    my $self=shift;
    
    $self->{"FORMAT"}="XDA";

    my $buffer; 

    # First some trivia

    (read ($self->{"FH"}, $buffer, 4)==4) or croak "Can no longer read from file";
    $self->{"VERSION"}= unpack ("V", $buffer);
    
    if ($self->{"VERSION"}!=4) {
	carp "This CEL file is newer than the software parsing them. Results may be suspect."; # die here, perhaps?
    } 

    # CEL file trivia

    (read ($self->{"FH"}, $buffer, 12)==12) or die "Can no longer read from file";
    ($self->{"COLS"},$self->{"ROWS"},undef)= unpack ("V3", $buffer);

    {
	# Header, if you can be bothered
	my $headerstring=$self->_unpack_length_string($self->{"FH"});
    }

    # Algorithm name
    $self->{"ALGORITHM"}=$self->_unpack_length_string($self->{"FH"});

    {
	$self->{"ALGORITHMPARAMS"}={};
	my $algorithmparamsstr=$self->_unpack_length_string($self->{"FH"});
	foreach my $i (split /[; ]/,$algorithmparamsstr) {
	    my ($k,$v)=split /[\=\-\:]/,$i;
	    $self->{"ALGORITHMPARAMS"}->{$k}=$v;
	}
	
    }


    (read ($self->{"FH"}, $buffer, 16)==16) or die "Can no longer read from file";

    my $outliercount;
    my $maskedcount;
    my $subgrids;

    # Cell margin is put in Algorithm Parameters in MAS5 files. We'll emulate this behaviour here.

    ($self->{"ALGORITHMPARAMS"}->{"CellMargin"},$outliercount,$maskedcount,$subgrids)=unpack("V4",$buffer);

    if ($subgrids!=0) {
	croak "Bio::Affymetrix::CEL cannot do subgrids";
    }


    # Intensities

    my @intensitymap;

    for (my $y=0;$y<$self->{"ROWS"};$y++) {
	for (my $x=0;$x<$self->{"COLS"};$x++) {

	    (read ($self->{"FH"}, $buffer, 10)==10) or croak "Can no longer read from file";
	    my @q= unpack ("f2S", $buffer);

	    push @q,(undef,undef);

	    $intensitymap[$x][$y]=\@q;

	}
    }

    # Masks 

    for (my $i=0;$i<$maskedcount;$i++) {
	(read ($self->{"FH"}, $buffer, 4)==4) or croak "Can no longer read from file";
	my ($x,$y)= unpack ("S2", $buffer);
	
	$intensitymap[$x][$y]->[3]=1;
	
    }


    for (my $i=0;$i<$outliercount;$i++) {
	(read ($self->{"FH"}, $buffer, 4)==4) or croak "Can no longer read from file";
	my ($x,$y)= unpack ("S2", $buffer);
	
	$intensitymap[$x][$y]->[4]=1;
	
    }

    $self->{"_INTENSITY"}=\@intensitymap;
}

sub _parse_mas5 {
    my $self=shift;

    # Obtain file version, and do some rudimentary checking of information
    
    $self->{"FORMAT"}="MAS5";
    
    my $i=$self->_next_line();
    
    my ($name,$value)=$self->_split_line($i);
    
    if ($name ne "Version") {
	croak "File does not look like a CEL file to me";
    }
    
    if ($value ne "3") {
	croak "Can't understand any version of MAS5 CEL files other than 3";
    }
    
    $self->{"VERSION"}=$value;


    # Parse the rest of the file
    $i=$self->_next_line();

    while (!eof $self->{"FH"}) {
	if ($i eq "[HEADER]") {
	    $i=$self->_parse_header_section($i);
	} elsif ($i eq "[INTENSITY]") {
	    $i=$self->_parse_intensity_section($i);
	} elsif ($i eq "[MASKS]") {
	    $i=$self->_parse_mask_section($i);
	} elsif ($i eq "[OUTLIERS]") {
	    $i=$self->_parse_outlier_section($i);
	} else {
	    $i=$self->_next_line();
	}
    }
}


# Parsing bits of the CDF file 

sub _parse_header_section {
    my $self=shift;
    my $i=shift;;
    while (!(($i=$self->_next_line())=~/^\[.*\]$/)) {
	my ($name,$value)=$self->_split_line($i);
	if ($name eq "TotalX" || $name eq "TotalY") {
	    ; # Do nothing- this contains no information
	} elsif ($name eq "AlgorithmParameters") { 
	    # Apparently, this file can have = dilimited too
	    my @list=split /;/,$value;
	    my %ap;
	    foreach my $q (@list) {
		my ($a,$b)=split /:/,$q;
		$ap{$a}=$b;
	    }

	    $self->{"ALGORITHMPARAMS"}=\%ap;

	} else {
	    $self->{uc $name}=$value;
	}
    }

    return $i;
}

sub _parse_intensity_section {
    my $self=shift;

    my $i=shift;

    my $fh=$self->{"FH"};

    my @intensitymap;

    $i=<$fh>; # Two lines of junk
    $i=<$fh>;


    while ((($i=<$fh>)=~/^\s*(\d+)\s+(\d+)\s+([\d\.]+)\s+([\d\.]+)\s+(\d+)/o)) {
	$intensitymap[$1][$2]=[$3,$4,$5,undef,undef];
	
    }


    $self->{"_INTENSITY"}=\@intensitymap;


    chomp $i;
    return $i;
}


sub _parse_mask_section {
    my $self=shift;
    shift;

    my $i;
    $i=readline $self->{"FH"}; # Two lines of junk
    $i=readline $self->{"FH"};

    while ((($i=readline $self->{"FH"})=~/^\s*(\d+)\s+(\d+)\s*$/o)) {
	$self->{"_INTENSITY"}->[$1][$2]->[3]=1;
    }


    chomp $i;
    return $i;
}


sub _parse_outlier_section {
    my $self=shift;
    shift;

    my $i;
    $i=readline $self->{"FH"}; # Two lines of junk
    $i=readline $self->{"FH"};

    while ((($i=readline $self->{"FH"})=~/^\s*(\d+)\s+(\d+)\s*$/o)) {
	$self->{"_INTENSITY"}->[$1][$2]->[4]=1;
    }

    chomp $i;
    return $i;
}



# General INI utility functions

sub _split_line {
    my $self=shift;
    my $line=shift;
    
    my @q=split /=/,$line,2;

    if (scalar(@q)!=2) {
	die "Can't parse line ".$line;
    }

    return @q;
}

# Sub that ignores blank lines

sub _next_line {
    my $self=shift;
    my $q;
    
    my $fh=$self->{"FH"};

    do {
	$q=<$fh>;
	chomp $q;
    } while (!eof $fh&&$q=~/^\s*$/);

    if (!eof $fh) {
	return $q;
    } else {
	return undef;
    }
}


# Writing

sub write_to_filehandle {
    my $self=shift;
    my $filehandle=shift;
    my $format=shift;
    my $version=shift;

    binmode $filehandle,":crlf";
}

# binary file utility to read a length-defined string

sub _unpack_length_string {
    my $self=shift;
    my $fh=shift;
    
    my $buffer;

    (read ($fh, $buffer, 4)==4) or die "Can no longer read from file";;
    my $len = unpack ("V", $buffer);
    (read ($fh, $buffer, $len)==$len) or die "Can no longer read from file";

    return unpack("a".$len,$buffer);

}


1;

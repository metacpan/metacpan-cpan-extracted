#!/usr/bin/perl

# A package for parsing CDF files

# Docs come before the code

=head1 NAME

Bio::Affymetrix::CDF- parse Affymetrix CDF files

=head1 SYNOPSIS

use Bio::Affymetrix::CDF;

# Parse the CDF file

my $cdf=new Bio::Affymetrix::CDF({"probemode"=>0});

$cdf->parse_from_file("foo.cdf");

# Find some fun facts about this chip type

print $cdf->rows().",".$cdf->cols()."\n";

print $cdf->version()."\n";



# Print out all of the probeset names on this chip type

foreach my $i (keys %{$chp->probesets}) {
    print $chp->probesets->{$i}->name()."\n";
}

=head1 DESCRIPTION

The Affymetrix microarray system produces files in a variety of
formats. If this means nothing to you, these modules are probably not
for you :). This module parses CDF files. Use this module if you want
to find out about the design of an Affymetrix GeneChip, or you need the
object for another one of the modules in this package.

All of the Bio::Affymetrix modules parse a file entirely into
memory. You therefore need enough memory to hold these objects. For
some applications, parsing as a stream may be more appropriate-
hopefully the source to these modules will give enough clues to make
this an easy task. This module in particular takes a lot of memory if
probe information is also stored (about 150Mb). Memory usage is not too
onorous (about 15Mb) if probe level information is omitted. You
can.control this by setting probemode=>1 or probemode=>0 in the constructor.

You can also use these modules to write CDF files (using the
write_to_filehandle method). See COMPATIBILITY for some important caveats.

=head2 HINTS

You fill the object filled with data using the
parse_from_filehandle, parse_from_string or parse_from_file
routines. You can get/set various statistics using methods on the
object.

The key method is probesets. This returns a reference to a hash of
Bio::Affymetrix::CDF::Probeset objects. The keys of this hash are unit
number - if you are looking for a specific probeset you will have to
search for it yourself. Each Bio::Affymetrix::CDF::Probeset object
contains information about the probesets. 


=head1 NOTES

=head2 REFERENCE

Modules were written with the official Affymetrix documentation, which
can be located at http://www.affymetrix.com/support/developer/AffxFileFormats.ZIP

=head2 COMPATIBILITY

This module can parse the CDF files used with the Affymetrix software
MAS 5 and GCOS. These files have QC information in them (such as the
information of the location of the QC probesets), which is not parsed.

This module can also write CDF files. The support is currently pretty
limited .Currently the software can only write MAS5 files (not XDA
format files), and will only write files that have been parsed in
previously- it cannot create CDF files from scratch. So if you have
any way of making Affymetrix chips, you will just have to look
elsewhere :). These limitations are caused through not parsing the QC
information. 

=head1 TODO

Parsing QC information? Rearrange probe information to make it more usable?

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


package Bio::Affymetrix::CDF;


use Carp;
use warnings;
use strict;
our $VERSION=0.5;

use Bio::Affymetrix::CDF::Probeset;

=head2 new

  Arg [1]    : hashref of parameters (optional)
  Example    : my $cdf=new Bio::Affymetrix::CDF({probemode=>1);
  Description: constructor for CDF object. Turn probemode on and off (default off) by supplying named parameters as a hash reference
  Returntype : new Bio::Affmetrix::CDF object
  Exceptions : none
  Caller     : general

=cut

sub new {
    my $class=shift;
    my $q=shift;
    my $self={};

    if (ref $q eq "HASH" && exists $q->{"probemode"}) {
	$self->{"_PROBEMODE"}=$q->{"probemode"};
    } else {
	$self->{"_PROBEMODE"}=undef;
    }

    $self->{"PROBESETS"}={};

    bless $self,$class;
    return $self;
}

# Getter/setters

# CDF file trivia
=head2 original_version
  Arg [0]    : 	none
  Example    : 	my $version=$cdf->original_version()
  Description: 	Returns the version of the CDF file parsed. Encoded in file.
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
  Example    : 	my $format=$cdf->original_format()
  Description:	Returns the format of the CDF file parsed. Currently
    MAS5 or XDA.
  Returntype : 	string
  Exceptions : 	none
  Caller     : 	general

=cut


sub original_format {
    my $self=shift;
    return $self->{"FORMAT"};
}

# Chip name

=head2 name
  Arg [1]    : 	string $name (optional)
  Example    : 	my $name=$cdf->name()
  Description: 	Get/set the name of this chip type
  (e.g. ATH1-121501). Only supplied by MAS5 version files.
  Returntype : string
  Exceptions : none
  Caller     : general
=cut

sub name {
    my $self=shift;
    if (my $q=shift) {
	$self->{"NAME"}=$q;
    }
    return $self->{"NAME"};
}

=head2 resequencing_reference_sequence
  Arg [1]    : 	string $refseq (optional)
  Example    : 	my $refseq=$cdf->resequencing_reference_sequence()
  Description: 	Get/set the name of resequencing_reference_sequence.
Only available in GCOS format files
  Returntype : string
  Exceptions : none
  Caller     : general
=cut

sub resequencing_reference_sequence {
    my $self=shift;
    if (my $q=shift) {
	$self->{"NAME"}=$q;
    }
    return $self->{"NAME"};
}



=head2 rows
  Arg [1]    : 	integer $rows (optional)
  Example    : 	my $name=$cdf->rows()
  Description: 	Get/set the number of rows in this chip
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut

sub rows {
    my $self=shift;
    if (my $q=shift) {
	$self->{"ROWS"}=$q;
    }
    return $self->{"ROWS"};
}

=head2 cols
  Arg [1]    : 	integer $cols (optional)
  Example    : 	my $name=$cdf->cols()
  Description: 	Get/set the number of cols in this chip
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut

sub cols {
    my $self=shift;
    if (my $q=shift) {
	$self->{"COLS"}=$q;
    }
    return $self->{"COLS"};
}

=head2 probesets
  Arg [1]    : 	hashref $probesets 
  Example    : 	my %probesets=%{$cdf->probesets()}
  Description: 	Get the probesets on the array
  Returntype : an reference to an hash of
Bio::Affymetrix::CDF::Probeset objects (q.v.), keyed on unit number
  Exceptions : none
  Caller     : general
=cut


sub probesets {
    my $self=shift;

    if (my $q=shift) {
	$self->{"PROBESETS"}=$q;
    }

    return $self->{"PROBESETS"};
}


=head2 probe_grid
  Arg [1]    : arrayref $probelist
    Example    : my $probe=$ps->probe_grid()->[500][500]; #Return probe at 500,500
  Description: Get/set the grid of probes making up this array. Only available if
    with probes mode is used.

    Returns an reference to a two dimensional array of
    Bio::Affymetrix::CDF::Probe objects. 
  Returntype : reference to two-dimensional array of Bio::Affymetrix::CDF::Probe objects
  Exceptions : none
  Caller     : general
=cut


sub probe_grid {
    my $self=shift;
    if (!$self->{"_PROBEMODE"}) {
	croak "probe_grid is not available when not in probemode";
    }

    if (my $q=shift) {
	$self->{"PROBEGRID"}=$q;
    }
    return $self->{"PROBEGRID"};
}


# These are all named "original_" because they aren't calculated, they are what a parsed file claims

=head2 original_number_of_probes
  Arg [0]    : 	none
  Example    : 	my $number_of_probes=$cdf->original_number_of_probes()
  Description: 	Get the number of probesets on the array, as listed
originally in the file. A better way is to do my
$q=scalar(@{$cdf->probesets()}); if you want a current count. Should really be called original_number_of_probesets.
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut


sub original_number_of_probes {
    my $self=shift;
    return $self->{"NUMBEROFUNITS"};
}

=head2 original_max_unit
  Arg [0]    : 	none
  Example    : 	my $max_units=$cdf->original_max_units()
  Description: 	Get the max unit number in the CDF file. Fairly useless. Only available in MAS5 files
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut

sub original_max_unit {
    my $self=shift;
    return $self->{"MAXUNIT"};
}

=head2 original_num_qc_units
  Arg [0]    : 	none
  Example    : 	my $max_units=$cdf->original_num_qc_units()
  Description: 	Get the number of QC units in the CDF file. Only piece
of QC information obtainable using this piece of software.
  Returntype : integer
  Exceptions : none
  Caller     : general
=cut


sub original_num_qc_units {
    my $self=shift;
    return $self->{"NUMQCUNITS"};
}

=head2 original_file_name

  Arg [0]    : 	none
  Example    : 	my $cdf_file_name=$cdf->original_file_name();
  Description:	If this object was created using parse_from_file, the original filename. Otherwise undef.
  Returntype :	string
  Exceptions : 	none
  Caller     : 	general

=cut


sub original_file_name {
    my $self=shift;

    return $self->{"file_name"};
}


# PARSING ROUTINES

=head2 parse_from_string

  Arg [1]    : 	string
  Example    : 	$cdf->parse_from_string($cdf_file_in_a_string);
  Description:	Parse a CDF file from a buffer in memory
  Returntype :	none
  Exceptions : 	none
  Caller     : 	general

=cut


sub parse_from_string {
    my $self=shift;
    my $string=shift;


    open CDF,"<",\$string or carp "Cannot open string stream";

    $self->parse_from_filehandle(\*CDF);

    close CDF;
}

=head2 parse_from_file

  Arg [1]    : 	string
  Example    : 	$cdf->parse_from_file($cdf_filename);
  Description:	Parse a CDF file from a file
  Returntype :	none
  Exceptions : 	dies if cannot open file
  Caller     : 	general

=cut

sub parse_from_file {
    my $self=shift;
    my $filename=shift;

    $self->{"file_name"}=$filename;
    open CDF,"<".$filename or carp "Cannot open file ".$filename;

    $self->parse_from_filehandle(\*CDF);

    close CDF;
}

=head2 parse_from_filehandle

  Arg [1]    : 	reference to filehandle
  Example    : 	$cdf->parse_from_filehandle(\*STDIN);
  Description:	Parse a CDF file from a filehandle
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

    # XDA files have their first feature as a magic number, 65

    read ($self->{"FH"}, $buffer, 4) or die "Cannot read from file";
    my $magic_number = unpack("V", $buffer);


    if ($magic_number==67) {
	# It's a GCOS v1.2 "v4 file", XDA file! Hurrah!
	$self->_parse_xda($self->{"FH"});
	delete $self->{"FH"};
	return;
    }

    binmode $self->{"FH"},":crlf";

    $buffer.=readline($self->{"FH"});

    if ($buffer eq "[CDF]\n") {
	# It's a MAS5/GCOS v1.0 "v3 file"! Yippee!
	$self->_parse_mas5($self->{"FH"});
	return;
	delete $self->{"FH"};
    }

    die "This doesn't look like a CDF file to me.";
}

sub _parse_xda {
    my ($self,$fh) = @_;
    
    $self->{"FORMAT"}="XDA";
    
    my $buffer; 

    # First some trivia

    (read ($fh, $buffer, 4)==4) or croak "Can no longer read from file";
    $self->{"VERSION"}= unpack ("V", $buffer);
    
    if ($self->{"VERSION"}!=1) {
	carp "This CDF file is newer than the software parsing them. Results may be suspect."; # die here, perhaps?
    } 

    # CDF file trivia

    (read ($fh, $buffer, 12)==12) or die "Can no longer read from file";
    ($self->{"COLS"},$self->{"ROWS"},$self->{"NUMBEROFUNITS"},$self->{"NUMQCUNITS"})= unpack ("S2V2", $buffer);

    $self->{"RESEQREFSEQ"}=$self->_unpack_length_string($fh); #What's this?

    # Probe names

    $self->{"PROBESETS"}={};

    for (my $i=1;$i<=$self->{"NUMBEROFUNITS"};$i++) {
	(read ($fh, $buffer, 64)==64)  or die "Can no longer read from file";
#	my $name=unpack("Z64",$buffer);
#	$self->{"PROBESETS"}->{$i}=new Bio::Affymetrix::CDF::Probeset;
#	$self->{"PROBESETS"}->{$i}->name($name);
    }

    # File offsets that are not useful for us
    read ($fh, $buffer, 4*($self->{"NUMBEROFUNITS"}+$self->{"NUMQCUNITS"}));

    # QC information is just stored, for now

    for (my $i=0;$i<$self->{"NUMQCUNITS"};$i++) {
	(read ($fh, $buffer, 6)==6)  or die "Can no longer read from file";
	my ($junk,$numprobe)=unpack("SV",$buffer);
	$self->{"_qcinfo"}.=$buffer;
	(read ($fh, $buffer, 7*$numprobe)==7*$numprobe)  or die "Can no longer read from file";
	$self->{"_qcinfo"}.=$buffer;
    }

    # Probe information
    for (my $i=1;$i<=$self->{"NUMBEROFUNITS"};$i++) {
	my $ps=new Bio::Affymetrix::CDF::Probeset();
	$ps->_parse_from_filehandle_bin($fh,$self->{"_PROBEMODE"});
	$ps->{"CDF"}=$self;
	$self->{"PROBESETS"}->{$ps->{"UNITNUMBER"}}=$ps;
    }
}


sub _parse_mas5 {
    my $self=shift;

    binmode $self->{"FH"},":crlf";
    # Obtain file version, and do some rudimentary checking of information
    {
	$self->{"FORMAT"}="MAS5";

	my $i=$self->_next_line();

	my ($name,$value)=$self->_split_line($i);

	if ($name ne "Version") {
	    die "File does not look like a CDF file to me";
	}

	if ($value ne "GC3.0") {
	    die "Can't understand any other type of CDF file other than GC3.0";
	}
	
	$self->{"VERSION"}=$value;
    }

    # Parse the rest of the file
    my $i=$self->_next_line();

    while (!eof $self->{"FH"}) {
	if ($i eq "[Chip]") {
	    $i=$self->_parse_chip_section($i);
	} elsif ($i=~/\[QC\d+\]/) {
	    $i=$self->_parse_qc_section($i);
	} elsif ($i=~/\[Unit\d+\]/) {
	    $i=$self->_parse_unit_section($i);
	} else {
	    $i=$self->_next_line();
	}
    }
}

# Parsing bits of the CDF file 

sub _parse_chip_section {
    my $self=shift;
    my $i=shift;;
    while (!(($i=$self->_next_line())=~/^\[.*\]$/)) {
	my ($name,$value)=$self->_split_line($i);
	$self->{uc $name}=$value;
    }

    return $i;
}

sub _parse_qc_section {
    my $self=shift;

    my $i=shift;

    my $fh=$self->{"FH"};

    $self->{"_qcinfo"}.=$i."\n";

    while (!(($i=<$fh>)=~/^^\s*\[.*\]\s*$/)) {
	# QC sections still bore
	# us, but we're now going to store them for later 

	$self->{"_qcinfo"}.=$i;
	
	
    }
    chomp $i;
    return $i;
}


sub _parse_unit_section {
    my $self=shift;
    shift;
    my $i=new Bio::Affymetrix::CDF::Probeset;
    $i->CDF($self);
    my $ret=$i->_parse_from_filehandle($self->{"FH"},$self->{"_PROBEMODE"});
    

    
    $self->{"PROBESETS"}->{$i->original_unit_number()}=$i;
    
    return $ret;
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

=head2 write_to_file

  Arg [1]    : 	string $filename
  Arg [2]    : 	string $format
  Arg [3]    : 	string $version
  Example    : 	$cdf->write_to_file($cdf_filename);
  Description:	Writes a CDF file to a file. See write_to_filehandle for descriptions of format and version
  Returntype :	none
  Exceptions : 	dies if cannot open file
  Caller     : 	general

=cut

sub write_to_file {
    my $self=shift;
    my $filename=shift;

    open CDF,">".$filename or croak "Cannot open file for writing ".$filename;

    $self->write_to_filehandle(\*CDF,@_);

    close CDF;
}

=head2 write_to_filehandle

  Arg [1]    : 	filehandle $filehandle
  Arg [2]    : 	string $format
  Arg [3]    : 	string $version
  Example    : 	$cdf->write_to_filehandle($cdf_filename);
  Description:	Writes a CDF file to a filehandle. Takes arguments of
  the filehandle, the desired format, and the desired version of that
  format.

  Currently, format defaults to MAS5, and version defaults to
  GC3.0. These are the only formats the software is capable of
  producing currently. Also, this software cannot write files that
  were read in using the GCOS file format. The original CDF file must
  have been parsed in probe mode.

  Returntype :	none
  Exceptions : 	dies if cannot open file
  Caller     : 	general

=cut


sub write_to_filehandle {
    my $self=shift;
    my $filehandle=shift;
    my $format=shift;
    my $version=shift;

    if (!$self->{"_PROBEMODE"}) {
	croak "No writing when not in probemode";
    }

    if (!defined $version) {
	$version="GC3.0";
    }

    if (!defined $format) {
	$format="MAS5";
    }


    binmode $filehandle,":crlf";



    if (defined $version && $version ne "GC3.0") {
	croak "Bio::Affymetrix::CDF module cannot do any other version than GC3.0 currently";
    }

    $version="GC3.0";

    if ($format ne "MAS5") {
	croak "Bio::Affymetrix::CDF module can only produce MAS5 CDF files currently";
    }

    if ($self->original_format() eq "XDA") {
	carp "You cannot produce authentic MAS5 CDF files starting from an XDA CDF file (yet). Output will continue, but resulting CDF file will be unusable";
    }

    # Chipfile trivia

    my $maxunit=-3000;

    foreach my $i (keys %{$self->probesets()}) {
	if ($i>$maxunit) {
	    $maxunit=$i;
	}
    }

    print $filehandle "[CDF]\nVersion=".$version."\n\n";
    # Uses $self->probesets as an arrayref (rather than hashref) for
    # calculating NumberOfUnits here

    if (!defined($self->name())) {
	carp("GCOS format files do not have a name. Use the name() method if you want to set a name for this chip in the output.");
    }

    print $filehandle "[Chip]\nName=".$self->name()."\nRows=".$self->rows()."\nCols=".$self->cols()."\nNumberOfUnits=".(scalar(keys %{$self->probesets()}))."\nMaxUnit=".$maxunit."\nNumQCUnits=".$self->original_num_qc_units()."\nChipReference=\n\n";


    print $filehandle $self->{"_qcinfo"} unless ($self->original_format() eq "XDA");

    foreach my $i (sort {int($a)<=>int($b)} keys %{$self->probesets()}) {

	my $numcells=0;
	
	my $z=$self->probesets()->{$i};

	# Calulate number of cells (or probes, in English)

	foreach my $v (@{$z->probe_pairs()}) {
	    $numcells+=scalar (@$v)
	}

	print $filehandle "[Unit".$i."]\n";
	print $filehandle "Name=".$z->unit_name()."\n";
	print $filehandle "Direction=".($z->is_sense()?1:2)."\n";
	print $filehandle "NumAtoms=".scalar(@{$z->probe_pairs()})."\n";
	print $filehandle "NumCells=".$numcells."\n";
	print $filehandle "UnitNumber=".$i."\n";
	print $filehandle "UnitType=".$z->{"UNITTYPE"}."\n";
	print $filehandle "NumberBlocks=1\n\n";

	print $filehandle "[Unit".$i."_Block1]\n";
	print $filehandle "Name=".$z->name()."\nBlockNumber=1\n";
	print $filehandle "NumAtoms=".scalar(@{$z->probe_pairs()})."\n";
	print $filehandle "NumCells=".$numcells."\n";
	print $filehandle "StartPosition=0\nStopPosition=".(scalar(@{$z->probe_pairs()})-1)."\n";
	print $filehandle "CellHeader=X	Y	PROBE	FEAT	QUAL	EXPOS	POS	CBASE	PBASE	TBASE	ATOM	INDEX	CODONIND	CODON	REGIONTYPE	REGION\n";

	my $count=1;

	for (my $x=0;$x<scalar(@{$z->probe_pairs()});$x++) {
	    foreach my $i (@{$z->probe_pairs()->[$x]}) {
		print $filehandle "Cell".($count)."=".join("\t",($i->x(),$i->y(),"N","control",$z->name(),$x,$i->mismatch_position(),$i->probe_target_base(),$i->probe_mismatch_base(),$i->probe_target_base(),$x,$i->index(),-1,-1,99,""))."\n";
		$count++;
	    }
	}

	print $filehandle "\n\n";
    }
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

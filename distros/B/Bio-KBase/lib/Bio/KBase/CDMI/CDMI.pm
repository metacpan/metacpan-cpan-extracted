#!/usr/bin/perl -w

#
# Copyright (c) 2003-2006 University of Chicago and Fellowship
# for Interpretations of Genomes. All Rights Reserved.
#
# This file is part of the SEED Toolkit.
#
# The SEED Toolkit is free software. You can redistribute
# it and/or modify it under the terms of the SEED Toolkit
# Public License.
#
# You should have received a copy of the SEED Toolkit Public License
# along with this program; if not write to the University of Chicago
# at info@ci.uchicago.edu or the Fellowship for Interpretation of
# Genomes at veronika@thefig.info or download a copy from
# http://www.theseed.org/LICENSE.TXT.
#

package Bio::KBase::CDMI::CDMI;

    use strict;
    use Tracer;
    use base qw(ERDB);
    use Stats;
    use DBKernel;
    use SeedUtils;
    use BasicLocation;
    use XML::Simple;
    use Digest::MD5;
    use Getopt::Long;
    use Data::UUID;

=head1 CDMI Package

Sapling Database Access Methods

=head2 Introduction

The CDMI database represents an instance of the Kbase Central Data
Model. This object has minimal
capabilities: most of its power comes the L<ERDB> base class.

The fields in this object are as follows.

=over 4

=item loadDirectory

Name of the directory containing the key load files.

=item tuning

Reference to a hash of tuning parameters.

=back

=head2 Configuration and Construction

The database is governed by tuning parameters in an XML configuration file. The
file name should be C<CdmiConfig.xml> in the load directory. The tuning
parameters that affect the way the data is loaded. These are specified as
attributes in the TuningParameters element, as follows.

=over 4

=item maxLocationLength

The maximum number of base pairs allowed in a single location. B<IsLocatedIn>
records are split into sections based on this length, so when you are looking
for all the features in a particular neighborhood, you can look for locations
within the maximum location distance from the neighborhood, and even if you have
a huge operon that contains tens of thousands of base pairs, you'll still be
able to find it.

=item maxSequenceLength

The maximum number of base pairs allowed in a single DNA sequence. DNA sequences
are broken into segments to prevent excessively large genomes from clogging
memory during sequence resolution.

=back

=head3 Loading

Unlike a normal ERDB database, the CDMI is loaded in sections, usually one
genome at a time, rather than in a massive full-database load. The standard
load support is therefore not present.

=head3 Tuning Parameter Defaults

Each tuning parameter must have a default value, in case it is not present in
the XML configuration file. The defaults are specified in a constant hash
reference called C<TUNING_DEFAULTS>.

=cut

    use constant TUNING_DEFAULTS => {
        maxLocationLength => 4000,
        maxSequenceLength => 10000,
    };

=head3 new

    my $cdmi = CDMI->new(%options);

Construct a new CDMI object. The following options are supported.

=over 4

=item loadDirectory

Data directory to be used by the loaders. The default is C</var/kbase/cdm>.

=item DBD

XML database definition file. The default is taken from the C<CDMIDBD> environment
variable, or C<KSaplingDBD.xml> in the load directory if the environment
variable is not set.

=item dbName

Name of the database to use. The default is C<kbase_sapling>.

=item sock

Socket for accessing the database. The default is the system default.

=item userData

Name and password used to log on to the database, separated by a slash.
The default is a user name of C<seed> and no password.

=item dbhost

Database host name. The default is C<localhost>.

=item port

MYSQL port number to use (MySQL only). The default is C<3306>.

=item dbms

Database management system to use (e.g. C<postgres>). The default is
C<mysql>.

=item uuid

L<Data::UUID> object for generating annotation IDs. Will not exist
unless it's needed.

=item develop

If TRUE, then the development database will be used. The development
database is located on a different server with a different DBD. This
option overrides C<dbhost>, C<externalDBD>, C<dbname>, and C<DBD>.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, %options) = @_;
    # Get the options.
    if (! $options{loadDirectory}) {
        $options{loadDirectory} = "/home/parrello/CdmiData";
    }
    my $dbd = $options{DBD} || $ENV{CDMIDBD} || "$options{loadDirectory}/Published/KSaplingDBD.xml";
    my $dbhost = $options{dbhost} || "db1.chicago.kbase.us"; # "bio-data-1.mcs.anl.gov";
    my $dbName = $options{dbName} || "kbase_sapling_v1";
    my $userData = $options{userData} || "kbase_sapselect/oiwn22&dmwWEe";
    if ($options{develop}) {
        $dbd = "$options{loadDirectory}/KSaplingDBD.xml";
        $dbhost = "oak.mcs.anl.gov";
        $dbName = "kbase_sapling";
        $options{externalDBD} = 1;
    }
    my $port = $options{port} || 3306;
    my $dbms = $options{dbms} || 'mysql';
    # Insure that if the user specified a DBD, it overrides the internal one.
    if ($options{DBD} && ! defined $options{externalDBD}) {
        $options{externalDBD} = 1;
    }
    # Compute the socket. An empty string is a valid override here.
    my $sock = $options{sock};
    if (! defined $sock) {
        $sock = $FIG_Config::sproutSock || "";
    }
    # Compute the user name and password.
    my ($user, $pass) = split '/', $userData, 2;
    $pass = "" if ! defined $pass;
    Trace("Connecting to CDMI database.") if T(2);
    # Connect to the database.
    my $dbh = DBKernel->new($dbms, $dbName, $user, $pass, $port, $dbhost, $sock);
    # Create the ERDB object.
    my $retVal = ERDB::new($class, $dbh, $dbd, %options);
    # Set up the space for the tuning parameters.
    $retVal->{tuning} = undef;
    # Return it.
    return $retVal;
}

=head3 new_for_script

    my $cdmi = CDMI->new_for_script(%options);

Construct a new CDMI object for a command-line script. This method
uses a call to L<GetOpt::Long/getoptions> to parse the command-line
options, with the incoming B<options> parameter as a parameter.
The following command-line options (all of which are optional) will
also be processed by this method and used to construct the CDMI object.

If the command-line parse fails, an undefined value will be returned
rather than a CDMI object.

=over 4

=item loadDirectory

Data directory to be used by the loaders.

=item DBD

XML database definition file.

=item dbName

Name of the database to use.

=item sock

Socket for accessing the database.

=item userData

Name and password used to log on to the database, separated by a slash.

=item dbhost

Database host name.

=item port

MYSQL port number to use (MySQL only).

=item dbms

Database management system to use (e.g. C<postgres>, default C<mysql>).

=item develop

If specified, then the development database will be used. This database
is located on a different server with a different DBD. The C<develop>
option overrides C<dbhost>, C<dbname> and C<DBD>, and forces use of an
external DBD.

=back

=cut

sub new_for_script {
    # Get the parameters.
    my ($class, %options) = @_;
    # We'll put the return value in here if the command-line parse fails.
    my $retVal;
    # Create the variables for our internal options.
    my ($loadDirectory, $dbd, $dbName, $sock, $userData, $dbhost, $port, $dbms, $develop);
    # Parse the command line.
    my $rc = GetOptions(%options, "loadDirectory=s" => \$loadDirectory,
            "DBD=s" => \$dbd, "dbName=s" => \$dbName, "sock=s" => \$sock,
            "userData=s" => \$userData, "dbhost=s" => \$dbhost,
            "port=i" => \$port, "dbms=s" => \$dbms, develop => \$develop);
    # If the parse worked, create the CDMI object.
    if ($rc) {
        $retVal = Bio::KBase::CDMI::CDMI::new($class, loadDirectory => $loadDirectory, DBD => $dbd,
                dbName => $dbName, sock => $sock, userData => $userData,
                dbhost => $dbhost, port => $port, dbms => $dbms,
                develop => $develop);
    }
    # Return the result.
    return $retVal;
}


=head2 Public Methods

=head3 ComputeTaxonID

    my $taxID = $cdmi->ComputeTaxonID($scientificName);

Compute the best-match taxonomy ID for a genome with the specified
scientific name. An attempt will be made to match to the strain and
then the genus and species. If no match is found, an undefined value
will be returned.

=over 4

=item scientificName

Scientific name of the genome whose taxonomy ID is desired.

=item RETURN

Returns the ID of the best taxonomic grouping at which to attach
the named genome, or C<undef> if no such grouping can be found.

=back

=cut

sub ComputeTaxonID {
    # Get the parameters.
    my ($self, $scientificName) = @_;
    # Search for the scientific name.
    my ($retVal) = $self->GetFlat('TaxonomicGrouping',
            'TaxonomicGrouping(alias) = ?', [$scientificName],
            'id');
    if (! $retVal) {
        # The full name was not found. Look for the genus and
        # species.
        if ($scientificName =~ /^(\S+\s+\S+)/) {
            ($retVal) = $self->GetFlat('TaxonomicGrouping',
            'TaxonomicGrouping(alias) = ?', [$1], 'id');
        }
    }
    # Return the taxon ID found (if any).
    return $retVal;
}

=head3 GetLocations

    my @locs = $cdmi->GetLocations($fid);

Return the locations of the DNA for the specified feature.

=over 4

=item fid

ID of the feature whose location is desired.

=item RETURN

Returns a list of L<BasicLocation> objects for the locations containing the
feature's DNA.

=back

=cut

sub GetLocations {
    # Get the parameters.
    my ($self, $fid) = @_;
    # Declare the return variable.
    my @retVal;
    # This will contain the last location found.
    my $lastLoc;
    # Get this feature's locations.
    my $qh = $self->Get("IsLocatedIn",
                       'IsLocatedIn(from_link) = ? ORDER BY IsLocatedIn(ordinal)',
                       [$fid]);
    while (my $resultRow = $qh->Fetch()) {
        # Compute the contig ID and other information.
        my $contig = $resultRow->PrimaryValue('to-link');
        my $begin = $resultRow->PrimaryValue('begin');
        my $dir = $resultRow->PrimaryValue('dir');
        my $len = $resultRow->PrimaryValue('len');
        # Create a location from the location information.
        my $start = ($dir eq '+' ? $begin : $begin + $len - 1);
        my $loc = BasicLocation->new($contig, $start, $dir, $len);
        # Check to see if this location is adjacent to the previous one.
        if ($lastLoc && $lastLoc->Adjacent($loc)) {
            # It is, so merge it in.
            $lastLoc->Merge($loc);
        } else {
            # It isn't, so push the new one on the list.
            $lastLoc = $loc;
            push @retVal, $loc;
        }
    }
    # Return the result.
    return @retVal;
}

=head3 GenesInRegion

    my @pegs = $cdmi->GenesInRegion($location);

Return a list of the IDs for the features that overlap the specified
region on a contig.

=over 4

=item location

Location of interest, either in the form of a location string (e.g.
C<360108.3:NZ_AANK01000002_264528_264007>)  or a L<BasicLocation>
object.

=item RETURN

Returns a list of feature IDs. The features in the list will be all
those that overlap or occur inside the location of interest.

=back

=cut

sub GenesInRegion {
    # Get the parameters.
    my ($self, $location) = @_;
    # Insure we have a location object.
    my $locObject = (ref $location ? $location : BasicLocation->new($location));
    # Get the beginning and the end of the location of interest.
    my $begin = $locObject->Left();
    my $end = $locObject->Right();
    # For performance reasons, we limit the possible starting location, using the
    # tuning parameter for maximum location length.
    my $limit = $begin - $self->TuningParameter('maxLocationLength');
    # Perform the query. Note we use a hash to eliminate duplicates.
    my %retVal = map { $_ => 1 } $self->GetFlat('Contig IsLocusFor Feature',
                                "Contig(id) = ? AND IsLocusFor(begin) <= ? AND " .
                                "IsLocusFor(begin) > ? AND " .
                                "IsLocusFor(begin) + IsLocusFor(len) >= ?",
                                [$locObject->Contig(), $end, $limit, $begin],
                                'Feature(id)');
    # Return the result.
    return sort keys %retVal;
}

=head3 ComputeDNA

    my $dna = $sap->ComputeDNA($contig, $beg, $dir, $length);

Return the DNA sequence for the specified location.

=over 4

=item contig

The ID of the contig containing the desired DNA.

=item beg

Location of the first desired base pair.

=item dir

C<+> for the plus strand and C<-> for the minus strand.

=item length

Number of base pairs.

=item RETURN

Returns a string containing the desired DNA. The DNA comes back in pure lower-case.

=back

=cut

sub ComputeDNA {
    # Get the parameters.
    my ($self, $contig, $beg, $dir, $length) = @_;
    # Get the contig, left end, and right end of the location. Note we subtract
    # 1 to convert contig positions to string offsets.
    my ($left, $right);
    if ($dir eq '+') {
        $left = $beg - 1;
        $right = $beg + $length - 2
    } else {
        $right = $beg - 1;
        $left = $beg - $length;
    }
    # Insure the left location is valid.
    if ($left < 0) {
        $left = 0;
    }
    # Get the contig sequence key.
    my ($contigKey) = $self->GetFlat("HasAsSequence", "HasAsSequence(from_link) = ?",
            [$contig], 'to-link');
    # Get the DNA segment length.
    my $maxSequenceLength = $self->TuningParameter("maxSequenceLength");
    # Compute the key of the first segment of our DNA and the starting
    # point in that segment.
    my $leftOffset = $left % $maxSequenceLength;
    my $leftKey = "$contigKey:" . Tracer::Pad(($left - $leftOffset)/$maxSequenceLength,
                                        7, 1, '0');
    # Compute the key of the last segment containing our DNA.
    my $rightKey = "$contigKey:" . Tracer::Pad(int($right/$maxSequenceLength), 7, 1, '0');
    my @results = $self->GetFlat("ContigChunk",
                                 'ContigChunk(id) >= ? AND ContigChunk(id) <= ?',
                                 [$leftKey, $rightKey], 'sequence');
    # Form all the DNA into a string and extract our piece.
    my $retVal = substr(join("", @results), $leftOffset, $length);
    # If this is a backwards string, we need the reverse complement.
    rev_comp(\$retVal) if $dir eq '-';
    # Return the result.
    return $retVal;
}

=head3 Taxonomy

    my @taxonomy = $sap->Taxonomy($genomeID, $format);

Return the full taxonomy of the specified genome, starting from the
domain downward.

=over 4

=item genomeID

ID of the genome whose taxonomy is desired.

=item format (optional)

Format of the taxonomy. C<names> will return primary names, C<numbers> will
return taxonomy numbers, and C<both> will return taxonomy number followed by
primary name. The default is C<names>.

=item RETURN

Returns a list of taxonomy names, starting from the domain and moving
down to the node where the genome is attached.

=back

=cut

sub Taxonomy {
    # Get the parameters.
    my ($self, $genomeID, $format) = @_;
    # Get the genome's taxonomic group.
    my ($taxon) = $self->GetFlat('IsInTaxa', 'IsInTaxa(from_link) = ?',
            [$genomeID], 'to-link');
    # We'll put the return data in here.
    my @retVal;
    # Only proceed if we found a group.
    if ($taxon) {
        # Loop until we hit a domain.
        my $domainFlag;
        while (! $domainFlag) {
            # Get the data we need for this taxonomic group.
            my ($taxonData) = $self->GetAll('TaxonomicGrouping IsInGroup',
                                            'TaxonomicGrouping(id) = ?', [$taxon],
                                            'domain scientific-name IsInGroup(to_link)');
            # If we didn't find what we're looking for, then we have a problem. This
            # would indicate a node below the domain level that doesn't have a parent
            # or (more likely) an invalid input string.
            if (! $taxonData) {
                # Terminate the loop and trace a warning.
                $domainFlag = 1;
                Trace("Could not find node or parent for \"$taxon\".") if T(1);
            } else {
                # Extract the data for the current group. Note we overwrite our
                # taxonomy ID with the ID of our parent, priming the next iteration
                # of the loop.
                my $name;
                my $oldTaxon = $taxon;
                ($domainFlag, $name, $taxon) = @$taxonData;
                # Compute the value we want to put in the output list.
                my $value;
                if ($format eq 'numbers') {
                    $value = $oldTaxon;
                } elsif ($format eq 'both') {
                    $value = "$oldTaxon $name";
                } else {
                    $value = $name;
                }
                # Put the current group's data in the return list.
                unshift @retVal, $value;
            }
        }
    }
    # Return the result.
    return @retVal;
}

=head3 ComputeNewAnnotationID

    my $annotationID = $cdmi->ComputeNewAnnotationID($fid, $timeStamp);

Return a valid annotation ID for the specified feature and time stamp.
The ID is formed from the feature ID and a complemented version of the
time stamp followed by a UUID. The complemented time stamp causes the
annotations to present in reverse chronological order and the
feature ID causes annotations for the same feature to cluster together.
This provides for efficient retrieval, though the keys are gigantic.

=over 4

=item fid

ID of the target feature for the annotation.

=item timeStamp

time at which the annotation occurred

=item RETURN

Returns a unique ID to give to the annotation.

=back

=cut

sub ComputeNewAnnotationID {
    # Get the parameters.
    my ($self, $fid, $timeStamp) = @_;
    # Complement the time stamp.
    my $inverted = 9999999999 - $timeStamp;
    my $padLen = 10 - length($inverted);
    if ($padLen > 0) {
        $inverted = ("0" x $padLen) . $inverted;
    }
    # Get a UUID.
    if (! defined $self->{uuid}) {
        $self->{uuid} = Data::UUID->new();
    }
    my $suffix = $self->{uuid}->create_b64();
    # Forge the full key.
    my $retVal = "$fid.$inverted.$suffix";
    # Return the result.
    return $retVal;
}

=head2 Configuration-Related Methods

=head3 TuningParameter

    my $parm = $cdmi->TuningParameter($parmName);

Return the value of the specified tuning parameter. Tuning parameters are
read from the XML configuration file.

=over 4

=item parmName

Name of the parameter whose value is desired.

=item RETURN

Returns the paramter value.

=back

=cut

sub TuningParameter {
    # Get the parameters.
    my ($self, $parmName) = @_;
    # Insure we have the parameters in memory.
    if (! defined $self->{tuning}) {
        # Read the configuration file.
        my $configFile = $self->ReadConfigFile();
        # Get the tuning parameters (if any).
        my $tuning;
        if (! defined $configFile || ! exists $configFile->{TuningParameters}) {
            $tuning = {};
        } else {
            $tuning = $configFile->{TuningParameters};
        }
        # Merge in the default option values.
        Tracer::MergeOptions($tuning, TUNING_DEFAULTS);
        # Save the result in our object.
        $self->{tuning} = $tuning;
    }
    # Extract the tuning paramter.
    my $retVal = $self->{tuning}{$parmName};
    # Throw an error if it does not exist.
    Confess("Invalid tuning parameter \"$parmName\".") if ! defined $retVal;
    # Return the result.
    return $retVal;
}


=head3 ReadConfigFile

    my $xmlObject = $cdmi->ReadConfigFile();

Return the hash structure created from reading the configuration file, or
an undefined value if the file is not found.

=cut

sub ReadConfigFile {
    my ($self) = @_;
    # Declare the return variable.
    my $retVal;
    # Compute the configuration file name.
    my $fileName = "$self->{loadDirectory}/CdmiConfig.xml";
    # Did we find it?
    if (-f $fileName) {
        # Yes, read it in.
        $retVal = XMLin($fileName);
    }
    # Return the result.
    return $retVal;
}

=head2 Virtual Methods

=head3 PreferredName

    my $name = $cdmi->PreferredName();

Return the variable name to use for this database when generating code.

=cut

sub PreferredName {
    return 'cdmi';
}

=head3 LoadDirectory

    my $dirName = $cdmi->LoadDirectory();

Return the name of the directory in which load files are kept. The default is
the FIG temporary directory, which is a really bad choice, but it's always there.

=cut

sub LoadDirectory {
    # Get the parameters.
    my ($self) = @_;
    # Return the directory name.
    return $self->{loadDirectory};
}

=head3 UseInternalDBD

    my $flag = $cdmi->UseInternalDBD();

Return TRUE if this database should be allowed to use an internal DBD.
The internal DBD is stored in the C<_metadata> table, which is created
when the database is loaded. The Sapling uses an internal DBD.

=cut

sub UseInternalDBD {
    return 1;
}

1;

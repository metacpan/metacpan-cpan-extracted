package Bio::KBase::CDMI::CDMILoader;

    use strict;
    use Stats;
    use SeedUtils;
    use Digest::MD5;
    use DateTime;
    use Data::Dumper;
    use File::Spec;
    use File::Temp;
    use IDServerAPIClient;
    use Bio::KBase::CDMI::Sources;

=head1 CDMI Load Utility Object

This object contains methods useful for the programming of CDMI load
scripts. It has a built-in statistics object and KBase ID server.
In addition, it contains useful utility methods.

The object contains the following fields.

=over 4

=item stats

A L<Stats> object for tracking statistics about the load.

=item db

The L<Bio::KBase::CDMI::CDMI> object for the database being loaded.

=item idserver

An L<IDServerAPIClient> object for requesting KBase IDs.

=item protCache

Reference to a hash of proteins known to be in the database.

=item relations

Reference to a hash keyed by relation name. Each relation
maps to a list containing an open L<File::Temp> object followed by
a list of field names representing the relation's field names in
order. The L</InsertObject> method will output field data to the
open file handle, and when the L</LoadRelations> method is called,
all of the relations will be loaded from the files created.

=item relationList

List of relation names in the order they should be loaded
by L</LoadRelations>.

=item sourceData

L<Bio::KBase::CDMI::Sources> object describing the load characteristics
of the current data source.

=item genome

ID of the genome currently being loaded (if any)

=back

=head2 Static Methods

=head3 GetLine

    my @fields = Bio::KBase::CDMI::CDMILoader::GetLine($ih);

or

    my @fields = $loader->GetLine($ih);

Read a line from a tab-delimited file, returning the fields in the form
of a list.

=over 4

=item ih

Open input file handle.

=item RETURN

Returns a list of the fields in the next input line. Note that fields
containing a single period (C<.>) will be converted to null strings.

=back

=cut

sub GetLine {
    # Get the parameters. Note we allow for both static and object-oriented
    # calls.
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($ih) = @_;
    # Read the line and chomp off the new-line character.
    my $line = <$ih>;
    chomp $line;
    # Return the individual fields.
    my @retVal = map { ($_ eq '.' ? '' : $_) } split /\t/, $line;
    return @retVal;
}

=head3 ReadFastaRecord

    my ($sequence, $nextID, $nextComment) = Bio::KBase::CDMI::CDMILoader::ReadFastaRecord($ih);

or

    my ($sequence, $nextID, $nextComment) = $loader->ReadFastaRecord($ih);

Read a sequence record from a FASTA file. The comment and identifier
for the next sequence record will be returned along with the sequence. If
end-of-file is reached, the returned comment and ID will be undefined.

=over 4

=item ih

Open file handle to the input file, which must be positioned after a
sequence header. At the end of the method call, the file will be
positioned after the next sequence header or at end-of-file.

=item RETURN

Returns a three-element list containing (0) the sequence read, (1) the
ID of the next sequence record in the file, and (2) the comment for
the next sequence record in the file.

=back

=cut

sub ReadFastaRecord {
    # Get the parameters. Note we allow for both static and object-oriented
    # calls.
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($ih) = @_;
    # Declare the return variables for the ID and comment. When we read a
    # header record, we'll set the next-ID variable and that will stop the
    # read loop.
    my ($nextID, $nextComment);
    # This will hold the sequence fragments.
    my @lines;
    # Loop until we've read the whole sequence.
    while (! eof $ih && ! defined $nextID) {
        # Read the next line.
        my $line = <$ih>;
        chomp $line;
        # Check for a header.
        if (substr($line,0,1) eq '>') {
            # This is a header line. Save the ID and comment.
            ($nextID, $nextComment) = split /\s+/, substr($line, 1), 2;
        } else {
            # This is a data line. Save the sequence.
            push @lines, $line;
        }
    }
    # Form the lines read into a sequence.
    my $sequence = join("", @lines);
    # Return everything read.
    return ($sequence, $nextID, $nextComment);
}

=head3 ParseMetadata

    my $metaHash = Bio::KBase::CDMI::CDMILoader::ParseMetadata($fileName);

or

    my $metaHash = $loader->ParseMetadata($fileName);

Parse a metadata file to extract the attributes and values. A
metadata file contains one or more multi-line records separated
by a record containing nothing but a double slash (C<//>). The
first line of the record is the attribute name. The remaining
lines form the attribute value.

=over 4

=item fileName

Name of the metadata file to parse.

=item RETURN

Returns a reference to a hash mapping attribute names to their
values. Multi-line values may contain embedded line-feeds.

=back

=cut

sub ParseMetadata {
    # Get the parameters. Note we allow for both static and object-oriented
    # calls.
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($fileName) = @_;
    # Declare the return hash.
    my %retVal;
    # Only proceed if the file exists.
    if (-f $fileName) {
        # Open the file.
        open(my $ih, "<$fileName") || die "Could not open $fileName: $!";
        # Denote we do not have an attribute or a value yet.
        my $key;
        my @value;
        # Loop through the file.
        while (! eof $ih) {
            # Get the current line.
            my $line = <$ih>;
            chomp $line;
            # Determine the type of line.
            if ($line eq '//') {
                # Here we have a delimiter. Store the accumulated value.
                $retVal{$key} = join("\n", @value);
                # Insure we know this key has been stored.
                undef $key;
            } elsif (! defined $key) {
                # Here we have an attribute name. Store it as the key and
                # clear the value.
                $key = $line;
                @value = ();
            } else {
                # Here we have part of the value.
                push @value, $line;
            }
        }
        # If there's a residual, put it in the hash.
        if (defined $key) {
            $retVal{$key} = join("\n", @value);
        }
    }
    # Return the hash of attributes.
    return \%retVal;
}

=head3 ReadAttribute

    my $value = Bio::KBase::CDMI::CDMILoader::ReadAttribute($fileName);

or

    my $value = $loader->ReadAttribute($fileName);

Read the record from a single-line file.

=over 4

=item fileName

Name of the file to read.

=item RETURN

Returns the record in the file read, or C<undef> if the file does
not exist.

=back

=cut

sub ReadAttribute {
    # Get the parameters. Note we allow for both static and object-oriented
    # calls.
    shift if UNIVERSAL::isa($_[0],__PACKAGE__);
    my ($fileName) = @_;
    # Declare the return variable.
    my $retVal;
    # Only proceed if the file exists.
    if (-f $fileName) {
        # Open the file and read its first line.
        open(my $ih, "<$fileName") || die "Could not open $fileName: $!";
        $retVal= <$ih>;
        chomp $retVal;
    }
    # Return the result.
    return $retVal;
}

=head3 ConvertTime

    my $timeValue = Bio::KBase::CDMI::CDMILoader::ConvertTime($modelTime);

Convert a time from ModelSEED format to an ERDB time value. The ModelSEED
format is

B<YYYY>C<->B<MM>C<->B<DD>C<T>B<HH>C<:>B<MM>C<:>B<SS>

The C<T> may sometimes be replaced by a space.

=over 4

=item modelTime

Date/time value in ModelSEED format.

=item RETURN

Returns the incoming time as a number of seconds since the epoch.

=back

=cut

sub ConvertTime {
    # Get the parameters.
    my ($modelTime) = @_;
    # Declare the return variable.
    my $retVal = 0;
    # Parse the components.
    if ($modelTime =~ /(\d+)[-\/](\d+)[-\/](\d+)[T ](\d+):(\d+):(\d+)/) {
        my $dt = DateTime->new(year => $1, month => $2, day => $3,
                               hour => $4, minute => $5, second => $6);
        $retVal = $dt->epoch();
    } elsif ($modelTime =~ /(\d+)[-\/](\d+)[-\/](\d+)/) {
        my $dt = DateTime->new(year => $1, month => $2, day => $3,
                               hour => 12, minute => 0, second => 0);
        $retVal = $dt->epoch();
    }
    # Return the result.
    return $retVal;
}

=head2 Special Methods

=head3 new

    my $loader = CDMILoader->new($cdmi, $idserver);

Create a new CDMI loader object for the specified CMDI database.

=over 4

=item cdmi

A L<Bio::KBase::CDMI::CDMI> object for the database being loaded.

=item idserver

KBase ID server object. If none is specified, a default one will be
created.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $cdmi, $idserver) = @_;
    # Create the statistics object.
    my $stats = Stats->new();
    # Create this object.
    my $retVal = {};
    bless $retVal, $class;
    # Store the statistics object and the database.
    $retVal->{stats} = $stats;
    $retVal->{cdmi} = $cdmi;
    # Insure we have a KBase ID server.
    if (! defined $idserver) {
        my $id_server_url = "http://bio-data-1.mcs.anl.gov:8080/services/idserver";
        $idserver = IDServerAPIClient->new($id_server_url);
    }
    # Attach the ID server.
    $retVal->{idserver} = $idserver;
    # Default to no genome and a source of KBase.
    $retVal->{sourceData} = Bio::KBase::CDMI::Sources->new("KBase");
    $retVal->{genome} = "";
    # Create the relation loader stuff.
    $retVal->{relations} = {};
    $retVal->{reltionList} = [];
    # Create the protein cache.
    $retVal->{protCache} = {};
    # Return the result.
    return $retVal;
}

=head2 Basic Access Methods

=head3 stats

    my $stats = $loader->stats;

Return the statistics object.

=cut

sub stats {
    return $_[0]->{stats};
}

=head3 cdmi

    my $cdmi = $loader->cdmi;

Return the database instance object.

=cut

sub cdmi {
    return $_[0]->{cdmi};
}

=head3 idserver

    my $idserver = $loader->idserver;

Return the ID server instance object.

=cut

sub idserver {
    return $_[0]->{idserver};
}

=head2 Relation Loader Services

The relation loader provides services for loading tables using the
B<LOAD DATA INFILE> facility, which is significantly faster. As
database records are computed, they are output to files using the
L</InsertObject> method. At the end of the load, the C<LoadRelations>
method is called to close the files and perform the B<LOAD DATA INFILE>
command. The C<SetRelations> method is called to initialize the
process.

B<There are limitations to this process>. It will only work if the
fields in question are untranslated scalars, such as numbers,
strings, or dates in internal format. For example, if the relation
in question contains DNA or images, it cannot be loaded in this
manner, since the fields need to be converted.

=head3 SetRelations

    $loader->SetRelations(@relationNames);

Initialize loaders for the specified relations.

=over 4

=item relationNames

List of the names for the relations to load.

=back

=cut

sub SetRelations {
    # Get the parameters.
    my ($self, @relationNames) = @_;
    # Get the attached database.
    my $cdmi = $self->cdmi;
    # Get the loader hash.
    my $relations = $self->{relations};
    # Save the relation name list.
    $self->{relationList} = \@relationNames;
    # Loop through the relation names, creating loaders.
    for my $relationName (@relationNames) {
        # Create the output file.
        my $fh = File::Temp->new(TEMPLATE => "loader_rel_$relationName.XXXXXXXX",
                SUFFIX => '.dtx', UNLINK => 1, DIR => File::Spec->tmpdir());
        # Get the list of fields in the relation.
        my $relData = $cdmi->FindRelation($relationName);
        my @fields = map { $_->{name} } @{$relData->{Fields}};
        # Convert hyphens to underscores.
        for (my $i = 0; $i < @fields; $i++) {
            $fields[$i] =~ tr/-/_/;
        }
        # Create the relation loader.
        $relations->{$relationName} = [$fh, @fields];
    }
}

=head3 InsertObject

    $loader->InsertObject($relationName, %fields);

Output a proposed database record to one of the relation loaders.

=over 4

=item relationName

Name of the relation being output.

=item fields

Hash mapping field names for the record to the field values.

=back

=cut

sub InsertObject {
    # Get the parameters.
    my ($self, $relationName, %fields) = @_;
    # Get the relation's loader.
    my $relData = $self->{relations}{$relationName};
    if (! defined $relData) {
        # No loader, so do a real insert.
        $self->cdmi->InsertObject($relationName, %fields);
    } else {
        my ($fh, @fieldNames) = @$relData;
        # Loop through the field names, collecting the field values.
        my @values;
        for my $fieldName (@fieldNames) {
            my $value = $fields{$fieldName};
            if (! defined $value) {
                die "Missing field $fieldName in $relationName InsertObject.\n";
            } else {
                push @values, $value;
            }
        }
        # Output the fields to the loader file.
        print $fh join("\t", @values) . "\n";
    }
}


=head3 LoadRelations

    $loader->LoadRelations();

Unspool all the relation loaders into the database. Each load file will
be closed and then a B<LOAD DATA INFILE> command will be used to load it.
A statistical object (L<Stat>) will be returned.

=cut

sub LoadRelations {
    # Get the parameters.
    my ($self) = @_;
    # Get our statistics object.
    my $stats = $self->stats;
    # Get the database.
    my $cdmi = $self->cdmi;
    # Get the relation loaders.
    my $relations = $self->{relations};
    # Loop through the loaders in the user-specified order, processing
    # one relation at a time.
    for my $relationName (@{$self->{relationList}}) {
        # Get the relation's file handle and file name.
        my $fh = $relations->{$relationName}[0];
        my $fileName = $fh->filename;
        # Close the handle to make the file available for reading.
        close $fh;
        # Load the file into the relation and roll up the statistics.
        my $stats2 = $cdmi->LoadTable($fileName, $relationName, partial => 1,
            );
        $stats->Accumulate($stats2);
        # Remove the loader.
        delete $relations->{$relationName};
    }
}


=head2 Loader Utility Methods

=head3 genome_load_file_name

    my $fileName = $loader->genome_load_file_name($directory, $name);

Compute the fully-qualified name of a load file. The load file will be
located in the specified directory and will have either the name
given, or the name given with the current genome ID inserted before
the extension. So, for example, if the given name is C<contigs.fa>
and the genome ID is C<100226.1>, this method will look for
C<contigs.100226.1.fa> first, and if that is not found return
C<contigs.fa>.

=over 4

=item directory

Directory containing the load files.

=item name

Name of the particular load file.

=item RETURN

Returns a fully-qualified file name to use in the load.

=back

=cut

sub genome_load_file_name {
    # Get the parameters.
    my ($self, $directory, $name) = @_;
    # Start with the default file name.
    my $retVal = "$directory/$name";
    # Get the genome ID.
    my $genome = $self->{genome};
    # Only Check for a genome-altered file if we have a genome ID.
    if ($genome) {
        # Compute the genome-altered file name.
        my @parts = split  /\./, $name;
        my $extension = pop @parts;
        my $altName = $directory . "/" . join(".", @parts, $genome, $extension);
        # Check to see if it exists.
        if (-f $altName) {
            # It does, so use it.
            $retVal = $altName;
        }
    }
    # Return the file name found.
    return $retVal;
}

=head3 CheckRole

    my $roleID = $loader->CheckRole($roleText);

Insure a record for the specified role exists in the database. If the
role is not found, it will be created.

=over 4

=item roleText

Text of the role.

=item RETURN

Returns the ID of the role in the database.

=back

=cut

sub CheckRole {
    # Get the parameters.
    my ($self, $roleText) = @_;
    # Get the database object.
    my $cdmi = $self->cdmi;
    # Get the statistics object.
    my $stats = $self->stats;
    # Compute the role ID from the role. They are currently the same.
    my $retVal = $roleText;
    # Check for the role in the database.
    if ($cdmi->Exists(Role => $retVal)) {
         # We found it, so we're done.
         $stats->Add(roleFound => 1);
    } else {
        # We have to add the role. Determine whether or not it is
        # hypothetical.
        my $hypo = (hypo($roleText) ? 1 : 0);
        $stats->Add(newRole => 1);
        # Create the role.
        $cdmi->InsertObject('Role', id => $roleText, hypothetical => $hypo);
    }
    # Return the role ID.
    return $retVal;
}

=head3 CheckProtein

    my $protID = $loader->CheckProtein($sequence);

Insure that a protein sequence is in the database. If it is not, a
record will be created for it.

=over 4

=item sequence

Protein amino acid sequence that needs to be in the database.

=item RETURN

Returns the MD5 identifier of the protein sequence.

=back

=cut

sub CheckProtein {
    # Get the parameters.
    my ($self, $sequence) = @_;
    # Get the statistics object.
    my $stats = $self->stats;
    # Get the database object;
    my $cdmi = $self->cdmi;
    # Compute the MD5 of the protein sequence.
    my $retVal = Digest::MD5::md5_hex($sequence);
    # Check to see if it's in the database.
    if ($self->{protCache}->{$retVal}) {
        # It's in the cache, so we're done.
        $stats->Add(proteinCached => 1);
    } elsif ($cdmi->Exists(ProteinSequence => $retVal)) {
         # It's in the database, so add it to the cache.
         $self->{protCache}->{$retVal} = 1;
         $stats->Add(proteinFound => 1);
    } else {
        # It isn't, so we must add it.
        $cdmi->InsertObject('ProteinSequence', id => $retVal,
                sequence => $sequence);
        $stats->Add(proteinAdded => 1);
        # Put it in the cache so we can find it later.
        $self->{protCache}->{$retVal} = 1;
    }
    # Return the protein's MD5 identifier.
    return $retVal;
}

=head3 InsureEntity

    my $createdFlag = $loader->InsureEntity($entityType => $id, %fields);

Insure that the specified record exists in the database. If no record is
found of the specified type with the specified ID, one will be created
with the indicated fields.

=over 4

=item $entityType

Type of entity to check.

=item id

ID of the entity instance in question.

=item fields

Hash mapping field names to values for all the fields in the desired entity record except
for the ID.

=item RETURN

Returns TRUE if a new object was created, FALSE if it already existed.

=back

=cut

sub InsureEntity {
    # Get the parameters.
    my ($self, $entityType, $id, %fields) = @_;
    # Get the database.
    my $cdmi = $self->cdmi;
    # Denote we haven't created a new record.
    my $retVal = 0;
    # It's not found. Check the database.
    if (! $cdmi->Exists($entityType => $id)) {
        # It's not in the database, so create it.
        $cdmi->InsertObject($entityType, id => $id, %fields);
        $self->stats->Add(insertSupport => 1);
        $retVal = 1;
    }
    # Return the insertion indicator.
    return $retVal;
}

=head3 DeleteRelatedRecords

    $loader->DeleteRelatedRecords($kbid, $relName, $entityName);

Delete all the records in the named entity and relationship relating to the
specified KBase ID and roll up the statistics.

=over 4

=item kbid

ID of the object whose related records are being deleted.

=item relName

Name of a relationship from the identified object's entity.

=item entityName

Name of the entity on the other side of the relationship.

=back

=cut

sub DeleteRelatedRecords {
    # Get the parameters.
    my ($self, $kbid, $relName, $entityName) = @_;
    # Get the database object.
    my $cdmi = $self->cdmi;
    # Get the statistics object.
    my $stats = $self->stats;
    # Get all the relationship records.
    my (@targets) = $cdmi->GetFlat($relName, "$relName(from_link) = ?", [$kbid],
                                  "to-link");
    print scalar(@targets) . " entries found for delete of $entityName via $relName.\n" if @targets;
    # Loop through the relationship records, deleting them and the target entity
    # records.
    for my $target (@targets) {
        # Delete the relationship instance.
        $cdmi->DeleteRow($relName, $kbid, $target);
        $stats->Add($relName => 1);
        # Delete the entity instance.
        my $subStats = $cdmi->Delete($entityName, $target);
        # Roll up the statistics.
        $stats->Accumulate($subStats);
    }
}

=head3 ConvertFileRecord

    $loader->ConvertFileRecord($objectName, $source, \@fileRecord,
                               \%rules);

Convert a file record to a database record. The parameters specify
which input columns correspond to output fields and the rules for
converting them.

=over 4

=item objectName

Name of the output object (entity or relationship).

=item source

Source database to be used in constructing KBase IDs.

=item fileRecord

Reference to a list of the input fields.

=item rules

Reference to a hash, keyed by output field name. The value of each
field is a 3-tuple consisting of (0) the index of the input field,
(1) the name of the rule for translating the field, and (2) the
default value to use if the field is empty or missing. The acceptable
rules are as follows.

=over 8

=item copy

Copy without conversion.

=item timeStamp

Convert from a ModelSEED date/time value to an ERDB time stamp.

=item kbid

Convert from an ID to a KBase ID.

=item copy1

Copy the first half of the value.

=item copy2

Copy the second half of the value.

=back

=back

=cut

sub ConvertFileRecord {
    # Get the parameters.
    my ($self, $objectName, $source, $fileRecord, $rules) = @_;
    # This will contain the field mapping for the InsertObject call.
    my %fields;
    # Get the CDMI database.
    my $cdmi = $self->cdmi;
    # Loop through the rules.
    for my $fieldName (keys %$rules) {
        my ($loc, $rule, $default) = @{$rules->{$fieldName}};
        # The output value will be put in here.
        my $outputValue = $default;
        # Get the specified input field. If the input field spec is
        # missing, we'll always do the default.
        my $inputValue;
        if (defined $loc) {
            $inputValue = $fileRecord->[$loc];
        }
        # Only proceed if it has a value.
        if (defined $inputValue && $inputValue ne '') {
            # Process according to the format rule.
            if ($rule eq 'copy') {
                $outputValue = $inputValue;
            } elsif ($rule eq 'timeStamp') {
                $outputValue = ConvertTime($inputValue);
            } elsif ($rule eq 'kbid') {
                my $hash = $self->FindKBaseIDs($source, '', [$inputValue]);
                $outputValue = $hash->{$inputValue};
            } elsif ($rule eq 'copy1') {
                $outputValue = substr($inputValue, 0, length($inputValue)/2);
            } elsif ($rule eq 'copy2') {
                $outputValue = substr($inputValue, length($inputValue)/2);
            } else {
                die "Invalid input rule $rule.\n";
            }
        }
        # Store the field specification in the field hash.
        $fields{$fieldName} = $outputValue;
    }
    # Insert the record.
    $self->InsertObject($objectName, %fields);
}

=head2 KBase ID Services

=head3 SetSource

    $loader->SetSource($source);

Specify the current database source.

=over 4

=item source

Name of the database from which data is being loaded.

=back

=cut

sub SetSource {
    # Get the parameters.
    my ($self, $source) = @_;
    # Update the source data.
    $self->{sourceData} = Bio::KBase::CDMI::Sources->new($source);
}

=head3 SetGenome

    $loader->SetGenome($genome);

Specify the ID of the genome being loaded. This helps the ID services
determine if the genome ID needs to be added to the object ID when
calling for the KBase ID.

=over 4

=item genome

ID of the genome currently being loaded.

=back

=cut

sub SetGenome {
    # Get the parameters.
    my ($self, $genome) = @_;
    # Store the proposed genome ID.
    $self->{genome} = $genome;
}

=head3 FindKBaseIDs

    my $idMapping = $loader->FindKBaseIDs($type, \@ids);

Find the KBase IDs for the specified identifiers from the given external
source database. No new IDs will be created or registered.

=over 4

=item type

Type of object to which the IDs apply.

=item ids

Reference to a list of foreign IDs to be converted to KBase IDs.

=item RETURN

Returns a reference to a hash that maps the foreign identifiers to their
KBase equivalents. If no KBase equivalent exists, the foreign identifier
will not appear in the hash.

=back

=cut

sub FindKBaseIDs {
    # Get the parameters.
    my ($self, $type, $ids) = @_;
    # Compute the real source and the real IDs.
    my $realSource = $self->realSource($type);
    my $idMap = $self->idMap($type, $ids);
    # Call through to the ID server.
    my $kbMap = $self->idserver->external_ids_to_kbase_ids($realSource,
            [map { $idMap->{$_} } @$ids]);
    # Convert the modified IDs to the original IDs.
    my %retVal = map { $_ => $kbMap->{$idMap->{$_}} } @$ids;
    # Return the result.
    return \%retVal;
}

=head3 GetKBaseIDs

    my $idHash = $loader->GetKBaseIDs($prefix, $type, \@ids);

Compute KBase IDs for all the specified foreign IDs from the specified
source. The KBase IDs will all have the indicated prefix, which must
begin with the string C<kb|>.

=over 4

=item prefix

Prefix to be put on all the IDs created. Must be a string beginning with
C<kb|>.

=item type

Type of object to which the IDs apply.

=item ids

Reference to a list of foreign IDs whose KBase IDs are desired. If
no KBase ID exists for a foreign ID, one will be created.

=item RETURN

Returns a reference to a hash mapping the foreign IDs to KBase IDs.

=back

=cut

sub GetKBaseIDs {
    # Get the parameters.
    my ($self, $prefix, $type, $ids) = @_;
    # Insure the IDs are a list reference.
    if (ref $ids ne 'ARRAY') {
        $ids = [$ids];
    }
    # Compute the real source and the real IDs.
    my $realSource = $self->realSource($type);
    my $idMap = $self->idMap($type, $ids);
    # Call through to the ID server.
    my $kbMap = $self->idserver->register_ids($prefix, $realSource,
            [map { $idMap->{$_} } @$ids]);
    # Convert the modified IDs to the original IDs.
    my %retVal = map { $_ => $kbMap->{$idMap->{$_}} } @$ids;
    # Return the result.
    return \%retVal;
}


=head3 GetKBaseID

    my $kbID = $loader->GetKBaseID($prefix, $type, $id);

Return the KBase ID for the specified foreign ID from the specified
source. If no such ID exists, one will be created with the specified
prefix (which must begin with the string C<kb|>).

=over 4

=item prefix

Prefix to be put on the ID created. Must be a string beginning with
C<kb|>.

=item type

Type of object to which the ID applies

=item id

Foreign ID whose KBase ID is desired.

=item RETURN

Returns the KBase ID for the specified foreign ID. If one did not
exist, it will have been created.

=back

=cut

sub GetKBaseID {
    # Get the parameters.
    my ($self, $prefix, $type, $id) = @_;
    # Ask the ID server for the ID.
    my $idHash = $self->GetKBaseIDs($prefix, $type, [$id]);
    # Return the result.
    return $idHash->{$id};
}

=head3 source

    my $source = $loader->source;

Return the source name associated with this load.

=cut

sub source {
    # Get the parameters.
    my ($self) = @_;
    # Return the source name.
    return $self->{sourceData}->name;
}

=head3 realSource

    my $realSource = $loader->realSource($type);

Return the object source name to be used when requesting an ID for
objects of the specified type. This is either the unmodified source
name or (for typed IDs) the source name suffixed with the object
type.

=over 4

=item type

Type of object for which IDs are being generated or retrieved.

=item RETURN

Returns a string to be used for requesting ID services related to
objects of the specified type.

=back

=cut

sub realSource {
    # Get the parameters.
    my ($self, $type) = @_;
    # Start with the source name.
    my $retVal = $self->{sourceData}->name;
    # If we're typed, add the type.
    if ($self->{sourceData}->typed) {
        $retVal .= ":$type";
    }
    # Return the result.
    return $retVal;
}


=head3 idMap

    my $idMap = $loader->idMap($type, \@ids);

Return a hash mapping each incoming source ID to the ID that should be
passed to the ID server in order to find its KBase ID. This is either
the raw ID or (if the source has genome-based IDs) the ID prefixed by
the current genome ID.

=over 4

=item type

Type of object for the IDs.

=item ids

Reference to a list of source IDs.

=item RETURN

Returns a reference to a hash mapping each incoming source ID to the ID that
should be used when looking it up on the ID server.

=back

=cut

sub idMap {
    # Get the parameters.
    my ($self, $type, $ids) = @_;
    # Declare the return hash.
    my %retVal;
    # Determine whether or not we are genome-based. Note that we are
    # never genome-based when looking for genome IDs.
    if ($self->{sourceData}->genomeBased && $type ne 'Genome') {
        # We are, so prefix the current genome ID.
        %retVal = map { $_ => "$self->{genome}:$_" } @$ids;
    } else {
        # We aren't, so use the IDs in their raw form.
        %retVal = map { $_ => $_ } @$ids;
    }
    # Return the result.
    return \%retVal;
}

1;

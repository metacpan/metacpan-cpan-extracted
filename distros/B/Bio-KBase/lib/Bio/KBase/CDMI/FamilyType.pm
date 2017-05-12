package Bio::KBase::CDMI::FamilyType;

    use strict;

=head1 Family Type Base Class

This is the base class for family types. A FamilyType object
is used by L<Bio::KBase::CDMI::CDMILoadFamilies.pl> to determine how to load
a protein family.

Protein families have a great deal of commonality, but there
are variations. They tend to have additional files with data
not present in all family types. Most load proteins, but some
contain features instead.

The base class will assume the most common response for each
question the load program needs to ask.

The following fields are present in the object.

=over 4

=item type

protein family type (used in the B<Family> record)

=item release

protein family release code (used in the B<Family> record)

=item feature

TRUE if this is a feature family, FALSE if it is purely a protein
family

=back

=head2 Special Methods

=head3 new

    my $familyType = Bio::KBase::CDMI::FamilyType->new($type, $release, $feature);

Construct a new family type object.

=over 4

=item type

Protein family type name (e.g. FIGFam, equivalog).

=item release

Protein family release code.

=item feature (optional)

TRUE if this family type stores features; FALSE if it stores proteins.
The default is FALSE.

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $type, $release, $feature) = @_;
    # Create the object.
    my $retVal = {
        type => $type,
        release => $release,
        feature => ($feature ? 1 : 0)
    };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head3 Init

    $familyType->Init($loader, $directory);

Perform special initialization. This method is called after the basic
data structures are created but before any data is processed from the
input directory.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for the current load.

=item directory

Name of the directory containing the load files.

=back

=cut

sub Init {
    # The default is to take no special actions.
}


=head2 Query Methods

=head3 typeName

    my $typeName = $familyType->typeName;

Return the type name to be used for these protein families in the
B<Family> records.

=cut

sub typeName {
    return $_[0]->{type};
}

=head3 release

    my $release = $familyType->release;

Return the release identifier to be used for these protein families in the
B<Family> records.

=cut

sub release {
    return $_[0]->{release};
}

=head3 featureBased

    my $featureFlag = $familyType->featureBased;

Return TRUE if the family contains features, FALSE if it contains
proteins only.

=cut

sub featureBased {
    return $_[0]->{feature};
}

=head2 Virtual Methods

=head3 ResolveProteinMember

    my $idHash = $familyType->ResolveProteinMember($loader, $memberID);

Compute the KBase ID for the specified protein member ID. The
translation generally depends on the type of protein family. The
default method assumes that the IDs are already in the MD5 format
used by KBase and we only need to verify that the protein is
already in the database.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for this load.

=item memberID

Family member ID to translate.

=item RETURN

Returns the KBase protein ID for the member, or C<undef> if the protein
is not in the database.

=back

=cut

sub ResolveProteinMember {
    # Get the parameters.
    my ($self, $loader, $memberID) = @_;
    # Get the CDMI database and the statistics object.
    my $cdmi = $loader->cdmi;
    my $stats = $loader->stats;
    # Look for the protein in the database.
    my $retVal;
    if ($cdmi->Exists(ProteinSequence => $memberID)) {
        $retVal = $memberID;
        $stats->Add(proteinMemberFound => 1);
    } else {
        $stats->Add(proteinMemberNotFound => 1);
    }
    return $retVal;
}

=head3 ResolveFeatureMember

    my ($kbaseID, $proteinID, $genomeID) = $familyType->ResolveFeatureMember($loader, $memberID);

Compute the KBase ID for a feature member of a family along with its
associated protein ssequence ID and genome ID. The method for doing this depends on
the type of family, since the member IDs are usually in a dialect
peculiar to the family type. Only feature-based families need to override
this method.

The default presumes that all the member IDs belong to a source type that
has been set as the source type of the loader object in the L</Init>
method.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for this load.

=item memberID

The family member ID, usually a feature ID in the source's dialect.

=item RETURN

Returns a list containing (0) the feature's KBase ID, (1) the ID of the
associated protein sequence, and (2) the ID of the associated genome. If a
member does not exist in the KBase, nothing will be returned.

=back

=cut

sub ResolveFeatureMembers {
    # Get the parameters.
    my ($self, $loader, $memberID) = @_;
    # The return values will be stored in here.
    my ($kbaseID, $proteinID, $genomeID);
    # Get the CDMI and statistics objects from the loader.
    my $stats = $loader->stats;
    my $cdmi = $loader->cdmi;
    # Get the source name.
    my $source = $loader->source;
    # Look for the incoming feature.
    my ($tuple) = $cdmi->GetAll('Feature Produces AND Feature IsOwnedBy WasSubmittedBy',
        'Feature(source-id) = ? AND WasSubmittedBy(to-link) = ?',
        [$memberID, $source], 'Feature(id) Produces(to-link) IsOwnedBy(to-link)');
    # Did we find it?
    if ($tuple) {
        # Yes. It can be returned.
        $stats->Add(fidFound => 1);
        ($kbaseID, $proteinID, $genomeID) = @$tuple;
    } else {
        # No. Record this in the statistics.
        $stats->Add(fidNotFound => 1);
    }
    # Return the result.
    return ($kbaseID, $proteinID, $genomeID);
}

=head3 ProcessAdditionalFiles

    $familyType->ProcessAdditionalFiles($loader, $directory);

Process additional files in the specified directory. This method
handles files aside from the two standard files used to load
families. These contain additional data such as coupling information,
alignments, or probability models.

=over 4

=item loader

L<Bio::KBase::CDMI::CDMILoader> object for the current load.

=item directory

Name of the directory containing the load files.

=back

=cut

sub ProcessAdditionalFiles {
    # The default is to load no additional data.
}

1;

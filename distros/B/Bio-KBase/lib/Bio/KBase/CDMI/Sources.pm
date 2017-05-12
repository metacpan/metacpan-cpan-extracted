package Bio::KBase::CDMI::Sources;

=head1 Genome Source Definition File

This module is used to determine how identifiers work in each of the
various data sources defined for the KBase. A data source is I<typed>
if IDs are only unique within the context of object type. A data source
is I<genome-based> if IDs are only unique within the context of the
parent genome. When calls are made to the ID server from the genome
loader, the source ID will be prefixed by the genome ID when IDs are
genome-based, and the source type will be suffixed with the object
type when IDs are typed.

=head2 Constants

=head3 NON_GENOME_BASED

This is a list of the sources that are not genome-based. Genome-based is
the default.

=cut

my @NON_GENOME_BASED = qw(
                MOL
                SEED
                );

=head3 TYPED

This is a list of the sources that are typed. Untyped is the default.

=cut

my @TYPED = qw(
                MOL
              );

=head2 Special Methods

=head3 new

    my $sourceData = Sources->new($source);

Create a source descriptor for the specified data source.

=over 4

=item source

KBase name of the database from which data is being loaded (e.g. C<SEED>,
C<MOL>, C<EnsemblPlant>).

=back

=cut

sub new {
    # Get the parameters.
    my ($class, $source) = @_;
    # Determine whether or not we're genome-based.
    my $genomeBased = ((grep { $_ eq $source } @NON_GENOME_BASED) ? 0 : 1);
    # Determine whether or not we're typed.
    my $typed = ((grep { $_ eq $source } @TYPED) ? 1 : 0);
    # Create the object.
    my $retVal = {
            genomeBased => $genomeBased,
            typed => $typed,
            name => $source
    };
    # Bless and return it.
    bless $retVal, $class;
    return $retVal;
}

=head2 Query Methods

=head3 genomeBased

    my $flag = $sourceData->genomeBased;

Return TRUE if this source is genome-based, else FALSE.

=cut

sub genomeBased {
    my ($self) = @_;
    return $self->{genomeBased};
}

=head3 typed

    my $flag = $sourceData->typed;

Return TRUE if this source is typed, else FALSE.

=cut

sub typed {
    my ($self) = @_;
    return $self->{typed};
}

=head3 name

    my $flag = $sourceData->name;

Return the name of this data source.

=cut

sub name {
    my ($self) = @_;
    return $self->{name};
}

1;
package Data::Pensieve;

use strict;
use warnings;

use Carp             qw(croak);
use DateTime         qw();
use List::Util       qw(first);
use List::MoreUtils  qw(uniq);
use Storable         qw(freeze);
use Text::Diff       qw(diff);

use Moose;

use Data::Pensieve::Revision;

our $VERSION = 0.03;

has 'revision_rs'      => ( is => 'rw' );
has 'revision_data_rs' => ( is => 'rw' );
has 'definitions'      => ( is => 'rw' );

=head1 NAME

Data::Pensieve - Simple tool for interacting with revisioned data

=head1 SYNOPSIS

    use Data::Pensieve;
    
    my $pensieve = Data::Pensieve->new(
        revision_rs      => $c->model('DB::Revision'),
        revision_data_rs => $c->model('DB::RevisionData'),
        definitions      => {
            lolcats => [ qw/name saying picture/ ],
        },
    );
    
    $pensieve->store_revision(
        lolcats => 1,
        {
            # data
            name    => 'lazy lolcat',
            saying  => 'i cannot brian today. i have the dumb',
            picture => 'lazycat.png',
        },
        {
            # change metadata
            modified_by => 'waffle wizard',
        },
    );

    # oops! a typo! time to denote a change.
    $pensieve->store_revision(
        lolcats => 1,
        {
            # data
            saying => 'i cannot brain today. i have the dumb',
        },
        {
            # change metadata
            modified_by => 'assistant regional manager',
        },
    );
    
    my @revisions = $pensieve->get_revisions(lolcats => 1);
    
    my ($rev1, $rev2) = @revisions;

    my $comparison = $pensieve->compare_revisions($rev1, $rev2);
    # {
    #   saying => [
    #       'i cannot brian today. i have the dumb',
    #       'i cannot brain today. i have the dumb'
    #   ]
    # }

=head1 DESCRIPTION

"I use the Pensieve. One simply siphons the excess thoughts from one's mind, pours them into the basin, and examines them at one's leisure. It becomes easier to spot patterns and links, you understand, when they are in this form." - Albus Dumbledore

In the world of Harry Potter, a Pensieve is a magical device that allows a wizard to store and review his or her thoughts. Data::Pensieve serves a similar purpose for Perl applications, allowing you to easily record revision histories and analyze differences between revisions.

Data::Pensieve uses a DBIx::Class backend to store revision data.

=head1 METHODS

=head2 new()

Returns a new Data::Pensieve object. Takes the following required parameters.

=over 4

=item * B<definitions>

A hash reference, where the keys are the names of groups of data and the values are array references of the expected columns.

For instance:

    # {
    #    cats       => [ qw/ name favorite_toy           / ],
    #    people     => [ qw/ name occupation             / ],
    #    food       => [ qw/ name calories               / ],
    #    japh       => [ qw/ cpan_name num_yapcs_attended /],
    # }

=item * B<revision_rs>

A DBIx::Class::ResultSet representing the revision table, which must have the following schema:

    revision_id int auto_increment primary key,
    grouping    varchar(255),
    identifier  varchar(255),
    recorded    datetime,
    metadata    blob

=item * B<revision_data_rs>

A DBIx::Class::ResultSet reprensenting the revision data table, which must have the following schema:

    revision_data_id int auto_increment primary key,
    revision_id      int,
    datum            varchar(255),
    datum_value      blob

=back

=cut

=head2 store_revision()

Given a grouping, item, hash reference of data, and optional hash reference of metadata related to this change, stores a change.

=cut

sub store_revision
{
    my ($self, $grouping, $item, $params, $metadata) = @_;

    $metadata ||= {};
    $metadata   = freeze $metadata;

    my $schema  = $self->schema($grouping);
    my @columns = ($schema and @$schema) ? @$schema : keys %$params;

    # overloaded objects can be provided as both the item identifier and the
    # object that generates the data itself. nifty!
    if (not defined $params and ref $item) {
        $params = $item;
        $item   = "$item";
    }

    # objects can be provided in lieu of a hash of parameters. however, you
    # must provide a definition so we know what parameters to retrieve
    if (ref $params and ref $params ne 'HASH')
    {
        if ($schema) {
            my $data = {};
            for my $column (@columns) {
                my $id = ref $column ? $column->{id} : $column;
    
                if ($params->can($id)) {
                    $data->{$id} = $params->$id;
                } else {
                    $data->{$id} = $params->{$id};
                }
            }

            $params = $data;
        } else {
            croak "An object may not be provided for revision storage unless a definition is provided";
        }
    }

    my $last_rev = $self->get_last_revision($grouping, $item);

    my $revision = $self->revision_rs->create({
        grouping   => $grouping,
        identifier => $item,
        recorded   => DateTime->now->ymd('-') . ' ' . DateTime->now->hms(':'),
        metadata   => $metadata,
    });

    for my $column (@columns)
    {
        $column = $column->{id}
            if ref $column;

        my $value;
        if (exists $params->{$column})
        {
            $value = $params->{$column};
        }
        elsif ($last_rev)
        {
            if (exists $last_rev->data->{$column}) {
                $value = $last_rev->data->{$column};
            } else {
                next;
            }
        }
        else
        {
            next;
        }

        $self->revision_data_rs->create({
            revision_id => $revision->revision_id,
            datum       => $column,
            datum_value => $value,
        });
    }

    return $self->_inflate_revision($revision);
}

=head2 get_revisions()

Given a grouping and item number, returns all associated revisions.

=cut

sub get_revisions
{
    my ($self, $grouping, $item, $revision_ids) = @_;

    $item = "$item";

    my %query = (
        grouping   => $grouping,
        identifier => $item,
    );

    if ($revision_ids) {
        $query{revision_id} = $revision_ids;
    }

    return map { $self->_inflate_revision($_) } $self->revision_rs->search( \%query );
}

=head2 get_last_revision()

Given a grouping and item number, returns the last revision.

=cut

sub get_last_revision
{
    my ($self, $grouping, $item) = @_;

    $item = "$item";

    my $record = $self->revision_rs->search({
        grouping   => $grouping,
        identifier => $item,
    }, {
        order_by => { -desc => 'revision_id' },
        rows     => 1,
    })->first;

    return $self->_inflate_revision($record);
}

=head2 compare_revisions()

Given two Data::Pensieve::Revision objects, returns a hash reference, keyed by column name, containing array references of the prior and current version of all changed data between the two provided revisions.

=cut

sub compare_revisions
{
    my ($self, $rev1, $rev2) = @_;

    croak "Two revisions must be provided"
        unless ($rev1 and $rev2);

    # Swap revisions 1 and 2 if revision 1 is newer
    my @revisions = ($rev1, $rev2);
    @revisions = sort {
        $a->row->revision_id <=> $b->row->revision_id ||
        $a->row->recorded    <=> $b->row->recorded
    } @revisions;
    ($rev1, $rev2) = @revisions;

    my $data1 = $rev1->data;
    my $data2 = $rev2->data;

    my $schema  = $self->schema($rev1->row->grouping);
    my @columns = ($schema and @$schema) ? @$schema : uniq (keys %$data1, keys %$data2);

    my %differences;
    for my $key (@columns)
    {
        $key = ref $key ? $key->{id} : $key;

        next unless (
            ( ((exists  $data1->{$key}) + (exists  $data2->{$key})) == 1 ) or
            ( ((defined $data1->{$key}) + (defined $data2->{$key})) == 1 ) or
            ( $data1->{$key} ne $data2->{$key} )
        );

        $differences{$key} = [ $data1->{$key}, $data2->{$key} ];
    }

    return wantarray ? %differences : \%differences;
}

=head2 diff_revisions()

Same as compare_revisions(), but returns a diff between the two values instead of an array reference.

=cut

sub diff_revisions
{
    my ($self, $rev1, $rev2) = @_;

    my $comparison = $self->compare_revisions($rev1, $rev2);

    for my $key (keys %$comparison)
    {
        my $values = $comparison->{$key};
        my ($cmp1, $cmp2) = @$values;

        my $diff   = diff( \$cmp1, \$cmp2, { STYLE => 'Text::Diff::HTML' } ); 
        $comparison->{$key} = $diff;
    }

    return wantarray ? %$comparison : $comparison;
}

#
# Here be undocumented methods.
#

sub _inflate_revision
{
    my ($self, $revision) = @_;

    return unless $revision;

    my $row = ref $revision
        ? $revision
        : $self->revision_rs->find($revision);

    return unless $row;

    return Data::Pensieve::Revision->new(
        pensieve => $self,
        row      => $row,
    );
}

sub schema
{
    my ($self, $grouping, $key) = @_;

    my $definitions = $self->definitions || {};
    my $definition  = $definitions->{$grouping};

    my $i = 0;
    for my $col (@$definition)
    {
        unless (ref $col and ref $col eq 'HASH') {
            $col = { id => $col };
        }

        $col->{label}   ||= ucfirst $col->{id} || '';
        $definition->[$i] = $col;

        $i++;
    }

    if ($key) {
        return first { $_->{id} eq $key } @$definition;
    }

    return $definition;
}

=head1 SEE ALSO

Data::Pensieve is intended as a quick & dirty, plug & play way to easily manage revisioned data.

If you're looking to do something more substantial, you probably want to consider journaling your data at the database level -- check out L<DBIx::Class::AuditLog> or L<DBIx::Class::Journal>.

=head1 DEPENDENCIES

L<Carp>, L<DateTime>, L<DateTime::Format::MySQL>, L<DBIx::Class>, L<List::Util>, L<List::MoreUtils>, L<Moose>, L<Storable>, L<Text::Diff>

=head1 AUTHORS

Michael Aquilina <aquilina@cpan.org>

Developed for Grant Street Group's Testafy (L<< http://testafy.com >>)

=cut

1;


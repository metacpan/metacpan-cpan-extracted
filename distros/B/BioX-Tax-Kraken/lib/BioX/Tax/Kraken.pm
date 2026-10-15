package BioX::Tax::Kraken 0.001003;

use strict;
use warnings;
use 5.016;
use autodie;

use IPC::Cmd qw/can_run/;
use List::Util qw/any first uniq/;

use constant N_VALID_COLUMNS => 4;
use constant PARENT => 0;
use constant NAME => 1;
use constant RANK => 2;

sub new {

    my ($class, $fn_in) = @_;

    my $self = bless {fn => $fn_in}, $class;

    $self->_set_handle();
    $self->_load();

    return $self;

}

sub parent {

    my ($self, $tid) = @_;

    return if (! defined $self->{tax}->{$tid});
    return $self->{_c_parent}->{$tid}
        if (defined $self->{_c_parent}->{$tid});
    my $p = (split "\0", $self->{tax}->{$tid})[PARENT];
    $self->{_c_parent}->{$tid} = $p;

    return $p;

}

sub name {

    my ($self, $tid) = @_;

    return if (! defined $self->{tax}->{$tid});
    return $self->{_c_name}->{$tid}
        if (defined $self->{_c_name}->{$tid});
    my $n = (split "\0", $self->{tax}->{$tid})[NAME];
    $self->{_c_name}->{$tid} = $n;

    return $n;

}

sub rank {

    my ($self, $tid) = @_;

    return if (! defined $self->{tax}->{$tid});
    return $self->{_c_rank}->{$tid}
        if (defined $self->{_c_rank}->{$tid});
    my $r = (split "\0", $self->{tax}->{$tid})[RANK];
    $self->{_c_rank}->{$tid} = $r;

    return $r;

}

sub children {

    my ($self, $tid) = @_;

    return if (! defined $self->{tax}->{$tid});
    return grep {
        $self->is_ancestor($_, $tid)
    } keys %{ $self->{tax} };

}

sub is_ancestor {

    my ($self, $child, $parent, $visited) = @_;

    $visited //= {}; # on first iteration

    return if (! defined $self->{tax}->{$child});
    return if (! defined $self->{tax}->{$parent});
    return 0 if ($child eq $parent); # save some time, maybe

    my $tag = "$child\b$parent";
    return $self->{_c_is_ancestor}->{$tag}
        if defined $self->{_c_is_ancestor}->{$tag};

    # Detect cycle: if we've visited this child in this query, stop
    if ($visited->{$child}++) {
        die "Cycle detected at $child! Bailing defensively...";
    }
    
    my $p = $self->parent($child);
    my $result;
    if ($p eq $parent) {
        $result = 1;
    }
    # the root node is a parent of itself;
    # prevent endless recursion here
    elsif ($p eq $child) {
        $result = 0;
    }
    else {
        $result = $self->is_ancestor( $p, $parent, $visited );
    }
    $self->{_c_is_ancestor}->{$tag} = $result;
    delete $visited->{$child};

    return $result;

}

# alias method
*a_isa_b = \&is_ancestor;

sub lineage {

    my ($self, $tid) = @_;
    my $orig = $tid;
    return if (! defined $self->{tax}->{$tid});
    return split( "\0", $self->{_c_lineage}->{$tid} )
        if defined $self->{_c_lineage}->{$tid};

    my @lineage = ($tid);
    my $parent = $self->parent($tid);
    my $visited = { $tid => 1 };

    while ($parent ne $tid) {
        if ($visited->{$parent}++) {
            die "Cycle detected in lineage of $orig at node $parent";
        }
        push @lineage, $parent;
        $tid = $parent;
        $parent = $self->parent($tid);
    }
    @lineage = reverse @lineage;
    $self->{_c_lineage}->{$orig} = join "\0", @lineage;
    return @lineage;

}

sub lca {

    my ($self, @ids) = @_;

    return if (! scalar @ids);
    return if any {! defined $self->{tax}->{$_} } @ids;

    my @l = map { [ $self->lineage($_) ] } @ids;
    my $lca;
    my $i = 0;
    while (1) {
        my @lvl = uniq map { $_->[$i] } @l;
        last if (any {! defined $_} @lvl);
        last if (scalar @lvl > 1);
        $lca = $lvl[0];
        ++$i;
    }
    
    return $lca;

}


sub _set_handle {

    my ($self) = @_;

    my $fh_in;
    if ( _is_xz($self->{fn}) ) {
        my $XZCAT = can_run('xzcat')
            // die "Require 'xzcat' for XZ-compressed inputs";
        open $fh_in, '-|', $XZCAT, $self->{fn};
    }
    else {
        open $fh_in, '<', $self->{fn};
    }
    $self->{fh} = $fh_in;

}


sub _is_xz {

    my ($fn) = @_;

    use constant XZ_MAGIC => "\xFD7zXZ\x00";
    open my $in, '<:raw', $fn;
    my $n = read $in, my $buf, 6;
    close $in;

    return 0 if ($n != 6);
    return $buf eq XZ_MAGIC

}

sub _load {

    my ($self) = @_;

    my $fh = $self->{fh};
    while (my $line = <$fh>) {
        chomp $line;
        my @f = split "\t", $line;
        if (scalar @f != N_VALID_COLUMNS) {
            die sprintf(
                "Invalid taxDB format: expected %s columns, found %s",
                N_VALID_COLUMNS,
                scalar @f,
            );
        }
        # uses < 50% memory to store data as null-padded strings instead of
        # Perl nested arrays or hashes. Can be significantly slower to extract
        # data on millions of calls, though.
        $self->{tax}->{$f[0]} = join "\0", @f[1..3];
    };
    close $fh;
    $self->{fh} = undef;

}

1;


__END__

=head1 NAME

BioX::Tax::Kraken - simple access to Kraken-style taxDB taxonomy database

=head1 SYNOPSIS

    use BioX::Tax::Kraken;

    use constant CHICKEN => 9031;
    use constant HUMAN => 9606;
    use constant VERTEBRATA => 7742;
    use constant WHITE_OAK => 3513;
    use constant HSV1 => 10298;

    my $tax = BioX::Tax::Kraken->new($ARGV[0]);

    say $tax->name(CHICKEN);
    # 'Gallus gallus'
    say $tax->rank(CHICKEN);
    # 'species'
    say $tax->name(
        $tax->parent(CHICKEN)
    );
    # 'Gallus'

    say $tax->is_ancestor(CHICKEN, VERTEBRATA) ? 'Y' : 'N';
    # 'Y'
    say $tax->is_ancestor(CHICKEN, WHITE_OAK) ? 'Y' : 'N';
    # 'N'
    say $tax->a_isa_b(CHICKEN, WHITE_OAK) ? 'Y' : 'N';
    # 'N'
    say $tax->name(
        $tax->lca(CHICKEN, HUMAN)
    );
    # 'Amniota'
    say $tax->name(
        $tax->lca(CHICKEN, WHITE_OAK)
    );
    # 'Eukaryota'
    say join ' > ',
        map {$tax->name($_)}
        $tax->lineage(HSV1);
    # 'root > Viruses > Duplodnaviria > Heunggongvirae > Peploviricota >
    # Herviviricetes > Herpesvirales > Orthoherpesviridae > Alphaherpesvirinae >
    # Simplexvirus > Simplexvirus humanalpha1'
    say join ' > ',
        map {$tax->rank($_)}
        $tax->lineage(HSV1);
    # 'no rank > domain > clade > kingdom > phylum > class > order > family >
    # subfamily > genus > species'

=head1 DESCRIPTION

NOTE:: This distribution is currently in testing phase. The API may change
without notice. You have been warned.

C<BioX::Tax::Kraken> is a simple interface to a Kraken-style flatfile
taxonomic database, typically using the filename 'taxDB'. This file format is
a four-column tab-delimited text file, where the columns contain:

=over 4

=item B<taxonomic ID>

=item B<parent ID>

=item B<name> (typically scientific)

=item B<rank>

=back

This distribution has a single class with methods to look up and compare
entries in a Kraken-style taxonomic database based on one or more taxonomic
IDs. It is designed to be simple and correct, and it is written to balance
speed and memory consumption. It is neither blazing fast nor ultra memory
efficient; there are better options for taxonomic data storage formats and
interfaces if you have one of these requirements. This software's only purpose
is to facilitate easy access to the information stored in a Kraken-style
database if you are already using that format for other reasons.

NOTE: The author typically utilizes the NCBI taxonomic database, where
taxonomic IDs are positive integers. Because this is Perl, all of the class
methods can be given either integers or strings as inputs; all inputs will be
treated as strings internally for purposes of comparison.

=head1 A NOTE ON ERROR HANDLING

The methods in this module are intentionally designed to be forgiving by
default. All methods take one or more taxonomic IDs as arguments; if an ID is
not found in the database, undefined is returned but no errors are thrown.
Because most taxonomic databases are constantly changing, this design choice
allows for the possibility of graceful failure if an ID has been removed from
the database without wrapping every method call in a try/catch block.

If you wish to treat these cases as errors, you must check for the definedness
of return values and throw your own errors accordingly. 

=head1 METHODS

=over 4

=item B<new> I<filename>

    my $tax = BioX::Tax::Kraken->new('/path/to/taxDB');

Create a new C<BioX::Tax::Kraken> object and load the database from file. The
input filename is required, and uncompressed or xz-compressed inputs are
supported (xz has significantly better compression ratios than gzip, bzip2, or
zstd on taxDB files).

Returns a new C<BioX::Tax::Kraken> object.

=item B<name> I<tax ID>

=item B<rank> I<tax ID>

=item B<parent> I<tax ID>

    say $tax->name(9031); # 'Gallus gallus'
    say $tax->rank(9031); # 'species'
    say $tax->parent(9031); # '9030'

Given a valid taxonomic ID, fetch the associated property from the database.

Returns a scalar string, or undefined if no entry was found for the input ID.

=item B<is_ancestor> I<child ID> I<parent ID>

    say "That explains a lot!"
        if $tax->is_ancestor(9606, 9443);

Given two valid taxonomic IDs, queries to database to check if the second ID
is an ancestor (not necessarily direct) of the first.

Returns a boolean value, or undefined if either ID was not found in the
database.

=item B<a_isa_b> I<child ID> I<parent ID>

Alias of C<is_ancestor> whose name makes it a little easier to remember the
order of arguments

=item B<lineage> I<tax ID>

    for my $id ( $tax->lineage(9031) ) {
        say sprintf "%s: %s",
            $tax->rank($id),
            $tax->name($id);
    }

Given a valid taxonomic ID, calculates the taxonomic lineage from the tree
root to the given node, inclusive.

Returns a list of IDs, or undefined if the given ID was not found in the
database.

=item B<lca> I<tax ID 1> I<tax ID 2> ...

    my $oldun = $tax->lca(9031, 9606);

Given two or more tax IDs, calculates the last common ancestor (LCA, aka MRCA)
in common to all given nodes.

Returns a taxonomic ID, or undefined if one or more given IDs were not found
in the database.

=item B<children> I<tax ID>

    my @descendents = $tax->children(9031);

Given a valid tax ID, traverses the taxonomic tree to collect all intermediate
and leaf nodes that descend from that ID. BEWARE: The class does not currently
store any back-references when parsing the input database. Thus, unlike all
other instance methods, this method currently must traverse the *entire*
database each time it is called, and it therefore will be a significant
bottleneck if called over thousands or millions of inputs.

Returns an unsorted list of IDs, or undefined if the given ID was not
found in the database.

=back

=head1 CAVEATS AND BUGS

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-BioX-Tax-Kraken/issues>.

=head1 AUTHOR

Jeremy Volkening <jeremy.volkening *at* base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 Jeremy Volkening

This software is licensed under the same terms as Perl 5 itself. See LICENSE
file for full details.

=cut


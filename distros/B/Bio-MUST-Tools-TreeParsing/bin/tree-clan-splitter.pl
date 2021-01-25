#!/usr/bin/env perl
# PODNAME: tree-clan-splitter.pl
# ABSTRACT: Extract clans (FASTA files) from trees based on taxonomic filters
# CONTRIBUTOR: Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>

use Modern::Perl '2011';
use autodie;

use Smart::Comments '###';
use Getopt::Euclid qw( :vars );

use Carp;
use File::Copy;
use File::Spec;
use Tie::IxHash;
use List::Compare;
use File::Basename;
use File::Find::Rule;
use Path::Class 'file', 'dir';
use List::AllUtils qw(min sum uniq any partition_by);

use Bio::MUST::Core;
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Core::Ali';
use aliased 'Bio::MUST::Core::Tree';
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::IdMapper';
use aliased 'Bio::MUST::Core::Taxonomy';
use aliased 'Bio::MUST::Core::Taxonomy::Filter';
use aliased 'Bio::MUST::Core::Taxonomy::Criterion';
use aliased 'Bio::MUST::Core::Taxonomy::Category';
use aliased 'Bio::MUST::Core::Taxonomy::Classifier';

## no critic (RequireLocalizedPunctuationVars)
BEGIN{
    $ENV{Smart_Comments} = $ARGV_verbosity
        ? join q{ }, map { '#' x (2 + $_) } 1..$ARGV_verbosity : q{} ;
}
use Smart::Comments -ENV;

# Collect tree(s)
my @intrees = File::Find::Rule
    ->file()
    ->name( qr{ .*  $ARGV_tree_suffix $ }xmsi )
    ->maxdepth(1)
    ->in($ARGV_indir)
;
### @intrees

#### Building classifier...
my $tax = Taxonomy->new_from_cache( tax_dir => $ARGV_taxdir );
my $classifier = _build_classifier();
### Done!

my @stripped_intrees;

TREE:
for my $intree (sort @intrees) {
    ### $intree

    my $tree = Tree->load($intree);
    my $stripped_intree = $intree;
       $stripped_intree =~ s/$_//xms for ($ARGV_tree_suffix);
    push @stripped_intrees, $stripped_intree;
    ### $stripped_intree

    # Eventually restore long ids
    if ($ARGV_map_ids) {
        # Load IDM file
        my $idm = IdMapper->load($stripped_intree . '.idm');

        # Restore long ids
        $tree->restore_ids($idm);
    }

    # Process intree file
    my $newick = $tree->tree->to_newick( -nodelabels => 1 );
       $newick =~ s/\'//xmsg;
       #### $newick

    my ($boot_hash, $spec_hash) = get_boot_spec_from_newick($newick);
    #### $boot_hash
    #### $spec_hash

    # optionally classify species and store to hashes
    my %seq_for;
    my @ps_idxs;
    my @all_groups;

    # classify each species
    for my $spec ( keys %$spec_hash ) {

        my $seq_id = SeqId->new( full_id => $spec );
        my $index  = $spec_hash->{$spec};
        my $group  = $classifier->classify($seq_id) // 'unwanted';
        #### $seq_id
        #### $index
        #### $group

        $seq_for{$index}{seq_id} = $seq_id;
        $seq_for{$index}{group} = $group;

        push @ps_idxs, $index if $group eq 'target';
        push @all_groups, $group;
    }

    # skip further processing if only one clan is found
    if ( uniq(@all_groups) == 1 ) {
        my ($type) = uniq(@all_groups);
        ### Only one clan found, type: $type
        if ( $type eq 'target' ) {

            my $alifile      = $stripped_intree . '.ali';
            my $clanzerofile = $stripped_intree . '-0.ali';
            my $ali = Ali->load($alifile);
               $ali->degap_seqs;
            ### Storing clan in: $clanzerofile
               $ali->store($clanzerofile);
        }
        ### Moving to next tree
        next TREE;
    }

    ### Reading clans for: $stripped_intree
#    my $clan_hash;
    my $clan_hash = get_clan_hash($boot_hash);
    ### Done reading clans for: $stripped_intree

    my @ps_clans;
    my @sorted_clans = sort { $clan_hash->{size}{$a} <=> $clan_hash->{size}{$b} }
        keys %{ $clan_hash->{size} };
    #### $clan_hash
    #### @sorted_clans

    SPLIT_CLAN:
    for my $clan (@sorted_clans) {

        my @idxs      = @{ $clan_hash->{idxs}{$clan} };
        my @seq_ids   = map { $seq_for{$_}{seq_id} } @idxs;
        my @full_orgs = map { $_->full_org         } @seq_ids;
        ##### $clan
        ##### @idxs

        # skip clans with only one species
        next SPLIT_CLAN if scalar uniq (@full_orgs) < 2;

        my @groups = map { $seq_for{$_}{group} } @idxs;
        my ($type) = uniq(@groups);

        # keep only strictly targeted clans
        next SPLIT_CLAN unless scalar uniq (@groups) == 1;
        next SPLIT_CLAN unless $type eq 'target';

        push @ps_clans, $clan;
        ##### $type
        ##### $clan
        ##### @idxs
        ##### @groups
    }
    #### @ps_clans

    unless ( scalar @ps_clans ) {
        ### No targeted clan(s) found for: $stripped_intree
        next TREE;
    }

    ### Checking clans layout...
    my ($is_included, $composition_for) = check_inclusions($clan_hash, \@ps_clans);
    my @main_clans = grep { ! %$is_included{$_} } @ps_clans;
    #### @main_clans

    # fit ali to ali2phylip filtering
    my $alifile  = $stripped_intree . '.ali';
    my $base_ali = Ali->load($alifile);
       $base_ali->dont_guess;
    my $alist = $tree->alphabetical_list;
    #### $list
    my $ali = $alist->filtered_ali($base_ali);

    my $n_ali;

    IDLIST:
    for my $main_clan ( @main_clans ) {

        $n_ali++;
        #### $main_clan
        my @clan_idxs = @{ $clan_hash->{idxs}{$main_clan} };
        my @seq_ids   = map { $seq_for{$_}{seq_id} } @clan_idxs;
        my @full_ids  = map { $_->full_id } @seq_ids;

        # apply list to Ali
        my $list       = IdList->new( ids => \@full_ids );
        my $pruned_ali = $list->filtered_ali($ali);
        my $outfile    = change_suffix($alifile, "-$n_ali.ali");

        # build corresponding para files
        my $nlist    = $list->negative_list($ali);
        my $para_ali = $nlist->filtered_ali($ali);
        my $parafile = change_suffix($alifile, "-$n_ali.para");

        ### Output alignment in: $outfile
        ### Output para file in: $parafile
        $pruned_ali->degap_seqs;
        $pruned_ali->store($outfile);
        $para_ali->degap_seqs;
        $para_ali->store($parafile);
    }
}


SUBROUTINES:

sub _build_classifier {
    if ($ARGV_otu_file) {
        my @categories;
        open my $in, '<', file($ARGV_otu_file);
        while ( my $line = <$in> ) {
            chomp $line;
            my ($label, $otu) = split ':', $line;

            my $list      = IdList->new( ids => [ split ',', $otu ] );
            my $filter    = $tax->tax_filter( $list );
            my $criterion = Criterion->new( tax_filter => $filter );
            my $category  = Category->new(
                label    => $label,
                criteria => [ $criterion ],
            );
            push @categories, $category;
        }
        close $in;

        return Classifier->new( categories => \@categories );
    }
    if ($ARGV_taxa_list) {

        open my $in, '<', $ARGV_taxa_list;
        chomp( my @ids = <$in> );
        my $id_list = IdList->new(ids => \@ids);
        return $tax->tax_labeler_from_list($id_list);
    }
}

sub change_path {
    my $infile          = shift;
    my $new_directories = shift;
    my $level           = shift;

    my ($filename, $directories) = fileparse($infile);
    # path::class::file

    my @dirs = split "/", $directories;

    my $outfile = file($new_directories ? $new_directories : '.',
                       $level ? File::Spec->catdir(splice @dirs, -$level) : '',
                       $filename
                       );
    return $outfile->stringify;
}


# build a hash of bipartitions from a Newick tree
my $badtree = "ERROR! The tree is not a valid Newick tree.\n";

sub get_topology {
    my ($tree) = @_;

    $tree =~ s/_{2,}//xmsg;                 # delete series of underscores
    $tree =~ s/\)[0-9Ee\.\-]+/)/xmsg;       # delete BPs
    $tree =~ s/:[0-9Ee\.\-]+//xmsg;         # delete branch lengths

    if ($tree =~ m/.*?(\(.*?\);)/xms) {     # not fool-proof for bad trees
        $tree = $1;
    }
    else { croak ($badtree); }
    return $tree;
}

sub get_topology_with_support {
    my ($tree) = @_;

    $tree =~ s/_{2,}//xmsg;                 # delete series of underscores
#   $tree =~ s/\)[0-9Ee\.\-]+/)xms/g;       # delete BPs
    $tree =~ s/:[0-9Ee\.\-]+//xmsg;         # delete branch lengths

    if ($tree =~ m/.*?(\(.*?\);)/xms) {     # not fool-proof for bad trees
        $tree = $1;
    }
    else { croak ($badtree); }
    return $tree;
}

sub get_boot_spec_from_newick {

    my $intree = shift;
    my $topology = get_topology($intree);
    #### $topology

    # extract species list
    $topology =~ s/[\(\)\;]+//xmsg;
    my @specs = split (',', $topology);

    # build species hash (numbered from 1 to spec_n)
    my $spec_n = 0;
    my $spec_hash = {};
    for my $spec (@specs) {
        $spec =~ s/^\s+|\s+$//xmsg;     # chop leading and trailing spaces
        $spec_hash->{$spec} = ++$spec_n;
    }
    #### $spec_hash

    my @bips;
    tie my %boot_hash, 'Tie::IxHash';

    my $tree = get_topology_with_support($intree);
    my $char = substr ($tree, 0, 1);

    while ($char ne ';') {

        my $badchar = "Maybe there are forbidden characters such as '$char'\n";

        # open new bipartition
        if ($char eq '(') {
            my $key = "." x $spec_n;
            push @bips, $key;
            $tree = substr ($tree, 1);
        }

        # close last open bipartition
        elsif ($char eq ')') {

            # throw error if not balanced parentheses
            croak ($badtree) if (@bips == 0);

            # store last bipartition
            my $key = pop @bips;
            my $bp_len = 0;
            if ($key !~ m/^\*+$/xms) {      # skip full tree
                my $tmp = $key;
                $tmp =~ s/\.//xmsg;         # skip trivial bipartitions
                my ($bp) = $tree =~ m/^\)(\d+)[\),]/xms;
                $bp_len = length($bp);
                $boot_hash{$key} = $bp || 1 if ($tmp ne "*");
                #### %boot_hash
            }
            #### before: $tree
            my $shift = 1 + $bp_len || 0;
            $tree = substr ($tree, $shift);
            #### after: $tree
        }

        # skip commas and spaces
        elsif ($char =~ m/[,\s]/xms) {
            $tree = substr ($tree, 1);
        }

        # process species name
        elsif ($tree =~ m/^([\#A-Za-z0-9_\@\-\.\ ]+(:?\#NEW\#)?)/xms) {

            # put stars for corresponding species in all open bipartitions
            my $col = $spec_hash->{$1};
            $tree = $';                     ## no critic (ProhibitMatchVars)

            for (my $i = 0; $i < @bips; $i++) {
                substr ($bips[$i], $col - 1, 1, '*');
            }
        }
        # throw error
        else { croak ($badtree . $badchar); }
        # read next char
        $char = substr ($tree, 0, 1);
    }

    return \%boot_hash, $spec_hash;
}


sub char_idxs {
    my ($bips, $char) = @_;

    my @indexes;
    my $offset = 0;

    my $index = index($bips, $char, $offset);
    push @indexes, ++$index;

    while ($index != 0) {

        $offset = $index;
        $index  = index($bips, $char, $offset);

        return \@indexes if $index == -1;

        push @indexes, ++$index;
    }

    return \@indexes;
}

sub get_clan_hash {
    my $boot_hash = shift;

    my $n_clan;
    my %clan_hash;
    BIP:
    while ( my ($bip, $boot) = each %$boot_hash ) {

#        next BIP if $boot < $ARGV_boot_threshold;
        my $dots  = $bip =~ tr/.//; # compute 1st clan size
        my $stars = $bip =~ tr/*//; # compute 2nd clan size

        # compute species indexes for both clans
        my $dots_idxs  = char_idxs($bip, '.');
        my $stars_idxs = char_idxs($bip, '*');
        $n_clan++;

        $clan_hash{size}{"dots_clan$n_clan"}  = @$dots_idxs;
        $clan_hash{idxs}{"dots_clan$n_clan"}  = $dots_idxs;
        $clan_hash{boot}{"dots_clan$n_clan"}  = $boot;
        $clan_hash{size}{"stars_clan$n_clan"} = @$stars_idxs;
        $clan_hash{idxs}{"stars_clan$n_clan"} = $stars_idxs;
        $clan_hash{boot}{"stars_clan$n_clan"} = $boot;
    }

    return \%clan_hash;
}


sub check_inclusions {
    my $clan_hash = shift;
    my $clans     = shift;

    my %is_included;
    my @previous_clans;
    my %composition_for;
    my @sorted_clans = sort { $clan_hash->{size}{$a} <=> $clan_hash->{size}{$b} } @$clans;

    for my $clan (@sorted_clans) {

        my $idxs = $clan_hash->{idxs}{$clan};

        for my $prev_clan (@previous_clans) {

            my $prev_idxs = $clan_hash->{idxs}{$prev_clan};
            my $lc_idxs = List::Compare->new( $prev_idxs, $idxs );
            my $is_subset = $lc_idxs->is_LsubsetR;

            $is_included{$prev_clan}            = 1 if $is_subset == 1;
            $composition_for{$clan}{$prev_clan} = 1 if $is_subset == 1;
        }
        push @previous_clans, $clan;
    }
    return \%is_included, \%composition_for;
}

# TODO: use YAML taxonomic filters as in classify-mcl-out.pl?

__END__

=pod

=head1 NAME

tree-clan-splitter.pl - Extract clans (FASTA files) from trees based on taxonomic filters

=head1 VERSION

version 0.210200

=head1 USAGE

    tree-clan-splitter.pl --indir <dir> --taxdir <dir> --tree-suffix=<str>
        [optional arguments]

=head1 REQUIRED ARGUMENTS

=over

=item --indir=<dir>

Path to input directory containing tree files.

=for Euclid: dir.type: str

=item --taxdir=<dir>

Path to local mirror of the NCBI Taxonomy database.

=for Euclid: dir.type: string

=item --tree-suffix=<str>

Suffix for finding trees in the defined working directory.

=for Euclid: str.type: string

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --otu[-file]=<file>

Path to artificial groups' file (user defined).

=for Euclid: file.type: readable

=item --taxa-list=<file>

Path to taxa list file for tax_labeler.

=for Euclid: file.type: readable

=item --og-regex=<str>

Regular expression for capturing ortholgous group name

=for Euclid str.type: string

=item --boot-threshold=<n>

Bootstrap threshold for filtering clans

=for Euclid: n.type: int
    n.default: 50

=item --map-ids

Restore ids from a .idm file

=item --verbosity=<level>

Verbosity level for logging to STDERR [default: level.default]. Available
levels range from 0 to 3.

=for Euclid: level.type: int, level >= 0 && level <= 3
    level.default: 0

=item --version

=item --usage

=item --help

=item --man

Print the usual program information

=back

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Mick VAN VLIERBERGHE

Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

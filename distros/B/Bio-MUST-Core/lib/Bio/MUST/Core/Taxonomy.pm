package Bio::MUST::Core::Taxonomy;
# ABSTRACT: NCBI Taxonomy one-stop shop
# CONTRIBUTOR: Loic MEUNIER <loic.meunier@doct.uliege.be>
# CONTRIBUTOR: Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>
$Bio::MUST::Core::Taxonomy::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

use Smart::Comments '###';

use MooseX::Storage;
with Storage('io' => 'StorableFile');

use Moose::Util::TypeConstraints;

use Algorithm::NeedlemanWunsch;
use Carp;
use Const::Fast;
use File::Basename;
use File::Find::Rule;
use IPC::System::Simple qw(system);
use List::AllUtils 0.12
    qw(first firstidx uniq each_array mesh count_by max_by);
use LWP::Simple qw(get getstore);
use Path::Class qw(dir file);
use POSIX;
use Scalar::Util qw(looks_like_number);
use Try::Tiny;
use Try::Tiny::Warnings;
use XML::Bare;

use Bio::LITE::Taxonomy::NCBI::Gi2taxid qw(new_dict);
use Bio::Phylo::IO qw(parse);

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:ncbi :files);
use Bio::MUST::Core::Utils qw(change_suffix);
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::IdList';
use aliased 'Bio::MUST::Core::IdMapper';
use aliased 'Bio::MUST::Core::Tree';
use aliased 'Bio::MUST::Core::Taxonomy::MooseNCBI';
use aliased 'Bio::MUST::Core::Taxonomy::Filter';
use aliased 'Bio::MUST::Core::Taxonomy::Criterion';
use aliased 'Bio::MUST::Core::Taxonomy::Category';
use aliased 'Bio::MUST::Core::Taxonomy::Classifier';
use aliased 'Bio::MUST::Core::Taxonomy::Labeler';
use aliased 'Bio::MUST::Core::Taxonomy::ColorScheme';


# public path to NCBI Taxonomy dump directory
has 'tax_dir' => (
    traits   => ['DoNotSerialize'],
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Types::Dir',
    required => 1,
    coerce   => 1,
);


# Note: init_arg => undef had to be removed to allow proper serialization
# this is needed because MooseX::Storage has never accepted my patches
# see https://rt.cpan.org/Public/Bug/Display.html?id=65733

has '_ncbi_tax' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Taxonomy::MooseNCBI',
    lazy     => 1,
    builder  => '_build_ncbi_tax',
    handles  => qr{get_\w+}xms, # expose Bio::LITE::Taxonomy accessor methods
);

                                # Note: this is related to (yet different from)
has '_gi_mapper' => (           # the nearly homonymous 'gi_mapper' method
    traits   => ['DoNotSerialize'],
    is       => 'ro',
    isa      => 'Bio::LITE::Taxonomy::NCBI::Gi2taxid',
    lazy     => 1,
    builder  => '_build_gi_mapper',
    handles  => {
        get_taxid_from_gi => 'get_taxid',
    },
);


has '_is_deleted' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Bool]',
    lazy     => 1,
    builder  => '_build_is_deleted',
    handles  => {
        'is_deleted' => 'defined',
    },
);


has '_' . $_ . '_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Str]',
    lazy     => 1,
    builder  => '_build_' . $_ . '_for',
    handles  => {
        'is_' .  $_    => 'defined',
          $_  . '_for' => 'get',
    },
) for qw(merged misleading);


has '_dupes_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[HashRef[Str]]',
    lazy     => 1,
    builder  => '_build_dupes_for',
    handles  => {
        'is_dupe'      => 'defined',
           'dupes_for' => 'get',
    },
);

# TODO: change this name? to avoid confusion with othe uses of rank_for
has '_rank_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[Str]',
    lazy     => 1,
    builder  => '_build_rank_for',
    handles  => {
        'rank_for' => 'get',
    },
);


has '_strain_taxid_for' => (
    traits   => ['Hash'],
    is       => 'ro',
    isa      => 'HashRef[HashRef[Str]]',
    lazy     => 1,
    builder  => '_build_strain_taxid_for',
    handles  => {
        'get_strain_taxid_for' => 'get',    # TODO: rename?
    },
);


has '_matcher' => (
    traits   => ['DoNotSerialize'],
    is       => 'ro',
    isa      => 'Algorithm::NeedlemanWunsch',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_matcher',
    handles  => {
        nw_score => 'align',
    },
);

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_ncbi_tax {
    my $self = shift;

    #### in _build_ncbi_tax

    local $_ = q{};     # to avoid loosing $_ due to Bio::LITE... constructor

    # open pipes from (possibly) multiple names.dmp and nodes.dmp
    my $names_txid = file($self->tax_dir, 'names*.dmp'   );
    my $names_gca  = file($self->tax_dir, 'gca*names.dmp');
    my $nodes_txid = file($self->tax_dir, 'nodes*.dmp'   );
    my $nodes_gca  = file($self->tax_dir, 'gca*nodes.dmp');

    # Note: taxid files are loaded last to get precedence in get_taxid_from_name
    my @names_files = ($names_gca, $names_txid);
    my @nodes_files = ($nodes_txid, $nodes_gca);

    # Note: names.dmp files are reordered on-the-fly so as scientific names
    # get precedence over other names (e.g., synonyms) in case of duplicates
    # Note: this should not be useful anymore (due to _dupes_for attribute)
    my $ol = q{'if (index($_, "scientific name") == -1) { print } else { push @sns, $_ } END{ print for @sns }'};
    open my $names_fh, '-|', qq{perl -nle $ol @names_files 2> /dev/null};
    open my $nodes_fh, '-|', qq{cat @nodes_files 2> /dev/null};

    return MooseNCBI->new(
        names => $names_fh,
        nodes => $nodes_fh,

        # allow most NCBI Taxonomy synonyms classes
        # cut -f4 -d'|' names.dmp | sort | uniq -c
        # last updated on Aug-18-2021
        #    1582   acronym
        #  576856   authority
        #     228   blast name
        #   14555   common name
        #   52040   equivalent name
        #     484   genbank acronym
        #   29979   genbank common name
        #    1096   genbank synonym
        #     733   in-part
        #   61755   includes
        # 2354398   scientific name
        #  199012   synonym
        #  167825   type material

        synonyms => [
            'synonym', 'genbank synonym',
            'acronym', 'genbank acronym',
            'anamorph', 'genbank anamorph', 'teleomorph',       # now useless
            'blast name', 'common name', 'genbank common name',
            'equivalent name', 'includes',
          # 'authority', 'in-part', 'type material',
        ]
    );
}

sub _build_gi_mapper {
    my $self = shift;

    #### in _build_gi_mapper

    local $_ = q{};     # to avoid loosing $_ due to Bio::LITE... constructor

    return Bio::LITE::Taxonomy::NCBI::Gi2taxid->new(
            dict => file($self->tax_dir, 'gi_taxid_nucl_prot.bin'),
        save_mem => 1,      # 0 does not work on my MacBook Air
    );
}

sub _build_is_deleted {
    my $self = shift;

    #### in _build_is_deleted

    my %is_deleted;

    my $infile = file($self->tax_dir, 'delnodes.dmp');
    open my $in, '<', $infile;

    while (my $line = <$in>) {
        my ($taxon_id) = $line =~ m/^(\d+)/xms;
        $is_deleted{$taxon_id} = 1;
    }

    return \%is_deleted;
}

sub _build_merged_for {
    my $self = shift;

    #### in _build_merged_for

    my %merged_for;

    my $infile = file($self->tax_dir, 'merged.dmp');
    open my $in, '<', $infile;

    while (my $line = <$in>) {
        chomp $line;
        my ($old_taxid, $new_taxid) = split /\s*\|\s*/xms, $line;
        $merged_for{$old_taxid} = $new_taxid;
    }

    return \%merged_for;
}

sub _build_misleading_for {
    my $self = shift;

    #### in _build_misleading_for

    my %misleading_for;

    # TODO: improve warning suppression
    # cat: .../taxdump/misleading*.dmp: No such file or directory
    my $misleadings = file($self->tax_dir, 'misleading*.dmp');
    open my $in, '-|', "cat $misleadings 2> /dev/null";

    while (my $line = <$in>) {
        chomp $line;
        my ($taxid, $full_org) = split /\s*\|\s*/xms, $line;
        $misleading_for{$full_org} = $taxid;
    }

    return \%misleading_for;
}

sub _build_dupes_for {
    my $self = shift;

    #### in _build_dupes_for

    my %taxids_for;

    my $infile = file($self->tax_dir, 'names.dmp');
    open my $in, '<', $infile;

    # build hash of NCBI names => taxon_id(s) for all taxa

    LINE:
    while (my $line = <$in>) {

        # focus on scientific names
        next LINE unless $line =~ m/scientific \s name/xms;

        # Note: old code was tolerant to "minor" duplications:
        # do not consider as duplicates genus and subgenus that are the same
        # similarly ignore duplicates involving phylum vs other levels
        # phyla come after classes and synonyms (and thus should win)
        # next LINE     if $line =~ m/genus>/xms || $line =~ m/<phylum>/xms;
        # next LINE     if $line =~ m/<actinobacteria>/xms;   # workaround...

        # extract taxon and track taxon_id
        chomp $line;
        my ($taxon_id, $taxon) = (split /\s*\|\s*/xms, $line)[0..1];
        push @{ $taxids_for{$taxon} }, $taxon_id;
    }

    my %dupes_for;

    # create helper Taxonomy object
    my $tax = $self->new( tax_dir => $self->tax_dir );

    TAXON:
    while (my ($taxon, $taxids) = each %taxids_for) {

        # only proceed for duplicate taxa
        next TAXON if @{$taxids} < 2;

        # build hash of partial lineage => taxon_id only for duplicate taxa
        no warnings 'uninitialized';    # avoid undef due to 2-4-level lineages
        my %taxid_for = map {
            ( join q{; }, ( $tax->get_taxonomy($_) )[-5..-1] ) => $_
        } @{$taxids};
        use warnings;

        # warn of taxa that end by the same three last taxa
        # Note: this looks like a NCBI bug a couple of scientific names
        carp "[BMC] Note: $taxon cannot be disambiguated."
            . ' This should not be an issue.' if keys %taxid_for < @{$taxids};

        $dupes_for{$taxon} = \%taxid_for;
    }

    return \%dupes_for;
}

# Note: taken from nodes.dmp as follows (then manually re-ordered)
# cut -f3 -d'|' nodes.dmp | sort | uniq
# last updated on Aug-18-2021
const my @LEVELS => (
    'skip',                     # default collapsing level
    'top',                      # useful to preserve 'cellular organisms'
    'superkingdom', 'kingdom', 'subkingdom',
    'superphylum', 'phylum', 'subphylum',
    'superclass', 'class', 'subclass', 'infraclass',
    'cohort', 'subcohort',
    'superorder', 'order', 'suborder', 'infraorder', 'parvorder',
    'superfamily', 'family', 'subfamily',
    'tribe', 'subtribe',
    'genus', 'subgenus',
    'section', 'subsection',
    'series',
    'species group', 'species subgroup', 'species', 'subspecies',

    'subvariety', 'varietas',   # relative order of all these terms is unclear
    'morph', 'forma', 'forma specialis',
    'isolate', 'strain',
    'pathogroup', 'serogroup', 'serotype',
    'biotype', 'genotype',

    'clade', 'no rank',         # both terms can appear anywhere in a lineage
);

sub _build_rank_for {
    #### in _build_rank_for
    my $i = 1;
    return { map { $_ => $i-- } @LEVELS };
}

sub _build_strain_taxid_for {
    my $self = shift;

    #### in _build_strain_taxid_for

    # open pipe from (possibly) multiple names.dmp
    # TODO: try to avoid code duplication with _build_ncbi_tax
    my $names_txid = file($self->tax_dir, 'names*.dmp'   );
    my $names_gca  = file($self->tax_dir, 'gca*names.dmp');

    # Note: taxid files are loaded last to get precedence over gca numbers
    my @names_files = ($names_gca, $names_txid);
    open my $names_fh, '-|', "cat @names_files";

    my %strain_taxid_for;

    LINE:
    while (my $line = <$names_fh>) {
        chomp $line;

        # fetch taxid and organism name
        my ($taxid, $org) = split /\s*\|\s*/xms, $line;

        # extract components from organism name
        my ($genus, $species, $strain) = SeqId->parse_ncbi_name($org);

        # skip entries without strain
        next LINE unless $strain;

        # store tax_id for org and strain combo
        my $org_key    = _make_hashkey($genus, $species);
        my $strain_key = _clean_strain($strain);
        $strain_taxid_for{$org_key}{$strain_key} = $taxid   # avoid bug with
            if defined $strain_key and length $strain_key;  # NW aligner
    }

    return \%strain_taxid_for;
}

sub _clean_strain {
    my $strain = shift;

    # remove unwanted prefices and characters (if any)
    $strain =~ s{\b substr \b}{}xmsgi;
    $strain =~ s{\b strain \b}{}xmsgi;
    $strain =~ s{\b subsp  \b}{}xmsgi;
    $strain =~ s{\b str    \b}{}xmsgi;
    $strain =~ tr/A-Za-z0-9//cd;        # delete non-alphanumeric chars

    return lc $strain;
}

sub _make_hashkey {
    my $genus   = shift;
    my $species = shift;

    $species =~ tr/-//d;        # clean hyphens in species
    my $org = lc( $genus . q{ } . $species );

    return $org;
}


const my $MATCHYOU   =>  3;     # cannot use $MATCH as it is reserved
const my $MISMATCH   => -1;
const my $GAP_OPEN   => -2;
const my $GAP_EXTEND =>  0;

sub _build_matcher {
    my $self = shift;

    #### in _build_matcher

    local $_ = q{};     # to avoid loosing $_ due to Algorithm::... constructor

    # setup Algorithm::NeedlemanWunsch object
    my $matcher = Algorithm::NeedlemanWunsch->new( \&_matcher_matrix );
    $matcher->gap_open_penalty(  $GAP_OPEN  );
    $matcher->gap_extend_penalty($GAP_EXTEND);

    return $matcher;
}

const my $GAP_CODE      => '*';
const my $MATCH_CODE    => '.';
const my $MISMATCH_CODE => ':';

const my %SCORE_FOR => (
    $GAP_CODE      => $GAP_OPEN,
    $MATCH_CODE    => $MATCHYOU,
    $MISMATCH_CODE => $MISMATCH,
);

sub _matcher_matrix {                       ## no critic (RequireArgUnpacking)
    return $SCORE_FOR{ _match_code(@_) };
}

sub _match_code {                           ## no critic (RequireArgUnpacking)
    return $GAP_CODE unless @_;

    # if one is not \w+ and the other is \w+ you want it to be a gap, not a
    # mismatch --> higher penalty
    if ( $_[0] =~ m/ [^A-Za-z0-9] /xms && $_[1] =~ m/  [A-Za-z0-9] /xms
      or $_[0] =~ m/  [A-Za-z0-9] /xms && $_[1] =~ m/ [^A-Za-z0-9] /xms ) {
        return $GAP_CODE;
    }

    if ( $_[0] =~ m/  [A-Za-z0-9] /xms || $_[1] =~ m/  [A-Za-z0-9] /xms ) {
        return ( lc $_[0] eq lc $_[1] ) ? $MATCH_CODE : $MISMATCH_CODE;
    }

    return $MATCH_CODE;
}

## use critic


# additional accessor methods (w.r.t. Bio::LITE::Taxonomy)
# Since Bio::LITE::Taxonomy methods return arrays (and not ArrayRefs), these
# methods also use arrays as in/out data structures (for consistency).
# Not quite... We use wantarray when needed now.

around qr{ _from_seq_id \z | _from_legacy_seq_id \z }xms => sub {
    my $method = shift;
    my $self   = shift;
    my $seq_id = shift;

    # coerce plain strings to SeqId...
    # ... but do not touch (stringified) lineages (and SeqIds)
    match_on_type $seq_id => (
        'Bio::MUST::Core::Types::Lineage' => sub { },
        'Str' => sub {
            $seq_id = SeqId->new( full_id => $seq_id )
        },
        => sub { },
    );

    return $self->$method($seq_id, @_);
};

around qr{ _from_name \z }xms => sub {
    my $method = shift;
    my $self   = shift;
    my $name   = shift;

    # avoid issue with undefined names
    return undef unless $name;      ## no critic (ProhibitExplicitReturnUndef)

    if ( $self->is_dupe($name) ) {
        carp "[BMC] Warning: $name is taxonomically ambiguous;"
            . ' returning undef!';
        return undef;               ## no critic (ProhibitExplicitReturnUndef)
    }

    return $self->$method($name);
};

# keep track of noted taxon mergers to avoid repeated Note messages
my %was_noted;

around qw( get_taxonomy get_taxonomy_with_levels get_term_at_level ) => sub {
    my $method   = shift;
    my $self     = shift;
    my $taxon_id = shift;

    # update taxon_id if merged in current version of NCBI Taxonomy
    # in contrast, we don't do anything if taxon_id has been deleted
    if ( defined $taxon_id && $self->is_merged($taxon_id) ) {
        my $noted = $was_noted{$taxon_id};         # noted?
        $was_noted{$taxon_id} //= 1;               # noted!
        my $msg = "[BMC] Note: merged taxid for $taxon_id;";
        $taxon_id = $self->merged_for($taxon_id);
        carp "$msg using $taxon_id instead!" unless $noted;
    }

    # enforce use of GCA accessions even with GCF accessions
    $taxon_id =~ tr/F/A/ if defined $taxon_id && $taxon_id =~ $GCAONLY;

    return $self->$method($taxon_id, @_);
};


sub get_taxid_from_seq_id {
    my $self   = shift;
    my $seq_id = shift;

    # 0. return undef in case of tagged contaminant sequences
    # TODO: return taxonomy of contaminant 'tail' if any?
    return undef                ## no critic (ProhibitExplicitReturnUndef)
        if $seq_id->is_doubtful;

    # 1. first handles valid MUST strain names that look like taxon_ids
    # Note1: 'valid' ids are the opposite to 'foreign_ids'
    # Note2: such cases are keyed by their full_org names
    unless ( $seq_id->is_foreign ) {
        my $taxon_id = $self->misleading_for( $seq_id->full_org );
        return $taxon_id if $taxon_id;
    }

    # 2. default path is to use already parsed taxon_id
    # this applies to modern MUST SeqIds and taxonomy-aware abbr ids
    return $seq_id->taxon_id
        if $seq_id->taxon_id;

    # 3. handles foreign_ids:
    # ... if a GI number is available then use the GI-to-taxid mapper
    # ... otherwise use full_id as a literal NCBI Taxonomy name
    if ( $seq_id->is_foreign ) {
        return $self->get_taxid_from_gi(   $seq_id->gi )
            if $seq_id->gi;
        return $self->get_taxid_from_name( $seq_id->full_id )
    }

    # back to valid MUST ids
    # idea: use as much information as possible but in case of failure...
    # ... retry after droppping the most specific piece (greedy behavior)

    # 4. tries to recover MUST legacy strain in NCBI Taxonomy...
    if ( $seq_id->strain ) {
        my $taxon_id = $self->get_taxid_from_legacy_seq_id($seq_id);
        return $taxon_id if $taxon_id;
    }

    # 5. tries to recover organism binomial in NCBI Taxonomy...
    unless ( $seq_id->is_genus_only ) {
        my $taxon_id = $self->get_taxid_from_name( $seq_id->org );
        return $taxon_id if $taxon_id;
    }

    # 6. tries to recover organism genus in NCBI Taxonomy
    # this may fail if genus is ambiguous (see around method modifier)
    return $self->get_taxid_from_name( $seq_id->genus );
}


sub get_taxid_from_legacy_seq_id {
    my $self   = shift;
    my $seq_id = shift;

    # fetch organism name
    my $org_key = _make_hashkey( $seq_id->genus, $seq_id->species );

    # fetch and clean organism (query) strain
    my $query_strain = $seq_id->strain;
    return undef                    ## no critic (ProhibitExplicitReturnUndef)
        unless $query_strain;
    $query_strain = lc SeqId->clean_strain($query_strain);

    # fetch hash containing 'strain => taxid' pairs
    # original clean code using native delegation:
    # my $taxid_for = $self->get_strain_taxid_for($org_key);
    # new hackish code for performance only:
    my $taxid_for = $self->_strain_taxid_for->{$org_key};
    return undef                    ## no critic (ProhibitExplicitReturnUndef)
        unless $taxid_for;

    # check if strain exist 'as is'
    my $taxid = $taxid_for->{$query_strain};
    return $taxid
        if $taxid;

    # fetch subject strains from hash in lexical order
    my @sbjct_strains = sort { $a cmp $b } keys %{$taxid_for};

    # split query and subject strains
    my @split_query_strain  =         split //xms,    $query_strain;
    my @split_sbjct_strains = map { [ split //xms ] } @sbjct_strains;

    # get score for each alignment through _matcher attribute
    my @scores = map {
        $self->nw_score( \@split_query_strain, $_ )
    } @split_sbjct_strains;

    # get strain with max_score
    my $max_score = List::AllUtils::max @scores;
    my $max_index = firstidx { $_ == $max_score } @scores;
    my $max_strain = $sbjct_strains[$max_index];

    # set heuristic threshold score based on shortest string len
    my $threshold = List::AllUtils::min(
        length $query_strain, length $max_strain
    ) * $MATCHYOU + $GAP_OPEN;

    # return strain taxid if above threshold
    return undef                    ## no critic (ProhibitExplicitReturnUndef)
        if $max_score < $threshold;
    return $taxid_for->{$max_strain};
}


sub get_taxonomy_from_seq_id {
    my $self   = shift;
    my $seq_id = shift;

    return match_on_type $seq_id => (

        # regular case: $seq_id is a Bio::MUST::Core::SeqId
        'Bio::MUST::Core::SeqId' => sub {
            $self->_taxonomy_from_seq_id_(0, $seq_id);
        },

        # optimizations for 'seq_ids' already being lineages (e.g., LCAs)
        # examine context for returning plain array or ArrayRef

        # case 1: stringified lineage that must be split on semicolons
        'Bio::MUST::Core::Types::Lineage' => sub {
            my @taxonomy = split qr{;\ *}xms, $seq_id;      # q{;} or q{; }
            wantarray ? @taxonomy : \@taxonomy;
        },

        # case 2: ArrayRef that just must be dereferenced
        ArrayRef => sub {
            wantarray ? @{$seq_id} : $seq_id
        },
    );
}


sub fetch_lineage {                         ## no critic (RequireArgUnpacking)
    return shift->get_taxonomy_from_seq_id(@_);
}


sub get_taxid_from_taxonomy {               ## no critic (RequireArgUnpacking)
    my $self = shift;

    # fetch taxonomy from args using match_on_type strategy (see above)
    # Note: this could also work from a seq_id but (this would be inefficient)
    my @taxonomy = $self->get_taxonomy_from_seq_id(@_);

    while (@taxonomy) {

        # first try to get taxon_id from last taxon
        my $taxon = $taxonomy[-1];
        my $taxon_id = $self->get_taxid_from_name($taxon);
        return $taxon_id if $taxon_id;

        # then try to disambiguate duplicate taxa
        my $dupes_for = $self->dupes_for($taxon);
        no warnings 'uninitialized';    # avoid undef due to 2-4-level lineages
        $taxon_id = $dupes_for->{ join q{; }, @taxonomy[-5..-1] };
        use warnings;
        if ($taxon_id) {
            carp "[BMC] Note: managed to disambiguate $taxon based on lineage!";
            return $taxon_id;
        }

        # finally retry with previous (= higher) taxon
        # Note: this should never be used for NCBI lineages
        # but for, e.g., SILVA lineages where (triplet) taxa may be different
        pop @taxonomy;
        carp "[BMC] Note: trying to identify $taxon by following lineage..."
            if @taxonomy;
    }

    return undef;                   ## no critic (ProhibitExplicitReturnUndef)
}


sub get_taxonomy_with_levels_from_seq_id {  ## no critic (RequireArgUnpacking)
    return shift->_taxonomy_from_seq_id_(1, @_);
}


sub _taxonomy_from_seq_id_ {
    my $self   = shift;
    my $levels = shift;
    my $seq_id = shift;

    # try to fetch taxon_id and corresponding taxonomy
    my $taxon_id = $self->get_taxid_from_seq_id($seq_id);
    my @taxonomy = $levels ? $self->get_taxonomy_with_levels($taxon_id)
                           : $self->get_taxonomy($taxon_id);

    # workaround for 'return undef' constructs in Bio::LITE::Taxonomy
    # ... to ensure that no (undef) list is returned by our additional methods
    # Note: our policy is thus unlike get_taxonomy and get_taxid_from_name
    @taxonomy = () unless $taxonomy[0];
    carp '[BMC] Warning: cannot fetch tax for ' . ( $seq_id->full_id || q{''} )
        . '; ignoring it!' unless @taxonomy;

    # examine context for returning plain array or ArrayRef
    return wantarray ? @taxonomy : \@taxonomy;
}


sub get_taxa_from_taxid {                   ## no critic (RequireArgUnpacking)
    my $self     = shift;
    my $taxon_id = shift;

    # TODO: consider numbered levels as in fetch-tax.pl?
    my @taxa = map { $self->get_term_at_level($taxon_id, $_) } @_;
    return wantarray ? @taxa : \@taxa;      # specify level through currying
}


# TODO: improve method using the following code snippet
# TODO: allows for non-pretty (@) MUST ids in --auto-final-ids
#     # fetch full taxonomy and lowest taxon
#     my @taxonomy = $tax->get_taxonomy($taxon_id);
#     my $org = $taxonomy[-1];
#
#     # proceed only if valid taxon_id
#     if ($org) {
#
#         # build base MUST id...
#         $must_id = SeqId->new_with(
#             org         => $org,
#             taxon_id    => $taxon_id,
#             keep_strain => $ARGV_keep_strain,
#         )->full_id;
#

sub get_nexus_label_from_seq_id {
    my $self   = shift;
    my $seq_id = shift;
    my $args   = shift // {};           # HashRef (should not be empty...)

    # try to fetch organism and accession (or GI number as a fallback)
    # TODO: allow for choosing between acc/gi when both are available
    my @lineage = $self->get_taxonomy_from_seq_id($seq_id);
    my $org = pop @lineage
        // $seq_id->full_org( q{ } );       # use space before strain
    my $acc = $args->{append_acc} ? $seq_id->accession // $seq_id->gi : undef;

    # build label according to available pieces
    # Note: fallback to full_id for foreign ids (undefined org)
    my $label = defined $org && defined $acc ? "$org [$acc]"
              : defined $org                 ?  $org
              :                                 $seq_id->full_id
    ;

    return SeqId->new(full_id => $label)->nexus_id;
}


# clade analysis methods


sub get_common_taxonomy_from_seq_ids {      ## no critic (RequireArgUnpacking)
    my $self    = shift;
    my @seq_ids = @_;

    # setup optional threshold (if any) to first argument
    # Note: this approach is used to preserved backwards compatibility
    # Note: even if SeqId->full_id is a number the test works as expected
    my $threshold = looks_like_number $seq_ids[0] ? shift @seq_ids : 1.0;

    # fetch lineages for all seq ids
    my @lineages = map {
        scalar $self->get_taxonomy_from_seq_id($_)  # note the scalar context
    } @seq_ids;

    # compute common lineage
    return $self->_common_taxonomy($threshold, @lineages);
}


sub compute_lca {                           ## no critic (RequireArgUnpacking)
    return shift->get_common_taxonomy_from_seq_ids(@_);
}

sub _common_taxonomy {                      ## no critic (RequireArgUnpacking)
    my $self      = shift;
    my $threshold = shift;
    my @lineages  = @_;

    # ignore missing lineages
    # TODO: decide whether missing lineages should be taken into account
    @lineages = grep { @{$_} ? $_ : () } @lineages;

    my @common_lineage;

    # original version: strict consensus
    # Note the use of a dynamically-sized multiple ArrayRef iterator
    # to walk down all lineages in parallel
    # my $ea = each_arrayref(@lineages);
    #
    # TAXON:
    # while ( my @taxa = $ea->() ) {
    #     no warnings 'uninitialized';  # avoid undef due to longer lineages
    #     last TAXON if uniq(@taxa) > 1;
    #     push @common_lineage, shift @taxa;
    # }

    # current version: threshold-based majority-rule consensus
    # algorithm: at each taxonomic rank count all seen taxa
    # if the most popular taxon is seen > threshold (w.r.t. all lineages)
    # then continue with the lineages featuring it
    # otherwise stop at previous taxon
    my $n = @lineages;

    TAXON:
    for (my $i = 0; $n; $i++) {
        my %count_for = count_by { $_->[$i] // q{} } @lineages;
        my $taxon = max_by { $count_for{$_} } keys %count_for;
        last TAXON unless $taxon;
        my $taxon_n = $count_for{$taxon};
        last TAXON if $taxon_n / $n < $threshold;
        push @common_lineage, $taxon;
        @lineages = grep { ( $_->[$i] // q{} ) eq $taxon } @lineages;
    }

    # examine context for returning plain array or ArrayRef
    return wantarray ? @common_lineage : \@common_lineage;
}

# tree annotation methods


sub attach_taxonomies_to_terminals {
    my $self = shift;
    my $tree = shift;

    #### ATTACHING TAXONOMIES TO TERMINALS...

    # transparently fetch Bio::Phylo component object
    $tree = $tree->tree if $tree->isa('Bio::MUST::Core::Tree');

    # store tip taxonomies in Bio::Phylo::Forest::Node generic attributes
    for my $tip ( @{ $tree->get_terminals } ) {

        # fetch taxonomy (and level list) from tip's seq id
        my @tax = $self->get_taxonomy_with_levels_from_seq_id($tip->get_name);

        # attach them as distinct ArrayRefs
        $tip->set_generic('taxonomy' => [ map { $_->[0] } @tax ] );
        $tip->set_generic('levels'   => [ map { $_->[1] } @tax ] );

        # Note: levels are needed for robust clade naming and collapsing.
        # Indeed, get_level_from_name() can return incorrect level when a name
        # exists at more than one taxonomic level in NCBI Taxonomy (e.g.,
        # Bacteria, which is also an insect genus).
    }

    return;
}



sub attach_taxonomies_to_internals {
    my $self = shift;
    my $tree = shift;

    # post-order tree traversal
    $tree->tree->visit_depth_first(

        # infer common taxonomy from direct children of each node
        -post => sub {
            my $node = shift;
            return if $node->is_terminal;

            # collect children lineages
            # ... and track the longest (better to be safe...) level list
            my @lineages;
            my @max_levels;
            for (my $i = 0; my $child = $node->get_child($i); $i++) {
                push @lineages, $child->get_generic('taxonomy');
                my @levels = @{ $child->get_generic('levels') };
                @max_levels = @levels if @levels > @max_levels;
            }

            # store into current node their common lineage
            # ... and cut down level list to match this common lineage
            my @common_lineage = $self->_common_taxonomy(1.0, @lineages);
            $node->set_generic('taxonomy' => \@common_lineage);
            $node->set_generic(
                'levels' => [ @max_levels[0..$#common_lineage] ]
            );

            return;
        },
     );

    return;
}



sub attach_taxa_to_entities {
    my $self = shift;
    my $tree = shift;
    my $args = shift // {};             # HashRef (should not be empty...)

    # setup minimal taxonomic level(s) to reach
    # Note 1: only named levels can be selected (see list above)
    # Note 2: thus, 'no rank' results in the lowest possible taxon
    # Note 3: default values are provided
    my %arg_levels = ( name => 'no rank', collapse => 'skip', %{$args} );
    my %target_for = map {
        $_ => $self->rank_for( $arg_levels{$_} )
    } keys %arg_levels;

    # ensure meaningful subtree collapsing WRT naming
    if ($target_for{collapse} < $target_for{name}) {
        carp '[BMC] Warning: collapsing level must include naming level;'
            . ' upgrading!';
        $target_for{collapse} = $target_for{name};
    }

    # update both terminal and internal nodes
    # attach lowest taxon with level higher or equal to target level(s)

    NODE:
    for my $node ( @{ $tree->tree->get_entities } ) {

        # reset taxon for robustness
        my $is_named;
        $node->set_generic('taxon' => undef);
        $node->set_generic('taxon_collapse' => undef);

        # walk up node lineage
        my @lineage = @{ $node->get_generic('taxonomy') };
        my @levels  = @{ $node->get_generic('levels') };
        while (my $taxon = pop @lineage) {

            # OLD VERSION DERIVING LEVEL FROM TAXON NAME
            # ... if taxon was the highest in the lineage then rank it at top
            # Note: this is needed to preserve 'cellular organisms'
            # my $rank = @lineage == 0 ? 0    # 0 means 'top rank'
            #     : $self->rank_for( $self->get_level_from_name($taxon) );

            # get rank for taxon
            my $rank = $self->rank_for( pop @levels );

            # name subtree at target level or above
            if (!$is_named && $rank >= $target_for{name}) {
                $node->set_generic('taxon' => $taxon);
                $is_named = 1;              # to get the lowest possible taxon
            }   # ... while keeping walking up to collapse at a higher level

            # collapse subtree only at target level
            if ($rank == $target_for{collapse}) {
                $node->set_generic('taxon_collapse' => $taxon);
                next NODE;                  # can stop walking up now!
            }
        }
    }

    return;
}

# Listable IdList and IdMapper factory methods

# TODO: decide on whether this kind of check is needed and where...

# around qr{ \A taxonomic_ }xms => sub {
#     my $method   = shift;
#     my $self     = shift;
#     my $listable = shift;
#
#     # ensure the object is listable (we could also test for the role)
#     unless ( $listable->can('all_seq_ids') ) {
#         carp 'Cannot build list/mapper from ' . ref($listable) . '; aborting!';
#         return;
#     }
#
#     return $self->$method($listable, @_);
# };

# TODO: remove support for GI numbers


sub gi_mapper {
    my $self     = shift;
    my $listable = shift;

    return IdMapper->new(
        long_ids => [ $self->_taxids_from_gis($listable) ],
        abbr_ids => [ map { $_->full_id } $listable->all_seq_ids ],
    );
}

const my $BATCH_SIZE   => 252;
const my $GOLDEN_RATIO => 1.618;
const my $MAX_ATTEMPT  => 3;

sub _taxids_from_gis {
    my $self     = shift;
    my $listable = shift;

    # get full_ids and GI numbers
    my @seq_ids = $listable->all_seq_ids;
    my @full_ids = map { $_->full_id } @seq_ids;
    my @gis      = map { $_->gi      } @seq_ids;
    ### GIs to process: scalar @gis
    my @uniq_gis = uniq @gis;
    ### Unique GIs to process: scalar @uniq_gis

    # try to associate taxon_ids to GIs using binary GI-to-taxid mapper
    my %taxid_for;
    try {
        %taxid_for = map { $_ => $self->get_taxid_from_gi($_) } @uniq_gis;
    }
    catch {
        ### Note: 'Cannot load binary GI-to-taxid mapper'
    };

    # collect missing taxon_ids
    my @miss_gis = grep { not $taxid_for{$_} } @uniq_gis;

    if (@miss_gis) {
        ### Unique GIs missing from binary GI-to-taxid mapper: scalar @miss_gis
        ### Fetching corresponding taxon_ids online instead...
    }

    my %miss_taxid_for;
    my $batch_size = $BATCH_SIZE;
    my $attempt = 1;

    ESUMMARY:
    while (@miss_gis) {             ### Iterating on missing GIs |===[%]    |
        my $total = @miss_gis;
        $batch_size = List::AllUtils::min($batch_size, $total);
        #### $total
        #### $batch_size
        #### $attempt

        BATCH:
        for (my $i = 0; $i < $total; $i += $batch_size) {
            my $end = List::AllUtils::min($i + $batch_size, $#miss_gis);
            #### $i
            #### $end

            # fetch eSummaries for current batch of GI numbers
            my $report = get(
                'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?'
                    . 'db=protein&id=' . join ',', @miss_gis[$i..$end]
            );

            # stop using current batch size if no answer from NCBI servers
            last BATCH unless $report;

            # parse XML report into hash tree
            my $ob = XML::Bare->new( text => $report );
            my $root = $ob->parse();

            # capture GI number/taxon_id pairs for each eSummary of the report
            for my $docsum ( @{ $root->{eSummaryResult}{DocSum} } ) {
                my @fields = @{ $docsum->{Item} };
                my $gi    = first { $_->{Name}->{value} eq 'Gi'    } @fields;
                my $taxid = first { $_->{Name}->{value} eq 'TaxId' } @fields;
                $miss_taxid_for{ $gi->{value} } = $taxid->{value};
            }
        }

        # update hash with retrieved taxon_ids
        %taxid_for = (%taxid_for, %miss_taxid_for);

        # collect anew missing taxon_ids
        @miss_gis = grep { not $taxid_for{$_} } @uniq_gis;

        # if some taxon_ids are still missing...
        if (@miss_gis) {

            # reduce batch_size after MAX_ATTEMPT attempts
            if (++$attempt > $MAX_ATTEMPT) {
                $batch_size = floor($batch_size / $GOLDEN_RATIO);
                $attempt = 1;
            }

            # stop trying if batch_size falls to zero
            unless ($batch_size) {
                carp '[BMC] Warning: no answer from NCBI E-utilities;'
                    . ' dropping GIs!';
                last ESUMMARY;
            }
        }
    }

    ### Unique GIs retrieved online: scalar keys %miss_taxid_for
    ### Unique GIs still missing: scalar @miss_gis

    # build new ids by prepending taxon_ids to full_ids
    my @taxids_gis;
    my $ea = each_array(@full_ids, @gis);
    while ( my ($full_id, $gi) = $ea->() ) {
        push @taxids_gis, $taxid_for{$gi} . '|' . $full_id;
    }

    return @taxids_gis;
}



sub tab_mapper {
    my $self    = shift;
    my $infile  = shift;
    my $args    = shift // {};

    my $col = $args->{column}    // 1;
    my $sep = $args->{separator} // qr{\t}xms;
    my $idm = $args->{gi2taxid};

    open my $in, '<', $infile;

    tie my %family_for, 'Tie::IxHash';

    LINE:
    while ( my $line = <$in>) {
        chomp $line;

        # skip empty lines and comment lines
        next LINE if $line =~ $EMPTY_LINE
                  || $line =~ $COMMENT_LINE;

        my @fields = split $sep, $line;
        $family_for{ $fields[0] } = $fields[$col];
    }

    my @abbr_ids = keys %family_for;
    my @must_ids = @abbr_ids;

    if ($idm) {

        # build gi2taxid 'mapper'
        my $gi_mapper = IdMapper->load($idm);
        my @gis       = map { $_->gi       } $gi_mapper->all_abbr_seq_ids;
        my @taxon_ids = map { $_->taxon_id } $gi_mapper->all_long_seq_ids;
        my %taxid_for = mesh @gis, @taxon_ids;

        # build modern seq_ids from GIs using 'mapper'
        for my $id (@must_ids) {
            my $taxon_id = $taxid_for{ SeqId->new( full_id => $id )->gi };
            my @taxonomy = $self->get_taxonomy($taxon_id);
            my $org = $taxonomy[-1];
            $id = SeqId->new_with(
                org      => $org,
                taxon_id => $taxon_id,
                gi       => $id,            # actually not a 'pure' GI here
            )->full_id;
        }
    }

    my @long_ids;

    my $ea = each_array @must_ids, @abbr_ids;
    while ( my ($must_id, $abbr_id) = $ea->() ) {
        ( my $family = $family_for{$abbr_id} // q{} ) =~ tr/- @_/./;
        $family .= '-' if $family;
        push @long_ids, $family . $must_id;
    }

    return IdMapper->new(
        long_ids => \@long_ids,
        abbr_ids => \@abbr_ids,
    );
}



sub tax_mapper {                        ## no critic (RequireArgUnpacking)
    my $self     = shift;
    my $listable = shift;

    return IdMapper->new(
        long_ids => [ map {
            $self->get_nexus_label_from_seq_id($_, @_)
        } $listable->all_seq_ids ],
        abbr_ids => [ map { $_->full_id } $listable->all_seq_ids ],
    );
}



sub tax_filter {
    my $self = shift;
    my $list = shift;

    return Filter->new( tax => $self, _specs => $list );
}



sub tax_criterion {
    my $self = shift;
    my $args = shift;

    $args->{tax_filter} = $self->tax_filter( $args->{tax_filter} );

    return Criterion->new($args);
}



sub tax_category {
    my $self = shift;
    my $args = shift;

    $args->{criteria} = [
        map { $self->tax_criterion($_) } @{ $args->{criteria} }
    ];

    return Category->new($args);
}


# Classifier/Labeler/ColorScheme factory methods


sub tax_classifier {
    my $self = shift;
    my $args = shift;

    $args->{categories} = [
        map { $self->tax_category($_) } @{ $args->{categories} }
    ];

    return Classifier->new($args);
}

# example of input HashRef for tax_classifier
# 'min', 'max' and 'description' keys are both optional
# categories => [
#                 {
#                   criteria => [
#                                 {
#                                   max => undef,
#                                   min => 1,
#                                   tax_filter => [
#                                                   '+Latimeria'
#                                                 ]
#                                 },
#                                 {
#                                   tax_filter => [
#                                                   '+Protopterus'
#                                                 ]
#                                 },
#                                 {
#                                   tax_filter => [
#                                                   '+Danio',
#                                                   '+Oreochromis'
#                                                 ]
#                                 },
#                                 {
#                                   tax_filter => [
#                                                   '+Xenopus'
#                                                 ]
#                                 },
#                                 {
#                                   tax_filter => [
#                                                   '+Anolis',
#                                                   '+Gallus',
#                                                   '+Meleagris',
#                                                   '+Taeniopygia'
#                                                 ]
#                                 },
#                                 {
#                                   tax_filter => [
#                                                   '+Mammalia'
#                                                 ]
#                                 }
#                               ],
#                   description => 'strict species sampling',
#                   label => 'strict'
#                 },
#                 {
#                   criteria => [
#                                 {
#                                   tax_filter => [
#                                                   '+Latimeria'
#                                                 ]
#                                 },
#                                 {
#                                   tax_filter => [
#                                                   '+Protopterus'
#                                                 ]
#                                 },
#                                 {
#                                   tax_filter => [
#                                                   '+Danio',
#                                                   '+Oreochromis'
#                                                 ]
#                                 },
#                                 {
#                                   tax_filter => [
#                                                   '+Amphibia',
#                                                   '+Amniota'
#                                                 ]
#                                 }
#                               ],
#                   description => 'loose species sampling',
#                   label => 'loose'
#                 }
#               ]



sub tax_labeler_from_systematic_frame {
    my $self   = shift;
    my $infile = shift;

    # Thursday 26 November 2015 at 15 hours 21
    # ((((((Crenarchaeota:371:88:-1,Korarchaeota:371:72:-1)a:15:80:-1,...)Tree of Life:3:16:-1;

    # ensure that we get a parseable tree from the .fra file
    # by considering only line 2 and turning all funny 'branch lengths' to 1
    my @lines = file($infile)->slurp;
    (my $newick_str = pop @lines) =~ s/(?: :-?(\d+) ){3}/:1/xmsg;

    # parse tree using Bio::Phylo
    # Note: keep whitespace because tip labels are not between quotes
    my $tree = parse(
        -format => 'newick',
        -string => $newick_str,
        -keep_whitespace => 1,
    )->first;

    # extract tip labels
    my @labels = map { $_->get_name } @{ $tree->get_terminals };

    # build classifier from labels
    return $self->tax_labeler_from_list( \@labels );
}



sub tax_labeler_from_list {
    my $self = shift;
    my $list = shift;

    return Labeler->new( tax => $self, labels => $list );
}



sub load_color_scheme {                     ## no critic (RequireArgUnpacking)
    my $self = shift;
    my $scheme = ColorScheme->new( tax => $self );
    return $scheme->load(@_);
}



sub eq_tax {                                ## no critic (RequireArgUnpacking)
    my $self       = shift;
    my $got        = shift;
    my $expect     = shift;
    my $classifier = shift;

    # classify got and expect orgs
    my $got_taxon = $classifier->classify($got,    @_);
    my $exp_taxon = $classifier->classify($expect, @_);

    # use context to decide what to return
    # list context: return taxon labels
    return ($got_taxon, $exp_taxon)
        if wantarray;

    # scalar context: compare taxon labels if both are defined
    return undef                    ## no critic (ProhibitExplicitReturnUndef)
        unless $got_taxon && $exp_taxon;

    return $got_taxon eq $exp_taxon;
}


# I/O METHODS

const my $CACHEDB => 'cachedb.bin';


sub new_from_cache {                        ## no critic (RequireArgUnpacking)
    my $class = shift;
    my %args  = @_;                         # TODO: handle HashRef?

    ### Loading NCBI (or GTDB) Taxonomy from binary cache file...
    my $tax_dir = dir( glob $args{tax_dir} );
    my $cachefile = file($tax_dir, $CACHEDB);
    my $tax = $class->load($cachefile, inject => { tax_dir => $tax_dir } );

    ### Done!
    return $tax;
}


sub update_cache {
    my $self = shift;

    my $cachefile = file($self->tax_dir, $CACHEDB);
    ### Updating binary cache file: $cachefile->stringify
    $self->store($cachefile);

    ### Done!
    return 1;
}


# class method to setup local taxonomy database


sub setup_taxdir {
    my $class   = shift;
    my $tax_dir = shift;
    my $args    = shift // {};          # HashRef (should not be empty...)

    my $source = $args->{source};

    $class->_setup_ncbi_taxdir($tax_dir, $args)
        if $source eq 'ncbi';

    $class->_setup_gtdb_taxdir($tax_dir)
        if $source eq 'gtdb';

    return;
}


sub _setup_ncbi_taxdir {
    my $class   = shift;
    my $tax_dir = shift;
    my $args    = shift // {};          # HashRef (should not be empty...)

    my $gi_mapper = $args->{gi_mapper} // 0;

    # setup local directory
    $tax_dir = dir( glob $tax_dir );
    $tax_dir->mkpath();

    ### Installing NCBI Taxonomy database to: $tax_dir->stringify
    ### Please be patient...

    # setup remote archive access
    my $base = 'ftp://ftp.ncbi.nih.gov/pub/taxonomy';
    my @targets = (
        'taxdump.tar.gz',
        $gi_mapper ? qw(gi_taxid_nucl.dmp.gz gi_taxid_prot.dmp.gz) : ()
    );

    # download and install file(s)...
    # ... first, the taxon_id version...
    my @dmpfiles;
    for my $target (@targets) {
        my $url  = "$base/$target";

        ### Downloading: $url
        my $zipfile = file($tax_dir, $target)->stringify;
        # Note: stringify is required by getstore
        my $ret_code = getstore($url, $zipfile);
        croak "[BMC] Error: cannot download $url: error $ret_code; aborting!"
            unless $ret_code == 200;

        # TODO: use modules for unarchiving (not that easy)

        ### Unarchiving: $zipfile
        if ($target =~ m/\A gi_taxid/xms) {         # GI mappers
            system("gzip -d $zipfile");
            push @dmpfiles, change_suffix( $zipfile, q{} );
        }
        else {                                      # main tax archive
            system("tar -xzf $zipfile -C $tax_dir");
            file($zipfile)->remove;
        }
    }

    # delete gca files if any
    my $gcanamefile = file($tax_dir, 'gca0-names.dmp');
    my $gcanodefile = file($tax_dir, 'gca0-nodes.dmp');
    $gcanamefile->remove if -e $gcanamefile;
    $gcanodefile->remove if -e $gcanodefile;

    #... second, the accession_id version
    $class->_make_gca_files($tax_dir);

    # return true on success (only check main files)
    if ( -r $gcanamefile && -r $gcanodefile ) {
        ### Successfully wrote GCA-based files!
    }

    # delete cache if any
    my $cachefile = file($tax_dir, $CACHEDB);
    $cachefile->remove if -e $cachefile;

    # optionally build binary GI mapper from GI-to-taxid flat files
    if ($gi_mapper) {
        my $mrgfile = file($tax_dir, 'gi_taxid_nucl_prot.dmp')->stringify;
        ### Merging GI-to-taxid flat files to: $mrgfile
        system("sort -nm @dmpfiles > $mrgfile");
        my $binfile = change_suffix($mrgfile, '.bin');
        ### Building binary GI-to-taxid mapper: $binfile
        new_dict( in => $mrgfile, out => $binfile );
        file($_)->remove for @dmpfiles, $mrgfile;
    }

    # return true on success (only check main files)
    if ( -r file($tax_dir, 'names.dmp') && -r file($tax_dir, 'nodes.dmp') ) {
        ### Successfully wrote taxid files!
        return 1;
    }

    ### Failed installation!
    return 0;
}

# December 2024
# $ cd ~/taxdump
# $ wc -l assembly_summary_*txt
#  2698890 assembly_summary_genbank.txt
#    75493 assembly_summary_genbank_historical.txt
#   414559 assembly_summary_refseq.txt
#    93051 assembly_summary_refseq_historical.txt
#  3281993 total
#
# $ cut -f1 *genbank_historical.txt | cut -c5- | sort | uniq > gca_hist
# $ cut -f1 *genbank.txt | cut -c5- | sort | uniq > gca
# $ cut -f1  *refseq_historical.txt | cut -c5- | sort | uniq > gcf_hist
# $ cut -f1  *refseq.txt | cut -c5- | sort | uniq > gcf
#
# $ cat gca gca_hist | sort | uniq -d
#        2              # header
# $ cat gcf gcf_hist | sort | uniq -d
#        2              # header
# $ cat gca gcf | sort | uniq -d | wc -l
#   411120              # incl. header
# $ cat gca gcf_hist | sort | uniq -d | wc -l
#    79371              # incl. header
#
# $ sort gca_hist gca > gca_all
# $ sort gcf_hist gcf > gcf_all
#
# $ join gcf_all gca_all > redund_gcf
# $ wc -l redund_gcf
#   507183 redund_gcf
# $ diff redund_gcf gcf_all | grep \> | cut -c3- > uniq_gcf
# $ wc -l uniq_gcf
#      433 uniq_gcf     # these RefSeq's GCFs are not found in GenBank's GCAs
#
# # check output of BMC's (smart) skipping of redundant GCFs
# $ grep GCF gca0-names.dmp | cut -f1 | cut -c5- | sort > uniq_gcf_bmc
# $ wc -l uniq_gcf_bmc
#      431 uniq_gcf_bmc # identical (only missing header)
#
# # now these are turned to GCAs in cachedb.bin

sub _make_gca_files {
    my $class   = shift;
    my $tax_dir = shift;

    const my $FS       => qq{\t|\t};
    const my $FS_REGEX => qr{\t \| \t}xms;

    my %rank_for;
    my %parent_taxid_for;

    # open nodes.dmp file
    my $nodes = file($tax_dir, 'nodes.dmp');
    open my $in, '<', $nodes;

    # get taxon_id and parent_taxon_id from nodes.dmp file
    while (my $line = <$in>) {
        chomp $line;
        my ($taxon_id, $parent_taxon_id, $rank) = $line
            =~ m/^ (\d+) $FS_REGEX (\d+) $FS_REGEX ([^\t]+) $FS_REGEX/xmsg;
        $rank_for{$taxon_id} = $rank;
        $parent_taxid_for{$taxon_id} = $parent_taxon_id;
    }

    # create helper Taxonomy object
    my $tax = $class->new( tax_dir => $tax_dir );

    # define remote assembly reports filenames
    # Note: the order is significant (last files dominate over first files)
    my @targets_acc = qw(
        assembly_summary_genbank_historical.txt
        assembly_summary_genbank.txt
        assembly_summary_refseq_historical.txt
        assembly_summary_refseq.txt
    );

    my %name_for;
    my %node_for;
    my %fix_for;

    my $base_acc = 'ftp://ftp.ncbi.nlm.nih.gov/genomes/ASSEMBLY_REPORTS';

    for my $target (@targets_acc) {
        #### $target

        my $url = "$base_acc/$target";
        my $file = file($tax_dir, $target)->stringify;
        #### $file

        ### Downloading: $url
        my $ret_code = getstore($url, $file);
        croak "[BMC] Error: cannot download $url: error $ret_code; aborting!"
            unless $ret_code == 200;

        # parse file for accession numbers and related taxon_ids
        open my $fh, '<', $file;

        LINE:
        while (my $line = <$fh>) {
            chomp $line;

            # skip empty lines and comment lines
            next LINE if $line =~ $EMPTY_LINE
                      || $line =~ $COMMENT_LINE;

            my ($accession, $taxon_id, $species_taxon_id)
                = (split /\t/xms, $line)[0,5,6];

            # update merged taxon_id (mostly from historical assembly files)
            $taxon_id         = $tax->merged_for($taxon_id)
                if $tax->is_merged($taxon_id);
            $species_taxon_id = $tax->merged_for($species_taxon_id)
                if $tax->is_merged($species_taxon_id);

            # skip deleted nodes (again mostly from historical assembly files)
            next LINE if $tax->is_deleted($taxon_id);

            # skip GCF entries with corresponding GCA already available...
            # ... and transform remaining GCF entries into GCA entries
            # Note: versions are considered relevant; only prefix is ignored
            # TODO: check how it goes with GTDB
            # grep 021018745 gca0-names.dmp | cat -n
            #  1	GCA_021018745.1	|	Gloeobacter morelensis	|		|	scientific name
            #  2	GCF_021018745.1	|	Gloeobacter morelensis	|		|	scientific name

            if ($accession =~ $GCAONLY) {
                $accession =~ tr/F/A/;
                next LINE if defined $name_for{$accession};
            }

            # fetch taxonomy and org using taxon_id
            my @taxonomy = $tax->get_taxonomy($taxon_id);
            my $org = $taxonomy[-1];

            # use parent taxon_id if no taxon_id for strain
            if ($species_taxon_id == $taxon_id) {
                $species_taxon_id = $parent_taxid_for{$taxon_id};
                $fix_for{$taxon_id}{name_for} = $org;
                $fix_for{$taxon_id}{node_for} = $species_taxon_id;
            }

            $name_for{$accession} = $org;
            $node_for{$accession} = $species_taxon_id;
        }

        close $fh;
    }

    # write names.dmp
    my $names_gca_file = file($tax_dir, 'gca0-names.dmp');
    open my $names_out, '>', $names_gca_file;

    for my $accession ( keys %name_for ) {
        say {$names_out} join $FS,
            $accession, $name_for{$accession}, q{}, 'scientific name';
    }
    for my $taxon_id  ( keys %fix_for  ) {
        say {$names_out} join $FS,
            $taxon_id, $fix_for{$taxon_id}{name_for}, q{}, 'scientific name';
            $rank_for{$fix_for{$taxon_id}{name_for}} = $rank_for{$taxon_id};
    }

    close $names_out;

    # write nodes.dmp
    my $nodes_gca_file = file($tax_dir, 'gca0-nodes.dmp');
    open my $nodes_out, '>', $nodes_gca_file;

    for my $accession ( keys %node_for ) {
        say {$nodes_out} join $FS, $accession, $node_for{$accession},
            $rank_for{$name_for{$accession}} // 'no rank';
    }
    for my $taxon_id  ( keys %fix_for  ) {
        say {$nodes_out} join $FS, $taxon_id, $fix_for{$taxon_id}{node_for},
            $rank_for{$taxon_id};
    }

    close $nodes_out;

    return;
}


# http://www.ncbi.nlm.nih.gov/news/11-21-2013-strain-id-changes/
#
# Planned change in bacterial strain-level information management
#
# Please be aware that there is an upcoming change (January 2014) in how NCBI
# manages organism strain information. Due to significant increases in the
# volume of strain-specific sequencing, we are changing our management of
# strain information.
#
# Next generation sequencing has already changed the way microbial genomes are
# being used. The scope of microbial sequencing projects has shifted from a
# single isolate representing an organism to multi-isolate and multi-species
# projects representing microbial communities. Consequently, in the first nine
# months of 2013 the sequences of more than 6000 prokaryotic genomes were
# released by INSDC (DDBJ/ENA/GenBank).
#
# NCBI is introducing several changes in prokaryotic genomes and related
# resources such as Assembly, BioProject, BioSample, and Taxonomy that will
# affect your submissions, data downloads, analysis tools, and parsers.
#
# Taxonomy
#
# Assigning strain-level TaxID will be discontinued in January 2014 because
# curation of strain-level TaxIDs will not remain possible under such growth.
# However, the thousands of existing strain-level TaxIDs will remain, and we
# will continue to add informal strain-specific names for genomes from
# specimens that have not yet been identified to the species level, e.g.
# “Rhizobium sp. CCGE 510” and “Micromonas sp. RCC299”. The strain information
# will continue to be collected and displayed.
#
# BioSample
#
# Submitters of genome sequences will be required to register sample meta-data
# in the BioSample database for each organism that they are sequencing. The
# BioSample submission will include the strain information and other metadata,
# such as culture collection and isolation information, as appropriate. The
# BioSample accession will be a link on the GenBank records, and the GenBank
# records themselves will display the strain in the source information.
#
# BioProject
#
# Submitters of genome sequences are already required to register meta-data
# about the research project in the BioProject database. We no longer require
# a one-to-one relationship between a BioProject accession and a genome.
# Instead, a research effort examining multiple strains of a species or
# multiple species of drug-resistant bacteria, for example, could be
# registered as a single BioProject.
#
# Assembly
#
# Each genome assembly is loaded to the Assembly database and assigned an
# Assembly accession. The Assembly accession is specific for a particular
# genome submission.
#
# What defines a genome?
#
# A BioProject ID or accession cannot be used to define a single genome, since
# many may belong to a multi-isolate or multi-species project. Furthermore, a
# TaxID can no longer reliably define an individual genome since unique TaxIDs
# will not be assigned for individual strains and isolates. The collection of
# DNA sequences of an individual sample (isolate) will be represented by a
# BioSample accession and if raw sequence reads are assembled and submitted to
# GenBank they will get a unique Assembly accession. The Assembly accession is
# specific for a particular genome submission. For example, sequence data
# generated from a single sample (with a BioSample accession) could be
# assembled with two different algorithms and so have two sets of GenBank
# accessions, each with its own Assembly accession.
# BioSample accession and each assembled genome has its own Assembly
# accession. This BioProject includes an isolate of Listeria monocytogenes
# (TaxID 1639, strain R2-502) which was registered as BioSample SAMN02203126,
# and its genome is represented in GenBank records CP006595-CP006596, which
# are tracked as a group in the Assembly database under accession
# GCA_000438585.
#
# FTP files
#
# Genome text reports on the FTP site have been modified to include the
# BioSample and Assembly accessions. These two columns were added at the end
# of the tables to minimize problems for existing parsers. Initially, not all
# assemblies will have a BioSample accession because we are still in the
# process of back-filling BioSamples for genomes.
#
# These changes will occur in January 2014. We will be releasing more
# information as the date approaches.

sub _setup_gtdb_taxdir {
    my $class   = shift;
    my $tax_dir = shift;

    # setup local directory
    $tax_dir = dir( glob $tax_dir );
    $tax_dir->mkpath();

    ### Installing GTDB Taxonomy database to: $tax_dir->stringify
    ### Please be patient...

    # setup remote archive access
    my $base = 'https://data.ace.uq.edu.au/public/gtdb/data/releases/latest/';

    # get directory listing of latest GTDB release
    my $listing = get($base)
        or croak "[BMC] Error: cannot download $base: error $!; aborting!";

    croak "[BMC] Error: cannot determine path to GTDB files; aborting!"
        unless $listing;

    # determine filenames from directory listing
    my @targets = (
        grep { m/metadata.*\.gz/xms } $listing =~ m/href="([^"]+?)"/xmsg,
        # Note: did try with Regexp::Common (delimiters) but less handy
        'FILE_DESCRIPTIONS', 'METHODS', 'RELEASE_NOTES', 'VERSION'
    );
    #### @targets

    for my $target (@targets) {
        my $url = "$base/$target";

        ### Downloading: $url
        my $zipfile = file($tax_dir, $target)->stringify;
        my $ret_code = getstore($url, $zipfile);
        croak "[BMC] Error: cannot download $url: error $ret_code; aborting!"
            unless $ret_code == 200;

        if ($target =~ m/metadata/xms) {
            ### Unarchiving: $zipfile
            system("gunzip $zipfile");
            # file($zipfile)->remove;
        }
    }

    # change file names to avoid GTDB version in basenames
    my $new_arcfile = file($tax_dir,  'archaea_metadata.tsv');
    my $new_bacfile = file($tax_dir, 'bacteria_metadata.tsv');
    $new_arcfile->remove if -e $new_arcfile;
    $new_bacfile->remove if -e $new_bacfile;

    my ($arcbase) = fileparse($targets[0], qr{\.[^.]*}xms);
    my ($bacbase) = fileparse($targets[1], qr{\.[^.]*}xms);
    my $old_arcfile = file($tax_dir, $arcbase);
    my $old_bacfile = file($tax_dir, $bacbase);

    $old_arcfile->move_to($new_arcfile);
    $old_bacfile->move_to($new_bacfile);

    # return true on success (only check main files)
    if ( -r $new_arcfile && -r $new_bacfile ) {
        ### Successfully downloaded metadata files!
    }

    else {
        ### Failed installation!
        return 0;
    }

    # concatenate metadata TSV files
    my $prok_file = file($tax_dir, 'prok_metadata.tsv');
    $prok_file->remove if -e $prok_file;
    system("cat $new_arcfile $new_bacfile > $prok_file");

    # create hash from metadata file
    my $table_for = _read_gtdb_metadata($prok_file);

    # hash for rank code
    my %rank_for = map {
       $_ eq 'superkingdom' ? 'd__' : substr($_, 0, 1) . '__' => $_
    } qw (superkingdom phylum class order family genus species);

    # setup taxonomic tree
    my %tree = (
        1 => {
            rank      => 'no rank',
            name      => 'root',
            uniq_name => q{},
            children => {
                2 => {
                    rank => 'no rank',
                    name => 'cellular organisms',
                    children => {},
                },
            },
        }
    );

    # fill up taxonomic tree
    for my $gca ( keys %{$table_for} ) {

        # get GTDB taxonomy
        my $lineage = $table_for->{$gca}{'gtdb_taxonomy'};
        my @taxonomy = split q{;}, $lineage;

        my $tree_ref  = $tree{1}{children}{2}{children};

        # count duplicate taxon in lineage
        my %count_for = count_by { substr( $_, 3, length()-1 ) } @taxonomy;

        while (my $gtdb_taxon = shift @taxonomy) {

            # get taxon rank
            my ($rank_code, $taxon) = ($gtdb_taxon) =~ m/^([a-z]__)(.*)/xms;
            my $rank = $rank_for{$rank_code};

            # create taxid for taxon
            my $taxon_id = $rank_code . lc($taxon =~ tr/A-Za-z0-9//cdr);

            # create taxid entry (if not yet existing)
            unless ( $tree_ref->{$taxon_id} ) {
                $tree_ref->{$taxon_id}{name} = $taxon;
                $tree_ref->{$taxon_id}{rank} = $rank;
            }

            # set a unique name (if duplicate taxon)
            my $uniq_name = $count_for{$taxon} > 1
                ? $taxon . ' <' . lc $rank . '>' : q{};
            # ... and add it in hash
            $tree_ref->{$taxon_id}{uniq_name} = $uniq_name
                if $uniq_name;

            # store GCA|F
            if ($rank eq 'species') {

                # change GCF to GCA and store it
                if ($gca =~ m/^GCF/xms) {
                    my $new_gca = $gca =~ tr/F/A/r;
                    push @{ $tree_ref->{$taxon_id}{gca} }, $new_gca;
                }

                push @{ $tree_ref->{$taxon_id}{gca} }, $gca;
            }

            # setup children entry if lineage not yet exhausted
            if (@taxonomy) {
                $tree_ref->{$taxon_id}{children} //= {};
                $tree_ref = $tree_ref->{$taxon_id}{children}
            }
        }
    }

    # taxid files
    my $name_file = file($tax_dir, 'names.dmp');
    my $node_file = file($tax_dir, 'nodes.dmp');
    open my $name_out, '>', $name_file;
    open my $node_out, '>', $node_file;

    # gca files
    my $gcanamefile = file($tax_dir, 'gca0-names.dmp');
    my $gcanodefile = file($tax_dir, 'gca0-nodes.dmp');
    open my $gcaname_out, '>', $gcanamefile;
    open my $gcanode_out, '>', $gcanodefile;

    # create empty additional dmp files
    file($tax_dir, 'delnodes.dmp')->spew;
    file($tax_dir, 'merged.dmp'  )->spew;

    # write regular dmp files (first recursive call)
    _write_dmp_files( $name_out, $node_out, $gcaname_out, $gcanode_out,
        1, 1, $tree{1} );

    if ( -r $name_file && -r $node_file ) {
        ### Successfully wrote taxid files!
    }

    if ( -r $gcanamefile && -r $gcanodefile ) {
        ### Successfully wrote GCA-based files!
    }

    close $name_out;
    close $node_out;
    close $gcaname_out;
    close $gcanode_out;

    return;
}

sub _read_gtdb_metadata {
    my $infile = shift;

    open my $in, '<', $infile;

    my %table_for;
    my @keys;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        if ($line =~ m/^accession/xms) {
            (undef, @keys) = split /\t/xms, $line;
            next LINE;
        }

        my ($gca, @values) = split /\t/xms, $line;
        $gca =~ s/GB_|RS_//xms;
        $table_for{$gca} = { mesh @keys, @values };
    }

    return \%table_for;
}

sub _write_dmp_files {                      ## no critic (ProhibitManyArgs)
    my ($name_out, $node_out, $gcaname_out, $gcanode_out,
        $taxon_id, $parent, $tree_ref) = @_;

    my $name      = $tree_ref->{name     };
    my $rank      = $tree_ref->{rank     };
    my $uniq_name = $tree_ref->{uniq_name} // q{};
    my $gcas      = $tree_ref->{gca      } // [];

    # write gca files
    if ($gcas) {
        _append2dmp($gcaname_out, $gcanode_out,
            $_, $parent, $name, $rank, $uniq_name)
            for sort @{$gcas};
    }

    # write taxid files
    _append2dmp($name_out, $node_out,
        $taxon_id, $parent, $name, $rank, $uniq_name);

    my $children_for = $tree_ref->{children};
    return unless $children_for;

    $parent = $taxon_id;

    _write_dmp_files( $name_out, $node_out, $gcaname_out, $gcanode_out,
        $_, $parent, $children_for->{$_} )
        for sort keys %{$children_for};

    return;
}

sub _append2dmp {                           ## no critic (ProhibitManyArgs)
    my ($name_out, $node_out,
        $taxon_id, $parent, $name, $rank, $uniq_name) = @_;

    # write names file
    say {$name_out} join "\t",
        $taxon_id , '|',
        $name     , '|',
        $uniq_name, '|',
        'scientific name'
    ;

    # write nodes file
    say {$node_out} join "\t",
        $taxon_id, '|', $parent, '|', $rank,
        ( join "\t", '|', q{} ) x 10;

    return;
}

no Moose::Util::TypeConstraints;

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Taxonomy - NCBI Taxonomy one-stop shop

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 METHODS

=head2 get_taxid_from_seq_id

=head2 get_taxid_from_legacy_seq_id

=head2 get_taxonomy_from_seq_id

=head2 get_taxid_from_taxonomy

=head2 get_taxonomy_with_levels_from_seq_id

=head2 get_taxa_from_taxid

=head2 get_nexus_label_from_seq_id

=head2 get_common_taxonomy_from_seq_ids

=head2 attach_taxonomies_to_terminals

=head2 attach_taxonomies_to_internals

=head2 attach_taxa_to_entities

=head2 gi_mapper

=head2 tab_mapper

=head2 tax_mapper

=head2 tax_filter

=head2 tax_criterion

=head2 tax_category

=head2 tax_classifier

=head2 tax_labeler_from_systematic_frame

=head2 tax_labeler_from_list

=head2 load_color_scheme

=head2 eq_tax

=head2 setup_taxdir

=head1 I/O METHODS

=head2 new_from_cache

=head2 update_cache

=head1 ALIASES

=head2 fetch_lineage

=head2 compute_lca

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Loic MEUNIER Mick VAN VLIERBERGHE

=over 4

=item *

Loic MEUNIER <loic.meunier@doct.uliege.be>

=item *

Mick VAN VLIERBERGHE <mvanvlierberghe@doct.uliege.be>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

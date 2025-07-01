package Bio::MUST::Core::Ali;
# ABSTRACT: Multiple sequence alignment
# CONTRIBUTOR: Catherine COLSON <ccolson@doct.uliege.be>
# CONTRIBUTOR: Arnaud DI FRANCO <arnaud.difranco@gmail.com>
$Bio::MUST::Core::Ali::VERSION = '0.251810';
use Moose;
use namespace::autoclean;

use autodie;
use feature qw(say);

# use Smart::Comments;

use Carp;
use File::Temp;
use List::AllUtils qw(uniq indexes sum0);
use Path::Class qw(file);
use POSIX qw(ceil floor);
use Statistics::Descriptive;
use Tie::IxHash;

use Bio::MUST::Core::Types;
use Bio::MUST::Core::Constants qw(:ncbi :gaps :files);

use aliased 'Bio::MUST::Core::Seq';
use aliased 'Bio::MUST::Core::SeqId';
use aliased 'Bio::MUST::Core::SeqMask';

# TODO: add information about methods available in Ali-like objects

# ATTRIBUTES


has 'seqs' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Bio::MUST::Core::Seq]',
    default  => sub { [] },
    writer   => '_set_seqs',
    handles  => {
          add_seq  => 'push',
          get_seq  => 'get',
          set_seq  => 'set',
       delete_seq  => 'delete',
       insert_seq  => 'insert',
        count_seqs => 'count',
          all_seqs => 'elements',
        first_seq  => 'first',
       filter_seqs => 'grep',
    },
);


has 'file' => (
    is       => 'ro',
    isa      => 'Bio::MUST::Core::Types::File',
    default  => 'untitled.ali',
    coerce   => 1,
    handles  => {
        filename => 'stringify',
    },
);


has 'guessing' => (
    traits   => ['Bool'],
    is       => 'ro',
    isa      => 'Bool',
    default  => 1,
    handles  => {
        dont_guess => 'unset',
        guess      => 'set',
    },
);


with 'Bio::MUST::Core::Roles::Commentable',
     'Bio::MUST::Core::Roles::Listable';
with 'Bio::MUST::Core::Roles::Aliable';     ## no critic (ProhibitMultipleWiths)

# CONSTRUCTORS



sub clone {
    my $self = shift;

    return $self->new(
        comments => [ $self->all_comments ],
        seqs     => [ map { $_->clone } $self->all_seqs ],
        file     => file( $self->filename ),
        guessing => $self->guessing,
    );
}

# ACCESSORS


sub get_seq_with_id {
    my $self = shift;
    my $id   = shift;

    my $seq = $self->first_seq( sub { $_->full_id eq $id } );
    carp "[BMC] Warning: cannot find seq with id: $id; returning undef!"
        unless $seq;

    return $seq;
}


sub all_new_seqs {
    return shift->filter_seqs( sub {     $_->is_new } );
}


sub all_but_new_seqs {
    return shift->filter_seqs( sub { not $_->is_new } );
}


sub all_seq_ids {
    my $self = shift;
    return map { $_->seq_id } $self->all_seqs;
}

# PROPERTIES


sub has_uniq_ids {
    my $self = shift;

    my @ids = map { $_->full_id } $self->all_seq_ids;
    return 1 if $self->count_seqs == uniq @ids;
    return 0;
}


sub is_protein {
    my $self = shift;
    return 1 if List::AllUtils::any { $_->is_protein } $self->all_seqs;
    return 0;
}


sub is_aligned {
    my $self = shift;
    return 0 if not $self->guessing;
    return 1 if List::AllUtils::any { $_->is_aligned } $self->all_seqs;
    return 0;
}


sub width {
    my $self = shift;
    $self->uniformize if $self->is_aligned;     # pad seqs for robustness
    return $self->_max_seq_len;
}

sub _max_seq_len {
    my $self = shift;
    my @lengths = map { $_->seq_len } $self->all_seqs;
    return (List::AllUtils::max @lengths) // 0;     # to avoid warnings
}


sub seq_len_stats {
    my $self = shift;

    my @lengths = map { $_->nomiss_seq_len } $self->all_seqs;
    my $stat = Statistics::Descriptive::Full->new;
       $stat->add_data( \@lengths );
    my @quantiles = map { $stat->quantile($_) } 0..4;

    return @quantiles;
}


sub perc_miss {
    my $self = shift;

    my $n = sum0 map { $_->nomiss_seq_len } $self->all_seqs;
    return 0.0 unless $n;

    my $total = $self->width * $self->count_seqs;
    return 100.0 * ($total - $n) / $total;
}

# MUTATORS


sub uc_seqs {
    my $self = shift;

    $_->uc for $self->all_seqs;
    return $self;
}


sub recode_seqs {                           ## no critic (RequireArgUnpacking)
    my $self = shift;

    $_->recode(@_) for $self->all_seqs;
    return $self;
}


sub degap_seqs {
    my $self = shift;

    $_->degap for $self->all_seqs;
    return $self;
}


sub spacify_seqs {
    my $self = shift;

    $_->spacify for $self->all_seqs;
    return $self;
}


sub gapify_seqs {                           ## no critic (RequireArgUnpacking)
    my $self = shift;
    $_->gapify(@_) for $self->all_seqs;
    return $self;
}


sub trim_seqs {
    my $self = shift;

    $_->trim for $self->all_seqs;
    return $self;
}


sub pad_seqs {
    my $self = shift;

    my $bound = $self->_max_seq_len;
    $_->pad_to($bound) for $self->all_seqs;
    return $self;
}


sub uniformize {
    my $self = shift;

    # TODO: profile code (triggers?) to avoid useless multiple calls

    $self->spacify_seqs;
    $self->trim_seqs;
    $self->pad_seqs;

    return $self;
}


sub clear_new_tags {
    my $self = shift;

    $_->clear_new_tag for $self->all_seqs;
    return $self;
}


sub shorten_ids {                           ## no critic (RequireArgUnpacking)
    return shift->_change_ids_(1, @_);
}


sub restore_ids {                           ## no critic (RequireArgUnpacking)
    return shift->_change_ids_(0, @_);
}

sub _change_ids_ {
    my $self   = shift;
    my $abbr   = shift;
    my $mapper = shift;

    for my $seq ($self->all_seqs) {
        my $new_id = $abbr ? $mapper->abbr_id_for( $seq->full_id )
                           : $mapper->long_id_for( $seq->full_id );
        $seq->set_seq_id($new_id) if $new_id;
    }                       # Note: leave id alone if not found

    return $self;
}


sub apply_list {
    my $self = shift;
    my $list = shift;

    # loop through seqs from bottom to top
    # ... and delete seq from Ali if not listed in list
    my $seq_n = $self->count_seqs;

    for (my $i = $seq_n-1; $i >= 0; $i--) {
        $self->delete_seq($i)
            unless $list->is_listed( $self->get_seq($i)->full_id );
    }

    return $self;
}


sub _premask_check {
    my $self = shift;
    my $mask = shift;

    # warn of unaligned Ali
    carp '[BMC] Note: Ali does not look aligned!'
        . ' This might not be an issue if seqs are ultra-conserved!'
        unless $self->is_aligned;
    $self->uniformize;

    # warn of empty SeqMask
    carp '[BMC] Note: applying this mask will result in a zero-width Ali!'
        unless List::AllUtils::any { $_ } $mask->all_states;

    # check that SeqMask is compatible with Ali
    # potential bugs could come from constant sites etc
    my $a_width = $self->width;
    my $m_width = $mask->mask_len;
    carp "[BMC] Note: Ali width does not match mask len: $a_width vs. $m_width!"
        . ' This might not be an issue if the mask results from blocks.'
        unless $a_width == $m_width;

    return;                 # return values of before subs are ignored
}

before 'apply_mask' => \&_premask_check;

sub apply_mask {
    my $self = shift;
    my $mask = shift;

    # select sites for each seq using a precomputed array slice
    my @indexes = indexes { $_ } $mask->all_states;
    $_->_set_seq( join q{}, ( $_->all_states )[@indexes] )
        for $self->all_seqs;

    return $self;
}


sub idealize {                              ## no critic (RequireArgUnpacking)
    my $self = shift;
    return $self->apply_mask( SeqMask->ideal_mask($self, @_) );
}

# MISC METHODS


# TODO: introduce miss_regex (without gaps?)
sub gapmiss_regex {
    return shift->is_protein ? $GAPPROTMISS : $GAPDNAMISS;
}


sub map_coords {
    my $self      = shift;
    my $id        = shift;
    my $coords_in = shift;

    my $seq = $self->get_seq_with_id($id);
    my @states = $seq->all_states;

    my $count = 0;
    my @index;
    for my $state (@states) {
        $count++ if $state !~ $GAP;
        push @index, $count;
    }

    my @coords_out = map { $index[$_-1] } @{$coords_in};

    return \@coords_out;
}

# ALIASES


sub height {
    return shift->count_seqs;
}

# I/O METHODS


sub load {
    my $class  = shift;
    my $infile = shift;

    open my $in, '<', $infile;

    my $ali = $class->new( file => $infile );
    my $seq_id;
    my $seq;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines and process comments
        next LINE if $line =~ $EMPTY_LINE
                  || $ali->is_comment($line);

        # at each '>' char...
        my ($defline) = $line =~ $DEF_LINE;
        if ($defline) {

            # add current seq to ali (if any)
            if ($seq) {
                my $new_seq = Seq->new( seq_id => $seq_id, seq => $seq );
                $ali->add_seq($new_seq);
                $seq = q{};
            }

            $seq_id = $defline;
            next LINE;
        }

        # elongate current seq (seqs can be broken on several lines)
        $seq .= $line;
    }

    # add last seq to ali (if any)
    if ($seq) {
        my $new_seq = Seq->new( seq_id => $seq_id, seq => $seq );
        $ali->add_seq($new_seq);
    }

    return $ali;
}


before qr{\Astore}xms => sub {
    my $self = shift;

    # perform pre-storage duties
    carp '[BMC] Warning: non unique seq ids!' unless $self->has_uniq_ids;
    $self->uniformize if $self->is_aligned;

    return;
};


sub store {                                 ## no critic (RequireArgUnpacking)
    my $self = shift;
    my $outfile = shift;

    # automatically redirect to store_fasta for non-Ali outfile names
    return $self->store_fasta($outfile, @_)     # note the currying
        unless $outfile =~ $ALI_SUFFIX;

    open my $out, '>', $outfile;

    print {$out} $self->header;
    for my $seq ($self->all_seqs) {
        say {$out} '>' . $seq->full_id;
        say {$out} $seq->seq;
    }

    close $out;

    return;
}


sub store_fasta {
    my $self    = shift;
    my $outfile = shift;
    my $args    = shift // {};          # HashRef (should not be empty...)

    my $degap = $args->{degap}  //  0;
    my $clean = $args->{clean}  //  0;
    my $gap   = $args->{gapify} // 'X';
    my $chunk = $args->{chunk}  // 60;
    my $nowrap = $chunk < 0 ? 1 : 0;
    my $is_aligned = $self->is_aligned;

    open my $out, '>', $outfile;

    for my $seq ($self->all_seqs) {
        say {$out} '>' . $seq->foreign_id;

        # optionally clean and/or degap seq
        $seq = $seq->clone  if $clean || $degap;    # clone seq only if needed
        $seq->gapify($gap)  if $clean;
        $seq->degap         if $degap;

        my $width = $seq->seq_len;
        $chunk = $width     if $nowrap;             # optionally disable wrap

        my $str = $seq->wrapped_str($chunk);
        $str =~ s{$GAP}{-}xmsg if $is_aligned;      # restore '-' when aligned
        print {$out} $str;
    }

    close $out;

    return;
}


sub temp_fasta {
    my $self = shift;
    my $args = shift // {};             # HashRef (should not be empty...)

    # abbreviate ids (possibly using a custom prefix, offset, or IdMapper)
    my $mapper = $args->{mapper} // $self->std_mapper($args);
    $self->shorten_ids($mapper);

    # write temporary .fasta file using standard abbr_ids
    # ...and restore long_ids afterwards
    my $out = File::Temp->new(UNLINK => 0, EXLOCK => 0, SUFFIX => '.fasta');
    $self->store_fasta($out->filename, $args);
    $self->restore_ids($mapper);
    ### filename: $out->filename

    return wantarray ? ($out->filename, $mapper) : $out->filename;
}


# TODO: add an option to remove trailing '_' in ids?

sub load_phylip {
    my $class  = shift;
    my $infile = shift;

    open my $in, '<', $infile;

    my $ali = $class->new( file => $infile );
    my $seq_n;
    my $site_n;
    my $n = 0;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines
        next LINE if $line =~ $EMPTY_LINE;

        # get matrix dimensions
        if ($line =~ $DIM_LINE) {
            ($seq_n, $site_n) = ($1, $2);
            next LINE;
        }

        # process regular line (identifier is optional)
        my ($seq_id, $seq) = $line =~ $PHY_LINE;

        # should never happen...
        croak "[BMC] Error: unable to parse PHYLIP file at line $.; aborting!"
            unless $seq;

        # delete optional spaces
        $seq =~ tr/ //d;

        # process first seq block
        if ($ali->count_seqs < $seq_n) {

            # seq_id are mandatory in first block
            croak "[BMC] Error: missing id in PHILIP file at line $.; aborting!"
                unless $seq_id;

            # store first seq chunk along with seq_id
            my $new_seq = Seq->new( seq_id => $seq_id, seq => $seq );
            $ali->add_seq($new_seq);
        }

        # process remaining seq blocks
        else {
            my $curr_seq = $ali->get_seq($n);

            # elongate current with partial seq chunk mistaken as seq_id
            if ($seq_id && $seq_id ne $curr_seq->full_id) {
                $curr_seq->append_seq($seq_id);
            }

            # elongate current seq with new seq chunk
            $curr_seq->append_seq($seq);
        }

        # prepare reading of next seq or next block
        $n = 0 if ++$n == $seq_n;
    }

    my $width = $ali->width;
    croak "[BMC] Error: unexpected site number in PHYLIP file: $width;"
        . ' aborting!' if $width != $site_n;

    return $ali;
}

# PHYLIP: http://evolution.genetics.washington.edu/phylip/doc/main.html
# The information for each species follows, starting with a ten-character
# species name (which can include blanks and some punctuation marks), and
# continuing with the characters for that species. The name should be on the
# same line as the first character of the data for that species. (...) The
# name should be ten characters in length, filled out to the full ten
# characters by blanks if shorter. Any printable ASCII/ISO character is
# allowed in the name, except for parentheses ("(" and ")"), square brackets
# ("[" and "]"), colon (":"), semicolon (";") and comma (","). (...) Note that
# in these sequences we have a blank every ten sites to make them easier to
# read: any such blanks are allowed. The blank line which separates the two
# groups of lines (the ones containing sites 1-20 and ones containing sites
# 21-39) may or may not be present.

# PhyML: http://www.atgc-montpellier.fr/phyml/usersguide.php?type=command
# The input sequence file is a standard PHYLIP file of aligned DNA or
# amino-acids sequences. (...) The maximum number of characters in species
# name MUST not exceed 100. Blanks and the symbols "(),:" are not allowed
# within sequence names because the Newick tree format makes special use of
# these symbols. However, blanks (one or more) MUST appear at the end of each
# species name.

# TREE-FINDER: http://www.treefinder.de/tf-march2011-manual.pdf
# A sequence name may consist of 1 to 10 alphanumeric characters, dashes "-",
# dots ".", underscores "_", or some of "/", "?", "*", "+". No space is
# allowed inside the names. The first name character must be a letter or an
# underscore. A sequence fragment may start behind position 10 after a
# sequence name, or anywhere in a line without a name.

# TREE-PUZZLE [data/globin.a]
#   7 128
# HBB_HUMAN      HLTPEEKSAV TALWGKVNVD EVGGEALGRL LVVYPWTQRF FESFDLSMGN
# HBB_HORSE      QLSGEEKAAV LALWDKVNEE EVGGEALGRL LVVYPWTQRF FDSFDLSMGN
# HBA_HUMAN      VLSPADKTNV KAAWGKVGAG EYGAEALERM FLSFPTTKTY FPHFDLSHGS
# HBA_HORSE      VLSAADKTNV KAAWSKVGAG EYGAEALERM FLGFPTTKTY FPHFDLSHGS
# MYG_PHYCA      VLSEGEWQLV LHVWAKVEVA GHGQDILIRL FKSHPETLEK FDRFHLKKAS
# GLB5_PETMA     PLSAAEKTKI RSAWAPVYYE TSGVDILVKF FTSTPAAQEF FPKFGLTKKS
# LGB2_LUPLU     ALTESQAALV KSSWEEFNIP KHTHRFFILV LEIAPAAKDL FSFLGTSQNN

# RAXML: http://sco.h-its.org/exelixis/oldPage/RAxML-Manual.7.0.4.pdf
# The input alignment format of RAxML is relaxed interleaved or sequential
# PHYLIP. "Relaxed" means that sequence names can be of variable length
# between 1 up to 256 characters. (...) Prohibited Character(s) in taxon names
# taxon names that contain any form of whitespace character, like blanks,
# tabulators, and carriage returns, as well as one of the following prohibited
# characters: :,();[].

# PHYLOBAYES: http://megasun.bch.umontreal.ca/People/lartillot/www/phylobayes3.3e.pdf
# Taxon names may contain more than 10 characters. Avoid special characters
# such as ';' or ')', which will create problems when parsing trees. The best
# is to only use letters, digits and '_'. Sequences can be interrupted by
# space and tab, but not by return characters. Be sure that the lengths of the
# sequences are all the same, and identical to the lengths indicated in the
# header. Sequences can be interleaved, in which case the taxon names may or
# may not be repeated in each block.


sub store_phylip {
    my $self    = shift;
    my $outfile = shift;
    my $args    = shift // {};          # HashRef (should not be empty...)

    my $short = $args->{short} // 1;
    my $clean = $args->{clean} // 0;
    my $chunk = $args->{chunk} // 60;

    open my $out, '>', $outfile;

    # print data matrix dimensions
    my $height = $self->count_seqs;
    my $width  = $self->width;
    say {$out} $height . q{ } . $width;

    # setup id format (this will also affect block-like structure)
    my $format = $short ? "%-10.10s %s\n" : "%s %s\n";
    my $method = $short ? 'full_id'       : 'foreign_id';
    my $sep    = $short ? q{ }            : q{};

    # optionally disable wrapping
    $chunk = $width if $chunk < 0;

    # optionally clean seq
    my @seqs = $self->all_seqs;
       @seqs = map { $_->clone->gapify('X') } @seqs if $clean;

    # output Ali in sequential or interleaved format
    for (my $site = 0; $site < $width; $site += $chunk) {

        # leave empty line between chunks (but not after last chunk)
        print {$out} "\n" if $site;

        for my $seq (@seqs) {

            # print 10-chars ids only once
            # Note: full_ids are only truncated (use IdMapper for more)
            my $id = $site == 0 ? $seq->$method : q{};

            # print seq chunks in 10-state blocks
            # Note: We insert a space in the 11th column to ensure that more
            # software packages can read the written files. PHYLIP itself will
            # ignore this spurious space in the 'sequences'.
            ( my $str = $seq->edit_seq($site, $chunk) ) =~ s{$GAP}{-}xmsg;
            printf {$out} $format, $id, join $sep,
                map { substr($str, $_*10, 10) } 0..ceil(length($str)/10)-1;
        }
    }

    close $out;

    return;
}


sub load_stockholm {
    my $class  = shift;
    my $infile = shift;

    open my $in, '<', $infile;

    my $ali = $class->new( file => $infile );
    tie my %seq_for, 'Tie::IxHash';

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # process GF comments
        next LINE if $ali->is_comment($line, $STK_COMMENT);

        # skip empty lines and other comment lines
        next LINE if $line =~ $EMPTY_LINE
                  || $line =~ $COMMENT_LINE;
        last LINE if $line =~ $END_LINE;

        # parse stockholm seq
        my ($seq_id, $seq) = $line =~ $STK_SEQ;

        # replace dots and gaps by stars
        $seq =~ s/[\.\-]/*/xmsg;

        # elongate seq
        $seq_for{$seq_id} .= $seq;
    }

    # populate Ali object
    while (my ($seq_id, $seq) = each %seq_for) {
        my $new_seq = Seq->new( seq_id => $seq_id, seq => $seq );
        $ali->add_seq($new_seq);
    }

    return $ali;
}


# <TSeq>
#  <TSeq_seqtype value="nucleotide"/>
#  <TSeq_gi>160476623</TSeq_gi>
#  <TSeq_accver>EY249574.1</TSeq_accver>
#  <TSeq_sid>gnl|dbEST|50783737</TSeq_sid>
#  <TSeq_taxid>5061</TSeq_taxid>
#  <TSeq_orgname>Aspergillus niger</TSeq_orgname>
#  <TSeq_defline>CATY7117.fwd CATY Aspergillus niger fungal ...</TSeq_defline>
#  <TSeq_length>906</TSeq_length>
#  <TSeq_sequence>ACGT...</TSeq_sequence>
# </TSeq>

sub load_tinyseq {
    my $class  = shift;
    my $infile = shift;
    my $args   = shift // {};           # HashRef (should not be empty...)

    my $kps = $args->{keep_strain} // 0;

    open my $in, '<', $infile;

    my $ali = $class->new( file => $infile );
    my ($acc, $tax, $org, $seq);

    # Note: crude parser derived from old tseq2ali.pl
    while (my $line = <$in>) {
        chomp $line;

        # capture attributes
        if      ($line =~ m{<TSeq_accver>      (.*?) </TSeq_accver>  }xms) {
            $acc = $1;
        } elsif ($line =~ m{<TSeq_taxid> ($NCBIPKEY) </TSeq_taxid>   }xms) {
            $tax = $1;
        } elsif ($line =~ m{<TSeq_orgname>  (.*?)    </TSeq_orgname> }xms) {
            $org = $1;
        } elsif ($line =~ m{<TSeq_sequence> (.*?)    </TSeq_sequence>}xms) {
            $seq = $1;
        }

        # process current seq (if any)
        if ($seq) {

            # build full_id from NCBI org
            my $seq_id = SeqId->new_with(
                org         => $org,
                taxon_id    => $tax,
                accession   => $acc,
                keep_strain => $kps,
            );

            # add current seq to ali
            my $new_seq = Seq->new( seq_id => $seq_id, seq => $seq );
            $ali->add_seq($new_seq);

            # clear attributes for next seq
            ($acc, $tax, $org, $seq) = () x 4;
        }
    }

    return $ali;
}


sub instant_store {
    my $class   = shift;
    my $outfile = shift;
    my $args    = shift // {};          # HashRef (should not be empty...)

    my $infile  = $args->{infile};
    croak '[BMC] Error: no infile specified for instant_store; aborting!'
        unless $infile;

    my $coderef = $args->{coderef};
    croak '[BMC] Error: no coderef specified for instant_store; aborting!'
        unless $coderef;

    open my $in,  '<', $infile;
    open my $out, '>', $outfile;

    my $seq_id;
    my $seq;

    LINE:
    while (my $line = <$in>) {
        chomp $line;

        # skip empty lines and process comments
        next LINE if $line =~ $EMPTY_LINE
                  || $line =~ $COMMENT_LINE;

        # at each '>' char...
        my ($defline) = $line =~ $DEF_LINE;
        if ($defline) {

            # process current seq (if any)
            if ($seq) {
                my $new_seq = Seq->new( seq_id => $seq_id, seq => $seq );
                print {$out} $coderef->($new_seq);
                $seq = q{};
            }

            $seq_id = $defline;
            next LINE;
        }

        # elongate current seq (seqs can be broken on several lines)
        $seq .= $line;
    }

    # process last seq (if any)
    if ($seq) {
        my $new_seq = Seq->new( seq_id => $seq_id, seq => $seq );
        print {$out} $coderef->($new_seq);
    }

    close $out;

    return;
}


sub instant_count {
    my $class  = shift;
    my $infile = shift;

    my $seq_n = 0;

    open my $in, '<', $infile;
    while (<$in>) { $seq_n++ if m/^>/xms }

    return $seq_n;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Bio::MUST::Core::Ali - Multiple sequence alignment

=head1 VERSION

version 0.251810

=head1 SYNOPSIS

    #!/usr/bin/env perl

    use Modern::Perl '2011';
    # same as:
    # use strict;
    # use warnings;
    # use feature qw(say);

    use Bio::MUST::Core;
    use aliased 'Bio::MUST::Core::Ali';

    # read Ali form disk
    my $ali = Ali->load('example.ali');

    # get some properties
    say 'height:  ' . $ali->height;         # number of seqs
    say 'width:   ' . $ali->width;          # number of sites
    say '% miss:  ' . $ali->perc_miss;      # fraction of missing chars (%)
    say 'seqs are ' . $ali->is_protein ? 'prot' : 'nucl';

    # turn seqs to uppercase
    $ali->uc_seqs;

    # filter out seqs with no species associated
    my @seqs = $ali->filter_seqs( sub { not $_->is_genus_only } );
    use aliased 'Bio::MUST::Core::IdList';
    my $list = IdList->new( ids => \@seqs );
    $ali->apply_list($list);

    # alternatively:
    # $ali = Ali->new( seqs => \@seqs );

    # filter out gap-rich sites
    $ali->idealize(0.2);                    # min 20% non-gaps per site

    # filter out non-informative sites
    use aliased 'Bio::MUST::Core::SeqMask';
    my $mask = SeqMask->parsimony_mask($ali);
    $ali->apply_mask($mask);

    # write down reduced Ali to disk
    $ali->store('example-uc-genus-sp-20.ali');
    $ali->store_fasta('example-uc-genus-sp-20.fasta');

    # see below for additional methods
    # ...

=head1 DESCRIPTION

This module implements the multiple sequence alignment (MSA) class and its
methods. An Ali is modeled as an array of L<Bio::MUST::Core::Seq> objects.
Consequently, sequence ids do not absolutely need to be unique for it to
work (though id uniqueness helps a lot for sequence access and filtering).

An Ali knows whether it contains nucleotide or protein sequences, whether
those are aligned or not, as well as its Seq count and exact width. All
these properties are introspected on the fly, which means that, while they
can be expensive to compute, they are always accurate.

This is important because an Ali provides methods for inserting, deleting
and editing its Seq objects. Further, it does its best to maintain a semantic
distinction between true gap states (encoded as '*') and missing regions of
undetermined length (encoded as pure whitespace, for example at the end of a
short sequence).

It also has methods for mapping its sequence ids (for example, before export
to the PHYLIP format), as well as methods to selectively retain sequences
and sites based on L<Bio::MUST::Core::IdList> and
L<Bio::MUST::Core::SeqMask> objects. For example, the C<idealize> method
discards shared gaps and optionally removes gap-rich sites only due to a
tiny number of sequences.

Finally, an Ali can be stored in MUST pseudo-FASTA format (which handles
meaningful whitespace and allows comment lines in the header) or be
imported/exported from/to several popular MSA formats, such as plain FASTA,
STOCKHOLM and PHYLIP.

=head1 ATTRIBUTES

=head2 seqs

ArrayRef of L<Bio::MUST::Core::Seq> objects (optional)

Most of the accessor methods described below are implemented by delegation
to this public attribute using L<Moose::Meta::Attribute::Native/Moose native
delegation>. Their documentation thus heavily borrows from the corresponding
help pages.

=head2 file

L<Path::Class::File> object (optional)

This optional attribute is initialized by class methods that C<load> an Ali
from disk. It is meant to improve the introspection capabilities of the Ali.
For now, this attribute is not used by the C<store> methods, though it might
provide them with a default value in the future.

=head2 guessing

Boolean (optional)

By default, an Ali object tries to guess whether it is aligned or not by
looking for gap-like characters in any of its Seq objects (see
L<Bio::MUST::Core::Seq> for the exact test performed on each sequence).

When this smart behavior causes issues, one can disable it by unsetting this
boolean attribute (see C<dont_guess> and C<guess> accessor methods).

=head2 comments

ArrayRef of strings (optional)

An Ali object is commentable, which means that it supports all the methods
pertaining to comment lines described in
L<Bio::MUST::Core::Roles::Commentable> (such as C<header>).

=head1 CONSTRUCTORS

=head2 new

Default constructor (class method) returning a new Ali.

    use aliased 'Bio::MUST::Core::Ali';
    my $ali1 = Ali->new();
    my @seqs = $ali->all_seqs;
    my $ali2 = Ali->new( seqs => \@seqs );

This method accepts four optional arguments (see ATTRIBUTES above): C<seqs>,
C<file>, C<guessing> and C<comments>.

=head2 clone

Creates a deep copy (a clone) of the Ali. Returns the copy.

    use aliased 'Bio::MUST::Core::Ali';
    my $ali = Ali->load('input.ali');
    my $ali_copy = $ali->clone;
    # you can now mess with $ali_copy without affecting $ali

This method does not accept any arguments.

=head1 ACCESSORS

=head2 add_seq

Adds one (or more) new sequence(s) at the end of the Ali. Returns the new
number of sequences of the Ali.

    use aliased 'Bio::MUST::Core::Seq';
    my $new_seq = Seq->new( seq_id => 'seq1', seq => 'ACGT' );
    $ali->add_seq($new_seq);

This method accepts any number of arguments.

=head2 get_seq

Returns a sequence of the Ali by its index. You can also use negative index
numbers, just as with Perl's core array handling. If the specified sequence
does not exist, this method will return C<undef>.

    my $seq = $ali->get_seq($index);
    croak "Seq $index not found in Ali!" unless defined $seq;

This method accepts just one argument (and not an array slice).

=head2 get_seq_with_id

Returns a sequence of the Ali by its id. If the specified id is not unique,
only the first matching sequence will be returned, whereas if no sequence
exists for the specified id, this method will return C<undef>.

    my $id = 'Pyrus malus_3750@658052655';
    my $seq = $ali->get_seq_with_id($id);
    croak "Seq $id not found in Ali!" unless defined $seq;

This method accepts just one argument.

=head2 set_seq

Given an index and a sequence, sets the specified Ali element to the
sequence. This method returns the new sequence at C<$index>.

    use aliased 'Bio::MUST::Core::Seq';
    my $new_seq = Seq->new( seq_id => 'seq1', seq => 'ACGT' );
    $ali->set_seq($index, $new_seq);

This method requires two arguments.

=head2 delete_seq

Removes the sequence at the given index from the Ali. This method returns
the deleted sequence. If the specified sequence does not exist, it will
return C<undef> instead.

    $ali->delete_seq($index);

This method requires one argument.

=head2 insert_seq

Inserts a new sequence into the Ali at the given index. This method returns
the new sequence at C<$index>.

    use aliased 'Bio::MUST::Core::Seq';
    my $new_seq = Seq->new( seq_id => 'seq1', seq => 'ACGT' );
    $ali->insert_seq($index, $new_seq);

This method requires two arguments.

=head2 all_seqs

Returns all the sequences of the Ali (not an array reference).

    my @seqs = $ali->all_seqs;

This method does not accept any arguments.

=head2 first_seq

Returns the first sequence of the Ali matching a given criterion, just like
L<List::Util>'s C<first> function. This method requires a subroutine
implementing the matching logic.

    # emulate get_seq_with_id method
    my $id2find = 'seq13';
    my $seq = $ali->first_seq( sub { $_->full_id eq $id2find } );

This method requires a single argument.

=head2 filter_seqs

Returns every sequence of the Ali matching a given criterion, just like
Perl's core C<grep> function. This method requires a subroutine implementing
the matching logic.

    # keep only long sequences (ignoring gaps and missing states)
    my @long_seqs = $ali->filter_seqs( sub { $_->nomiss_seq_len > 500 } );

This method requires a single argument.

=head2 all_new_seqs

Returns all the sequences of the Ali tagged as #NEW# (not an array reference).

    my @new_seqs = $ali->all_new_seqs;

This method does not accept any arguments.

=head2 all_but_new_seqs

Returns all the sequences of the Ali except those tagged as #NEW# (not an array
reference).

    my @preexisting_seqs = $ali->all_but_new_seqs;

This method does not accept any arguments.

=head2 all_seq_ids

Returns all the sequence ids (L<Bio::MUST::Core::SeqId> objects) of the Ali
(not an array reference). This is only a convenience method.

    use Test::Deeply;
    my @ids1 = $ali->all_seq_ids;
    my @ids2 = map { $_->seq_id } $ali->all_seqs;
    is_deeply \@ids1, \@ids2, 'should be true';
    my @orgs = map { $_->org } @ids1;

This method does not accept any arguments.

=head2 filename

Returns the stringified filename of the Ali.

This method does not accept any arguments.

=head2 guess

Turn on the smart detection of gaps (see C<guessing> attribute above).

This method does not accept any arguments.

=head2 dont_guess

Turn off the smart detection of gaps (see C<guessing> attribute above).

    use aliased 'Bio::MUST::Core::Ali';
    my $ali = Ali->load('ensembl.fasta');
    $ali->dont_guess;

This method does not accept any arguments.

=head1 PROPERTIES

=head2 has_uniq_ids

Returns true if all the sequence ids are unique.

    carp 'Warning: duplicate sequence ids!' unless $ali->has_uniq_ids;

This method does not accept any arguments.

=head2 is_protein

Returns true if any sequence of the Ali looks like a protein. See
L<Bio::MUST::Core::Seq> for the exact test performed on each sequence.

    say 'Your file includes nucleotide sequences' unless $ali->is_protein;

This method does not accept any arguments.

=head2 is_aligned

Returns true if any sequence of the Ali appears to be aligned. See
L<Bio::MUST::Core::Seq> for the exact test performed on each sequence.

If the boolean attribute guessing is not set, always returns false.

    carp 'Warning: file does not look aligned!' unless $ali->is_aligned;

This method does not accept any arguments.

=head2 count_seqs

Returns the number of sequences of the Ali. The alias method C<height> is
provided for convenience.

    my $height = $ali->count_seqs;

This method does not accept any arguments.

=head2 width

Returns the width of the Ali (in characters). If the Ali is not aligned,
returns the length of the longest sequence instead.

To avoid potential bugs due to caching, this method dynamically computes the
Ali width at each call. Moreover, the Ali is always uniformized (see below)
beforehands to ensure accurate width value. Therefore, this method is
expensive and should not be called repeatedly (e.g., in a loop condition).

    # you'd better looping through sites like this...
    my $width = $ali->width;
    for my $site (0..$width-1) {
        ...
    }

This method does not accept any arguments.

=head2 seq_len_stats

Returns a list of 5 values summarizing the Ali seq lengths (ignoring gaps).
The values are the following: Q0 (min), Q1, Q2 (median), Q3, and Q4 (max).

This method does not accept any arguments.

=head2 perc_miss

Returns the percentage of missing (and gap-like) character states in the Ali.

As this method internally calls C<Ali::width>, the remarks above also apply.

    my $miss_level = $ali->perc_miss;

This method does not accept any arguments.

=head1 MUTATORS

=head2 uc_seqs

Turn all the sequences of the Ali to uppercase and returns it.

This method does not accept any arguments.

=head2 recode_seqs

Recode all the sequences of the Ali and returns it.

    use aliased 'Bio::MUST::Core::Ali';
    my $ali = Ali->load('biased.ali');

    # set up RY recoding for suppressing codon bias
    my %base_for = (
        A => 'A',   G => 'A',       # purines
        C => 'C',   T => 'C',       # pyrimidines
    );

    my $ali_rec = $ali->recode_seqs( \%base_for );
    $ali_rec->store('biased_ry.ali');

This method requires one argument.

=head2 degap_seqs

Remove the gaps in all the sequences of the Ali and returns it.

This method does not accept any arguments.

=head2 spacify_seqs

Spacifies all the sequences of the Ali and returns it. See the corresponding
method in L<Bio::MUST::Core::Seq> for the exact effect of this gap-cleaning
operation.

This method does not accept any arguments.

=head2 gapify_seqs

Gapifies all the sequences of the Ali and returns it. See the corresponding
method in L<Bio::MUST::Core::Seq> for the exact effect of this gap-cleaning
operation.

This method accepts an optional argument.

=head2 trim_seqs

Trims all the sequences of the Ali and returns it. See the corresponding
method in L<Bio::MUST::Core::Seq> for the exact effect of this gap-cleaning
operation.

This method does not accept any arguments.

=head2 pad_seqs

Pads all the sequences of the Ali and returns it. See the corresponding
method in L<Bio::MUST::Core::Seq> for the exact effect of this gap-cleaning
operation.

This method does not accept any arguments.

=head2 uniformize

Performs the three gap-cleaning operations in turn on all the sequences of
the Ali and returns it, which ensures that it is semantically clean and
rectangular.

This is only a convenience method called internally by the Ali object before
selected methods (such as storage-like methods). However, it might prove
useful in some circumstances, hence it is not defined as private.

    use aliased 'Bio::MUST::Core::Ali';
    my $ali = Ali->load('input.ali');
    $ali->add_seq(...);
    # more editing of the Ali sequences
    $ali->uniformize;

This method does not accept any arguments.

=head2 clear_new_tags

Clear the #NEW# tag (if any) from all the sequences of the Ali and returns it.

    use aliased 'Bio::MUST::Core::Ali';
    my $ali = Ali->load('input-42.ali');
    $ali->clear_new_tags;
    my @new_seqs = $ali->all_new_seqs;
    # array should be empty

This method does not accept any arguments.

=head2 shorten_ids

Replaces all the sequence ids of the Ali by their abbreviated forms as
specified by the passed L<Bio::MUST::Core::IdMapper> and returns the Ali.

Note that this method will work only if the sequence ids have not been
already shortened or modified in any way since the creation of the IdMapper.
Long ids without abbreviated forms in the IdMapper are left untouched.

    use aliased 'Bio::MUST::Core::Ali';
    use aliased 'Bio::MUST::Core::IdMapper';
    my $ali = Ali->load('input.ali');
    my $mapper = IdMapper->std_mapper( $ali, { id_prefix => 'lcl|seq' } );
    $ali->shorten_ids($mapper);
    $ali->store_fasta('input.4blast.fasta');
    # makeblastdb

    # Note: the temp_fasta method does exactly that

This method requires one argument.

=head2 restore_ids

Replaces all the sequence ids of the Ali by their long forms as specified by
the passed L<Bio::MUST::Core::IdMapper> and returns the Ali.

Note that this method will work only if the sequence ids have been previously
abbreviated (see above) and have not been modified in any way since then.
Again, abbreviated ids without long forms in the IdMapper are left untouched.

    use aliased 'Bio::MUST::Core::IdMapper';
    my $mapper = IdMapper->gi_mapper($ali);
    $ali->shorten_ids($mapper);
    ...
    $ali->restore_ids($mapper);

This method requires one argument.

=head2 apply_list

Selectively retains or discards sequences from the Ali based on the content
of the passed L<Bio::MUST::Core::IdList> object and returns the Ali.

    use aliased 'Bio::MUST::Core::IdList';
    my $list = IdList->load('interesting_seqs.idl');
    $ali->apply_list($list);                # discard non-interesting seqs

This method requires one argument.

=head2 apply_mask

Selectively retains or discards sites from the Ali based on the content of
the passed L<Bio::MUST::Core::SeqMask> object and returns the Ali.

    use aliased 'Bio::MUST::Core::SeqMask';
    my $variable_sites = SeqMask->variable_mask($ali);
    $ali->apply_mask($variable_sites);      # discard constant sites

This method requires one argument.

=head2 idealize

Computes and applies an ideal sequence mask to the Ali and returns it. This
is only a convenience method.

When invoked without arguments, it will discard the gaps that are
universally shared by all the sequences. Otherwise, the provided argument
corresponds to the threshold of the C<ideal_mask> method described in
L<Bio::MUST::Core::SeqMask>.

    use aliased 'Bio::MUST::Core::IdList';
    my $fast_seqs = IdList->load('fast_evolving_seqs.idl');
    my $seqs2keep = $fast_seqs->negative_list($ali);
    $ali->apply_list($seqs2keep);           # discard fast-evolving seqs
    $ali->idealize;      # discard newly shared gaps caused by fast seqs

    use aliased 'Bio::MUST::Core::Ali';
    my $ali = Ali->load('hmm_based.ali');
    $ali->idealize(0.05);    # discard insertions due to <5% of the seqs

This method accepts an optional argument.

=head1 MISC METHODS

=head2 gapmiss_regex

Returns a regular expression matching gaps and ambiguous or missing states.
The exact regex returned depends on the type of sequences in the Ali (nucl. or
proteins).

    my $regex = $ali->gapmiss_regex;
    my $first_seq = $ali->get_seq(0)->seq;
    my $gapmiss_n = $first_seq =~ m/($regex)/xmsg;
    say "The first sequence has $gapmiss_n gaps or ambiguous/missing sites";

This method does not accept any arguments.

=head2 map_coords

Converts a set of site positions from Ali coordinates to coordinates of the
specified sequence (thereby ignoring positions due to gaps). Returns the
converted sites in sequence coordinates as an array refrence.

    use aliased 'Bio::MUST::Core::Ali';
    my $ali = Ali->load('input.ali');
    my $id = 'GIV-Norovirus Hum.GIV.1.POL_1338688@508124125';
    my $ali_coords = [ 4, 25, 73, 89, 104, 116 ];
    my $seq_coords = $ali->map_coords($id, $ali_coords);
    # $seq_coords is [ 3, 23, 59, 71,  71,  74 ]

This method requires two arguments: the id of a sequence and an array
reference of input sites in Ali coordinates.

=head1 I/O METHODS

=head2 load

Class method (constructor) returning a new Ali read from disk. This method
will transparently import plain FASTA files in addition to the MUST
pseudo-FASTA format (ALI files).

    use Test::Deeply;
    use aliased 'Bio::MUST::Core::Ali';
    my $ali1 = Ali->load('example.ali');
    my $ali2 = Ali->load('example.fasta');
    my @seqs1 = $ali1->all_seqs;
    my @seqs2 = $ali2->all_seqs;
    is_deeply, \@seqs1, \@seqs2, 'should be true';

This method requires one argument.

=head2 store

Writes the Ali to disk in the MUST pseudo-FASTA format (ALI files).

Note that the ALI format is only used when the suffix of the outfile name is
'.ali'. In all other cases (including lack of suffix), this method
automatically forwards the call to C<store_fasta>.

    $ali->store('output.ali');
    # output.ali is written in ALI format
    $ali->store('output.fasta');
    # output.fasta is written in FASTA format

This method requires one argument (but see C<store_fasta> in case of automatic
forwarding of the method call).

=head2 store_fasta

Writes the Ali to disk in the plain FASTA format.

For compatibility purposes, this method automatically fetches sequence ids
using the C<foreign_id> method instead of the native C<full_id> method, both
described in L<Bio::MUST::Core::SeqId>.

    $ali->store_fasta( 'output.fasta' );
    $ali->store_fasta( 'output.fasta', {chunk => -1, degap => 1} );

This method requires one argument and accepts a second optional argument
controlling the output format. It is a hash reference that may contain one
or more of the following keys:

    - clean: replace all ambiguous and missing states by C<X> (default: false)
    - degap: boolean value controlling degapping (default: false)
    - chunk: line width (default is 60 chars; negative values means no wrap)

Finally, it is possible to fine-tune the behavior of the C<clean> option by
providing another character than C<X> through the C<gapify> key. This can be
useful to replace all ambiguous and missing states by gaps, as shown below:

    $ali->store_fasta( 'output.fasta, { clean => 1, gapify => '*' } );

=head2 temp_fasta

Writes a temporary copy of the Ali to disk in the plain FASTA format using
numeric sequence ids and returns the name of the temporary file. This is
only a convenience method.

In list context, returns the IdMapper object along with temporary filename.

    my $infile = $ali->temp_fasta( { degap => 1 } );
    my $output = `script.sh $infile`;
    ...

This method accepts the same optional argument hash as C<store_fasta>.
However, an additional option (C<id_prefix>) is available to control the way
abbreviated sequence ids are prefixed by the C<std_mapper> method (see
L<Bio::MUST::Core::Listable>).

    my $infile1 = $ali1->temp_fasta( { id_prefix => 'file1-' } );
    my $infile2 = $ali2->temp_fasta( { id_prefix => 'file2-' } );

Finally, it is possible to pass an existing L<Bio::MUST::Core::IdMapper> object
by providing the C<mapper> option.

=head2 load_phylip

Class method (constructor) returning a new Ali read from a file in the
PHYLIP format. Both sequential and interleaved formats are supported.

The only constraint is that sequence ids MUST NOT contain whitespace and be
followed by at least one whitespace character. This means that some old-school
PHYLIP files not following this convention will not be processed correctly.

When using the interleaved format, sequence ids may or may not be repeated in
each block.

    use aliased 'Bio::MUST::Core::Ali';
    my $ali = Ali->load_phylip('phylip.phy');
    say $ali->count_seqs;
    say $ali->width;

    # outputs:
    # 10
    # 709

This method requires one argument.

=head2 store_phylip

Writes the Ali to disk in the interleaved (or sequential) PHYLIP format.

To ensure maximal flexibility, this method fetches sequence ids using the
native C<full_id> method described in L<Bio::MUST::Core::SeqId>, but
truncates them to 10 characters, as expected by the original PHYLIP software
package. No other tinkering is carried out on the ids. Thus, if the ids
contain whitespace or are not unique in their 10 first characters, it is
advised to first map them using one of the constructors in
L<Bio::MUST::Core::IdMapper>.

    use aliased 'Bio::MUST::Core::Ali';
    use aliased 'Bio::MUST::Core::IdMapper';
    my $ali = Ali->load('input.ali');
    my $mapper = IdMapper->std_mapper($ali);
    $ali->shorten_ids($mapper);
    $ali->store_phylip( 'input.phy', { chunk => 50 } );

This method requires one argument and accepts a second optional argument
controlling the output format. It is a hash reference that may contain one
or more of the following keys:

    - short: truncate ids to 10 chars, as in original PHYLIP (defaut: yes)
    - clean: replace all ambiguous and missing states by 'X' (default: false)
    - chunk: line width (default: 60 chars; negative values means no wrap)

To store the Ali in PHYLIP sequential format, specify a negative chunk (-1).

=head2 load_stockholm

Class method (constructor) returning a new Ali read from a file in the
STOCKHOLM format. =GF comments are retained (see above) but not the other
comment classes (=GS, =GR and =GC).

    use aliased 'Bio::MUST::Core::Ali';
    my $ali = Ali->load('upsk.stockholm');
    say $ali->header;

    # outputs:
    # ID    UPSK
    # SE    Predicted; Infernal
    # SS    Published; PMID 9223489
    # RN    [1]
    # RM    9223489
    # RT    The role of the pseudoknot at the 3' end of turnip yellow mosaic
    # RT    virus RNA in minus-strand synthesis by the viral RNA-dependent RNA
    # RT    polymerase.
    # RA    Deiman BA, Kortlever RM, Pleij CW;
    # RL    J Virol 1997;71:5990-5996.

This method requires one argument.

=head2 load_tinyseq

Class method (constructor) returning a new Ali read from a file in NCBI
TinySeq XML format.

=head2 instant_store

Class method intended to transform a large sequence file read from disk
without loading it in memory. This method will transparently process plain
FASTA files in addition to the MUST pseudo-FASTA format (ALI files).

    my $chunk = 200;

    my $split = sub {
        my $seq = shift;
        my $base_id = ( split /\s+/xms, $seq->full_id )[0];
        my $max_pos = $seq->seq_len - $chunk;
        my $n = 0;
        my $out_str;
        for (my $pos = 0; $pos <= $max_pos; $pos += $chunk, $n++) {
            $out_str .= ">$base_id.$n\n" . $seq->edit_seq($pos,
                $pos + $chunk <= $max_pos ? $chunk : 2 * $chunk
            ) . "\n";
        }
        return $out_str;
    };

    use aliased 'Bio::MUST::Core::Ali';

    Ali->instant_store(
        'outfile.fasta', { infile => 'infile.fasta', coderef => $split }
    );

This method requires two arguments. The sercond is a hash reference that must
contain the following keys:
    - infile:  input sequence file
    - coderef: subroutine implementing the transforming logic

=head2 instant_count

Class method returning the number of seqs in any sequence file read from disk
without loading it in memory. This method will transparently process plain
FASTA files in addition to the MUST pseudo-FASTA format (ALI files).

    use aliased 'Bio::MUST::Core::Ali';
    my $seq_n = Ali->instant_count('input.ali');
    say $seq_n;

=head1 ALIASES

=head2 height

Alias for C<count_seqs> method. For API consistency.

=head1 AUTHOR

Denis BAURAIN <denis.baurain@uliege.be>

=head1 CONTRIBUTORS

=for stopwords Catherine COLSON Arnaud DI FRANCO

=over 4

=item *

Catherine COLSON <ccolson@doct.uliege.be>

=item *

Arnaud DI FRANCO <arnaud.difranco@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Liege / Unit of Eukaryotic Phylogenomics / Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

=encoding utf8

=head1 NAME

Bio::BPWrapper::SeqManipulations - Functions for bioseq

=head1 SYNOPSIS

    require Bio::BPWrapper::SeqManipulations;

=cut

package Bio::BPWrapper::SeqManipulations;

use strict;    # Still on 5.10, so need this for strict
use warnings;
use 5.010;
use Bio::Seq;
use Bio::SeqIO;
use File::Basename;
use Bio::Tools::CodonTable;
use Bio::DB::GenBank;
use Bio::Tools::SeqStats;
use Bio::SeqUtils;
use Scalar::Util;
use Exporter ();

if ($ENV{'DEBUG'}) { use Data::Dumper }

use vars qw(@ISA @EXPORT @EXPORT_OK);

@ISA         = qw(Exporter);

# FIXME: some of these might be put in
# a common routine like print_version
@EXPORT      = qw(initialize can_handle handle_opt write_out
print_composition filter_seqs retrieve_seqs remove_gaps
print_lengths print_seq_count make_revcom
print_subseq restrict_digets anonymize
shred_seq count_codons print_gb_gene_feats
count_leading_gaps hydroB linearize reloop_at
print_version remove_stop parse_orders find_by_order
pick_by_order del_by_order find_by_id
pick_by_id del_by_id find_by_re
pick_by_re del_by_re
find_by_ambig pick_by_ambig del_by_ambig find_by_length
del_by_length);

# Package global variables
my ($in, $out, $seq, %opts, $filename, $in_format, $out_format);
my $RELEASE = '1.0';

## For new options, just add an entry into this table with the same key as in
## the GetOpts function in the main program. Make the key be a reference to the handler subroutine (defined below), and test that it works.
my %opt_dispatch = (
    'composition' => \&print_composition,
    'delete' => \&filter_seqs,
    'fetch' => \&retrieve_seqs,
    'nogaps' => \&remove_gaps,
    'length' => \&print_lengths,
    'numseq' => \&print_seq_count,
    'pick' => \&filter_seqs,
    'revcom' => \&make_revcom,
    'subseq' => \&print_subseq,
    'translate' => \&reading_frame_ops,
    'restrict' => \&restrict_digest,
    'anonymize' => \&anonymize,
    'break' => \&shred_seq,
    'count-codons' => \&count_codons,
    'feat2fas' => \&print_gb_gene_feats,
    'leadgaps' => \&count_leading_gaps,
    'hydroB' => \&hydroB,
    'linearize' => \&linearize,
    'reloop' => \&reloop_at,
    'removestop' => \&remove_stop,
    'split-cdhit' => \&split_cdhit,
#   'dotplot' => \&draw_dotplot,
#    'extract' => \&reading_frame_ops,
#	'longest-orf' => \&reading_frame_ops,
#	'prefix' => \&anonymize,
#	'rename' => \&rename_id,
#	'slidingwindow' => \&sliding_window,
#	'split' => \&split_seqs,
  );

my %filter_dispatch = (
    'find_by_order'  => \&find_by_order,
    'pick_by_order'  => \&pick_by_order,
    'delete_by_order'   => \&del_by_order,
    'find_by_id'     => \&find_by_id,
    'pick_by_id'     => \&pick_by_id,
    'delete_by_id'      => \&del_by_id,
    'find_by_re'     => \&find_by_re,
    'pick_by_re'     => \&pick_by_re,
    'delete_by_re'      => \&del_by_re,
    'find_by_ambig'  => \&find_by_ambig,
    'pick_by_ambig'  => \&pick_by_ambig,
    'delete_by_ambig'   => \&del_by_ambig,
    'find_by_length' => \&find_by_length,
    'pick_by_length' => \&pick_by_length,
    'del_by_length'  => \&del_by_length,
);

##################### initializer & option handlers ###################

## TODO Function documentation!
## TODO Formal testing!

sub initialize {
    my $val = shift;
    %opts = %{$val};

    die "Option 'prefix' requires a value\n" if defined $opts{"prefix"} && $opts{"prefix"} =~ /^$/;

    $filename = shift @ARGV || "STDIN";    # If no more arguments were given on the command line, assume we're getting input from standard input

    $in_format = $opts{"input"} // 'fasta';

    $in = Bio::SeqIO->new(-format => $in_format, ($filename eq "STDIN")? (-fh => \*STDIN) : (-file => $filename));

    $out_format = $opts{"output"} // 'fasta';

# A change in SeqIO, commit 0e04486ca4cc2e61fd72, means -fh or -file is required
    $out = Bio::SeqIO->new(-format => $out_format, -fh => \*STDOUT)
}

sub can_handle {
    my $option = shift;
    return defined($opt_dispatch{$option})
}

sub handle_opt {
    my $option = shift;
    $opt_dispatch{$option}->($option)  # This passes option name to all functions
}

sub write_out {
    while ($seq = $in->next_seq()) { $out->write_seq($seq) }
}


################### subroutine ########################

sub split_cdhit {
    my $cls_file = $opts{'split-cdhit'};
    open IN, "<" . $cls_file || die "cdhit clstr file not found: $cls_file\n";
    my %clusters;
    my $cl_id;
    my @mem;
    while (<IN>) {
	my $line = $_;
	chomp $line;
	if ($line =~ /^>(\S+)\s+(\d+)/) {
	    $cl_id = $1 . "_" . $2;
	    my @mem = ();
	    $clusters{$cl_id} = \@mem;
	} else {
	    my $ref = $clusters{$cl_id};
	    my @mems = @$ref;
	    my @els = split /\s+/, $line;
	    my $seq_id = $els[2];
	    $seq_id =~ s/>//;
	    $seq_id =~ s/\.\.\.$//;
	    push @mems, $seq_id;
	    $clusters{$cl_id} = \@mems;
	}
    }
#    print Dumper(\%clusters);
    my %seqs;
    while ($seq = $in->next_seq()) {
        my $id = $seq->display_id();
	$seqs{$id} = $seq;
    }

    foreach my $id (keys %clusters) {
	my $out = Bio::SeqIO->new( -file => ">" . $filename . "-". $id . ".fas", -format => 'fasta');
	my @seqids = @{ $clusters{$id} };
	foreach my $seq_id (@seqids) {
	    $out->write_seq($seqs{$seq_id});
	}
    }
    exit;
}


sub print_composition {
    while ($seq = $in->next_seq()) {
        my $hash_ref = Bio::Tools::SeqStats->count_monomers($seq);
        my $count;
        $count += $hash_ref->{$_} foreach keys %$hash_ref;
        print $seq->id();
        foreach (sort keys %$hash_ref) {
            print "\t", $_, ":", $hash_ref->{$_}, "(";
            printf "%.2f", $hash_ref->{$_}/$count*100;
            print "%)"
        }
        print "\n"
    }
}

# This sub calls all the del/pick subs above. Any option to filter input sequences by some criterion goes through here, and the appropriate filter subroutine is called.
sub filter_seqs {
    my $action = shift;
    my $match  = $opts{$action};

    # matching to stop at 1st ':' so that ids using ':' as field delimiters are handled properly
    $match =~ /^([^:]+):(\S+)$/ || die "Bad search format. Expecting a pattern of the form: tag:value.\n";

    my ($tag, $value) = ($1, $2);
    my @selected = split(/,/, $value);
    my $callsub = "find_by_" . "$tag";

    die "Bad tag or function not implemented. Tag was: $tag\n" if !defined($filter_dispatch{$callsub});

    if ($tag eq 'order') {
        my $ct = 0;
        my %order_list = parse_orders(\@selected);   # Parse selected orders and create a hash
        while (my $currseq = $in->next_seq) { $ct++; $filter_dispatch{$callsub}->($action, $ct, $currseq, \%order_list) }
        foreach (keys %order_list) { print STDERR "No matches found for order number $_\n" if $_ > $ct }
    }
    elsif ($tag eq 'id') {
        my %id_list = map { $_ => 1 } @selected;    # create a hash from @selected
        while (my $currseq = $in->next_seq) { $filter_dispatch{$callsub}->($action, $match, $currseq, \%id_list) }
        foreach (keys %id_list) { warn "No matches found for '$_'\n" if $id_list{$_} == 1 }
    } else {
        while (my $currseq = $in->next_seq) { $filter_dispatch{$callsub}->($action, $currseq, $value) }
    }
}

# To do: add fetch by gi
sub retrieve_seqs {
    my $gb  = Bio::DB::GenBank->new();
    my $seq = $gb->get_Seq_by_acc($opts{'fetch'}); # Retrieve sequence with Accession Number
    $out->write_seq($seq)
}

sub remove_gaps {    # remove gaps
    while ($seq = $in->next_seq()) {
        my $string = $seq->seq();
        $string =~ s/-//g;
        my $new_seq = Bio::Seq->new(-id => $seq->id(), -seq => $string);
        $out->write_seq($new_seq)
    }
}

sub print_lengths {
    while ($seq = $in->next_seq()) { print $seq->id(), "\t", $seq->length(), "\n" }
}

sub print_seq_count {
    my $count;
    while ($seq = $in->next_seq()) { $count++ }
    print $count, "\n"
}

sub make_revcom {    # reverse-complement a sequence
    while ($seq = $in->next_seq()) {
        my $new = Bio::Seq->new(-id  => $seq->id() . ":revcom", -seq => $seq->revcom()->seq());
        $out->write_seq($new)
    }
}

sub print_subseq {
    while ($seq = $in->next_seq()) {
        my $id = $seq->id();
        my ($start, $end) = split /\s*,\s*/, $opts{"subseq"};
	$end = $seq->length() if $end eq '-'; # allow shorthand: -s'2,-'
        die "end out of bound: $id\n" if $end > $seq->length();
        my $new = Bio::Seq->new(-id  => $seq->id() . ":$start-$end", -seq => $seq->subseq($start, $end));
        $out->write_seq($new)
    }
}

sub _internal_stop_or_x {
    my $str = shift;
    $str =~ s/\*$//; # remove last stop
    return ($str =~ /[X\*]/) ? 1 : 0; # previously missed double **
}

sub reading_frame_ops {
    my $frame = $opts{"translate"};
    while ($seq = $in->next_seq()) {
        if ($frame == 1) {
	    if (&_internal_stop_or_x($seq->translate()->seq())) {
		warn "internal stop:\t" . $seq->id . "\tskip.\n"
	    } else {
		$out->write_seq($seq->translate())
	    }
	}
        elsif ($frame == 3) {
                my @prots = Bio::SeqUtils->translate_3frames($seq);
                $out->write_seq($_) foreach @prots
        } elsif ($frame == 6) {
                my @prots = Bio::SeqUtils->translate_6frames($seq);
                $out->write_seq($_) foreach @prots
        } else { warn "Accepted frame arguments: 1, 3, and 6\n"}
    }
}

sub restrict_digest {
    my $enz = $opts{"restrict"};
    use Bio::Restriction::Analysis;
    $seq = $in->next_seq();
    my $seq_str = $seq->seq();
    die "Not a DNA sequence\n" unless $seq_str =~ /^[ATCG]+$/i;
    my $ra = Bio::Restriction::Analysis->new(-seq=>$seq);
    foreach my $frag ($ra->fragment_maps($enz)) {
        my $seq_obj = Bio::Seq->new(
            -id=>$seq->id().'|'.$frag->{start}.'-'.$frag->{end}.'|'.($frag->{end}-$frag->{start}+1),
            -seq=>$frag->{seq});
        $out->write_seq($seq_obj)
    }
}

sub anonymize {
    my $char_len = $opts{"anonymize"} // die "Tried to use option 'preifx' without using option 'anonymize'. Exiting...\n";
    my $prefix = (defined($opts{"prefix"})) ? $opts{"prefix"} : "S";

    pod2usage(1) if $char_len < 1;

    my $ct = 1;
    my %serial_name;
    my $length_warn = 0;
    while ($seq = $in->next_seq()) {
        my $serial = $prefix . sprintf "%0" . ($char_len - length($prefix)) . "s", $ct;
        $length_warn = 1 if length($serial) > $char_len;
        $serial_name{$serial} = $seq->id();
        $seq->id($serial);
        $out->write_seq($seq);
        $ct++
    }

    _make_sed_file($filename, %serial_name);
    warn "Anonymization map:\n";
    while (my ($k, $v) = each %serial_name) { warn "$k => $v\n" }

    warn "WARNING: Anonymized ID length exceeded requested length: try a different length or prefix.\n" if $length_warn
}

sub shred_seq {
    while ($seq = $in->next_seq()) {
        my $newid = $seq->id();
        $newid =~ s/[\s\|]/_/g;
        print $newid, "\n";
        my $newout = Bio::SeqIO->new(-format => $out_format, -file => ">" . $newid . ".fas");
        $newout->write_seq($seq)
    }
    exit
}

sub count_codons {
    my $new_seq;
    my $myCodonTable = Bio::Tools::CodonTable->new();
    while ($seq = $in->next_seq()) { $new_seq .= $seq->seq() }
    my $hash_ref = Bio::Tools::SeqStats->count_codons(Bio::Seq->new(-seq=>$new_seq, -id=>'concat'));
    my $count;
    $count += $hash_ref->{$_} foreach keys %$hash_ref;
    foreach (sort keys %$hash_ref) {
        print $_, ":\t", $myCodonTable->translate($_), "\t", $hash_ref->{$_}, "\t";
        printf "%.2f", $hash_ref->{$_}/$count*100;
        print "%\n"
    }
}

sub print_gb_gene_feats { # works only for prokaryote genome
    $seq = $in->next_seq();
    my $gene_count = 0;
    foreach my $feat ($seq->get_SeqFeatures()) {
        if ($feat->primary_tag eq 'gene') {
	    my $location = $feat->location();
	    next if $location->isa('Bio::Location::Split');
            my $gene_tag = "gene_" . $gene_count++;
	    my $gene_symbol = 'na';
            foreach my $tag ($feat->get_all_tags()) {
		($gene_tag) = $feat->get_tag_values($tag) if $tag eq 'locus_tag';
		($gene_symbol) = $feat->get_tag_values($tag) if $tag eq 'gene';
	    }
            my $gene = Bio::Seq->new(-id => (join "|", ($gene_tag, $feat->start, $feat->end, $feat->strand, $gene_symbol)),
				     -seq=>$seq->subseq($feat->start, $feat->end));
            if ($feat->strand() > 0) { $out->write_seq($gene) } else { $out->write_seq($gene->revcom())}
#            print join "\t",
#                ($feat->gff_string, $feat->start, $feat->end,
#                $feat->strand);
#            print "\n";
        }
    }
}

sub count_leading_gaps {
    while ($seq = $in->next_seq()) {
        my $lead_gap = 0;
        my $see_aa   = 0;                       # status variable
        my @mono     = split //, $seq->seq();
        for (my $i = 0; $i < $seq->length(); $i++) {
            $see_aa = 1 if $mono[$i] ne '-';
            $lead_gap++ if !$see_aa && $mono[$i] eq '-'
        }
        print $seq->id(), "\t", $lead_gap, "\n"
    }
}

sub hydroB {
    while ($seq = $in->next_seq()) {
        my $pep_str = $seq->seq();
        $pep_str =~ s/\*//g;
        $seq->seq($pep_str);
        my $gravy = Bio::Tools::SeqStats->hydropathicity($seq);
        printf "%s\t%.4f\n", $seq->id(), $gravy
    }
}

sub linearize {
    while ($seq = $in->next_seq()) { print $seq->id(),  "\t", $seq->seq(), "\n" }
}

sub reloop_at {
    my $seq = $in->next_seq;  # only the first sequence
    my $break = $opts{"reloop"};
    my $new_seq = Bio::Seq->new(-id => $seq->id().":relooped_at_".$break, -seq => $seq->subseq($break, $seq->length()) . $seq->subseq(1, $break-1));
    $out->write_seq($new_seq)
}

sub print_version {
    say "bp-utils release version: ", $RELEASE;
    exit
}

sub remove_stop {
    my $myCodonTable = Bio::Tools::CodonTable->new();
    while ($seq = $in->next_seq()) {
        my $newstr = "";
        for (my $i = 1; $i <= $seq->length() / 3; $i++) {
            my $codon = $seq->subseq(3 * ($i - 1) + 1, 3 * ($i - 1) + 3);
            if ($myCodonTable->is_ter_codon($codon)) { warn "Found and removed stop codon\n"; next }
            $newstr .= $codon
        }
        my $new = Bio::Seq->new(-id  => $seq->id(), -seq => $newstr);
        $out->write_seq($new)
    }
}


####################### internal subroutine ###########################

sub parse_orders {
    my @selected = @{shift()};

    my @orders;
    # Parse if $value contains ranges: allows mixing ranges and lists
    foreach my $val (@selected) {
        if ($val =~ /^(\d+)-(\d+)$/) {    # A numerical range
            my ($first, $last) = ($1, $2);
            die "Invalid seq range: $first, $last\n" unless $last > $first;
            push @orders, ($first .. $last)
        } else { push @orders, $val }          # Single value
    }
    return map { $_ => 1 } @orders
}

sub _make_sed_file {
    my $filename = shift @_;
    my (%serial_names) = @_;

    $filename = "STDOUT" if $filename eq '-';

    my $sedfile = basename($filename) . ".sed";
    open(my $sedout, ">", $sedfile) or die $!;

    print $sedout "# usage: sed -f $filename.sed <anonymized file>\n";

    foreach (keys %serial_names) {
        my $real_name = $serial_names{$_};
        my $sed_cmd   = "s/$_/" . $real_name . "/g;\n";
        print $sedout $sed_cmd
    }
    close $sedout;

    print STDERR "\nCreated $filename.sed\tusage: sed -f $filename.sed <anonymized file>\n\n"
}

################### pick/delete filters #####################

sub find_by_order {
    my ($action, $ct, $currseq, $order_list) = @_; # say join "\t", @_;
    $filter_dispatch{ $action . "_by_order" }->($ct, $currseq, $order_list)
}

sub pick_by_order {
    my ($ct, $currseq, $order_list) = @_;
    $out->write_seq($currseq) if $order_list->{$ct}
}

sub del_by_order {
    my ($ct, $currseq, $order_list) = @_; # say join "\t", @_;
    if ($order_list->{$ct}) { warn "Deleted sequence: ", $currseq->id(), "\n" }
    else { $out->write_seq($currseq) }
}

sub find_by_id {
    my ($action, $match, $currseq, $id_list) = @_;
    my $seq_id = $currseq->id();
    $filter_dispatch{$action . "_by_id"}->($match, $currseq, $id_list, $seq_id)
}

sub pick_by_id {
    my ($match, $currseq, $id_list, $seq_id) = @_;

    if ($id_list->{$seq_id}) {
        $id_list->{$seq_id}++;
        die "Multiple matches (" . $id_list->{$seq_id} - 1 . ") for $match found\n" if $id_list->{$seq_id} > 2;
        $out->write_seq($currseq)
    }
}

sub del_by_id {
    my ($match, $currseq, $id_list, $seq_id) = @_;

    if ($id_list->{$seq_id}) {
        $id_list->{$seq_id}++;
        warn "Deleted sequence: ", $currseq->id(), "\n"
    } else { $out->write_seq($currseq) }
}

sub find_by_re {
    my ($action, $currseq, $value) = @_;
    my $regex  = qr/$value/;
    my $seq_id = $currseq->id();
    $filter_dispatch{ $action . "_by_re" }->($currseq, $regex, $seq_id)
}

sub pick_by_re {
    my ($currseq, $regex, $seq_id) = @_;
    $out->write_seq($currseq) if $seq_id =~ /$regex/
}

sub del_by_re {
    my ($currseq, $regex, $seq_id) = @_;

    if ($seq_id =~ /$regex/) { warn "Deleted sequence: $seq_id\n" }
    else { $out->write_seq($currseq) }
}

# TODO This needs better documentation
sub find_by_ambig {
    my ($action, $currseq, $cutoff) = @_;
    my $string        = $currseq->seq();
    my $ct            = ($string =~ s/n/n/gi);
    my $percent_ambig = $ct / $currseq->length();
    $filter_dispatch{"$action" . "_by_ambig"}->($currseq, $cutoff, $ct, $percent_ambig)
}

# TODO Probably better to change behavior when 'picking'?
sub pick_by_ambig {
    my ($currseq, $cutoff, $ct, $percent_ambig) = @_;
    $out->write_seq($currseq) if $percent_ambig > $cutoff
}

sub del_by_ambig {
    my ($currseq, $cutoff, $ct, $percent_ambig) = @_;

    if ($percent_ambig > $cutoff) { warn "Deleted sequence: ", $currseq->id(), " number of N: ", $ct, "\n" }
    else { $out->write_seq($currseq) }
}

sub find_by_length {
    my ($action, $currseq, $value) = @_;
    $filter_dispatch{$action . "_by_length"}->($currseq, $value)
}

sub pick_by_length {
    my ($currseq, $value) = @_;
    $out->write_seq($currseq) if $currseq->length() <= $value
}

sub del_by_length {
    my ($currseq, $value) = @_;

    if ($currseq->length() <= $value) { warn "Deleted sequence: ", $currseq->id(), " length: ", $currseq->length(), "\n" }
    else { $out->write_seq($currseq) }
}

1;

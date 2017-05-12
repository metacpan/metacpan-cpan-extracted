package Bio::FdrFet;

use 5.008;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Bio::FdrFet ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.05';

1;

=head1 NAME

Bio::FdrFet - Perl extension for False Discovery Rate and Fisher Exact Test applied to pathway analysis.

=head1 SYNOPSIS

  use Bio::FdrFet;
  my $obj = new Bio::FdrFet($fdrcutoff);

  open (IN, $pathwayfile) ||
      die "can not open pathway annotation file $pathwayfile: $!\n";
  while (<IN>) {
      chomp;
      my ($gene, $dbacc, $desc, $rest) = split (/\t/, $_, 4);
      $obj->add_to_pathway("gene" => $gene,
	   		   "dbacc" => $dbacc,
			   "desc" => $desc);
  }
  close IN;

  #read in genes and associated p values
  my (%genes, @fdrs);
  open (IN, $genefile) || die "can not open gene file $genefile: $!\n";
  my $ref_size = 0;
  while (<IN>) {
      my ($gene, $pval) = split (/\t/, $_);
      $obj->add_to_genes("gene" => $gene,
  		         "pval" => $pval);
      $ref_size++;
  }
  close IN;
  $obj->gene_count($ref_size);
  $obj->calculate;
  foreach my $pathway ($obj->pathways('sorted')) {
      my $logpval = $obj->pathway_result($pathway, 'LOGPVAL');
      printf "Pathway $pathway %s has - log(pval) = %6.4f",
             $obj->pathway_desc($pathway),
             $logpval;
  }

=head2 Constructor

  $obj = new Bio::FdrFet($fdrcutoff);

  # You can also use $obj = new Bio::FdrFet->new($fdrcutoff);

=head2 Object Methods

=head3 Input Methods

  $obj->fdr_cutoff($new_cutoff);
  $obj->universe($universe_option);
  $obj->verbose($new_verbose);
  $obj->add_to_pathway("gene" => <gene_name>,
                       "dbacc" => <pathway_accession>,
                       "desc" => <pathway description>);
  $obj->add_to_genes("gene" => <gene_name>,
                     "pval" => <probability_value>);

=head3 Output Methods

  $obj->genes;
  $obj->pathways[($order)];
  $obj->pathway_result($pathway, $data_name[, $all_flag]);
  $obj->pathway_desc($pathway);
  $obj->pathway_genes($pathway);
  $obj->fdr_position($fdr);

=head3 Other Methods

  $obj->gene_count[($fet_gene_count)];
  $obj->calculate;

=head1 DESCRIPTION

Bio::FdrFet implements the False Discovery Rate Fisher Exact Test of gene
expression analysis applied to pathways described in the paper by
Ruiru Ji, Karl-Heinz Ott, Roumyana Yordanova, and Robert E
Bruccoleri.  A copy of the paper is included with the distribution in
the file, Fdr-Fet-Manuscript.pdf.

The module is implemented using a simple object oriented paradigm
where the object stores all the information needed for a calculation
along with a state variable, C<STATE>. The state variable has two
possible values, C<'setup'> and C<'calculated'>. The value of
C<'setup'> indicates that the object is being setup with data, and any
results in the object are inconsistent with the data. The value of
C<'calculated'> indicates that the object's computational results are
consistent with the data, and may be returned to a calling program.

The C<'calculate'> method is used to update all the calculated values
from the input data. It checks the state variable first, and only does
the calculation if the state is C<'setup'>. Once the calculations are
complete, then the state variable is set to C<'calculated'>. Thus, the C<calculate> method
can be called whenever a calculated value is needed, and there is no
performance penalty.

The module initializes the C<Bio::FdrFet> object with a state of
C<'setup'>. Any data input sets the state to C<'setup'>. Any requests
for calculated data, calls C<'calculate'>, which updates the state
variable so futures requests for calculated data return quickly.

=head1 METHODS

The following methods are provided:

=over 4

=cut


=item C<new([$fdrcutoff])>

Creates a new Bio::FdrFet object. The optional parameter is the False
Discovery Rate cutoff in units of percent. See the C<fdr_cutoff>
method below for more details.

=cut

sub new {
    my $pkg;
    my $class = shift;
    eval {($pkg) = caller(0);};
    if ($class ne $pkg) {
	unshift @_, $class;
    }
    my $self = {};
    bless $self;
    my $cutoff = shift;
    $cutoff = 35 if not defined $cutoff;
    $self->{STATE} = "setup";
    $self->{FDR_CUTOFF} = _check_fdr_cutoff($cutoff);
    $self->{PATHWAYS} = {};
    $self->{GENES} = {};
    $self->{INPUT_GENE_COUNT} = 0;
    $self->{GENE_COUNT} = undef;
    $self->{VERBOSE} = 1;
    $self->{UNIVERSE} = "genes";
    return $self;
}

=item C<fdr_cutoff([$fdrcutoff])>

Retrieves the current setting for the False Discovery Rate threshold,
and optionally sets it. This threshold must be an integer greater than
0 and less than or equal to 100, and is divided by 100 for the value
used by the computation.

=cut

sub fdr_cutoff {

    my $self = shift;
    my $new_cutoff = shift;
    if (defined($new_cutoff)) {
	$self->{FDR_CUTOFF} = _check_fdr_cutoff($new_cutoff);
        $self->{STATE} = 'setup';
    }
    return $self->{FDR_CUTOFF};
}

=item C<verbose([$verbose_mode])>

Retrieves the current setting for the verbose parameter
and optionally sets it. It can be either 0, no verbosity, or 1, lots
of messages sent to STDERR.

=cut

sub verbose {

    my $self = shift;
    my $new_verbose = shift;
    if (defined($new_verbose)) {
	$self->{VERBOSE} = $new_verbose;
    }
    return $self->{VERBOSE};
}

=item C<universe([$universe_option])>

Retrieves the current setting for the B<universe> option
and optionally sets it. The B<universe> option specifies how the number of
genes in our statistical universe is calculated. There are four possible
settings to this option:

=over 2

=item union

The universe is the union of all gene names specified
individually and in pathways. Genes which have no P value are counted in the universe,
but they are not counted as regulated in the FET or FDR calculations.

=item genes

Only genes specified by the add_to_genes method count.

=item intersection

Only genes in the intersection of the gene list and pathways are used for the universe
calculation

=item user

The user specifies the universe size by calling the C<gene_count> method with an argument.

=back

=cut

sub universe {

    my $self = shift;
    my $new_universe = shift;
    if (defined($new_universe)) {
	$new_universe = lc($new_universe);
	if ($new_universe =~ m/^(user|union|genes|intersection)$/) {
	    $self->{UNIVERSE} = $new_universe;
	}
	else {
	    confess "Bad value ($new_universe) for setting universe option\n";
	}
    }
    return $self->{UNIVERSE};
}

=item C<< add_to_pathway( >>

 "gene" => <gene_name>,
 "dbacc" => <pathway_accession>,
 "desc" => <pathway description>)

Adds a gene to a pathway and also defines a pathway. The arguments are
specified as a pseudo hash, with each argument being preceded by its
name.

Pathways are defined by an accession key (C<dbacc> parameter), a
description (C<desc> parameter, and a set of genes (specified by the
C<gene>parameter). To use this function to specify a pathway with
multiple genes, you call this method multiple times with the same
accession key and description, and vary the gene name. The gene names
are just arbitrary strings, but they must match the values used for
specifying Probability Values (pvalues) used by the C<add_to_genes>
method.

=cut

sub add_to_pathway {
    
    my $self = shift;
    my %arg = &_check_args(\@_, "gene", "dbacc", "desc");
    if (exists($self->{PATHWAYS}->{$arg{dbacc}}) and
	exists($self->{PATHWAYS}->{$arg{dbacc}}->{DESC})) {
	if ($arg{desc} ne $self->{PATHWAYS}->{$arg{dbacc}}->{DESC}) {
	    confess(sprintf("Gene %s has a dbacc = %s with descriptor of %s does not match previous entry descriptor = %s\n",
			    $arg{gene},
			    $arg{dbacc},
			    $arg{desc},
			    $self->{PATHWAYS}->{$arg{dbacc}}));
	}
    }
    else {
	$self->{PATHWAYS}->{$arg{dbacc}}->{DESC} = $arg{desc};
    }
    push (@{$self->{PATHWAYS}->{$arg{dbacc}}->{GENES}}, $arg{gene});
    push(@{$self->{GENES}->{$arg{gene}}->{PATHWAYS}}, $arg{dbacc});
    $self->{STATE} = 'setup';
}

=item C<< add_to_genes( >>

 "gene" => <gene_name>,
 "pval" => <probability value>)


Adds a probability values for a gene in the calculation. The arguments
are specified using a pseudo hash with the nameof parameter preceding
its value. The gene names must match those used in the pathways. The
probability values are estimates of non-randomness and should range
from 0 to 1.

=cut

sub add_to_genes {
    my $self = shift;
    my %arg = &_check_args(\@_, "gene", "pval");
    if (exists($self->{GENES}->{$arg{gene}}->{PVAL}) and
	$self->{GENES}->{$arg{gene}}->{PVAL} != $arg{pval}) {
	confess sprintf("Gene %s has a pre-existing pval (%g) different than the current argument = %g\n",
			$arg{gene},
			$self->{GENES}->{$arg{gene}}->{PVAL},
			$arg{pval});
    }
    $self->{GENES}->{$arg{gene}}->{PVAL} = $arg{pval};
    $self->{STATE} = 'setup';
    $self->{INPUT_GENE_COUNT} += 1;
}

=item C<genes()>

Returns the list of gene names in the system.

=cut

sub genes {
    my $self = shift;
    return keys %{$self->{GENES}};
}

=item C<pathways[($order)]>

Returns the list of pathways. If the optional argument, C<$order>, is
specified and contains the word, C<"sorted">, (comparison is case
insensitive), then the object will return the pathways in order of
most significant to least. If sorting is done, then the object will
update the calculation of probability values, whereas if no sorting is
done, then the object does no calculation.

=cut

sub pathways {
    my $self = shift;
    my $order = shift;
    if (lc($order) ne 'sorted') {
	return keys %{$self->{PATHWAYS}};
    }
    else {
	$self->calculate;
	return sort { $self->{PATHWAYS}->{$b}->{BEST_RESULTS}->{LOGPVAL} <=>
		      $self->{PATHWAYS}->{$a}->{BEST_RESULTS}->{LOGPVAL} } keys %{$self->{PATHWAYS}};
    }
}

=item C<pathway_result($pathway, $data_name[, $all_flag])>

Returns a calculated result for a pathway. The following values may be
used for C<$data_name>. Case of C<$data_name> does not matter.

 LOGPVAL   -log10(probability value for pathway).
 PVAL      probability value for pathway
 ODDS      Odds ratio. 
 Q         Number of genes in the pathway passing the FDR cutoff
 M         Number of genes overall passing the FDR cutoff
 N         Number of genes in the system minus C<M> above.
 K         Number of genes in the pathway.
 FDR       FDR cutoff in percent giving the best pvalue.
 LOCI      Reference to an array of gene names in the pathway
           that satisfy FDR cutoff.

If C<$all_flag> is specified and has the value, "all", then this
returns an array of values for all the attempted FDR cutoffs, except
for the c<FDR> cutoff.

=cut

sub pathway_result {
    my $self = shift;
    my $pathway = $self->_check_pathway_arg(shift(@_));
    my $name = uc(shift(@_));
    my $all_option = shift(@_);
    $all_option = "" if not defined $all_option;
    $all_option = uc($all_option);
    
    $self->calculate;
    if (not exists($self->{PATHWAYS}->{$pathway})) {
	confess "Pathway ($pathway) not found.\n";
    }
    if ($all_option eq 'ALL') {
	if ($name eq 'FDR') {
	    confess "All option not valid for FDR result.\n";
	}
	if (not exists($self->{PATHWAYS}->{$pathway}->{ALL_RESULTS}->{$name})) {
	    confess "Pathway all_results ($name) not found.\n";
	}
	return @{$self->{PATHWAYS}->{$pathway}->{ALL_RESULTS}->{$name}};
    }
    else {
	if (not exists($self->{PATHWAYS}->{$pathway}->{BEST_RESULTS}->{$name})) {
	    confess "Pathway results ($name) not found.\n";
	}
	return $self->{PATHWAYS}->{$pathway}->{BEST_RESULTS}->{$name};
    }
}

=item C<pathway_desc($pathway)>

Returns the description field of the specified pathway.

=cut

sub pathway_desc {
    my $self = shift;
    my $pathway = $self->_check_pathway_arg(shift(@_));
    return $self->{PATHWAYS}->{$pathway}->{DESC};
}

=item C<pathway_genes($pathway)>

Returns an array containing the genes of the specified pathway.

=cut

sub pathway_genes {
    my $self = shift;
    my $pathway = $self->_check_pathway_arg(shift(@_));
    return @{$self->{PATHWAYS}->{$pathway}->{GENES}};
}


=item C<fdr_position($fdr)>

Returns the position in the gene list for a specific FDR value. The
C<$fdr> variable must be an integer between 1 and the FDR cutoff.

=cut

sub fdr_position {
    my $self = shift;
    my $fdr = shift;
    if ($fdr < 1 or
	$fdr > $self->{FDR_CUTOFF} or
	int($fdr) != $fdr) {
	confess "Invalid FDR value = $fdr passed to fdr_position.\n";
    }
    return $self->{FDRS}->[$fdr-1];
}


=item C<gene_count([$fet_gene_count])>

Returns the count of genes in the system which the size of the union
of the gene names seen from both the C<add_to_genes> and
C<add_to_pathway> methods. This value is used in the Fisher Exact Test
calculation. You can change the total gene count value used in the
calculation by specifying a parameter to this method.

=cut

sub gene_count {
    my $self = shift;
    if (defined($_[0])) {
	if ($self->{UNIVERSE} eq 'user') {
	    $self->{GENE_COUNT} = $_[0];
	    $self->{STATE} = 'setup';
	}
	else {
	    confess "Gene count can be updated only if the universe option is set to 'user'";
	}
    }
    return $self->{GENE_COUNT};
}

=item C<calculate()>

Run the FDR FET calculation.

=cut

sub calculate {
    my $self = shift;
    return if $self->{STATE} eq 'calculated';
    print STDERR "New calculation initiated.\n" if $self->{VERBOSE};
    $self->_sort_by_pvals;
    $self->_clean_genes;
    $self->_calc_fdrs;
    $self->_calculate_fets;
    $self->{STATE} = 'calculated';
}

# Internal procedures.

sub _check_fdr_cutoff {
    my $cutoff = shift;
    if ($cutoff > 0 and
	$cutoff <= 100 and
	$cutoff == int($cutoff)) {
	return $cutoff;
    }
    else {
	confess "New fdr_cutoff ($cutoff) is outside the range (0, 100] or is not an integer.\n";
	return undef; # We shouldn't get here, but if so, return something that will cause problems.
    }
}

sub _check_args {
    # Check validity of argument list.
    # First argument is reference to argument list.
    # Remaining arguments are required arguments.
    my $arg_ref = shift;
    if (scalar(@{$arg_ref}) % 2 == 1) {
	confess "Argument to caller of _check_args has an odd number of elements and is not interpretable as a hash.\n";
    }
    my %args = @{$arg_ref};
    my @missing = ();
    foreach my $arg (@_) {
	if (not exists($args{$arg})) {
	    push (@missing, $arg);
	}
    }
    if (scalar(@missing)) {
	confess sprintf("Argument(s) %s missing to caller of _check_args.\n",
			join(", ", @missing));
    }
    return %args;
}

sub _check_pathway_arg {
    my $self = shift;
    my $pathway = shift;
    if (not exists($self->{PATHWAYS}->{$pathway})) {
	confess "Pathway ($pathway) not found.\n";
    }
    return $pathway;
}

sub _sort_by_pvals {
    my $self = shift;
    $self->{SORTED_GENES} = [ sort
			      { ( defined ($self->{GENES}->{$a}->{PVAL}) and
				  defined ($self->{GENES}->{$b}->{PVAL})) ?
				  $self->{GENES}->{$a}->{PVAL} <=> $self->{GENES}->{$b}->{PVAL} :
				  ( defined ($self->{GENES}->{$a}->{PVAL}) ? -1 :
				    defined ($self->{GENES}->{$b}->{PVAL}) ? 1 :
				    $a cmp $b ) }
			      keys %{$self->{GENES}} ];
    $self->{SORTED_PVALS} = [ map {$self->{GENES}->{$_}->{PVAL}} @{$self->{SORTED_GENES}} ];
}

sub _calc_fdrs {
    my $self = shift;
    $self->{FDRS} = [];
    #calculate FDRs based p values
    for (my $i = 1; $i <= $self->{FDR_CUTOFF}; $i++) {
	my $cutoff = $i / 100;
	my $result = $self->_fdr($cutoff, $self->{SORTED_PVALS});
	$self->{FDRS}->[$i-1] = $result;
	printf STDERR "FDR count at %d%% is %d\n", $i, $result if $self->{VERBOSE};
    }
}

sub _fdr {
    my $self = shift;
    my ($qlevel, $pvals) = @_;
    my $i=1;
    my $count=0;
    map { $count = ($i - 1) if (defined $_ and
				$_ <= $qlevel * $i++ / $self->{GENE_COUNT}) } @$pvals; # / ) }; Fix Emacs cperl confusion.
    return $count;
}

sub _clean_genes {
    my $self = shift;
    if (not defined $self->{GENE_COUNT}) {
	$self->{GENE_COUNT} = scalar(keys %{$self->{GENES}});
    }
    if ($self->{UNIVERSE} eq 'genes') {
	$self->_clean_unused_genes;
	$self->{GENE_COUNT} = $self->{INPUT_GENE_COUNT};
    }
    elsif ($self->{UNIVERSE} eq 'user') {
	my $sum = 0;
	foreach my $p ($self->pathways) {
	    $sum += scalar(@{$self->{PATHWAYS}->{$p}->{GENES}});
	}
	if  (not ($self->{GENE_COUNT} >= scalar(keys %{$self->{GENES}}) and
		  $self->{GENE_COUNT} >= $sum)) {
	    confess sprintf("Gene count setting %d is too small. Gene count is %d and pathway gene count is %d\n",
			    $self->{GENE_COUNT},
			    scalar(keys %{$self->{GENES}}),
			    $sum);
	}
    }
    elsif ($self->{UNIVERSE} eq 'union') {
	# No action required.
    }
    elsif ($self->{UNIVERSE} eq 'intersection') {
	foreach my $gene (keys %{$self->{GENES}}) {
	    my $exists_pathway = exists($self->{GENES}->{$gene}->{PATHWAYS});
	    my $exists_pval =
	    (exists($self->{GENES}->{$gene}->{PVAL}) and
	     defined($self->{GENES}->{$gene}->{PVAL}));
	    if (not ($exists_pathway and $exists_pval)) {
		printf STDERR "Gene $gene eliminated. exists_pathway = $exists_pathway  " .
		"exists_pval = $exists_pval\n" if $self->{VERBOSE};
		delete $self->{GENES}->{$gene};
	    }
	}
	$self->{GENE_COUNT} = scalar(keys %{$self->{GENES}});
	$self->_sort_by_pvals;
	$self->_clean_unused_genes;
    }
    printf STDERR "Gene count set to %d\n", $self->{GENE_COUNT} if $self->{VERBOSE};
}

sub _clean_unused_genes {
    my $self = shift;
    my %seen;
    foreach my $gene (@{$self->{SORTED_GENES}}) {
	if (defined ($self->{GENES}->{$gene}->{PVAL})) {
	    $seen{$gene} = 1;
	}
    }
    foreach my $pathway (keys %{$self->{PATHWAYS}}) {
	my @new_gene_list = ();
	my $old_size = scalar(@{$self->{PATHWAYS}->{$pathway}->{GENES}});
	foreach my $pgene (@{$self->{PATHWAYS}->{$pathway}->{GENES}}) {
	    if (exists($seen{$pgene})) {
		push (@new_gene_list, $pgene);
	    }
	}
	$self->{PATHWAYS}->{$pathway}->{GENES} = [ @new_gene_list ];
	my $new_size = scalar(@new_gene_list);
	if ($self->{VERBOSE}) {
	    if ($old_size != $new_size) {
		printf STDERR "Pathway %s size reduced from %d to %d\n", $pathway, $old_size, $new_size;
	    }
	    else {
		printf STDERR "Pathway %s size left at %d\n", $pathway, $old_size;
	    }
	}
    }
}

sub _calculate_fets {
    my $self = shift;
    foreach my $p (keys %{$self->{PATHWAYS}}) {
	my @pids = @{$self->{PATHWAYS}->{$p}->{GENES}};
	my ($fdr, $fdr_gene_cutoff, @s);
	my ($pval, $logpval, $q, $m, $n, $k, $bestpval, $oddratio, $bestratio);
	my ($bestm, $bestn, $bestq, $bestfdr, $bestloci, $bestlogpval);
	my (@q);
	$k = scalar(@pids);
	$bestpval = 1.1;
	$bestlogpval = 0;
	$bestratio = 0;
	$bestm = 0;
	$bestn = 0;
	$bestq = 0;
	$bestfdr = 100;
	my $path_ref = $self->{PATHWAYS}->{$p};
	for (my $fdr = $self->{FDR_CUTOFF} - 1; $fdr >= 0; $fdr--) {
	    $fdr_gene_cutoff = $self->{FDRS}->[$fdr];
	    last if ($fdr_gene_cutoff == 0);
	    $fdr_gene_cutoff--;
	    @s = @{$self->{SORTED_GENES}}[0..$fdr_gene_cutoff];
	    
	    #find intersection of pathway and regulated genes
	    my %seen = ();
	    undef @q;
	    foreach my $g (@pids) {
		$seen{$g} = 1;
	    }
	    foreach my $g (@s) {
		push @q , $g if (defined $seen{$g});
	    }
	    
	    #calculate values in 2 by 2 contigency table
	    $m = $fdr_gene_cutoff + 1;
	    $n = $self->{GENE_COUNT} - $m;
	    $q = scalar(@q);
	    
	    #FET calculation
	    ($pval, $oddratio) = _fet($q, $m, $n, $k);
	    if ($self->{VERBOSE}) {
		printf STDERR "FET calculation for $p FDR = %d: P = %.3g  Odds = %.2f  q = $q  m = $m  n = $n  k = $k\n",
		$fdr+1, $pval, $oddratio;
	    }
	    if ($pval == 0) {
		$logpval = 1000;
	    }
	    else {
		$logpval = 0 - log10($pval); # The unary operator "-" does not work correctly
		                             # if log10($pval) is 0. You get -0 for $logpval. 
	    }
	    $path_ref->{ALL_RESULTS}->{PVAL}->[$fdr] = $pval;
	    $path_ref->{ALL_RESULTS}->{LOGPVAL}->[$fdr] = $logpval;
	    $path_ref->{ALL_RESULTS}->{ODDS}->[$fdr] = $oddratio;
	    $path_ref->{ALL_RESULTS}->{Q}->[$fdr] = $q;
	    $path_ref->{ALL_RESULTS}->{M}->[$fdr] = $m;
	    $path_ref->{ALL_RESULTS}->{N}->[$fdr] = $n;
	    $path_ref->{ALL_RESULTS}->{K}->[$fdr] = $k;
	    $path_ref->{ALL_RESULTS}->{LOCI}->[$fdr] = [ @q ];
	    if ($pval < $bestpval) {
		$bestpval = $pval;
		$bestlogpval = $logpval;
		$bestratio = $oddratio;
		$bestm = $m;
		$bestn = $n;
		$bestq = $q;
		$bestfdr = $fdr + 1;
		$bestloci = [ @q ];
	    }
	}
	&_complete_all_results_array($path_ref, 'PVAL', 1.0);
	&_complete_all_results_array($path_ref, 'LOGPVAL', 0.0);
	&_complete_all_results_array($path_ref, 'ODDS', 0.0);
	&_complete_all_results_array($path_ref, 'Q', -1);
	&_complete_all_results_array($path_ref, 'M', -1);
	&_complete_all_results_array($path_ref, 'N', -1);
	&_complete_all_results_array($path_ref, 'K', -1);
	&_complete_all_results_array($path_ref, 'LOCI', [ ]);
	if ($self->{VERBOSE}) {
	    print STDERR "FET calculation for $p Bestfdr = $bestfdr\n",
	}
	$path_ref->{BEST_RESULTS} = { PVAL => $bestpval,
				      LOGPVAL => $bestlogpval,
				      ODDS => $bestratio,
				      Q => $bestq,
				      M => $bestm,
				      N => $bestn,
				      K => $k,
				      FDR => $bestfdr,
				      LOCI => $bestloci };
    }
}

sub log10 {
	my $number = shift;
	return log($number)/log(10);
}

sub _complete_all_results_array {
    my $path_ref = shift;
    my $datum = shift;
    my $default = shift;
    my $array_ref = $path_ref->{ALL_RESULTS}->{$datum};
    
    for (my $i = 0; $i < scalar(@{$array_ref}); $i++) {
	$array_ref->[$i] = $default if not defined $array_ref->[$i];
    }
}

use Inline C => <<'END_OF_C_CODE', NAME => 'Bio::FdrFet::FastFet';
  
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
  
#define MAXIT 100
#define MAX_ITER 2000
#define TOL 1.0e-7
#define EPS 1.0e-12
#define EPS1 1.0e-13
#define DBL_EPSILON 2.220446049250313e-16
#define EPSKS1 0.001
#define EPSKS2 1.0e-8
#define FPMIN 1.0e-30
#define TINY 1.0e-20
#define MD fmod(1,0)
#define PI 3.141593
#define PIX2 6.283185307179586476925286766559
   
#define SQR(a) ((a)*(a))
#define MAX(a,b) ((a) > (b) ? (a) : (b))
#define MIN(a,b) ((a) > (b) ? (b) : (a))
#define SWAP(a,b) temp=(a);(a)=(b);(b)=temp;
#define SIGN(a, b) ((b) < 0 ? -fabs(a) : fabs(a))
  
void _fet (double q, double m, double n, double k);
double dhyper (double q, double m, double n, double k);
double dbinom_raw (double q, double k, double p, double pq);
double stirlerr (double n);
double pdhyper (double q, double m, double n, double k);
double bd0 (double x, double np);
  
void
_fet (double q,
      double m,
      double n,
      double k)
{
  
  double oldn;
  double d;
  double pd;
  double pval;
  double oddratio;
  I32 flag;
  Inline_Stack_Vars;
   
  if ((m-q) == 0 || (k-q) == 0) {
    oddratio = 999999;
  } else {
    oddratio = (q*(n-k+q))/((m-q)*(k-q));
  }
  
  if ((q*(m+n)) > (k*m)) {
    oldn = n;
    n = m;
    m = oldn;
    q = k-q;
    flag = 1;
  } else {
    flag = 0;
  }
   
  if (flag == 1) {
    d  = dhyper(q, m, n, k);
    pd = pdhyper(q, m, n, k);
    pval = d * pd;
  } else if (flag == 0) {
    d  = dhyper(q-1, m, n, k);
    pd = pdhyper(q-1, m, n, k);
    pval = 0.5 - d * pd + 0.5;
  }
  
  Inline_Stack_Reset;
  Inline_Stack_Push(sv_2mortal(newSVnv(pval)));
  Inline_Stack_Push(sv_2mortal(newSVnv(oddratio)));
  Inline_Stack_Done;
   
}
   
double
dhyper (double q,
        double m,
        double n,
        double k) {
   
  double p, pq, p1, p2, p3;
   
  p = ((double)k)/((double)(m+n));
  pq = ((double)(m+n-k))/((double)(m+n));
   
  p1 = dbinom_raw(q,  m, p,pq);
  p2 = dbinom_raw(k-q,n, p,pq);
  p3 = dbinom_raw(k,m+n, p,pq);
   
  return(p1*p2/p3);
}
   
double
dbinom_raw (double q,
            double k,
            double p,
            double pq) {
   
  double lf, lc;
    
  if (p == 0) return ((q == 0) ? 1 : 0);
  if (pq == 0) return ((q == k) ? 1 : 0);
     
  if (q == 0) {
    if (k == 0) return 1;
    lc = (p < 0.1) ? -bd0(k,k*pq) - k*p : k*log(pq);
    return(exp(lc));
  }
  if (q == k) {
    lc = (pq < 0.1) ? -bd0(k,k*p) - k*pq : k*log(p);
    return(exp(lc));
  }
  if (q < 0 || q > k) return(0);
                                                                                                                                             
  lc = stirlerr(k) - stirlerr(q) - stirlerr(k-q) - bd0(q,k*p) - bd0(k-q,k*pq);
     
  lf = log(PIX2) + log(q) + log(k-q) - log(k);
     
  return exp(lc - 0.5*lf);
}
    
   
double
stirlerr (double n) {
     
  double nn;
  
  #define S0 0.083333333333333333333       /* 1/12 */
  #define S1 0.00277777777777777777778     /* 1/360 */
  #define S2 0.00079365079365079365079365  /* 1/1260 */
  #define S3 0.000595238095238095238095238 /* 1/1680 */
  #define S4 0.0008417508417508417508417508/* 1/1188 */
    
  const double sferr_halves[31] = {
    0.0, /* n=0 - wrong, place holder only */
    0.1534264097200273452913848,  /* 0.5 */
    0.0810614667953272582196702,  /* 1.0 */
    0.0548141210519176538961390,  /* 1.5 */
    0.0413406959554092940938221,  /* 2.0 */
    0.03316287351993628748511048, /* 2.5 */
    0.02767792568499833914878929, /* 3.0 */
    0.02374616365629749597132920, /* 3.5 */
    0.02079067210376509311152277, /* 4.0 */
    0.01848845053267318523077934, /* 4.5 */
    0.01664469118982119216319487, /* 5.0 */
    0.01513497322191737887351255, /* 5.5 */
    0.01387612882307074799874573, /* 6.0 */
    0.01281046524292022692424986, /* 6.5 */
    0.01189670994589177009505572, /* 7.0 */
    0.01110455975820691732662991, /* 7.5 */
    0.010411265261972096497478567, /* 8.0 */
    0.009799416126158803298389475, /* 8.5 */
    0.009255462182712732917728637, /* 9.0 */
    0.008768700134139385462952823, /* 9.5 */
    0.008330563433362871256469318, /* 10.0 */
    0.007934114564314020547248100, /* 10.5 */
    0.007573675487951840794972024, /* 11.0 */
    0.007244554301320383179543912, /* 11.5 */
    0.006942840107209529865664152, /* 12.0 */
    0.006665247032707682442354394, /* 12.5 */
    0.006408994188004207068439631, /* 13.0 */
    0.006171712263039457647532867, /* 13.5 */
    0.005951370112758847735624416, /* 14.0 */
    0.005746216513010115682023589, /* 14.5 */
    0.005554733551962801371038690  /* 15.0 */
  };
   
    
  if (n <= 15.0) {
    nn = n + n;
    if (nn == (int)nn) {
      return (sferr_halves[(int)nn]);
    } else {
      fprintf(stderr, "%f not integer\n", nn);
      exit(1);
    }
  } else {
    nn = n*n;
    if (n>500) return ((S0-S1/nn)/n);
    if (n> 80) return ((S0-(S1-S2/nn)/nn)/n);
    if (n> 35) return ((S0-(S1-(S2-S3/nn)/nn)/nn)/n);
    /* 15 < n <= 35 : */
    return ((S0-(S1-(S2-(S3-S4/nn)/nn)/nn)/nn)/n);
  }
   
}
                                                                                                                                             
                                              
double
bd0 (double x,
     double np) {
   
  double ej, s, s1, v;
  int j;
     
  if ((abs(x-np)) < (0.1*(x+np))) {
    v = (x-np)/(x+np);
    s = (x-np)*v; /* s using v -- change by MM */
    ej = 2*x*v;
    v = v*v;
    for (j=1; ; j++) { /* Taylor series */
      ej *= v;
      s1 = s+ej/((j<<1)+1);
      if (s1==s) { /* last term was effectively 0 */
        return (s1);
      }
      s = s1;
    }
  } else {
    // | x - np |  is not too small */
    return (x*log(x/np)+np-x);
  }
   
}
                
   
double
pdhyper (double q,
         double m,
         double n,
         double k) {
       
  double sum = 0;
  double term = 1;
    
  while (q > 0 && term >= DBL_EPSILON * sum) {
    term *= q * (n - k + q) / (k + 1 - q) / (m + 1 - q);
    sum += term;
    q--;
  }
    
  return 1 + sum;
   
}
  
END_OF_C_CODE
    

__END__

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

The FDR FET paper included with the source code.

=head1 AUTHORS

 Robert Bruccoleri <bruc@acm.org>
 Ruiru Ji <ruiru.ji@bms.com>
 Karl-Heinz Ott <karl-heinz.ott@bms.com>
 Roumyana Yordanova <roumyana.yordanova@bms.com>

=head1 ACKNOWLEDGEMENT

We thank Douglas B. Craig, Division of Clinical Pharmacology and Toxicology,
Children's Hospital of Michigan, Detroit, MI for finding a correcting a bug in the
FDR implementation.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Bristol-Myers Squibb Company and Congenomics LLC.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

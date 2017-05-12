package Bio::MaxQuant::Evidence::Statistics;

use 5.006;
use strict;
use warnings;

use Text::CSV;
use Carp;
use Storable;
use Statistics::Distributions;

=head1 NAME

Bio::MaxQuant::Evidence::Statistics - Additional statistics on your SILAC evidence

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Read/convert your evidence file to a more rapidly processable format,
and perform various operations and statistics across/between multiple
experiments.  Supports multidimensional experiments with replicate
analyses.


    use Bio::MaxQuant::Evidence::Statistics;

    my $foo = Bio::MaxQuant::Evidence::Statistics->new();
    
    # get the essential data from an evidence file
    $foo->parseEssentials(filename=>$evidencePath);

    # store the essentials for later
	$foo->writeEssentials(filename=>$essentialsPath);

	# laod previously stored essentials
	$foo->readEssentials(filename=>$essentialsPath);


=head1 SUBROUTINES/METHODS

=head2 new

Create a new object:

    my $foo = Bio::MaxQuant::Evidence::Statistics->new();

=cut

sub new {
    my $p = shift;
    my $c = ref($p) || $p;
    my %defaults = (
        separator => "\t",
        essential_column_names => {
            'Protein group IDs' => 1,
            'Modified'          => 1,
            'Leading Proteins'  => 1,
            'PEP'               => 1,
            'Ratio H/L'         => 1,
            'Intensity H'       => 1,
            'Intensity L'       => 1,
            'Contaminant'       => 1,
            'Reverse'           => 1,
        },
        list_column_names      => {
            'Modified'          => 1,
            'PEP'               => 1,
            'Ratio H/L'         => 1,
            'Intensity H'       => 1,
            'Intensity L'       => 1,
        },
        key_column_name        => 'id',
        experiment_column_name => 'Experiment',
        csv_options            => {sep_char=>"\t"},
    );
    my %options = (%defaults, @_);
    my $o = {defaults=>\%options};
    bless $o, $c;
    return $o;
}

=head2 parseEssentials(%options)

Reads the essential data from an evidence file.  Evidence files
for large analyses can be very big and take a long time to process,
to we only read what's necessary, and can save this for convenience
and speed too, using writeEssentials().

The data are stored by Protein group IDs, i.e. one entry per protein
group.  Other data stored here are:

=over

=item id

=item Protein group IDs

=item Modified  -- is this actually the right name??

=item Leading Proteins

=item Experiment

=item PEP

=item Ratio H/L

=item Intensity H

=item Intensity L

=item Contaminant

=item Reverse

=back

The column names used for storage are defined in the default option
essential_column_names, and can be changed when you call new, or when you call
parseEssentials.  The option is a hash of column names whose values
detmerine whether the column is kept by their truthness... e.g.

    $o->parseEssentials(essential_column_names=>(
        'id'  => 1, # kept
        'PEP' => 0, # discarded
        #foo  => ?, # discarded
    ));

If a column doesn't exist, it does not complain!

The method takes a hash of options.

options:

=over

=item filename - path of the file to process

=item separator - passed to Text::CSV (default is tab)

=item key_column_name - change the column keyed on (default is id)

=item experiment_column_name - change the column the data are split on

=item list_column_names - change the columns stored as lists

=back

=head3 list_column_names

Some columns are the same across all the evidence in a protein group, 
eg, the id is obviously the same, Contaminant and Reverse, Protein IDs, 
and so on.  The default, therefore, is to overwrite the column with
the value seen in an evidence.  BUT, some columns have a different value
in each evidence, e.g. Ratio H/L or PEP.  Whatever columns are given in 
list_column_names, which true values, will be appended as lists, so in the
final data, there will be one row per protein and any column bearing multiple
evidences for that protein will be a list.

If that makes no sense, write to me and I'll try to change it.

=cut

sub parseEssentials {
    my $o = shift;
    my %defaults = %{$o->{defaults}};
    my %options = (%defaults, @_);
    my $io = IO::File->new($options{filename}, 'r');
    my $csv = Text::CSV->new($options{csv_options});
    # head the column names, just like in the pod...
    $csv->column_names ($csv->getline ($io));
    # now getline_hr will give us hashrefs :-)
    # we just need to know which to keep...
    my %k = %{$options{essential_column_names}};
    my $i = $options{key_column_name};
    my $e = $options{experiment_column_name};
    my %l = %{$options{list_column_names}};
    my %data = ();
    my @ids = ();
    my @sharedids = ();
    my @uniqueids = ();
    
    while(! eof($io)){
        my $hr = $csv->getline_hr($io);
        my %h = map {
                exists $k{$_} && $k{$_} # exists and true
                 ? ($_=>$hr->{$_})      # key => value
                 : ()                   # empty
            } keys %$hr;
        my $key = $hr->{$i};
        my $expt = $hr->{$e};
        # store it...
        push @ids, $key; # keep track of what we've got
        # store stuff by expt, then id, then column
        $data{$expt} = {} unless exists $data{$expt};
        $data{$expt}->{$key} = { # set up this expt/key... unless it exists
            map {
                exists $l{$_} && $l{$_} 
                    ? ($_ => []) # it's an array
                    : ($_ => '') # it's a scalar
            } keys %h
        } unless exists $data{$expt}->{$key};
        # add the data...
        foreach (keys %h){ # each column
            if(exists $l{$_} && $l{$_}){ # is it a list column?
                push @{$data{$expt}->{$key}->{$_}}, $h{$_}; # push it
            }
            else {
                $data{$expt}->{$key}->{$_} = $h{$_}; # set it
            }
        }
        if($data{$expt}->{$key}->{'Protein group IDs'} =~ /;/){
            push @sharedids, $key;
        }
        else {
            push @uniqueids, $key;
        }
    }
    $o->{data} = \%data;
    $o->{ids} = [sort {$a <=> $b} @ids];
    $o->{sharedids} = [sort {$a <=> $b} @sharedids];
    $o->{uniqueids} = [sort {$a <=> $b} @uniqueids];
    $o->{cache} = {};
}

=head2 experiments

Returns a list of the experiments in the data.

=cut

sub experiments {
    my $o = shift;
    my $data = $o->{data};
    return  keys %$data;
}

=head2 replicated

Returns a list of the experiment names without the replicate portion.

The names are assumed to be Cell.Condition.Replicate, i.e. full-stop (period) separated.

=cut

sub replicated {
    my $o = shift;
    return @{$o->{cache}->{replicated}} if exists $o->{cache}->{replicated};
    my %repl = ();
    my @expts = $o->experiments();
    foreach (@expts){
        s/\.[^.]+$//;
        $repl{$_} = 1;
    }
    $o->{cache}->{replicated} = [keys %repl];
    return @{$o->{cache}->{replicated}};
}

=head2 orthogonals 

Returns a list of sets of orthogonal experiments, that is 3 experiments in which the first has
one condition in common with the other two, but they have nothing in common with each other.

e.g.   A.X A.Y B.X

The rationale behind this is that quantitative differences across this set indicate mechanistic
links between, for example, cell line and drug treatment.  If a reponse is seen to a drug, and
a different repsonse is seen in a different cell-type, this system will pick that up.  The
fourth member of the comparison (in the example that would be B.Y) could be anything... and the
interpretation would still be that there is a differential response.

=cut

sub orthogonals {
    my $o = shift;
    return @{$o->{cache}->{orthogonals}} if exists $o->{cache}->{orthogonals};
    my @repls = $o->replicated();
    my @orths = ();
    foreach my $c1(@repls){
        my ($p,$x) = split(/\./, $c1, 2);
        foreach my $c2(@repls){
            next if $c2 eq $c1;
            my ($q,$y) = split(/\./, $c2, 2);
            next unless $p eq $q;
            foreach my $c3(@repls){
                next if $c3 eq $c1 || $c3 eq $c2;
                my ($r,$z) = split(/\./, $c3, 2);
                next unless $x eq $z;
                push @orths, "$c1 $c2 $c3";
            }
        }
    }
    $o->{cache}->{orthogonals} = \@orths;
    return @orths;
}

=head2 pairs

Returns a list of pairs of replicated experiments (e.g. A.X A.Y, A.X B.X ...)
that represents all possible comparisons.

=cut

sub pairs {
    my $o = shift;
    return @{$o->{cache}->{pairs}} if exists $o->{cache}->{pairs};
    my @r = $o->replicated();
    my @pairs = ();
    foreach my $r1(sort @r){
        foreach my $r2(sort @r){
            next unless $r1 lt $r2;
            push @pairs, "$r1 $r2";
        }
    }
    $o->{cache}->{pairs} = \@pairs;
    return @pairs;
}

=head2 ids 

Returns a list of evidence ids in the data.

=cut

sub ids {
    return @{shift()->{ids}};
}

=head2 sharedIds 

Returns a list containing the ids of those evidences shared between protein groups.

=cut

sub sharedIds {
    return @{shift()->{sharedids}};
}

=head2 uniqueIds 

Returns a list containing the ids of those evidences unique to one protein group.

=cut

sub uniqueIds {
    return @{shift()->{uniqueids}};
}

=head2 saveEssentials(%options)

Save the essential data (quicker to read again in future)

=cut

sub saveEssentials {
    my $o = shift;
    my %defaults = %{$o->{defaults}};
    my %options = (%defaults, @_);
    # here we want to save everything
    store $o, $options{filename};
}

=head2 loadEssentials

Load up previously saved essentials

=cut

sub loadEssentials {
    my $o = shift;
    my %defaults = %{$o->{defaults}};
    my %options = (%defaults, @_);
    my $p = retrieve($options{filename});
    %$o = %$p;
    return $o;
}


=head2 extractColumnValues

=cut

sub extractColumnValues {
    my ($o, %options) = @_;
    # options: 
    my %defaults = (
        column      => 'id', # which column to collect
        experiment  => '',   # only extract this expt (all if false)
        'split'     => 1,    # true = split cell on ; before adding to results
        'nodup'     => 1,    # true = remove duplicates
        'emptiesok' => 0,    # true = include empty values in output
    );
    %options = (%defaults, %options);
    my $data = $o->{data};
    my $results = $options{nodup} ? {} : [];
    my @expts = $options{experiment} ? ($options{experiment}) : (keys %$data);
    foreach my $e(@expts){
        foreach my $k(keys %{$data->{$e}}){
            my $value = $data->{$e}->{$k}->{$options{column}};
            if(ref($value) eq ''){
                $value = [split /;/, $value];
            }
            my @values = $options{'split'} ? (@$value) : (join(';',@$value));
            foreach (@values){
                next unless $_ ne '' || $options{'emptiesok'};
                if($options{nodup}){
                    $results->{$_} = 1;
                }
                else {
                    push @$results, $_;
                }
            }
        }
    }
#    use Data::Dumper;
#    print STDERR Dumper $results;
    return $options{nodup} ? (keys %$results) : (@$results);
}

=head2 proteinCount

=cut

sub proteinCount {
    my $o = shift;
    return $o->{cache}->{proteinCount} if exists $o->{cache}->{proteinCount};
    my @proteins = $o->getLeadingProteins();
    $o->{cache}->{proteinCount} = scalar @proteins;
    return $o->{cache}->{proteinCount};
}

=head2 getProteinGroupIds

=cut

sub getProteinGroupIds {
    my $o = shift;
    $o->{cache}->{proteinGroupIds} = [sort $o->extractColumnValues(column=>'Protein group IDs')] unless exists $o->{cache}->{proteinGroupIds};
    return @{$o->{cache}->{proteinGroupIds}}
}

=head2 getLeadingProteins

=cut

sub getLeadingProteins {
    my $o = shift;
    $o->{cache}->{leadingProteins} = [sort $o->extractColumnValues(column=>'Leading Proteins')] unless exists $o->{cache}->{proteinGroupIds};
    return @{$o->{cache}->{leadingProteins}};
}

=head2 logRatios

Logs ratios (base 2) throughout the dataset, and sets a flag so it can't get logged again.

Treatment of "special values": empty string, <= 0, NaN, and any other non-number are removed
from the data!

=cut

sub logRatios {
    my $o = shift;
    return 0 if $o->{logged};
    $o->{logged} = 1;
    my $data = $o->{data};
    foreach my $exptname(keys %$data){
        my $experiment = $data->{$exptname};
        foreach my $proteinGroupId(keys %$experiment){
            my $proteinGroup = $experiment->{$proteinGroupId};
            my $ratios = $proteinGroup->{'Ratio H/L'};
            my @newRatios = ();
            foreach (0..$#$ratios){
                $ratios->[$_] = $ratios->[$_] =~ /^\d+\.?\d*$/
                    ? log($ratios->[$_])/log(2)
                    : '';
            }
        }
    }
    return 1;
}

=head2 filter

returns a set of protein records based on filter parameters...

=head3 options

=over

=item experiment - regular expression to match experiment name

=item proteinGroupId - regular expression to match protein group id 

=item leadingProteins - regular expression to match leading protein ids

=item notLeadingProteins - regular expression to not match leading protein ids

=back

Returns a filtered object of the same type, with relevant flags set (e.g. whether
data has been logged, etc).

Warning, intentionally does not perform a deep clone!

=cut

sub filter {
    my ($o,%opts) = @_;
    # options : 
#    use Data::Dumper;
#    print STDERR 'OPTS: ', Dumper \%opts;
    my $data = $o->{data};
    my $result = {};
    foreach my $experiment(keys %$data){
        if(! exists $opts{experiment} || $experiment =~ /$opts{experiment}/){
            $result->{$experiment} = {};
            my $exptdata = $data->{$experiment};
            foreach my $pgid(keys %$exptdata){
                if(! exists $opts{proteinGroupId} || $pgid =~ /$opts{proteinGroupId}/){
                    my $pgdata = $exptdata->{$pgid};
                    if(! exists $opts{leadingProteins} || $pgdata->{'Leading Proteins'} =~ /$opts{leadingProteins}/){
                        if(! exists $opts{notLeadingProteins} || $pgdata->{'Leading Proteins'} !~ /$opts{notLeadingProteins}/){
                            $result->{$experiment}->{$pgid} = $pgdata;
                        }
                    }
                }
            }
        }
    }
#   print STDERR Dumper $result if $opts{experiment} eq qr/^LCC1.nE.r2$/;
    my $p = $o->new;
    %$p = %$o;
    $p->{data} = $result;
    $o->{lastfiltered} = $p;
    return $p;
}

=head2 replicateMedian

options are passed to filter.

=cut

sub replicateMedian {
    my ($o,%opts) = @_;
    my $f = $o->filter(%opts);
    return $f->median(
        $f->extractColumnValues(
            column => 'Ratio H/L',
            nodup  => 0,
        )
    );
}

=head2 deviations 

returns an hashref with the following keys

=over

=item n - the number of items

=item sd - the standard deviation (from the mean)

=item mad - the median absolute deviation (from the median)

=item sd_via_mad - the standard deviation estimated from the median absolute deviation

=back

=cut

sub deviations {
    my ($o,%opts) = @_;
    # cache
    $o->{cache}->{deviations} = {} unless exists $o->{cache}->{deviations};
    my $cachekey = join('::', map {"$_=$opts{$_}"} sort keys %opts);
   # print STDERR "$cachekey\n";
    return $o->{cache}->{deviations}->{$cachekey} if exists $o->{cache}->{deviations}->{$cachekey};
    ##
    my $f = $o->filter(%opts);
    my @values = $f->extractColumnValues(
            column => 'Ratio H/L',
            nodup  => 0,
    );
    my $n = scalar @values;
    my $d = $n > 1 ? $o->sd(@values) : '';
    $d->{'values'} = \@values;
    $d->{mad} = $n ? $o->mad(@values) : '';
    
    $d->{sd_from_mad} = $d->{sd_via_mad} = $n ? $d->{mad} * 1.4826016694 : '';
    $d->{usv_mad} = $n ? $d->{sd_from_mad} ** 2 : '';
    $d->{median} = $n ? $o->median(@values) : '';
    # I should think about caching here!!!  DONE!
    $o->{cache}->{deviations}->{$cachekey} = $d;
    return $d;
}

=head2 mean

given a list of values, returns the mean

=cut

sub mean {
    my ($o,@values) = @_;
    if(scalar(@values) < 1){ return ''; }
    return $o->sum(@values) / scalar @values;
}

=head2 sd (unbiased standard deviation)

given a list of values, returns a hash with keys mean and sd (standard deviation).

=cut

sub sd {
    my ($o,@values) = @_;
    my $n = scalar(@values);
    my $mean = $n ? $o->mean(@values) : '';
    my $sos = $o->sum(map {($_ - $mean)**2} @values);
    if($n > 1){
        $sos /= ($n-1);
    }
    else {
        $sos = '';
    }
    return {
        sd => sqrt($sos),
        usv => $sos,
        mean => $mean,
        n => $n,
    };
}

=head2 sum

given a list of values, returns the sum

=cut

sub sum {
    my ($o,@values) = @_;
    my $t = 0;
    $t += $_ foreach @values;
    return $t;
}

=head2 mad

given a list of values, returns the median absolute deviation

=cut

sub mad {
    my ($o,@values) = @_;
    if(scalar(@values) < 1){
        return '';
    }
    my $median = $o->median(@values);
    my @ads = map {abs ($_ - $median)} @values;
    return $o->median(@ads);
}

=head2 ttest

Given options, experiment1, experiment2 and optional filters,
returns a hash of statistics...

stats1 and stats2 are hashes of deviations: sd, mad, sd_via_mad, usv, n, values

ttest is hash of Welch's ttest results: t, df, p

ttest_mad is like ttest but based on median and median absolute deviateions.

The p-values are derived using Welch's Ttest and the t-distribution function from 
Statistics::Distributions.

MAD and medians are much more robust to outliers, which are significant in peptide ratios.


=cut

sub ttest {
    my ($o,%opts) = @_;
    # cache
    if($opts{experiment1} gt $opts{experiment2}){ # sort requested expts
        ($opts{experiment1}, $opts{experiment2}) = ($opts{experiment2}, $opts{experiment1});
    }
    $o->{cache}->{ttests} = {} unless exists $o->{cache}->{ttests};
    my $cachekey = join('::', map {"$_=$opts{$_}"} sort keys %opts);
    return $o->{cache}->{ttests}->{$cachekey} if exists $o->{cache}->{ttests}->{$cachekey};
    ##
    $opts{experiment} = $opts{experiment1};
    my $d1 = $o->deviations(%opts);
    $opts{experiment} = $opts{experiment2};
    my $d2 = $o->deviations(%opts);
    my $tt = $o->welchs_ttest(
        mean1 => $d1->{mean},
        mean2 => $d2->{mean},
        usv1  => $d1->{usv},
        usv2  => $d2->{usv},
        n1    => $d1->{n},
        n2    => $d2->{n},
    );
    $tt->{p} = ($d1->{n} && $d2->{n}) ? Statistics::Distributions::tprob(int ($tt->{df}), $tt->{t}) : '';
    my $tm = $o->welchs_ttest(
        mean1 => $d1->{median},
        mean2 => $d2->{median},
        usv1  => $d1->{usv_mad},
        usv2  => $d2->{usv_mad},
        n1    => $d1->{n},
        n2    => $d2->{n},
    );
    $tm->{p} = ($d1->{n} && $d2->{n}) ? Statistics::Distributions::tprob(int ($tm->{df}), $tm->{t}) : '';
    
    my $r =   {
        stats1 => $d1, stats2 => $d2, ttest => $tt, ttest_mad => $tm 
    };
    $o->{cache}->{ttests}->{$cachekey} = $r;
    return $r;
}

=head2 welchs_ttest

performs Welch's ttest, given mean1, mean2, usv1, usv2, n1 and n2 in a hash.

e.g. 

    $o->welchs_ttest( mean1 => 4, mean2 => 3,  # sample mean
                      usv1 => 1,  usv2 => 1.1, # unbiased sample variance (returned as usv from $o->sd
                      n1 => 4,    n2=> 7       # number of observations
                      
also performs Welch-Satterthwaite to calculate degrees of freedom (to look up in t-statistic table)

Returns hashref containing t and df.

=cut

sub welchs_ttest {
    my ($o, %t) = @_;
    my ($x1,$x2,$v1,$v2,$n1,$n2) = map {$t{$_}} qw/mean1 mean2 usv1 usv2 n1 n2/;
    my ($vn1,$vn2) = ($v1/$n1,  $v2/$n2);
    my $t = abs($x1 - $x2) / sqrt( $vn1 + $vn2 );
    my $df = ($vn1 + $vn2)**2 / (  $vn1**2/($n1-1) + $vn2**2/($n2-1)  );
    return {t => $t, df => $df};
}

=head2 replicateMedianSubtractions 

Logs data, if not already done, calculates median for each replicate, and subtracts median from each evidence in that replicate.

=cut

sub replicateMedianSubtractions {
    my ($o, %opts) = @_; # can set filter here
    $o->logRatios();
    foreach my $replicate($o->experiments()){
        my $median = $o->replicateMedian(%opts, experiment=>$replicate);
        my $p = $o->filter(experiment=>$replicate);
        foreach my $pgid(keys %{$p->{data}->{$replicate}}){
            foreach my $i(0.. $#{$p->{data}->{$replicate}->{$pgid}->{'Ratio H/L'}}){
                if($p->{data}->{$replicate}->{$pgid}->{'Ratio H/L'}->[$i] =~ /\d/){
                    $p->{data}->{$replicate}->{$pgid}->{'Ratio H/L'}->[$i] -= $median;
                }
            }
        }
    }
    # i guess we should do something better with generating this status:
    return 1;
}

=head2 median 

given a list of numbers, returns the median... assumes all items are numbers!

=cut

sub median {
    my $o = shift;
    my @list = sort {$a <=> $b} @_;
    my $n = scalar @list;
    if($n % 2){ # remainder on division by two -> it's odd!
        return $list[($n-1)/2]; # index of last over 2, e.g. 21 items, last index 20, return 10.
    }
    else { # it's not odd... so it's even
        return ($list[$n/2 - 1] + $list[$n/2]) / 2; # length over 2 and the same minus 1, e.g. 20 items, we want 9 and 10.  
    }
}


=head2 experimentMaximumPvalue 

=cut

sub experimentMaximumPvalue {
    my ($o,%opts) = @_;
    # run through experiments and collect replicate names for comparisons...
    # this should be filtered for individual proteins using the leadingProteins option.
    my @reps1 = ();
    my @reps2 = ();
    foreach my $rep($o->experiments){
        if($rep =~ /^$opts{experiment1}/){
            push @reps1, $rep;
        }
        if($rep =~ /^$opts{experiment2}/){
            push @reps2, $rep;
        }
    }
    # now there must be enough replicates with enough observations in each...
    $opts{minimum_observations} = 2 unless exists $opts{minimum_observations};
    $opts{minimum_replicates} = 2 unless exists $opts{minimum_replicates};
    my $reps1 = 0;
    my $reps2 = 0;
    foreach my $rep(@reps1){
        my $f = $o->filter(experiment=>$rep, leadingProteins=>$opts{filter});
        my @values = $f->extractColumnValues(column => 'Ratio H/L');
        $reps1 ++ if scalar(@values) > $opts{minimum_observations};
    }
    foreach my $rep(@reps2){
        my $f = $o->filter(experiment=>$rep, leadingProteins=>$opts{filter});
        my @values = $f->extractColumnValues(column => 'Ratio H/L', nodup  => 0);
        $reps2 ++ if scalar(@values) > $opts{minimum_observations};
    }
    return {p_max => -1, p_mad_max => -1} if $reps1 < $opts{minimum_replicates} || $reps2 < $opts{minimum_replicates};
    
    # compare each combination of replicates
    my $p_max = 0;
    my $p_mad_max = 0;
    foreach my $r1(@reps1){
        foreach my $r2(@reps2){
            my $tt = $o->ttest(%opts, experiment1=>$r1, experiment2=>$r2);
            $p_max = $tt->{ttest}->{p} if $tt->{ttest}->{p} > $p_max;
            $p_mad_max = $tt->{ttest_mad}->{p} if $tt->{ttest_mad}->{p} > $p_mad_max;
        }
    }
    # compare experiments overall
    my $tt = $o->ttest(%opts);
    $p_max = $tt->{ttest}->{p} if $tt->{ttest}->{p} > $p_max;
    $p_mad_max = $tt->{ttest_mad}->{p} if $tt->{ttest_mad}->{p} > $p_mad_max;
    
    # report the maxima
    return {p_max=>$p_max, p_mad_max=>$p_mad_max};
}

=head2 fullProteinComparison

Does a full comparison on a particular protein, i.e. compares all pairs of conditions, also does
differential response analysis.  Allows limitation of analysis to proteotypic peptides.

=cut

sub fullProteinComparison {
    my ($o, %opts) = @_;
    # %opts should have our protein listed as "filter"
    my @pairs = $o->pairs();
    my @orths = $o->orthogonals();
    my %results = ();
    foreach my $p(@pairs){
        my ($e1,$e2) = split(/\s+/, $p);
        $results{$p} = $o->experimentMaximumPvalue(%opts, experiment1=>$e1, experiment2=>$e2);
    }
    foreach my $p(@orths){
        my ($e1,$e2,$e3) = split(/\s+/, $p);
        my $r1 = $o->experimentMaximumPvalue(%opts, experiment1=>$e1, experiment2=>$e2);
        my $r2 = $o->experimentMaximumPvalue(%opts, experiment1=>$e1, experiment2=>$e3);
        if($r1->{p_max} < 0 || $r2->{p_max} < 0){
            $r1->{p_max} = -1;
        }
        elsif($r2->{p_max} > $r1->{p_max}) {
            $r1->{p_max} = $r2->{p_max};
        }
        if($r1->{p_mad_max} < 0 || $r2->{p_mad_max} < 0){
            $r1->{p_mad_max} = -1;
        }
        elsif($r2->{p_mad_max} > $r1->{p_mad_max}) {
            $r1->{p_mad_max} = $r2->{p_mad_max};
        }
        $results{$p} = $r1;
    }
    return \%results;
}

=head2 fullComparison

Does a full comparison for each protein.  Returns hash of hashes.

=cut

sub fullComparison {
    my $o = shift;
    my @leadingProteins = $o->getLeadingProteins();
    my %results = ();
    foreach my $lp(@leadingProteins){
        $results{$lp} = $o->fullProteinComparison(filter=>$lp);
    }
    return \%results;
}

=head2 direction

given two values, returns whether the different between first and second is positive or negative

returns '+' or '-'

=cut

sub direction {
    return $_[1] > $_[2] ? '-' : '+';
}

=head2 directionsDisagree

given two directions, which could be '+', '-' or '', returns true if one is '+' and the other is '-'

=cut

sub directionsDisagree {
    return if $_[1] eq '-' && $_[2] eq '+';
    return if $_[1] eq '+' && $_[2] eq '-';
    return 1; # must be the same or one is blank.
}




=head1 AUTHOR

jimi, C<< <j at 0na.me> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-maxquant-evidence-statistics at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-MaxQuant-Evidence-Statistics>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::MaxQuant::Evidence::Statistics


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-MaxQuant-Evidence-Statistics>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-MaxQuant-Evidence-Statistics>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-MaxQuant-Evidence-Statistics>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-MaxQuant-Evidence-Statistics/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 jimi.

This program is released under the following license: artistic2


=cut

1; # End of Bio::MaxQuant::Evidence::Statistics

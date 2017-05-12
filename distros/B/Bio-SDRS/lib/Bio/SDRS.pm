package Bio::SDRS;

use 5.008;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION $AUTOLOAD);
use warnings;
use Carp qw(cluck croak carp);
use POSIX;
use Math::NumberCruncher;
use Statistics::Distributions;

require Exporter;

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration
# use Bio::SDRS ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $AUTOLOAD;

my %component = map { ($_ => 1) } ('MULTIPLE', 'LDOSE', 'HDOSE', 'STEP',
				   'MAXPROC', 'TRIM', 'SIGNIFICANCE', 
				   'TMPDIR', 'DEBUG');

our $VERSION = '0.11';

1;

=head1 NAME

Bio::SDRS - Perl extension for Sigmoidal Dose Response Search, a tool
for characterizing biological responses to compounds.

=head1 SYNOPSIS

  use Bio::SDRS;
  my $sdrs = new Bio::SDRS;

  $sdrs->doses(0.423377, 1.270132, 3.810395, 11.431184, 34.293553,
               102.880658, 308.641975, 925.925926, 2777.777778, 8333.333333,
               25000);
  $sdrs->set_assay('C8-BMS-208882',
	           1.885, 1.82, 2.2, 2.205, 2.78,
                   4.965, 9.21, 31.275, 74.445, 99.03,
                   100);
  $sdrs->calculate;
  foreach my $assay ($sdrs->assays) {
      print "$assay\n";
      foreach my $prop (('MAX', 'MIN', 'LOW', 'HIGH', 'EC50',
		         'PVALUE', 'EC50RANGE', 'PEAK', 'A', 'B',
		         'D', 'FOLD')) {
	  printf "  %s = %s\n", $prop, $sdrs->ec50data($assay, $prop);
      }
      print "\n";
  }

=head2 Constructor

  $obj = new Bio::SDRS;

  # You can also use $obj = Bio::SDRS->new();

=head2 Object Methods

=head3 Input Methods

  $sdrs->multiple([$new_multiple]);
  $sdrs->ldose([$new_ldose]);
  $sdrs->hdose([$new_hdose]);
  $sdrs->step([$new_step]);
  $sdrs->maxproc([$new_maxproc]);
  $sdrs->trim([$new_trim]);
  $sdrs->significance([$new_significance]);
  $sdrs->tmpdir([$new_tmpdir]);
  $sdrs->debug([$new_debug]);
  $sdrs->doses(doses...);
  $sdrs->set_assay(assay, {response}...)

=head3 Output Methods

  $sdrs->assays;
  $sdrs->scandata;
  $sdrs->score_doses;
  $sdrs->sorted_assays_by_dose([$dose]);
  $sdrs->pvalues_by_dose([$dose])
  $sdrs->ec50data([$assay[, $property[, $precision]]]);

=head3 Other Methods

  $sdrs->calculate;

=head1 DESCRIPTION

Bio::SDRS implements the Sigmoidal Dose Response Search of assay responses
described in the paper by

Rui-Ru Ji, Nathan O. Siemers, Lei Ming, Liang Schweizer, and Robert E
Bruccoleri.

The module is implemented using a simple object oriented paradigm
where the object stores all the information needed for a calculation
along with a state variable, C<STATE>. The state variable has three
possible values, C<'setup'>, C<'calculating'> and C<'calculated'>. The
value of C<'setup'> indicates that the object is being setup with
data, and any results in the object are inconsistent with the data.
The value of C<'calculating'> indicates the object's computations are
in progress and tells the code not to delete intermediate files. This
object runs in parallel, and the object destruction code gets called
when each thread exits. Intermediate files must be protected at that
time.  The value of C<'calculated'> indicates that the object's
computational results are consistent with the data, and may be
returned to a calling program.

The C<'calculate'> method is used to update all the calculated values
from the input data. It checks the state variable first, and only does
the calculation if the state is C<'setup'>. Once the calculations are
complete, then the state variable is set to C<'calculated'>. Thus, the
C<calculate> method can be called whenever a calculated value is
needed, and there is no performance penalty.

The module initializes the C<Bio::SDRS> object with a state of
C<'setup'>. Any data input sets the state to C<'setup'>. Any requests
for calculated data, calls C<'calculate'>, which updates the state
variable so futures requests for calculated data return quickly.

B<N.B.> This module uses parallel programming via a fork call to get
high performance.  I<You must close all database connections prior to
calling the C<calculate> method, and reopen them afterwards. In
addition, you must ensure that any automated DESTROY methods take in
account their execution when the child processes terminated.>

=head1 METHODS

The following methods are provided:

=over 4

=cut


=item C<new()>

Creates a new Bio::SDRS object.

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
    $self->_init_data;
    $self->{MULTIPLE} = 1.18;
    $self->{LDOSE} = 0.17;
    $self->{HDOSE} = 30000;
    $self->{STEP} = 60;
    $self->{MAXPROC} = 2;
    $self->{TRIM} = 0.0;
    $self->{SIGNIFICANCE} = 0.05;
    $self->{DEBUG} = 0;
    $self->_init_tmp;
    
    return $self;
}

sub _init_data {
    my $self = shift;
    $self->{STATE} = "setup";
    $self->{DOSES} = [];
    $self->{RESPONSES} = {};
}

sub _init_tmp {
    my $self = shift;
    my $tmp = exists($ENV{TMPDIR}) ? $ENV{TMPDIR} : "/tmp";
    $tmp .= "/sdrs";
    if (exists($ENV{USER})) {
	$tmp .= "." . $ENV{USER};
    }
    $tmp .= "." . $$;
    $self->{TMPDIR} = $tmp;
    $self->{TMP_CREATED} = 0;
}

sub DESTROY {
    
    # There's an important multiprocessing issue to keep in mind here.
    # When this process forks, this method will be invoked for all the subprocesses.
    # Thus, we need to prevent the deletion of the temporary array until the
    # calculation is completed. That is why there is a check on the STATE.
    
    my $self = shift;
    if (not $self->{DEBUG} and
        $self->{TMP_CREATED} and
        $self->{STATE} eq 'calculated') {
	&_system_with_check("rm -rf " . $self->{TMPDIR},
			    $self->{DEBUG});
    }
}

# documentation for autoloaded methods goes here.

=item C<multiple([$multiple_value])>

Retrieves the current setting for the C<multiple> value, 
and optionally sets it. This value specifies the multiplicity factor
for increasing the dose in the search. It must be greater than one.

=item C<ldose([$ldose_value])>

Retrieves the current setting for the C<ldose> value, 
and optionally sets it. This value specifies the lowest dose in the search.
It must be greater than zero.

=item C<hdose([$hdose_value])>

Retrieves the current setting for the C<hdose> value, 
and optionally sets it. This value specifies the highest
dose in the search. It must be greater than the ldose value.

=item C<step([$step_value])>

Retrieves the current setting for the C<step> value, and optionally
sets it. This value specifies the maximum change in doses in the
search. In the search process, this module starts at the ldose
value. It tries multiplying the current dose by the C<multiple> value,
but it will only increase the dose by no more than the C<step> value
specified here.  It must be positive.

=item C<maxproc([$maxproc_value])>

Retrieves the current setting for the C<maxproc> value, 
and optionally sets it. This value specifies the maximum number of processes that
can be used for the search. The upper limit is 64 and the lower limit is 1.

=item C<trim([$trim_value])>

Retrieves the current setting for the C<trim> value, and optionally
sets it. This value specifies the trimming factor for the number of
assays. If the C<trim> is 0, then all assays will be used, and if 1,
no assays will be used.  It must be between 0 and 1.

=item C<significance([$significance_value])>

Retrieves the current setting for the C<significance> value, and
optionally sets it. This value specifies the minimum permitted
significance value for the F score cutoff. It must be between zero and
1.

=item C<tmpdir([$tmpdir_value])>

Retrieves the current setting for the C<tmpdir> value, and optionally
sets it. This value specifies the temporary directory where scans of
the dose calculation are written. The default is
/tmp/sdrs.C<user>.C<process_id>.

=item C<debug([$debug_value])>

Retrieves the current setting for the C<debug> variable, and
optionally sets it. This value specifies whether debugging information
is printed and if the temporary directory (see above) is deleted after
execution of this module.

=cut

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self);
    my $pkg = __PACKAGE__;
    my ($pos, $new_val);

    croak "$self is not an object\n" if not $type;
    croak "$pkg AUTOLOAD function fails on $type\n"
	if $type !~ m/^$pkg$/;
    my $name = uc($AUTOLOAD);
    $name =~ s/^.*:://;
    if (not exists($component{$name})) {
	croak "$name is not a valid method for $type.\n";
    }
    elsif (not exists($self->{$name})) {
	croak "$name is not a valid method for $type\n";
    }
    elsif (defined $_[0]) {
	$self->{$name} = shift;
	$self->{STATE} = "setup";
    }
    if ($name eq "MULTIPLE" and
	$self->{MULTIPLE} <= 1.0) {
	croak "multiple parameter must be greater than 1.\n";
    }
    if ($name eq "LDOSE" and
	$self->{LDOSE} <= 0.0) {
	croak "ldose parameter must be positive.\n";
    }
    if ($name eq "HDOSE" and
	$self->{HDOSE} <= $self->{LDOSE}) {
	croak "hdose parameter must be greater than the ldose parameter.\n";
    }
    if ($name eq "STEP" and
	$self->{STEP} <= 0.0) {
	croak "step parameter must be positive.\n";
    }
    if ($name eq "MAXPROC" and
	($self->{MAXPROC} > 64 or $self->{MAXPROC} < 1)) {
	croak "maxproc parameter must be between 1 and 64.\n";
    }
    if ($name eq "TRIM" and
	($self->{TRIM} < 0.0 or
	 $self->{TRIM} > 1.0)) {
	croak "trim parameter must be between 0 and 1, inclusive\n";
    }
    if ($name eq "SIGNIFICANCE" and
	($self->{SIGNIFICANCE} <= 0.0 or
	 $self->{SIGNIFICANCE} >= 1.0)) {
	croak "trim parameter must be between 0 and 1, exclusive\n";
    }
    return $self->{$name};
}

=item C<doses($dose1, $dose2, ...)>

Specify the list of compound doses used in the all the assays in the
experiment. The doses must be in numerical order, from smallest to
largest.

=cut

sub doses {
    my $self = shift;
    if (scalar(@_) == 0) {
	return @{$self->{DOSES}};
    }
    else {
	$self->_init_data;
	my $dose1 = shift;
	push(@{$self->{DOSES}}, $dose1);
	foreach my $dose (@_) {
	    if ($dose < $dose1) {
		croak "Doses not in order. Current dose is $dose, and previous does is $dose1\n";
	    }
	    push(@{$self->{DOSES}}, $dose);
	    $dose1 = $dose;
	}
	$self->{STATE} = "setup";
    }
}

=item C<set_assay($assay_name, $response1, ...)>

Adds an assay to the list to be searched over. Each response in the
list corresponds to the doses specified in the C<doses> method. The
number must match, and they must be in numerical order, from smallest
to largest.

=cut

sub set_assay {
    my $self = shift;
    my $assay = shift;

    $self->{STATE} = "setup";
    if (exists($self->{RESPONSES}->{$assay})) {
	croak "Duplicate assay ($assay) response specified.\n";
    }
    $self->{RESPONSES}->{$assay} = [ @_ ];
    if (scalar(@{$self->{DOSES}}) == 0) {
	croak "You must call the doses method before calling the set_assay method.\n";
    }
    my $nresp = scalar(@{$self->{RESPONSES}->{$assay}});
    my $ndoses = scalar(@{$self->{DOSES}});
    if ($nresp != $ndoses) {
	croak "The number of assay responses ($nresp) does not equal the number of doses ($ndoses)\n";
    }
}

=item C<assays()>

Return the list of assay names;

=cut
    
sub assays {
    my $self = shift;
    return keys %{$self->{RESPONSES}};
}

=item C<calculate()>

Perform the SDRS calculation.

=cut

sub calculate {
    my $self = shift;
    return if $self->{STATE} eq 'calculated';
    $self->_make_tmp;
    $self->{STATE} = "calculating";
    #
    # Calculate F Test degrees of freedom.
    #
    my $ndoses = scalar(@{$self->{DOSES}});
    my $p = 4;	#number of parameters
    $self->{FDISTR_N} = $p - 1;
    $self->{FDISTR_M} = $ndoses - $p;
    $self->{CUTOFF} = Statistics::Distributions::fdistr($self->{FDISTR_N},
							$self->{FDISTR_M},
							$self->{SIGNIFICANCE});

    my $count = scalar(keys %{$self->{RESPONSES}});
    foreach my $assay (keys %{$self->{RESPONSES}}) {
	my @data = @{$self->{RESPONSES}->{$assay}};
	my ($max, $min) = Math::NumberCruncher::Range(\@data);
	$self->{MAX}->{$assay} = $max;
	$self->{MIN}->{$assay} = $min;
	my $value = _compute_sst(\@data);	#total sum of squares
	$self->_define_ab_boundary($assay, \@data);
	$self->{SST}->{$assay} = $value;
	$self->{VALUES}->{$assay} = \@data;
    }
    my $assayNum = int($count * (1 - $self->{TRIM}));
    my %expressedAssays;
    $count = 0;
    foreach my $g (sort {$self->{MAX}->{$b} <=> $self->{MAX}->{$a}} (keys %{$self->{MAX}})) {
	last if ($count >= $assayNum);
	$expressedAssays{$g} = 1;
	$count++;
    }

    my (%pvalues, %sortedprobes, $pid, @pids, $file, $iproc, $err);
    my $tmpdir = $self->{TMPDIR};
    for ($iproc = 0; $iproc < $self->{MAXPROC}; $iproc++) {
	if ($pid = fork) {
	    print STDERR "Process $pid forked.\n" if $self->{DEBUG};
	    push @pids, $pid;
	}
	elsif (defined $pid) {
	    sleep $iproc;
	    $file = "$tmpdir/sdrs.out.$iproc";
	    open (ECOUT, ">$file") || die "can not open EC50 output file: $!\n";
	    #
	    # The following statement causes the system to write each output line
	    # to disk immediately, rather than waiting for a buffer to fill.
	    #
	    select((select(ECOUT), $| = 1)[$[]); # Change buffering to line by line.
	    my $last_dose = $self->{LDOSE};
	    my $icount = 0;
	    for (my $dose = $self->{LDOSE};
		 $dose < $self->{HDOSE} * $self->{MULTIPLE};
		 $dose *= $self->{MULTIPLE}) {
		if ($dose - $last_dose > $self->{STEP}) {
		    $dose = $last_dose + $self->{STEP};
		}
		if (($icount++ % $self->{MAXPROC}) == $iproc) {
		    print ECOUT $self->_scan_dose_point($dose);
		}
		$last_dose = $dose;
	    }
	    close ECOUT;
	    exit 0;
	}
	else {
	    die "Can't fork: $!\n";
	}
    }
    $err = 0;
    foreach $pid (@pids) {
	waitpid($pid, 0);
	if ($? != 0) {
	    print STDERR "Process $pid return status was $?\n";
	    $err = 1;
	}
    }
    
    # Now collect all the outputs together.
    %{$self->{GSCORE}} = ();
    %{$self->{GPARAM}} = ();
    %{$self->{FSCORES}} = ();
    my $multiple = $self->{MULTIPLE};
    my $step = $self->{STEP};
    @{$self->{SCANDATA}} = ();
    
    for ($iproc = 0; $iproc < $self->{MAXPROC}; $iproc++) {
	my $infile = "$tmpdir/sdrs.out.$iproc";
	open (IN, "<$infile") || die "can not open input file $infile: $!\n";
	while (<IN>) {
	    push (@{$self->{SCANDATA}}, $_);
	    chomp;
	    my ($assay, $dose, $fscore, $a, $b, $d) = split (/\t/, $_);
	    $self->{GSCORE}->{$assay}->{$dose} = $fscore;
	    $self->{GPARAM}->{$assay}->{$dose} = "$a:$b:$d";
	    if (defined $expressedAssays{$assay}) {
		$self->{FSCORES}->{$dose}->{$assay} = $fscore;
	    }
	}
	close IN;
    }
    
    #sort probesets based on F scores for every selected doses, output P values for FDR calculation
    %{$self->{SORTED_DATA}} = ();
    %{$self->{PVAL_DATA}} = ();
    foreach my $dose (keys %{$self->{FSCORES}}) {
	my %fs = %{$self->{FSCORES}->{$dose}};
	foreach my $assay (sort {$fs{$b} <=> $fs{$a} || $a cmp $b } (keys %fs)) {
	    push (@{$self->{SORTED_DATA}->{$dose}}, $assay);
	    my $pvalue;
	    if ($fs{$assay} < 0) {
		$pvalue = 1.0;
	    }
	    else {
		$pvalue = Statistics::Distributions::fprob($self->{FDISTR_N},
							   $self->{FDISTR_M},
							   $fs{$assay});
	    }
	    push (@{$self->{PVAL_DATA}->{$dose}}, $pvalue);
	}
    }
    
    #calculates EC50 for every probeset
    %{$self->{EC50DATA}} = ();
    foreach my $assay (keys %{$self->{GPARAM}}) {
	my (%fscore, %param);
	%fscore = %{$self->{GSCORE}->{$assay}};
	%param = %{$self->{GPARAM}->{$assay}};

	my @sorted_list = sort {$a<=>$b} (values %fscore);
	my $max = pop @sorted_list;
	my $min = shift @sorted_list;
	@sorted_list = sort {$fscore{$a}<=>$fscore{$b}} (keys %fscore);
	my $ec50 = pop @sorted_list;    #highest f score
	my ($range, $high, $low, $peak, $ec50range, $fold);
	if ($max >= $self->{CUTOFF}) {
	    $range = $self->_find_ec50_range(\%fscore, $ec50);
	    ($high, $low, $peak) = split (/\-/, $range);
	    $ec50range = $high - $low;
	} else {
	    $high = $low = $peak = $ec50range = '';
	}
	my $pvalue;
	if ($max <= 0.0) {
	    $pvalue = 1.0;
	}
	else {
	    $pvalue = Statistics::Distributions::fprob($self->{FDISTR_N},
						       $self->{FDISTR_M},
						       $max);
	}
	my ($a, $b, $d) = split (/\:/, $param{$ec50});
	if ($d >= 0) {
	    if ($a != 0) {
		$fold = -($b/$a);
	    } else {
		$fold = -99999;
	    }
	} else {
	    if ($a != 0) {
		$fold = $b/$a;
	    } else {
		$fold = 99999;
	    }
	}
	$self->{EC50DATA}->{$assay} = { MAX => $max,
					MIN => $min,
					LOW => $low,
					HIGH => $high,
					EC50 => $ec50,
					PVALUE => $pvalue,
					EC50RANGE => $ec50range,
					PEAK => $peak,
					A => $a,
					B => $b,
					D => $d,
					FOLD => $fold };
    }
    $self->{STATE} = "calculated";
}

=item C<scandata()>

Return the complete list of scan data used in the SDRS calculation. This is just an array of lines containing the values of the EC50 calculations.

=cut

sub scandata {
    my $self = shift;
    return @{$self->{SCANDATA}};
}

=item C<score_doses()>

Return the list of doses used in the SDRS calculation that can be
used as arguments for assays and pvalues.

=cut

sub score_doses {
    my $self = shift;
    return keys %{$self->{FSCORES}};
}

=item C<sorted_assays_by_dose([$dose])>

Return a list of assays for each dose in $dose sorted by F-score.

=cut
    
sub sorted_assays_by_dose {
    my $self = shift;
    my $dose = shift;
    if ($self->{STATE} ne 'calculated') {
	$self->calculate;
    }

    if (not defined $dose) {
	return %{$self->{SORTED_DATA}};
    }
    else {
	if (not exists($self->{SORTED_DATA}->{$dose})) {
	    carp "Sorted assays by dose = $dose does not exist.\n";
	    return undef;
	}
	else {
	    return @{$self->{SORTED_DATA}->{$dose}};
	}
    }
}
    

=item C<pvalues_by_dose([$dose])>

Return a list of P values for the assays returned by sorted_assays_by_dose
for each dose in $dose sorted by F-score.

=cut
    
sub pvalues_by_dose {
    my $self = shift;
    my $dose = shift;
    if ($self->{STATE} ne 'calculated') {
	$self->calculate;
    }

    if (not defined $dose) {
	return %{$self->{PVAL_DATA}};
    }
    else {
	if (not exists($self->{PVAL_DATA}->{$dose})) {
	    carp "P values by dose = $dose does not exist.\n";
	    return undef;
	}
	else {
	    return @{$self->{PVAL_DATA}->{$dose}};
	}
    }
}

=item C<ec50data([$assay[, $property[, $precision]]])>

Returns EC50 data for the calculation. If no arguments are specified,
then the internal hash for the EC50 calculation are returned. If just
an C<$assay> is specified, then the internal hash for all the EC50
values associated with that C<$assay> is returned. If an C<$assay> and
C<$property> are specified, then the property for that assay is
returned. If the C<$precision> operand is specified, then it controls
how many digits of precision are returned for the value.

Here is the list of possible properties.

  MAX         Maximum F score
  MIN         Minimum F score. If this property is negative, then an error
              was encountered in the calculation of F scores. This is likely due
              insufficient range in the responses.
  LOW         Lower bound of 95% confidence interval for the estimated EC50. 
  HIGH        Upper bound of 95% confidence interval for the estimated EC50.
  EC50        Estimated EC50.
  PVALUE      P value of the best fitting model
  EC50RANGE   range of 95% confidence interval for the estimated EC50.
  PEAK        Number of peaks in the F scores at search doses across experimental dose range.
  A           Estimated value for A in the best model.
  B           Estimated value for B in the best model.
  D           Estimated value for D in the best model.
  FOLD        Ratio of B/A or 99999.0. If A == 0. Positive if D < 0, negative otherwise.

=cut

sub ec50data {
    my $self = shift;
    my $assay = shift;
    my $property = shift;
    my $precision = shift;

    $precision = 6 if not defined $precision;
    if ($self->{STATE} ne 'calculated') {
	$self->calculate;
    }
    if (not defined $assay) {
	return %{$self->{EC50DATA}};
    }
    else {
	if (not exists($self->{EC50DATA}->{$assay})) {
	    carp "EC50 data for $assay does not exist.\n";
	    return undef;
	}
	my $assaydata = $self->{EC50DATA}->{$assay};
	if (not defined $property) {
	    return %{$self->{EC50DATA}->{$assay}};
	}
	else {
	    if (not exists($assaydata->{$property})) {
		carp "EC50 data for property $property for assay $assay does not exist.\n";
		return undef;
	    }
	    else {
		my $ret = $assaydata->{$property};
		if ($ret ne "" and $ret != int($ret)) {
		    $ret = sprintf("%.${precision}g", $ret) + 0.0;
		}
		return $ret;
	    }
	}
    }
}

sub _make_tmp {
    my $self = shift;
    if (-d $self->{TMPDIR} and -w $self->{TMPDIR}) {
	return;
    }
    if (-d $self->{TMPDIR}) {
	croak "Unable to write " . $self->{TMPDIR} . "\n";
    }
    if (-w $self->{TMPDIR}) {
	unlink($self->{TMPDIR}) ||
	    croak "Unable to delete " . $self->{TMPDIR} . "\n";
    }
    &_system_with_check("mkdir -p " . $self->{TMPDIR}, 
		       $self->{DEBUG});
    $self->{TMP_CREATED} = 1;
}

sub _find_ec50_range {
    my $self = shift;
    my ($scores, $ec50) = @_;
    my @range = ();
    my $off_flag = 1;
    my $peak = 0;
    my $current;
    my $seen = 0;
    my $boundary;
    foreach my $dose (sort {$a<=>$b} keys %$scores) {
	$current = $$scores{$dose};
	$seen = 1 if ($dose == $ec50);
	if ($current >= $self->{CUTOFF}) {
	    push @range, $dose;
	    $off_flag = 0 if ($off_flag == 1);
	} else {
	    if ($seen == 1) {
		$boundary = _find_boundary(\@range);
		$seen = 0;
	    }
	    @range = ();
	    if ($off_flag == 0) {
		$off_flag = 1;
		$peak++;
	    }
	}
    }
    $boundary = _find_boundary(\@range) if ($seen == 1);
    $peak++ if ($current >= $self->{CUTOFF});
    
    return "$boundary-$peak";
}
 
sub _find_boundary {
    my $range = shift;
    my ($high, $low);

    if (@$range >= 2) {
	$low = shift @$range;
	$high = pop @$range;
    } else {
	$low = shift @$range;
	$high = $low;
    }
    return "$high-$low";
}

sub _scan_dose_point {
    my $self = shift;
    my $dose = shift;
    my $ecstring = '';
    my $m = $self->{FDISTR_M};
    my $n = $self->{FDISTR_N};
    foreach my $assay (keys %{$self->{VALUES}}) {
	my ($al, $ah, $astep) = split (/\:/, $self->{ARANGE}->{$assay});
	my ($bl, $bh, $bstep) = split (/\:/, $self->{BRANGE}->{$assay});
	my ($a, $b, $d, $best_sse) = _compute_best_sse($al, $ah, $astep,
						       $bl, $bh, $bstep,
						       $dose,
						       $self->{VALUES}->{$assay},
						       $self->{DOSES});
	if ($best_sse == 0 or $n == 0) {
	    carp sprintf("best_sse($best_sse) = 0 or n($n) = 0 for $assay. arange = %s  brange = %s\n",
			 $self->{ARANGE}->{$assay},
			 $self->{BRANGE}->{$assay});
	    $ecstring .= "$assay\t" .
		sprintf("%.5f", $dose) .
		    "\t-1\t-1\t-1\t-1\n";
	}
	else {
	    my $f_score = ($self->{SST}->{$assay} - $best_sse) * $m / ($best_sse * $n);
	    $f_score = sprintf("%.3f", $f_score);
	    $a = sprintf("%.3f", $a);
	    $b = sprintf("%.3f", $b);
	    $d = sprintf("%.3f", $d);
	    $ecstring .= "$assay\t" .
		sprintf("%.5f", $dose) .
		    "\t$f_score\t$a\t$b\t$d\n";
	}
    }
    return $ecstring;
}

sub _define_ab_boundary {
    my $self = shift;
    my ($assay, $data) = @_;
    my @sorted = sort {$a<=>$b} @$data;
    my @sorted_copy = @sorted;
    my @brange = splice (@sorted, $#sorted-5, 6);
    $self->_find_step($assay, 'b', \@brange);
    my @arange = splice (@sorted_copy, 0, 6);
    $self->_find_step($assay, 'a', \@arange);
}

sub _find_step {

    my $self = shift;
    my ($assay, $pam, $data) = @_;
    my $stdev = Math::NumberCruncher::StandardDeviation($data);
    my $mean = Math::NumberCruncher::Mean($data);
    my $cutoff = $mean / 10;
    $stdev = $cutoff if ($stdev eq 'NaN' || $stdev < $cutoff);
    my ($l, $h, $step);
    $step = $stdev / 2.5;
    $step = sprintf("%.3f", $step);
    if ($step == 0.0) {
	carp "Data range too small for $assay -- step size raised to 0.001.\n";
	$step = "0.001";
    }
    if ($pam eq 'a') {
	$h = $mean + 2.3*$stdev;
	$l = $mean - 2*$stdev;
	$l = $self->{MIN}->{$assay} if ($l <= 0);
	$h = sprintf("%.3f", $h);
	$l = sprintf("%.3f", $l);
	$self->{ARANGE}->{$assay} = "$l:$h:$step";
    } elsif ($pam eq 'b') {
	$h = $mean + 2*$stdev;
	$l = $mean - 2.3*$stdev;
	$l = $self->{MIN}->{$assay} if ($l <= 0);
	$h = sprintf("%.3f", $h);
	$l = sprintf("%.3f", $l);
	$self->{BRANGE}->{$assay} = "$l:$h:$step";
    }
}

sub _compute_sst {
    my $data = shift;
    my $sst = 0;
    my $mean = Math::NumberCruncher::Mean($data);
    
    foreach my $data (@$data) {
	$sst += ($data - $mean)**2;
    }
    return $sst;
}

sub _system_with_check {

    my $command = shift;
    my $echo = shift;

    if (defined $echo and $echo) {
	&_dated_mesg($command);
    }
    my $status = system("$command");
    if ($status != 0) {
	croak "Shell command: $command returned $status error code.\n";
    }
}

sub _dated_mesg {

    # Print a dated message to STDERR
    my $mesg = shift;

    my $date = &_date;
    if (substr($mesg, -1, 1) ne "\n") {
	$mesg .= "\n";
    }
    print STDERR "At $date: $mesg";
}

sub _date {
    return strftime("%a %b %d %T %Z %Y", localtime);
}

=back

=head1 SEE ALSO

sdrs.pl

=head1 AUTHORS

 Ruiru Ji <ruiruji@gmail.com>
 Nathan O. Siemers <nathan.siemers@bms.com>
 Lei Ming <lei.ming@bms.com>
 Liang Schweizer <liang.schweizer@bms.com>
 Robert Bruccoleri <bruc@acm.org>

=cut

    
use Inline C => <<'END_OF_C_CODE', NAME => 'Bio::SDRS::FastSSE'; 

void extract_double_array(SV *arrayp,
			  double a[],
			  I32 asize,
			  I32 *limitp);

void _compute_best_sse(double al,
                      double ah,
                      double astep,
		      double bl,
		      double bh,
		      double bstep,
		      double dose,
		      SV* valuesp,
		      SV* dosesp)
{
    double a, b, d, diff, sse, tmp, y_hat, d2;
    double a_best, b_best, d_best, sse_best;
    SV* param_ret;
    SV* best_sse_ret;
    I32 count = 0;
    I32 i;
    I32 vlimit, dlimit;
#define DOSE_SIZE 100
    double doses[DOSE_SIZE];
    double values[DOSE_SIZE];
    Inline_Stack_Vars;

    extract_double_array(valuesp, values, DOSE_SIZE, &vlimit);
    extract_double_array(dosesp, doses, DOSE_SIZE, &dlimit);
    if (vlimit != dlimit) {
	fprintf(stderr, "Error in compute_best_sse: limit mismatch. vlimit = %d  dlimit = %s\n",
		vlimit, dlimit);
	exit(1);
    }
    
    for (a = al; a < ah; a += astep) {
//	fprintf(stderr, "a = %14.10g\n", a);
	for (b = bh; b > bl && a <= b; b -= bstep) {
//	    fprintf(stderr, "b = %14.10g\n", b);
	    diff = b - a;
	    for (d = -6; d < 6.3; d += 0.3) {
//  	        fprintf(stderr, "d = %14.10g  dlimit = %d\n", d, dlimit);
		sse = 0;
		for (i = 0; i <= dlimit; i++) {
		    tmp = doses[i] / dose;
		    tmp = pow(tmp, d);
		    y_hat = a + diff / (1 + tmp);
		    d2 = (y_hat - values[i]);
		    sse += d2 * d2;
		}
		if (++count == 1 || sse < sse_best) {
		    a_best = a;
		    b_best = b;
		    d_best = d;
		    sse_best = sse;
		}
	    }
	}
    }
    Inline_Stack_Reset;
    Inline_Stack_Push(sv_2mortal(newSVnv(a_best)));
    Inline_Stack_Push(sv_2mortal(newSVnv(b_best)));
    Inline_Stack_Push(sv_2mortal(newSVnv(d_best)));
    Inline_Stack_Push(sv_2mortal(newSVnv(sse_best)));
    Inline_Stack_Done;
}

void extract_double_array(SV *arrayp,
			  double a[],
			  I32 asize,
			  I32 *limitp)
/*
 * Extract the elements of the Perl array, pointed to by arrayp,
 * into the C array a. The size of a is asize, and the code will check
 * for overflow. The limiting subscript for arrayp will be returned in
 * *limitp. */

{
    AV* array;
    I32 limit, i;

    array = SvRV(arrayp);
    limit = av_len(array);
    if (limit+1 > asize) {
	fprintf(stderr,
		"extract_double_array: Perl array is too big. limit = %d  asize = %d\n",
		limit, asize);
	exit(1);
    }
    for (i = 0; i <= limit; i++) {
	SV *element, **elementp;
	elementp = av_fetch(array, i, 0);
	element = *elementp;
	a[i] = SvNV(element);
    }
    *limitp = limit;
}

END_OF_C_CODE

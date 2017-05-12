#!/usr/bin/perl -w
######################################################
# history.pl
######################################################
# Author: liangc 
# $Id: history.pl,v 1.8 2009/08/13 20:42:58 astoltzfus Exp $

# create ancestral intron states based on an alignment and tree
# in a nexus file. The BUGS program will run many times with small
# number of generations to find those can converge (to global optimum)
# and then run one with a large number of generations (convergence)
# the ancestral states will be computed from the average value of 
# those generations and write back to file in history block

use strict;
use Pod::Usage;
use Data::Dumper;
use Getopt::Long;
use Bio::NEXUS;

my $version = "\$Revision\$";

Getopt::Long::Configure("bundling"); # for short options bundling
my %opts = ();
GetOptions(\%opts, 'help|h', 'man', 'v', 'l=s','n=s', 'b=s', 'm=s', 'debug') or pod2usage(2);
if ( $opts{'man'} ) { pod2usage(-exitval => 0, -verbose => 2) } 
if ( $opts{'help'} ) { pod2usage(1) }
if ($opts{v}) {
    print "history.pl $version\n"; exit;
}

my $infile = shift;
unless ($infile) {die "history.pl [options] <filename>\n";}
my $burnin = defined $opts{b} ? $opts{b} : 1000; # burnin generation #
my $monitor = $opts{m} || 1000; # monitor #
my $good_num = $opts{n} || 3; # the number of files to be selected
my $runlevel = defined $opts{l} ? $opts{l} : 0;
my $debug = $opts{debug};

my $stem = $infile;
$stem =~ s/^(.+).nex$/$1/;
$stem =~ s/^(.+\/)?([^\/]+)$/$2/;
#print "$1 $stem\n"; exit;
$stem =~ s/[^a-zA-Z0-9.]/\./g; # remove non alphanumeric characters in name
my $dir = "$stem.dir";
system "mkdir $dir";
system "cp $infile $dir/$stem.nex";
$infile = "$stem.nex";
chdir "$dir";

my @data; # all monitored data in file
my ($llike, $alpha, $beta, $r, $k, @node);
my $maxlike = -1.E+20;
my $minfile = 0;
my $maxfile = 2;
my @like;
my $names; # name of each node in the index file

#print "$runlevel--$burnin--$monitor\n";exit;
if ($runlevel == 0) {
    exec_bugs();
    re_exec_bugs($minfile, $maxfile, 50, 50);
    rename "$stem.$maxfile.bug", "$stem.0.bug";
}
if ($runlevel < 2) {
    re_exec_bugs(0, 0, $burnin, $monitor);
}else {
    read_bugs_out("$stem.0.bugs1");
}
write_data(0);
modify_nexus();

exit;

# select runs not trapped locally
sub exec_bugs {
    $maxfile = 0;
    for (my $i = 0; $i < 20; $i++) {
	system ("bugs.pl $stem.$i $infile > $stem.$i.bug") == 0 or die "BUGS execution error!\n";
	system "bugs <$stem.$i.cmd >$stem.$i.bugs.log";
	read_bugs_out("bugs1");
	print "$i: ", $llike->[0], "\n" if $debug;
	if ( $alpha->[1] != 0 && abs($alpha->[0]/$alpha->[1]) < 1000 &&
	    $beta->[1] != 0 && abs($beta->[0]/$beta->[1]) < 1000 &&
	    $r->[1] != 0 && abs($r->[0]/$r->[1]) < 1000 &&
	    $k->[1] != 0 && abs($k->[0]/$k->[1]) < 1000 ) {
	    print "   move to $stem.$maxfile ", $llike->[0], "\n" if $debug;
	    rename "$stem.$i.bug", "$stem.$maxfile.bug";
	    $like[$maxfile] = $llike->[0];
	    $maxfile++;
	}
	if ($maxfile == $good_num) {last;}
    }
    if (--$maxfile == -1) {print "Error for file: $infile; no good starting was found\n"; exit; }
    print join(' ', @like), "\n" if $debug;
}

# select a run with maximum mean probability
sub re_exec_bugs {
    my ($bugs1, $bugs2, $burnin, $monitor) = @_;
#    if ($bugs1 == $bugs2) { die "-----Error: $stem\n"; }
#    my ($nchar, $nnodes) = read_node_num("$stem.$bugs1.bug");
#    $burnin = 1000; #int(sqrt(sqrt(sqrt($nchar*$nnodes+1))))*1000;
#    print "burnin: $burnin\n";
    foreach my $i ($bugs1..$bugs2) {
	print "$i running...\n" if $debug;
	system ("bugs.cmd.pl $stem.$i $burnin $monitor") == 0 or die "BUGS error: $infile\n";
	system "bugs <$stem.$i.cmd >$stem.$i.bugs.log";
	rename "bugs.ind", "$stem.$i.bugs.ind";
	rename "bugs.out", "$stem.$i.bugs.out";
	rename "bugs1.ind", "$stem.$i.bugs1.ind";
	rename "bugs1.out", "$stem.$i.bugs1.out";    
	read_bugs_out("$stem.$i.bugs1");
	select_file($i);
	$like[$i] = $llike->[0];
    }
    print join(' ', @like), "\n" if $debug;
}

# select the run to be used
sub select_file {
    my $i = shift;
    if ($llike->[0] > $maxlike) { $maxlike = $llike->[0]; $maxfile = $i; }
}

# read .out file
sub read_bugs_out {
    my $bugstem = shift;
    read_ind($bugstem);
    open (INFILE, "$bugstem.out") or die "Error open file\n";
	
    for (my $i = 1; my $line = <INFILE>; $i++) {
#	    print "$line\n"; exit;
	$line =~ s/^\s+//;
	${$data[$i]} = [split /\s+/, $line];
    }
    close (INFILE);
}

#read index file
sub read_ind {
    my $bugstem = shift;
    open(IND, "$bugstem.ind");
    while (my $line = <IND>) {
	$line =~ s/^s+//;
	my ($v1, $v2) = split /\s+/, $line;
	if (!$v1) { print "$line, -- $v1, $v2\n"; exit;}
	if ($v1 eq 'llike') {
	    $data[$v2] = \$llike;
	}elsif ($v1 eq 'r') {
	    $data[$v2] = \$r;
	}elsif ($v1 eq 'k') {
	    $data[$v2] = \$k;
	}elsif ($v1 eq 'alpha') {
	    $data[$v2] = \$alpha;
	}elsif ($v1 eq 'beta') {
	    $data[$v2] = \$beta;
	}elsif ($v1 =~ /^root/) {
	    my $name = $v1;
	    $name =~ /\[(\d+)\]/;
#	    print "$1\n";
	    $data[$v2] = \$node[0][$1]; # [intron#][first node--root], 
	}elsif ($v1 =~ /^node/) {
	    my $name = $v1;
	    $name =~ /\[(\d+),(\d+)\]/;
#	    print "$2, $1\n";
	    $data[$v2] = \$node[$1][$2]; # [intron#][other internal node]
	}
    }
    close(IND);
}

# write bugs out to a file
sub write_data {
    my ($file) = @_;
#    print &Dumper($llike); exit;
#    print scalar @{$node[1]}, "\n"; exit;
#    print &Dumper($node[0]);exit;

    open(OUTFILE, ">$stem.node.bugs.out");

    my ($nnodes, $nchar) = read_node_num("$stem.$file.bug");
    print OUTFILE "inodes\t", $nnodes, "\n";
    print OUTFILE "characters\t", $nchar, "\n";

    my @llike = map {$_->[0]} @{[$llike]};
    my @r = map {$_->[0]} @{[$r]};
    my @k = map {$_->[0]} @{[$k]};
    my @alpha = map {$_->[0]} @{[$alpha]};
    my @beta = map {$_->[0]} @{[$beta]};
    print OUTFILE "loglikelihood\t", join(' ', @llike), "\n";
    print OUTFILE "alpha\t", join(' ', @alpha), "\n";
    print OUTFILE "beta\t", join(' ', @beta), "\n";
    print OUTFILE "r\t", join(' ', @r), "\n";
    print OUTFILE "k\t", join(' ', @k), "\n";

    $names = read_node_name("$stem.$file.log");
    for (my $i = 0; $i < @node; $i++) {
	print OUTFILE $names->{$i}, "\t";
	for (my $j = 1; $j < @{$node[0]}; $j++) {
	    printf OUTFILE "%4.3f\t", $node[$i][$j][0]-1;
	}
	print OUTFILE "\n";
    }
    close(OUTFILE);
}

# convert internal node names used in bugs run
sub read_node_name {
    my $file = shift;
    open(LOG, "$file");
    my %names;
    $names{0} = 'root';
    while (<LOG>) {
	if (/^\s+$/) {last;}
    }
    while (<LOG>) {
	/(\d+):\s*(\S+)/;
	$names{$1} = $2;
    }
    close(LOG);
#    print &Dumper(%names);exit;
    return \%names;
}

# find out the number of parameters based on tree size and character num
sub read_node_num {
    my $file = shift;
    open(BUG, "$file");
    my ($nchar, $nnodes);
    while (<BUG>) {
	if (/nChar = (\d+)/) {$nchar = $1;}
	elsif (/nNode = (\d+)/) {$nnodes = $1+1;}
	elsif ($nchar && $nnodes) {last;}
    }
    close(BUG);
    return ($nnodes, $nchar);
}

# modifying input nexus file (with new name)
sub modify_nexus {
    my $nexus = new Bio::NEXUS($infile);
    create_history_block($nexus, \@node);
    modify_span_block($nexus);
    $nexus->write("../${stem}.h.nex");
}

# create history block based on BUGS output
sub create_history_block {
    my ($nexus, $nodes) = @_;
    my $otuset = $nexus->get_block('characters', 'intron')->get_otuset()->clone();

    my @otus;
    for (my $i = 0; $i < @$nodes; $i++) {
	my @seq;
	for (my $j = 1; $j < @{$nodes->[0]}; $j++) {
	    push @seq, [sprintf("%4.3f", 2-$nodes->[$i][$j][0]), (sprintf"%4.3f", $nodes->[$i][$j][0]-1)];
	}
	push @otus, new Bio::NEXUS::TaxUnit($names->{$i}, \@seq);
    }
#    @otus = sort { $a->get_name cmp $b->get_name } @otus;
    my $history = new Bio::NEXUS::HistoryBlock('History');
    foreach my $otu (@otus) {
	$otuset->add_otu($otu);
    }
    $history->set_title('intron');
    $history->add_link('taxa', $nexus->get_name);
    $history->set_format($nexus->get_block('characters', 'intron')->get_format());
    $history->set_otuset($otuset);
    $history->add_tree($nexus->get_block("trees")->get_tree);
    $nexus->remove_block('history', 'intron');
    $nexus->add_block($history);
}

# modify span block by adding BUGS parameters
sub modify_span_block {
    my $nexus = shift;
    my %descendant;
    $descendant{program}='BUGS';
    $descendant{version}='unix-0.600';
    my $like = $llike->[0];
    my $a = $alpha->[0];
    my $b = $beta->[0];
    $descendant{parameters}="loglikelihood=$like, alpha=$a, beta=$b, burnin=$burnin, monitor=$monitor";
    my $spanblock = $nexus->get_block("span");
    if (! $spanblock) {
	$spanblock = new Bio::NEXUS::SpanBlock('span'); 
	$spanblock->{method}{ancestral_inference} = \%descendant;
	$nexus->add_block($spanblock);
    }else {
	$spanblock->{method}{descendant} = \%descendant;
    }
}


################# POD Documentation ##################

__END__

=head1 NAME

history.pl

=head1 SYNOPSIS

history.pl [options] <input_file>

  Options:
    --help -h       brief help message
    --man           full documentation
    --debug         output running info
    -n <run-num>           the number of converging initial runs
    -l <running-level>           running level
       0          new run
       1          old run with new number of generations
       2          just retrieve data from existing files
    -b <burin-in> the number of burnin generations
    -m <monitor>  the number of monitoring generations
    -v            print version information and quit

=head1 Description

 create ancestral intron states based on an alignment and tree
 in a nexus file. The BUGS program will run many times with small
 number of generations to find those can converge (to global optimum)
 and then run one with a large number of generations (convergence)
 the ancestral states will be computed from the average value of 
 those generations and write back to file in history block

=head1 REQUIRES

BUGS must be installed for running this program.

=head1 VERSION

$Revision: 1.8 $

=head1 AUTHOR

Chengzhi Liang <liangc@umbi.umd.edu>

=cut

##################### End ##########################



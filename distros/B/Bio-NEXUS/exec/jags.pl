#!/usr/bin/perl -w
# Write BUGS scripts for reconstruction
# Tree has to be bifurcating
# Author:  
# $Date: 2007/02/22 17:46:30 $
# $Revision: 1.2 $

use Data::Dumper;
use Bio::NEXUS;

die "jags.pl <model name> <nexus file (1 data block 1 tree)> [burn-in generations] [monitor generations]\n" unless @ARGV == 2;
my $model = shift;
my $file  = shift;
my $burnin = shift;
unless (defined $burnin) {$burnin = 10;}
my $monitor = shift || 10;

my $nexus = new Bio::NEXUS($file);

my ($n_otu, $n_node, $n_intron);
my %state_otu; # intron states for each otu
my ($root, $nodes, $tree_length);
my $indent_count = 1;
my $indent_size = 4;

foreach my $block ( @{$nexus->get_blocks()} ) {
    my $type = $block->{'type'};
    if (lc $type eq "characters" && (! $block->get_title || $block->get_title =~ m/intron/i )) {
	$n_otu = $block->get_ntax;
	$n_intron = $block->get_nchar;
	foreach my $otu ( @{$block->get_otus()} ) {
	    my @states = @{$otu->get_seq()};
	    foreach (@states) { 
		if ($_ eq '0' || $_ eq '1') {$_ += 1;} 
		else {$_ = 1;}
	    }
	    $state_otu{$otu->get_name()} = \@states;
	}
    }

    if ($type eq "trees") { 
	foreach my $tree ( @{$block->get_trees()} ) {
	    $root = $tree->get_rootnode();
	    $nodes = $tree->node_list();
	    $tree_length = $tree->get_tree_length();
	    last;
	}
    }
}
#print &Dumper($tree_length);exit;
$n_node = @$nodes-$n_otu-1;

print "var lk[nNode,nChar,2], lkroot[nChar,2], otu[nOTU,nChar], p.otu[nOTU,nChar,2], p.root[nChar,2]\n";
print "model {  #$model\n";

#########################
#  for "const":
#########################
#print "const\n";
#print "\tnChar = $n_intron,\n";
#print "\tnOTU = $n_otu,\n";
#print "\tnNode = $n_node;\n";

#########################
#  for "var":
#########################

=ignore

print "var\n";
print "\tr, k,\n";
print "\ta, b, \n";
print "\talpha, beta,\n";
#print "\tg, \n\n";
print "\troot\[nChar\], p\.root\[2\],\n";
print "\tnode\[nNode, nChar\], p\.node\[nNode,2,2\],\n";
print "\totu\[nOTU, nChar\], p\.otu\[nOTU,2,2\],\n";
print "\tb\.otu\[nOTU\], b\.node\[nNode\],\n";
print "\n\tlk\[nOTU+nNode+1, nChar\], llike;\n\n";

=cut

#########################
#  for "data" (S-format)
#########################

#print "data in \"$model.dat\";\n";
#print "inits in \"$model.in\";\n\n";

###############################
#  main loop: transition prob
###############################
my $ex = "1/(1+r)";
my $exp = "1 - exp(-1\*k\*b\.otu\[i\])";
print<<XXX; 
    gain ~ dunif(0,100);
    loss ~ dunif(0,100);
    r <- loss/gain;
XXX

my ( @otu, @node, @b_otu, @b_node, %parent, @dist, @lk );
foreach my $nd (@$nodes) {  # for "var"
	if ($nd eq $root) {
		push @dist, "root\[i\] ~ dcat(p\.root\[\])";
		push @dist, "root\[i\] ~ dcat(p\.root\[\])";
		#push @lk, "log(p.root\[root\[i\]\])"; 
	} elsif ($nd -> is_otu()) {
		push @otu, $nd;
		push @b_otu, sprintf ("%.4f", $nd -> {'length'}); 
		$parent {$nd} = $nd ->{'parent'};
	} else {
		push @node, $nd;
		push @b_node, sprintf ("%.4f", $nd -> {'length'});
		$parent {$nd} = $nd ->{'parent'};
	}
}
#########################
#  main loop: tree 
#########################

my $nodes_index; 
my $otu_count = 1;
my $internal_count = 1;
foreach my $nd (@$nodes) {  # for "var"
	if ($nd->is_otu) {
		$nodes_index->{$nd->get_name} = $otu_count;
		$otu_count++;
	}
}
foreach my $nd (@$nodes) {  # for "var"
	if (! $nd->is_otu) {
		next if $nd eq $root;
		$nodes_index->{$nd->get_name} = $internal_count;
		$internal_count++;
	}
}
print<<XXX;
    for (i in 1:nChar) {
	#site[i] ~  dunif(0,100);
        site[i] <- 1; 
	k[i] <- site[i]*(gain + loss);
        for (j in 1:nOTU) {
            trp.otu[j,i,1,2] <- 1/(1+r)*(1 - exp(-1*k[i]*b.otu[j]));
	    trp.otu[j,i,1,1] <- 1 - trp.otu[j,i,1,2];
	    trp.otu[j,i,2,1] <- trp.otu[j,i,1,2] * r;
	    trp.otu[j,i,2,2] <- 1 - trp.otu[j,i,2,1];
	}
        for (j in 1:nNode) {
            trp.node[j,i,1,2] <- 1/(1+r)*(1 - exp(-1*k[i]*b.node[j]));
            trp.node[j,i,1,1] <- 1 - trp.node[j,i,1,2];
            trp.node[j,i,2,1] <- trp.node[j,i,1,2] * r;
            trp.node[j,i,2,2] <- 1 - trp.node[j,i,2,1];
        }
        #p.root[i,1] ~ dunif(0,1);
       	p.root[i,1] <- loss/(loss + gain);
        p.root[i,2] <- 1 - p.root[i,1];
XXX

&calc_prob($root);
print "\n"." " x 8 . "# Log likelihood estimation\n";
&calc_likeli($root);
print " " x 4 . "}\n";
print qq{    loglik <-log(sum(lkroot[,]));\n}; 
print "}\n";

sub calc_prob {
	my $node = shift;
	my $doub;
	#calc cond like's of root based on closest nodes
	my $p_num = 0;
	my $i = $nodes_index->{$node->get_name};
	foreach my $child (@{$node->get_children()}) {
		my $n;
		my $j = $nodes_index->{$child->get_name};
		my $val;
		my $child_name = $child->get_name;
		my $node_name = $node->get_name;
		if ($child->is_otu) {
			if ($node_name eq 'root') {
				$val = qq{((trp.otu[$j,i,2,1])+(p.root[i,1]*exp( -1*k[i]*b.otu[$j] )))};
			} else {
				$val = qq{((trp.otu[$j,i,2,1])+(p.node[$i,i,1]*exp( -1*k[i]*b.otu[$j] )))};
			}
			print " " x 8 . qq{p.otu[$j,i,1]  <- $val; # $node_name - $child_name\n}; 
			print " " x 8 . qq{p.otu[$j,i,2]  <- 1-p.otu[$j,i,1];\n}; 
			print " " x 8 . qq{otu[$j,i] ~ dcat(p.otu[$j,i,]);\n};

		}else {
			if ($node_name eq 'root') {
			$val = qq{((trp.node[$j,i,2,1])+(p.root[i,1]*exp( -1*k[i]*b.node[$j] )))};
		} else { 
			$val = qq{((trp.node[$j,i,2,1])+(p.node[$i,i,1]*exp( -1*k[i]*b.node[$j] )))};
		}
			print " " x 8 . qq{p.node[$j,i,1] <- $val; # $node_name - $child_name\n}; 
			print " " x 8 . qq{p.node[$j,i,2] <- 1-p.node[$j,i,1];\n}; 
		}
		&calc_prob($child);
	}
}

sub calc_likeli { 
	my $node = shift;
	my $doub;
	#calc cond like's of root based on closest nodes
	my $p_num = 0;
	my $i = $nodes_index->{$node->get_name};
	foreach my $child (@{$node->get_children()}) {
		&calc_likeli($child) if (not defined $child->{conditional_like});
		my $n;
		my $cl = $child->{conditional_like};
		my $j = $nodes_index->{$child->get_name};
		if ($child->is_otu) {
			push @{$doub->[0]},qq{((otu[$j,i]*trp.otu[$j,i,1,1])+(otu[$j,i]*trp.otu[$j,i,1,2]))};
			push @{$doub->[1]},qq{((otu[$j,i]*trp.otu[$j,i,2,1])+(otu[$j,i]*trp.otu[$j,i,2,2]))};

		}else {
			push @{$doub->[0]},qq{((lk[$j,i,1]*trp.node[$j,i,1,1])+(lk[$j,i,2]*trp.node[$j,i,1,2]))};
			push @{$doub->[1]},qq{((lk[$j,i,1]*trp.node[$j,i,2,1])+(lk[$j,i,2]*trp.node[$j,i,2,2]))};
		}

		#my $a = ($cl->[0]*$p->[0][0]) + ($cl->[1]*$p->[0][1]);
		#my $b = ($cl->[0]*$p->[1][0]) + ($cl->[1]*$p->[1][1]);
	}
	$node->{conditional_like} = $doub;
		my $node_name = $node->get_name;
		if (defined $doub) {
	if ($node ne $root) {
		print " " x 8 . qq{lk[$i,i,1] <- },join( ' * ',@{$doub->[0]}),"; \# $node_name - 0\n"; 
		print " " x 8 . qq{lk[$i,i,2] <- },join(' * ',@{$doub->[1]}),";\n"; 
	}else{
		my $node_name = $node->get_name;
		print " " x 8 . qq{lkroot[i,1] <- },join( ' * ',@{$doub->[0]}),"; \# $node_name - 0\n"; 
		print " " x 8 . qq{lkroot[i,2] <- },join(' * ',@{$doub->[1]}),";\n"; 
	}
}

} 

sub cal_otu_dist { ### INCOMPLETE
	foreach my $otu (@{$tree->get_node_names()}) {
		my $i = $nodes_index->{$otu->get_name};
		my $j = $nodes_index->{$otu->get_parent->get_name};

		print qq{p.otu[i,$i,1] <- lk[i,$i,1]/(lk[i,$i,1] + lk[i,$i,2]) \n};
		print qq{ p.otu[i,$i,2] <- lk[i,$i,2]/(lk[i,$i,1] + lk[i,$i,2]) \n};
		
}
}



###############################
#  ".dat" file
###############################

open (OUT, ">$model.dat");
print OUT qq{"nChar" <- $n_intron\n};
print OUT qq{"nOTU"  <- $n_otu\n};
print OUT qq{"nNode" <- $n_node\n};

print OUT qq{"otu" <- structure(c(\n};
for (my $i = 0; $i <= $#otu; $i++) {

    print OUT join(",", @{ $state_otu{$otu[$i]->get_name()} });
	if ($i == $#otu) {
		print OUT qq{\n),.Dim = as.integer(c($n_otu,$n_intron)))\n};
	} else {
		print OUT ",\n";
	}
}
my $str = join (",", @b_otu);
print OUT qq{"b.otu" <- c(}, $str, ")\n"; 
$str = join (',', @b_node);
print OUT qq{"b.node" <- c(}, $str, ")\n";
close (OUT);


###############################
#  ".in" file
###############################
my @state = (1,2);
srand;
my $seed = int(100000000*rand());
open (OUT, ">$model.in");

print OUT qq{"node" <- structure(c(\n};
for (my $i = 0; $i <= $#node; $i++) {
	print OUT join(",", @state[ map { rand @state } ( 1 .. $n_intron)]);

	if ($i == $#node) {
		print OUT qq{\n),.Dim = as.integer(c($n_node,$n_intron)))\n};
	} else {
		print OUT ",\n";
	}
}
print OUT qq{"root" <- c(\n};
print OUT join(",", @state[ map { rand @state } ( 1 .. $n_intron)]);
print OUT "\n)\n";
close (OUT);

###############################
#  ".log" file
###############################
open (OUT, ">$model.log");
my $i = 1;
foreach my $otu (@otu) { print OUT $i++, ":\t", $otu->{'name'}, "\n" }
print OUT "\n";
$i = 1;
foreach my $nd (@node) { print OUT $i++, ":\t", $nd->{'name'}, "\n" }
close (OUT);

###############################
#  ".cmd" file
###############################
open (OUT, ">$model.cmd");
print OUT<<XXX;
seed $seed 
model in "$model.bug"
data in "$model.dat"
compile 
inits in "$model.in"
initialize
update 1200
monitor set gain, thin(50)
monitor set loss, thin(50)
monitor set site, thin(50)
monitor set loglik, thin(50)
monitor set p.root[1,1], thin(50)

update 10000
coda *
exit
XXX
close (OUT);

exit;

sub index_of_parent {
    my $item = shift;
    my @array = @_;

    for (my $i  = 0; $i <= $#array; $i ++) {
	return $i + 1 if $item eq $array[$i];
    }
    warn "parent not found!\n";
}






=head1 NAME

this.pl - do something very important. 

=head1 SYNOPSIS

this.pl [opts] <file>

=head1 DESCRIPTION

B<this.pl> does something very important. 

=head1 FILES

<file> must have a specific format.  

=head1 REQUIRES

Perl 5.004; GetOpt::Std; 

=head1 VERSION

$Id: jags.pl,v 1.2 2007/02/22 17:46:30 vivek Exp $

=head1 AUTHOR

Weigang Qiu 

=head1 CONTRIBUTORS

Arlin Stoltzfus

=cut

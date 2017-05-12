#!/usr/bin/perl -w
# Write BUGS scripts for reconstruction
# Tree has to be bifurcating
# Author:  
# $Date: 2006/10/11 21:17:06 $
# $Revision: 1.14 $

use Data::Dumper;
use Bio::NEXUS;

die "bug.pl <model name> <nexus file (1 data block 1 tree)> [burn-in generations] [monitor generations]\n" unless @ARGV == 2;
my $model = shift;
my $file  = shift;
my $burnin = shift;
unless (defined $burnin) {$burnin = 10;}
my $monitor = shift || 10;

my $nexus = new Bio::NEXUS($file);

my ($n_otu, $n_node, $n_intron);
my %state_otu; # intron states for each otu
my ($root, $nodes, $tree_length);
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
print "model $model;\n\n";

#########################
#  for "const":
#########################
print "const\n";
print "\tnChar = $n_intron,\n";
print "\tnOTU = $n_otu,\n";
print "\tnNode = $n_node;\n";

#########################
#  for "var":
#########################

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

#########################
#  for "data" (S-format)
#########################

print "data in \"$model.dat\";\n";
print "inits in \"$model.in\";\n\n";

#########################
#  main loop: tree 
#########################

my ( @otu, @node, @b_otu, @b_node, %parent, @dist, @lk );
foreach my $nd (@$nodes) {  # for "var"
    if ($nd eq $root) {
	push @dist, "root\[i\] ~ dcat(p\.root\[\])";
	push @lk, "log(p.root\[root\[i\]\])"; 
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
#print &Dumper(@b_node);exit;

for (my $i = 0; $i <= $#otu; $i ++) {
    if ( $parent{$otu[$i]} eq $root ) {
	push @dist, sprintf "%s%d%s%d%s", "otu\[", $i + 1, ",i\] ~ dcat(p\.otu\[", $i + 1, ", root\[i\],\])";
	push @lk, sprintf "%s%d%s%d%s", "log(p.otu\[", $i + 1, ",root\[i\],otu\[", $i + 1, ",i\]\])";  
    } else {
	my $j = &index_of_parent($parent{$otu[$i]}, @node);
	push @dist, sprintf "%s%d%s%d%s%d%s", "otu\[", $i + 1, ",i\] ~ dcat(p\.otu\[", $i + 1, ", node\[", $j, ",i\],\])";
	push @lk, sprintf "%s%d%s%d%s%d%s", "log(p.otu\[", $i + 1, ",node\[", $j, ",i\],otu\[", $i + 1, ",i\]\])";  
    }
}

for (my $i = 0; $i <= $#node; $i ++) {
    if ( $parent{$node[$i]} eq $root ) {
	push @dist, sprintf "%s%d%s%d%s", "node\[", $i + 1, ",i\] ~ dcat(p\.node\[", $i + 1, ", root\[i\],\])";
	push @lk, sprintf "%s%d%s%d%s", "log(p.node\[", $i + 1, ",root\[i\],node\[", $i + 1, ",i\]\])";  
    } else {
	my $j = &index_of_parent($parent{$node[$i]}, @node);
	push @dist, sprintf "%s%d%s%d%s%d%s",  "node\[", $i + 1, ",i\] ~ dcat(p\.node\[", $i + 1, ", node\[", $j, ",i\],\])";
	push @lk, sprintf "%s%d%s%d%s%d%s", "log(p.node\[", $i + 1, ",node\[", $j, ",i\],node\[", $i + 1, ",i\]\])";  
    }
}

print "\{\n";

print "\tfor (i in 1:nChar) \{\n";
for(my $i = 0; $i <= $#lk; $i ++) { 
    print "\t\t", $dist[$i], ";\t", 
    "lk\[", $i+1, ",i\] <- $lk[$i];\n"
	; 
}
print "\t\}\n\n";

###############################
#  main loop: transition prob
###############################
my $ex = "1/(1+r)";
my $exp = "1 - exp(-1\*k\*b\.otu\[i\])";

print "\tfor (i in 1:nOTU) \{\n";
print "\t\tp\.otu\[i,1,2\] <- $ex\*($exp);\n";
print "\t\tp\.otu\[i,1,1\] <- 1 - p\.otu\[i,1,2\];\n";    
print "\t\tp\.otu\[i,2,1\] <- p\.otu\[i,1,2\] \* r;\n";
print "\t\tp\.otu\[i,2,2\] <- 1 - p\.otu\[i,2,1\];\n";    
print "\t}\n\n";

$exp = "1 - exp(-1\*k\*b\.node\[i\])";

print "\tfor (i in 1:nNode) \{\n";
print "\t\tp\.node\[i,1,2\] <- $ex\*($exp);\n";
print "\t\tp\.node\[i,1,1\] <- 1 - p\.node\[i,1,2\];\n";    
print "\t\tp\.node\[i,2,1\] <- p\.node\[i,1,2\] \* r;\n";
print "\t\tp\.node\[i,2,2\] <- 1 - p\.node\[i,2,1\];\n";    
print "\t}\n\n";

print "\tp\.root\[2\] <- $ex;\n";
print "\tp\.root\[1\] <- 1 - p\.root\[2\];\n";    
print "\n";

print "\tllike <- sum(lk\[,\]);\n\n";

my $a1 = $n_otu/($tree_length*2);
#print STDERR "$n_otu -- $tree_length -- $a1\n";exit;
my $b1 = sqrt($a1);
if ($b1 < 2) { $b1 = 2; }

#print "\ta ~ dunif(0.01, $b1);\n"; 
#print "\tb ~ dunif(0.01, $b1);\n";
#print "\talpha <- pow(a, 2);\n";
#print "\tbeta <- pow(b, 2);\n";
#print "\tr <- beta / alpha;\n";
#print "\tk <- beta + alpha;\n";

print "\n\ta \~ dunif(0,10);\n";
print "\n\tr <- a*a;\n"; 
print "\tb \~ dunif(0,$b1);\n"; 
print "\tk <- b*b";
print "\talpha <- k /(1+r)\n";
print "\tbeta <- alpha*r";


print "\}\n\n";

###############################
#  ".dat" file
###############################

open (OUT, ">$model.dat");
print OUT "list(\notu = c(\n";
for (my $i = 0; $i <= $#otu; $i++) {
    print OUT join(",", @{ $state_otu{$otu[$i]->name()} });
    print OUT ($i == $#otu) ? "\n),\n" : ",\n";
}
my $str = join (",", @b_otu);
print OUT "b.otu = c(", $str, "),\n"; 
$str = join (',', @b_node);
print OUT "b.node = c(", $str, ")\n";
print OUT ")\n";
close (OUT);


###############################
#  ".in" file
###############################
my @state = (1,2);
srand;
my $seed = int(100000000*rand());
open (OUT, ">$model.in");
print OUT "list(\n";
print OUT "seed = $seed";
print OUT ",\n";
print OUT "node = c(\n";
for (my $i = 0; $i <= $#node; $i++) {
    print OUT join(",", @state[ map { rand @state } ( 1 .. $n_intron)]);
    print OUT ($i == $#node) ? "\n),\n" : ",\n";
}
print OUT "root = c(\n";
print OUT join(",", @state[ map { rand @state } ( 1 .. $n_intron)]);
print OUT "\n)\n";
print OUT ")\n";
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
print OUT "compile(\"$model\.bug\")\n";
print OUT "update($burnin)\n";
print OUT "monitor(alpha)\n";
print OUT "monitor(beta)\n";
print OUT "monitor(r)\n";
print OUT "monitor(k)\n";
print OUT "monitor(llike)\n";
print OUT "monitor(root)\n";
#print OUT "monitor(node)\n";
#print OUT "monitor(node[,18])\n";
#print OUT "monitor(node[,32])\n";
#print OUT "monitor(node[,35])\n";
#print OUT "monitor(node[,39])\n";
print OUT "update($monitor)\n";
print OUT "stats(alpha)\n";
print OUT "stats(beta)\n";
print OUT "stats(r)\n";
print OUT "stats(k)\n";
print OUT "stats(llike)\n";
print OUT "stats(root)\n";
#print OUT "stats(node)\n";
#print OUT "stats(node[,18])\n";
#print OUT "stats(node[,32])\n";
#print OUT "stats(node[,35])\n";
#print OUT "stats(node[,39])\n";
print OUT "q()\n";
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

$Id: bugs.pl,v 1.14 2006/10/11 21:17:06 vivek Exp $

=head1 AUTHOR

Weigang Qiu 

=head1 CONTRIBUTORS

Arlin Stoltzfus

=cut

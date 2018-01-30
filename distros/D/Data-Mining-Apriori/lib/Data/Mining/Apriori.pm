package Data::Mining::Apriori;

use 5.010001;
use strict;
use warnings;
use Algorithm::Combinatorics qw(subsets variations);
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

our $VERSION = 0.17;

my$self;

$" = ', ';
$| = 1;
$SIG{'INT'} = \&stop;

sub new{
	my $type = shift;
	my $class = ref($type)||$type;
	$self = {
		totalTransactions => 0,
		metrics => {
			minSupport => 0.01,
			minConfidence => 0.10,
			minLift => undef,
			minLeverage => undef,
			minConviction => undef,
			minCoverage => undef,
			minCorrelation => undef,
			minCosine => undef,
			minLaplace => undef,
			minJaccard => undef
		},
		precision => 3,
		output => undef,
		pathOutputFiles => "",
		messages => undef,
		keyItemsDescription => undef,
		keyItemsTransactions => undef,
		limitRules => undef,
		limitSubsets => undef,
		numberSubsets => 0,
		frequentItemset => [],
		associationRules => undef,
		implications => undef,
		largeItemsetLength => 2,
		rule => 0
	};
	bless($self,$class);
	return $self;
}

sub validate_data{
	(defined $self->{keyItemsDescription})
		or die('Error: $apriori->{keyItemsDescription} is not defined!');
	(defined $self->{keyItemsTransactions})
		or die('Error: $apriori->{keyItemsTransactions} is not defined!');
	(defined $self->{metrics}{minSupport})
		or die('Error: $apriori->{metrics}{minSupport} is not defined!');
	(defined $self->{metrics}{minConfidence})
		or die('Error: $apriori->{metrics}{minConfidence} is not defined!');
}

sub insert_key_items_transaction{
	(scalar(@_)==2)
		or die('Error: $apriori->insert_key_items_transaction(\@items) missing parameter key items to array reference!');
	(ref($_[1]) eq "ARRAY")
		or die('Error: $apriori->insert_key_items_transaction(\@items) parameter key items is not an array reference!');
	my@items=sort(@{$_[1]});
	my @itemsets=subsets(\@items);
	foreach my$itemset(@itemsets){
		$self->{keyItemsTransactions}{"@{$itemset}"}++;
	}
	$self->{totalTransactions}++;
}

sub input_data_file{
	(scalar(@_)==3)
		or die('Error: $apriori->input_data_file("datafile.txt",",") missing parameters path to data file and/or item separator!');
	my$file=$_[1];
	my$separator=$_[2];
	(-e $file)
		or die("Error: the file \"$file\" does not exists!");
	(-r $file)
		or die("Error: the file \"$file\" is not readable!");
	(-T $file)
		or die("Error: the file \"$file\" is not a text file!");
	open(FILE,"<$file")
		or die("Error: $!");
	while(my$line=<FILE>){
		$line=~s/\r\n|\n//;
		my@items=split($separator,$line);
		if(scalar(@items)>=2){
			$self->insert_key_items_transaction(\@items);
		}
	}
	close(FILE);
}

sub quantity_possible_rules{
	$self->validate_data;
	return ((3**scalar(keys(%{$self->{keyItemsDescription}})))-(2**(scalar(keys(%{$self->{keyItemsDescription}}))+1))+1);
}

sub generate_rules{
	$self->validate_data;
	if($self->{messages}){
		print "\n${\scalar(keys(%{$self->{keyItemsDescription}}))} items, ${\$self->quantity_possible_rules} possible rules";
	}
	my @largeItemsetLengthOne = grep{(($self->{keyItemsTransactions}{$_}/$self->{totalTransactions})*100)>=$self->{metrics}{minSupport}}keys(%{$self->{keyItemsDescription}});
	$self->association_rules(\@largeItemsetLengthOne);
}

sub association_rules{
	my @largeItemset = @{$_[1]};
	my @variations = variations(\@largeItemset,$self->{largeItemsetLength});
	my @frequentItemset;
	if($self->{messages}){
		print "\nLarge itemset of length $self->{largeItemsetLength}, ${\scalar(@largeItemset)} items ";
		print "\nProcessing ...";
	}
	VARIATIONS:
	foreach my$variation(@variations){
		my@candidateItemset=@{$variation};
		my@antecedent;
		my@consequent;
		for(my$antecedentLength=0;$antecedentLength<$#candidateItemset;$antecedentLength++){
			push@antecedent,$candidateItemset[$antecedentLength];
			@consequent=();
			for(my$consequentLength=($antecedentLength+1);$consequentLength<=$#candidateItemset;$consequentLength++){
				push@consequent,$candidateItemset[$consequentLength];
			}
			@antecedent=sort@antecedent;
			@consequent=sort@consequent;
			next if("@consequent"~~@{$self->{implications}{"@antecedent"}});
			last VARIATIONS if(defined $self->{limitSubsets} && $self->{numberSubsets} == $self->{limitSubsets});
			$self->{numberSubsets}++;
			push @{$self->{implications}{"@antecedent"}},"@consequent";
			my@implication;
			push@implication,@antecedent,@consequent;
			@implication=sort(@implication);
			next unless $self->{keyItemsTransactions}{"@antecedent"};
			my$supportAntecedent=($self->{keyItemsTransactions}{"@antecedent"}/$self->{totalTransactions});
			next unless $self->{keyItemsTransactions}{"@implication"};
			my$supportConsequent=($self->{keyItemsTransactions}{"@implication"}/$self->{totalTransactions});
			my $support = $supportConsequent;
			next if($support < $self->{metrics}{minSupport});
			my $confidence = ($supportConsequent/$supportAntecedent);
			next if(defined $self->{metrics}{minConfidence} && $confidence < $self->{metrics}{minConfidence});
			my $lift = ($support/($supportAntecedent*$supportConsequent));
			next if(defined $self->{metrics}{minLift} && $lift < $self->{metrics}{minLift});
			my $leverage = ($support-($supportAntecedent*$supportConsequent));
			next if(defined $self->{metrics}{minLeverage} && $leverage < $self->{metrics}{minLeverage});
			my $conviction = ((1-$supportConsequent)==0)?"NaN":((1-$confidence)==0)?"NaN":((1-$supportConsequent)/(1-$confidence));
			next if(defined $self->{metrics}{minConviction} && $conviction < $self->{metrics}{minConviction});
			my $coverage = $supportAntecedent;
			next if(defined $self->{metrics}{minCoverage} && $coverage < $self->{metrics}{minCoverage});
			my $correlation = (($support-($supportAntecedent*$supportConsequent))/sqrt($supportAntecedent*(1-$supportAntecedent)*$supportConsequent*(1-$supportConsequent)));
			next if(defined $self->{metrics}{minCorrelation} && $correlation < $self->{metrics}{minCorrelation});
			my $cosine = ($support/sqrt($supportAntecedent*$supportConsequent));
			next if(defined $self->{metrics}{minCosine} && $cosine < $self->{metrics}{minCosine});
			my $laplace = (($support+1)/($supportAntecedent+2));
			next if(defined $self->{metrics}{minLaplace} && $laplace < $self->{metrics}{minLaplace});
			my $jaccard = ($support/($supportAntecedent+$supportConsequent-$support));
			next if(defined $self->{metrics}{minJaccard} && $jaccard < $self->{metrics}{minJaccard});
			$self->{rule}++;
			$support = sprintf("%.$self->{precision}f", $support);
			$confidence = sprintf("%.$self->{precision}f", $confidence);
			$lift = sprintf("%.$self->{precision}f", $lift);
			$leverage = sprintf("%.$self->{precision}f", $leverage);
			$conviction = sprintf("%.$self->{precision}f", $conviction)if($conviction ne "NaN");
			$coverage = sprintf("%.$self->{precision}f", $coverage);
			$correlation = sprintf("%.$self->{precision}f", $correlation);
			$cosine = sprintf("%.$self->{precision}f", $cosine);
			$laplace = sprintf("%.$self->{precision}f", $laplace);
			$jaccard = sprintf("%.$self->{precision}f", $jaccard);
			$self->{associationRules}{$self->{rule}} = {
				implication => "{ @antecedent } => { @consequent }",
				support => $support, 
				confidence => $confidence,
				lift => $lift,
				leverage => $leverage,
				conviction => $conviction,
				coverage => $coverage,
				correlation => $correlation,
				cosine => $cosine,
				laplace => $laplace,
				jaccard => $jaccard,
				items => [@antecedent, @consequent]
			};
			my@items=grep{!($_~~@frequentItemset)}@implication;
			push@frequentItemset,@items;
			last VARIATIONS if(defined $self->{limitRules} && $self->{rule} == $self->{limitRules});
		}
	}
	if($self->{messages}){
		print "\nFrequent itemset: { @frequentItemset }, ${\scalar(@frequentItemset)} items ";
	}
	if(defined $self->{associationRules}){
		@{$self->{frequentItemset}}=@frequentItemset;
		$self->output;
	}
	return if((defined $self->{limitRules} && $self->{rule} == $self->{limitRules})
				||(defined $self->{limitSubsets} && $self->{numberSubsets} == $self->{limitSubsets}));
	if(scalar(@frequentItemset)>=($self->{largeItemsetLength}+1)){
		$self->{largeItemsetLength}++;
		$self->{associationRules} = undef;
		$self->association_rules(\@frequentItemset);
	}
}

sub stop{
	if($self->{messages}){
		print "\nStopping ...";
		$self->output if $self->{associationRules};
		print "\nExit? (Y/N): ";
		my $answer = <STDIN>;
		chomp($answer);
		if($answer =~ /^y$/i){
			exit;
		}
		else{
			print "Processing ...";
		}
	}
	else{
		$self->output if $self->{associationRules};
		exit;
	}
}

sub output{
	if($self->{output}){
		if($self->{output}==1){
			$self->file;
		}
		elsif($self->{output}==2){
			$self->excel;
		}
	}
}

sub file{
	if($self->{messages}){
		print "\nExporting to file $self->{pathOutputFiles}output_large_itemset_length_$self->{largeItemsetLength}.txt ...";
	}
	open(FILE,">$self->{pathOutputFiles}output_large_itemset_length_$self->{largeItemsetLength}.txt")
		or die("\nError: $self->{pathOutputFiles}output_large_itemset_length_$self->{largeItemsetLength}.txt $!");
	print FILE "Rules\tSupport\tConfidence";
	my@headings=('Lift', 'Leverage', 'Conviction', 'Coverage', 'Correlation', 'Cosine', 'Laplace', 'Jaccard');
	my@metrics;
	foreach my$metric(@headings){
		push@metrics,$metric if defined $self->{metrics}{"min$metric"};
	}
	foreach my$metric(@metrics){
		print FILE "\t$metric";
	}
	print FILE "\n";
	foreach my$rule(sort{$a<=>$b}keys(%{$self->{associationRules}})){
		$self->{associationRules}{$rule}{support}=~s/\./,/;
		$self->{associationRules}{$rule}{confidence}=~s/\./,/;
		foreach my$metric(@metrics){
			$self->{associationRules}{$rule}{lc$metric}=~s/\./,/;
		}
		print FILE "R$rule\t$self->{associationRules}{$rule}{support}\t$self->{associationRules}{$rule}{confidence}";
		foreach my$metric(@metrics){
			print FILE "\t$self->{associationRules}{$rule}{${\lc$metric}}";
		}
		print FILE "\n";
	}
	print FILE "\n";
	foreach my$rule(sort{$a<=>$b}keys(%{$self->{associationRules}})){
		print FILE "Rule R$rule: $self->{associationRules}{$rule}{implication}\n";
		print FILE "Support: $self->{associationRules}{$rule}{support}\n";
		print FILE "Confidence: $self->{associationRules}{$rule}{confidence}\n";
		foreach my$metric(@metrics){
			print FILE "$metric: $self->{associationRules}{$rule}{${\lc$metric}}\n";
		}
		print FILE "Items:\n";
		foreach my$item(@{$self->{associationRules}{$rule}{items}}){
			print FILE "$item $self->{keyItemsDescription}{$item}\n";
		}
		print FILE "\n";
	}
	print FILE "Frequent itemset: { @{$self->{frequentItemset}} }\n";
	print FILE "Items:\n";
	foreach my$item(@{$self->{frequentItemset}}){
		print FILE "$item $self->{keyItemsDescription}{$item}\n";
	}
	close(FILE);
}

sub excel{
	require Excel::Writer::XLSX;
	if($self->{messages}){
		print "\nExporting to excel $self->{pathOutputFiles}output_large_itemset_length_$self->{largeItemsetLength}.xlsx ...";
	}
	my $workbook  = Excel::Writer::XLSX->new("$self->{pathOutputFiles}output_large_itemset_length_$self->{largeItemsetLength}.xlsx") 
		or die("\nError: $self->{pathOutputFiles}output_large_itemset_length_$self->{largeItemsetLength}.xlsx $!");
	my $worksheet = $workbook->add_worksheet();
	my $bold = $workbook->add_format(bold => 1);
	my $headings = ['Rules', 'Support', 'Confidence'];
	my@metrics=('Lift', 'Leverage', 'Conviction', 'Coverage', 'Correlation', 'Cosine', 'Laplace', 'Jaccard');
	foreach my$metric(@metrics){
		push@{$headings},$metric if defined $self->{metrics}{"min$metric"};
	}
	@metrics=@{$headings}[3..$#{$headings}];
	my(@rules,@support,@confidence,@lift,@leverage,@conviction,@coverage,@correlation,@cosine,@laplace,@jaccard);	
	foreach my$rule(sort{$a<=>$b}keys(%{$self->{associationRules}})){
		push @rules,"R$rule";
		push @support,$self->{associationRules}{$rule}{support};
		push @confidence,$self->{associationRules}{$rule}{confidence};
		push @lift,$self->{associationRules}{$rule}{lift} if defined $self->{metrics}{minLift};
		push @leverage,$self->{associationRules}{$rule}{leverage} if defined $self->{metrics}{minLeverage};
		push @conviction,$self->{associationRules}{$rule}{conviction} if defined $self->{metrics}{minConviction};
		push @coverage,$self->{associationRules}{$rule}{coverage} if defined $self->{metrics}{minCoverage};
		push @correlation,$self->{associationRules}{$rule}{correlation} if defined $self->{metrics}{minCorrelation};
		push @cosine,$self->{associationRules}{$rule}{cosine} if defined $self->{metrics}{minCosine};
		push @laplace,$self->{associationRules}{$rule}{laplace} if defined $self->{metrics}{minLaplace};
		push @jaccard,$self->{associationRules}{$rule}{jaccard} if defined $self->{metrics}{minJaccard};
	}
	my$line=(scalar(@rules)+1);
	my@data=(\@rules,\@support,\@confidence);
	push @data,\@lift if defined $self->{metrics}{minLift};
	push @data,\@leverage if defined $self->{metrics}{minLeverage};
	push @data,\@conviction if defined $self->{metrics}{minConviction};
	push @data,\@coverage if defined $self->{metrics}{minCoverage};
	push @data,\@correlation if defined $self->{metrics}{minCorrelation};
	push @data,\@cosine if defined $self->{metrics}{minCosine};
	push @data,\@laplace if defined $self->{metrics}{minLaplace};
	push @data,\@jaccard if defined $self->{metrics}{minJaccard};
	$worksheet->write('A1', $headings, $bold);
	$worksheet->write('A2', \@data);
	my$chart=$workbook->add_chart(type =>'column', embedded=>1);
	my@columns=('B'..'M');
	my$i=0;
	$chart->add_series(
		name       => 'Support',
		categories => '=Sheet1!$A$2:$A$'.$line,
		values     => '=Sheet1!$'.$columns[$i].'$2:$'.$columns[$i].'$'.$line,
	);
	$i++;
	$chart->add_series(
		name       => 'Confidence',
		categories => '=Sheet1!$A$2:$A$'.$line,
		values     => '=Sheet1!$'.$columns[$i].'$2:$'.$columns[$i].'$'.$line,
	);
	foreach my$metric(@metrics){
		$i++;
		$chart->add_series(
			name       => $metric,
			categories => '=Sheet1!$A$2:$A$'.$line,
			values     => '=Sheet1!$'.$columns[$i].'$2:$'.$columns[$i].'$'.$line,
		);
	}
	$worksheet->insert_chart($columns[($i+2)].'2', $chart);
	$line+=2;
	my $urlFormat = $workbook->add_format(
	    color     => 'blue',
	);
	my$url=2;
	foreach my$rule(sort{$a<=>$b}keys(%{$self->{associationRules}})){
		$worksheet->write_url("A$line","internal:Sheet1!A$url",$urlFormat,"<");
		$line++;
		$worksheet->write_url("A$url","internal:Sheet1!A$line",$urlFormat,"R$rule");
		$worksheet->write("A$line","Rule R$rule: $self->{associationRules}{$rule}{implication}");
		$line++;
		$worksheet->write("A$line","Support: $self->{associationRules}{$rule}{support}");
		$line++;
		$worksheet->write("A$line","Confidence: $self->{associationRules}{$rule}{confidence}");
		$line++;
		foreach my$metric(@metrics){
			$worksheet->write("A$line","$metric: $self->{associationRules}{$rule}{${\lc$metric}}");
			$line++;
		}
		$worksheet->write("A$line","Items:");
		$line++;
		foreach my$item(@{$self->{associationRules}{$rule}{items}}){
			$worksheet->write("A$line","$item $self->{keyItemsDescription}{$item}");
			$line++;
		}
		$line++;
		$url++;
	}
	$worksheet->write("A$line","Frequent itemset: { @{$self->{frequentItemset}} }");
	$line++;
	$worksheet->write("A$line","Items:");
	$line++;
	foreach my$item(@{$self->{frequentItemset}}){
		$worksheet->write("A$line","$item $self->{keyItemsDescription}{$item}");
		$line++;
	}
	$workbook->close;
}

return 1;
__END__
=head1 NAME

Data::Mining::Apriori - Perl extension for implement the apriori algorithm of data mining.

=head1 SYNOPSIS

	use strict;
	use warnings;
	use Data::Mining::Apriori;

	# TRANSACTION 103:CEREAL 101:MILK 102:BREAD
	#        1101          1        1         0
	#        1102          1        0         1
	#        1103          1        1         1
	#        1104          1        1         1
	#        1105          0        1         1
	#        1106          1        1         1
	#        1107          1        1         1
	#        1108          1        0         1
	#        1109          1        1         1
	#        1110          1        1         1

	my $apriori = new Data::Mining::Apriori;

	$apriori->{metrics}{minSupport}=0.0155; # The minimum support (required), default value is 0.01 (1%)

	$apriori->{metrics}{minConfidence}=0.0155; # The minimum confidence (required), default value is 0.10 (10%)

	$apriori->{metrics}{minLift}=1; # The minimum lift (optional)

	$apriori->{metrics}{minLeverage}=0; # The minimum leverage (optional)

	$apriori->{metrics}{minConviction}=0; # The minimum conviction (optional)

	$apriori->{metrics}{minCoverage}=0; # The minimum coverage (optional)

	$apriori->{metrics}{minCorrelation}=0; # The minimum correlation (optional)

	$apriori->{metrics}{minCosine}=0; # The minimum cosine (optional)

	$apriori->{metrics}{minLaplace}=0; # The minimum laplace (optional)

	$apriori->{metrics}{minJaccard}=0; # The minimum jaccard (optional)

	$apriori->{precision}=2; # Sets the floating point precision of the metrics (required), default value is 3

	$apriori->{output}=1;
	# The output type (optional): 1 - Export to text file delimited by TAB; 2 - Export to excel file with chart.

	$apriori->{pathOutputFiles}='data/'; # The path to output files (optional)

	$apriori->{messages}=1; # A value boolean to display the messages (optional)

	$apriori->{keyItemsDescription}{'101'}='MILK'; # Hash table reference to add items by key and description
	$apriori->{keyItemsDescription}{102}='BREAD';
	$apriori->{keyItemsDescription}{'103'}='CEREAL';

	my@items=(103,101);
	$apriori->insert_key_items_transaction(\@items); # Insert key items by transaction
	$apriori->insert_key_items_transaction([103,102]);
	$apriori->insert_key_items_transaction([103,101,102]);
	$apriori->insert_key_items_transaction([103,101,102]);
	$apriori->insert_key_items_transaction([101,102]);
	$apriori->insert_key_items_transaction([103,101,102]);
	$apriori->insert_key_items_transaction([103,101,102]);
	$apriori->insert_key_items_transaction([103,102]);
	$apriori->insert_key_items_transaction([103,101,102]);
	$apriori->insert_key_items_transaction([103,101,102]);

	# or from a data file

	$apriori->input_data_file("datafile.txt",",");
	# Insert key items by line (transaction), accepts the arguments of path to data file and item separator

	# file contents (example)

	103,101
	103,102
	103,101,102
	103,101,102
	101,102
	103,101,102
	103,101,102
	103,102
	103,101,102
	103,101,102

	print "\n${\$apriori->quantity_possible_rules}"; # Show the quantity of possible rules

	$apriori->{limitRules}=10; # The limit of rules (optional)

	$apriori->{limitSubsets}=12; # The limit of subsets (optional)

	$apriori->generate_rules;
	# Generate association rules to no longer meet the minimum support, confidence, lift, leverage, conviction, coverage, correlation, cosine, laplace, jaccard or limit of rules

	print "\n@{$apriori->{frequentItemset}}\n"; # Show frequent items

	#output messages

	12
	3 items, 12 possible rules
	Large itemset of length 2, 3 items
	Processing ...
	Frequent itemset: { 102, 103, 101 }, 3 items
	Exporting to file data/output_large_itemset_length_2.txt ...
	Large itemset of length 3, 3 items
	Processing ...
	Frequent itemset: { 101, 102, 103 }, 3 items
	Exporting to file data/output_large_itemset_length_3.txt ...
	101, 102, 103

	#output file "output_itemset_length_2.txt"

	Rules	Support	Confidence	Lift	Leverage	Conviction	Coverage	Correlation	Cosine	Laplace	Jaccard
	R1	0,80	0,89	1,11	0,08	1,80	0,90	0,67	0,94	0,62	0,89
	R2	0,70	0,78	1,11	0,07	1,35	0,90	0,51	0,88	0,59	0,78
	R3	0,80	0,89	1,11	0,08	1,80	0,90	0,67	0,94	0,62	0,89
	R4	0,70	0,78	1,11	0,07	1,35	0,90	0,51	0,88	0,59	0,78
	R5	0,70	0,87	1,25	0,14	2,40	0,80	0,76	0,94	0,61	0,87
	R6	0,70	0,87	1,25	0,14	2,40	0,80	0,76	0,94	0,61	0,87

	Rule R1: { 102 } => { 103 }
	Support: 0,80
	Confidence: 0,89
	Lift: 1,11
	Leverage: 0,08
	Conviction: 1,80
	Coverage: 0,90
	Correlation: 0,67
	Cosine: 0,94
	Laplace: 0,62
	Jaccard: 0,89
	Items:
	102 BREAD
	103 CEREAL

	#...

	#output file "output_itemset_length_3.txt"

	Rules	Support	Confidence	Lift	Leverage	Conviction	Coverage	Correlation	Cosine	Laplace	Jaccard
	R7	0,60	0,67	1,11	0,06	1,20	0,90	0,41	0,82	0,55	0,67
	R8	0,60	0,75	1,25	0,12	1,60	0,80	0,61	0,87	0,57	0,75
	R9	0,60	0,86	1,43	0,18	2,80	0,70	0,80	0,93	0,59	0,86
	R10	0,60	0,67	1,11	0,06	1,20	0,90	0,41	0,82	0,55	0,67
	R11	0,60	0,86	1,43	0,18	2,80	0,70	0,80	0,93	0,59	0,86
	R12	0,60	0,75	1,25	0,12	1,60	0,80	0,61	0,87	0,57	0,75

	Rule R7: { 102 } => { 101, 103 }
	Support: 0,60
	Confidence: 0,67
	Lift: 1,11
	Leverage: 0,06
	Conviction: 1,20
	Coverage: 0,90
	Correlation: 0,41
	Cosine: 0,82
	Laplace: 0,55
	Jaccard: 0,67
	Items:
	102 BREAD
	101 MILK
	103 CEREAL

	Rule R8: { 102, 103 } => { 101 }
	Support: 0,60
	Confidence: 0,75
	Lift: 1,25
	Leverage: 0,12
	Conviction: 1,60
	Coverage: 0,80
	Correlation: 0,61
	Cosine: 0,87
	Laplace: 0,57
	Jaccard: 0,75
	Items:
	102 BREAD
	103 CEREAL
	101 MILK

	#...

=head1 DESCRIPTION

This module implements the apriori algorithm of data mining.

=head1 ATTRIBUTES

=head2 totalTransactions

The total number of transactions.

=head2 metrics

The type of metrics

=over 4

=item minSupport

The minimum support (required), default value is 0.01 (1%)

=item minConfidence

The minimum confidence (required), default value is 0.10 (10%)

=item minLift

The minimum lift (optional)

=item minLeverage

The minimum leverage (optional)

=item minConviction

The minimum conviction (optional)

=item minCoverage

The minimum coverage (optional)

=item minCorrelation

The minimum correlation (optional)

=item minCosine

The minimum cosine (optional)

=item minLaplace

The minimum laplace (optional)

=item minJaccard

The minimum jaccard (optional)

=back

=head2 precision

Sets the floating point precision of the metrics (required), default value is 3

=head2 limitRules

The limit of rules (optional)

=head2 limitSubsets

The limit of subsets (optional)

=head2 output

The output type (optional):

=over 4

=item *

1 - Text file delimited by TAB;

=item *

2 - Excel file with chart.

=back

=head2 pathOutputFiles

The path to output files (optional)

=head2 messages

A value boolean to display the messages (optional)

=head2 keyItemsDescription

Hash table reference to add item by key and description.

=head2 keyItemsTransactions

Hash table reference to add items by keys and transactions.

=head2 frequentItemset

Frequent itemset.

=head2 associationRules

A data structure to store the name of the rule, key items, implication, support, confidence, lift, leverage, conviction, coverage, correlation, cosine, laplace and jaccard.

	$self->{associationRules} = {
								  '1' => {
										   'confidence' => '0.89',
										   'cosine' => '0.94',
										   'implication' => '{ 102 } => { 103 }',
										   'coverage' => '0.90',
										   'laplace' => '0.62',
										   'jaccard' => '0.89',
										   'support' => '0.80',
										   'correlation' => '0.67',
										   'items' => [
														'102',
														'103'
													  ],
										   'conviction' => '1.80',
										   'lift' => '1.11',
										   'leverage' => '0.08'
										 },
									#...

=head1 METHODS

=head2 new

Creates a new instance of Data::Mining::Apriori.

=head2 insert_key_items_transaction(\@items)

Insert key items per transaction. Accepts the following arguments:

=over 4

=item *

An array reference to key items.

=back

=head2 input_data_file("datafile.txt",",")

Insert items per line (transaction). Accepts the following arguments:

=over 4

=item *

Data file;

=item *

Item separator.

=back

	# file contents (example)

	103,101
	103,102
	103,101,102
	103,101,102
	101,102
	103,101,102
	103,101,102
	103,102
	103,101,102
	103,101,102

=head2 quantity_possible_rules

Returns the quantity of possible rules.

=head2 generate_rules

Generate association rules until no set of items meets the minimum support, confidence, lift, leverage, conviction, coverage, correlation, cosine, laplace, jaccard or limit of rules.

=head2 association_rules

Generate association rules by length of large itemsets.

=head1 AUTHOR

Alex Graciano, E<lt>agraciano@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2018 by Alex Graciano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

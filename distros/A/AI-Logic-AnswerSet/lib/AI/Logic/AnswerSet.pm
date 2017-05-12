package AI::Logic::AnswerSet;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

sub executeFromFileAndSave {		#Executes DLV with a file as input and saves the output in another file

	open DLVW, ">>", "$_[1]";
	print DLVW $_[2];
	close DLVW;

	open(SAVESTDOUT, ">&STDOUT") or die "Can't save STDOUT: $!\n";
	open(STDOUT, ">$_[0]") or die "Can't open STDOUT to $_[0]", "$!\n";


	my @args = ("./dlv", "$_[1]");
	system(@args) == 0
		or die "system @args failed: $?";

	open(STDOUT,">&SAVESTDOUT"); #close file and restore STDOUT
	close OUTPUT;

}

sub executeAndSave {	#Executes DLV and saves the output of the program written by the user in a file

	open(SAVESTDOUT, ">&STDOUT") or die "Can't save STDOUT: $!\n";
	open(STDOUT, ">$_[0]") or die "Can't open STDOUT to $_[0]", "$!\n";

	my @args = ("./dlv --");
	system(@args) == 0 or die "system @args failed: $?";

	open(STDOUT,">&SAVESTDOUT"); #close file and restore STDOUT
	close OUTPUT;


}


sub iterativeExec {	# Executes an input program with several instances and stores them in a bidimensional array

	my @input = @_;

	my @returned_value;

	if(@input) {
		
		my $option = $input[$#input];

		if($option =~ /^-/) {
			pop(@input);
		}
		else {
			$option = "";
		}

		my $dir = pop(@input);
		my @files = qx(ls $dir);
			
		my $size = @files;

		for(my $i = 0; $i < $size; $i++) {

			my $elem = $files[$i];
			chomp $elem;
			my @args = ("./dlv", "@input", "$dir$elem", "$option");
			my (@out) = `@args`;
			push @{$returned_value[$i]}, @out;
		}
		
	}

	else {
		print "INPUT ERROR\n";
	}

	return @returned_value;

}

sub singleExec {	 # Executes a single input program or opens the DLV terminal and stores it in an array

	my @input = @_;
	my @returned_value;

	if(@input) {


		my @args = ("./dlv", "@input");
		(@returned_value) = `@args`;
		
	}

	else {
		my $command = "./dlv --";
		(@returned_value) = `$command`;		
	}

	return @returned_value;
}

sub selectOutput {	# Select one of the outputs returned by the iterative execution of more input programs 

	my @stdoutput = @{$_[0]};
	my $n = $_[1];

	return @{$stdoutput[$n]};
	
}

sub getFacts {	# Return the facts of the input program

	my $input = shift;

	my @isAFile = stat($input);

	my @facts;

	if(@isAFile) {

		open INPUT, "<", "$input";
		my @rows = <INPUT>;
		foreach my $row (@rows) {
			if($row =~ /^(\w+)(\(((\w|\d|\.)+,?)*\))?\./) {
				push @facts, $row;
			}
		}
		close INPUT;

	}
	else {
		my @str = split /\. /,$input;
		foreach my $elem (@str) {

			if($elem =~ /^(\w+)(\(((\w|\d|\.)+,?)*\))?\.?$/) {
				push @facts, $elem;
			}
		}
	}
	return @facts;
	
}

sub addCode {	#Adds code to input

	my $program = $_[0];
	my $code = $_[1];
	my @isAFile = stat($program);

	if(@isAFile) {
		open PROGRAM, ">>", $program;
		print PROGRAM "$code\n";
		close PROGRAM;
	}

	else {
		$program = \($_[0]);
		$$program = "$$program $code";
	}
		
}

sub getASFromFile {	#Gets the Answer Set from the file where the output was saved

	open RESULT, "<", "$_[0]" or die $!;
	my @result = <RESULT>;
	my @arr;
	foreach my $line (@result) {

		if($line =~ /\{\w*/) {
			$line =~ s/(\{|\})//g;
			#$line =~ s/\n//g;  # delete \n from $line
		        my @tmp = split(', ', $line);
			push @arr, @tmp;
		}

	}

	close RESULT;
	return @arr;
}

sub getAS { #Returns the Answer Sets from the array where the output was saved

	my @result = @_;
	my @arr;

	foreach my $line (@result) {


		if($line =~ /\{\w*/) {
			$line =~ s/(\{|\})//g;
			$line =~ s/(Best model:)//g;
		        my @tmp = split(', ', $line);
			push @arr, @tmp;
		}

	}

	return @arr;
}

sub statistics {	# Return an array of hashes in which the statistics of every predicate of every answerSets are stored
			# If a condition of comparison is specified(number of predicates) it returns the answer sets that satisfy
			# that condition 

	my @as = @{$_[0]};
	my @pred = @{$_[1]};
	my @num = @{$_[2]};
	my @operators = @{$_[3]};

	my @sets;
	my @ans;
	
	my $countAS = 0;
	my @stat;

	my $countPred;

	foreach my $elem (@as) {

		if($elem =~ /(\w+).*\n/) {
			push @{$sets[$countAS]}, $elem;
			if(_existsPred($1,\@pred)) {
				$stat[$countAS]{$1} += 1;
				$countAS += 1;
			}
		}

		elsif($elem =~ /(\w+).*/) {
			push @{$sets[$countAS]}, $elem;
			if(_existsPred($1,\@pred)) {
				$stat[$countAS]{$1} += 1;
			}
		}
	}

	my $comparison = 0;
	if(@num and @operators) {
		$comparison = 1;
	}
	elsif(@num and !@operators) {
		print "Error: comparison element missing";
		return @ans;
	}
	
	

	if($comparison) {
		my $size = @pred;
		my $statSize = @stat;

		for(my $j = 0; $j < $statSize; $j++) {
			for(my $i = 0; $i < $size; $i++) {

				my $t = $stat[$j]{$pred[$i]};

				if(_evaluate($t,$num[$i],$operators[$i])) {
					$countPred++;
				}
				else {
					$countPred = 0;
					break;
				}
			}

			if($countPred == $size) {
				push @ans , $sets[$j];
			}
			$countPred = 0;
		}
		return @ans;

	}

	return @stat;
}

sub _evaluate {		#private use only

	my $value = shift;
	my $num = shift;
	my $operator = shift;

	if($operator eq "==") {
		if($value == $num) {
			return 1;
		}
		return 0;
	}
	elsif($operator eq "!=") {
		if($value != $num) {
			return 1;
		}
		return 0;		
	}
	elsif($operator eq ">") {
		if($value > $num) {
			return 1;
		}
		return 0;
	}
	elsif($operator eq ">=") {
		if($value >= $num) {
			return 1;
		}
		return 0;
	}
	elsif($operator eq "<") {
		if($value < $num) {
			return 1;
		}
		return 0;
	}
	elsif($operator eq "<=") {
		if($value <= $num) {
			return 1;
		}
		return 0;
	}
	return 0;
}

sub mapAS {	#Mapping of the Answer Sets in an array of hashes

	my $countAS = 0;

	my @answerSets = @{$_[0]};

	my @second;
	if($_[1]) {
		@second = @{$_[1]};
	}

	my @third;
	if($_[2]) {
		@third = @{$_[2]};
	}

	my @selectedAS;
	
	my @predList;

	my @pred;

	if(@second) {
		if($second[0] =~ /\d+/) {

			@selectedAS = @second;
			if(@third) {
				@predList = @third;
			}

		}

		else {
			@predList = @second;
			if(@third) {
				@selectedAS = @third;
			}
		}
	}


	foreach my $elem (@answerSets) {


		if($elem =~ /(\w+).*\n/){
			if(@predList) {
				if(_existsPred($1,\@predList)) {
					push @{$pred[$countAS]{$1}}, $elem;
				}
			}
			else {
				push @{$pred[$countAS]{$1}}, $elem;
			}
			$countAS = $countAS + 1;
			
		}

		elsif($elem =~ /(\w+).*/) {
			if(@predList) {
				if(_existsPred($1,\@predList)) {
					push @{$pred[$countAS]{$1}}, $elem;
				}
			}
			else {
				push @{$pred[$countAS]{$1}}, $elem;
			}
		}
		
	}

	if(@selectedAS) {
		
		my $size = @selectedAS;

		my @selectedPred;


		for(my $i = 0; $i < $size; $i++) {
			my $as = $selectedAS[$i];
			push @selectedPred, $pred[$as];
		}

		return @selectedPred;
	}
	return @pred;

}

sub _existsPred {	#Verifies the existence of a predicate (private use only)

	my $pred = $_[0];
	my @predList = @{$_[1]};

	my $size = @predList;

	for(my $i = 0; $i < $size; $i++) {
		if($pred eq $predList[$i]) {
			return 1;
		}
	}
	return 0;
		
}

sub getPred {	#Returns the predicates from the array of hashes

	my @pr = @{$_[0]};
	return @{$pr[$_[1]]{$_[2]}};
}

sub getProjection {	#Returns the values selected by the user

	my @pr = @{$_[0]};
	my @projection;

	my @res = @{$pr[$_[1]]{$_[2]}};
	
	my $size = @res;
	my $fieldsStr;

	for(my $i = 0; $i < $size; $i++) {
		my $pred = @{$pr[$_[1]]{$_[2]}}[$i];
		if($pred =~ /(\w+)\((.+)\)/) {
			$fieldsStr = $2;
		}
		my @fields = split(',',$fieldsStr);
		push @projection , $fields[$_[3]-1];		
			
	}

	return @projection;
}

sub createNewFile {

	my $file = $_[0];
	my $code = $_[1];

	open FILE, ">", $file;
	print FILE "$code\n";
	close FILE;

}

sub addFacts {

	my $name = $_[0];
	my @facts = @{$_[1]};
	my $append = $_[2];
	my $filename = $_[3];
	
	open FILE, $append, $filename;

	foreach my $f (@facts) {
		print FILE "$name($f).\n";
	}
	close FILE;
}


1;
__END__

# 

=head1 NAME

AI::Logic::AnswerSet - Perl extension for embedding ASP (Answer Set Programming) programs in Perl.


=head1 SYNOPSIS

  use AI::Logic::AnswerSet;
  
  # invoke DLV( AnwerSetProgramming-based system) and save the stdoutput
  my @stdoutput = AI::Logic::AnswerSet::singleExec("3-colorability.txt");

  # parse the output
  my @res = AI::Logic::AnswerSet::getAS(@stdoutput);

  # map the results
  my @mappedAS = AI::Logic::AnswerSet::mapAS(\@res);

  # get a predicate from the results
  my @col = AI::Logic::AnswerSet::getPred(\@mappedAS,1,"col");

  # get a term of a predicate
  my @term = AI::Logic::AnswerSet::getProjection(\@mappedAS,1,"col",2);


=head1 DESCRIPTION

This extension allows to interact with DLV, an Artificial Intelligence system
for Answer Set Programming (ASP).
Please note that the DLV system must appear in the same folder of the perl program
and it must be renamed as "dlv";
DLV can be freely obtained at www.dlvsystem.com.
For further info about DLV and Answer Set Programming please start from www.dlvsystem.com.

The module was originally published as "ASPerl", but suffered from
some problems with the namespace, now changed. The module has been
also significantly rearranged according to the advices coming from the
community. Thank you all!
If you are using this module, please let us know: we are always
interested in end-users desires, and we wish to improve our library:
comments are truly welcome!

=head2 Methods

=head3 executeFromFileAndSave

This method allows to execute DLV with and input file and save the output in another file.

	AI::Logic::AnswerSet::executeFromFileAndSave("outprog.txt","dlvprog.txt","");

In this case the file "outprog.txt" consists of the result of the DLV invocation 
with the file "dlvprog.txt".
No code is specified in the third value of the method. It can be used to add code 
to an existing file or to a new one.

	AI::Logic::AnswerSet::executeFromFileAndSave("outprog.txt","dlvprog.txt",
	"b(X):-a(X). a(1).");
  
=head3 executeAndSave

To call DLV without an input file, directly writing the ASP code from the terminal, 
use this method, passing only the name of the output file.

	AI::Logic::AnswerSet::executeAndSave("outprog.txt");

Press Ctrl+D to stop using the DLV terminal and execute the program.

=head3 singleExec

Use this method to execute DLV whit several input files, including also
DLV options like "-nofacts".
The output will be stored inside an array.

	my @out = AI::Logic::AnswerSet::singleExec("3col.txt","nodes.txt","edges.txt","-nofacts");

Another way to use this method:

	my @out = AI::Logic::AnswerSet::singleExec();

In this way it will work like C<executeAndSave()> without saving the output to a file.

=head3 iterativeExec

This method allows to call multiples DLV executions for several instances of the same problem.
Suppose you have a program that calculates the 3-colorability of a graph; in this case
one might have more than a graph, and each graph instance can be stored in a different file.
A Perl programmer might want to work with the results of all the graphs she has in her files,
so this function will be useful for this purpose.
Use it like in the following:

	my @outputs = AI::Logic::AnswerSet::iterativeExec("3col.txt","nodes.txt","./instances");

In this case the nodes of each graph are the same, but not the edges.
Notice that in order to correctly use this method, the user must specify the path 
to the instances (the edges, in this case).

The output of this function is a two-dimensional array; each element corresponds to the result
of a single DLV execution, exactly as in the case of the function C<singleExec()>.

=head3 selectOutput

This method allows to get one of the results of C<iterativeExec>.

	my @outputs = AI::Logic::AnswerSet::iterativeExec("3col.txt","nodes.txt","./instances");
	my @out = AI::Logic::AnswerSet::selectOutput(\@outputs,0);

In this case the first output is selected.

=head3 getASFromFile

Parses the output of a DLV execution saved in a file and gather the answer sets.

	AI::Logic::AnswerSet::executeFromFileAndSave("outprog.txt","dlvprog.txt","");
	my @result = AI::Logic::AnswerSet::getASFromFile("outprog.txt");

=head3 getAS

Parses the output of a DLV execution and gather the answer sets.

	my @out = AI::Logic::AnswerSet::singleExec("3col.txt","nodes.txt","edges.txt","-nofacts");
	my @result = AI::Logic::AnswerSet::getAS(@out);

=head3 mapAS

Parses the new output in order to save and organize the results into a hashmap.

	my @out = AI::Logic::AnswerSet::singleExec("3col.txt","nodes.txt","edges.txt","-nofacts");
	my @result = AI::Logic::AnswerSet::getAS(@out);
	my @mappedAS = AI::Logic::AnswerSet::mapAS(@result);

The user can set some constraints on the data to be saved in the hashmap, such as predicates, or answer sets, or both.

	my @mappedAS = AI::Logic::AnswerSet::mapAS(@result,@predicates,@answerSets);

For instance, think about the 3-colorability problem: imagine to 
have the edges in the hashmap, and to print the edges contained in the third answer set
returned by DLV; this is an example of the print instruction, useful to understand how
the hashmap works:

	print "Edges: @{$mappedAS[2]{edge}}\n";

In this case, we are printing the array containing the predicate "edge".

=head3 getPred

Easily manage the hashmap and get the desired predicate(see the print example
described in the method above):

	my @edges = AI::Logic::AnswerSet::getPred(\@mappedAS,3,"edge");

=head3 getProjection

Returns the projection of the n-th term of a specified predicate.
Suppose that we have the predicate "person" C<person(Name,Surename);> and
that we just want the surenames of all the instances of "person":

	my @surenames = AI::Logic::AnswerSet::getProjection(\@mappedAS,3,"person",2);

The parameters are, respectively: hashmap, number of the answer set, name of the predicate,
position of the term.

=head3 statistics

This method returns an array of hashes with some stats of every predicate of every answer set,
namely the number of occurrences of the specified predicates of each answer set.
If a condition is specified(number of predicates), only the answer sets that satisfy
the condition are returned.

	my @res = AI::Logic::AnswerSet::getAS(@output);
	my @predicates = ("node","edge");
	my @stats = AI::Logic::AnswerSet::statistics(\@res,\@predicates);

In this case the data structure returned is the same as the one returned by C<mapAS()>.
Hence, for each answer set (each element of the array of hashes), the hashmap will appear 
like this:

	{
		node => 6
		edge => 9
	}

This means that for a particular answer set we have 6 nodes and 9 edges.
In addition, this method can be used with some constraints:

	my @res = AI::Logic::AnswerSet::getAS(@output);
	my @predicates = ("node,"edge");
	my @numbers = (4,15);
	my @operators = (">","<");
	my @stats = AI::Logic::AnswerSet::statistics(\@res,\@predicates,\@numbers,\@operators);

Now the functions returns the answer sets that satisfy the condition, i.e., an answer set
is returned only if the number of occurrences of the predicate "node" is higher than 4, and the number of occurrences of the predicate "edge" less than 15.

=head3 getFacts

Get the logic program facts from a file or a string.

	my @facts = AI::Logic::AnswerSet::getFacts($inputFile);

or

	my $code = "a(X):-b(X). b(1). b(2).";
	my @facts = AI::Logic::AnswerSet::getFacts($code);

DLV code can be freely exploited, with the only constraint of putting a space between rules
or facts.
This is an example of wrong input code:

	my $code = "a(X):-b(X).b(1).b(2).";

=head3 addCode

Use this method to quiclky add new code to a string or a file.

	my $code = "a(X):-b(X). b(1). b(2).";
	AI::Logic::AnswerSet::addCode($code,"b(3). b(4).");

or

	my $file = "myfile.txt";
	AI::Logic::AnswerSet::addCode($file,"b(3). b(4).");

=head3 createNewFile

Creates a new file with some code.

	AI::Logic::AnswerSet::createNewFile($file,"b(3). b(4).");

=head3 addFacts

Quiclky adds facts to a file. Imagine to have some data(representing facts) 
stored inside an array; just use this method to put them in a file and give it a name.

	AI::Logic::AnswerSet::addFacts("villagers",\@villagers,">","villagersFile.txt");

In the example above, "villagers" will be the name of the facts; C<@villagers> is the array 
containing the data; ">" is the file operator(will create a new file, in this case); 
"villagersFile.txt" is the filename. The file will contain facts of the form "villagers(X)",
for each "X", appearing in the array C<@villagers>.


=head1 SEE ALSO

www.dlvsystem.com

=head1 AUTHOR

Ferdinando Primerano, E<lt>levia@cpan.orgE<gt>
Francesco Calimeri, E<lt>calimeri@mat.unical.itE<gt>

This work started within the bachelor degree thesis program of the
Computer Science course at Department of Mathematics of the University
of Calabria.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Ferdinando Primerano , Francesco Calimeri

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

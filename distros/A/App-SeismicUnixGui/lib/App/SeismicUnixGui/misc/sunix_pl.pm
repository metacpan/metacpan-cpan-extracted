package App::SeismicUnixGui::misc::sunix_pl;

=head1 DOCUMENTATION


=head2 SYNOPSIS 

 PERL PROGRAM NAME: sunix_pl 
 AUTHOR: 	Juan Lorenzo
 DATE: 		June 22 2017 
 			Oct 1 2018 V0.0.2

 DESCRIPTION  Parse perl scripts written by L_SU
     

 BASED ON:


=cut

=head2 USE

=head3 NOTES

=head4 Examples


=head2 CHANGES and their DATES 

	V0.0.2 
		10.1.2018 
		gaps and non-standard characters in a string are allowable e.g. windowtitle='Strange units (m/Pa)

 
=cut

use Moose;
our $VERSION = '0.0.2';

use Text::ParseWords;
use aliased 'App::SeismicUnixGui::misc::perl_header';
use aliased 'App::SeismicUnixGui::misc::perl_use_pkg';
use aliased 'App::SeismicUnixGui::misc::perl_instantiate';
use aliased 'App::SeismicUnixGui::misc::pod_declare';
use aliased 'App::SeismicUnixGui::misc::perl_declare';
use aliased 'App::SeismicUnixGui::misc::perl_inbound';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

=head2 instantiate modules

=cut

my $get               = L_SU_global_constants->new();
my $get_header        = perl_header->new();
my $get_use_pkg       = perl_use_pkg->new();
my $pod_declare       = pod_declare->new();
my $get_declare       = perl_declare->new();
my $get_inbound       = perl_inbound->new();
my $get_instantiation = perl_instantiate->new();

=head2 declasre variables

=cut

my $var          = $get->var();
my $empty_string = $var->{_empty_string};
my $false        = 0;
my $true         = 1;

my @lines = ();
my $file_out;
my $file_in;
my $self;

my @all_lines        = ();
my @lines_wth_string = ();

=head2 initialize shared anonymous hash 

  key/value pairs

=cut

my $sunix_pl = {
	_all_lines_aref        => \@all_lines,
	_contain_line_contents => \@all_lines,
	_contain_prog_lines    => \@all_lines,
	_end_line_contents     => \@all_lines,
	_end_line_nums         => \@all_lines,
	_end_prog_lines        => \@all_lines,
	_good_prog_indices_ref => '',
	_first_word            => '',
	_last_word             => '',

	#      _line_contents    	=> \@all_lines,
	_line_nums           => \@all_lines,
	_labels_aref2        => @all_lines,
	_message1            => $false,
	_num_lines           => '',
	_num_progs           => \@all_lines,
	_path                => '',
	_perl_file_in        => '',
	_prog_names          => \@all_lines,
	_prog_versions       => '',
	_file_in             => '',
	_file_out            => '',
	_string              => '',
	_start_line_contents => \@all_lines,
	_start_line_nums     => '',
	_start_prog_lines    => \@all_lines,
	_values_aref2        => @all_lines,
};

=head2 _good_sunix_params

	extract labels and parameter values 
	for each program

=cut

sub _good_sunix_params {
	my ($self) = @_;

	my @prog_lines_aref_holder;    # holds several array refs
	my @values_aref_holder;        # holds several array refs
	my @labels_aref_holder;        # holds several array refs
	my $ref_prog_lines;
	my @good_prog_index;

	my $size = $sunix_pl->{_num_progs};

	# print("sunix_pl, _good_sunix_params,num_progs: $size \n");
	my @all_prog_names = @{ $sunix_pl->{_prog_names} };

	my $prog_number = 0;

	# for each program, collect lines of information
	for ( my $prog_count = 0; $prog_count < $size; $prog_count++ ) {

		my @extract;
		my ( $line_num, $first, $last );

		$first = $sunix_pl->{_start_prog_lines}[$prog_count];
		$last  = $sunix_pl->{_end_prog_lines}[$prog_count];

		# print("sunix_pl, _good_sunix_params, prog num: $prog_count, name: $all_prog_names[$prog_count]\n");
		# print("sunix_pl, _good_sunix_params,first line : $first\n");
		# print("sunix_pl, _good_sunix_params,last line : $last\n");

		# monotonically increasing line numbers are an error check
		if ( $last >= $first ) {

			# extract coded sunix program lines
			for ( my $count = 0, $line_num = $first; $line_num < $last; $count++, $line_num++ ) {
				$extract[$count] = @{ $sunix_pl->{_all_lines_aref} }[$line_num];

				# print("sunix_pl,_good_sunix_params, lines for each program: $extract[$count]\n")
			}
			push @prog_lines_aref_holder, \@extract;
		} else {

			# print("sunix_pl, _good_sunix_params,Warning: bad line numbers for $all_prog_names[$prog_count]\n");
		}
	}    # for each progam

	# extract parameter names/labels and values
	# from lines in each perl program
	for ( my $prog_count = 0, my $op_prog_count = 0; $prog_count < $size; $prog_count++ ) {

		my $ref_prog_lines = $prog_lines_aref_holder[$prog_count];
		my ( @temp_values, @temp_labels );
		my $value_index = 0;
		my $label_index = 0;

		my ( @labels_holder, @values_holder );    # holds one array of values and labels per program
												  # print("sunix_pl,_good_sunix_params,prog_lines: @$ref_prog_lines\n");
												  # print("sunix_pl,_good_sunix_params,prog#: $prog_count\n");
			# print("\n sunix_pl,_good_sunix_params,prog_name: $sunix_pl->{_prog_names}[$prog_count]\n");

		# extract labels and parameter values from lines
		foreach my $line (@$ref_prog_lines) {
			my @values;
			my @values1;
			my @values2;
			my @labels = ();
			my ( $line1, $line2 );

			# print(" sunix_pl,_good_sunix_params_values,line:--$line");

			# from start ^ to end $ of the string
			# matches label names, e.g., ->(agc) with
			# look behind the arrow head and exclude the arrow (?=<  ....) >))
			# look for zero or more spaces between the arrow head and the first parenthesis
			# exclude any spaces
			# extract () only the text

			@labels = $line =~ m/(?<=>)\s*(\w+)/g;
#			print("sunix_pl,_good_sunix_params,labels:---@labels\n");
			my $label_length = scalar @labels;

			#print("sunix_pl,_good_sunix_params,label length:---$label_length\n");

			# zero more spaces between the first parenthesis and
			# [ the word or number (+ or -ve)
			# matches the following values between parentheses
			# 1 '1' 111 '111' $on 'on' on -100 -100.00 100.00 -.5
			# '1,2,3', or quotemeta(ANYTHING)
			# or $sufile[1]

			# print("1. sunix_pl,_good_sunix_params, line=$line \n");
			# In order to get the useful value
			# Step 1

			# remove ONLY the prefix and the suffix inside the quotemeta parentheses i.e. $DATA_SEISMIC_SU.'/'. and .$suffix_su
			#  substitute  $                  \$
			#  substitute  one or more words \w+
			#  substitute  .'/'.              \.'\/'\.

			$line =~ s/quotemeta\(\$\w+\.'\/'\./quotemeta\(/;
#			print("1. sunix_pl,_good_sunix_params, line=$line \n");

			# Step 2
			# substitute quotemeta with nothing
			# substitute
			$line =~ s/quotemeta//;

			# print("2. sunix_pl,_good_sunix_params, line=$line \n");

			# Step 3
			# substitute double parentheses with single parentheses
			$line =~ s/\(\(/\(/;
			$line =~ s/\)\)/\)/;

			# Step 4
			# substitute .$suffix_su) with )
			# substitute
			$line =~ s/\.\$\w+\);/\)/;

			# print("2. sunix_pl,_good_sunix_params, line=$line \n");

			# group anyhting which lies within parentheses \( \)
			@values = $line =~ m/\((\'\w+\'|.+|(\(.+\))|\w+|\$\w+|-?(.|\d+)\.\d+)\)/g;

			print("4. sunix_pl,_good_sunix_params, values = @values, values[0]=$values[0]\n");

			#   TBD  		@values = $line=~m/\((\'\w+\'|.+|(quotemeta\(.+\))|\w+|\$\w+|-?(.|\d+)\.\d+)\)/g;

			#@values length is longer by one **
			my $value_length = scalar @values;

			# print("1. sunix_pl,_good_sunix_params,prog: $prog_count number of values:---$value_length \n");
			if ( $value_length > 0 ) {

				# ** this one never works: print("1. sunix_pl,_good_sunix_params,prog: $prog_count values:---@values---\n");
				print("sunix_pl,_good_sunix_params, value[0] =-- $values[0]---\n\n");
			} elsif ( !$values[0] ) {
				print("sunix_pl,_good_sunix_params, values[0] is empty: =-----\n\n");
			} else {
				print("sunix_pl,_good_sunix_params, value[0] =---$values[0]--\n\n");
			}

			# assume label and value lengths are always 1
			if ( $label_length > 0 and $value_length > 0 ) {
				$labels_holder[$label_index] = $labels[0];
				$values_holder[$value_index] = $values[0];
				$value_index++;
				$label_index++;

				# print("1. sunix_pl,_good_sunix_params,values[0]:--$values[0]\n");
				# print("1. sunix_pl,_good_sunix_params,labels[0]:--$labels[0]\n");
				# print("1. sunix_pl,_good_sunix_params,values_holder:--@values_holder\n");
				# print("1. sunix_pl,_good_sunix_params,values_holder:--@values_holder----prog_count:$prog_count\n");
			} else {

				# print("sunix_pl,_good_sunix_params_values, either no label or value exists\n");
			}

		}    # over each line in for a single  program

		# print("2. sunix_pl,_good_sunix_params_values,prog: $prog_count---temp values:---@temp_values\n\n");
		# store value and label for each program only if a value has been found
		my $long = ( $value_index - 1 );
		if ( $long > -1 ) {    #
			@temp_values                        = @values_holder[ 0 .. $long ];
			@temp_labels                        = @labels_holder[ 0 .. $long ];
			$values_aref_holder[$op_prog_count] = \@temp_values;
			$labels_aref_holder[$op_prog_count] = \@temp_labels;
			$good_prog_index[$op_prog_count]    = $prog_count;    # remember which prgrams are useful for later
			$op_prog_count++;

			# print(" sunix_pl,_good_sunix_params,prog: $prog_count---temp values:---@temp_values\n\n");
			# print(" sunix_pl,_good_sunix_params,prog: $prog_count---values:---@{$values_aref_holder[$prog_count]}\n\n");
			# print(" sunix_pl,_good_sunix_params,prog: $prog_count---temp labels:---@temp_labels\n\n");
			# print(" sunix_pl,g_good_sunix_params,prog: $prog_count---labels:---@{$labels_aref_holder[$prog_count]}\n\n");
		} else {

			# label and values are not assigned to array elements
			# BUT array continues to increment
			# print("warning: sunix_pl,_good_sunix_params, no value found: long = $long\n");
		}

	}    # over each program

	# for all programs
	# my $num_progs = $size;
	# print("sunix_pl,i/p num_progs: $num_progs\n");

	$sunix_pl->{_labels_aref2} = \@labels_aref_holder;
	$sunix_pl->{_values_aref2} = \@values_aref_holder;

	my $new_num_progs = scalar @values_aref_holder;

	#print("sunix_pl,o/p num_progs: $new_num_progs\n");

	#for(my $i=0; $i < $new_num_progs; $i++) {
	#	my $num_params = scalar @{$values_aref_holder[$i]};
	# print("sunix_pl, prog: $i---num_params: $num_params---\n");
	# print("sunix_pl, original good program index: $good_prog_index[$i]\n");

	#for (my $j=0; $j <$num_params; $j++ ){
	#			print("sunix_pl,_good_sunix_params,labels: @{@{$sunix_pl->{_labels_aref2}}[$i]}[$j]\n");
	#			print("sunix_pl,_good_sunix_params,values: @{@{$sunix_pl->{_values_aref2}}[$i]}[$j]\n");
	#		}
	#}
	$sunix_pl->{_good_prog_indices_ref} = \@good_prog_index;

	# print("sunix_pl,_good_sunix_names,good_prog_indices, @{$sunix_pl->{_good_prog_indices_ref}} \n");
	return ($sunix_pl);
}

=pod sub all
inbound
 open  and write 
 to the file

=cut

sub all {
	my ($self) = @_;

	# = shift;
	open( $file_out, '>', @{ $self->{_file_out} }[1] )
		|| print("Can't open file_out, $!\n");

	#    header();
	#    use_pkg();
	#   use_external();
	#
	#    instantiation();
	#   instantiation_external();
	#
	#    for ($i=0; $i < $max_progs; $i++) {
	#    set_programs()
	#    params();
	#    }
	#
	#    pod_declare();
	#    declare();
	#    declare_external();
	write_inbound();

	flows();

	run();

	logs();

	close($file_out);
}

=head2 sub declare

=cut

sub declare {

	my $ref_array = $get_declare->section();

	foreach (@$ref_array) {
		print $file_out "$_\n";
	}
}

=head2 sub flows

=cut

sub flows {

	print $file_out "\n" . ' $flow[1] = $run->modules(\@items);' . "\n\n";

}

=head2 get_all_labels

 	get all active and default 
 	parameter names from a program in a perl flow

=cut

=head2 sub get_error_messages

=cut

sub get_error_messages {
	my ($self) = @_;

	if ( $sunix_pl->{_messages1} ) {

		my $error_message = {
			_program_name   => 'sunix_pl',
			_message_number => 1
		};

		my $results = $error_message;

		return ($results);

	} else {

		return ();
		print("sunix_pl, get_error_messages, none to return\n");
	}

}

=head2 sub get_lines_progs_contain

 return line numbers that contain a particular
 word or string 


=cut

sub get_lines_progs_contain {
	my ($self) = @_;

	my ( $line, $count_all_lines, $case_num );
	my ( @line_nums, @line_contents );

	if ( $sunix_pl->{_string} ) {

		my $string = $sunix_pl->{_string};

		# print("sunix_pl,get_lines_progs_contain, string:$string\n");

		$count_all_lines = 0;
		$case_num        = 0;

		my @all_lines = @{ $sunix_pl->{_all_lines_aref} };

		my $length = scalar @all_lines;

		# print("sunix_pl, get_lines_progs_contain, num_lines= $length, all_lines[104]= $all_lines[104]\n");

		for ( my $i = 0; $i < $length; $i++ ) {

			$line = $all_lines[$i];

			# print("sunix_pl, get_lines_progs_contain, line= $i\n");

			if ( $line =~ /$string/ ) {

				$line_nums[$case_num]     = $count_all_lines;
				$line_contents[$case_num] = $line;
				$case_num++;

				# print("sunix_pl, get_lines_progs_contain, line= $i\n");
			}
			$count_all_lines++;
		}

		$sunix_pl->{_contain_prog_lines}    = \@line_nums;
		$sunix_pl->{_contain_line_contents} = \@line_contents;
		return ( \@line_nums );

	} else {
		print("sunix_pl, get_lines_progs_contain, missing string\n");
	}

}

=head2 sub get_lines_progs_end_with

 return line numbers that contain a particular
 word or string 
   print("progs_end_with,@{$sunix_pl->{_end_prog_lines}}\n");i
   print("progs_end_with,@{$sunix_pl->{_end_line_contents}}\n");

=cut

sub get_lines_progs_end_with {
	my ($self) = @_;
	my ( $line, $count_all_lines, $case_num );
	my ( @line_nums, @line_contents );

	my $string = $sunix_pl->{_last_word};

	$count_all_lines = 0;
	$case_num        = 0;

	my @all_lines = $sunix_pl->{_all_lines_aref};

	foreach my $line (@all_lines) {
		if ( $line =~ /$string/ ) {
			$line_nums[$case_num]     = $count_all_lines;
			$line_contents[$case_num] = $line;
			$case_num++;
		}
		$count_all_lines++;
	}

	$sunix_pl->{_end_prog_lines}    = \@line_nums;
	$sunix_pl->{_end_line_contents} = \@line_contents;

	return ( \@line_nums );
}

=head2 sub get_lines_progs_start_with

 return line numbers that contain a particular
 word or string 
  print("$case_num cases in $count_all_lines lines,\n");  
  print("at line(s): @{$sunix_pl->{_line_nums}}\n");  
  print("progs_start_with, length is $size\n"); 
  print ("word is $word\n");
  print ("word is $string\n");

=cut

sub get_lines_progs_start_with {
	my ($self) = @_;

	my ( $line, $count_all_lines, $case_num );
	my ( @line_nums, @line_contents );
	my $string = $sunix_pl->{_first_word};

	$count_all_lines = 0;
	$case_num        = 0;

	my @all_lines = $sunix_pl->{_all_lines_aref};

	foreach my $line (@all_lines) {
		if ( $line =~ /$string/ ) {
			$line_nums[$case_num]     = $count_all_lines;
			$line_contents[$case_num] = $line;
			$case_num++;
		}
		$count_all_lines++;
	}

	$sunix_pl->{_start_prog_lines}    = \@line_nums;
	$sunix_pl->{_start_line_contents} = \@line_contents;

	return ( \@line_nums );
}

=head2 sub get_num_good_progs

 get_good_sunix_params should have been run first

=cut

sub get_num_good_progs {
	my ($self) = @_;

	my $num_good_progs = scalar @{ $sunix_pl->{_good_prog_names} };

	# print("sunix_pl, get_num_progs: $num_good_progs\n");
	return ($num_good_progs);
}

=head2 sub get_num_progs

=cut

sub get_num_progs {
	my ($self) = @_;

	my $num_progs = $sunix_pl->{_num_progs};

	# print("sunix_pl, get_num_progs: $num_progs\n");
	return ($num_progs);
}

=cut 


#
#=head2 sub set_progs_end_with
#
# return line numbers that contain a particular
# word or string 
#   print("progs_end_with,@{$sunix_pl->{_end_prog_lines}}\n");i
#   print("progs_end_with,@{$sunix_pl->{_end_line_contents}}\n");
#
#=cut
#
# sub set_progs_end_with {
#   my ($self,$word) = @_;
#   $sunix_pl->{_last_word} = $word;
#  
#   return();
#}
#
#
#=head2 sub set_progs_start_with
#
# return line numbers that contain a particular
# word or string 
#  print("$case_num cases in $count_all_lines lines,\n");  
#  print("at line(s): @{$sunix_pl->{_line_nums}}\n");  
#  print("set_progs_start_with, length is $size\n"); 
#  print ("word is $word\n");
#  print ("word is $string\n");
#
#=cut
#
# sub set_progs_start_with {
#   my ($self,$word) = @_;
#   
#   $sunix_pl ->{_first_word} = $word;
#   return();
#}

#=head2 sub print
#
# return characters from particular lines
# particular lines = $ref_line 
#
#=cut
#
# sub  print{
#   my ($self,$hash_ref_line) = @_;
#   my $i=0;
#   my ($seq,@print);
#   #print( "self is $self,\n"); 
#   #print("prog_line is @$ref_line\n");
#   foreach  $seq  (@{$ref_line}) {
#     $print[$i] = @{$sunix_pl->{_all_lines_aref}}[@{$ref_line}[$i]];
#     #print ("line: $i @{$ref_line}[$i]\n");
#     $i++;
#   }i
#  return(\@print);
#}

=head2 get_all_labels

 	return all active and default 
 	parameter labels from a program in a perl flow

=cut

=head2 get_all_values

 	return all active and default 
 	parameter values from a program in a perl flow

=cut

=head2 sub get_all_sunix_names

   foreach my $keys (sort keys %$psunix) {
     print("keys $keys value @{$sunix_pl->{$keys}}[1]\n");
   }
   this subroutine needs file read by sub lines_with 
     print ("i: $i fields are: @{$hash_ref->{_line_contents}}[$i] \n");
	print("self is $self hash ref is $hash_ref\n");

=cut

sub get_all_sunix_names {

	my ($self) = @_;
	my $i = 0;
	my $line;
	my @fields = ();
	my ( @prog_name, @extraction );

	foreach ( @{ $sunix_pl->{_start_line_contents} } ) {

		# print ("$i fields are: @{$sunix_pl->{_start_line_contents}}[$i] ");
		$line = @{ $sunix_pl->{_start_line_contents} }[$i];

		# print ("$i line is: $line  ");
		# match in list format @fields 		=
		# g  search  globally
		# \s match any whitespace character
		# +  match \s one or more times
		# [A-za-z]+ match any letter one or more times
		# [0-9]*    match any number, none or more times
		@fields = $line =~ /\s+\$[A-za-z]+[0-9]*[A-za-z]+[0-9]*/g;

		# print ("sunix_pl,get_all_sunix_names, $i field 0 is:...$fields[0]...\n ");

		@extraction = split /\s+\$/, $fields[0], 2;

		# print("sunix_pl,get_all_sunix_names, $i  prog_name [$extraction[1]]\n");

		$prog_name[$i] = $extraction[1];
		$i++;
	}
	$sunix_pl->{_prog_names} = \@prog_name;

	# print("sunix_pl, get_all_sunix_names, sunix_names, @{$sunix_pl->{_prog_names}}\n");
	return ( \@prog_name );
}

=head2 sub get_all_versions

=cut

sub get_all_versions {
	my ($self) = @_;
	my @version;

	#print("self is $self array ref is $sunix_pl->{_prog_versions}\n");
	my $num_progs = scalar @$sunix_pl{_num_progs};

	#print("num_progs $num_progs\n");
	# always first program is version 1
	$version[0] = 1;

	# 2nd program
	for ( my $this = 1; $this < $num_progs; $this++ ) {
		$version[$this] = 1;
		for ( my $up_to = 0; $up_to < $this; $up_to++ ) {
			if ( @{ $sunix_pl->{_prog_names} }[$this] eq @{ $sunix_pl->{_prog_names} }[$up_to] ) {
				$version[$this]++;
			}
		}
	}

	$sunix_pl->{_prog_versions} = \@version;

	# print("versions, @{$sunix_pl->{_prog_versions}}\n");
	# print("versions, names:@{$sunix_pl->{_prog_names}}\n");
	return ( \@version );
}

=head2 sub get_good_sunix_names

	only those sunix programs
	that have useful parameter
	values and labels
	
	MUST run get_good_sunix_params first (externally called)
	to have 
	$good_prog_indices_ref

=cut

sub get_good_sunix_names {

	my ($self) = @_;
	my ( @good_prog_indices, @all_prog_names );
	my (@good_prog_names);
	my $good_prog_indices = $sunix_pl->{_good_prog_indices_ref};

	if ($good_prog_indices) {
		@good_prog_indices = @{ $sunix_pl->{_good_prog_indices_ref} };

		# print("sunix_pl,get_good_sunix_names,good_prog_indices, @good_prog_indices \n");

		@all_prog_names = @{ $sunix_pl->{_prog_names} };

		# print("sunix_pl,get_good_sunix_names,all_prog_names: @all_prog_names \n");
		my $length = scalar @good_prog_indices;

		for ( my $i = 0; $i < $length; $i++ ) {

			my $good_idx = $good_prog_indices[$i];
			$good_prog_names[$i] = $all_prog_names[$good_idx];
		}

		$sunix_pl->{_good_prog_names} = \@good_prog_names;

		# print("sunix_pl, get_good_sunix_names, @{$sunix_pl->{_good_prog_names}}\n");
		return ( \@good_prog_names );

	} else {

		print("suix_pl,warning: get_good_sunix_names: must run sunix_params first\n");

		_get_good_sunix_params();
		@good_prog_indices = @{ $sunix_pl->{_good_prog_indices_ref} };

		# print("sunix_pl,get_good_sunix_names,good_prog_indices, @good_prog_indices \n");

		@all_prog_names = @{ $sunix_pl->{_prog_names} };

		# print("sunix_pl,get_good_sunix_names,all_prog_names: @all_prog_names \n");
		my $length = scalar @good_prog_indices;
		for ( my $i = 0; $i < $length; $i++ ) {
			my $good_idx = $good_prog_indices[$i];
			$good_prog_names[$i] = $all_prog_names[$good_idx];
		}

		$sunix_pl->{_good_prog_names} = \@good_prog_names;

		#print("sunix_pl, get_good_sunix_names, @{$sunix_pl->{_good_prog_names}}\n");
		return ( \@good_prog_names );
	}
}

=head2 get_good_sunix_params

	From a file containing a perl-scripted flow,
	extract labels and parameter values 
	for each program
	
	10-1-2018 sunix text sequences are now allowable gaps via quotemeta
	10-5-2018 sunix text sequences can have suffixes and prefixes to the value as well
	11-25-2018 account for programs with NULL parameters, e.g. suspecfx

=cut

sub get_good_sunix_params {
	my ($self) = @_;

	use File::Basename;

	my @prog_lines_aref_holder;    # holds several array refs
	my @values_aref_holder;        # holds several array refs
	my @labels_aref_holder;        # holds several array refs
	my $ref_prog_lines;
	my @good_prog_index;

	my $size = $sunix_pl->{_num_progs};

#	print("sunix_pl, get_good_sunix_params,num_progs: $size \n");
	my @all_prog_names = @{ $sunix_pl->{_prog_names} };

	my $prog_number = 0;

	# for each program, collect lines of information
	for ( my $prog_count = 0; $prog_count < $size; $prog_count++ ) {

		my @extract;
		my ( $line_num, $first );
		my $last = 9999;    # very large default

		$first = $sunix_pl->{_start_prog_lines}[$prog_count];
		$last  = $sunix_pl->{_end_prog_lines}[$prog_count];

#		print("1. sunix_pl, get_good_sunix_params, prog num: $prog_count, name: $all_prog_names[$prog_count]\n");
#		print("sunix_pl, get_good_sunix_params,first line : $first\n");
#		print("sunix_pl, get_good_sunix_params,last line : $last\n");

		# monotonically increasing line numbers are an error check
		if ( $last >= $first ) {

			# print("sunix_pl,get_good_sunix_params, lines for each program: @{$sunix_pl->{_all_lines_aref}} \n");

			# extract coded sunix program lines
			for ( my $count = 0, $line_num = $first; $line_num < $last; $count++, $line_num++ ) {
				$extract[$count] = @{ $sunix_pl->{_all_lines_aref} }[$line_num];

				# print("sunix_pl,get_good_sunix_params, lines with parameter names and their values, for each program: $extract[$count]\n")
			}
			push @prog_lines_aref_holder, \@extract;

		} else {
			print("sunix_pl, get_good_sunix_params,Warning: bad line numbers for $all_prog_names[$prog_count]\n");
		}
	}    # for each progam

	# extract parameter names/labels and values
	# from lines in each program
	for ( my $prog_count = 0, my $op_prog_count = 0; $prog_count < $size; $prog_count++ ) {

		my $ref_prog_lines = $prog_lines_aref_holder[$prog_count];
		my ( @temp_values, @temp_labels );
		my $value_index = 0;
		my $label_index = 0;

		# holds one array of values and labels per program
		my ( @labels_holder, @values_holder );

		# print("sunix_pl,get_good_sunix_params,prog_lines: @$ref_prog_lines\n");
		# print("sunix_pl,get_good_sunix_params,prog#: $prog_count\n");
		# print("\n sunix_pl,get_good_sunix_params,prog_name: $sunix_pl->{_prog_names}[$prog_count]\n");

		# extract labels and parameter values from lines
		foreach my $line (@$ref_prog_lines) {
			my @values;

			# $values[0] = $empty_string; # initialize empty
			my @values1;
			my @values2;
			my @labels = ();
			my ( $line1, $line2 );

			# print(" 893: sunix_pl,get_good_sunix_params_values,line:--$line\n");

			# from start ^ to end $ of the string
			# matches label names, e.g., ->(agc) with
			# look behind the arrow head and exclude the arrow (?=<  ....) >))
			# look for zero or more spaces between the arrow head and the first parenthesis
			# exclude any spaces
			# extract () only the text

			@labels = $line =~ m/(?<=>)\s*(\w+)/g;

#			print("sunix_pl,get_good_sunix_params,labels:---@labels\n");
			my $label_length = scalar @labels;

			# print("sunix_pl,get_good_sunix_params,label length:---$label_length\n");

			# zero more spaces between the first parenthesis and
			# [ the word or number (+ or -ve)
			# matches the following values between parentheses
			# 1 '1' 111 '111' $on 'on' on -100 -100.00 100.00 -.5
			# '1,2,3', or quotemeta(ANYTHING)
			# or $sufile[1]

#			print("1. sunix_pl,get_good_sunix_params, line=$line \n");
			# In order to get the useful value
			# Step 1

			# remove ONLY the prefix and the suffix inside the quotemeta parentheses i.e. $DATA_SEISMIC_SU.'/'. and .$suffix_su
			#  substitute  $                  \$
			#  substitute  one or more words \w+
			#  substitute  .'/'.              \.'\/'\.

			$line =~ s/quotemeta\(\$\w+\.'\/'\./quotemeta\(/;

#			print("1. sunix_pl,get_good_sunix_params, line=$line \n");

			# Step 2
			# substitute quotemeta with nothing
			# substitute
			$line =~ s/quotemeta//;

			#print("2. sunix_pl,get_good_sunix_params, line=$line \n");

			# Step 3
			# substitute double parentheses with single parentheses
			$line =~ s/\(\(/\(/;
			$line =~ s/\)\)/\)/;

			# print("21. sunix_pl,get_good_sunix_params, line=$line \n");
			# Step 4
			# substitute .$suffix_su) with )
			# substitute
			$line =~ s/\.\$\w+\);/\)/;

#			print("Step 4 sunix_pl,get_good_sunix_params, line=$line \n");
			#Step 5
			# substitute regular extensions )
			# e.g. .bin .txt .SGY .sgy .SEGY .segy)
			$line =~ s/\.[a-z]+\);/\)/;
			$line =~ s/\.[A-Z]+\);/\)/;

#			print("Step 5 sunix_pl,get_good_sunix_params, line=$line \n");

			# group anything which lies within parentheses \( \)
			@values = $line =~ m/\((\'\w+\'|.+|(\(.+\))|\w+|\$\w+|-?(.|\d+)\.\d+)\)/g;

			# print("4. sunix_pl,get_good_sunix_params, values = @values, values[0]=$values[0]\n");

			# extract name, path will however affect Project parameters which are directories
			# my ($name,$path) = fileparse($values[0]);

			# print("5. sunix_pl,get_good_sunix_params, name\n");

			#@values length is longer by one **
			my $value_length = scalar @values;

			# print("1. sunix_pl,get_good_sunix_params,prog: $prog_count number of values:---$value_length \n");
			if ( $value_length > 0 ) {

				# ** this one never works: print("1. sunix_pl,get_good_sunix_params,prog: $prog_count values:---@values---\n");
				# print ("sunix_pl,get_good_sunix_params, value[0] =-- $values[0]---\n\n");
			} elsif ( !$values[0] ) {

				# print ("sunix_pl,get_good_sunix_params, values[0]
				# is empty: =-----\n\n");
			} else {
				print("sunix_pl,get_good_sunix_params, unexpected value[0] =---$values[0]--\n\n");
			}

			# number of labels and values are always >= 1
			if ( $label_length >= 1 or $value_length >= 1 ) {

				$values_holder[$value_index] = $values[0];
				$labels_holder[$label_index] = $labels[0];
				$value_index++;
				$label_index++;

				# if($values[0]) { print("1. sunix_pl,get_good_sunix_params,values[0]:--$values[0]--\n")};
				# if($labels[0]) { print("1. sunix_pl,get_good_sunix_params,labels[0]:--$labels[0]--\n")};
				# print("1. sunix_pl,get_good_sunix_params,values_holder:--@values_holder\n");
				# print("1. sunix_pl,get_good_sunix_params,values_holder:--@values_holder----prog_count:$prog_count\n");
			} else {
				print("sunix_pl,get_good_sunix_params_values, either no value or label exists\n");
			}

			# USER ERRORS
			# CASE 1 : label that is not 'clear' but is is empty
			# print("1. sunix_pl,get_good_sunix_params,labels[0]:--$labels[0]--\n");
			if ( $labels[0] ne 'clear'
				and ( !$labels[0] or $labels[0] eq $empty_string ) ) {

				# print(
				# 	"1 USER ERROR: edit your flow; Cannot continue; A program is missing all its values\n"
				# );
				#  print(
				# 	"prog_name is  $sunix_pl->{_prog_names}[$prog_count]\n\n ");
				$sunix_pl->{_message1} = $true;

				# CASE 2: label exists and is not 'clear'
			} elsif ( $labels[0] ne 'clear'
				and ( $labels[0] or $labels[0] ne $empty_string ) ) {

				# Case 2A: value is empty
				if ( !$values[0] or $values[0] eq $empty_string ) {

					# print("2 USER ERROR: Gedit your flow; Cannot continue; A program is missing all its values\n");
					# print("prog_name is  $sunix_pl->{_prog_names}[$prog_count]\n\n ");
					# $sunix_pl->{_message1} = $true;
					# exit;

				} else {

					# Case 2B: value is  not empty
					# print("sunix_pl,get_good_sunix_params_values,a good value NADA\n")
				}

			} else {

				# print("sunix_pl,get_good_sunix_params_values,unexpected or 'clear' NADA\n")
			}

		}    # over each line in for a single  program

		# print("2. sunix_pl,get_good_sunix_params_values,prog: $prog_count---temp values:---@temp_values\n\n");
		# store value and label for each program only if a value has been found
		my $long = ( $value_index - 1 );
		if ( $long > -1 ) {    #
			@temp_values                        = @values_holder[ 0 .. $long ];
			@temp_labels                        = @labels_holder[ 0 .. $long ];
			$values_aref_holder[$op_prog_count] = \@temp_values;
			$labels_aref_holder[$op_prog_count] = \@temp_labels;
			$good_prog_index[$op_prog_count]    = $prog_count;    # remember which programs are useful for later
			$op_prog_count++;

			# print(" sunix_pl,get_good_sunix_params,prog: $prog_count---temp values:---@temp_values\n\n");
			# print(" sunix_pl,get_good_sunix_params,prog: $prog_count---values:---@{$values_aref_holder[$prog_count]}\n\n");
			# print(" sunix_pl,get_good_sunix_params,prog: $prog_count---temp labels:---@temp_labels\n\n");
			# print(" sunix_pl,gget_good_sunix_params,prog: $prog_count---labels:---@{$labels_aref_holder[$prog_count]}\n\n");
		} else {

			# label and values are not assigned to array elements
			# BUT array continues to increment
			print("warning: sunix_pl,get_good_sunix_params, no value found: long = $long\n");
		}

	}    # over each program

	# for all programs
	# my $num_progs = $size;
	# print("sunix_pl,i/p num_progs: $num_progs\n");

	$sunix_pl->{_labels_aref2} = \@labels_aref_holder;
	$sunix_pl->{_values_aref2} = \@values_aref_holder;

	my $new_num_progs = scalar @values_aref_holder;

	#print("sunix_pl,o/p num_progs: $new_num_progs\n");

	#	for(my $i=0; $i < $new_num_progs; $i++) {
	#		my $num_params = scalar @{$values_aref_holder[$i]};
	#				 print("sunix_pl, prog: $i---num_params: $num_params---\n");
	#				 print("sunix_pl, original good program index: $good_prog_index[$i]\n");
	#
	#		 for (my $j=0; $j <$num_params; $j++ ){
	#					 print("sunix_pl,get_good_sunix_params,labels: @{@{$sunix_pl->{_labels_aref2}}[$i]}[$j]\n");
	#					 print("sunix_pl,get_good_sunix_params,values: @{@{$sunix_pl->{_values_aref2}}[$i]}[$j]\n");
	#		}
	#	}
	$sunix_pl->{_good_prog_indices_ref} = \@good_prog_index;

	# print("sunix_pl,get_good_sunix_names,good_prog_indices, @{$sunix_pl->{_good_prog_indices_ref}} \n");
	return ($sunix_pl);
}

=head2 sub get_good_sunix_namessions

=cut

sub get_good_prog_versions {
	my ($self) = @_;
	my @version;
	my $num_good_progs = scalar @{ $sunix_pl->{_good_prog_names} };

	# print("sunix.pl, get_good_prog_versions:num_progs $num_good_progs\n");
	# always first program is version 1

	$version[0] = 1;

	# 2nd program
	for ( my $this = 0; $this < $num_good_progs; $this++ ) {
		$version[$this] = 1;
		for ( my $up_to = 0; $up_to < $this; $up_to++ ) {
			if ( @{ $sunix_pl->{_good_prog_names} }[$this] eq @{ $sunix_pl->{_good_prog_names} }[$up_to] ) {
				$version[$this]++;
			}
		}
	}
	$sunix_pl->{_good_prog_versions} = \@version;

	# print("versions, @{$sunix_pl->{_good_prog_versions}}\n");
	# print("versions, names:@{$sunix_pl->{_good_prog_names}}\n");
	return ( \@version );
}

=pod sub get_whole 

 get the complete file
 line by line

=cut

sub get_whole {
	my ($self) = @_;

	if ( $sunix_pl->{_all_lines_aref} ) {

		my $all_lines_aref = $sunix_pl->{_all_lines_aref};

		# print(" sunix_pl, get_whole, @{$sunix_pl->{_all_lines_aref}}\n");

		#    			for (my $i=0; $i < $sunix_pl->{_num_lines}; $i++ ) {
		#    				print("sunix_pl, whole, all_lines_aref: @{$sunix_pl->{_all_lines_aref}}[$i] \n");
		#    			}

		return ($all_lines_aref);

	} else {
		print(" sunix_pl, get_whole, missing: sunix_pl->{_all_lines_aref}\n");
	}

}

=pod sub header 

 import standard perl
 headers 
 and write to output file

=cut

sub header {

	my $ref_array = $get_header->section();

	foreach (@$ref_array) {
		print $file_out "$_\n";
	}

}

=head2 sub instantiation

=cut

sub instantiation {

	my $ref_array = $get_instantiation->section();

	foreach (@$ref_array) {
		print $file_out "$_\n";
	}

}

sub length {
	my ($self) = shift;
	return ($sunix_pl);
}

=head2 sub lines_with

 return line numbers that contain a particular
 word or string 

=cut

sub lines_with {
	my ( $self, $word ) = @_;
	my $string = $word;
	my ( $line, $count_all_lines, $case_num );
	my ( @line_nums, @line_contents );

	$count_all_lines = 0;
	$case_num        = 0;

	# print("got to sunix_pl, lines_with, $word\n");
	# print("got to sunix_pl,all_lines: $sunix_pl->{_all_lines_aref}\n");

	if ( $sunix_pl->{_all_lines_aref} ) {
		my @all_lines = @{ $sunix_pl->{_all_lines_aref} };

		# print("got to sunix_pl,all_lines: @all_lines\n");
		foreach my $line (@all_lines) {

			if ( $line =~ /$string/ ) {

				# print ("sunix_pl,line= $line \n");
				$line_nums[$case_num]     = $count_all_lines;
				$line_contents[$case_num] = $line;
				$case_num++;
			}
			$count_all_lines++;
		}

		$sunix_pl->{_line_nums}     = \@line_nums;
		$sunix_pl->{_line_contents} = \@line_contents;

		return ($sunix_pl);

	} else {
		print("sunix_pl,lines_with, missing: all_lines_aref\n");
	}

}

=head2 sub logs

=cut

sub logs {

	print $file_out ' print  "$flow[1]";' . "\n\n";
	print $file_out ' $log->file($flow[1]);' . "\n\n";

}

sub need {
	print("sub need \n");
	return ();

}

#=head2 sub get_pod_declare
#
#=cut
#
#sub get_pod_declare {
#
#	my $ref_array = $pod_declare->section();
#	foreach (@$ref_array) {
#		print $file_out "$_\n";
#	}
#}

=head2 sub run

=cut

sub run {

	print $file_out ' $run->flow(\$flow[1]);' . "\n\n";

}

=head2 sub set_file_in


=cut

sub set_file_in {
	my ( $self, $file_aref ) = @_;

	if ($file_aref) {

		# print("sunix_pl,set_file_in, @$file_aref[0]\n");

		$sunix_pl->{_file_in} = @$file_aref[0];

	} else {
		print("sunix_pl,set_file_in, missing file-aref\n");
	}
}

=head2 sub set_file_in_sref

  print("set_file_in is $sunix_pl->{_file_in}\n");

=cut

sub set_file_in_sref {
	my ( $self, $file_sref ) = @_;

	if ($file_sref) {

#		print("sunix_pl,set_file_in, $$file_sref\n");

		$sunix_pl->{_file_in} = $$file_sref;

	} else {
		print("sunix_pl,set_file_in_sref, missing file_sref\n");
	}
}

=head2 sub set_file_out

  print("set_file_out is $sunix_pl->{_file_out}\n");

=cut

sub set_file_out {
	my ( $self, $file_aref ) = @_;
	$sunix_pl->{_file_out} = @$file_aref[0];
}

=head2 sub set_good_labels

 	enter only those active
 	parameter values from a program in a perl flow
 	
 	

=cut

=head2 sub set_good_values

 	enter only those active
 	parameter values from a program in a perl flow

=cut

=head2 sub set_num_progs

=cut

sub set_num_progs {
	my ($self) = @_;

	if ( $sunix_pl->{_start_line_contents} ) {

		$sunix_pl->{_num_progs} = scalar @{ $sunix_pl->{_start_line_contents} };

		# print("sunix_pl, set_num_progs: $sunix_pl->{_num_progs}\n");

	} else {
		print("sunix_pl, set_num_progs: missing $sunix_pl->{_start_line_contents}\n");
	}
	return ();
}

=head2 sub set_path_in_ref

	
=cut

sub set_path_in_sref {

	my ( $self, $path_in_sref ) = @_;

	if ($path_in_sref) {

		$sunix_pl->{_path} = $$path_in_sref;

		# print("sunix_pl,set_path_in_sref, $sunix_pl->{_path}\n");

	} else {
		print("sunix_pl,set_path_in_sref,missing path_in\n");
	}

	return ();
}

=head2 sub set_perl_file_in

	
=cut

sub set_perl_file_in {

	my ( $self, $file_in ) = @_;

	if ($file_in) {

		$sunix_pl->{_perl_file_in} = $file_in;
		$sunix_pl->{_file_in}      = $file_in;

		# print("sunix_pl,set_perl_file_in, $file_in\n");

	} else {
		print("sunix_pl,set_perl_file_in,missing file_in\n");
	}

	return ();
}

=head2 sub set_perl_path

 working file name
	
=cut

sub set_perl_path {

	my ( $self, $path ) = @_;

	if ($path) {

		# print("sunix_pl,set_perl_path, $path\n");
		$sunix_pl->{_path} = $path;

	} else {
		print("perl_flow,missing path\n");
	}
	return ();
}

=head2 sub set_perl_path_in

 working file name
	
=cut

sub set_perl_path_in {

	my ( $self, $path ) = @_;

	if ($path) {

		#		print("sunix_pl,set_perl_path_in, $path\n");
		$sunix_pl->{_path} = $path;

	} else {
		print("perl_flow,missing path\n");
	}
	return ();
}

=head2 sub set_progs_contain

 return line numbers that contain a particular
 word or string 

=cut

sub set_progs_contain {

	my ( $self, $string ) = @_;

	if ($string) {

		$sunix_pl->{_string} = $string;

		# print("sunix_pl,set_progs_contain, string:[$string]\n");

	} else {
		print("sunix_pl,set_progs_contain, missing string\n");
	}

	return ();
}

=head2 sub set_progs_end_with

 return line numbers that contain a particular
 word or string 
   print("progs_end_with,@{$sunix_pl->{_end_prog_lines}}\n");i
   print("progs_end_with,@{$sunix_pl->{_end_line_contents}}\n");

=cut

sub set_progs_end_with {
	my ( $self, $word ) = @_;

	if ( $word && $sunix_pl->{_all_lines_aref} ) {

		my $string = $word;
		my ( $line, $count_all_lines, $case_num );
		my ( @line_nums, @line_contents );

		my @all_lines = @{ $sunix_pl->{_all_lines_aref} };

		$count_all_lines = 0;
		$case_num        = 0;

		foreach my $line (@all_lines) {

			if ( $line =~ /$string/ ) {
				$line_nums[$case_num]     = $count_all_lines;
				$line_contents[$case_num] = $line;
				$case_num++;

				# print("sunix_pl,set_progs_end_with, found $string at line $line \n");
			}

			$count_all_lines++;
		}

		$sunix_pl->{_end_prog_lines}    = \@line_nums;
		$sunix_pl->{_end_line_contents} = \@line_contents;

		# print("sunix_pl,set_progs_end_with, end lines: @{$sunix_pl->{_end_prog_lines}}\n");

	} else {
		print("sunix_pl,set_progs_end_with, missing word\n");
	}

	return ();
}

=head2 sub set_progs_start_with

 return line numbers that contain a particular
 word or string 
  print("$case_num cases in $count_all_lines lines,\n");  
  print("at line(s): @{$sunix_pl->{_line_nums}}\n");  
  print("set_progs_start_with, length is $size\n"); 
  print ("word is $word\n");
  print ("word is $string\n");

=cut

sub set_progs_start_with {
	my ( $self, $word ) = @_;

	if ( $word && $sunix_pl->{_all_lines_aref} ) {

		my $string = $word;
		my ( $line, $count_all_lines, $case_num );
		my ( @line_nums, @line_contents );

		my @all_lines = @{ $sunix_pl->{_all_lines_aref} };

		$count_all_lines = 0;
		$case_num        = 0;

		foreach my $line (@all_lines) {
			if ( $line =~ /$string/ ) {
				$line_nums[$case_num]     = $count_all_lines;
				$line_contents[$case_num] = $line;
				$case_num++;

				# print("sunix_pl,set_progs_start_with, found $string at line $line \n");
			}
			$count_all_lines++;
		}

		$sunix_pl->{_start_prog_lines}    = \@line_nums;
		$sunix_pl->{_start_line_contents} = \@line_contents;

		# print("sunix_pl,set_progs_start_with, start lines: @{$sunix_pl->{_start_prog_lines}}\n");

	} else {
		print("sunix_pl,set_progs_start_with, missing word\n");
	}

	return ();
}

=head2 sub use_pkg

=cut

sub use_pkg {

	my $ref_array = $get_use_pkg->section();
	foreach (@$ref_array) {
		print $file_out "$_\n";
	}
}

=pod sub whole 

 open and read
 the complete file
 line by line
    #print ("lines are @{$sunix_pl->{_all_lines_aref}}\n"); 
    print ("We seem to have $sunix_pl->{_num_lines} lines total\n");

=cut

sub whole {
	my ($self) = @_;
	my @all_lines;

	if ( $sunix_pl->{_path} && $sunix_pl->{_file_in} ) {

		# full directory path plus file name
		my $inbound = $sunix_pl->{_path} . '/' . $sunix_pl->{_file_in};
#		print("sunix_pl, whole, $inbound\n");

		my $i = 0;
		open( my $fh, '<', $inbound )
			or die "Could not open file '$sunix_pl->{_file_in}' $!";
		while ( my $row = <$fh> ) {
			chomp $row;
			$all_lines[$i] = $row;

#			print "I read: " . $all_lines[$i] . "from the file, i=" . $i . "\n";
			$i++;
		}

		$sunix_pl->{_all_lines_aref} = \@all_lines;
		close($fh);
		$sunix_pl->{_num_lines} = scalar @{ $sunix_pl->{_all_lines_aref} };

		# $sunix_pl->{_num_lines} = 16;

		# print("sunix_pl, whole, num_lines: $sunix_pl->{_num_lines}\n");
		#for (my $i=14; $i < $sunix_pl->{_num_lines}; $i++ ) {
		# 	print("sunix_pl, whole, all_lines_aref: @{$sunix_pl->{_all_lines_aref}}[$i] \n");
		#}
		# print("sunix_pl, whole, all_lines_aref: @{$sunix_pl->{_all_lines_aref}} \n");
	} else {
#		print("sunix_pl, whole, missing path or file name \n");
	}

	return ();
}

#
#=head2 sub write_inbound
#
# import standard perl
# inbound files and their paths
#
#=cut
#
# sub write_inbound {
#
# 	my ($file_in) = @_;
#
# 	print (" 3. file in is $self->{ref_file_in}\n");
# 	my $ref_array = $get_inbound->section($self->{ref_file_in});
#
#  	foreach (@$ref_array) {
#    	print $file_out "$_\n";
#  	}
#}

1;

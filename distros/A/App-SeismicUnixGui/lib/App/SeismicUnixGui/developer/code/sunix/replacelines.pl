use Moose;
our $VERSION = '0.0.1';

my $MAIN_DIR = '/usr/local/pl/L_SU/specs';
my ( @INBOUND, @SUBDIR );
my @directories;
my @line;
my $number_of_lines;

# print("MAIN_DIR= $MAIN_DIR\n");

# Contents of main  directory
opendir( DIR, $MAIN_DIR ) or die $!;
my @directory_list = readdir(DIR);
close(DIR);

# print @directory_list;

foreach my $thing (@directory_list) {

	if (   $thing eq '.'
		or $thing eq '..'
		or $thing =~ /.pm/ ) {

		next;

	} else {
		push @directories, $MAIN_DIR . '/' . $thing;

		# print("DIR= $thing\n");
	}
}

# Listing within each subdirectory
foreach my $subdir (@directories) {
	my @inbound;
	print("\nWorking inside sub-directory: $subdir\n");

	opendir( DIR, $subdir ) or die $!;
	my @file_list = readdir(DIR);
	close(DIR);

	foreach my $file (@file_list) {

		if ( $file eq '.' or $file eq '..' ) {
			next;

		} else {
			push @inbound, $subdir . '/' . $file;

			print("file= $file\n");
		}
	}

	# Working with individual files in each subdirectory
	foreach my $inbound_prog_spec (@inbound) {
		my $i;
		open( FH, $inbound_prog_spec ) or die("File $inbound_prog_spec not found");
		print("opening up $inbound_prog_spec \n");

		$line[0] = <FH>;

		# print("line0= $line[0]\n");
		$i = 1;

		while ( my $String = <FH> ) {
			$line[$i] = $String;

			#my $other_words2find = '_has_infile';
			my $other_words2find = '_has_pipe_in';

			# my $words2find = '_has_pipe_in';
			# my $words2find = '_has_pipe_out';
			my $words2find = '_has_outpar';

			if ( $line[$i] =~ /$words2find/
				and ( $line[ ( $i - 1 ) ] =~ /$other_words2find/ ) ) {

				print "found $line[($i-1)]  and $line[$i]\n";

				# exchange lines
				my $temp = $line[ ( $i - 1 ) ];
				$line[ ( $i - 1 ) ] = $line[$i];
				$line[$i] = $temp;
				print "reversed: $line[($i-1)]  and $line[$i]\n";

			}    # check words

			$i++;    # track lines
		}    # inside a file
		close(FH);

		# write out the corrected file
		$number_of_lines = $i;
		print("number of lines= $i\n");
		open( OUT, ">$inbound_prog_spec" ) or die("File $inbound_prog_spec not found");
		print("writing our $inbound_prog_spec\n");
		for ( my $i = 0; $i < $number_of_lines; $i++ ) {
			print OUT $line[$i];
		}
		close(OUT);
	}    # for each file

}    # within each subdirectory


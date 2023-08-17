package App::SeismicUnixGui::misc::manage_files_by;

use Moose;
our $VERSION = '0.0.1';

# manage_files_by  class
# Contains methods/subroutines/functions to operate on directories
# V 1. March 3 2008
# Juan M. Lorenzo

sub copy_file {

	# this function/method  makes a  directory
	# if it does not exist already

	#get directory names
	my ($origin)      = shift @_;
	my ($destination) = shift @_;

	print("\nCopying $origin to $destination \n");

	system(
		"                       	\\
                cp $origin $destination       	\\
        "
	);

}

=head2 sub count_lines

 this function counts the numbers of lines in a text file
 
=cut

sub count_lines {
	my ($self, $ref_origin) = @_;

# print ("\nmanage_files_by,count_lines The input file is called $$ref_origin\n");

	# open the file of interest
	open( my $IN, '<', $$ref_origin ) or die "Can't open $$ref_origin, $!\n";
	my $cnt;
	$cnt++ while <$IN>;
	close($IN);

	my $num_lines = $cnt;

	# print ("line number = $num_lines\n");

	return ($num_lines);
}

sub delete_file {

	# this function/method deletes files

	#get directory names
	my ($ref_directory_path) = shift @_;
	my ($ref_filename)       = shift @_;

	print("\nDeleting $$ref_directory_path/$$ref_filename \n");

	system(
		"                       			\\
                rm  $$ref_directory_path/$$ref_filename      	\\
        "
	);

}

sub is_file_empty {
	my ($ref_file) = shift @_;

	# default situation is to have a file that is empty
	my $answer = 1;

	# find status of file to see whether it is empty
	#$fsize[1] = (stat($$ref_file))[2];
	#print("\nfile is: $$ref_file\n");

	# -s is for size
	#verified by JL
	my $j = ( -s $$ref_file );

	#	print ("file: $$ref_file is $j in size\n\n");
	if ( -s $$ref_file > 0 ) {

		#		print  ("file is not empty\n\n") ;
		$answer = 0;
	}

	#	print("is file empty 1-yes 0-no---- $answer\n\n");
	#	print("file name for size is $$ref_file \n\n");
	#	answer=1 if empty and =0 if not empty

	return ($answer);
}

sub does_file_exist {
	my ($ref_file) = shift @_;

	# default situation is to have a file non-existent
	my $answer = 0;

	# -e returns 1 or ''
	#verified by JL
	#	print("file for exist test is $$ref_file\n\n");
	if ( -e $$ref_file ) {

		#	   print  ("file existence verified\n\n") ;
		$answer = 1;
	}

	#	answer=1 if existent and =0 if non-existent
	#verified by JL
	return ($answer);
}

sub is_one {

	# find out if a special file's content ==1
	# thereby verifying the existence of a second file
	my ($ref_file) = shift @_;

	# default situation is to have a file that is empty
	my $answer = 0;
	my $line;

	#print ("\nFor is_one the input file is called $$ref_file\n");

	# open the file of interest
	open( FILE, $$ref_file ) || print("Can't open file_name, $!\n");

	# read contents of file
	while ( $line = <FILE> ) {
		chomp($line);
		my ($x) = $line;

		if ( $x == 1 ) {
			$answer = 1;

			#print (" yes, first line is one\n\n");
		}
	}
	close(FILE);

	#	answer=1 if line=1  and =0 if line=0
	return ($answer);
}

sub is_zero {

	# find out if a special file's content ==0
	# thereby showing a second file does not exist
	my ($ref_file) = shift @_;

	# default situation is not to have a file with a zero on the first line
	my $answer = 0;
	my $line;

	#print ("\nFor is_zero the input file is called $$ref_file\n");

	# open the file of interest
	open( FILE, $$ref_file ) || print("Can't open file_name, $!\n");

	# read contents of file
	while ( $line = <FILE> ) {
		chomp($line);
		my ($x) = $line;

		if ( $x == 0 ) {
			$answer = 1;

			#print (" yes, first line is zero\n\n");
		}
	}
	close(FILE);

	#	answer=1 if line=1  =0
	#       answer=0 if line1 Not equal to 0
	return ($answer);
}

=head2 sub read_mute_par

 read parameter file

=cut 

sub read_mute_par {

	my ($ref_file_name) = shift @_;

	#print ("\nThe input file is called $$ref_file_name\n");

=pod Steps

     1. open file

     2. set the counter

     3. read contents of parameter file

     4. odd-numbered lines contain tnmo and even contain vnmo

=cut

	open( FILE, $$ref_file_name ) || print("Can't open $$ref_file_name, $!\n");

	my $row = 0;
	my ( @Items, @things );
	my ( $i,     $line );
	my ( @row,   @numberOfValues );

	while ( $line = <FILE> ) {

		#	print("\n$line");

=pod

 1. remove end of line
 2. calculate number of useful elements
 2. only leave the numbers

=cut

		chomp($line);
		@things = split /=/, $line;

		# print("things= @things\n");
		$numberOfValues[$row] = scalar(@things) + 1;
		$Items[$row]          = pop @things;
		$row                  = $row + 1;
	}
	close(FILE);

	print("\n number of rows is $row\n\n");

	for ( $i = 0 ; $i < $row ; $i++ ) {
		print("\n row $i contains $Items[$i]");
		print(" i.e., $numberOfValues[$i] values\n");
	}

	return ( \@Items, \@numberOfValues );

}

=head2 sub read_par

 read parameter file

=cut 

sub read_par {

	my ($self, $ref_file_name) = @_;

# print ("\nmanage_files_by,read_par,The input file is called $$ref_file_name\n");

=pod Steps

     1. open file

     2. set the counter

     3. read contents of parameter file

     4. odd-numbered lines contain time and even contain vnmo/xmute etc.
     

=cut

	open( FILE, $$ref_file_name ) || print("Can't open file_name, $!\n");

	my $row = 0;
	my ( @Items, @things );
	my ( $i,     $line );
	my ( @row,   @ValuesPerRow );

	while ( $line = <FILE> ) {

#		print("manage_files_by,read_par, $line");

=pod

 1. remove end of line
 2. calculate number of useful elements
 2. only leave the numbers

=cut

		chomp($line);
		@things             = split /=/, $line;
		$ValuesPerRow[$row] = scalar(@things) + 1;
		$Items[$row]        = pop @things;
		$row                = $row + 1;
	}
	close(FILE);

	return ( \@Items, \@ValuesPerRow );

}

sub read_2cols_sugethw {

	# this function reads cols 1 and 2 in a text file

	my ($ref_origin) = shift @_;

	# print ("\nThe input file is called $$ref_origin\n");

	# open the file of interest
	open( FILE, $$ref_origin ) || print("Can't open file_name, $!\n");

	#set the counter
	my $i = 1;
	my $line;
	my ( $t, $x );
	my @TIME;
	my @OFFSET;

	# read contents of shotpoint geometry file
	while ( $line = <FILE> ) {

		#	print("\n$line");
		chomp($line);
		( $t, $x ) = split( " ", $line );
		$TIME[$i]   = $t;
		$OFFSET[$i] = $x;

		#        print("\n @TIME[$i] @OFFSET[$i]\n");
		#        print("\n @TIME[$i]\n");
		$i = $i + 1;

	}

	close(FILE);

	my $num_rows = $i - 1;

	# print out the number of lines of data for the user
	# print("\nThis file contains $num_rows row(s) of data\n");

	#   to prevent contaminating outside variables
	my @TIME_OUT   = @TIME;
	my @OFFSET_OUT = @OFFSET;

	return ( \@TIME_OUT, \@OFFSET_OUT, $num_rows );
}

sub read_3colsp {

	# this function reads 3 cols in a text file

	my ($file_name) = @_;

	# print ("\nThe input file is called $file_name\n");

	# open the file of interest
	open( FILE, $file_name ) || print("Can't open file name, $!\n");

	#set the counter
	my $i = 0;
	my ( @X, @Y, @Z );

	# read contents of file
	while ( my $lines = <FILE> ) {

		#     print("$lines");
		chomp($lines);
		my ( $x, $y, $z ) = split( " ", $lines );

		#        print("\n$x \n");
		$X[$i] = $x;
		$Y[$i] = $y;
		$Z[$i] = $z;

		#print("\n @X[$i] @Y[$i] @Z[$i] \n");
		$i = $i + 1;
	}

	# number of geophones stations in file
	my $num_rows = $i;

	#print ("This file contains $num_rows rows\n\n\n");
	# close the file of interest
	close(FILE);

	# make sure arrays do not contaminate outside
	my @XX = @X;
	my @YY = @Y;
	my @ZZ = @Z;
	return ( \@XX, \@YY, \@ZZ, $num_rows );

}

sub read_3cols {

	# this function reads 3 cols in a text file

	my ($ref_file_name) = shift @_;

	#   print ("\nThe input file is called $$ref_file_name\n");

	# open the file of interest
	open( FILE, $$ref_file_name ) || print("Can't open file name, $!\n");

	#set the counter
	my $i = 1;
	my ( @X, @Y, @Z );

	# read contents of file
	while ( my $lines = <FILE> ) {

		#     print("$lines");
		chomp($lines);
		my ( $x, $y, $z ) = split( " ", $lines );

		#        print("\n$x \n");
		$X[$i] = $x;
		$Y[$i] = $y;
		$Z[$i] = $z;

		#print("\n @X[$i] @Y[$i] @Z[$i] \n");
		$i = $i + 1;
	}

	# number of geophones stations in file
	my $num_rows = $i - 1;

	#print ("This file contains $num_rows rows\n\n\n");
	# close the file of interest
	close(FILE);

	# make sure arrays do not contaminate outside
	my @XX = @X;
	my @YY = @Y;
	my @ZZ = @Z;
	return ( \@XX, \@YY, \@ZZ, $num_rows );

}

sub read_4cols {

	# this function reads 4 cols in a text file

	my ($ref_file_name) = shift @_;

	# print ("\nThe input file is called $$ref_file_name\n");

	# open the file of interest
	open( FILE, $$ref_file_name ) || print("Can't open file_name, $!\n");

	#set the counter
	# start counting at 1, NOT 0
	my $i = 1;
	my ( @ID, @X, @Y, @Z );
	my $lines;

	# read contents of file
	while ( $lines = <FILE> ) {

		#print("$lines");
		chomp($lines);
		my ( $ident, $x, $y, $z ) = split( " ", $lines );

		#print("\n $ident \n");
		$ID[$i] = $ident;
		$X[$i]  = $x;
		$Y[$i]  = $y;
		$Z[$i]  = $z;

		#print("\nInside sub:read_4cols @ID[$i] @X[$i] @Y[$i] @Z[$i] \n");
		$i = $i + 1;

	}

	# number of geophones stations in file
	my $num_rows = $i - 1;

	#print ("This file contains $num_rows row(s)\n\n\n");
	# close the file of interest
	close(FILE);

	# make sure arrays do not contaminate outside
	my @XX  = @X;
	my @YY  = @Y;
	my @ZZ  = @Z;
	my @IDD = @ID;

	return ( \@IDD, \@XX, \@YY, \@ZZ, $num_rows );

}

sub read_4cols_p {

	# this function reads 4 cols in a text file
	my $ref_file_name;
	my @ref_file_name;

	$ref_file_name = shift @_;

	# print ("\nThe input file is called @$ref_file_name\n");

	# open the file of interest
	open( FILE, @$ref_file_name[1] ) || print("Can't open file_name, $!\n");

	# set the counter
	# start counting at 0, NOT 1
	my $i = 0;
	my $lines;
	my ( @ID, @X, @Y, @Z );

	# read contents of file
	while ( $lines = <FILE> ) {

		#print("$lines");
		chomp($lines);
		my ( $ident, $x, $y, $z ) = split( " ", $lines );

		#print("\n $ident \n");
		$ID[$i] = $ident;
		$X[$i]  = $x;
		$Y[$i]  = $y;
		$Z[$i]  = $z;

		#print("\nInside sub:read_4cols @ID[$i] @X[$i] @Y[$i] @Z[$i] \n");
		$i = $i + 1;

	}

	# number of geophones stations in file
	my $num_rows = $i;

	#print ("This file contains $num_rows row(s)\n\n\n");
	# close the file of interest
	close(FILE);

	# make sure arrays do not contaminate outside
	my @XX  = @X;
	my @YY  = @Y;
	my @ZZ  = @Z;
	my @IDD = @ID;

	return ( \@IDD, \@XX, \@YY, \@ZZ, $num_rows );

}

sub read_5cols {

	# this function reads 5 cols in a text file

	my ($ref_file_name) = shift @_;

	print("\nThe input file with 5 cols is called @$ref_file_name\n");

	# open the file of interest
	open( FILE, @$ref_file_name[1] ) || print("Can't open $!\n");

	#set the counter
	# start counting at 0, NOT 1
	my $i = 0;
	my ( @ID, @X, @Y, @Z, @W );
	my $lines;

	# read contents of file
	while ( $lines = <FILE> ) {

		#print("$lines");
		chomp($lines);
		my ( $ident, $x, $y, $z, $w ) = split( " ", $lines );

		#print("\n $ident \n");
		$ID[$i] = $ident;
		$X[$i]  = $x;
		$Y[$i]  = $y;
		$Z[$i]  = $z;
		$W[$i]  = $w;

		#print("\nInside sub:read_5cols @ID[$i] @X[$i] @Y[$i] @Z[$i] @W[$i]\n");
		$i = $i + 1;
	}

	# number of geophones stations in file
	my $num_rows = $i - 1;

	#print ("This file contains $num_rows row(s)\n\n\n");
	# close the file of interest
	close(FILE);

	# make sure arrays do not contaminate outside
	my @WW  = @W;
	my @XX  = @X;
	my @YY  = @Y;
	my @ZZ  = @Z;
	my @IDD = @ID;

	return ( \@IDD, \@XX, \@YY, \@ZZ, \@WW, $num_rows );

}

sub read_5cols_p {

	# this function reads 5 cols in a text file

	my ($ref_file_name) = shift @_;
	print("\nThe input file with 5 cols is called $$ref_file_name[1]\n");

	# open the file of interest
	open( FILE, $$ref_file_name[1] ) || print("Can't open $!\n");

	#set the counter
	# start counting at 0
	my $i = 0;
	my ( @ID, @X, @Y, @Z, @W );
	my $lines;

	# read contents of file
	while ( $lines = <FILE> ) {

		#print("$lines");
		chomp($lines);
		my ( $ident, $x, $y, $z, $w ) = split( " ", $lines );

		#print("\n $ident \n");
		$ID[$i] = $ident;
		$X[$i]  = $x;
		$Y[$i]  = $y;
		$Z[$i]  = $z;
		$W[$i]  = $w;

		#print("\nInside sub:read_5cols @ID[$i] @X[$i] @Y[$i] @Z[$i] @W[$i]\n");
		$i = $i + 1;
	}

	# number of geophones stations in file
	my $num_rows = $i;

	#print ("This file contains $num_rows row(s)\n\n\n");
	# close the file of interest
	close(FILE);

	# make sure arrays do not contaminate outside
	my @WW  = @W;
	my @XX  = @X;
	my @YY  = @Y;
	my @ZZ  = @Z;
	my @IDD = @ID;

	return ( \@IDD, \@XX, \@YY, \@ZZ, \@WW, $num_rows );

}

sub read_6cols {

	# this function reads 6 cols in a text file

	my ($ref_file_name) = shift @_;

	#  print ("\nThe input file with 6 cols is called $$ref_file_name\n");

	# open the file of interest
	open( FILE, $$ref_file_name ) || print("Can't open $$ref_file_name, $!\n");

	#set the counter
	my $i = 0;
	my ( @A, @B, @C, @D, @E, @F );
	my $lines;

	# read contents of file
	while ( $lines = <FILE> ) {

		#print("$lines");
		chomp($lines);
		my ( $a, $b, $c, $d, $e, $f ) = split( " ", $lines );

		#        print("\n $a \n");
		$A[$i] = $a;
		$B[$i] = $b;
		$C[$i] = $c;
		$D[$i] = $d;
		$E[$i] = $e;
		$F[$i] = $f;
		$i     = $i + 1;
	}

	# number of geophones stations in file
	my $num_rows = $i - 1;

	#print ("This file contains $num_rows row(s)\n\n\n");
	# close the file of interest
	close(FILE);

	# make sure arrays do not contaminate outside
	my @AA = @A;
	my @BB = @B;
	my @CC = @C;
	my @DD = @D;
	my @EE = @E;
	my @FF = @F;

	return ( \@AA, \@BB, \@CC, \@DD, \@EE, \@FF, $num_rows );

}

sub write_1col {

	# WRITE OUT FILE

	# open and write to output file
	my ( $ref_X, $ref_file_name, $num_rows, $fmt ) = @_;

	#print("\nThe write_1col file is called $$ref_file_name\n");

	open( OUT, ">$$ref_file_name" );

	for ( my $j = 0 ; $j < $num_rows ; $j++ ) {

		printf OUT "$fmt\n", $$ref_X[$j];

		#print("Number of rows is $j, Value is $$ref_X[$j]\n");
	}

	close(OUT);

}

sub mult_col2 {

	# this function multiplies column  2 by a user given value

	my ($origin) = shift @_;
	my ($scale)  = shift @_;

	# print ("\nThe input file is called $origin\n");

	# open the file of interest
	open( FILE, $origin ) || print("Can't open file_name, $!\n");

	#set the counter
	my $i = 1;
	my ( @TIME, @OFFSET );
	my $line;

	# read contents of file
	while ( $line = <FILE> ) {

		#print("\n$line");
		chomp($line);
		my ( $t, $x ) = split( "  ", $line );
		$TIME[$i]   = $t;
		$OFFSET[$i] = $x * $scale;

		#        print("\n @TIME[$i] @OFFSET[$i]\n");
		$i = $i + 1;

	}

	close(FILE);

	my $num_rows = $i - 1;

	# print out the number of lines of data for the user
	#   print ("This file contains $num_rows[1] rows of data\n\n\n");

	return ( \@TIME, \@OFFSET, $num_rows );

}

sub overwriting {

	# overwrite old Sunix file

	#get file names
	my ($ref_backup_file) = shift @_;
	my ($ref_old_file)    = shift @_;
	my ($ref_new_file)    = shift @_;

	print("\nReplacing $$ref_old_file with $$ref_new_file \n");
	print("\nKeeping old name $$ref_old_file \n");
	print("\nBackup is  $$ref_backup_file \n");

	system(" mv $$ref_old_file $$ref_backup_file");
	system(" mv $$ref_new_file $$ref_old_file ");

}

sub read_1col {

	# this function reads 1 col from  a text file

	my ($ref_origin) = shift @_;

	#print ("\nThe input file is called $$ref_origin\n");

	# open the file of interest
	open( FILE, $$ref_origin ) || print("Can't open file_name, $!\n");

	#set the counter
	my $i = 1;
	my $line;
	my @OFFSET;

	# read contents of shotpoint geometry file
	while ( $line = <FILE> ) {

		#print("\n$line");
		chomp($line);
		my ($x) = $line;
		$OFFSET[$i] = $x;

		#print("\n Reading 1 col file:@OFFSET[$i]\n");
		$i = $i + 1;

	}

	close(FILE);

	my $num_rows = $i - 1;

	# print out the number of lines of data for the user
	#print ("This file contains $num_rows rows of data\n\n\n");
	# make sure arrays do not contaminate outside
	my @OOFFSET = @OFFSET;

	return ( \@OOFFSET, $num_rows );

}

sub read_2cols {

	# this function reads cols 1 and 2 in a text file

	my ($self, $ref_origin) = @_;

	# for names that have '
	# $$ref_origin =~s/'//g;

	if ( length $ref_origin ) {

		print("\nThe input file is called $$ref_origin\n");

		# open the file of interest
		open( FILE, $$ref_origin ) || print("Can't open file_name, $!\n");

		# set the counter
		my $i = 1;
		my ( @TIME, @OFFSET );
		my $line;

		# read contents of shotpoint geometry file
		while ( $line = <FILE> ) {

			#print("\n$line");
			chomp($line);
			my ( $t, $x ) = split( "  ", $line );
			$TIME[$i]   = $t;
			$OFFSET[$i] = $x;

			#print("\n @TIME[$i] @OFFSET[$i]\n");
			$i = $i + 1;

		}

		close(FILE);

		my $num_rows = $i - 1;

		# print out the number of lines of data for the user
		#print ("\nThis file contains $num_rows row(s) of data\n");

		#   to prevent contaminating outside variables
		my @TIME_OUT   = @TIME;
		my @OFFSET_OUT = @OFFSET;

		return ( \@TIME_OUT, \@OFFSET_OUT, $num_rows );

	}else{
		print("manage_files_by, read_2cols, missing file name\n");
	}

}

#sub read_2cols_sugethw{
## this function reads cols 1 and 2 in a text file
#
#        my ($ref_origin) 		= shift @_;
#
#   print ("\nThe input file is called $$ref_origin\n");
#
## open the file of interest
#  open(FILE,$$ref_origin) || print("Can't open file_name, $!\n");
#
##set the counter
#  $i = 1;
#
## read contents of shotpoint geometry file
#   while ($line = <FILE>) {
##	print("\n$line");
#	chomp($line);
#       ($t,$x)    = split (" ",$line);
#	$TIME[$i] 	      = $t;
#       $OFFSET[$i]           = $x;
#        print("\n @TIME[$i] @OFFSET[$i]\n");
##        print("\n @TIME[$i]\n");
#        $i 		 = $i +1;
#
#    }
#
#   close(FILE);
#
#   $num_rows = $i-1;
#
## print out the number of lines of data for the user
#   print ("\nThis file contains $num_rows row(s) of data\n");
#
##   to prevent contaminating outside variables
#        my  @TIME_OUT     = @TIME;
#        my  @OFFSET_OUT   = @OFFSET;
#
#return (\@TIME_OUT,\@OFFSET_OUT,$num_rows);
#
#}

#sub read_2cols_2 {
#use String::Scanf; # imports sscanf()
#TODO
# this function reads cols 1 and 2 in a text file with format
# this functiondoes not work ebcause it needs scanf from an
# unloaded class and scanf is still not tested
#        my ($ref_filename,$ref_fmt)	= shift @_;
#   	print ("\nThe input file is called $$ref_filename\n");
#
## open the file of interest
#  open(FILE,$$ref_filename) || print("Can't open file_name, $!\n");
#
## read contents of shotpoint geometry file
#   for($j=1; <FILE>; $j++) {
#  	printf OUT "$ref_fmt\n", $$ref_X[$j], $$ref_Y[$j];
#  	sscanf FILE "$$ref_fmt\n",$X[$j],$Y[$j];
#        print("Number of rows is $j, Value is $X[$j]\n");
#	}
#	$num_rows = $j-1;
#   close(FILE);
##        print("\n @X[$i] @Y[$i]\n");
#
##   to prevent contaminating outside variables
#        my @X_OUT     = @X;
#        my @Y_OUT   = @Y;
#	my $num_rows_out = $num_rows;
#
#return (\@X_OUT,\@Y_OUT,$num_rows_out);
#
#}
sub trime {

	# remove the empty spaces at the end of a string
	#
	my ($string_in) = @_;
	$string_in =~ s/\s+$//;    #remove trailing spaces
	my $string_out = $string_in;
	return ($string_out);
}

sub write_zero {

	# WRITE 0 to OUT FILE

	# open and write 0 to output file
	my ($ref_file_name) = @_;

	#print("\nThe write_zero output file is called $$ref_file_name\n");
	my $zero = 0;
	open( OUT, ">$$ref_file_name" );
	print OUT ("$zero\n");
	close(OUT);
}

sub write_one {

	# WRITE 1 to OUT FILE
	# open and write 1 to output file
	my ($ref_file_name) = @_;

	#print("\nThe write_one output file is called $$ref_file_name\n");

	my $one = 1;
	open( OUT, ">$$ref_file_name" );
	print OUT ("$one\n");
	close(OUT);
}

sub write_2cols {

	# WRITE OUT FILE

	# open and write to output file
	my ( $ref_X, $ref_Y, $num_rows, $ref_file_name, $fmt ) = @_;

	#print("\nThe output file is called $$ref_file_name\n");
	#print("\nThe output file contains $num_rows rows\n");
	#print("\nThe output file uses the following format: $fmt\n");

	open( OUT, ">$$ref_file_name" );

	for ( my $j = 1 ; $j <= $num_rows ; $j++ ) {

		#print OUT  ("$$ref_X[$j] $$ref_Y[$j]\n");
		printf OUT "$fmt\n", $$ref_X[$j], $$ref_Y[$j];

		#print("$$ref_X[$j] $$ref_Y[$j]\n");
	}

	close(OUT);
}

sub write_2cols_p {

	# perl option where the first file has index=0

	# WRITE OUT FILE

	# open and write to output file
	my ( $ref_X, $ref_Y, $num_rows, $ref_file_name, $fmt ) = @_;

	print("\nThe output file is called $$ref_file_name\n");
	print("\nThe output file contains $num_rows rows\n");
	print("\nThe output file uses the following format: $fmt\n");

	open( OUT, ">$$ref_file_name" );

	for ( my $j = 0 ; $j < $num_rows ; $j++ ) {

		#print OUT  ("$$ref_X[$j] $$ref_Y[$j]\n");
		printf OUT "$fmt\n", $$ref_X[$j], $$ref_Y[$j];

		#print("$$ref_X[$j] $$ref_Y[$j]\n");
	}

	close(OUT);
}

sub write_2cols_2 {

	# WRITE OUT FILE
	# April 9 2009
	# V2
	# new array statements
	# open and write to output file
	my ( $ref_X, $ref_Y, $num_rows, $ref_file_name, $ref_fmt ) = @_;

	#print("\nThe output file is called $$ref_file_name\n");
	#print("\nThe output file contains $num_rows rows\n");
	#print("\nThe output file uses the following format: $$ref_fmt\n");

	open( OUT, ">$$ref_file_name" );

	for ( my $j = 1 ; $j <= $num_rows ; $j++ ) {

		#print OUT  ("$$ref_X[$j] $$ref_Y[$j]\n");
		printf OUT "$$ref_fmt\n", $$ref_X[$j], $$ref_Y[$j];

		#print("$$ref_X[$j] $$ref_Y[$j]\n");
	}

	close(OUT);
}

sub write_3cols {

	# WRITE OUT FILE

	# open and write to output file
	my ( $ref_X, $ref_Y, $ref_Z, $num_rows, $ref_file_name, $fmt ) = @_;

	print("\nThe output file is called $$ref_file_name\n");

	open( OUT, ">$$ref_file_name" );

	for ( my $j = 1 ; $j <= $num_rows ; $j++ ) {

		printf OUT "$fmt\n", $$ref_X[$j], $$ref_Y[$j], $$ref_Z[$j];

		#print ("$$ref_X[$j] $$ref_Y[$j] $$ref_Z[$j]\n");
	}

	close(OUT);
}

sub write_3colsp {

	# WRITE OUT FILE

	# open and write to output file
	my ( $ref_X, $ref_Y, $ref_Z, $num_rows, $ref_file_name, $fmt ) = @_;

	print("\nThe output file is called $$ref_file_name\n");

	open( OUT, ">$$ref_file_name" );

	for ( my $j = 0 ; $j < $num_rows ; $j++ ) {

		printf OUT "$fmt\n", $$ref_X[$j], $$ref_Y[$j], $$ref_Z[$j];

		#		print("$$ref_X[$j] $$ref_Y[$j] $$ref_Z[$j]\n");
	}

	close(OUT);
}

sub write_4cols {

	# WRITE OUT FILE

	# open and write to output filec
	my ( $ref_ID, $ref_X, $ref_Y, $ref_Z, $num_rows, $ref_file_name, $fmt ) =
	  @_;

	print("\nThe output file is called $$ref_file_name\n");

	open( OUT, ">$$ref_file_name" );

	for ( my $j = 1 ; $j <= $num_rows ; $j++ ) {

		printf OUT "$fmt\n", $$ref_ID[$j], $$ref_X[$j], $$ref_Y[$j],
		  $$ref_Z[$j];

		#print ("$$ref_ID[$j] $$ref_X[$j] $$ref_Y[$j] $$ref_Z[$j]\n");
	}

	close(OUT);
}

sub write_4cols_2 {

	# WRITE OUT FILE
	# using two-dimensional arrays
	# open and write to output file
	my ( $ref_A, $ref_X, $ref_Y, $ref_Z, $num_rows, $num_cols, $ref_file_name,
		$fmt )
	  = @_;

	print("\nThe output file is called $$ref_file_name\n");

	open( OUT, ">$$ref_file_name" );

	for ( my $j = 1 ; $j <= $num_rows ; $j++ ) {
		for ( my $i = 1 ; $i <= $num_cols ; $i++ ) {
			printf OUT "$fmt\n", $$ref_A[$j][$i], $$ref_X[$j][$i],
			  $$ref_Y[$j][$i], $$ref_Z[$j][$i];
		}
	}
	close(OUT);
}

sub write_5cols {

	# WRITE OUT FILE
	# open and write to output file
	my ( $ref_X, $ref_Y, $ref_Z, $ref_A, $ref_B, $num_rows, $ref_file_name,
		$fmt )
	  = @_;

	print("\nThe output file is called $$ref_file_name\n");

	open( OUT, ">$$ref_file_name" );

	for ( my $j = 1 ; $j <= $num_rows ; $j++ ) {

		printf OUT "$fmt\n", $$ref_X[$j], $$ref_Y[$j], $$ref_Z[$j],
		  $$ref_A[$j], $$ref_B[$j];
	}
	close(OUT);
}

sub write_5cols_2 {

	# WRITE OUT FILE
	# using two-dimensional arrays
	# open and write to output file
	my (
		$ref_A,    $ref_X,    $ref_Y,         $ref_Z, $ref_B,
		$num_rows, $num_cols, $ref_file_name, $fmt
	) = @_;

	print("\nThe output file is called $$ref_file_name\n");

	open( OUT, ">$$ref_file_name" );

	for ( my $j = 1 ; $j <= $num_rows ; $j++ ) {
		for ( my $i = 1 ; $i <= $num_cols ; $i++ ) {
			printf OUT "$fmt\n", $$ref_A[$j][$i], $$ref_X[$j][$i],
			  $$ref_Y[$j][$i], $$ref_Z[$j][$i], $$ref_B[$j][$i];
		}
	}
	close(OUT);
}

sub write_6cols {

	# WRITE OUT FILE

	# open and write to output file
	my (
		$ref_X,    $ref_Y,         $ref_Z,
		$ref_R,    $ref_uncert,    $ref_arrival,
		$num_rows, $ref_file_name, $fmt
	) = @_;

	print("\nThe output file is called $$ref_file_name\n");

	open( OUT, ">$$ref_file_name" );

	for ( my $j = 1 ; $j <= $num_rows ; $j++ ) {

		printf OUT "$fmt\n", $$ref_X[$j], $$ref_Y[$j], $$ref_Z[$j],
		  $$ref_R[$j], $$ref_uncert[$j], $$ref_arrival[$j];
	}

	close(OUT);
}

=head2 write_mute_par

	write out a par file in the correct
	format

=cut

sub write_mute_par {

	# WRITE OUT FILE

	# open and write to output file
	my ( $ref_trace, $ref_values, $ref_file_name, $gather_header ) = @_;
	my ( $i, $number_of_traces, $number_of_lines );

	#print("\nThe output file is called $$ref_file_name\n");
	$number_of_traces = scalar @$ref_trace - 1;
	$number_of_lines  = 2 * $number_of_traces;

	#print("number of cdps is $number_of_traces\n");
	#print("number of lines is $number_of_lines\n");

	open( OUT, ">$$ref_file_name" );

	print OUT ("$gather_header=");
	print OUT ("$$ref_trace[1]");

	for ( $i = 2 ; $i <= $number_of_traces ; $i++ ) {
		print OUT (",$$ref_trace[$i]");
	}
	print OUT ("\n");

	for ( my $i = 1 ; $i < $number_of_lines ; $i = $i + 2 ) {
		print OUT ("tmute=$$ref_values[$i]\n");
		print OUT ("xmute=$$ref_values[($i+1)]\n");
	}

	close(OUT);
}

=head2 write_cdp

Write out only the cdp nos.
	
	cdp=g,h
	
for the first part of a file that contains
more than one tnmo, vnmo pair. 

=cut

sub write_cdp {

	# WRITE OUT FILE

	# open and write to output file
	my ($self, $cdp_aref, $DIR_OUT ) = @_;

	my ( $i, $number_of_cdps, $number_of_lines );

	$number_of_cdps = scalar @$cdp_aref;

	# print("number of cdps is $number_of_cdps \n");
	# print("number of cdps is $number_of_cdps \n");
	my $temp = '.cdp';
	open( OUT, ">$DIR_OUT/$temp" );

	# print first line
	print OUT ("cdp=");
	print OUT ("@$cdp_aref[0]");

	for ( $i = 1 ; $i < $number_of_cdps ; $i++ ) {
		print OUT (",@$cdp_aref[$i]");
	}
	print OUT ("\n");

	close(OUT);
}

=head2 write_gather

	write out only the gather nos.
	
	gather=g,h
	
	for the first part of a file that contains
	more than one tnmo, vnmo pair 

=cut

sub write_gather {

	# WRITE OUT FILE

	# open and write to output file
	my ( $self, $gather_aref, $DIR_OUT , $gather_type) = @_;

	my ( $i, $number_of_gathers, $number_of_lines );

	$number_of_gathers = scalar @$gather_aref;

	# print("number of gathers is $number_of_gathers \n");
	# print("number of gathers is $number_of_gathers \n");
	my $temp = '.gather';
	open( OUT, ">$DIR_OUT/$temp" );

	# print first line
	print OUT ("$gather_type=");
	print OUT ("@$gather_aref[0]");

	for ( $i = 1 ; $i < $number_of_gathers ; $i++ ) {
		print OUT (",@$gather_aref[$i]");
	}
	print OUT ("\n");

	close(OUT);
}

=head2 write_tmute_xmute

	write out only 
	tmute= a,b,c
	xmute= A,B,C
	tmute= d,e,f
	xmute= D,E,F
	 
	for the second part of a file that contains
	more than one tmute-xmute pair 

=cut

sub write_tmute_xmute {

	# WRITE OUT FILE

	# open and write to output file
	my ( $self, $gather_aref, $tmute_aref, $xmute_aref, $DIR_OUT ) = @_;

	my ( $i, $number_of_gathers );
	$number_of_gathers = scalar @$gather_aref;

	my $temp = '.tx';
	open( OUT, ">$DIR_OUT/$temp" );

	# print out subsequent lines
	for ( my $i = 0 ; $i < $number_of_gathers ; $i++ ) {

		# for each CDP
		print OUT ("tmute=@$tmute_aref[$i]\n");
		print OUT ("xmute=@{$xmute_aref}[$i]\n");

	}

	close(OUT);
}

=head2 write_tnmo_vnmo

	write out only 
	tnmo= a,b,c
	vnmo= A,B,C
	rnmo= d,e,f
	vnmo= D,E,F
	 
	for the second part of a file that contains
	more than one tnmo-vnmo pair 

=cut

sub write_tnmo_vnmo {

	# WRITE OUT FILE

	# open and write to output file
	my ( $self, $cdp_aref, $tnmo_aref, $vnmo_aref, $DIR_OUT ) = @_;

	my ( $i, $number_of_cdps );
	$number_of_cdps = scalar @$cdp_aref;

	my $temp = '.tv';
	open( OUT, ">$DIR_OUT/$temp" );

	# print out subsequent lines
	for ( my $i = 0 ; $i < $number_of_cdps ; $i++ ) {

		# for each CDP
		print OUT ("tnmo=@{$tnmo_aref}[$i]\n");
		print OUT ("vnmo=@{$vnmo_aref}[$i]\n");

	}

	close(OUT);
}

1;

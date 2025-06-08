package App::SeismicUnixGui::misc::manage_files_by2;

=head1 DOCUMENTATION

=head2 SYNOPSIS 
 Contains methods/subroutines/functions to operate on directories

 PROGRAM NAME: manage_files_by2 
 AUTHOR: Juan Lorenzo
 DATE:   V 1. March 3 2008
 V 2 May 27 2014
         
 DESCRIPTION: 
 modified from
 manage_files_by  to stricts requirements using Moose
 manage_files_by  class

 =head2 USE

=head3 NOTES 

=head4 
 Examples

=head3 NOTES  

=head4 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::sunix::shell::cat_su';
use aliased 'App::SeismicUnixGui::sunix::shell::cat_txt';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::control';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::sunix::data::data_out';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::misc::readfiles';

use Carp;


=head2 Instantiate

modules

=cut
		my $control = control->new();
		my $readfiles = readfiles->new();

=head2 clear memory


=cut
		
		$control->clear();
		$readfiles->clear();	

=head2 define private hash
to share

=cut

my @array1;
my @array2;

my $manage_files_by2 = {
	_all_lines_aref         => '',
	_appendix               => '',
	_cat_base_file_name_out => '',
	_delete_base_file_name  => '',
	_directory              => '',
	_file_in                => '',
	_inbound_list           => '',
	_pathNfile              => '',
	_program_name           => '',
	_suffix_type            => '',
};

=head2 sub clear

Clear all memory

=cut

sub clear {
	my $self = @_;
	$manage_files_by2->{_all_lines_aref}         = '';
	$manage_files_by2->{_appendix}               = '';
	$manage_files_by2->{_cat_base_file_name_out} = '';
	$manage_files_by2->{_delete_base_file_name}  = '';
	$manage_files_by2->{_inbound_list}  		 = '';	
	$manage_files_by2->{_directory}              = '';
	$manage_files_by2->{_file_in}                = '';
	$manage_files_by2->{_pathNfile}              = '';
	$manage_files_by2->{_program_name}           = '';
	$manage_files_by2->{_suffix_type}            = '';

}

=head2 sub _exists

Another (private) way to see if a file exists
input is a scalar


=cut

sub _exists {

	my ($file) = @_;

	if ($file) {

		# default situation is to have a file non-existent
		my $answer = 0;

		# -e returns 1 or ''
		# verified by JL
		#		print("existence test for $file\n\n");
		if ( -e $file ) {

			#			print("file existence verified; answer=$answer\n\n");
			$answer = 1;
		}

		#	answer=1 if existent and =0 if non-existent
		#		print  ("file non-existence verified; answer=$answer\n\n") ;
		# verified by JL
		return ($answer);
	}
	else {
		print("\n");
	}

}



=head2 sub _read_2cols

 read in a 2-columned file
 reads cols 1 and 2 in a text file


=cut

sub _read_2cols {

	my ($ref_origin) = @_;

	if ( length $ref_origin ) {

		# CASE 1
		# declare locally scoped variables
		my ( $i, $line, $t, $x, $num_rows );
		my ( @TIME, @TIME_OUT, @OFFSET, @OFFSET_OUT );

		#		print("manage_files_by2,_read_2_cols, $$ref_origin\n");

		# open the file of interest
		open( FILE, $$ref_origin ) || print("Can't open $$ref_origin \n");

		#set the counter
		$i = 1;

		# read contents of shotpoint geometry file
		while ( $line = <FILE> ) {

			#print("\n$line");
			chomp($line);
			( $t, $x ) = split( "  ", $line );
			$TIME[$i]   = $t;
			$OFFSET[$i] = $x;

			#print("\n $TIME[$i] $OFFSET[$i]\n");
			$i = $i + 1;

		}

		close(FILE);

		$num_rows = $i - 1;

		# print out the number of lines of data for the user
		#print ("\nThis file contains $num_rows row(s) of data\n");

		#   to prevent contaminating outside variables
		@TIME_OUT   = @TIME;
		@OFFSET_OUT = @OFFSET;

		return ( \@TIME_OUT, \@OFFSET_OUT, $num_rows );
	}
	elsif ( not length $ref_origin
		and length $manage_files_by2->{_pathNfile} )
	{

		# CASE 2
		# declare locally scoped variables
		my ( $i, $line, $t, $x, $num_rows );
		my ( @TIME, @TIME_OUT, @OFFSET, @OFFSET_OUT );
		my $pathNfile = $manage_files_by2->{_pathNfile};

		#		print("manage_files_by2,read_2cols,$pathNfile\n");

		# open the file of interest
		open( FILE, $pathNfile )
		  || print("Can't open $pathNfile \n");

		#set the counter
		$i = 0;

		# read contents of shotpoint geometry file
		while ( $line = <FILE> ) {

			#			print("\n$line");
			chomp($line);

			#			split line on tab
			( $t, $x ) = split( /\t/, $line );
			$TIME[$i]   = $t;
			$OFFSET[$i] = $x;

			$i = $i + 1;

		}

		#			print("\n--$TIME[0]--$OFFSET[0]\n");
		#		    print("\n--$TIME[1]--$OFFSET[1]\n");
		close(FILE);

		$num_rows = $i;

		# print out the number of lines of data for the user
		#		print ("\nmanage_files_by2,read_2cols,num_rows=$num_rows\n");

		#   to prevent contaminating outside variables
		@TIME_OUT   = @TIME;
		@OFFSET_OUT = @OFFSET;

		return ( \@TIME_OUT, \@OFFSET_OUT, $num_rows );

	}
	else {
		print("manage_files_by2,read_2cols, missing reference to pathNfile\n");
	}

	return ();
}

=head2 sub _set_pathNfile

=cut

sub _set_pathNfile {

	  my ( $self,) = @_;

	  if ( length $manage_files_by2->{_file_in}  
	  	   && length $manage_files_by2->{_directory}) {
	  	   	
	  	 $manage_files_by2->{_pathNfile} =  $manage_files_by2->{_directory}.'/'.$manage_files_by2->{_file_in};
#         print("manage_files_by2, _set_pathNfile, pathNfile=$manage_files_by2->{_pathNfile} \n");
	    return ();
	  }
		 else {	
	  	print("manage_files_by2, _set_pathNfile, missing parameters\n");
	  }	  
	  return (); 
}

=head2 sub clean

delete a pre-existing file
directory of a file

=cut

sub clean {
	my ($self) = @_;

	if (    length $manage_files_by2->{_delete_base_file_name}
		and length $manage_files_by2->{_suffix_type} )
	{

		use App::SeismicUnixGui::misc::SeismicUnix
		  qw($gx $in $out $on $go $to $txt
		  $suffix_ascii $off $offset $pick $profile $report
		  $su $suffix_profile $sx $suffix_su $suffix_target
		  $suffix_pick $suffix_report $suffix_target_tilde
		  $suffix_txt $target $target_tilde $tracl);

		my $Project = Project_config->new();
		my $file    = manage_files_by2->new();

		my $DATA_SEISMIC_BIN  = $Project->DATA_SEISMIC_BIN;
		my $DATA_SEISMIC_SEGY = $Project->DATA_SEISMIC_SEGY;
		my $DATA_SEISMIC_SU   = $Project->DATA_SEISMIC_SU;
		my $DATA_SEISMIC_TXT  = $Project->DATA_SEISMIC_TXT;
		my $GEOPSY_PICKS      = $Project->GEOPSY_PICKS;
		my $GEOPSY_PROFILES   = $Project->GEOPSY_PROFILES;
		my $GEOPSY_REPORTS    = $Project->GEOPSY_REPORTS;
		my $GEOPSY_TARGETS    = $Project->GEOPSY_TARGETS;
		my $file_name         = $manage_files_by2->{_delete_base_file_name};
		my $suffix_type       = $manage_files_by2->{_suffix_type};
		my $outbound;

		if ( $suffix_type eq $txt ) {

			$outbound = $DATA_SEISMIC_TXT . '/' . $file_name . $suffix_txt;

		}
		elsif ( $suffix_type eq $su ) {

			$outbound = $DATA_SEISMIC_SU . '/' . $file_name . $suffix_su;

		}

		elsif ( $suffix_type eq $pick ) {

			$outbound = $GEOPSY_PICKS . '/' . $file_name . $suffix_pick;

			print("manage_files_by2, clean, outbound=$outbound\n");

		}

		elsif ( $suffix_type eq $profile ) {

			$outbound = $GEOPSY_PROFILES . '/' . $file_name . $suffix_profile;

			print("manage_files_by2, clean, outbound=$outbound\n");

		}

		elsif ( $suffix_type eq $report ) {

			$outbound = $GEOPSY_REPORTS . '/' . $file_name . $suffix_report;

			print("manage_files_by2, clean, outbound=$outbound\n");

		}

		elsif ( $suffix_type eq $target ) {

			$outbound = $GEOPSY_TARGETS . '/' . $file_name . $suffix_target;

			print("manage_files_by2, clean, outbound=$outbound\n");

		}

		elsif ( $suffix_type eq $target_tilde ) {

			$outbound =
			  $GEOPSY_TARGETS . '/' . $file_name . $suffix_target_tilde;
			print("manage_files_by2, clean, outbound=$outbound\n");

		}

		else {
			print("manage_files_by2, clean, unexpected value\n");
		}

		my $ans = _exists($outbound);

		#		print("manage_files_by2, clean, ans = $ans\n");

		if ($ans) {

			_delete($outbound);

			#			print(
			#"manage_files_by2, clean, Cleaning for pre-existing $outbound \n"
			#			);

		}
		else {
			#			print("manage_files_by2, clean, file does not exist NADA\n");
		}

	}
	else {
		print("manage_files_by2, set_geom4calc, missing values\n");
		print(
"manage_files_by2, clean, delete_base_file_name=$manage_files_by2->{_delete_base_file_name}\n"
		);

	}

}

=head2 sub _delete

This (provate) function/method deletes files

=cut 

sub _delete {

	my ($outbound) = @_;

	#   get directory names
	#	print("\n manage_files_by2, delete, Deleting $outbound \n");

	system(
		"                       	\\
                rm  $outbound      	\\
        "
	);

}

=head2 sub clear_empty_files

=cut

sub clear_empty_files {

	my ($self) = @_;

	if ( length( $manage_files_by2->{_directory} ) ) {

		my $dir = $manage_files_by2->{_directory};

		my ( @size,      @file_name, @inode );
		my ( $i,         $junk,      $cmd_file_name, $num_file_names );
		my ( $cmd_inode, $cmd_size,  $index_node_number );

#		print("manage_files_by2, clear_empty_files, dir=$manage_files_by2->{_directory} \n");

		#		print("\n manage_files_by2, clear_empty_files in dir=$dir\n");
		chomp $dir;

		$cmd_file_name  = "ls -1 $dir";
		$cmd_size       = "ls -s1 $dir";
		$cmd_inode      = "ls -i1 $dir";
		@file_name      = `$cmd_file_name`;
		@size           = `$cmd_size`;
		@inode          = `$cmd_inode`;
		$num_file_names = scalar @file_name;

		for ( my $i = 0 ; $i < $num_file_names ; $i++ ) {
			chomp $file_name[$i];
			chomp $inode[$i];

			$inode[$i] =~ s/^\s+//g;    # trim spaces at start
			( $inode[$i], $junk ) = split( / /, $inode[$i] );

			$file_name[$i] =~ s/^\s+//g;    # trim spaces at start
			( $file_name[$i], $junk ) = split( / /, $file_name[$i] );
		}

		for ( my $i = 1 ; $i <= $num_file_names ; $i++ ) {

			chomp $size[$i];
			$size[$i] =~ s/^\s+//g;         # trim spaces at start
			( $size[$i], $junk ) = split( / /, $size[$i] );

		}

		for ( my $i = 0, my $j = 1 ; $i < $num_file_names ; $i++, $j++ ) {

			my $test = ( -d $dir . '/' . $file_name[$i] );
			if ( $size[$j] == 0
				&& not($test) )
			{
				my $ans = ($test);

	 #				print("CASE of not a directory and file =0\n");
	 #				print("CASE name inode size = $file_name[$i] $inode[$i] $size[$j]\n");

				$index_node_number = $inode[$i];
				my $flow = (
					"cd $dir
								find . -inum $index_node_number -exec rm {} \\;"
				);

				#		    print $flow;
				system $flow;

			}
			else {

				#			print("immodpg,clean_trash,size>0,line=$i, NADA\n");
			}
		}

	}
	else {

	}

	return ();
}

=head2 sub count_lines

 this function counts the numbers of lines in a text file
 
=cut

sub count_lines {
	my ( $self, $ref_origin ) = @_;

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

=head2 sub delete

This function/method deletes files

=cut 

sub delete {

	my ( $self, $outbound ) = @_;

	#   get directory names
	#	print("\n manage_files_by2, delete, Deleting $outbound \n");

	system(
		"                       	\\
                rm  $outbound      	\\
        "
	);

}

=head2 sub does_file_exist

=cut

sub does_file_exist {

	my ( $does_file_exist, $ref_file ) = @_;

	$does_file_exist->{ref_file} = $$ref_file if defined($ref_file);

	#    print("manage_files_by2,does_file_exist,file name is, $$ref_file\n");

	# default situation is to have a file non-existent
	my $answer = 0;

	# -e returns 1 or ''
	# verified by JL
	# print("plain file for test is $$ref_file\n\n");
	if ( -f $does_file_exist->{ref_file} ) {

	 #	 print  ("manage_files_by2,does_file_exist,$$ref_file file exists\n\n") ;
		$answer = 1;
	}
	else {
	   #		 print("manage_files_by2,does_file_exist,$$ref_file is missing\n\n") ;
	}

	#	answer=1 if existent and =0 if non-existent
	# verified by JL
	return ($answer);
}

sub does_file_exist_sref {

	my ( $self, $ref_file ) = @_;

	if ($ref_file) {

		my $file = $$ref_file;

	# print("manage_files_by2,does_file_exist_sref,file name is, $$ref_file\n");

		# default situation is to have a file non-existent
		my $answer = 0;

		# -e returns 1 or ''
		# verified by JL
		# print("file for exist test is $$ref_file\n\n");
		# actually dies it exist and is it a plain file!!
		if ( -f $file ) {

			# print  ("file existence verified\n\n") ;
			$answer = 1;
		}

		#	answer=1 if existent and =0 if non-existent
		#verified by JL
		return ($answer);
	}
	else {
		print("does_file_exist_sref, ref_file is missing\n");
	}

}

=head2 sub exists

Another way to see if a file exists
input is a scalar


=cut

sub exists {

	my ( $self, $file ) = @_;

	if ($file) {

		# default situation is to have a file non-existent
		my $answer = 0;

		# -e returns 1 or ''
		# verified by JL
		#		print("existence test for $file\n\n");
		if ( -e $file ) {

			#			print("file existence verified; answer=$answer\n\n");
			$answer = 1;
		}

		#	answer=1 if existent and =0 if non-existent
		#		print  ("file non-existence verified; answer=$answer\n\n") ;
		#verified by JL
		return ($answer);
	}
	else {
		print("\n");
	}

}

=head2 sub get_3cols_aref
  
  This function reads 3 cols in a text file
  
=cut

sub get_3cols_aref {

	my ( $reference, $file_name, $skip_lines ) = @_;
	my ( @X, @Y, @Z );
	my $lines;

	print("\nThe input file is called $file_name\n");

	# open the file of interest
	open( FILE, "$file_name" ) || print("Can't open $file_name, $!\n");

	# skip lines
	for ( my $i = 0 ; $i < $skip_lines ; $i++ ) {
		$lines = <FILE>;
		print("line $i = $lines\n");
	}

	#set the counter
	my $i = 0;

	# read contents of file
	while ( my $lines = <FILE> ) {

		#     print("$lines");
		chomp($lines);
		my ( $x, $y, $z ) = split( " ", $lines );

		print("\n$x \n");
		$X[$i] = $x;
		$Y[$i] = $y;
		$Z[$i] = $z;

		#print("\n @X[$i] @Y[$i] @Z[$i] \n");
		$i++;
	}

	# number of geophones stations in file
	my $num_rows = $i - 1;

	#print ("This file contains $num_rows rows\n\n\n");
	# close the file of interest
	close(FILE);

	# make sure arrays do not contaminate outside

	return ( \@X, \@Y, \@Z );

}

=head2 sub get_5cols_aref

this function reads 5 cols in a text file

=cut

sub get_5cols_aref {

	my ( $self, $file_name ) = @_;

	if ( length $file_name ) {

		my @ID;
		my @X;
		my @Y;
		my @Z;
		my @W;
		my ($lines);
		my $i = 0;

#		print(
#"\n manage_files_by2, get_5cols_aref, The input file with 5 cols is called $file_name\n"
#		);

		# open the file of interest
		open( FILE, $file_name ) || print("Can't open $!\n");

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

			$i++;

		}
		$i = $i - 1;

		#	 		print ("This file contains number of indices: $i\n\n\n");
		# close the file of interest
		close(FILE);

		my @output_array = ( \@ID, \@X, \@Y, \@Z, \@W );
		return ( \@output_array );

	}
	else {
		print("\n, manage_files_by2, get_5cols_aref, missing a value\n");
	}

	print("\nThe input file with 5 cols is called $file_name\n");

}

=head2 sub get 1 column

=cut

sub get_1col {

	# this function reads first col from  a text file
	my ($self) = @_;

	if (   length $manage_files_by2->{_directory}
		&& length $manage_files_by2->{_file_in} )
	  {
	  	
    my @OFFSET;
   _set_pathNfile(); 
	my $pathNfile = $manage_files_by2->{_pathNfile};
#	print(
#		"\nmanage_files_by2, get_1col, The input is called $pathNfile\n");

	# open the file of interest
	open( FILE, $pathNfile ) || print("Can't open $pathNfile, $!\n");

	#set the counter
	my $i = 0;

	# read contents of shotpoint geometry file
	while ( my $line = <FILE> ) {

		#print("\n$line");
		chomp($line);
		my ($x) = $line;
		$OFFSET[$i] = $x;

#		print(
#			"\n manage_files_by2, read_1col, Reading 1 col file:$OFFSET[$i]\n");
		$i = $i + 1;
	}

	close(FILE);

	my $num_rows = scalar @OFFSET;

	# print out the number of lines of data for the user
#	print(
#"manage_files_by2, read_1col, This file contains $num_rows rows of data\n\n\n"
#	);

	# make sure arrays do not contaminate outside
	my $result = \@OFFSET;

	return ( $result, $num_rows );
	}

}


=head2 sub get_base_file_names_aref

read a list of file names
remove the su suffix
return array reference of the
list of names without su suffixes

=cut

sub get_base_file_name_aref {
	my ($self) = @_;

	# simple check
	if ( length $manage_files_by2->{_inbound_list} ) {

		my $inbound_list = $manage_files_by2->{_inbound_list};

		my ( $file_names_aref, $num_files ) = $readfiles->cols_1p($inbound_list);
		$control->set_aref($file_names_aref);
		# TODO to general suffix
		$control->remove_su_suffix4aref();
		my $base_file_name_aref = $control->get_base_file_name_aref();

		print("manage_files_by2, get_base_file_names, values=@$base_file_name_aref\n");
		
		my $result_a = $base_file_name_aref;
		my $result_b = $num_files;
		return ( $result_a, $result_b);

	}
	else {
		print("_get_base_file_name_aref, missing inbound lsit\n");
		return ();
	}
}

=pod sub get_whole 

 open and read
 the complete file
 line by line
    #print ("lines are @{$manage_files_by2->{_all_lines_aref}}\n"); 
    print ("We seem to have $manage_files_by2->{_num_lines} lines total\n");

=cut

sub get_whole {
	  my ($self) = @_;
	  my @all_lines;

	  if (
		  (
				 length $manage_files_by2->{_directory}
			  && length $manage_files_by2->{_file_in}
		  )
		  or length $manage_files_by2->{_pathNfile}
		)
	  {
		  my $inbound;
		  my $i = 0;

		  # full directory directory plus file name
		  if (   length $manage_files_by2->{_directory}
			  && length $manage_files_by2->{_file_in} )
		  {
			  $inbound =
				  $manage_files_by2->{_directory} . '/'
				. $manage_files_by2->{_file_in};

			  #			print("manage_files_by2, get_whole, $inbound\n");

		  }
		  elsif ( length $manage_files_by2->{_pathNfile} ) {

			  $inbound = $manage_files_by2->{_pathNfile};

			  #			print("manage_files_by2, get_whole, $inbound\n");

		  }
		  else {
			  print("manage_files_by2_get_whole, unexpected variable\n");
		  }

		  open( my $fh, '<', $inbound )
			or die "Could not open file '$manage_files_by2->{_file_in}' $!";
		  while ( my $row = <$fh> ) {

			  chomp $row;
			  $all_lines[$i] = $row;

		#			print "I read: " . $all_lines[$i] . "from the file, i=" . $i . "\n";
			  $i++;
		  }

		  $manage_files_by2->{_all_lines_aref} = \@all_lines;
		  close($fh);

		  $manage_files_by2->{_num_lines} =
			scalar @{ $manage_files_by2->{_all_lines_aref} };

		  # $manage_files_by2->{_num_lines} = 16;

# print("manage_files_by2, get_whole, num_lines: $manage_files_by2->{_num_lines}\n");
#for (my $i=14; $i < $manage_files_by2->{_num_lines}; $i++ ) {
# 	print("manage_files_by2, get_whole, all_lines_aref: @{$manage_files_by2->{_all_lines_aref}}[$i] \n");
#}
# print("manage_files_by2, get_whole, all_lines_aref: @{$manage_files_by2->{_all_lines_aref}} \n");
	  }
	  else {
		  print(
"manage_files_by2, get_whole, missing either directory or file name, or both \n"
		  );
	  }

	  my $result_ref = \@all_lines;
	  return ($result_ref);
}

=head2 sub set_directory

=cut

 sub set_directory {

	  my ( $self, $dir ) = @_;

	  if ( length($dir) ) {

		  $manage_files_by2->{_directory} = $dir;

#		print("manage_files_by2, set_directory, dir=$manage_files_by2->{_directory} \n");

	  }
	  else {
		  print("manage_files_by2, set_directory, missing value\n");
	  }

	  return ();
}

=head2 sub set_file_in

=cut

sub set_file_in {

	  my ( $self, $file_in ) = @_;

	  if ( length($file_in) ) {

		  $manage_files_by2->{_file_in} = $file_in;

#		print("manage_files_by2, set_file_in, file=$manage_files_by2->{_file_in} \n");

	  }
	  else {
		  print("manage_files_by2, set_file_in, missing value\n");
	  }

	  return ();

}


=head2 sub set_inbound_list

=cut

sub set_inbound_list {
	my ($self,$inbound_list) = @_;

	if ( length $inbound_list ) {
		
		$control->set_back_slashBgone($inbound_list);
		$inbound_list  = $control->get_back_slashBgone();
		$manage_files_by2->{_inbound_list} = $inbound_list;

	}
	else {
		print("manage_files_by2, set_inbound_list, missing list\n");
		return ();
	}

}


=head2

  read a 1-column file

=cut

sub read_1col_aref {

	  # open and read and input file
	  my ( $caller, $ref_file_name ) = @_;

	  #declare locally scoped variables
	  my ( $j, $num_rows );
	  my ( $i, $x );
	  my @X;
	  my $line;

	 #	print(
	 #"manage_files_by2,read_1col_aref,The output file name = $$ref_file_name\n"
	 #	);

	  # set the counter

	  $i = 0;
	  open( IN, "<$$ref_file_name" )
		or die "Could not open file '$$ref_file_name'. $!";

	  # read contents of file
	  while ( $line = <IN> ) {

		  # print("\n$line");
		  chomp($line);
		  ($x) = split( "  ", $line );
		  $X[$i] = $x;

		  # print("\n $X[$i]\n");
		  $i++;

	  }

	  close(FILE);

	  $num_rows = $i;

	  # print ("\nThis file contains $num_rows row(s) of data\n");

	  return ( \@X );

}

=pod

 read in a 2-columned file
 reads cols 1 and 2 in a text file


=cut

sub read_2cols_aref {

	  my ( $variable, $inbound, $spacer ) = @_;

	  if ( length $inbound
		  and $spacer )
	  {

		  #declare locally scoped variables
		  my ( $i, $line, $t, $x, $num_rows );
		  my ( @TIME, @OFFSET );

		  # open the file of interest
		  open( FILE, $inbound ) || print("Can't open $inbound \n");

		  #set the counter
		  $i = 0;

		  # read contents of shotpoint geometry file
		  while ( $line = <FILE> ) {

			  #			print("\n$line");
			  chomp($line);
			  ( $t, $x ) = split( $spacer, $line );
			  $TIME[$i]   = $t;
			  $OFFSET[$i] = $x;

			  #			print("\n $TIME[$i] $OFFSET[$i]\n");
			  $i = $i + 1;

		  }

		  close(FILE);

		  $num_rows = $i - 1;

		  # print out the number of lines of data for the user
		  #print ("\nThis file contains $num_rows row(s) of data\n");

		  my @array_out = ( \@TIME, \@OFFSET );
		  my $result    = \@array_out;

		  return ($result);

	  }
	  else {
		  print("manage_files_by2, read_2cols_ref, missing variables\n");
		  return ();
	}

}

=pod

 read in a 2-columned file
 reads cols 1 and 2 in a text file


=cut

sub read_2cols {

	  my ( $variable, $ref_origin ) = @_;

	  if ( length $ref_origin ) {

		  # CASE 1
		  # declare locally scoped variables
		  my ( $i, $line, $t, $x, $num_rows );
		  my ( @TIME, @TIME_OUT, @OFFSET, @OFFSET_OUT );

		  #		print("manage_files_by2,read_2cols $$ref_origin\n");

		  # open the file of interest
		  open( FILE, $$ref_origin ) || print("Can't open $$ref_origin \n");

		  #set the counter
		  $i = 1;

		  # read contents of shotpoint geometry file
		  while ( $line = <FILE> ) {

			  #print("\n$line");
			  chomp($line);
			  ( $t, $x ) = split( "  ", $line );
			  $TIME[$i]   = $t;
			  $OFFSET[$i] = $x;

			  #print("\n $TIME[$i] $OFFSET[$i]\n");
			  $i = $i + 1;

		  }

		  close(FILE);

		  $num_rows = $i - 1;

		  # print out the number of lines of data for the user
		  #print ("\nThis file contains $num_rows row(s) of data\n");

		  #   to prevent contaminating outside variables
		  @TIME_OUT   = @TIME;
		  @OFFSET_OUT = @OFFSET;

		  return ( \@TIME_OUT, \@OFFSET_OUT, $num_rows );
	  }
	  elsif ( not length $ref_origin
		  and length $manage_files_by2->{_pathNfile} )
	  {

		  # CASE 2
		  # declare locally scoped variables
		  my ( $i, $line, $t, $x, $num_rows );
		  my ( @TIME, @TIME_OUT, @OFFSET, @OFFSET_OUT );
		  my $pathNfile = $manage_files_by2->{_pathNfile};

		  #		print("manage_files_by2,read_2cols,$pathNfile\n");

		  # open the file of interest
		  open( FILE, $pathNfile )
			|| print("Can't open $pathNfile \n");

		  #set the counter
		  $i = 0;

		  # read contents of shotpoint geometry file
		  while ( $line = <FILE> ) {

			  #			print("\n$line");
			  chomp($line);

			  #			split line on tab
			  ( $t, $x ) = split( /\t/, $line );
			  $TIME[$i]   = $t;
			  $OFFSET[$i] = $x;

			  $i = $i + 1;

		  }

		  #			print("\n--$TIME[0]--$OFFSET[0]\n");
		  #		    print("\n--$TIME[1]--$OFFSET[1]\n");
		  close(FILE);

		  $num_rows = $i;

		  # print out the number of lines of data for the user
		  #		print ("\nmanage_files_by2,read_2cols,num_rows=$num_rows\n");

		  #   to prevent contaminating outside variables
		  @TIME_OUT   = @TIME;
		  @OFFSET_OUT = @OFFSET;

		  return ( \@TIME_OUT, \@OFFSET_OUT, $num_rows );

	  }
	  else {
		  print(
			  "manage_files_by2,read_2cols, missing reference to pathNfile\n");
	  }

	  return ();
}

sub read_1col {

	  # this function reads 1 col from  a text file

	  my ( $self, $file_name ) = @_;
	  my @OFFSET;

#	  print(
#		  "\nmanage_files_by2, read_1col, The input file is called $file_name\n"
#	  );

	  # open the file of interest
	  open( FILE, $file_name ) || print("Can't open $file_name, $!\n");

	  #set the counter
	  my $i = 0;

	  # read contents of shotpoint geometry file
	  while ( my $line = <FILE> ) {

		  #print("\n$line");
		  chomp($line);
		  my ($x) = $line;
		  $OFFSET[$i] = $x;

#		  print(
#			  "\n manage_files_by2, read_1col, Reading 1 col file:$OFFSET[$i]\n"
#		  );
		  $i = $i + 1;

	  }

	  close(FILE);

	  my $num_rows = scalar @OFFSET;

	  # print out the number of lines of data for the user
#	  print(
#"manage_files_by2, read_1col, This file contains $num_rows rows of data\n\n\n"
#	  );

	  # make sure arrays do not contaminate outside
	  my $result = \@OFFSET;

	  return ( $result, $num_rows );

}

=pod

 read in a 2-columned file
 reads cols 1 and 2 in a text file


=cut

sub get_10cols_aref {

	  my ( $self, $inbound, $skip ) = @_;

	  #		print("$inbound--\n");

	  if ( length $inbound
		  and $skip )
	  {

		  # declare locally scoped variables
		  my ( $i, $j, $k, $line, $num_rows );
		  my ( @a, @b, @c, @d, @e, @f, @g, @h, @i, @j );
		  my @value;
		  my (@row_aref);

		  # match one or more spaces from start of line
		  # before the first number
		  my $spacer = '^\s+';

		  # open the file of interest
		  open( FILE, $inbound ) || print("Can't open $inbound \n");

		  # set the counter
		  $i = 0;
		  $j = 0;

		  # read contents of shotpoint geometry file
		  while ( $line = <FILE> ) {

			  if ( $i >= $skip ) {
				  chomp($line);
				  my @stuff    = split( $spacer, $line );
				  my $last_idx = $#stuff;
				  my @value    = @stuff[ 1 .. $last_idx ];
				  $row_aref[$j] = \@value;
				  $j = $j + 1;

				  #				print ("value_0=$value[0]---\n");
			  }
			  $i = $i + 1;
		  }

		  $num_rows = $i - 1;
		  close(FILE);

		  # print out the number of lines of data for the user
		  #	print("\nThis file contains $num_rows row(s) of data\n");
		  my $result = \@row_aref;
		  return ($result);

	  }
	  else {
		  print("manage_files_by2, get_10cols_ref, missing variables\n");
		  return ();

	}
}

=head2 sub read_tx_curves2plot


=cut

sub read_tx_curves2plot {

	  my ( $self, $curve_aref ) = @_;

	  if ( length $curve_aref ) {

		  my @curve     = @$curve_aref;
		  my $num_files = scalar @curve;
		  my $first     = 0;
		  my $last      = $num_files - 1;
		  my @color;
		  my ( $ref_T, $ref_X );
		  my @num_tx_pairs;

=head2 Define

private hash

=cut		

		  my $read_tx_curves2plot = {
			  _curves       => '',
			  _curve_color  => '',
			  _num_tx_pairs => '',
		  };

=head2 Define

curve color

=cut

		  $color[0] = 'red';
		  $color[1] = 'blue';
		  $color[2] = 'green';
		  $color[3] = 'yellow';
		  $color[4] = 'white';
		  $color[5] = 'black';
		  $color[6] = 'purple';
		  $color[7] = 'orange';
		  $color[8] = 'magenta';
		  $color[9] = 'brown';

=head2 Collect

     curve data
     
=cut

		  if ( $num_files == 1 ) {

			  # first case = 0
			  $read_tx_curves2plot->{_curves} =
				$read_tx_curves2plot->{_curves} . $curve[$first];

			  ( $ref_T, $ref_X, $num_tx_pairs[$first] ) =
				_read_2cols( \$curve[$first] );

			  $read_tx_curves2plot->{_num_tx_pairs} =
				$read_tx_curves2plot->{_num_tx_pairs} . $num_tx_pairs[$first];
			  $read_tx_curves2plot->{_curve_color} =
				$read_tx_curves2plot->{_curve_color} . $color[$first];
		  }
		  else {
			  # print(" # files ==1 2\n");
		  }

		  if ( $num_files > 1 ) {

			  # first case = 0
			  $read_tx_curves2plot->{_curves} =
				$read_tx_curves2plot->{_curves} . $curve[$first] . ',';

			  ( $ref_T, $ref_X, $num_tx_pairs[$first] ) =
				_read_2cols( \$curve[$first] );

			  $read_tx_curves2plot->{_num_tx_pairs} =
				  $read_tx_curves2plot->{_num_tx_pairs}
				. $num_tx_pairs[$first] . ',';
			  $read_tx_curves2plot->{_curve_color} =
				$read_tx_curves2plot->{_curve_color} . $color[$first] . ',';

			  if ( $num_files >= 2 ) {

				  for ( my $i = 1 ; $i < ($last) ; $i++ ) {

					  # middle cases
					  ( $ref_T, $ref_X, $num_tx_pairs[$i] ) =
						_read_2cols( \$curve[$i] );

					  $read_tx_curves2plot->{_curves} =
						$read_tx_curves2plot->{_curves} . $curve[$i] . ',';
					  $read_tx_curves2plot->{_num_tx_pairs} =
						  $read_tx_curves2plot->{_num_tx_pairs}
						. $num_tx_pairs[$i] . ',';
					  $read_tx_curves2plot->{_curve_color} =
						$read_tx_curves2plot->{_curve_color} . $color[$i] . ',';
				  }

				  # last case
				  $read_tx_curves2plot->{_curves} =
					$read_tx_curves2plot->{_curves} . $curve[$last];

				  ( $ref_T, $ref_X, $num_tx_pairs[ ( $num_files - 1 ) ] ) =
					_read_2cols( \$curve[$last] );

				  $read_tx_curves2plot->{_num_tx_pairs} =
					  $read_tx_curves2plot->{_num_tx_pairs}
					. $num_tx_pairs[$last];
				  $read_tx_curves2plot->{_curve_color} =
					$read_tx_curves2plot->{_curve_color} . $color[$last];

			 #print("\tcurve colors=$read_tx_curves2plot->{_curve_color}\n");
			 #print("\tnum_tx_pairs = $read_tx_curves2plot->{_num_tx_pairs}\n");
			  }
			  else {
				  # print(" # files > 2\n");
			}
		  }
		  else {
			  # print(" # files > 0 \n");
		  }

		  my $result = $read_tx_curves2plot;

		  return ($result);
	  }
	  else {
		  print(
"manage_files_by2, read_tx_curves2plot, missing curve aref=@{$curve_aref}\n"
		  );
		  return ();
	}
}

=head2 sub read_par

 read parameter file
 file name is a scalar reference (to 
 scalar file name)
 o/p includes array of array references

=cut 

sub read_par {

	  my ( $self, $ref_file_name ) = @_;

#	print("\nmanage_files_by2,read_par, The input file is called $$ref_file_name\n");

=pod Steps

     1. open file

     2. set the counter

     3. read contents of parameter file

     4. odd-numbered lines contain tnmo and even contain vnmo
     

=cut

	  open( FILE, $$ref_file_name )
		|| print("Can't open $$ref_file_name, $!\n");

	  my $row = -1;
	  my (@Items);
	  my ( $i,   $line );
	  my ( @row, @ValuesPerRow );

	  while ( $line = <FILE> ) {
		  $row++;
		  my @things;

		  # print("manage_files_by2,read_par, $line");

=pod

 1. remove end of line
 2. calculate number of useful elements
 2. only leave the numbers with commas in between:
 	e.g. things=tnmo 0.0567282,0.271768
 	N.B. these are only 2 things and not 3 things

=cut

		  chomp($line);
		  @things = split /[=,]/, $line;

		  # print("manage_files_by2,read_par, things=@things, row= $row\n");
		  $Items[$row]        = \@things;
		  $ValuesPerRow[$row] = scalar(@things);

# print("manage_files_by2,read_par, ValuesPerRow=$ValuesPerRow[$row], row=$row\n");

	  }
	  close(FILE);

 # print("manage_files_by2,read_par, ROW 0 @{$Items[0]} \n");
 # print("manage_files_by2,read_par, ROW 1 @{$Items[1]} \n");
 # print("manage_files_by2,read_par, ROW 0,1 Values per rows: @ValuesPerRow\n");
	  return ( \@Items, \@ValuesPerRow );
}

=head2 sub set_appendix

set file for catting

=cut

sub set_appendix {
	  my ( $self, $appendix ) = @_;

	  if ( length $appendix ) {

		  $manage_files_by2->{_appendix} = $appendix;

   #		print("manage_files_by2, set_appendix, base_file_name_out = $appendix\n");
	  }
	  else {
		  print("manage_files_by2, set_appendix, missing variable\n");
	  }

	  my $result;

	  return ($result);

}

=head2 sub set_pathNfile

=cut

sub set_pathNfile {

	  my ( $self, $pathNfile ) = @_;

	  if ( length($pathNfile) ) {

		  $manage_files_by2->{_pathNfile} = $pathNfile;

#		print("manage_files_by2, set_pathNfile, pathNfile=$manage_files_by2->{_pathNfile} \n");

	  }
	  else {
		  print("manage_files_by2, set_pathNfile, missing value\n");
	  }

	  return ();
}

=head2 sub set_cat_base_file_name_out

=cut

sub set_cat_base_file_name_out {
	  my ( $self, $base_file_name_out ) = @_;

	  if ( length $base_file_name_out ) {

#		print(
#"manage_files_by2, set_cat_base_file_name_out, base_file_name_out = $base_file_name_out\n"
#		);

		  $manage_files_by2->{_cat_base_file_name_out} = $base_file_name_out;
	  }
	  else {
		  print(
			  "manage_files_by2, set_cat_base_file_name_out, missing variable\n"
		  );
	  }

	  my $result;

	  return ($result);

}

=head2 sub set_cat_su

append individual output files to 
a major product file

=cut

sub set_cat_su {

	  my ($self) = @_;

	  if (    length $manage_files_by2->{_cat_base_file_name_out}
		  and length $manage_files_by2->{_appendix} )
	  {

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut

		  use Moose;
		  use App::SeismicUnixGui::misc::SeismicUnix
			qw($append $in $out $on $go $to $suffix_ascii $off
			$suffix_segd $su $suffix_segy $suffix_sgy $suffix_su
			$suffix_segd $suffix_txt $suffix_bin);

		  my $Project           = Project_config->new();
		  my $DATA_SEISMIC_BIN  = $Project->DATA_SEISMIC_BIN;
		  my $DATA_SEISMIC_SEGY = $Project->DATA_SEISMIC_SEGY;
		  my $DATA_SEISMIC_SU   = $Project->DATA_SEISMIC_SU;
		  my $DATA_SEISMIC_TXT  = $Project->DATA_SEISMIC_TXT;

		  my $log      = message->new();
		  my $run      = flow->new();
		  my $cat_su   = cat_su->new();
		  my $data_out = data_out->new();

=head2 Declare

	local variables

=cut

		  my (@flow);
		  my (@items);
		  my (@cat_su);
		  my (@data_out);

=head2 Set up

	cat_su parameter values

=cut

		  $cat_su->clear();
		  $cat_su->base_file_name1(
			  quotemeta(
				  $DATA_SEISMIC_SU . '/' . $manage_files_by2->{_appendix}
				)
				. $suffix_su
		  );

		  #	$cat_su->base_file_name2(
		  #		quotemeta( $DATA_SEISMIC_SU . '/' . '00000004' ) . $suffix_su );
		  $cat_su[1] = $cat_su->Step();

=head2 Set up

	data_out parameter values

=cut

		  $data_out->clear();
		  $data_out->base_file_name(
			  quotemeta( $manage_files_by2->{_cat_base_file_name_out} ) );
		  $data_out->suffix_type($su);
		  $data_out[1] = $data_out->Step();

=head2 DEFINE FLOW(s) 


=cut

		  @items = ( $cat_su[1], $append, $data_out[1], $go );
		  $flow[1] = $run->modules( \@items );

=head2 RUN FLOW(s) 


=cut

		  $run->flow( \$flow[1] );

=head2 LOG FLOW(s)

	to screen and FILE

=cut

		  $log->screen( $flow[1] );

		  $log->file(localtime);
		  $log->file( $flow[1] );

	  }
	  else {
		  print(",manage_files_by2, cat_su, missing variables \n");
		  print(
",manage_files_by2, cat_su, manage_files_by2->{_cat_base_file_name_out}=$manage_files_by2->{_cat_base_file_name_out} \n"
		  );
		  print(
",manage_files_by2, cat_su, manage_files_by2->{_appendix}=$manage_files_by2->{_appendix} \n"
		  );
	}

}    # end set_cat_su

=head2 sub set_cat_txt

append individual output files to 
a major product file

=cut

sub set_cat_txt {

	  my ($self) = @_;

	  if (    length $manage_files_by2->{_cat_base_file_name_out}
		  and length $manage_files_by2->{_appendix} )
	  {

=head2 SYNOPSIS

PERL PROGRAM NAME: 

AUTHOR:  

DATE:

DESCRIPTION:

Version:

=head2 USE

=head3 NOTES

=head4 Examples

=head2 SYNOPSIS

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut

		  use Moose;
		  use App::SeismicUnixGui::misc::SeismicUnix
			qw($append $in $out $on $go $to $suffix_ascii $off $suffix_segd $suffix_segy $suffix_sgy $suffix_su $suffix_segd $suffix_txt $suffix_bin);

		  my $Project           = Project_config->new();
		  my $DATA_SEISMIC_BIN  = $Project->DATA_SEISMIC_BIN;
		  my $DATA_SEISMIC_SEGY = $Project->DATA_SEISMIC_SEGY;
		  my $DATA_SEISMIC_SU   = $Project->DATA_SEISMIC_SU;
		  my $DATA_SEISMIC_TXT  = $Project->DATA_SEISMIC_TXT;

		  my $log      = message->new();
		  my $run      = flow->new();
		  my $cat_txt  = cat_txt->new();
		  my $data_out = data_out->new();

=head2 Declare

	local variables

=cut

		  my (@flow);
		  my (@items);
		  my (@cat_txt);
		  my (@data_out);

=head2 Set up

	cat_txt parameter values

=cut

		  $cat_txt->clear();
		  $cat_txt->base_file_name1(
			  quotemeta(
				  $DATA_SEISMIC_TXT . '/' . $manage_files_by2->{_appendix}
				)
				. $suffix_txt
		  );

		  $cat_txt[1] = $cat_txt->Step();

=head2 Set up

	data_out parameter values

=cut

		  $data_out->clear();
		  $data_out->base_file_name(
			  quotemeta( $manage_files_by2->{_cat_base_file_name_out} ) );
		  $data_out->suffix_type( quotemeta('txt') );
		  $data_out[1] = $data_out->Step();

=head2 DEFINE FLOW(s) 


=cut

		  @items = ( $cat_txt[1], $append, $data_out[1], $go );
		  $flow[1] = $run->modules( \@items );

=head2 RUN FLOW(s) 


=cut

		  $run->flow( \$flow[1] );

=head2 LOG FLOW(s)

	to screen and FILE

=cut

		  $log->screen( $flow[1] );

		  $log->file(localtime);
		  $log->file( $flow[1] );

	  }
	  else {
		  print(",manage_files_by2, cat_txt, missing variables \n");
		  print(
",manage_files_by2, cat_txt, manage_files_by2->{_cat_base_file_name_out}=$manage_files_by2->{_cat_base_file_name_out} \n"
		  );
		  print(
",manage_files_by2, cat_txt, manage_files_by2->{_appendix}=$manage_files_by2->{_appendix} \n"
		  );
	}

}    # end set_cat_txt

=head2 sub set_delete_base_file_name

=cut

sub set_delete_base_file_name {
	  my ( $self, $base_file_name ) = @_;

	  if ( length $base_file_name ) {

#	print(
#   "manage_files_by2, set_delete_base_file_name, base_file_name = $base_file_name\n"
#	);

		  $manage_files_by2->{_delete_base_file_name} = $base_file_name;

	  }
	  else {
		  print(
			  "manage_files_by2, set_delete_base_file_name, missing variable\n"
		  );
	  }

	  my $result;
	  return ($result);

}

#=head2 sub set_porgram_name
#
#=cut
#
#sub set_program_name {
#
#	my ( $self, $program_name ) = @_;
#
#	if ( length $program_name ) {
#
#		$manage_files_by2->{_program_name} = $program_name;
#
#	}
#	else {
#		carp "missing program_name";
#		print("manage_files_by2,set_program_name,missing program_name\n");
#	}
#
#}

=head2 sub suffix_type

geometry values

=cut

sub set_suffix_type {
	  my ( $self, $suffix_type ) = @_;

	  my $result;

	  if ( length $suffix_type ) {

		  $manage_files_by2->{_suffix_type} = $suffix_type;

	  }
	  else {
		  print("manage_files_by2, missing suffix_type=$suffix_type\n");
	  }

	  return ($result);
}

=pod sub unique_elements

	filter out only unique elements from an array

=cut 

sub unique_elements {
	  my ( $self, $array_ref ) = @_;

	  my $results_ref;

	  if ($array_ref) {

		  my @unique_progs;
		  my $total_num_progs4flow = scalar @{$array_ref};
		  my $false                = 0;
		  my $true                 = 1;
		  my $num_unique_progs     = 1;

		  my $repeated = $false;

		  # the first program is always unique
		  $unique_progs[0] = @{$array_ref}[0];

	 #		print("1. manage_files_by2, first program in flow: @{$array_ref}[0]\n");
	 #		print("2. manage_files_by2, num_unique_progs=$num_unique_progs\n\n");

		  for ( my $i = 1 ; $i < $total_num_progs4flow ; $i++ ) {

			  for ( my $j = 0 ; $j < $num_unique_progs ; $j++ ) {

				  if ( $unique_progs[$j] eq @{$array_ref}[$i] ) {

#					print("3. manage_files_by2, program index #$i in flow: @{$array_ref}[$i]\n");
#					print("4. manage_files_by2, repeated program detected \n");
#					print("5. manage_files_by2, prog repeated: @{$array_ref}[$i]\n\n");
					  $repeated = $true;

					  # exit if-loop and increment $j
				  }
				  else {
#					print("6. manage_files_by2, program index #$i in flow: @{$array_ref}[$i]\n");
#	print("7. manage_files_by2, prog @{array_ref}[$i] is unique\n\n");
#					print("8. manage_files_by2,unique_prog detected=@{$array_ref}[$i] \n");
				}

			  }

			  if ($repeated) {

				  $repeated = $false;    #reset for next check

			  }
			  else {
				  push @unique_progs, @{$array_ref}[$i];

	   #				print("9. manage_files_by2,unique new program found for output \n");
				  $num_unique_progs++;

	 #				print("10. manage_files_by2, num_unique_progs=$num_unique_progs\n\n");
			}

		  }    # end all programs

		# print("3. manage_files_by2, unique_progs are: @unique_progs\n");
		# print ("3. manage_files_by2, num_unique_progs=$num_unique_progs\n\n");

		  $results_ref = \@unique_progs;
		  return ($results_ref);

	  }
	  else {
		  print("manage_files_by2,unique_elements, missing array\n");
		  return ();

	}    # end if
}

=pod

  write out a 1-column file

=cut

sub write_1col_aref {

	  # open and write to output file
	  my ( $variable, $ref_X, $ref_file_name, $ref_fmt ) = @_;

#	print("\n manage_files_by2,write_1col_aref,The output file name = $$ref_file_name\n");
#	print("\n manage_files_by2,write_1col_aref,VALUE: @$ref_X\n");
#	print("\n manage_files_by2,write_1col_aref,The output file uses the following format: $$ref_fmt\n");
	  my $num_rows = scalar @$ref_X;

	  # $variable is an unused hash

#   print("\n manage_files_by2,write_1col_aref,The output file contains $num_rows rows\n");

	  open( OUT, ">$$ref_file_name" );

	  for ( my $j = 0 ; $j < $num_rows ; $j++ ) {

		  printf OUT "$$ref_fmt\n", @$ref_X[$j];

		  #		print @$ref_X[$j]."\n";

	  }

	  close(OUT);
	  return ();

}

=pod

  write out a 1-columned file

=cut

sub write_1col1 {

	  # open and write to output file
	  my ( $variable, $ref_X, $ref_file_name, $ref_fmt ) = @_;

	  #declare locally scoped variables
	  my $j;

	  my $num_rows = scalar $$ref_X;

	  # $variable is an unused hash

	  #print("\nThe subroutine has is called $variable\n");
	  #print("\nThe output file contains $num_rows rows\n");
	  #print("\nThe output file uses the following format: $$ref_fmt\n");
	  open( OUT, ">$$ref_file_name" );

	  for ( $j = 1 ; $j <= $num_rows ; $j++ ) {

		  #print OUT  ("$$ref_X[$j] $$ref_Y[$j]\n");
		  printf OUT "$$ref_fmt\n", $$ref_X[$j];

		  #print("$$ref_X[$j] $$ref_Y[$j]\n");
	  }

	  close(OUT);
	  return ();

}

=pod

  write out a 2-columned file

=cut

sub write_2cols {

	  # open and write to output file
	  my ( $self, $ref_X, $ref_Y, $num_rows, $ref_file_name, $ref_fmt ) = @_;

	  #declare locally scoped variables
	  my $j;

	  # $variable is an unused hash

	  #		print("\nThe subroutine has is called %$self\n");
	  #		print("\nThe output file contains $num_rows rows\n");
	  #		print("\nThe output file uses the following format:--$$ref_fmt--\n");
	  #		print("\nThe output file name is $$ref_file_name\n");

	  open( OUT, ">$$ref_file_name" );

	  for ( $j = 0 ; $j < $num_rows ; $j++ ) {

		  #		print OUT  ("$$ref_X[$j] $$ref_Y[$j]\n");
		  printf OUT "$$ref_fmt\n", $$ref_X[$j], $$ref_Y[$j];

		  #		print("index=$j;$$ref_X[$j] $$ref_Y[$j]\n");
	  }

	  close(OUT);
	  return ();

}

=head2 sub write_5cols 

WRITE OUT FILE
open and write to output file
	
=cut 

sub write_5cols {

	  my ( $self, $ref_X, $ref_Y, $ref_Z, $ref_A, $ref_B, $file_name, $fmt ) =
		@_;

	  if (length $ref_X &&
	      length $ref_Y &&
	      length $ref_A &&
	      length $ref_B &&
	      length $file_name &&
	      length $fmt ) {
			
		  my $num_rows = scalar @$ref_X;
#		  $num_rows=5;
		  print ("manage_files_by2,write_5cols,num_rows, $num_rows\n");

#	  open( OUT, ">$file_name" );

	  for ( my $j = 0 ; $j < $num_rows ; $j++ ) {

#		  printf OUT "$fmt", @$ref_X[$j], @$ref_Y[$j], @$ref_Z[$j],
#			@$ref_A[$j], @$ref_B[$j];
			print ("$fmt @$ref_X[$j], @$ref_Y[$j], @$ref_Z[$j],@$ref_A[$j], @$ref_B[$j]\n");
	  }

	  close(OUT);	
	  } else{
		print("manage_files_by2,write_5cols, incompelte values\n");
	  }


	  #	print(
	  #		"\nmanage_files_by2,write_5cols,The output file is called $file_name\n"
	  #	);

}

=head2 sub write_par

 write parameter file
 file name is a scalar reference to 
 scalar file name

=cut 

sub write_par {

	  my ( $self, $ref_outbound, $ref_array_tnmo_row, $ref_array_vnmo_row,
		  $first_name, $second_name )
		= @_;

# print("\nmanage_files_by2,write_par,The input file is called $$ref_outbound\n");

=head2 local definitions

=cut

	  my $values_per_row;
	  my @tnmo_array               = @$ref_array_tnmo_row;
	  my @vnmo_array               = @$ref_array_vnmo_row;
	  my $number_of_values_per_row = scalar @tnmo_array;

=pod Steps

     odd-numbered lines contain tnmo and even contain vnmo
     e.g., tnmo=1,2,3
     	   vnm==4,5,6
     
=cut

=head2 open and write values

=cut

	  open( my $fh, '>', $$ref_outbound );

	  print $fh ("$first_name=$tnmo_array[1]");

	  for ( my $i = 2 ; $i < $number_of_values_per_row ; $i++ ) {

		  print $fh (",$tnmo_array[$i]");

	  }

	  print $fh ("\n");

	  print $fh ("$second_name=$vnmo_array[1]");

	  for ( my $i = 2 ; $i < $number_of_values_per_row ; $i++ ) {

		  print $fh (",$vnmo_array[$i]");

	  }

	  close($fh);
	  return ();
}

=head2 sub write_multipar

 write parameter file
 file name is a scalar reference to 
 scalar file name

=cut 

sub write_multipar {

	  my ( $self, $ref_outbound, $ref_array_cdp_row,
		  $ref_array_tnmo_row, $ref_array_vnmo_row, $first_name, $second_name )
		= @_;

	 #	print(
	 #		"\nmanage_files_by2,write_par,The input file is called $$ref_outbound\n"
	 #	);

=head2 local definitions

=cut

	  my $values_per_row;
	  my @cdp_array                = $ref_array_cdp_row;
	  my @tnmo_array               = @$ref_array_tnmo_row;
	  my @vnmo_array               = @$ref_array_vnmo_row;
	  my $number_of_values_per_row = scalar @tnmo_array;
	  my $number_of_cdp_per_row    = scalar @cdp_array;

	  #	print("@$ref_array_cdp_row \n");
	  #	print("$number_of_values_per_row \n");

=pod Steps

     odd-numbered lines contain tnmo and even contain vnmo
     e.g., tnmo=1,2,3
     	   vnm==4,5,6
     
=cut

=head2 open and write values

=cut

	  #print("manage_files_by2,par, tnmo_row @tnmo_array\n");
	  #print("manage_files_by2,par, vnmo_row @vnmo_array\n");
	  #print("manage_files_by2,par, tnmo_row $tnmo_array[1] \n");
	  #print("manage_files_by2,par, ref_outbound $$ref_outbound \n");

	  open( my $fh, '>', $$ref_outbound );

	  print $fh ("$first_name=$tnmo_array[1]");

	  for ( my $i = 2 ; $i < $number_of_values_per_row ; $i++ ) {

		  print $fh (",$tnmo_array[$i]");

	  }

	  print $fh ("\n");

	  print $fh ("second_name=$vnmo_array[1]");

	  for ( my $i = 2 ; $i < $number_of_values_per_row ; $i++ ) {

		  print $fh (",$vnmo_array[$i]");

	  }

	  print $fh ("\n");

	  close($fh);
	  return ();
}

1;

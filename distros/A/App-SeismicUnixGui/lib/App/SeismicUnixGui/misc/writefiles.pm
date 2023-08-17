package App::SeismicUnixGui::misc::writefiles;

use Moose;
our $VERSION = '0.0.1';

=pod

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PERL PROGRAM NAME: writefiles 
 AUTHOR: Juan Lorenzo
 DATE: Oct 29 2012
 DESCRIPTION write file operations
 Version 1

 STEPS ARE:
=cut

use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

my ( @col1, @col2 );
my ( $num_rows, $file_out, $fmt );

my $newline = '
';

my $writefiles = {
    _format    => '',
    _file_name => '',
    _path      => '',
};

=pod

 sub clear 
     clear global variables from the memory

=cut

sub clear {
    $writefiles->{_format} = '';
}

sub cols_2 {

    #WRITE OUT FILE
    #open and write 2 cols to output file

    open( OUT, ">$file_out" );
    my $j;
    print("format is: $fmt\n\n");
    for ( $j = 1 ; $j <= $num_rows ; $j++ ) {
        printf OUT "$fmt\n", $col1[$j], $col2[$j];

        #print("$col1[$j] $col2[$j]\n");
    }
    close(OUT);
}

sub data {
    my ( $variables, $ref_array_data1, $ref_array_data2 ) = @_;

    @col1 = @$ref_array_data1 if defined($ref_array_data1);
    @col2 = @$ref_array_data2 if defined($ref_array_data2);
    $num_rows = scalar(@col1) - 1;
    print("length of data goes from 1 : $num_rows points\n\n");
}

sub file {
    my ( $variables, $ref_filename ) = @_;
    $file_out = $$ref_filename if defined($ref_filename);

    #print("filename out is: $file_out\n\n");
}

=head2 sub out_1_col 

 write 1 col into text file
 
=cut

sub out_1_col {

    my ( $self, $ref_X ) = @_;

    if (   $writefiles->{_file_name} ne $empty_string
        && $writefiles->{_path} ne $empty_string
        && $ref_X ne $empty_string )
    {

        my $outbound_fh;
        my $outbound = $writefiles->{_path} . '/' . $writefiles->{_file_name};

        print("writefiles,cols_7 outbound = $outbound\n");

        open( $outbound_fh, '>', $outbound )
          || print(
            "writefiles,cols_7,Can't open $writefiles->{_file_name}, $!\n");

        # set the counter
        my $op_counter   = 0;
        my @output_array = @$ref_X;
        my $array_length = scalar @output_array;

        # write contents of file
        for ( my $j = 0 ; $j <= $array_length ; $j++ ) {

            print OUT ("$$ref_X[$j]\n");

            # printf OUT "$$ref_fmt\n", $$ref_X[$j];
#            print("$$ref_X[$j]\n");
#
        }

        # close the file of interest
        close($outbound_fh);

        return ();

    }
    else {
        print("writefiles,cols_7,missing either ref_X, path or file_name\n");
        print("file_name 				= $writefiles->{_file_name}\n");
        print("path 					= $writefiles->{_path}\n");
        return ();
    }

}

=head2 sub config_LSU 

=cut

sub config_LSU {

    my ( $self, $array_ref ) = @_;

    #my ($self,$array_ref) = @_;
    #print ("@$array_ref\n");
    #foreach (@$array_ref) {
    #  print "$_\n";
    ##}
    print("$self writefiles,config_LSU\n");

    return ();
}

sub format {
    my ( $variables, $format ) = @_;
    $writefiles->{_format} = $format if defined($format);
    $fmt = $writefiles->{_format};
    my @cols = split( /%/, $format );
    my $num_cols = scalar(@cols) - 1;

    # only use element =1 through i<=$num_cols
    # do not use i=0
    #print("#cols = $num_cols\n\n");
    print("format is = $writefiles->{_format}\n\n");
}

sub outcol_1 {

    #WRITE OUT FILE
    #open and write 1 cols to output file
    open( OUT, ">$file_out" );
    my $j;

    #print("format is: $fmt\n\n");
    for ( $j = 1 ; $j <= $num_rows ; $j++ ) {
        printf OUT "$fmt\n", $col1[$j], $col2[$j];

        #print("$col1[$j] \n");
    }
    close(OUT);
}

sub setcol_1 {
    my ( $variables, $ref_array_data1 ) = @_;
    @col1 = @$ref_array_data1 if defined($ref_array_data1);
    $num_rows = scalar(@col1) - 1;
    print("length of data goes from 1 : $num_rows points\n\n");
}

sub setfile {
    my ( $variables, $ref_filename ) = @_;
    $file_out = $ref_filename if defined($ref_filename);
    print("filename out is: $$file_out\n\n");
}

=head2 sub set_file_name

=cut

sub set_file_name {
    my ( $self, $file_name_ref ) = @_;

    #  		print("writefiles,set_file_name,path = $$file_name_ref\n");
    #  		my $file_name = $$file_name_ref;
    # 	if ($file_name ne $empty_string)  {
    #
    #		$writefiles->{_file_name}  = $file_name;
    # 		print("writefiles,set_file_name,path = $writefiles->{_file_name}\n");
    #
    # 	} else {
    # 		print("writefiles,set_file_name,missing file_name\n");
    # 	}
}

=head2 sub set_path

=cut

sub set_path {
    my ( $self, $path ) = @_;

    if ( $path ne $empty_string ) {

        $writefiles->{_path} = $path;
        print("writefiles,set_path,path = $writefiles->{_path} \n");

    }
    else {
        print("writefiles,set_path,missing path\n");
    }

}

1;

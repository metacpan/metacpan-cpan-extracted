package App::SeismicUnixGui::misc::program_name;

=head1 DOCUMENTATION

=head2 SYNOPSIS


 PROGRAM NAME:  program_name
 AUTHOR:  Juan Lorenzo

=head2 CHANGES and their DATES

 DATE:    July 2024
 Version  1.0.1 July 29 2016


=head2 DESCRIPTION

 handle program name exchanges between
 gui and internal representations
 
 For example for the user: fk
             for the program: Sudipfilt

=head2 REQUIRES 


=head2 Examples



=head2 STEPS



=head2 NOTES 

 We are using Moose.
 Moose already declares that you need debuggers turned on
 so you don't need a line like the following:
 use warnings;
 

=cut

use Moose;
our $VERSION = '0.0.1';

=head2 private hash control


=cut

my $program_name = {

	_in => '',

};

=head2 definitions copied from L_SU_global constants

=cut

my $superflow_internal_names_h = {
	_fk                => 'Sudipfilt',
	_Sudipfilt         => 'Sudipfilt',
	_ProjectVariables  => 'ProjectVariables',
	_iPick             => 'iPick',
	_SetProject        => 'SetProject',
	_iSpectralAnalysis => 'iSpectralAnalysis',
	_iVelAnalysis      => 'iVA',
	_iVA               => 'iVA',
	_iTopMute          => 'iTopMute',
	_iBottomMute       => 'iBottomMute',
	_Project           => 'Project',
	_Synseis           => 'Synseis',
	_Sseg2su           => 'Sseg2su',
	_Sucat             => 'Sucat',
	_immodpg           => 'immodpg',
	_BackupProject     => 'BackupProject',
	_ProjectBackup     => 'BackupProject',
	_ProjectRestore    => 'RestoreProject',
	_RestoreProject    => 'RestoreProject',
	_temp              => 'temp',                # make last
};

=head2

 as shown in gui

=cut

my @superflow_names_gui;

$superflow_names_gui[0]  = 'Project';
$superflow_names_gui[1]  = 'Sseg2su';
$superflow_names_gui[2]  = 'Sucat';
$superflow_names_gui[3]  = 'iSpectralAnalysis';
$superflow_names_gui[4]  = 'iVelAnalysis';
$superflow_names_gui[5]  = 'iTopMute';
$superflow_names_gui[6]  = 'iBottomMute';
$superflow_names_gui[7]  = 'fk';
$superflow_names_gui[8]  = 'Synseis';
$superflow_names_gui[9]  = 'iPick';
$superflow_names_gui[10] = 'immodpg';
$superflow_names_gui[11] = 'Project_Backup';
$superflow_names_gui[12] = 'Project_Restore';
$superflow_names_gui[13] = 'temp';                # make last

my $num_superflow_names_gui = scalar @superflow_names_gui;

my $developer_Tools_categories_h ={
	_Project            => '.',
	_Sseg2su   			=> 'big_streams',
	_SetProject         => '.',
	_Sucat     			=> 'big_streams',
	_iSpectralAnalysis  => 'big_streams',
	_iVelAnalysis       => 'big_streams',
	_iVA                => 'big_streams',
	_iTopMute        	=> 'big_streams',
	_iBottomMute  	    => 'big_streams',
	_Sudipfilt          => 'big_streams',
	_fk                 => 'big_streams',
	_Synseis            => 'big_streams',
	_iPick              => 'big_streams',
	_immodpg            => 'big_streams',
	_ProjectBackup      => 'big_streams',
	_BackupProject      => 'big_streams',
	_ProjectRestore     => 'big_streams',
	_RestoreProject     => 'big_streams',	
	_temp               => 'temp',                # make last
	
};

=head2 sub _internal

=cut

sub _internal {
	my ($external_name) = @_;

	my $result;

	if ( length $external_name ) {

		# remove any underscores
		$external_name =~ s/_/\ /;
		
		# remove any spaces
        $external_name =~ s/\ //;
        
#        print("corrected external name = $external_name\n");
        
        # look for corresponding internal version of this shorter name
        $external_name      = '_' . $external_name;
        my $internal_name   = $superflow_internal_names_h->{$external_name};
        $result             = $internal_name;
        
	}
	else {
		print("program_name, _internal,missing value\n");
		$result = ();

	}

	return ($result);
}

=head2 sub set

=cut

sub set {
	my ( $self, $name ) = @_;
	
	if ( length $name ) {

		$program_name->{_in} = $name;

	}
	else {
		print("program_name, set, missing value\n");
	}
}

=head2 sub get

=cut

sub get {
	my ($self) = @_;

	my $result;

	if ( length $program_name->{_in} ) {

		my $out = _internal( $program_name->{_in} );

		$program_name->{_out} = $out;
		$result = $out;

	}
	else {
		print("program_name, get,missing value\n");
		$result = ();

	}
}
	
=head2 sub category

=cut

sub category{
	my ($self) = @_;

	my $result;

	if ( length $program_name->{_in} ) {
		
		my $external_name = $program_name->{_in};
		
		# remove any underscores
		$external_name =~ s/_/\ /;
		
		# remove any spaces
        $external_name =~ s/\ //;
        
        # look for corresponding internal version of this shorter name
        my $key               = '_' . $external_name;
        my $category          = $developer_Tools_categories_h->{$key};
        $result               = $category;
#	    print("1. program_name, program_category $external_name(corrected) is $result\n");

	}
	else {
		print("program_name, get,missing value\n");
		$result = ();

	}

	return ($result);
}
1;

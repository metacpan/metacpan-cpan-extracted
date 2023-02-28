package App::SeismicUnixGui::developer::code::sunix::sunix_package_declaration;
use Moose;
our $VERSION = '0.0.1';

my @lines;

=head2 declaration variables

=cut

my $sunix_package_declaration = {
	_package_name    => '',
	_subroutine_name => '',
	_param_names     => '',
};

=head2 sub make_section 

 print("sunix_package_declaration,get_section,@lines\n");
	    "\t".'my $get					= L_SU_global_constants->new();'."\n\n".
=cut

sub make_section {

	my ($self) = @_;

	$lines[0] =
	  'my $get' . "\t\t\t\t\t" . '= L_SU_global_constants->new();' . "\n";
	$lines[1] = 'my $Project' . "\t\t\t\t" . '= Project_config->new();' . "\n";
	$lines[2] =
	  'my $DATA_SEISMIC_SU' . "\t\t" . '= $Project->DATA_SEISMIC_SU();' . "\n";
	$lines[3] =
	  'my $DATA_SEISMIC_BIN' . "\t" . '= $Project->DATA_SEISMIC_BIN();' . "\n";
	$lines[4] = 'my $DATA_SEISMIC_TXT' . "\t"
	  . '= $Project->DATA_SEISMIC_TXT();' . "\n\n";
	$lines[5] =
	  'my $PS_SEISMIC      ' . "\t" . '= $Project->PS_SEISMIC();' . "\n\n";
	$lines[6]  = 'my $var' . "\t\t\t\t" . '= $get->var();' . "\n";
	$lines[7]  = 'my $on' . "\t\t\t\t" . '= $var->{_on};' . "\n";
	$lines[8]  = 'my $off' . "\t\t\t\t" . '= $var->{_off};' . "\n";
	$lines[9]  = 'my $true' . "\t\t\t" . '= $var->{_true};' . "\n";
	$lines[10] = 'my $false' . "\t\t\t" . '= $var->{_false};' . "\n";
	$lines[11] = 'my $empty_string' . "\t" . '= $var->{_empty_string};' . "\n";

	return ( \@lines );
}

=head2 sub get_section 

 print("sunix_package_declaration,get_section,@lines\n");

=cut

sub get_section {
	my ($self) = @_;
	return ( \@lines );
}

1;

package App::SeismicUnixGui::sunix::header::header_values;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

 PROGRAM NAME: header_values 
AUTHOR: Juan Lorenzo (Perl module only)
 DATE:   Jan 14 2020
 DESCRIPTION: Extract segy header values
 Version: 0.0.1

=head2 USE

=head3 NOTES 

=head4 
 Examples


=head4 CHANGES and their DATES


=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use aliased 'App::SeismicUnixGui::misc::message';
use aliased 'App::SeismicUnixGui::misc::flow';
use aliased 'App::SeismicUnixGui::sunix::header::surange';

use App::SeismicUnixGui::misc::SeismicUnix
  qw($in $out $on $go $to $suffix_ascii $off $suffix_su $suffix_bin);

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};

=head2 Create prheader_valueste hash

=cut

my $header_values = {
	_key            => '',
	_base_file_name => '',
	_header_name    => '',
};

=head2 sub clear

=cut

sub clear {

	$header_values->{_key}            = '';
	$header_values->{_base_file_name} = '';
	$header_values->{_header_name}    = '';
}

=head2 sub set_base_file_name

=cut

sub set_base_file_name {

	my ( $self, $base_file_name ) = @_;

	if ( $base_file_name ne $empty_string ) {

		$header_values->{_base_file_name} = $base_file_name;

	}
	else {

		print("header_values,set_base_file_name, missing base file name\n");
	}

	return ();

}

=head2 sub set_header_name

=cut

sub set_header_name {

	my ( $self, $header_name ) = @_;

	if ( $header_name ne $empty_string ) {

		$header_values->{_header_name} = $header_name;

	}
	else {

		print("header_values,set_header_name, missing header name\n");
	}

	return ();
}

=head2 sub get_number

=cut

sub get_number() {

	my ($self) = @_;

	if (   defined $header_values->{_base_file_name}
		&& $header_values->{_base_file_name} ne $empty_string
		&& defined $header_values->{_header_name}
		&& $header_values->{_header_name} ne $empty_string )
	{

=head2 Declare

	import and instantiate classes

=cut

		my $log     = message->new;
		my $run     = flow->new();
		my $surange = surange->new();

=head2 Declare

	local variables

=cut

		my (@flow);
		my (@items);
		my (@data_in);
		my (@surange);
		my $Project         = Project_config->new();
		my $DATA_SEISMIC_SU = $Project->DATA_SEISMIC_SU;

=head2 Set up

	data_in parameter values

=cut

		$data_in[1] =
			$DATA_SEISMIC_SU . '/'
		  . $header_values->{_base_file_name}
		  . $suffix_su;

=head2 Set up

	surange parameter values

=cut

		$surange->clear();
		$surange->key( quotemeta( $header_values->{_header_name} ) );
		$surange[1] = $surange->Step();

=head2 DEFINE FLOW(s) 

=cut

		@items = ( $surange[1], $in, $data_in[1], $go );

=head2 RUN FLOW(s) and Capture output (with backticks) from the system

=cut

		my @values = `@items`;

		#		print("get_number, header_values, @values \n");

=head2 LOG FLOW(s)

	to screen

=cut

		#		print("header_values,get_number,@items \n");

=head2 parse output to obtain header value

=cut 		

		my $result;
		my $number = $values[1];

		#		print("header_values, get_number,values[0]:$values[0]...\n");
		#		print("header_values, get_number,values[1]:$values[1]\n");
		my $length = scalar @values;

		#		print("header_values, get_number,length=$length\n");

		if ( defined $number ) {

			# print("header_values,get_number, values[1]:$values[1]\n");

			if (   $number eq 0
				or $number eq $empty_string )
			{
				if ( $header_values->{_header_name} eq 'scalel' ) {

					$result = 1;

				}
				elsif ( $header_values->{_header_name} ne 'scalel' ) {

					my $key = quotemeta( $header_values->{_header_name} );
					print("header_values, get_number, key = $key\n");
					$number =~ s/$key\s*//;
					chomp($number);

					$result = $number;
					print("1 header_values, get_number, result = $number\n");
					print(
"header_values, get_number, header_name = $header_values->{_header_name}\n"
					);

				}
				else {
					print("header_values, get_number, unknown parameter\n");
					$result = $empty_string;
				}

				# print("header_values, get_number, scale=$result... \n");
				return ($result);

			}

			#			$number != 0
			elsif ( $number ne $empty_string ) {

				if ( $header_values->{_header_name} eq 'scalel' ) {
					$number =~ s/scalel\s*//;
					chomp($number);

					print("scale:$number....\n");

					if ( $number > 0 ) {

						# 10, 100 stays as 10, 100
						$result = $number;

					  # print("header_values, get_number, scale=$result... \n");
						return ($result);

					}
					elsif ( ( $number < 0 ) ) {

						# -10, -100 becomes .1, .01
						$result = -1 / $number;

					  # print("header_values, get_number, scale=$result... \n");
						return ($result);

					}
					else {
						print("header_values, get_number, incorrect value \n");
						return ($empty_string);
					}

				}
				elsif ( $header_values->{_header_name} ne 'scalel' ) {

					my $key = quotemeta( $header_values->{_header_name} );

					#					print("header_values, get_number, key = $key\n");
					$number =~ s/$key\s*//;
					chomp($number);

					$result = $number;

				 #					print("2 header_values, get_number, result = $number\n");
				 #					print("header_values,get_number,header_name= $key\n");

				}
				else {
					print("header_values, get_number, unexpected\n");
					return ($empty_string);
				}

			}
			else {
				print("header_values, get_number, unexpected result\n");
				return ($empty_string);
			}

		}
		else {
			$result = 1;

			# print("header_values, get_number, data_scale = 1:1\n");
			return ($result);
		}
		return ($result);

	}
	else {
		print(
"header_values, get_number, missing base file name and/or header name\n"
		);
	}
}    # end sub get_number
1;

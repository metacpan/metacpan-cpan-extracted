package App::SeismicUnixGui::misc::count;

=head1 DOCUMENTATION

=head2 SYNOPSIS 

count

 PERL PROGRAM NAME: count.pm
 AUTHOR: 	Juan Lorenzo
 DATE: 		Feb. 2022

 DESCRIPTION 
     count occurrences of strings in a list

 BASED ON:

=cut

=head2 USE

=head3 NOTES



=head4 Examples

=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut 

=head2 Notes from bash
 
=cut

=head2 declare libraries

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use aliased 'App::SeismicUnixGui::misc::manage_files_by2';
use aliased 'App::SeismicUnixGui::configs::big_streams::Project_config';
use App::SeismicUnixGui::misc::SeismicUnix
  qw($cdp $gx $in $out $on $go $to $txt $suffix_ascii $off $offset $su $sx $suffix_su $suffix_txt $tracl);

=head2

instantiate modules

=cut

my $Project = Project_config->new();
my $get     = L_SU_global_constants->new();

=head2

define local variables

=cut

my $DATA_SEISMIC_TXT = $Project->DATA_SEISMIC_TXT();

my $var   = $get->var();
my $true  = $var->{_true};
my $false = $var->{_false};

=head2 define private hash
to share

=cut

my @array1;
my @array2;

my $count = {
	_column      => '',
	_file_name   => '',
	_suffix_type => '',
	_file_format => '',

	#	_aref4cc_pt3            => '',
	#	_aref4cc_pt4            => '',
	#	_aref4cc_pt5            => '',

};

=head2 sub clear
all memory

=cut

sub clear {
	my $self = @_;
	$count->{_column}      = '';
	$count->{_file_name}   = '';
	$count->{_suffix_type} = '';
	$count->{_file_format} = '';

	#	$count->{_aref4cc_pt3}            = '';
	#	$count->{_aref4cc_pt4}            = '';
}

=head2 sub set_column

=cut

sub set_column {
	my ( $self, $column ) = @_;

	if ( length $column ) {

		#		print(
		#"count, set_column, column = $column\n"
		#		);

		$count->{_column} = $column;
	}
	else {
		print("count, set_column, missing variable\n");
	}

	my $result;

	return ($result);

}

=head2 sub set_file_name_in

=cut

sub set_file_name_in {
	my ( $self, $file_name_in ) = @_;

	if ( length $file_name_in ) {

		#		print(
		#"count, set_file_name_in, file_name_in = $file_name_in\n"
		#		);

		$count->{_file_name_in} = $file_name_in;
	}
	else {
		print("count, set_file_name_in, missing variable\n");
	}

	my $result;

	return ($result);

}

=head2 sub set_file_format

geometry values

=cut

sub set_file_format {
	my ( $self, $file_format ) = @_;

	my $result;

	if ( length $file_format ) {

		$count->{_file_format} = $file_format;

	}
	else {
		print("count, set_file_format, missing file_format=$file_format\n");
	}

	return ($result);
}

=head2 sub set_suffix_type

geometry values

=cut

sub set_suffix_type {
	my ( $self, $suffix_type ) = @_;

	my $result;

	if ( length $suffix_type ) {

		$count->{_suffix_type} = $suffix_type;

	}
	else {
		print("count, set_suffix_type, missing suffix_type=$suffix_type\n");
	}

	return ($result);
}

=head2 sub get_histogram_aref 

count unique elements
output the element value and the number of
occurrences

=cut

sub get_histogram_aref {
	my ($self) = @_;

	my $result_aref =();

	if (    length $count->{_file_name_in}
		and length $count->{_suffix_type}
		and length $count->{_column} )
	{

		my %hash;
		my $inbound;

		my $name_in      = $count->{_file_name_in};
		my $file         = manage_files_by2->new();
		my $suffix_type  = $count->{_suffix_type};
		my $column       = $count->{_column};
		my $column_index = $column - 1;

		my @value;
		my @name;
		my @count;
		my $i = 0;

		if ( $suffix_type eq $txt ) {

			$inbound = $DATA_SEISMIC_TXT . '/' . $name_in . $suffix_txt;

		}
		else {
			print(
				"get_histogram_aref, count, suffix type is only for $txt\n"
			);
		}

		my $data_aref = $file->get_5cols_aref($inbound);

		my @data = @$data_aref;
		my $l    = scalar @data;
#		print("$l, @data\n");

		# Convert individual array into a hash,
		# for counting
		my $array_ref = $data[$column_index];
		my @array     = @{$array_ref};

		$hash{$_}++ for @array;

		# sort keys numerically

		#tested agains groupcount in Matlab JML Feb 2022
		foreach my $name ( sort { $a <=> $b } keys %hash ) {

#			print("cdp,fold pairs = $name,$hash{$name}\n");
			$name[$i]  = $name;
			$count[$i] = $hash{$name};
			$i++;

		}

		my @result = ( \@name, \@count );
		$result_aref = \@result;

	}
	else {
		print("count,  get_histogram_aref, missing value(s)\n");
	}

	return($result_aref);
}

1;

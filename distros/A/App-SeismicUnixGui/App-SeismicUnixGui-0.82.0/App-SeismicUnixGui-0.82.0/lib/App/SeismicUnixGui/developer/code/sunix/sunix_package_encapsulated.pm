package App::SeismicUnixGui::developer::code::sunix::sunix_package_encapsulated;
use Moose;
our $VERSION = '0.0.1';

	my @lines;

=head2 encapsulated variables

=cut

 my $sunix_package_encapsulated = {
		_package_name      => '',
		_subroutine_name   => '',
		_param_names   	    => '',
    };

=head2 sub set_param_names

[$i]
  

=cut

sub  set_param_names{
 	my ($self,$name_aref) = @_;
 	my ($first,$last,$i,$package_name);
 	
 	use App::SeismicUnixGui::misc::control '0.0.3';
use aliased 'App::SeismicUnixGui::misc::control';
 	
 	# my $control 	= control->new();
 	
 	# $control		->set_infection($name_aref); 	
	# $name_aref 	= $control->get_no_double_hyphen();

 	$sunix_package_encapsulated->{_param_names} = $name_aref;
	$package_name				= $sunix_package_encapsulated->{_package_name};
	my $length 					= scalar @$name_aref;
	@lines						= []; # clear all memory from prior lines
	# print("sunix_package_encapsulated,set_param_names,length:$length\n");	
 	$lines[0] 					= ("\n");
 	$lines[1] 					= ("my ").'$'.$package_name."\t\t\t".'= '."{\n";

 	for ($i=2, my $j=0; $j < $length ; $i++,$j++) {
  		$lines[$i] 		= "\t".'_'.@$name_aref[$j]."\t\t\t\t\t".'=> \'\','.("\n");
	}
	$lines[$i]	=	"\t".'_Step'."\t\t\t\t\t".'=> \'\','.("\n");
	$lines[++$i]	=	"\t".'_note'."\t\t\t\t\t".'=> \'\','.("\n\n");
	$lines[++$i] 	=  '};'.("\n");
    $lines[++$i] 		=  ("\n");
}


=head2 sub set_package_name

=cut

	sub set_package_name {
 		my ($self,$name_href) = @_;
 		$sunix_package_encapsulated->{_package_name} = $name_href;
 		# print("sunix_package_encapsulated,set_package_name,$sunix_package_encapsulated->{_package_name}\n");
 		return();
	}


=head2 sub set_package_name_href

=cut

	sub set_package_name_href {
 		my ($self,$name_href) = @_;
 		$sunix_package_encapsulated->{_package_name} = $name_href;
 		# print("sunix_package_encapsulated,set_package_name,$sunix_package_encapsulated->{_package_name}\n");
 		return();
	}


=head2 sub get_section 

 print("sunix_package_encapsulated,get_section,@lines\n");

=cut

	sub get_section {
 		my ($self) = @_;
 		# print("sunix_package_encapsulated,get_section, lines: @lines\n");
 		return (\@lines);
	}

1;

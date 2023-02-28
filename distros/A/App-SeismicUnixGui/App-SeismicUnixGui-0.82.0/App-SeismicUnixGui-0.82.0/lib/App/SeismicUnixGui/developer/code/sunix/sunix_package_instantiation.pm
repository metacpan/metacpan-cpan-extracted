package App::SeismicUnixGui::developer::code::sunix::sunix_package_instantiation;
use Moose;
our $VERSION = '0.0.1';

	my @lines;

=head2 encapsulated variables

=cut

 my $sunix_package_instantiation = {
		_package_name      => '',
		_subroutine_name   => '',
		_param_names   	    => '',
    };

=head2 sub make_section 

 print("sunix_package_use,get_section,@lines\n");

=cut

 sub make_section {
 	
	my ($self) = @_;
	
	    $lines[0] =
	    "\t".'my $get					= L_SU_global_constants->new();'."\n\n";
		
		return (\@lines);
 }

=head2 sub get_section 

 print("sunix_package_encapsulated,get_section,@lines\n");

=cut

	sub get_section {
 		my ($self) = @_;
 		return (\@lines);
	}

1;

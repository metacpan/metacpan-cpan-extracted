package App::SeismicUnixGui::developer::code::sunix::sunix_package_subroutine;
use Moose;
our $VERSION = '0.0.1';


=head2 encapsualted variables

=cut

 my $sunix_package_subroutine = {
		_package_name   => '',
    };

=head2 Default perl lines for  a subroutine 


=cut

 my @lines;

 $lines[0] = ("\n");



=head2 sub set_name


=cut

sub set_name {

 my ($self,$name_href) = @_;
 $sunix_package_subroutine->{_package_name} = $name_href;
 # print("1. sunix_package_subroutine,name $name_href\n");

}


=head2 sub set_package_name


=cut

sub set_package_name {

 my ($self,$name_href) = @_;
 $sunix_package_subroutine->{_package_name} = $name_href;
 # print("1. sunix_package_subroutine,package_name $name_href\n");

}

=head2 sub set_param_name_aref

  print("sunix_package_subroutine,name,@lines\n");

=cut

sub set_param_name_aref {
 my ($self,$name_aref) = @_;
 my ($first,$i,$package_name);

 $package_name = $sunix_package_subroutine->{_package_name};

  $first 	= 1;
  $i  		= $first;

  $lines[$i] 		= (" sub $$name_aref {\n\n");
  $lines[++$i]		=  "\t".'my ( $self,$'.$$name_aref.' )'.("\t\t").'= @_;'.("\n");
  $lines[++$i]		=  "\t".'if ( $'.$$name_aref.' ne $empty_string ) {'.("\n\n");
  $lines[++$i]		=  "\t\t".'$'.$package_name.'->{_'.$$name_aref.'}'.("\t\t").'= $'.$$name_aref.';'.("\n"); 
  $lines[++$i] 		=  "\t\t".'$'.$package_name.'->{_note}'.("\t\t").'= $'.$package_name.'->{_note}.'.'\' '. $$name_aref.'=\'.$'.$package_name.'->{_'.$$name_aref.'};'.("\n") ; 
  $lines[++$i] 		=  "\t\t".'$'.$package_name.'->{_Step}'.("\t\t").'= $'.$package_name.'->{_Step}.'.'\' '. $$name_aref.'=\'.$'.$package_name.'->{_'.$$name_aref.'};'.("\n\n"); 
  $lines[++$i] 		=  "\t".'} else { '."\n";
  $lines[++$i] 		=  "\t\t".'print("'.$package_name.', '.$$name_aref.', missing '.$$name_aref.',\n");'."\n"; 
  $lines[++$i] 		=  "\t".' }'."\n";
  $lines[++$i] 		=  ' }'."\n\n";
    	
  		# print("sunix_packge_subroutine, set_param_name_aref, lines= @lines \n");
  
  return();
}

=head2 sub section 

 print("sunix_package_subroutine,section,@lines\n");

=cut

sub section {
 my ($self) = @_;
 return (\@lines);
}

1;

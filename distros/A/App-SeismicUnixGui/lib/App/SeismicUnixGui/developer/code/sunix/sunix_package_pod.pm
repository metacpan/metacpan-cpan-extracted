package App::SeismicUnixGui::developer::code::sunix::sunix_package_pod;
use Moose;
our $VERSION = '0.0.1';

=head2 encapsualted variables

=cut

my $sunix_package_pod = {
	_package_name    => '',
	_subroutine_name => '',
	_sudoc           => '',
	_num_lines       => '',
	_local_variables => '',
};

=head2 sub get_clear

	Introducton to clear for 
  		my $size = scalar @h_lines;
  		print("sunix_package_pod,clear num_lines,$size\n");

=cut

sub get_clear {
	my ($self) = @_;
	my @h_lines;
	my $i = 0;

	$h_lines[$i] = ("\n=head2 sub clear\n\n");
	$h_lines[ ++$i ] = ("=cut\n\n");

	# print("sunix_package_pod,clear header\n @h_lines");
	return ( \@h_lines );
}


=head2 sub get_declare

=cut

sub get_declare {
	my ($self) = @_;
	my @h_lines;
	my $i = 0;

	$h_lines[$i] = ("\n\n=head2 declare variables\n\n");
	$h_lines[ ++$i ] = ("=cut\n");
	return ( \@h_lines );
}


=head2 sub get_encapsulated

	Introducton to encapsulated for 
  		print("sunix_package_pod,get_encapsulated num_lines,$size\n");

=cut

sub get_encapsulated {
	my ($self) = @_;
	my @h_lines;
	my $i = 0;

	$h_lines[$i] = ("\n=head2 Encapsulated\n");
	$h_lines[ ++$i ] = ("hash of private variables\n\n");
	$h_lines[ ++$i ] = ("=cut\n");

	# print("sunix_package_pod,get_encapsulated header\n @h_lines");
	return ( \@h_lines );
}

=head2 sub get_instantiation

=cut

sub get_instantiation {
	my ($self) = @_;
	my @h_lines;
	my $i = 0;

	$h_lines[$i] = ("\n=head2 instantiation of packages\n\n");
	$h_lines[ ++$i ] = ("=cut\n\n");
	return ( \@h_lines );
}

=head2 sub get_use

=cut

sub get_use {
	my ($self) = @_;
	my @h_lines;
	my $i = 0;

	$h_lines[$i] = ("\n=head2 Import packages\n\n");
	$h_lines[ ++$i ] = ("=cut\n\n");
	return ( \@h_lines );
}

=head2 sub get_verbose

	Introducton to verbose for 
  		my $size = scalar @h_lines;
  		print("sunix_package_pod,verbose num_lines,$size\n");

=cut

sub get_verbose {
	my ($self) = @_;
	my @h_lines;
	my $i = 0;

	$h_lines[$i] = ("\n=head2 sub verbose\n\n");
	$h_lines[ ++$i ] = ("=cut\n");

	# print("sunix_package_pod,verbose header\n @h_lines");
	return ( \@h_lines );
}

=head2 sub get_V

	Introducton to V for 
  		my $size = scalar @h_lines;
  		print("sunix_package_pod,V num_lines,$size\n");

=cut

sub get_V {
	my ($self) = @_;
	my @h_lines;
	my $i = 0;

	$h_lines[$i] = ("\n=head2 sub V\n\n");
	$h_lines[ ++$i ] = ("=cut\n");

	# print("sunix_package_pod,V header\n @h_lines");
	return ( \@h_lines );
}

=head2 Default perl lines for  a subroutine 


=cut

my @lines;

$lines[0] = ("\n");

=head2 sub sudoc 

 	Complete sunix documentation

=cut

sub sudoc {

	my ( $self, $aref ) = @_;
	$sunix_package_pod->{_sudoc} = $aref;

	#print("package_pod,sudoc,whole @{$sunix_package_pod->{_sudoc}} \n");
	#$sunix_package_pod->{_num_lines} 	= scalar (@{$aref});

}

=head2 sub header

	Introductory header for each package

=cut

sub header {
	my ( $self, $name_aref ) = @_;
	my ( $first, $last, $i, $name );
	my @h_lines;
	$sunix_package_pod->{_package_name} = $name_aref;
	$name                               = @{ $sunix_package_pod->{_package_name} }[0];
	$first                              = 0;
	$i                                  = $first;
	my $length = scalar @{ $sunix_package_pod->{_package_name} };

	$h_lines[$i]     = ("\n\n=head1 DOCUMENTATION\n\n");
	$h_lines[ ++$i ] = ("=head2 SYNOPSIS\n\n");
	$h_lines[ ++$i ] = ("PACKAGE NAME: $name\n");
	$h_lines[ ++$i ] = ("AUTHOR: Juan Lorenzo\n");
	$h_lines[ ++$i ] = ("DATE:   \n");
	$h_lines[ ++$i ] = ("DESCRIPTION:\n");
	$h_lines[ ++$i ] = ("Version: \n\n");
	$h_lines[ ++$i ] = ("=head2 USE\n\n");
	$h_lines[ ++$i ] = ("=head3 NOTES\n\n");
	$h_lines[ ++$i ] = ("=head4 Examples\n\n");
	$h_lines[ ++$i ] = ("=head3 SEISMIC UNIX NOTES\n\n");

	#	print(" start is $i\n");
	my $start = $i;
	for ( my $j = 0; $j < ($length); $j++ ) {

		#	print(" i is $i\n");
		# 	print("no. lines =  $length\n");
		#	print (" @{$sunix_package_pod->{_package_name}} \n");

		$h_lines[ ++$i ] = ("@{$sunix_package_pod->{_package_name}}[$j]\n");

	}
	$h_lines[ ++$i ] = ("=head2 CHANGES and their DATES\n\n");
	$h_lines[ ++$i ] = ("=cut\n");
	my $size = scalar @h_lines;

	# print("sunix_package_pod,num_lines,$size\n");
	# print("sunix_package_pod,header\n @h_lines");

	return ( \@h_lines );
}

=head2 sub subroutine_name

  print("package_pod,name,@lines\n");

=cut

sub subroutine_name {
	my ( $self, $name_aref ) = @_;
	my ( $first, $last, $i, $sub_name );

	$sunix_package_pod->{_subroutine_name} = $$name_aref;

	$first = 1;
	$i     = $first;

	$lines[$i]     = ("=head2 sub $$name_aref \n");
	$lines[ ++$i ] = ("\n");
	$lines[ ++$i ] = ("\n");
	$lines[ ++$i ] = ("=cut\n");
}

=head2 sub sunix_package_name

  print("sunix_package_pod,name,@lines\n");

=cut

sub sunix_package_name {
	my ( $self, $name_href ) = @_;
	$sunix_package_pod->{_package_name} = $name_href;
	return ();
}

=head2 sub section 

 print("sunix_package_pod,section,@lines\n");

=cut

sub section {
	my ($self) = @_;
	return ( \@lines );
}

1;

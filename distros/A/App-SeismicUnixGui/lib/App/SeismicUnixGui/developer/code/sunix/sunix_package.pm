package App::SeismicUnixGui::developer::code::sunix::sunix_package;
use Moose;
our $VERSION = '0.0.1';


=head2 declare modules

=cut

use aliased 'App::SeismicUnixGui::developer::code::sunix::sunix_package_header';
use aliased
  'App::SeismicUnixGui::developer::code::sunix::sunix_package_pod_header';

#		use App::SeismicUnixGui::developer::code::sunix::sunix_package_instantiation';
use aliased
  'App::SeismicUnixGui::developer::code::sunix::sunix_package_declaration';
use aliased 'App::SeismicUnixGui::developer::code::sunix::sunix_package_pod';
use aliased
  'App::SeismicUnixGui::developer::code::sunix::sunix_package_encapsulated';
use aliased
  'App::SeismicUnixGui::developer::code::sunix::sunix_package_subroutine';
use aliased 'App::SeismicUnixGui::developer::code::sunix::sunix_package_use';
use aliased 'App::SeismicUnixGui::developer::code::sunix::sunix_package_Step';
use aliased 'App::SeismicUnixGui::developer::code::sunix::sunix_package_note';
use aliased 'App::SeismicUnixGui::developer::code::sunix::sunix_package_clear';
use aliased 'App::SeismicUnixGui::developer::code::sunix::sunix_package_tail';
use aliased 'App::SeismicUnixGui::developer::code::sunix::sunix_spec';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';


=head2 Instantiate modules

=cut

my $L_SU_global_constants = L_SU_global_constants->new();

=head2 Extract values from
modules

=cut
my $var               = $L_SU_global_constants->var();
my $format            =  $var->{_config_file_format};


=head2 initialize shared anonymous hash 

  key/value pairs

=cut

my $sunix_package = {
	_config_file_out    => '',
	_spec_file_out      => '',
	_file_in            => '',
	_file_out           => '',
	_length             => '',
	_package_name       => '',
	_num_lines          => '',
	_path_out4configs   => '',
	_path_out4developer => '',
	_path_out4specs     => '',
	_path_out4sunix     => '',
	_sudoc              => '',
	_outbound_pm        => '',
};

=head2 sub get_file_out

  		 
=cut

sub get_file_out {
	my ($self) = @_;
	my $file_out = $sunix_package->{_file_out};

	# print("1. sunix_package,get_file_out is $sunix_package->{_file_out}\n");
	return ($file_out);
}

=head2 sub set_config_file_out

print("sunix_package,config_file_out,_config_file_out:  $sunix_package->{_config_file_out}\n");

=cut

sub set_config_file_out {
	my ( $self, $file_aref ) = @_;
	$sunix_package->{_config_file_out} = @$file_aref[0];
}

=head2 sub set_file_in

print("file_in is $sunix_package->{_file_in}\n");

=cut

sub set_file_in {
	my ( $self, $file_aref ) = @_;
	$sunix_package->{_file_in} = @$file_aref[0];
}

=head2 sub set_file_out

print("1. sunix_package,file_out is $sunix_package->{_file_out}\n");

=cut

sub set_file_out {
	my ( $self, $file_aref ) = @_;
	$sunix_package->{_file_out} = @$file_aref[0];
}

=head2 sub set_package_name



=cut

sub set_package_name {
	my ( $self, $file_aref ) = @_;

	if ($file_aref) {

		$sunix_package->{_package_name} = @$file_aref[0];
		print(
"sunix_package, set_package_name is $sunix_package->{_package_name}\n"
		);
	}
	else {
		print("sunix_package,set_package name, missing package name\n");
	}

}

=head2 sub set_path_out4configs

  
=cut

sub set_path_out4configs {
	my ( $self, $file_aref ) = @_;

	$sunix_package->{_path_out4configs} = @$file_aref[0];

	print(
"sunix_package,set_path_out4configs,path_out is $sunix_package->{_path_out4configs}\n"
	);
}

=head2 sub set_path_out4developer

  
=cut

sub set_path_out4developer {
	my ( $self, $file_aref ) = @_;

	$sunix_package->{_path_out4developer} = @$file_aref[0];

#	print("sunix_package,set_path_out4developer,path_out is $sunix_package->{_path_out4developer}\n");
}

=head2 sub set_path_out4specs

  
=cut

sub set_path_out4specs {
	my ( $self, $file_aref ) = @_;

	$sunix_package->{_path_out4specs} = @$file_aref[0];

#	print(
#"sunix_package,set_path_out4specs,path_out is $sunix_package->{_path_out4specs}\n"
#	);
}

=head2 sub set_path_out4sunix

  
=cut

sub set_path_out4sunix {
	my ( $self, $file_aref ) = @_;

	$sunix_package->{_path_out4sunix} = @$file_aref[0];

	print(
"sunix_package,set_path_out4sunix,path_out is $sunix_package->{_path_out4sunix}\n"
	);
}

=head2 sub set_param_names


=cut

sub set_param_names {

	my ( $self, $names_aref ) = @_;

	if ($names_aref) {

		$sunix_package->{_param_names} = $names_aref;
		$sunix_package->{_length} = scalar @{ $sunix_package->{_param_names} };

  #  	print("sunix_package,set_param_names,names: @{$names_aref}\n");
  #  print("sunix_package,set_param_names,length:$sunix_package->{_length} \n");

	}
	else {
		print("sunix_package,set_param_names,param_names are missing\n");
	}

}

=head2 sub set_param_values

  				 print("sunix_package,param_values @{$sunix_package->{_param_values}}\n");

=cut

sub set_param_values {

	my ( $self, $values_aref ) = @_;

	if ($values_aref) {

		$sunix_package->{_param_values} = $values_aref;
		$sunix_package->{_length}       = scalar @$values_aref;

 #  	print("sunix_package,set_param_values,values: @{$values_aref}\n");
 # 	print("sunix_package,set_param_values,length:$sunix_package->{_length} \n");

	}
	else {
		print("sunix_package,set_param_values,param_values are missing\n");
	}
}

=head2 sub set_spec_file_out



=cut

sub set_spec_file_out {
	my ( $self, $file_aref ) = @_;
	$sunix_package->{_spec_file_out} = @$file_aref[0];

#print("sunix_package,set_spec_file_out,_spec_file_out:  $sunix_package->{_spec_file_out}\n");
}

=head2 sub set_sudoc_aref

  print("sunix_package,sudoc @{$sunix_package->{_sudoc_aref}}\n");

=cut

sub set_sudoc_aref {
	my ( $self, $sudoc_aref ) = @_;

	if ($sudoc_aref) {

		$sunix_package->{_sudoc_aref} = $sudoc_aref;

		#  	 my $length = scalar @$sudoc_aref;
		#	  for (my $i=0; $i < $length; $i++) {
		#
		#		 	  print ("@{$sudoc_aref}[$i]\n");
		#
		#	  }
		$sunix_package->{_num_lines} = scalar @$sudoc_aref;

	}
	else {
		print("sunix_package,missing set_sudoc_aref\n");
	}

}

=pod sub write_config 

 open and write configuration 
 file

=cut

sub write_config {
	my ($self) = shift;

	if ( $sunix_package->{_config_file_out} && $sunix_package->{_length} )
	{    # avoids errors

		my $OUT;
		my $outbound = $sunix_package->{_path_out4configs} . '/'
		  . $sunix_package->{_config_file_out};

		# print ("sunix_package,write_config $outbound\n");
		print("sunix_package,write_config length=$sunix_package->{_length}\n");
		my $i;
		open $OUT, '>', $outbound or die;
		for ( $i = 0 ; $i < ( $sunix_package->{_length} - 1 ) ; $i++ ) {
			printf $OUT
			  $format."\n",
			  @{ $sunix_package->{_param_names} }[$i], '= ',
			  @{ $sunix_package->{_param_values} }[$i];
		}

# make last line not include a "return" which produces an annoying final empty line
# in the configuration file
#		print("sunix_package,write_config length, last line=$i\n");
		printf $OUT
		  $format,
		  @{ $sunix_package->{_param_names} }[$i], '= ',
		  @{ $sunix_package->{_param_values} }[$i];
		close($OUT);
	}
}

=pod sub write_pm 

 open  and write 
 to the package

=cut

sub write_pm {
	my ($self) = shift;

	print(
"sunix_package, write_pm: sunix_package->{_file_out}= $sunix_package->{_file_out}\n"
	);
	print(
"sunix_package, write_pm: sunix_package->{_length}= $sunix_package->{_length}\n"
	);

	if ( $sunix_package->{_file_out} && $sunix_package->{_length} >= 0 )
	{    # avoids errors

		my $name = $sunix_package->{_package_name};
		my $OUT;

		my $header      = sunix_package_header->new();
		my $pod_header  = sunix_package_pod_header->new();
		my $declaration = sunix_package_declaration->new();

		# TODO following 2 are both instantiations
		my $encapsulated = sunix_package_encapsulated->new();

		#		my $instantiation = sunix_package_instantiation->new();
		my $pod        = sunix_package_pod->new();
		my $use        = sunix_package_use->new();
		my $Step       = sunix_package_Step->new();
		my $note       = sunix_package_note->new();
		my $clear      = sunix_package_clear->new();
		my $subroutine = sunix_package_subroutine->new();
		my $tail       = sunix_package_tail->new();

		# set up header
		$header->set_package_name($name);
		$use->make_section();

		# $instantiation					->set_package_name($name);
		# $instantiation->make_section();

		# set up pod_header
		$pod_header->set_prog_docs_aref( $sunix_package->{_sudoc_aref} );
		$pod_header->set_header();

		#$declaration					->set_package_name($name);
		$declaration->make_section();

		# set up encapsulated
		$encapsulated->set_package_name($name);
		$encapsulated->set_param_names( $sunix_package->{_param_names} );

		# set up Step
		$Step->set_package_name($name);
		$Step->set_sub_Step();

		# set up note
		$note->set_package_name($name);
		$note->set_sub_note();

		# set up clear
		$clear->set_package_name($name);
		$clear->set_param_names( $sunix_package->{_param_names} );

		# set up pod
		# $pod->sunix_package_name($name);
		# $pod->sudoc( $sunix_package->{_sudoc_aref} );

		# set up subroutine package_name
		$subroutine->set_name($name);

		# HERE starts THE output PRODUCT!
		$sunix_package->{_outbound_pm} =
		  $sunix_package->{_path_out4sunix} . '/' . $sunix_package->{_file_out};
		print(
			"sunix_package,write_pm, outbound=$sunix_package->{_outbound_pm}\n"
		);
		open $OUT, '>', $sunix_package->{_outbound_pm} or die;

		# prints out to file: package name
		print $OUT @{ $header->get_package_name_section() };

		# prints out to file: Sunix documentation
		print $OUT @{ $pod_header->get_section() };

# print @{ $pod_header->get_section() };
# # print $OUT @{ $pod->header( $sunix_package->{_sudoc_aref} ) };
# # print ("sunix_package, write_pm, su documentation: @{$sunix_package->{_sudoc_aref}}[0]\n");

		# prints out to file: call to Moose
		print $OUT @{ $header->get_Moose_section() };

		# prints out to file: Version
		print $OUT @{ $header->get_version_section() };

		# prints out 'use...' (import packages)
		print $OUT @{ $pod->get_use };
		print $OUT @{ $use->get_section };

		# print @{ $pod->get_use };
		# print @{ $use->get_section };

		# # prints out instantiation of modules (="... new..")
		# # print $OUT @{ $instantiation->get_section };
		## print @{ $instantiation->get_section };

		# prints out declared variables  ("my ...")
		print $OUT @{ $pod->get_instantiation };
		print $OUT @{ $declaration->get_section };

		# print @{ $pod->get_instantiation };
		# print @{ $declaration->get_section };

		# prints out a private hash
		print $OUT @{ $pod->get_encapsulated() };
		print $OUT @{ $encapsulated->get_section() };

		# print @{ $pod->get_encapsulated() };
		# print @{ $encapsulated->get_section() };

		# prints out a private hash
		##		print $OUT @{ $pod->get_instantiation };
		##		print $OUT @{ $declaration->get_section() };

		# prints out Step subroutine and pod
		print $OUT @{ $Step->get_section() };

		# print @{ $Step->get_section() };

		# prints out note subroutine and pod
		print $OUT @{ $note->get_section() };

		# print @{ $note->get_section() };

		# prints out clear subroutine
		print $OUT @{ $pod->get_clear() };
		print $OUT @{ $clear->get_section() };

		# print @{ $pod->get_clear() };
		# print @{ $clear->get_section() };

		for ( my $i = 0 ; $i < $sunix_package->{_length} ; $i++ ) {

			$subroutine->set_param_name_aref(
				\@{ $sunix_package->{_param_names} }[$i] );
			$pod->subroutine_name( \@{ $sunix_package->{_param_names} }[$i] );

			print $OUT @{ $pod->section };
			print $OUT @{ $subroutine->section };

			# print @{ $pod->section };
			# print @{ $subroutine->section };
		}

		# prints out  sub get_max_index and '1;'
		print $OUT @{ $tail->section };

		# print @{ $tail->section };

		# print ("sunix_package outbound $sunix_package->{_outbound_pm}\n");;
		close($OUT);

	}
	else {
		print(
"sunix_package,write_pm, missing:  sunix_package->{_file_out} and sunix_package->{_length}\n"
		);
	}

}

=pod sub write_spec

 open and write specification file 
 file
 
 TODO

=cut

sub write_spec {
	my ($self)     = shift;
	
	my $sunix_spec = sunix_spec->new();
	
	$sunix_spec->set_path_out4specs($sunix_package->{_path_out4specs});
	
	my $name       = $sunix_package->{_package_name};
	$sunix_spec->set_package_name($name);
	my $header = $sunix_spec->get_header_section();
	my $body   = $sunix_spec->get_body_section();
	my $subs   = $sunix_spec->get_subroutine_section();
	my $tail   = $sunix_spec->get_tail_section();

	if ( $sunix_package->{_spec_file_out} ) {    # avoids errors

		my $outbound_spec = $sunix_package->{_path_out4specs} . '/'
		  . $sunix_package->{_spec_file_out};

#		print ("sunix_package,write_spec outbound_spec= $outbound_spec \n");
#		print ("sunix_package,write_spec, header=\n @{$header}\n");
		# print ("sunix_package,write_spec, body=\n @{$body}\n");
		
		open( my $OUT, '>', $outbound_spec )
		  or die "Could not open file '$outbound_spec' $!";

		my @header = @{$header};
		for (my $j=0; $j < scalar @header; $j++ ){		
			print $OUT ("$header[$j]");
		}

		print $OUT @{ $sunix_spec->get_body_section() };
		print $OUT @{ $sunix_spec->get_subroutine_section() };
		print $OUT @{$tail};
		close $OUT;
	}
}

1;

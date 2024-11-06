package App::SeismicUnixGui::developer::code::sunix::prog_doc2pm;

=head1 DOCUMENTATION

=head2 SYNOPSIS

PROGRAM NAME:  prog_doc2pm.pm						

 AUTHOR: Juan Lorenzo
 DATE:   Nov 14 2018 
 DESCRIPTION: 
 			package of to access programs
 			for which a module is to be made
 
 Version: 1.0.0

=head2 USE

=head3 NOTES

=head4 Examples
my $selected_program_name = 'sugetgthr';
=head3 SEISMIC UNIX NOTES

=head2 CHANGES and their DATES

=cut

use Moose;
our $VERSION = '0.0.1';
use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
use Cwd;

my $get = L_SU_global_constants->new();

my $var          = $get->var();
my $empty_string = $var->{_empty_string};
my $global_libs  = $get->global_libs();
my $SeismicUnixGui = $var->{_SeismicUnixGui};

my $developer_sunix_categories_aref = $get->developer_sunix_categories_aref();
my @developer_sunix_categories      = @$developer_sunix_categories_aref;

my $prog_doc2pm = {
	_list_length     => '',
	_list_names_aref => '',
	_group_directory => '',
	_path            => '',
};

=head2 declaration of local variables

=cut

my ( @file_in, @pm_file_out, @package_name, @program_name );
my (@config_file_out);
my ( @spec_file_out, $group_no );
my ( @inbound, @path_out, $path );

=head2 sub _get_list_aref 
List of file names from within a directory
	
=cut

sub _get_list_aref {

	my ($self) = @_;

	if ( $prog_doc2pm->{_group_directory} ne $empty_string ) {

		my $list_aref;
		my $path_in   = _get_path_in();
		my $directory = $prog_doc2pm->{_group_directory};
		$prog_doc2pm->{_path} = $path_in . '/Stripped/' . $directory;
		my $path = $prog_doc2pm->{_path};

		# print("prog_doc2pm,_get_list_aref, PATH:$prog_doc2pm->{_path}\n");

		opendir my $dh, $path or die "Could not open '$path' for reading: $!\n";

		my @file_name;
		my $thing;
		my @name;

		while ( defined( $thing = readdir $dh ) ) {

			$thing =~ s/\///;

			#			print("prog_doc2pm,count=$count; file_name=$thing\___\n");

			if ( not( $thing =~ /^\.\.?$/ ) ) {

				(@name) = split( /\./, $thing );
				push @file_name, $name[0];

				#				print("prog_doc2pm,file_name=$name[0]\___\n");

			} else {    # skip . and ..

				#				print("prog_doc2pm, skipping\___\n");
			}

			$list_aref = \@file_name;
		}
		closedir $dh;

		# print("prog_doc2pm,_get_list_aref,file_names=@file_name\n");
		return ($list_aref);

	} else {
		print("prog_doc2pm, _get_list_aref, missing group no,\n");
		return ();
	}

}

=head2 sub _get_path_in


=cut

sub _get_path_in {

	my ($self) = @_;

	if ( $prog_doc2pm->{_group_directory} ne $empty_string ) {

		my $local_dir= getcwd();
        my $up3dir = '/../../../';
		my $path_in = $local_dir.$up3dir.'developer';

#		print("prog_doc2pm,_get_path_in = $path_in\n");
		return ($path_in);

	} else {
		print("prog_doc2pm, _get_path_in, missing directory,\n");
		return ();
	}
}

=head2 sub get_group_directory 


=cut

sub get_group_directory {

	my ($self) = @_;

	if ( $prog_doc2pm->{_group_directory} ne $empty_string ) {

		$prog_doc2pm->{_group_directory} = $developer_sunix_categories[$group_no];

		#print("prog_doc2pm, get_group_directory,$prog_doc2pm->{_group_directory}\n");

	} else {
		print("prog_doc2pm, get_group_directory, missing group no,\n");
	}
}

=head2 sub get_list_aref 


=cut

sub get_list_aref {

	my ($self) = @_;

	if ( $prog_doc2pm->{_group_directory} ne $empty_string ) {

		my $list_aref;
		my $path_in = _get_path_in();

		my $directory = $prog_doc2pm->{_group_directory};
		$prog_doc2pm->{_path} = $path_in . '/Stripped/' . $directory;
		my $path = $prog_doc2pm->{_path};

		# print("prog_doc2pm,get_list_aref, PATH:$prog_doc2pm->{_path}\n");

		opendir my $dh, $path or die "Could not open '$path' for reading: $!\n";

		my @file_name;
		my @name;
		my $thing;

		while ( defined( $thing = readdir $dh ) ) {

			$thing =~ s/\///;

			if ( not( $thing =~ /^\.\.?$/ ) ) {

				push @file_name, $thing;

				#				print("prog_doc2pm,ile_name=$thing\___\n");

			} else {    # skip . and ..

				#				print("prog_doc2pm, skipping\___\n");
			}
			$list_aref = \@file_name;
		}
		closedir $dh;

		# print("prog_doc2pm,get_list_aref,file_names=@file_name\n");
		return ($list_aref);

	} else {
		print("prog_doc2pm, get_list_aref, missing group no,\n");
		return ();
	}
}

=head2 sub get_list_length 

=cut

sub get_list_length {

	my ($self) = @_;

	if ( $prog_doc2pm->{_group_directory} ne $empty_string ) {

		my $length = ( scalar @{ _get_list_aref() } );

		#		print("prog_doc2pm,get_list_length,length= $length \n");
		return ($length);

	} else {
		print("prog_doc2pm, get_list_length, missing group no,\n");
		return ();
	}
}

=head2 sub get_path_in


=cut

sub get_path_in {

	my ($self) = @_;

	if ( $prog_doc2pm->{_group_directory} ne $empty_string ) {

		my $dir = $prog_doc2pm->{_group_directory};

		my $local_dir= getcwd();
        my $up3dir = '/../../../';
		my $path_in = $local_dir.$up3dir.'developer/Stripped'. '/' . $dir;

#		print("prog_doc2pm,get_path_in = $path_in\n");
		return ($path_in);

	} else {
		print("prog_doc2pm, get_,path_in missing directory,\n");
		return ();
	}
}

=head2 sub get_path_out4configs


=cut

sub get_path_out4configs {

	my ($self) = @_;

	if ( $prog_doc2pm->{_group_directory} ne $empty_string ) {

		my $dir = $prog_doc2pm->{_group_directory};

		my $PATH_OUT = $global_libs->{_configs} . '/' . $dir;

#		print("prog_doc2pm,get_path_out4configs = $PATH_OUT\n");
		return ($PATH_OUT);

	} else {
		print("prog_doc2pm, get_path_out4configs missing directory,\n");
		return ();
	}
}

=head2 sub get_path_out


=cut

sub get_path_out4developer {

	my ($self) = @_;

	if ( $prog_doc2pm->{_group_directory} ne $empty_string ) {

		my $dir = $prog_doc2pm->{_group_directory};

		my $PATH_OUT = $global_libs->{_developer} . '/' . $dir;

		# print("prog_doc2pm,get_path_out4developer = $PATH_OUT\n");
		return ($PATH_OUT);

	} else {
		print("prog_doc2pm, get_,path_out missing directory,\n");
		return ();
	}
}

=head2 sub get_path_out4global_constants


=cut

sub get_path_out4global_constants {

	my ($self) = @_;

	if ( $prog_doc2pm->{_group_directory} ne $empty_string ) {

		# my $path 	= '/usr/local/pl/L_SU/misc';

		my $PATH_OUT = $global_libs->{_misc};

#		print("prog_doc2pm, get_path_out4global_constants= $PATH_OUT\n");
		return ($PATH_OUT);

	} else {
		print("prog_doc2pm, get_path_out4global_constants missing directory,\n");
		return ();
	}

}

=head2 sub get_path_out4specs


=cut

sub get_path_out4specs {

	my ($self) = @_;

	if ( $prog_doc2pm->{_group_directory} ne $empty_string ) {

		# my $path 	= '/usr/local/pl/L_SU/specs';
		my $dir = $prog_doc2pm->{_group_directory};

		my $PATH_OUT = $global_libs->{_specs} . '/' . $dir;

		#		print("prog_doc2pm, get_path_out4specs= $PATH_OUT\n");
		return ($PATH_OUT);

	} else {
		print("prog_doc2pm, get_path_out4specs missing directory,\n");
		return ();
	}

}

=head2 sub get_path_out4sunix


=cut

sub get_path_out4sunix {

	my ($self) = @_;

	if ( $prog_doc2pm->{_group_directory} ne $empty_string ) {

		my $dir = $prog_doc2pm->{_group_directory};

		my $PATH_OUT = $global_libs->{_sunix} . '/' . $dir;

		print("prog_doc2pm,get_path_out4sunix = $PATH_OUT\n");
		return ($PATH_OUT);

	} else {
		print("prog_doc2pm, get_path_out4sunix missing directory,\n");
		return ();
	}
}

=head2 sub get_program_aref 

=cut

sub get_program_aref {

	my ($self) = @_;

	if ( $prog_doc2pm->{_group_directory} ne $empty_string ) {

		my $list_aref;
		my $path_in   = _get_path_in();
		my $directory = $prog_doc2pm->{_group_directory};
		$prog_doc2pm->{_path} = $path_in . '/Stripped/' . $directory;
		my $path = $prog_doc2pm->{_path};

		#		print("prog_doc2pm,get_program_aref, PATH:$prog_doc2pm->{_path}\n");

		opendir my $dh, $path or die "Could not open '$path' for reading: $!\n";

		#		print("prog_doc2pm,_get_program_aref, DIR=$path\n");
		my @file_name;
		my $thing;
		my @name;

		while ( defined( $thing = readdir $dh ) ) {

			$thing =~ s/\///;

			if ( not( $thing =~ /^\.\.?$/ ) ) {

				(@name) = split( /\./, $thing );
				push @file_name, $name[0];

				#				print("prog_doc2pm,file_name=$name[0] \___\n");

			} else {    # skip . and ..

				#				print("prog_doc2pm, skipping $thing\n");
			}

			$list_aref = \@file_name;

		}    # end while
		closedir $dh;

		#		print("prog_doc2pm,get_program_aref,file_names=@file_name\n");
		return ($list_aref);

	} else {
		print("prog_doc2pm, get_program_aref, missing group no,\n");
		return ();
	}

}

=head2 sub set_group_directory 


=cut

sub set_group_directory {

	my ( $self, $group_no ) = @_;

	if ( $group_no ne $empty_string ) {

		$prog_doc2pm->{_group_directory} = $developer_sunix_categories[$group_no];

#		print("prog_doc2pm, set_group_directory,$prog_doc2pm->{_group_directory}\n");

	} else {
		print("prog_doc2pm, set_group_directory, missing group no,\n");
	}
}

1;

 package App::SeismicUnixGui::developer::code::sunix::sunix_spec;
 use Moose;
our $VERSION = '0.0.1';
 
 use aliased 'App::SeismicUnixGui::misc::L_SU_global_constants';
 use aliased 'App::SeismicUnixGui::misc::dirs';
 
 my $get 				= L_SU_global_constants->new();
 my $dirs               = dirs->new();
 my $flow_type			= $get->flow_type_href();

=head2 initialize shared anonymous hash 

  key/value pairs

=cut

 my $sunix_spec = {
  	  _config_file_out	=> '',
  	  _spec_file_out	=> '',
  	  _file_in			=> '',
  	  _file_out			=> '',
  	  _length			=> '',
  	  _package_name		=> '',
  	  _path_out4specs   => '', 
  	  _num_lines		=> '',
  	  _path_out			=> '',
  	  _sudoc			=> '',
  	  _outbound_pm		=> '',
    };

=head2  sub  _get_Moose_section

=cut

sub _get_Moose_section {
 	my ($self) = @_;
	my @head;
 	$head[0] = ("use Moose;\n");

 	
=head2 sub _get_declare_section


=cut

sub _get_declare_section {
	my ($self) = @_;
	my @declare;
	my $name = $sunix_spec->{_package_name}; 
		
	$declare[0] = "\n".'my $var                 = $get->var();'."\n\n".
					'my $empty_string        = $var->{_empty_string};'."\n".	
					'my $true                = $var->{_true};'."\n".
					'my $false               = $var->{_false};'."\n".
					'my $file_dialog_type    = $get->file_dialog_type_href();'."\n".
 					'my $flow_type           = $get->flow_type_href();'."\n";										
						
	return (\@declare);
	
}


=head2 sub _get_instantiation_section


=cut

sub _get_instantiation_section {
	my ($self) = @_;
	my @instantiate;
	my $package_name = $sunix_spec->{_package_name}; 
		
	$instantiate[0] = "\n".'use aliased \'App::SeismicUnixGui::configs::big_streams::Project_config\';'."\n".
		                'use App::SeismicUnixGui::misc::SeismicUnix qw($bin $ps $segy $su $suffix_bin $suffix_ps $suffix_segy $suffix_su $suffix_txt $txt);' . "\n".
						'use aliased \'App::SeismicUnixGui::misc::L_SU_global_constants\';'."\n".					
						"\n".					
						'my $get                 = L_SU_global_constants->new();'."\n".
						'my $Project             = Project_config->new();'."\n".
						"\n";
											
	return (\@instantiate);	
}


=head2 sub _get_package_section

 a small section of the file
 print ("sunix_package_header,section:name $name\n");

=cut

sub _get_package_section {
 	my ($self) = @_;
	my @head;
	my $name = $sunix_spec->{_package_name}; 
	my $path_out4specs =  $sunix_spec->{_path_out4specs};
	
	my $path4SeismicUnixGui = $dirs->get_path4SeismicUnixGui();
#	print("sunix_spec,_get_package_section,$path4SeismicUnixGui\n");
		
	$path_out4specs =~ s/$path4SeismicUnixGui//g;
	$path_out4specs =~ s/\//::/g;
	
	my $colon_path2module_spec = 'App::SeismicUnixGui' .$path_out4specs;

	if($name) {
		
		$head[0] = 'package '.$colon_path2module_spec.'::'.$name.'_spec;'."\n"; 
#		print("sunix_spec,_get_package_section,$head[0] \n");	
		
		return (\@head);
		
	} else {
		print ("sunix_spec, get_package_section, package name missing");
	}
}

return (\@head);
}


=head2  sub  _get_version_section

=cut

sub _get_version_section {
 	my ($self) = @_;
	my @head;
 	$head[0] = ("our \$VERSION = '0.0.1';\n");

 	return (\@head);
}


=head2  sub _sub_binding_index_aref

=cut

 sub _sub_binding_index_aref {
	my ($self) = @_;
	
	my @section;	
	my $package_name = $sunix_spec->{_package_name}; 
  
	$section[0] = '=head2  sub binding_index_aref'."\n\n".
	'=cut'."\n\n".
	' sub binding_index_aref {'."\n\n".
	"\t".'my $self 	= @_;'."\n\n".
	"\t".'my @index;'."\n\n".	
	"\t".'# first binding index (index=0)'."\n".
    "\t".'# connects to second item (index=1)'."\n".
    "\t".'# in the parameter list'."\n".
    "#\t".'$index[0] = 1; # inbound item is  bound '."\n".
	"#\t".'$index[1]	= 2; # inbound item is  bound'."\n".
	"#\t".'$index[2]	= 8; # outbound item is  bound'."\n\n".		
	"\t".'$'.$package_name.'_spec ->{_binding_index_aref} = \@index;'."\n".	
	"\t".'return();'."\n\n".
 	' }'."\n\n\n";
 
 	return(\@section);
		
 }
  
 
=head2  sub _sub_file_dialog_type_aref

=cut

 sub _sub_file_dialog_type_aref {
	my ($self) = @_;
	
	my @section;	
	my $package_name = $sunix_spec->{_package_name}; 
  
	$section[0] = '=head2  sub file_dialog_type_aref'."\n\n".
	'type of dialog (Data, Flow, SaveAs) is needed by binding'."\n".
	'one type of dialog for each index'."\n".
	'=cut'."\n\n".
	' sub file_dialog_type_aref {'."\n\n".
	"\t".'my $self 	= @_;'."\n\n".
	"\t".'my @type;'."\n\n".
	 "\t".'my $index_aref = get_binding_index_aref();'."\n".
	"\t".'my @index      = @$index_aref;'."\n\n".
	"\t".'# bound index will look for data'."\n".
	"\t".'$type[0]	= \'\';'."\n".
	"#\t".'$type[$index[0]] = $file_dialog_type->{_Data};'."\n".
	"#\t".'$type[$index[1]]	=  $file_dialog_type->{_Data};'."\n".
	"#\t".'$type[$index[2]]	=  $file_dialog_type->{_Data};'."\n\n".
	"\t".'$'.$package_name.'_spec ->{_file_dialog_type_aref} = \@type;'."\n".	
	"\t".'return();'."\n\n".
 	' }'."\n\n\n";
 
 	return(\@section);
		
 }  
 
 
=head2  sub _sub_flow_type_aref

=cut

 sub _sub_flow_type_aref {
	my ($self) = @_;
	
	my @section;	
	my $package_name = $sunix_spec->{_package_name}; 
  
	$section[0] = '=head2  sub flow_type_aref'."\n\n".
	'=cut'."\n\n".
	' sub flow_type_aref {'."\n\n".
	"\t".'my $self 	= @_;'."\n\n".
	"\t".'my @type;'."\n\n".	
	"\t".'$type[0]	= $flow_type->{_user_built};'."\n\n".
	"\t".'$'.$package_name.'_spec ->{_flow_type_aref} = \@type;'."\n".	
	"\t".'return();'."\n\n".
 	' }'."\n\n\n";
 
 	return(\@section);
		
 }


=head2  sub _sub_get_binding_length

=cut

 sub _sub_get_binding_length {
	my ($self) = @_;
	
	my @section;	
	my $package_name = $sunix_spec->{_package_name};
	
	$section[0] = '=head2 sub get_binding_length'."\n\n".
	'=cut'."\n\n".
	' sub get_binding_length{'."\n\n".
	"\t".'my $self 	= @_;'."\n\n".	
	"\t".'if ($'.$package_name.'_spec->{_binding_index_aref} ) {'."\n\n".
	"\t\t".'my $binding_length= scalar @{$'.$package_name.'_spec->{_binding_index_aref}};'."\n".
	"\t\t".'return($binding_length);'."\n\n".		
	"\t".'} else {'."\n".
	"\t\t".'print("'.$package_name.'_spec, get_binding_length, missing binding_length\n");'."\n".
	"\t\t".'return();'."\n".
	"\t".'}'."\n\n".
	"\t".'return();'."\n".
 	' }'."\n\n\n";
 
 	return(\@section);
		
 }   
 
 
=head2  sub _sub_get_file_dialog_type_aref

=cut

 sub _sub_get_file_dialog_type_aref {
	my ($self) = @_;
	
	my @section;	
	my $package_name = $sunix_spec->{_package_name};
	
	$section[0] = '=head2 sub get_file_dialog_type_aref'."\n\n".
	'=cut'."\n\n".
	' sub get_file_dialog_type_aref{'."\n\n".
	"\t".'my $self 	= @_;'."\n".	
	"\t".'if ($'.$package_name.'_spec->{_file_dialog_type_aref} ) {'."\n\n".
	"\t\t".'my $index_aref = $'.$package_name.'_spec->{_file_dialog_type_aref};'."\n".
	"\t\t".'return($index_aref);'."\n\n".		
	"\t".'} else {'."\n".
	"\t\t".'print("'.$package_name.'_spec, get_file_dialog_type_aref, missing get_file_dialog_type_aref\n");'."\n".
	"\t\t".'return();'."\n".
	"\t".'}'."\n\n".
	"\t".'return();'."\n".
 	' }'."\n\n\n";
 
 	return(\@section);
		
 }  


=head2 sub sub_get_binding_index_aref

=cut
 
 sub _sub_get_binding_index_aref {
	my ($self) = @_;
	
	my @section;	
	my $package_name = $sunix_spec->{_package_name};
	
	$section[0] = '=head2 sub get_binding_index_aref'."\n\n".
	'=cut'."\n\n".
	' sub get_binding_index_aref{'."\n\n".
	"\t".'my $self 	= @_;'."\n".
	"\t".'my @index;'."\n\n".	
	"\t".'if ($'.$package_name.'_spec->{_binding_index_aref} ) {'."\n\n".
	"\t\t".'my $index_aref = $'.$package_name.'_spec->{_binding_index_aref};'."\n".
	"\t\t".'return($index_aref);'."\n\n".		
	"\t".'} else {'."\n".
	"\t\t".'print("'.$package_name.'_spec, get_binding_index_aref, missing binding_index_aref\n");'."\n".
	"\t\t".'return();'."\n".
	"\t".'}'."\n\n".
	"\t".'my $index_aref = $'.$package_name.'_spec->{_binding_index_aref};'."\n".
 	' }'."\n\n\n";
 
 	return(\@section);
		
 }
 
 
 sub _sub_get_flow_type_aref {
	my ($self) = @_;
	
	my @section;	
	my $package_name = $sunix_spec->{_package_name};
	
	$section[0] = '=head2 sub get_flow_type_aref'."\n\n".
	'=cut'."\n\n".
	' sub get_flow_type_aref {'."\n\n".
	"\t".'my $self 	= @_;'."\n\n".
	"\t".'if ($'.$package_name.'_spec->{_flow_type_aref} ) {'."\n\n".
	"\t\t".'	my $index_aref = $'.$package_name.'_spec->{_flow_type_aref};'."\n".
	"\t\t".'	return($index_aref);'."\n\n".		
	"\t".'} else {'."\n".
	"\t\t".'print("'.$package_name.'_spec, get_flow_type_aref, missing flow_type_aref\n");'."\n".
	"\t\t".'return();'."\n".
	"\t".'}'."\n\n".
 	' }'."\n\n\n";
 
 	return(\@section);
		
 }


=head2  sub _sub_get_incompatibles 

	section for get_incompatibles

=cut
 
 sub _sub_get_incompatibles {
	my ($self) = @_;
	
	my @section;	
	my $package_name = $sunix_spec->{_package_name};
	
	$section[0] = '=head2 sub get_incompatibles'."\n\n".
	'=cut'."\n\n".
	' sub get_incompatibles{'."\n\n".
	"\t".'my $self 	= @_;'."\n".
	"\t".'my @needed;'."\n\n".
	"\t".'my @_need_both;'."\n\n".
	"\t".'my @_need_only_1;'."\n\n".
	"\t".'my @_none_needed;'."\n\n".
	"\t".'my @_all_needed;'."\n\n".	
	"\t".'my $params = {'."\n\n".
	"\t\t".'_need_both'."\t\t\t".'=> \@_need_both,'."\n".
	"\t\t".'_need_only_1'."\t\t".'=> \@_need_only_1,'."\n".
	"\t\t".'_none_needed'."\t\t".'=> \@_none_needed,'."\n".
	"\t\t".'_all_needed'."\t\t\t".'=> \@_all_needed,'."\n\n".		
	"\t".'};'."\n\n".		
	"\t".'my @of_two'."\t\t\t\t\t".'= (\'xx\',\'yy\');'."\n".
	"\t".'push @{$params->{_need_only_1}}	,	\@of_two;'."\n\n".
	"\t".'my $len_1_needed'."\t\t\t".'= scalar @{$params->{_need_only_1}};'."\n\n".	
	"\t".'if ($len_1_needed >= 1) {'."\n\n". 		
	"\t\t".'for (my $i=0; $i < $len_1_needed; $i++) {'."\n\n".
	"\t\t\t".'print("'.$package_name.', get_incompatibles,need_only_1:  @{@{$params->{_need_only_1}}[$i]}\n");'."\n\n".
	"\t\t".'}'."\n\n".		
	"\t".'} else {'."\n".
	"\t\t".'print("get_incompatibles, no incompatibles\n")'."\n".
	"\t".'}'."\n\n".	
	"\t".'return($params);'."\n\n".
	' }'."\n\n\n";
 
 	return(\@section);
		
 }
 

=head2  sub _sub_get_prefix_aref

=cut

 sub _sub_get_prefix_aref {
	my ($self) = @_;
	
	my @section;	
	my $package_name = $sunix_spec->{_package_name};
	
	$section[0] = '=head2 sub get_prefix_aref'."\n\n".
	'=cut'."\n\n".
	' sub get_prefix_aref {'."\n\n".
	"\t".'my $self 	= @_;'."\n\n".	
	"\t".'if ($'.$package_name.'_spec->{_prefix_aref} ) {'."\n\n".
	"\t\t".'my $prefix_aref= $'.$package_name.'_spec->{_prefix_aref};'."\n".
	"\t\t".'return($prefix_aref);'."\n\n".		
	"\t".'} else {'."\n".
	"\t\t".'print("'.$package_name.'_spec, get_prefix_aref, missing prefix_aref\n");'."\n".
	"\t\t".'return();'."\n".
	"\t".'}'."\n\n".
	"\t".'return();'."\n".
 	' }'."\n\n\n";
 
 	return(\@section);
		
 }


=head2  sub _sub_get_suffix_aref

=cut

 sub _sub_get_suffix_aref {
	my ($self) = @_;
	
	my @section;
	my $package_name = $sunix_spec->{_package_name};
		
	$section[0] = '=head2 sub get_suffix_aref'."\n\n".
	'=cut'."\n".	
	"\n".
	' sub get_suffix_aref {'."\n\n".
	"\t".'my $self 	= @_;'."\n".
	"\n".	
	"\t".'if ($'.$package_name.'_spec->{_suffix_aref} ) {'."\n".
	"\n".
	"\t\t".'	my $suffix_aref= $'.$package_name.'_spec->{_suffix_aref};'."\n".
	"\t\t".'	return($suffix_aref);'."\n".
	"\n".
	"\t".'} else {'."\n".
	"\t\t".'	print("$'.$package_name.'_spec, get_suffix_aref, missing suffix_aref\n");'."\n".
	"\t\t".'	return();'."\n".
	"\t".'}'."\n".
	"\n".
	"\t".'return();'."\n".	
 	' }'."\n\n\n";

 	return(\@section);
 }
 
=head2  sub _sub_prefix_aref

=cut

 sub _sub_prefix_aref{
	my ($self) = @_;
	
	my @section;	
	my $package_name = $sunix_spec->{_package_name}; 
  
	$section[0] = '=head2  sub prefix_aref'."\n\n".
	'Include in the Set up'."\n".
	'sections of an output Poop flow.'."\n\n".
	'prefixes and suffixes to parameter labels'."\n".
	'are filtered by sunix_pl'."\n\n".	
	'=cut'."\n\n".
	' sub prefix_aref {'."\n\n".
	"\t".'my $self 	= @_;'."\n\n".
	"\t".'my @prefix;'."\n\n".
	"\t".'for (my $i=0; $i < $max_index; $i++) {'."\n\n".
	"\t\t".'$prefix[$i]	= $empty_string;'."\n\n".
	"\t".'}'."\n\n".
	"#\t".'my $index_aref = get_binding_index_aref();'."\n".	
	"#\t".'my @index       = @$index_aref;'."\n\n".
	"\t".'# label 2 in GUI is input xx_file and needs a home directory'."\n".
	"#\t".'$prefix[ $index[0] ] = \'$DATA_SEISMIC_BIN\' . ".\'/\'.";' ."\n\n".
	"\t".'# label 3 in GUI is input yy_file and needs a home directory'."\n".
	"#\t".'$prefix[ $index[1] ] = \'$DATA_SEISMIC_TXT\' . ".\'/\'.";' ."\n\n".	
	"\t".'# label 9 in GUI is input zz_file and needs a home directory'."\n".
	"#\t".'$prefix[ $index[2] ] = \'$DATA_SEISMIC_SU\' . ".\'/\'.";' ."\n\n".	
	"\t".'$'.$package_name.'_spec ->{_prefix_aref} = \@prefix;'."\n".	
	"\t".'return();'."\n\n".
 	' }'."\n\n\n";
 
 	return(\@section);
		
 }
 
 
=head2  sub _sub_suffix_aref

For sub suffix_aref 

=cut

 sub _sub_suffix_aref{
	my ($self) = @_;
	
	my @section;	
	my $package_name = $sunix_spec->{_package_name}; 
  
	$section[0] = '=head2  sub suffix_aref'."\n\n".
	'Initialize suffixes as empty'."\n".
	'values'."\n\n".
	'=cut'."\n\n".
	' sub suffix_aref {'."\n\n".
	"\t".'my $self 	= @_;'."\n\n".
	"\t".'my @suffix;'."\n\n".
	"\t".'for (my $i=0; $i < $max_index; $i++) {'."\n\n".
	"\t\t".'$suffix[$i]	= $empty_string;'."\n\n".
	"\t".'}'."\n\n".
	"#\t".'my $index_aref = get_binding_index_aref();'."\n".	
	"#\t".'my @index       = @$index_aref;'."\n\n".
	"\t".'# label 2 in GUI is input xx_file and needs a home directory'."\n".
	"#\t".'$suffix[ $index[0] ] = \'\'.\'\' . \'$suffix_bin\';'."\n\n".
	"\t".'# label 3 in GUI is input yy_file and needs a home directory'."\n".
	"#\t".'$suffix[ $index[1] ] = \'\'.\'\' . \'$suffix_bin\';'."\n\n".
	"\t".'# label 9 in GUI is output zz_file and needs a home directory'."\n".
	"#\t".'$suffix[ $index[2] ] = \'\'.\'\' . \'$suffix_su\';'."\n\n".
	"\t".'$'.$package_name.'_spec ->{_suffix_aref} = \@suffix;'."\n".	
	"\t".'return();'."\n\n".
 	' }'."\n\n\n";
 
 	return(\@section);
		
 }
 
=head2 sub file_dialog_type_aref

=cut 

 sub file_dialog_type_aref{
	my ($self) = @_;
	
	my @type;
	
	$type[0]= '';
	
	$sunix_spec->{_file_dialog_type_aref} = \@type;
	
	return();
	
 }
 
 
=head2 sub get_max_index

=cut

sub get_max_index {
	my $self	= @_;
	
	if ( $sunix_spec->{_max_index} ) {		

		my $max_idx           	  = $sunix_spec->{_max_index};
		return($max_idx);
		
	} else {
		print("sunix_spec, get_max_index, missing max_index\n");
		return();
	}
} 

 
=head2 sub get_file_dialog_type_aref

=cut 

 sub get_file_dialog_type_aref {
	my ($self) = @_;
	
	if ( $sunix_spec->{_file_dialog_type_aref}) {
		my @type	  =  @{$sunix_spec->{_file_dialog_type_aref}};	
		return(\@type);
	} else {
		print("sunix_spec,get_file_dialog_type_aref, missing file_dialog_type_aref\n");
		return();
	}
 }
 
=head2 sub flow_type_aref

=cut 

 sub flow_type_aref{
	my ($self) = @_;
	
	my @type;
	
	$type[0]		= $flow_type->{_user_built};
	
	$sunix_spec	->{_flow_type_aref} = \@type;
	
	return();
	
 }
  
=head2 sub get_flow_type_aref

=cut 

 sub get_flow_type_aref{
	my ($self) = @_;
	
	if ( $sunix_spec->{_flow_type_aref} ) { 				
		my $type_aref = $sunix_spec->{_flow_type_aref};
		return($type_aref);			
	} else {
		
		print("sunix_spec, get_flow_type_aref, missing flow_type_aref \n");
		return();
	}	
 }

# 
#=head2 sub variables
#
#	return a hash array 
#	with definitions
#
#=cut
#
#sub variables {
#	my ($self) = @_;
#	my $hash_ref = $sunix_spec;
#	return ($hash_ref);
#}

  
#    my @file_dialog 		= @{_sub_file_dialog_type_aref()}; 
#    my @get_max_index		= @{_sub_get_max_index()}; 
#    my @get_file_dialog 	= @{_sub_get_file_dialog_type_aref()};
#    my @flow_type			= @{_sub_flow_type_aref()};
#    my @get_flow_type		= @{_sub_get_flow_type_aref()};
#    my @get_binding_length 	= @{_subget_binding_length()};
#    my @variables			= @{_sub_variables()};


=head2 sub get_body_section

 a small section of the file
 print ("sunix_package_header,section:name $name\n");

=cut

sub get_body_section {
 	my ($self) = @_;
	my @head;
	my $package_name;
	$package_name = $sunix_spec->{_package_name};
	
    $head[0]    = '	my $'.$package_name.'_spec'.' = {'."\n";
    $head[1]    = '		_CONFIG		            => $PL_SEISMIC,'."\n";
    $head[2]    = '		_DATA_DIR_IN		    => $DATA_SEISMIC_BIN,'."\n";
    $head[3]    = '	 	_DATA_DIR_OUT		    => $DATA_SEISMIC_SU,'."\n";
    $head[4]    = '		_binding_index_aref	    => \'\','."\n";
    $head[5]    = '	 	_suffix_type_in			=> $su,'."\n";
    $head[6]    = '		_data_suffix_in			=> $suffix_su,'."\n";
    $head[7]    = '		_suffix_type_out		=> $su,'."\n";
    $head[8]    = '	 	_data_suffix_out		=> $suffix_su,'."\n";
 	$head[9]    = '		_file_dialog_type_aref	=> \'\','."\n";
	$head[10]    = '		_flow_type_aref			=> \'\','."\n";		
    $head[11]   = '	 	_has_infile				=> $true,'."\n";
    $head[12]   = '	 	_has_outpar				=> $false,'."\n";	   
    $head[13]   = '	 	_has_pipe_in			=> $true,	'."\n";
    $head[14]    = '	 	_has_pipe_out           => $true,'."\n";	 
    $head[15]   = '	 	_has_redirect_in		=> $true,'."\n";
    $head[16]   = '	 	_has_redirect_out		=> $true,'."\n";
    $head[17]   = '	 	_has_subin_in			=> $false,'."\n";
    $head[18]   = '	 	_has_subin_out			=> $false,'."\n";
    $head[19]   = '	 	_is_data				=> $false,'."\n";
    $head[20]   = '		_is_first_of_2			=> $true,'."\n";
    $head[21]   = '		_is_first_of_3or_more	=> $true,'."\n";
    $head[22]   = '		_is_first_of_4or_more	=> $true,'."\n";
    $head[23]   = '	 	_is_last_of_2			=> $false,'."\n";
    $head[24]   = '	 	_is_last_of_3or_more	=> $false,'."\n";
    $head[25]   = '		_is_last_of_4or_more	=> $false,'."\n";
    $head[26]   = '		_is_suprog				=> $true,'."\n";
    $head[27]   = '	 	_is_superflow			=> $false,'."\n";
    $head[28]   = '	 	_max_index              => $max_index,'."\n";
    $head[29]   = '	 	_prefix_aref               => \'\','."\n";
    $head[30]   = '	 	_suffix_aref               => \'\','."\n";
    $head[31]   = '	};'."\n";
    $head[32]   = ''."\n\n"; 
    
    	my $incompatibles = {
		_clip              => ['mbal', 'pbal'],	
	};
    
    
    # print ("sunix_spec, get_body_section:\n @head\n");
 	return (\@head);
}


=head2 sub get_header_section

 a small section of the file
 print ("sunix_package_header,section:name $name\n");

=cut

sub get_header_section {
 	my ($self,$name) = @_;
	my @head;
	
	my $package_name;
	$package_name 		= $sunix_spec->{_package_name} ;
 	my @package 		= @{_get_package_section()};	
    my @Moose 			= @{_get_Moose_section()};
    my @version 		= @{_get_version_section()};
    my @instantiate  	= @{_get_instantiation_section()};
    my @declare			= @{_get_declare_section()};
    
    $head[0]    = $package[0];
    $head[1]    = $Moose[0];
    $head[2]    = $version[0];
    $head[3]    = $instantiate[0];
    $head[4]    = $declare[0];
	$head[5]    = ''."\n";
	$head[6]   = 'my $DATA_SEISMIC_BIN  	= $Project->DATA_SEISMIC_BIN();'."\n";
	$head[7]   = 'my $DATA_SEISMIC_SEGY  	= $Project->DATA_SEISMIC_SEGY();'."\n";
	$head[8]   = 'my $DATA_SEISMIC_SU  	= $Project->DATA_SEISMIC_SU();   # output data directory'."\n";
	$head[9]   = 'my $DATA_SEISMIC_TXT  	= $Project->DATA_SEISMIC_TXT();   # output data directory'."\n";	
	$head[10]  = 'my $PL_SEISMIC		    = $Project->PL_SEISMIC();'."\n";
	$head[11]  = 'my $PS_SEISMIC  		= $Project->PS_SEISMIC();'."\n";
	$head[12]  = 'my $max_index = # Insert a number here'."\n";
	#$'.$package_name.'->get_max_index();'."\n"; 7.14.21
	$head[13]   = ''."\n";
	$head[14]   = ''."\n";	
    
    # print ("sunix_spec, get_header_section:\n @head\n");
 	return (\@head);
}


=head2 sub get_subroutine_section


=cut

sub get_subroutine_section {
 	my ($self,$name) = @_;
	my @head;
	
	my $package_name;
	$package_name 			= $sunix_spec->{_package_name} ;
		
 	my @binding 			= @{_sub_binding_index_aref()};	
	my @file_dialog 		= @{_sub_file_dialog_type_aref()}; 
    my @flow_type			= @{_sub_flow_type_aref()};  
    my @get_binding 		= @{_sub_get_binding_index_aref()};
    my @get_binding_length 	= @{_sub_get_binding_length()};
    my @get_file_dialog 	= @{_sub_get_file_dialog_type_aref()};    
    my @get_flow_type		= @{_sub_get_flow_type_aref()};
    my @get_incompatibles   = @{_sub_get_incompatibles()};
    my @get_prefix          = @{_sub_get_prefix_aref()};
    my @get_suffix          = @{_sub_get_suffix_aref()};    
    my @prefix          	= @{_sub_prefix_aref()}; 
    my @suffix          	= @{_sub_suffix_aref()};    
#    my @get_max_index		= @{_sub_get_max_index()}; 
#    my @variables			= @{_sub_variables()}; 
          
    $head[0]    = $binding[0];
    $head[1]    = $file_dialog[0];
	$head[2]	= $flow_type[0];
    $head[3]    = $get_binding[0];
	$head[4]    = $get_binding_length[0];
    $head[5]    = $get_file_dialog[0]; 
    $head[6]    = $get_flow_type[0];
    $head[7]    = $get_incompatibles[0];
    $head[8]    = $get_prefix[0];
    $head[9]    = $get_suffix[0];   
 	$head[10]   = $prefix[0];
  	$head[11]   = $suffix[0];   
#    $head[3]    = $get_max_index[0];
#    $head[5]    = $flow_type[0];
#    $head[8]    = $variables[0];        
#    print ("sunix_spec, get_subroutine_section:\n @head\n");

 	return (\@head);
 	
}


=head2 sub set_package_name

 a small section of the file

=cut


sub set_package_name {
 	my ($self,$package_name) = @_;
	if($package_name) {
		$sunix_spec->{_package_name} = $package_name;
		# print ("sunix_spec,set_package_name,name: $package_name\n");
	} else {
		print ("sunix_spec, set_package_name, package name missing\n");
	}

}


=head2 sub get_tail_section

 a small section of the file

=cut

sub get_tail_section {
 	my ($self) = @_;
	my @head;
	
	my $package_name;
	$package_name 			= $sunix_spec->{_package_name} ;
	
    $head[0]   = '=head2 sub variables'."\n";
    $head[1]   = ''."\n\n";
    $head[2]   = 'return a hash array '."\n";
    $head[3]   = 'with definitions'."\n";
    $head[4]   = ' '."\n";
    $head[5]   = '=cut'."\n";
    $head[6]   = ' '."\n";
    $head[7]   = 'sub variables {'."\n\n";
    $head[8]   = "\t".'my ($self) = @_;'."\n";
    $head[9]   = "\t".'my $hash_ref = $'.$package_name.'_spec;'."\n";
    $head[10]  = "\t".'return ($hash_ref);'."\n";
    $head[11]  = '}'."\n";
    $head[12]  = ''."\n";
    $head[13]  = '1;'."\n";
    # print ("sunix_spec, get_tail_section:\n @head\n");
 	return (\@head);
}
	
=head2 sub set_path_out4specs

 a small section of the file

=cut

sub set_path_out4specs {
	
	my ($self,$slash_path) = @_;
	
	if (length $slash_path) {
		
		$sunix_spec->{_path_out4specs} =  $slash_path;
#		print("sunix_spec,set_path_out4specs, $slash_path\n");
		
	} else {
		print("sunix_spec,set_path_out4specs,missing value\n");
	}
	
	return();
}

1;

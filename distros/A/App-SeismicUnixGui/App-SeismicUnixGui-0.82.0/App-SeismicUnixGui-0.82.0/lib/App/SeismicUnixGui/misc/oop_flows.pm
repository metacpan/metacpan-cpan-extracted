package App::SeismicUnixGui::misc::oop_flows;
use Moose;
our $VERSION = '0.0.3';
use aliased 'App::SeismicUnixGui::messages::message_director';
use aliased 'App::SeismicUnixGui::misc::L_SU_path';

my $L_SU_messages = message_director->new();
my $L_SU_path     = L_SU_path->new();

=head2 initialize shared anonymous hash 

  key/value pairs

=cut

my $oop_flows = {
	_corrected_prog_names_aref    => '',
	_corrected_prog_versions_aref => '',
	_message_w                    => '',
	_num_progs4flow               => '',
	_prog_name                    => '',
	_prog_version                 => '',
	_prog_names_aref              => '',
	_prog_versions_aref           => '',
	_symbols_aref                 => '',
};

my @lines;

=head2 sub get_section

	final assemblage of text for perl script
	this section covers the defined flows
	Removed in V 0.0.2:
	if ( ($prog_name[$prog_idx] ne 'data_in') &&  ($prog_name[$prog_idx] ne 'data_out') ) { 
   12.3.20 corrected symbol at index 3
  
=cut

sub get_section {

	my $self           = @_;
	my @prog_name      = @{ $oop_flows->{_corrected_prog_names_aref} };
	my @version        = @{ $oop_flows->{_corrected_prog_versions_aref} };
	my @symbol         = @{ $oop_flows->{_symbols_aref} };
	my $num_progs4flow = $oop_flows->{_num_progs4flow};
	my $j              = 0;
	my $prog_idx       = 0;
	my @lines;

	$lines[$j] = "\t" . ' @items' . "\t" . '= (';

	if ( $num_progs4flow >= 0 ) {

		for (
			$prog_idx = 0, $j = 1 ;
			$prog_idx < ( $num_progs4flow - 1 ) ;
			$prog_idx++, $j++
		  )
		{

		   #			print(" oop_flows,get_section,symbols are @symbol \n");
		   #			print("oop_flows,get_section,prog_name=$prog_name[$prog_idx]\n");
		   #			print("oop_flows,get_section,num_progs4flow=$num_progs4flow\n");
		   #			print("oop_flows,get_section,version=$version[$prog_idx]\n");
		   #			print("oop_flows,get_section,symbol=$symbol[$prog_idx]\n");

			$lines[$j] =
				"\t\t  " . '$'
			  . $prog_name[$prog_idx] . '['
			  . "$version[$prog_idx]" . '], '
			  . $symbol[$prog_idx] . ',';

		}
		if (   ( $prog_name[$prog_idx] ne 'data_in' )
			&& ( $prog_name[$prog_idx] ne 'data_out' ) )
		{

			$lines[$j] =
				"\t\t  " . '$'
			  . $prog_name[$prog_idx] . '['
			  . "$version[$prog_idx]" . '],';

		}
		elsif ( $prog_name[$prog_idx] eq 'data_in' ) {

			$lines[$j] = "\t\t  " . '$data_in[1],';

		}
		elsif ( $prog_name[$prog_idx] eq 'data_out' ) {

			$lines[$j] = "\t\t  " . '$data_out[1],';
		}

		$j++;
		$lines[$j] = "\t\t  " . '$go';
		$j++;
		$lines[$j] = "\t\t  " . ');';
		$j++;
		$lines[$j] = "\t" . '$flow[1] = $run->modules(\@items);';

		return ( \@lines );

	}
	else {
		print("oop_flows,get_section,missing num_progs4flow \n");
	}

}

sub set_num_progs4flow {

	my ( $self, $hash_ref ) = @_;
	$oop_flows->{_num_progs4flow} = $hash_ref->{_num_progs4flow};

   #print("1. flows,set_num_progs4flow,number=$oop_flows->{_num_progs4flow}\n");
	return ();
}

=head2 sub set_message (widget)

=cut

sub set_message {
	my ( $self, $hash_ref ) = @_;

	if ($hash_ref) {
		$oop_flows->{_message_w} = $hash_ref->{_message_w};

		#    			 my $message_w     = $oop_flows->{_message_w};
		#				 my	$m          = "oop_flows,set_message,$message_w\n";
		# 	  			 $message_w->delete("1.0",'end');
		# 	  			 $message_w->insert('end', $m);
		# print("oop_text,set_message, message=$oop_text->{_message}\n");
	}
	return ();
}

sub set_prog_name {
	my ( $self, $prog_name_href ) = @_;

	if ($prog_name_href) {
		$oop_flows->{_prog_name} = $prog_name_href->{_prog_name};

		#print("1. flows,set_prog_name,prog_name,$oop_flows->{_prog_name}\n");
	}
	return ();
}

=head2 sub set_prog_names_aref

=cut

sub set_prog_names_aref {
	my ( $self, $prog_names_href ) = @_;

	if ($prog_names_href) {
		$oop_flows->{_prog_names_aref} = $prog_names_href->{_prog_names_aref};

#print("oop_flows,set_prog_names_aref, prog_names=@{$oop_flows->{_prog_names_aref}}\n");
	}
	return ();
}

=head2 sub set_prog_version_aref
		  print("oop_flows,set_prog_version_aref,prog_version_aref=@{$hash_aref->{_prog_version_aref}}\n");

=cut

sub set_prog_version_aref {
	my ( $self, $hash_aref ) = @_;

	if ($hash_aref) {
		$oop_flows->{_prog_version_aref} = $hash_aref->{_prog_version_aref};

# print("oop_flows,set_prog_version_aref,prog_version_aref=@{$oop_flows->{_prog_version_aref}}\n");
	}
	return ();
}

=head2 sub set_specs

	if first program is data_in
    switch with the second program in the list that 
    moves to first location in the flow

	if second file is data_in then OK
	do nothing set symbol to '<' ($in)
	 
	if there is only one item in a flow, do not run the flow

    my $num_progs4flow   =	$oop_flows->{_num_progs4flow};
    
    First program has index=0

=cut

sub set_specs {
	my ($self) = @_;

	#   use Module::Refresh; # reload updated module
	#	my $refresher = Module::Refresh->new;

	my ( @specs, @prog, @symbols );
	my (@module_spec);
	my ( $message_w, $message, $second2last_idx );
	my @corrected_prog_names;
	my @corrected_prog_versions;
	my $reverse                 = 0;
	my $prog_names_aref         = $oop_flows->{_prog_names_aref};
	my $prog_names_version_aref = $oop_flows->{_prog_version_aref};
	my @prog_names              = @$prog_names_aref;
	my @prog_versions           = @$prog_names_version_aref;
	my $num_progs4flow          = $oop_flows->{_num_progs4flow};
	my $last_idx                = $num_progs4flow - 1;
	$message_w = $oop_flows->{_message_w};

#	print("1. oop_flows,set_specs, prog_names_aref=@{$prog_names_aref}\n");
#	print(
#"1. oop_flows,set_specs, prog_version_aref=@{$prog_names_version_aref}\n"
#	);
#	print("1. oop_flows,set_specs, num_progs4flow=$num_progs4flow\n");

=head2 STEP 1

	If data_in is first program in flow
	REVERSE first two items in the flow
	i.e., switch the order of the program and data_in
	
=cut

	if ( $num_progs4flow > 1 ) {

		$second2last_idx = $num_progs4flow - 2;

		if ( $prog_names[0] eq 'data_in' ) { $reverse = 1; }

		if ($reverse) {
			my $temp_prog_name    = $prog_names[1];
			my $temp_prog_version = $prog_versions[1];

			$prog_names[1]    = $prog_names[0];
			$prog_versions[1] = $prog_versions[0];

			$prog_names[0]    = $temp_prog_name;
			$prog_versions[0] = $temp_prog_version;

			for ( my $i = 2 ; $i < $num_progs4flow ; $i++ ) {

				$prog_names[$i]    = @{$prog_names_aref}[$i];
				$prog_versions[$i] = @{$prog_names_version_aref}[$i];
			}
		}
	}
	elsif ( $num_progs4flow == 1 ) {

		# Not enough items in a flow sequence
		# NULL CASE

		print(
"1.Warning  Only one item in flow--flow may not run: oop_flows,set_specs,length = 0 or 1 \n"
		);

		# for example unif2 can run as a standalone item

		my $message_w = $oop_flows->{_message_w};
		my $message   = $L_SU_messages->flows(4);

		$message_w->delete( "1.0", 'end' );
		$message_w->insert( 'end', $message );

	}
	else {
		print(
"2.Warning No item in flow--flow will not run: oop_flows,set_specs,length = 0 \n"
		);

		my $message_w = $oop_flows->{_message_w};
		my $message   = $L_SU_messages->flows(5);

		$message_w->delete( "1.0", 'end' );
		$message_w->insert( 'end', $message );
	}

	# results of STEP 1 - reversal of first two modules in flow

	$oop_flows->{_corrected_prog_names_aref}    = \@prog_names;
	$oop_flows->{_corrected_prog_versions_aref} = \@prog_versions;
	@corrected_prog_names    = @{ $oop_flows->{_corrected_prog_names_aref} };
	@corrected_prog_versions = @{ $oop_flows->{_corrected_prog_versions_aref} };

	# END of STEP 1

# if(@prog_names) {
# print("2. oop_flows,set_specs, new prog_names=     @{$oop_flows->{_corrected_prog_names_aref}}\n");
# print("3. oop_flows,set_specs, old prog names =    @{$oop_flows->{_prog_names_aref}}\n");
# print("2. oop_flows,set_specs, new prog_versions=  @{$oop_flows->{_corrected_prog_versions_aref}}\n");
# print("3. oop_flows,set_specs, old prog versions = @{$oop_flows->{_prog_version_aref}}\n");
#}

=head2 	
	  
Using corrected names and versions (from STEP 1), 
arrange symbols within a flow sequence.
Estimate first the redirect and pipe sequences
arrange programs and symbols (>,<,|) in order.
	
=cut

	for ( my $i = 0 ; $i < $num_progs4flow ; $i++ ) {

		my $program_name = $corrected_prog_names[$i];

		$L_SU_path->set_program_name($program_name);

		my $pathNmodule_spec_w_slash_pm =
		  $L_SU_path->get_pathNmodule_spec_w_slash_pm();
		my $pathNmodule_spec_w_colon =
		  $L_SU_path->get_pathNmodule_spec_w_colon();

		require $pathNmodule_spec_w_slash_pm;

		$module_spec[$i] = $pathNmodule_spec_w_colon;

		# INSTANTIATE
		$prog[$i] = ( $module_spec[$i] )->new;

	   # print ("oop_flows,set_specs, instantiate $module_spec[$i]\n");

		$specs[$i] = $prog[$i]->variables();

	}

	if ( $num_progs4flow == 2 ) {

		# CASE 1 with 2 programs in flow
		# i.e., num_progs4flow = 2
		# first item has index 0 and has already been reordered
		# previously, e.g.,
		# data_in, evince would now be evince, data_in
		# for symbol index = 0, 1

		if ( $specs[0]->{_is_first_of_2} ) {

#			print(" 1. oop_flows,first item is $module_spec[0]\n");

			if ( $specs[1]->{_is_last_of_2} ) {

				# CASE 1A data_out is last program
				# only if second item is data_out
				if ( $corrected_prog_names[1] eq 'data_out' ) {

					# print(" 1. flows, second item is now $module_spec[1]\n");
					$symbols[0] = '$out';

					# only if second item is NOT data_out, i.e. probably data_in
					# BUT not certain this will be the case always TODO
				}
				elsif (( $corrected_prog_names[1] ne 'data_out' )
					&& ( $corrected_prog_names[1] ne 'data_in' ) )
				{

					# print(" 2. flows, second item is now $module_spec[1]\n");
					$symbols[0] = '$to';    # pipe

				}
				elsif ( $corrected_prog_names[1] eq 'data_in' ) {

					if ( $specs[0]->{_is_suprog} ) {

					 # print(" 3. flows, second item is now $module_spec[1]\n");
						$symbols[0] = '$in';    # redirect
					}
					elsif ( not $specs[0]->{_is_suprog} ) {

					 # print(" 4. flows, second item is now $module_spec[1]\n");

						if ( $specs[0]->{_has_redirect_in} ) {

					 # print(" 5. flows, second item is now $module_spec[1]\n");
							$symbols[0] = '$in';    # redirect
						}
						elsif ( not $specs[0]->{_has_redirect_in} ) {

					 # print(" 6. flows, second item is now $module_spec[1]\n");
							$symbols[0] =
							  " ";    # nothing, e.g., evince file_name.ps

						}
						else {
							print(
" 1. oop_flows, set_specs first item has bad spec file\n"
							);
						}

					}
					else {
						print(
" 2. oop_flows, set_specs first item has bad spec file\n"
						);
					}
				}
				else {
					print(" oop_flows, set_specs unexpected case\n");
				}
			}
			else {
				print(
" Warning: Second item ($module_spec[1]) is not allowed. Check *spec.pm file (oop_flows,set_specs)\n"
				);
				print(" oop_flows, set_specs, unexpected input\n");
				$message = $L_SU_messages->flows(0);
				$message_w->delete( "1.0", 'end' );
				$message_w->insert( 'end', $message );
			}

		}
		else {
			$message = $L_SU_messages->flows(1);
			$message_w->delete( "1.0", 'end' );
			$message_w->insert( 'end', $message );
			print(" Warning: First item is not allowed. Use another program\n");
		}    # first of two

	}    # length =2
	
	if ( $num_progs4flow == 3 ) {

		# CASE 2.1 first and second items
		# for symbol whose index=0
		# e.g., sugain < data_in |
			
#		print("CASE = 2.1; items in flow; length,num_progs4flow=3\n");
		
		if (   $specs[0]->{_is_first_of_3or_more}
			&& $corrected_prog_names[1] eq 'data_in' )
		{

			$symbols[0] = '$in';

#			print(" oop_flows,set_specs,case 2.1\n");

#			print(" Between items 1 and 2 symbol=$symbols[0], with index=0 \n");

			# for Third item
			if ( $specs[2]->{_is_last_of_3or_more} ) {

				# CASE 3.1.1
				# for symbol 1
				# e.g., sugain < data_in > data_out
				if ( $corrected_prog_names[2] eq 'data_out' ) {

					$symbols[1] = '$out';

					# print(" oop_flows,set_specs,case 3.1.1\n");

				}

				# CASE 3.1.2
				# e.g., sugain < data_in | suximage
				# fors symbols[1]
				elsif ($specs[2]->{_is_suprog}
					&& $corrected_prog_names[1] eq 'data_in'
					&& $specs[2]->{_has_pipe_in} )
				{

# print(" oop_flows,set_specs,corrected_prog_names[1]= $corrected_prog_names[1]\n");
					$symbols[1] = '$to';

				}
				elsif ($specs[2]->{_is_suprog}
					&& $specs[2]->{_has_outpar} )
				{

# print(" oop_flows,set_specs,corrected_prog_names[1]= $corrected_prog_names[1]\n");
					$symbols[1] = '$tty';

				}
				else {
					$message = $L_SU_messages->flows(2);
					$message_w->delete( "1.0", 'end' );
					$message_w->insert( 'end', $message );

# print(" 1. Warning: Last item is not allowed. Use data_out or a program (oop_flows,set_specs)\n");
				}
			}
			else {
				print(
" 2. Warning: Last item is not allowed. (oop_flows,set_specs)\n"
				);
			}

			# CASE 3.2 first and second items,
			# where the first program has internal access to files
			# e.g., suop2 | sugain
			# for symbols[0]
		}
		elsif ($specs[0]->{_is_first_of_3or_more}
			&& $specs[0]->{_has_pipe_out}
			&& $specs[1]->{_is_suprog}
			&& $specs[1]->{_has_pipe_in} )
		{

			$symbols[0] = '$to';

			# for Third item
			if ( $specs[2]->{_is_last_of_3or_more} ) {

				# CASE 3.2.1
				# e.g., suop2 | sugain > data_out
				# for symbols[1]
				if ( $corrected_prog_names[2] eq 'data_out' ) {

					$symbols[1] = '$out';

					# CASE 3.2.2
					# e.g., suop2 | sugain | suximage
					# for second symbol symbol[1] between
					# second and thrid program
				}
				elsif ($specs[2]->{_is_suprog}
					&& $specs[1]->{_has_pipe_out}
					&& $specs[2]->{_has_pipe_in} )
				{

					$symbols[1] = '$to';

				}
				else {
					$message = $L_SU_messages->flows(2);
					$message_w->delete( "1.0", 'end' );
					$message_w->insert( 'end', $message );

# print(" Warning: Last item is not allowed. Use data_out or program (oop_flows,set_specs)\n");
				}
			}
		}
		else {
			$message = $L_SU_messages->flows(3);
			$message_w->delete( "1.0", 'end' );
			$message_w->insert( 'end', $message );

# print(" Warning: First or second items are not allowed. (oop_flows,set_specs)\n");
		}

	}

	# end of CASE with 3 items in flow

	# CASE 4
	# when there are >=4 items in flow
	if ( $num_progs4flow >= 4 ) {

		#		print("oop_flows,set_specs,num_progs=$num_progs4flow\n");

		# CASE 4.1
		# first and second items, of 4 or more
		# e.g., sugain < data_in ...| suprog
		# for symbols[0]
		if (   $specs[0]->{_is_first_of_4or_more}
			&& $corrected_prog_names[1] eq 'data_in' )
		{

			$symbols[0] = '$in';

			#			print(" oop_flows,set_specs,case 4.1\n");

		  # CASE 4.1.1
		  # For symbol[1] between second item (index=1) and third item (index=2)
		  # for symbols[1]

			if (   $specs[2]->{_is_suprog}
				&& $specs[1]->{_has_pipe_out}
				&& $specs[2]->{_has_pipe_in} )
			{

				$symbols[1] = '$to';

	   #				print(" oop_flows,set_specs,case 4.1.1; symbols[1] =$symbols[1]\n");

			}
			else {
				print(
" Warning: Problem with item 2 or beyond, item OK (oop_flows,set_specs)\n"
				);
			}

			# End CASE 4.1.1

			# Start CASE 4.1.2
			# Third item and above, of 4 or more items
			# e.g., sugain < data_in | suprog ... > data_out or |	suximage
			# for third item and second symbol and up to symbol between the
			# second- ($j) and third-to-last ($i) of 4 or more items
			# for symbols[2 and above]
			for (
				my $i = 2, my $j = 3 ;
				$i < ( $num_progs4flow - 2 ) ;
				$i++, $j++
			  )
			{

				if (   $specs[$i]->{_is_suprog}
					&& $specs[$i]->{_has_pipe_out}
					&& $specs[$j]->{_has_pipe_in} )
				{

					#					print(" oop_flows,set_specs,case 4.1.2\n");
					$symbols[$i] = '$to';

				}
				else {
					print(
" Case 4.1.2 Warning: Problem with item 3 or beyond, items 1 and 2 OK (oop_flows,set_specs)\n"
					);

			 #					print(
			 #						" Case 4.1.2 oop_flows,set_specs,\n
			 #							\tspecs[$i]->{_is_suprog}=$specs[$i]->{_is_suprog} \n
			 #							\tspecs[$i]->{_has_pipe_out}=$specs[$i]->{_has_pipe_out} \n
			 #							\tspecs[$j]->{_has_pipe_in}=$specs[$j]->{_has_pipe_in}\n"
			 #					);
				}
			}

			# End CASE 4.1.2

# CASE 4.1.3
# For last symbol
#			print(
#				" Case 4.1.3 oop_flows,set_specs,\n
#					\tspecs[$last_idx]->{_is_suprog}=$specs[$last_idx]->{_is_suprog} \n
#					\tspecs[$last_idx]->{_is_last_of_4or_more}=$specs[$last_idx]->{_is_last_of_4or_more} \n
#					\tspecs[$last_idx]->{_has_pipe_in}=$specs[$last_idx]->{_has_pipe_in}\n"
#			);
			if ( $specs[$last_idx]->{_is_last_of_4or_more} ) {

				#				print(" oop_flows,set_specs,case 4.1.3.1\n");
				# e.g., sugain < data_in | suprog  > data_out

				# CASE 4.1.3.1
				if ( $corrected_prog_names[$last_idx] eq 'data_out' ) {

					$symbols[$second2last_idx] = '$out';

					# print(" oop_flows,set_specs,case 4.1.3.1\n");

					# CASE 4.1.3.2  sugain < data_in | suprog | suprog
				}
				elsif ($specs[$last_idx]->{_is_suprog}
					&& $specs[$last_idx]->{_has_pipe_in} )
				{

		  #					print(" oop_flows,set_specs,case 4.1.3.2\n");
		  #					print("oop_flows,set_specs,second_last_idx=$second_last_idx\n");
					$symbols[$second2last_idx] = '$to';

				}
				else {
					$message = $L_SU_messages->flows(2);
					$message_w->delete( "1.0", 'end' );
					$message_w->insert( 'end', $message );
					print(
" Warning:  3. unexpected last item (oop_flows,set_specs)\n"
					);
					print(
" Warning: 3 Last item is not allowed. Use data_out or program (oop_flows,set_specs)\n"
					);
				}

			}
			else {
				$message = $L_SU_messages->flows(2);
				$message_w->delete( "1.0", 'end' );
				$message_w->insert( 'end', $message );
				print(
					" Warning: 4. unexpected last item (oop_flows,set_specs)\n"
				);
				print(
" Warning: 4. Last item is not allowed. Use data_out or program (oop_flows,set_specs)\n"
				);
			}

			# End CASE 4.1.3

			# CASE 4.2
			# for 1st and second item of 4 or more
			# where the first program has internal access to files
			# e.g., suop2 | suprog | ... suprog .... > data_out or |	suximage
			# for symbols[0]
		}
		elsif ($specs[0]->{_is_first_of_4or_more}
			&& $specs[0]->{_has_pipe_out}
			&& $specs[1]->{_has_pipe_in}
			&& $specs[1]->{_is_suprog} )
		{
			$symbols[0] = '$to';

	   # print(" oop_flows,set_specs,case 4.2\n");
	   # print ("Between programs 1 and 2, symbol=$symbols[0], with index=0\n");

			# CASE 4.2.1
			# For symbol between second and third items
			# for symbols[1]
			if (   $specs[1]->{_is_suprog}
				&& $specs[1]->{_has_pipe_out}
				&& $specs[2]->{_has_pipe_in} )
			{

				$symbols[1] = '$to';

	   # print(" oop_flows,set_specs,case 4.2.1\n");
	   # print ("Between programs 2 and 3, symbol=$symbols[1], with index=1\n");
			}
			else {
				print(
" Warning: Problem with item 2 or beyond, item OK (oop_flows,set_specs)\n"
				);

			}

			# CASE 4.2.2
			# Third item and above of 4 or more
			# e.g., suop2 | sugain | suprog ... > data_out or |	suximage
			# for third item and up to symbol between the
			# second- ($j) and third-to-last ($i) of 4 or more items
			# for symbols [2 and beyond]
			for (
				my $i = 2, my $j = 3 ;
				$i < ( $num_progs4flow - 2 ) ;
				$i++, $j++
			  )
			{

				if (   $specs[$i]->{_is_suprog}
					&& $specs[$i]->{_has_pipe_out}
					&& $specs[$j]->{_has_pipe_in} )
				{

					$symbols[$i] = '$to';

# print(" oop_flows,set_specs,case 4.2.1\n");
# print ("Between programs $j and ($j+1), symbol=$symbols[$i], with index=$i\n");
				}
				else {
					print(
" Case 4.2.2 Warning: Problem with item 3 or beyond, items 1 and 2 OK (oop_flows,set_specs)\n"
					);
				}
			}

			# CASE 4.2.3
			# Last item and its previous symbol ( last symbol)
			if ( $specs[$last_idx]->{_is_last_of_4or_more} ) {

				# CASE 4.2.3.1
				# e.g., sugain | suprog | suprog > data_out
				# Last item and its previous symbol ( last symbol)
				if ( $corrected_prog_names[$last_idx] eq 'data_out' ) {

					$symbols[$second2last_idx] = '$out';

					# print(" oop_flows,set_specs,case 4.2.3.1\n");

					# CASE 4.2.3.2  sugain | suprog | suprog | suprog
					# for last symbol
				}
				elsif ($specs[$last_idx]->{_is_suprog}
					&& $specs[$last_idx]->{_has_pipe_in} )
				{

					# print(" oop_flows,set_specs,case 4.2.3.2\n");
					$symbols[$second2last_idx] = '$to';

				}
				else {
					$message = $L_SU_messages->flows(2);
					$message_w->delete( "1.0", 'end' );
					$message_w->insert( 'end', $message );
					print(
" Warning:  1. unexpected last item (oop_flows,set_specs)\n"
					);
					print(
" Warning: 1 Last item is not allowed. Use data_out or program (oop_flows,set_specs)\n"
					);
				}

			}
			else {

				$message = $L_SU_messages->flows(2);
				$message_w->delete( "1.0", 'end' );
				$message_w->insert( 'end', $message );
				print(
					" Warning:  2. unexpected last item (oop_flows,set_specs)\n"
				);
				print(
" Warning: 2 Last item is not allowed. Use data_out or program (oop_flows,set_specs)\n"
				);

			}

			# End CASE 4.2.3

		}
		else {
			print(" Warning:  unexpected first item (oop_flows,set_specs)\n");
		}    # CASE 4.2

	}    # CASE 4; 4 or more items or more

	$oop_flows->{_symbols_aref} = \@symbols;

#	print(
#" oop_flows,set_specs,symbols are ***@{$oop_flows->{_symbols_aref}}*** \n"
#	);
	return ();
}

1;

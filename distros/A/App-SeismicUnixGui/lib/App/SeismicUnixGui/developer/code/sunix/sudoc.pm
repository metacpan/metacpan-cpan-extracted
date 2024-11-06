package App::SeismicUnixGui::developer::code::sunix::sudoc;
use Moose;

=head2 sunix_pl

 shares many similar attributes to current 
 class in that files are examined for patterns
 However, the current class uses sudoc files
 rather than sunix perl scripts

=cut

extends 'App::SeismicUnixGui::misc::sunix_pl';

=head2 hash of encapsuated variables


=cut

my $sudoc = {
	_names  => '',
	_values => '',
};

=head2 sub parse variable names

    from among selected lines

=cut

sub parameters {
	my ( $self, $hash_ref ) = @_;
	my $line_num    = 0;
	my $op_line_num = 0;
	my $line_text;
	my ( @default_names, @default_values, @extraction );
	my $parse_names;
	my $parse_names_ref = $hash_ref;

	foreach ( @{ $parse_names_ref->{_line_contents} } ) {

# print ("line $line_num comprises: @{$parse_names_ref->{_line_contents}}[$i] ");

		$line_text = @{ $parse_names_ref->{_line_contents} }[$line_num];

		#  match regex (m//) to string ($line_text)
		#  and assign (=~) to array @fields
		#  look for any number of whitespaces (\s*)
		#  followed by one or more word characters (\w+)
		#  followed by '='
		#  followed by any or no whitespaces (\s*)
		#  followed by one or more (+) non-whitespaces [^\s]+
		my @fields = $line_text =~ m/\s*(\w+)\s*=\s*([^\s]+)/;
		my $length = scalar @fields;

		# filtered results
		#		 for (my $i=0; $i<$length; $i++) {
		#     		print ("line:$line_num, field $i:----$fields[$i]----\n");
		#		 }

		if ( $fields[0] ) {

			$default_names[$op_line_num] = $fields[0];

 # print("sudoc, $line_num param_name: $default_names[$op_line_num]\n");
 # only allow to pass those fields that are default useful values of the program
 # replace the following fields with blanks
 # replace any character .
 # greedy replacement *

			$fields[1] =~ s/\w+//;
			$fields[1] =~ s/\*\w+//;
			$fields[1] =~ s/\.\w+//;
			$fields[1] =~ s/\-\w+//;
			$fields[1] =~ s/\/\w+//;				
#			$fields[1] =~ s/^\w+\-\w+$//;
#			$fields[1] =~ s/^\w*\/\w*$//;
#			$fields[1] =~ s/\w+\/\w+$//;
			$fields[1] =~ s/;//;
			$fields[1] =~ s/\*//;			
			$fields[1] =~ s/\s+\w+//;
			$fields[1] =~ s/=//;		
			
			$fields[1] =~ s/0.0,\.\.\..*//;
			$fields[1] =~ s/1,\.\.\..*//;
			$fields[1] =~ s/1.0,\.\.\..*//;
			$fields[1] =~ s/0.0,0.0,\.\.\..*//;
			$fields[1] =~ s/\(.*//;
			$fields[1] =~ s/clip//;
			$fields[1] =~ s/\-clip//;
#			$fields[1] =~ s/^\w+\*\w+//;
			$fields[1] =~ s/fc.*//;

			$fields[1] =~ s/all.*//;	
			$fields[1] =~ s/axeswidth.*//;				
			$fields[1] =~ s/curve.*//;			
			
			$fields[1] =~ s/if.*//;	

			$fields[1] =~ s/d3*//;
			
			$fields[1] =~ s/file.*//;
			$fields[1] =~ s/f2.*//;

			$fields[1] =~ s/height.*//;
			$fields[1] =~ s/lmin//;
			$fields[1] =~ s/lmax//;
			$fields[1] =~ s/lwidth//;

			$fields[1] =~ s/maximum.*//;
			$fields[1] =~ s/min.*//;
			$fields[1] =~ s/minimum.*//;
			$fields[1] =~ s/name.*//;
			$fields[1] =~ s/nc.*//;

			$fields[1] =~ s/npair1.*//;
			$fields[1] =~ s/number//;
			$fields[1] =~ s/offset.*//;
			
			$fields[1] =~ s/\[optional.*//;


			$fields[1] =~ s/or.*//;

			$fields[1] =~ s/perc.*//;
			$fields[1] =~ s/\-perc.*//;
			$fields[1] =~ s/red,yellow,blue,\.\.\..*//;
			
			
			
			$fields[1] =~ s/tr.*//;
			$fields[1] =~ s/x-coordinate.*//;

			$fields[1] =~ s/x1min.*//;
			$fields[1] =~ s/x2min.*//;
			$fields[1] =~ s/x3min.*//;
			$fields[1] =~ s/x1max.*//;
			$fields[1] =~ s/x2max.*//;
			$fields[1] =~ s/x3max.*//;

			$fields[1] =~ s/x1.*//;
			$fields[1] =~ s/x2.*//;
			$fields[1] =~ s/x3.*//;

			$fields[1] =~ s/-wperc//;
			$default_values[$op_line_num] = $fields[1];
#			print(
#"sudoc, $line_num default param_value: $default_values[$op_line_num]\n"
#			);

			$op_line_num++;
		}

		$line_num++;
	}

	# before exporting the parameter names and their values
	# sort the names alphabetically but keep corresponding values attached
	# borrowed from web: AdrianHHH
	my @key_names = @default_names;
	my @values    = @default_values;

	my ( @export_names, @export_values );
	my ( %old_hash,     %new_hash );

	# place names and their values into a hash key/value pairs
	for ( my $i = 0 ; $i <= $#key_names ; $i++ ) {
		$old_hash{ $key_names[$i] } = $values[$i];

		# print("key=$key_names[$i]; values=$old_hash{$key_names[$i]}\n");
	}

	# remove duplicate names/keys and their attached values
	my @unique_keys        = sort keys %old_hash;
	my $length_unique_keys = scalar @unique_keys;

# print ("#unique_keys=$length_unique_keys, alphabetical and unique_keys: @unique_keys,\n");

	my ( $key, $value );

	for ( my $i = 0 ; $i < $length_unique_keys ; $i++ ) {

		$key   = $unique_keys[$i];
		$value = $old_hash{$key};

#		print
#		  "#=$i: unique and alphabetical key: $key, and its value: $value\n";

		$export_names[$i]  = $unique_keys[$i];
		$export_values[$i] = $value;
	}

	$sudoc->{_names}  = \@export_names;
	$sudoc->{_values} = \@export_values;
	return ($sudoc);

}
1;

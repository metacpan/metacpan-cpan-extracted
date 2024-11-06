use Moose;
=head1 DOCUMENTATION

=head2 SYNOPSIS 

count

 PERL PROGRAM NAME: copyNclean_segy_up.pl
 AUTHOR: 	Juan Lorenzo
 DATE: 		Nov. 23 2023

 DESCRIPTION 
     count occurrences of strings in a list

 BASED ON:

=cut

=head2 USE

=head3 NOTES

=cut

my $content_ref = &wanted('./');
my @content     = @$content_ref;

copy_up($content_ref);

exit;

sub wanted {
	my ($path2look) = @_;

	use File::Slurp;
	my @content = read_dir( $path2look, prefix => 1 );

	my $result = \@content;

	return ($result);
}

=head2 sub clean

Removes leading zeros and
chages sgy to segy suffix.

=cut
sub clean {
	my ($array_ref) = @_;
	my @names;

	foreach my $val (@$array_ref) {
		$val =~ s/^.\/0+//;
		$val =~ s/sgy/segy/;
		push @names, $val;
	}
     my $result = \@names;

	 return($result);
}

sub copy_up {
	my ($array_ref) = @_;

	my $new_name;
	my $old_name;
	
	# pre-condition
	my @old_name = @$array_ref;
	print @old_name;
	
	my $clean_name_aref = &clean($array_ref);
	my @clean_name      = @$clean_name_aref;
	my $num_names       = scalar @clean_name;
	
	for (my $i=0; $i< $num_names; $i++){
		
		if ( $old_name[$i]  ne './copy.pl' 
		      and $old_name[$i] ne '../') {

			$new_name = "../".$clean_name[$i];
			system("cp $old_name[$i] $new_name");
			print ("copy $old_name[$i] $new_name \n");
		} else {
			print ("will not cp copy.pl or ../ \n");
		}
	}

}

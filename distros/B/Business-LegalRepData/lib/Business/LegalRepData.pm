package Business::LegalRepData;
use strict;
use warnings;
our $VERSION = '0.06';

use URI::Escape;
use JSON;
use Data::Dumper;
use File::Spec;

=pod
USAGE:
	my $whole_data_subfolder = "./echrapp_reps";
	my $step = 1000;
	my $range_order = $ARGV[0] or die "Must give the argument";
	my $output_folder = "echrapp_rep_data_extracts";
	Business::LegalRepData::extract_json_range_number($whole_data_subfolder, $step, $range_order, $output_folder);
USAGE:
	my $whole_data_subfolder = "./echrapp_rep_data_extracts";
	my @cumulative_aoh = Business::LegalRepData::get_aoh_from_range_of_jsons($whole_data_subfolder);	
=cut


$| = 1;


sub extract_table_1_from_html{
	my $html_content = shift;
	my ($table) = $html_content =~ m{
		(<table\s+class="table\s+table-striped\s+table-borderless">.*?</table>)
	}xs;
	return $table;
}


sub extract_table_2_from_html{
	my $html_content = shift;
	my ($table) = $html_content =~ m{
		(<table\s+class="applications-index\s+table\s+table-hover">.*?</table>)
	}xs;
	return $table;
}


sub extract_rep_name_from_html{
	my $html_content = shift;
	my ($rep_name) = $html_content =~ m{
		<h1>([^<]*)</h1>
	}xs;
	return $rep_name;
}

sub extract_total_app_count_from_html {
    my $html_content = shift;
    my ($total_app_count) = $html_content =~ m{
        <b>\s*(\d+)\s*</b>\s*applications?\s+available\s+in\s+the\s+SOP\s+database\.
    }xsi;
    return $total_app_count;
}

sub extract_status_counts_array {
    my $html = shift;
    my @rows;
    while ( $html =~ m{
        <tr>\s*
        <td\b[^>]*>\s*([^<]+)\s*</td>\s*
        <td\b[^>]*>\s*([^<]+)\s*</td>\s*
        </tr>
    }xsg ) {
        push @rows, {
            key   => $1,
            value => $2,
        };
    }
	return \@rows;
}

sub extract_hashref_from_file{
	my $fn = shift;
	open FH, "<$fn" or die $!;
	my $html_content = do {local $/; <FH>};
	my $status_aohref = extract_status_counts_array($html_content);
	my $total_app_count = extract_total_app_count_from_html($html_content);
	my $rep_name = extract_rep_name_from_html($html_content);
	return {total_app_count=>$total_app_count, status_aohref=>$status_aohref, rep_name=>$rep_name,  };
}

sub extract_tables_rows_from_table_2{
	my $table_2 = shift;
	my @rows = $table_2 =~ m{
		(<tr\b.*?</tr>)
	}xsg;
	shift @rows;
	foreach my $row (@rows){
		get_href_from_trow_2($row);
	}
}

sub read_and_save_rawdata{
	my $out_json_file_name = shift;
	my $raw_data_subfolder = shift;
	my $first_rep_number = shift;
	my $last_rep_number = shift;
	printf "raw_data_subfolder = %s\n", $raw_data_subfolder;
    opendir(D, "$raw_data_subfolder") || die "Can't open directory $raw_data_subfolder: $!\n";
    my @file_list = readdir(D);
    my @aoh;
	my $count = 0;
    foreach my $entry (@file_list) {
		next unless $entry =~ /^(\d{5})\.html$/;
		my $rep_number = scalar $1;
        if($rep_number >= $first_rep_number){
			$count++;
			last if $rep_number > $last_rep_number;
			my $full_fn = File::Spec->catdir($raw_data_subfolder, $entry);
			print ". ";
			my $href = extract_hashref_from_file($full_fn);
			$href->{rep_database_number} = $rep_number;
			push @aoh, $href;
        }
    }
    closedir(D);
	my $json_text = JSON->new->utf8->encode(\@aoh);
	open FH, ">$out_json_file_name" or die $!;
	print FH $json_text, "\n";
	close FH;
	printf "\nData output to %s\n", $out_json_file_name;			
}


# The following function generates array of ranges (as a hashref)
sub generate_file_number_ranges{
	my $step = shift;
	my $last_possible_file_number = 38301;
	my @file_number_ranges;
	my $buffer_date;
	foreach (my $fst_number=1; $fst_number<=$last_possible_file_number; $fst_number += $step ){
		my $projected_lst_number = $fst_number + $step - 1 ;
		my $lst_number = $projected_lst_number > $last_possible_file_number ? $last_possible_file_number : $projected_lst_number ;
		push @file_number_ranges, {fst_number=>$fst_number, lst_number=>$lst_number} ;
	}
	printf "step = %d. Total ranges generated : %d\n", $step, scalar @file_number_ranges;
	return @file_number_ranges;
}

sub extract_json_range_number{
	my $whole_data_subfolder = shift;
	my $step = shift;
	my $range_order = shift;
	my $output_folder = shift;
	
	my @file_number_ranges = generate_file_number_ranges($step);
	print "range_order = $range_order\n";
	my $first_file_number = $file_number_ranges[$range_order-1]->{fst_number};
	my $last_file_number  = $file_number_ranges[$range_order-1]->{lst_number};
	my $json_filename = sprintf "%05d_%05d.json", $first_file_number, $last_file_number;
	printf "%d => %d. json_filename = %s\n", $first_file_number, $last_file_number, $json_filename ;
	my $full_json_filename = File::Spec->catdir($output_folder, $json_filename);
	read_and_save_rawdata($full_json_filename, $whole_data_subfolder, $first_file_number, $last_file_number);
}


#####################################################################################
#   READING EXTRACTS
#####################################################################################

sub get_aoh_from_one_json{
	my $whole_data_subfolder = shift;
	my $fn = shift;
	my $full_file_path = File::Spec->catdir($whole_data_subfolder, $fn);
	# print  $full_file_path, "\n";
	open( my $fh, '<', "$full_file_path" ) or die $!;
	my $json_text = do { local $/; <$fh> };
	my $perl_scalar = decode_json( $json_text );
	# print Dumper $perl_scalar;
	close($fh);
	# printf "count = %d\n", scalar @$perl_scalar;
	return @$perl_scalar;
}

sub get_aoh_from_range_of_jsons{
	my $whole_data_subfolder = shift;
	
    opendir(D, "$whole_data_subfolder") || die "Can't open directory $whole_data_subfolder: $!\n";
    my @file_list = readdir(D);
    my @cumulative_aoh;
    foreach my $f (@file_list) {
		next if ( -d $f or $f !~ /\.json$/g);
		my @aoh = get_aoh_from_one_json($whole_data_subfolder, $f);
		# printf "%d ", scalar @aoh;
		push @cumulative_aoh, @aoh;
		# print "$f ";
	}
	return @cumulative_aoh;
}

1;

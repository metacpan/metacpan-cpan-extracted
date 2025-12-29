package Business::Legal;
use strict;
use warnings;
our $VERSION = '0.04';

use URI::Escape;
use JSON;
use Data::Dumper;
use File::Spec;

=pod
USAGE:

my $whole_data_subfolder = "./monthly_data";
my $folder_count = 12;
Business::Legal::read_rawdata_by_month_dirs($whole_data_subfolder, "1999-12-11", $folder_count);

USAGE:

my $subfolder = ".";
Business::Legal::get_aoh_from_range_of_jsons($subfolder);

=cut



$| = 1;

sub extract_tbody{
	my $html_content = shift;
	$html_content =~ /<tbody>(.*)<\/tbody>/sg;
	my $tbody = $1;
	return $tbody;
}

sub extract_aoh_from_html_content{
	my $html_content = shift;
	my $tbody = extract_tbody($html_content);
	my @tbodies = $tbody =~ /<tr>(.*?)<\/tr>/sg;
	my @aoh;
	foreach my $trow (@tbodies){
		my $hashref = get_hashref_from_trow($trow);
		push @aoh, $hashref;
		# printf "%s \n%s\n", $trow, '-' x 40 ;
	}
	return @aoh;
}

sub get_hashref_from_trow{
	my $trow = shift;
	my ($current_state)     = $trow =~ /<td class="current-state-col d-table-cell">([^<]+)<\/td>/g;
	my ($state)             = $trow =~ /<td class="state-col d-none d-sm-table-cell"><a href=[^<]+>([^<]+)<\/a><\/td>/g; # new
	my ($name)              = $trow =~ /<td class="name-col d-none d-sm-table-cell">([^<]+)<\/td>/g;
	my ($date)              = $trow =~ /<td class="date-col d-none d-sm-table-cell">([^<]+)<\/td>/g;
	my ($rep_id, $rep_name)              = $trow =~ /<td class="rep-col d-none d-lg-table-cell"><a href="\/\w+\/(\d*)">([^<]*)<\/a><\/td>/ ? ($1, $2) : ('', '');
	my ($app_database_id, $app_legal_id) = $trow =~ /<td class="number-col d-none d-sm-table-cell"><a href="\/applications\/(\d*)">([^<]*)<\/a><\/td>/ ? ($1, $2) : ('', '');
	
	my $hashref = {
		current_state => $current_state,
		name => $name,
		state=> $state,
		date => $date,
		rep_id => $rep_id,
		rep_name => $rep_name,
		app_database_id => $app_database_id,
		app_legal_id => $app_legal_id,
		};
	return $hashref;
}

sub extract_aoh_from_file{
	my $fn = shift;
	my $metadata = shift;
	open FH, "<$fn" or die $!;
	my $html_content = do {local $/; <FH>};
	my @aoh = extract_aoh_from_html_content($html_content, $metadata);

	# print Dumper \@aoh;
	return @aoh;
}

sub read_destination_folder_aohref{
	my $dir = shift;
	opendir(D, "$dir") || die "Can't open directory $dir: $!\n";
	my @file_list = readdir(D);
	my @aoh;
    foreach my $html_filename (@file_list) {
		next unless $html_filename =~ /\d{4}-\d{2}-\d{2}_(\d{4}-\d{2}-\d{2})_(\d{4})/;
		my $end_date_of_span = $1;
		my $page = $2;
		print ".";
		my $full_file_path = File::Spec->catdir($dir, $html_filename);
		my $metadata = {end_date_of_span=>$end_date_of_span, page=>$page, html_filename=>$html_filename};
		my @aoh_from_one_file = extract_aoh_from_file($full_file_path, $metadata);
		push @aoh, @aoh_from_one_file;
    }
	return \@aoh;
}

sub read_rawdata_by_month_dirs{
	my $whole_data_subfolder = shift;
	my $start_folder_prefix = shift;
	my $folder_count = shift;
	printf "whole_data_subfolder = %s\n", $whole_data_subfolder;
    opendir(D, "$whole_data_subfolder") || die "Can't open directory $whole_data_subfolder: $!\n";
    my @file_list = readdir(D);
    my @aoh;
	my $count = 0;
    foreach my $entry (@file_list) {
        if($entry ge $start_folder_prefix){
			$count++;
			last if $count > $folder_count;
			my $destination_folder = File::Spec->catdir($whole_data_subfolder, $entry);
            print $destination_folder, "\n";
            
			my $aohref = read_destination_folder_aohref($destination_folder);
			printf "count = %d\n", scalar @$aohref;
			
			my $json_text = JSON->new->utf8->encode($aohref);
			my $json_file_name = File::Spec->catdir($whole_data_subfolder, "$entry.json.txt");
			open FH, ">$json_file_name" or die $!;
			print FH $json_text, "\n";
			close FH;
			printf "Metadata output to %s\n", $json_file_name;			
        }
    }
    closedir(D);
	return @aoh;
}





sub get_aoh_from_one_json{
	my $whole_data_subfolder = shift;
	my $fn = shift;
	my $full_file_path = File::Spec->catdir($whole_data_subfolder, $fn);
	open( my $fh, '<', "$full_file_path" );
	my $json_text   = <$fh>;
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
		next if ( -d $f or $f !~ /\.json\.txt$/g);
		my @aoh = get_aoh_from_one_json($whole_data_subfolder, $f);
		printf "%d ", scalar @aoh;
		push @cumulative_aoh, @aoh;
		# print "$f ";
	}
	return @cumulative_aoh;
}

1;

package BlankOnDev::DateTime;

use strict;
use warnings;

# Import Module :
use DateTime;
#use NKTIweb::DateTime::lang;
use base 'BlankOnDev::DateTime::lang';
#use vars qw($language $date_lang);

# Version :
our $VERSION = '0.1005';;

# scalar global :
our ($language, $date_lang);

# Subroutine for set languages :
# ------------------------------------------------------------------------
sub set_lang {
	# Define parameter subroutine :
	my $self = shift;
	my $key_param = scalar keys(@_);
	my $lang = 'id_ID';
	my $hashdate = undef;
	
	# IF one parameter input :
	if ($key_param eq 1) {
		if ($_[0] =~ m/^[A-Za-z_]+/ and ref($_[0]) ne 'HASH') {
			$lang = $_[0];
			$language = $_[0];
		}
		elsif (ref($_[0]) eq 'HASH') {
			$hashdate = $_[0];
			$date_lang = $_[0];
		}
	}
	
	# IF two parameters input :
	if ($key_param eq 2) {
		if ($_[0] =~ m/^[A-Za-z_]+/ and ref($_[0]) ne 'HASH') {
			$lang = $_[0];
			$language = $_[0];
		} elsif (ref($_[0]) eq 'HASH') {
			$lang = $_[0];
			$language = $_[0];
		}
		if (ref($_[1]) eq 'HASH') {
			$hashdate = $_[1];
			$date_lang = $_[1];
		} elsif ($_[1] =~ m/^[A-Za-z_]+/ and ref($_[1]) ne 'HASH') {
			$lang = $_[1];
			$language = $_[1];
		}
	}
}

# Subroutine for get languages :
# ------------------------------------------------------------------------
sub get_lang {
	# Define parameter subroutine :
	my ($self, $lang) = @_;
	
	# Define scalar for place result :
	my $data = undef;
	
	# Get language :
	my $get_lang = $self->$lang();
	$date_lang = $get_lang;
	
	return $get_lang;
}
# End of Subroutine for get languages
# ===========================================================================================================

# Subroutine for Add or Subtract Duration :
# ------------------------------------------------------------------------
sub add_or_subtract {
	# Define parameter subroutine :
	my ($self, $dt, $minplus) = @_;
	
	# Define scalar for use in this function :
	my $action = undef;
	my $number = undef;
	
	# Check IF $minplus == "HASH" :
	if ($minplus ne '') {
		#		print "HASH type \n";
		
		# Parse Action :
		$action = $minplus =~ m/\+/ ? 'add' : 'subtract';
		
		# Parse Time for add or subtract :
		if ($minplus =~ m/[D]/) {
			$minplus =~ s/\D//g;
			$number = $minplus;
			$number = $number eq '' ? 1 : $number;
			if ($action eq 'add') {
				$dt->add(days => $number);
			} else {
				$dt->subtract(days => $number);
			}
		}
		if ($minplus =~ m/W/) {
			$minplus =~ s/\D//g;
			$number = $minplus;
			$number = $number eq '' ? 1 : $number;
			if ($action eq 'add') {
				$dt->add(weeks => $number);
			} else {
				$dt->subtract(weeks => $number);
			}
		}
		if ($minplus =~ m/M/) {
			$minplus =~ s/\D//g;
			$number = $minplus;
			$number = $number eq '' ? 1 : $number;
			if ($action eq 'add') {
				$dt->add(months => $number);
			} else {
				$dt->subtract(months => $number);
			}
		}
		if ($minplus =~ m/Y/) {
			$minplus =~ s/\D//g;
			$number = $minplus;
			$number = $number eq '' ? 1 : $number;
			if ($action eq 'add') {
				$dt->add(years => $number);
			} else {
				$dt->subtract(years => $number);
			}
		}
		if ($minplus =~ m/h/) {
			$minplus =~ s/\D//g;
			$number = $minplus;
			$number = $number eq '' ? 1 : $number;
			if ($action eq 'add') {
				$dt->add(hours => $number);
			} else {
				$dt->subtract(hours => $number);
			}
		}
		if ($minplus =~ m/m/) {
			$minplus =~ s/\D//g;
			$number = $minplus;
			$number = $number eq '' ? 1 : $number;
			if ($action eq 'add') {
				$dt->add(minutes => $number);
			} else {
				$dt->subtract(minutes => $number);
			}
		}
		if ($minplus =~ m/s/) {
			$minplus =~ s/\D//g;
			$number = $minplus;
			$number = $number eq '' ? 1 : $number;
			if ($action eq 'add') {
				$dt->add(seconds => $number);
			} else {
				$dt->subtract(seconds => $number);
			}
		}
	}
	return(0);
}
# End of Subroutine for Add or Subtract Duration
# ===========================================================================================================


# Subroutine for Get Date Time :
# ------------------------------------------------------------------------
sub get {
	# Define parameter subroutine :
	my $self = shift;
	my $timestamp = undef;
	my $timezone = undef;
	my $attribute = undef;
	
	# Define hash for place result :
	my %data = ();
	
	# IF no input parameter :
	my $keys_param = scalar keys(@_);
	if ($keys_param eq 0) {
		$timestamp = time();
		$timezone = 'Asia/Makassar';
	}
	# IF just one of input parameter :
	elsif ($keys_param eq 1) {
		if ($_[0] =~ m/^[0-9,.E]+$/) {
			$timestamp = $_[0];
			$timezone = 'Asia/Makassar';
			$attribute = undef;
		}
		if ($_[0] =~ m/^[A-Za-z\/]+/ and ref($_[0]) ne 'HASH') {
			$timestamp = time();
			$timezone = $_[0];
			$attribute = undef;
		}
		if (ref($_[0]) eq "HASH") {
			$timestamp = time();
			$timezone = 'Asia/Makassar';
			$attribute = $_[0];
		}
	}
	# IF just two of input parameter :
	elsif ($keys_param == 2) {
		# For $_[0] :
		if ($_[0] =~ m/^[0-9,.E]+$/) {
			$timestamp = $_[0];
		}
		elsif ($_[0] =~ m/^[A-Za-z\/\w]+/ and ref($_[0]) ne 'HASH') {
			$timestamp = time();
			$timezone = $_[0];
		}
		# For $_[1] :
		if ($_[1] =~ m/^[A-Za-z\/]+/ and ref($_[1]) ne 'HASH') {
			$timezone = $_[1];
		}
		elsif ($_[1] =~ m/^[0-9,.E]+$/ and ref($_[1]) ne 'HASH') {
			$timestamp = $_[1];
			$timezone = 'Asia/Makassar';
		}
		elsif (ref($_[1]) eq "HASH") {
			$timezone = 'Asia/Makassar';
			$attribute = $_[1];
		}
		
	}
	# IF three of input parameter :
	elsif ($keys_param eq 3) {
		# For $_[0] :
		if (exists $_[0] and $_[0] =~ m/^[0-9,.E]+$/) {
			$timestamp = $_[0];
		} else {
			$timestamp = time();
		}
		# For $_[1] :
		if (exists $_[1] and $_[1] =~ m/^[A-Za-z\/]+/ and ref($_[1]) ne 'HASH') {
			$timezone = $_[1];
		} else {
			$timezone = 'Asia/Makassar';
			$attribute = undef;
		}
		# For $_[2] :
		if (exists $_[2] and ref($_[2]) eq "HASH") {
			$attribute = $_[2];
		} else {
			$attribute = undef;
		}
	} else {
		$timestamp = time();
		$timezone = 'Asia/Makassar';
	}
	
	# Get Language :
	if ($language) {
		$self->set_lang($language);
	} else {
		$self->set_lang('id_ID');
	}
	my $lang_date = $self->get_lang($language);
	my @Mname = @{$lang_date->{'month'}};
	my @Mname_short = @{$lang_date->{'month_short'}};
	my @Dname = @{$lang_date->{'day'}};
	my @Dname_short = @{$lang_date->{'day_short'}};
	
	# Get date time ;
	my $dt = DateTime->from_epoch(epoch => $timestamp);
	$dt->set_time_zone( $timezone );
	my $dayNum = $dt->day_of_week();
	my $dayName = $Dname[$dayNum];
	my $dayName_short = $Dname_short[$dayNum];
	my $date_num = $dt->day();
	my $monthNum = $dt->month();
	my $monthName = $Mname[$monthNum];
	my $years = $dt->year();
	
	my $hours = $dt->hour();
	my $minutes = $dt->minute();
	my $second = $dt->second();
	
	my $ymd = undef;
	my $dmy = undef;
	my $hms = undef;
	my $DateNow = undef;
	my $DateNow_custom = undef;
	my $DateNow_custom_instring = undef;
	my $add_or_subtract = undef;
	my $epoch_time = undef;
#	my $epoch_time = $dt->epoch();
	
	# Check $attribute ;
	if (ref($attribute) eq 'HASH') {
		
		# For Config :
		my $delim_date = $attribute->{'date'} ? $attribute->{'date'} : '-';
		my $delim_time = $attribute->{'time'} ? $attribute->{'time'} : ':';
		my $delim_datetime = $attribute->{'datetime'} ? $attribute->{'datetime'} : ' ';
		my $minplus_datetime = $attribute->{'minplus'} ? $attribute->{'minplus'} : '';
		$add_or_subtract = $self->add_or_subtract($dt, $minplus_datetime);
		
		# get Date Format :
		$dayNum = $dt->day_of_week();
		$dayName = $Dname[$dayNum];
		$dayName_short = $Dname_short[$dayNum];
		$date_num = $dt->day();
		$monthNum = $dt->month();
		$monthName = $Mname[$monthNum];
		$years = $dt->year();
		$epoch_time = $dt->epoch();
		
		$hours = $dt->hour();
		$minutes = $dt->minute();
		$second = $dt->second();
		
		$ymd = $dt->ymd($delim_date);
		$dmy = $dt->dmy($delim_date);
		$hms = $dt->hms($delim_time);
		
		# For Action Custom :
		my $format_datetime = $attribute->{'format'} ? $attribute->{'format'} : '';
		$format_datetime =~ s/DD/$date_num/g;
		$format_datetime =~ s/Dn/$dayName_short/g;
		$format_datetime =~ s/Di/$dayNum/g;
		$format_datetime =~ s/MM/$monthNum/g;
		$format_datetime =~ s/YYYY/$years/g;
		$format_datetime =~ s/h/$hours/g;
		$format_datetime =~ s/m/$minutes/g;
		$format_datetime =~ s/s/$second/g;
		$DateNow_custom_instring = $format_datetime;
		
		# For Action
		$DateNow = $ymd.' '.$hms;
		$DateNow_custom = $ymd.$delim_datetime.$hms;
		
	} else {
		# get Date Format :
		$ymd = $dt->ymd();
		$dmy = $dt->dmy();
		$hms = $dt->hms();
		$DateNow = $ymd.' '.$hms;
		$DateNow_custom = $ymd.' '.$hms;
		$epoch_time = $dt->epoch();
	}
	
	# Place result :
	$data{'custom_in_string'} = $DateNow_custom_instring;
	$data{'custom'} = $DateNow_custom;
	$data{'datetime'} = $DateNow;
	$data{'timestamp'} = $epoch_time;
	$data{'calender'} = {
		'day_num' => $dayNum,
		'day_name' => $dayName,
		'day_short' => $dayName_short,
		'date' => $date_num,
		'month' => $monthNum,
		'month_name' => $monthName,
		'year' => $years,
		'ymd' => $ymd,
		'dmy' => $dmy,
	};
	$data{'time'} = {
		'hour' => $hours,
		'minute' => $minutes,
		'second' => $second,
		'hms' => $hms
	};
	
#	$data{'timestamp'} = $timestamp;
#	$data{'timezone'} = $timezone;
#	$data{'test'} = 'data-test';
#	$data{'param'} = \@_;
#	$data{'param1'} = $_[0];
#	$data{'param2'} = $_[1];
#	$data{'param1_ref'} = ref($_[0]);
#	$data{'config'} = $attribute;
#	$data{'keys_param'} = $keys_param;
#	$data{'self'} = $self;
#	$data{'attribute'} = ref($attribute);
#	$data{'add-substr'} = $add_or_subtract;
	
	# Return result :
	return \%data;
}
# End of Subroutine for Get Date Time
# ===========================================================================================================

# Subroutine for Indonesia Timezone :
# ------------------------------------------------------------------------
sub id_timezone {
	my %data = ();

	$data{'wib'} = 'Asia/Jakarta';
	$data{'wita'} = 'Asia/Makassar';
	$data{'wit'} = 'Asia/Jayapura';
	$data{'short-long'} = {
		'wib' => 'Asia/Jakarta',
		'wita' => 'Asia/Makassar',
		'wit' => 'Asia/Jayapura'
	};
	$data{'long-short'} = {
		'Asia/Jakarta' => 'wib',
		'Asia/Makassar' => 'wita',
		'Asia/Jayapura' => 'wit'
	};
	$data{'shor-num'} = {
		'wib' => 1,
		'wita' => 2,
		'wit' => 3
	};
	$data{'long-num'} = {
		'Asia/Jakarta' => 1,
		'Asia/Makassar' => 2,
		'Asia/Jayapura' => 3
	};
	$data{'num-short'} = {
		'1' => 'wib',
		'2' => 'wita',
		'3' => 'wit',
	};
	$data{'num-long'} = {
		'1' => 'Asia/Jakarta',
		'2' => 'Asia/Makassar',
		'3' => 'Asia/Jayapura'
	};
	return \%data;
}
# Subroutine for Test Module NKTIweb::DateTime :
# ------------------------------------------------------------------------
sub test {
	# Define parameter subroutine :
	my $self = shift;
	my $timestamp = undef;
	my $timezone = undef;
	my $attribute = undef;
	
	# Define hash for place result :
	my %data = ();
	
	# IF no input parameter :
	my $keys_param = scalar keys(@_);
	if ($keys_param eq 0) {
		$timestamp = time();
		$timezone = 'Asia/Makassar';
	}
	# IF just one of input parameter :
	elsif ($keys_param eq 1) {
		if ($_[0] =~ m/^[0-9,.E]+$/) {
			$timestamp = $_[0];
			$timezone = 'Asia/Makassar';
			$attribute = undef;
		}
		if ($_[0] =~ m/^[A-Za-z\/]+/ and ref($_[0]) ne 'HASH') {
			$timestamp = time();
			$timezone = $_[0];
			$attribute = undef;
		}
		if (ref($_[0]) eq "HASH") {
			$timestamp = time();
			$timezone = 'Asia/Makassar';
			$attribute = $_[0];
		}
	}
	# IF just two of input parameter :
	elsif ($keys_param == 2) {
		# For $_[0] :
		if ($_[0] =~ m/^[0-9,.E]+$/) {
			$timestamp = $_[0];
		}
		elsif ($_[0] =~ m/^[A-Za-z\/\w]+/ and ref($_[0]) ne 'HASH') {
			$timestamp = time();
			$timezone = $_[0];
		}
		# For $_[1] :
		if ($_[1] =~ m/^[A-Za-z\/]+/ and ref($_[1]) ne 'HASH') {
			$timezone = $_[1];
		}
		elsif ($_[1] =~ m/^[0-9,.E]+$/ and ref($_[1]) ne 'HASH') {
			$timestamp = $_[1];
			$timezone = 'Asia/Makassar';
		}
		elsif (ref($_[1]) eq "HASH") {
			$timezone = 'Asia/Makassar';
			$attribute = $_[1];
		}
	}
	# IF three of input parameter :
	elsif ($keys_param eq 3) {
		# For $_[0] :
		if ($_[0] =~ m/^[0-9,.E]+$/) {
			$timestamp = $_[0];
		} else {
			$timestamp = time();
		}
		# For $_[1] :
		if ($_[1] =~ m/^[A-Za-z\/]+/ and ref($_[1]) ne 'HASH') {
			$timezone = $_[1];
		} else {
			$timezone = 'Asia/Makassar';
			$attribute = undef;
		}
		# For $_[2] :
		if (ref($_[2]) eq "HASH") {
			$attribute = $_[2];
		} else {
			$attribute = undef;
		}
	} else {
		$timestamp = time();
		$timezone = 'Asia/Makassar';
	}
	
	
	# Print Result :
	print "TimeStamp : $timestamp <br>";
	print "TimeZone : $timezone <br>";
	print "index 0 : <br>";
	print Dumper $_[0];
	print "<br>";
	print "index 1  : <br>";
	print Dumper $_[1];
	print "<br>";
	print "index 2  : <br>";
	print Dumper $_[2];
	print "<br>";
	print "Attribute <br>";
	print Dumper $attribute;
	print "<pre>";
	print Dumper \@_;
	print "</pre>";
	print "<br>";
	print "<hr>";
}
# End of Subroutine for Test Module NKTIweb::DateTime
# ===========================================================================================================

1;
__END__
#

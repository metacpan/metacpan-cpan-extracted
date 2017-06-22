package BlankOnDev::DateTime::lang;
use strict;
use warnings;

# Import Module :
use BlankOnDev;

# Version :
our $VERSION = '0.1005';;
use vars '$AUTOLOAD';

# AutoLoad :
sub AUTOLOAD {
	return $_[0]->id_ID();
}

# For Indonesian Language :
sub id_ID {
	my $lang = {
		'month' => [
			'', 'Januari', 'Februari', 'Maret', 'April',
			'Mei', 'Juni', 'Juli', 'Agustus',
			'September', 'Oktober', 'November', 'Desember'
		],
			'month_short' => [
			'', 'Jan', 'Feb', 'Mar', 'Apr',
			'Mei', 'Jun', 'Jul', 'Agu',
			'Sep', 'Okt', 'Nov', 'Des'
		],
			'day' => [
			'',
			'Senin', 'Selasa', 'Rabu',
			'Kamis', 'Jum\'at', 'Sabtu', 'Minggu'
		],
		'day_short' => [
			'', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'
		]
	};
	return $lang;
}

# For mount Indonesian and day Engish Language :
sub id_US {
	my $lang = {
		'month' => [
			'',
			'Januari', 'Februari','Maret','April',
			'Mei', 'Juni', 'Juli','Agustus',
			'September','Oktober','November','Desember'
		],
		'month_short' => [
			'',
			'Jan','Feb','Mar','Apr',
			'Mei','Jun','Jul','Agu',
			'Sep','Okt','Nov','Des'
		],
		'day' => [
			'',
			'Monday','Tuesday','Wednesday',
			'Thursday','Friday','Saturday','Sunday'
		],
		'day_short' => [
			'',
			'Mon','Tue','Wed',
			'Thu','Fri','Sat','Mon'
		]
	};
	return $lang;
}

# For English US Language :
sub en_US {
	my $lang = {
		'month' => [
			'',
			'January','February','March','April',
			'May', 'June', 'Juy', 'August',
			'September', 'October', 'November', 'December'
		],
		'month_short' => [
			'',
			'Jan', 'Feb', 'Mar', 'Apr',
			'May', 'Jun', 'Jul', 'Aug',
			'Sep', 'Oct', 'Nov', 'Dec'
		],
		'day' => [
			'',
			'Monday', 'Tuesday', 'Wednesday',
			'Thursday', 'Friday', 'Saturday', 'Sunday'
		],
		'day_short' => [
			'',
			'Mon', 'Tue', 'Wed',
			'Thu', 'Fri', 'Sat', 'Mon'
		]
	};
	return $lang;
}

# For Germany Language :
sub de_DE {
	my $lang = {
		'month' => [
			'',
			'Januar','Februa','Márz','April',
			'Mai', 'Juni', 'Juli', 'August',
			'September', 'Oktober', 'November', 'Dezember'
		],
		'month_short' => [
			'',
			'Jan', 'Feb', 'Mär', 'Apr',
			'Mai', 'Jun', 'Jul', 'Aug',
			'Sep', 'Okt', 'Nov', 'Dez'
		],
		'day' => [
			'',
			'Montag', 'Dienstag', 'Mittwoch',
			'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'
		],
		'day_short' => [
			'',
			'Mon', 'Die', 'Mit',
			'Don', 'Fre', 'Sam', 'Son'
		]
	};
	return $lang;
}

1;
__END__
#
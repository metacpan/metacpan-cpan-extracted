use inc::Module::Install;
use Config;

my %fussy_OS = (
	MSWin32	=> "Win32",
	aix	=> "AIX",
);

$fussy_OS{$^O}  and $] < 5.008009  and die "ERROR:  [OS unsupported]  " .
	"Data::Alias on $fussy_OS{$^O} requires perl 5.8.9 or later.\n";


name     'Data-Alias';
all_from 'lib/Data/Alias.pm';

die "ERROR: Data::Alias does not support old 5.005-style threads\n"
	if $Config{use5005threads};

WriteAll;

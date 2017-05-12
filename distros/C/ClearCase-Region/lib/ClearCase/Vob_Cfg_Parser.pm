package ClearCase::Vob_Cfg_Parser;

$VERSION = 1.01;

use strict;
use Carp;
use Log::Log4perl qw(:easy);

my(@keys		) = ();
my(@values		) = ();
my($configFile	) = "";
my($dir			) = "";
my($found		) = 0;
my($logger		) = "";

$logger = Log::Log4perl->get_logger("Vob_Cfg_Parser");
$logger->level($INFO);

foreach $dir (@INC) {
	if ( -f "$dir/Vob.cfg" ) {
		$configFile = "$dir/Vob.cfg";
		$found = 1;
		last;
	}
}
if ($found == 0) {
	$logger->error("Error: Vob.cfg not found in any \@INC directory\n");
	exit 1;
}


#*************************************************************************
# create anonymous array from comma delimited string
#*************************************************************************
sub create_anon_array
{
	use strict;

	my(@array	) = split(/,/, $_[0]);

	return \@array;
}

#*************************************************************************
# create anonymous hash
#*************************************************************************
sub create_anon_hash
{
	use strict;

	my($i			) = 0;
	my($len			) = $#keys;
	my(%hash		) = ();

	for ($i=0 ; $i <= $len ; $i++) {
		$hash{$keys[$i]} = $values[$i];
	}
	return \%hash;
}

#*************************************************************************
# get configuration info from cfg file
#*************************************************************************
sub new
{
	use strict;

	my($proto		) = shift;
	my($class		) = ref($proto) || $proto;
	my($region_name	) = Region->name();
	my($subregion	) = $_[0];
	my($vob			) = $_[1];
	my($argstg		) = $region_name . ' ' . $subregion;
	my($match		) = 0;
	my($rname		) = "";
	my($key			) = "";
	my($keyflg		) = 0;
	my($name		) = "";
	my($value		) = "";
	my($valuestg	) = "";
	my(@Fld			) = ();
	my($hashref		) = {};

	croak("Private method, Vob_Cfg_Parser->new(), cannot be called directly")
		unless caller->isa("Vob");
	push(@keys, 'vob');
	push(@values, $vob);
	push(@keys, 'subregion');
	push(@values, $subregion);
	if (! open (INFILE,"$configFile")) {
		$logger->error("Bad open on $configFile\n");
		exit 1;
	}

	while (<INFILE>) {
		# Ignore the comments and blank lines in the configuration file
		# This allows for documentation in the configuration file
		if (/^\s*#/) {                 # ignore comments
			if ($match) {
				if ($keyflg == 1) {
					last;
				}
			}
			next;
		}
		elsif (/^\s+/) {               # ignore blank lines
			if ($match) {
				if ($keyflg == 1) {
					last;
				}
			}
			next;
		}

		chomp;                  # chop off the trailing new line character

		@Fld = split(' ',$_,9999);

		# Look for the entry matching for the region label
		if (/^[ \t]*\[/) {
			$rname = $_;
			$rname =~ s/[ \t]*\[//g;
			$rname =~ s/\].*//;
			$rname =~ s/\'//g;
			if ($argstg eq $rname) {
				$match = 1;
			}
			else {
				if ($match == 1) {
					last;
				}
				$match = 0;
			}
			next;
		}
		if ($match) {
			# load the hash with the vob specific configuration options
			if ($keyflg == 0) {
				$key = $Fld[1];
				$key =~ s/\'//g;
				$key =~ s/\#.*//;
				if ($vob eq $key) {
					$keyflg = 1;
				}
				else {
					next;
				}
			}
			else {
				$name = $Fld[0];
				$value = $_;
				$value =~ s/$name[ \t]*//;
				$value =~ s/\'*//g;
				$value =~ s/\#.*//;
				if ($value =~ /\[/) {
					$valuestg = $value;
					$valuestg=~ s/\[//;
					$valuestg =~ s/\].*//;
					$valuestg=~ s/[ \t]*//g;
					$value = create_anon_array($valuestg);
				}
				push(@keys, $name);
				push(@values, $value);
			}
		}
	} # end of while loop

	close(INFILE);
	$hashref = create_anon_hash();
	bless $hashref, $class;
	return $hashref;
}

1;

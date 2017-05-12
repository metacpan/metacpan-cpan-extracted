use strict;
use Test;
BEGIN { plan tests => 12 }

use File::Spec;
use Crypt::PassGen qw/ passgen /;
ok(1);

# Since we do not have access to the installed file directly we
# need to explicitly ask for the frequency file that we generated
# during the build. The alternative is to run ingest again to 
# generate a dummy file but this may cause problems for dictionary
# selection and will not test the file we are going to install.

# Location is
my $freqfile = File::Spec->catdir("blib","lib","Crypt","PassGenWordFreq.dat");


my $nwords = 10;
my $nlett = 8;

my @words = passgen(
		    FILE => $freqfile,
		    NLETT => $nlett,
		    NWORDS => $nwords
		   );

ok(scalar(@words), $nwords);

foreach (@words) {
  ok(length($_), $nlett);
  print "# Password: $_\n";
}

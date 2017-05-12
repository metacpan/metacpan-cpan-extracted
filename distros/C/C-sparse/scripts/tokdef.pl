use Data::Dumper;
use Getopt::Long;
use Getopt::Long;
use Carp;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Cwd;
use Cwd 'abs_path';

foreach my $v (qw(

	EXPANSION_CMDLINE
	EXPANSION_STREAM
	EXPANSION_MACRO
	EXPANSION_MACROARG
	EXPANSION_CONCAT
	EXPANSION_PREPRO


    )) {
     print("package C::sparse::exp::$v;\n");
     print("our \@ISA = qw (C::sparse::exp);\n");

   }



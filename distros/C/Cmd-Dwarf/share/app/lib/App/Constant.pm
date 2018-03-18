package App::Constant;
use Dwarf::Pragma;

our(@ISA, @EXPORT);
require Exporter;
@ISA = qw(Exporter);

my %constant;
BEGIN {
	%constant = (
		TRUE    => 1,
		FALSE   => 0,
		SUCCESS => 0,
		FAILURE => 1,
	);
}

@EXPORT = keys %constant;
use constant { %constant };

1;


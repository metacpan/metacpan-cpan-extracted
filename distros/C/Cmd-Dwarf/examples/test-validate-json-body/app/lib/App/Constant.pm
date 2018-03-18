package App::Constant;
use Dwarf::Pragma;

our(@ISA, @EXPORT);
require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw|
	TRUE FALSE HTTPS_PORT SUCCESS FAILURE|;

use constant {
	TRUE                  => 1,
	FALSE                 => 0,
	SUCCESS               => 0,
	FAILURE               => 1,
	HTTPS_PORT            => 443,
};

1;


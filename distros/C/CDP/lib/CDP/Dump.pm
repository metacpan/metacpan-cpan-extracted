package CDP::Dump;

use Frontier::Client;

use strict;
use warnings;

our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS, );
require Exporter;      
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw//;

@EXPORT_OK =
qw/
	dumpARef
	dumpHRef
/;

%EXPORT_TAGS = (
    'ALL' => \@EXPORT_OK,
    'CONST' => [qw//],
);

Exporter::export_ok_tags(keys %EXPORT_TAGS);

sub dumpARef {
	my $aref = shift;
	return @{$aref};
}

sub dumpHRef {
	my $href = shift;
	while (my ($key, $value) = %{$href}) {
		print "$key:  $value";
	}
}

1;
__END__

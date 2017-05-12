package CDP::Connect;

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
@EXPORT =
qw/
	OpenCDP	
/;

@EXPORT_OK =
qw/
    OpenCDP
/;

%EXPORT_TAGS = (
    'ALL' => \@EXPORT_OK,
    'CONST' => [qw//],
);

Exporter::export_ok_tags(keys %EXPORT_TAGS);


my $debug = 0;
my $encoding = 'ISO-8859-1';

sub OpenCDP {
	my ($cdp_url, $u_name, $pw, ) = @_;

	my $control_server_url = "http://$u_name:$pw\@$cdp_url:8084/xmlrpc";

	my $client = Frontier::Client->new(
                'url' => $control_server_url,
                'debug' => $debug,
                'encoding' => $encoding,
	);
}

__END__

package Crop::Server::Constants;
use base qw/ Exporter /;

=begin nd
Class: Crop::Server::Constants
	Server layer uses a few.

	Serveral modules require constatns this class contains. All of constatns
	are exported by default.
=cut

use v5.14;
use warnings;

=begin nd
Variable: @EXPORT
	Default exort:
	
	- DEFAULT_TPL
	- FAIL
	- OK
	- PAGELESS
	- REDIRECT
	- WORKFLOW
	- XSLT_SUFFIX
=cut
our @EXPORT = qw/ DEFAULT_TPL FAIL OK PAGELESS REDIRECT WORKFLOW XSLT_SUFFIX /;

=begin nd
Constants:
	Handler result code

Constant: OK
	Handler has finished with success.

Constant: FAIL
	Handler fails.

Constant: REDIRECT
	Handler requires redirect, so handlers chain is breaks.

Constant: WORKFLOW
	Workque has replaced by other queue.
=cut
use constant {
	OK       => 'OK',
	FAIL     => 'FAIL',
	REDIRECT => 'REDIRECT',
	WORKFLOW => 'WORKFLOW',
};

=begin nd
Constant: PAGELESS
	Special name 'PAGELESS' in page name means no output, only redirect or an error handler is allowed.
=cut
use constant {
	PAGELESS => 'PAGELESS',
};

=begin nd
Constants:
	Output templates constatns.

Constant: DEFAULT_TPL
	Name part (without extension) of the default template file.

Constant: XSLT_SUFFIX
	Suffio of an XSLT template file.
=cut
use constant {
	DEFAULT_TPL => 'index',
	XSLT_SUFFIX => '.xsl',
};

1;

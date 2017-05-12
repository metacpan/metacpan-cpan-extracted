package CGI::Snapp::Overrides;

use parent 'CGI::Snapp';
use strict;
use warnings;

use Carp;

our $VERSION = '2.01';

# --------------------------------------------------

sub cgiapp_init
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.cgiapp_init()';

	print "$name\n";

} # End of cgiapp_init.

# --------------------------------------------------

sub cgiapp_prerun
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.cgiapp_prerun()';

	print "$name\n";

} # End of cgiapp_prerun.

# --------------------------------------------------

sub cgiapp_postrun
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.cgiapp_postrun()';

	print "$name\n";

} # End of cgiapp_postrun.

# --------------------------------------------------

sub setup
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.setup()';

	print "$name\n";

} # End of setup.

# --------------------------------------------------

sub teardown
{
	my($self) = @_;
	my($name) = __PACKAGE__ . '.teardown()';

	print "$name\n";

} # End of teardown.

# --------------------------------------------------

1;

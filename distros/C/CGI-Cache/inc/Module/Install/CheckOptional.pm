#line 1
package Module::Install::CheckOptional;

use strict;
use 5.005;

use Carp;
# For module install and version checks
use Module::AutoInstall;

use vars qw( @ISA $VERSION );

use Module::Install::Base;
@ISA = qw( Module::Install::Base Module::AutoInstall );

$VERSION = sprintf "%d.%02d%02d", q/0.11.5/ =~ /(\d+)/g;

# ---------------------------------------------------------------------------

sub check_optional {
  my ($self, $module, $version, $message) = @_;

  # Tell Module::Install to include this, since we use it.
  $self->perl_version('5.005');
  $self->include('Module::AutoInstall', 0);

  croak "check_optional requires a dependency and version such as \"Carp => 1.03\""
    unless defined $module and defined $version;

	return if Module::AutoInstall::_version_cmp(
	  Module::AutoInstall::_load($module), $version ) >= 0;

	print<<EOF;
*************************************************************************** 
NOTE: The optional module $module (version $version) is not installed.
EOF

	print "\n$message" if defined $message;
}

1;

# ---------------------------------------------------------------------------

#line 96

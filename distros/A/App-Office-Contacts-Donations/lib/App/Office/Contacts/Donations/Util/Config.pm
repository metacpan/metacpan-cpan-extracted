package App::Office::Contacts::Donations::Util::Config;

use Moose;

extends 'App::Office::Contacts::Util::Config';

use namespace::autoclean;

our $VERSION = '1.10';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;
	my($name) = '.htoffice.donations.conf';

	my($path);

	for (keys %INC)
	{
		next if ($_ !~ m|App/Office/Contacts/Donations/Util/Config.pm|);

		($path = $INC{$_}) =~ s|Util/Config.pm|$name|;
	}

	$self -> init($path);

} # End of BUILD.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

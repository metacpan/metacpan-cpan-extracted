
# (c) 2009 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
require 5.005_62; use strict; use warnings;

use Class::Maker::Examples::Expirable;

package Auth;

Class::Maker::class
{
	isa => [ qw( Expirable ) ],

	public =>
	{
		bool => [ qw( isin ) ],

		int => [ qw( logincount passfailed ) ],

		string => [ qw( userid passwd lastvisitdate passlastfailed ) ],
	},
};

our $VERSION = '0.02';

# Preloaded methods go here.

sub _preinit
{
	my $this = shift;

		$this->logincount( 0 );

		$this->passfailed( 0 );

		$this->isin(0);
}

sub login : method
{
	my $this = shift;

	my $passwd = shift || die __PACKAGE__."login() needs a defined passwd argument";

	#$this->debugPrint( sprintf "LOGIN COMPARE '%s' '%s'\n", $this->passwd, $passwd );

	if( $this->passwd && defined $passwd )
	{
		if( $this->passwd eq $passwd)
		{
			#$this->debugPrint( sprintf "'%s' comes in..\n\n", $this->userid );

			$this->lastvisitdate( time );

			$this->logincount( $this->logincount + 1 );

			$this->isin(1);

			return 1;
		}
	}

	$this->passfailed( $this->passfailed + 1 );

	$this->passlastfailed( time );

	$this->isin(0);

return undef;
}

sub logout : method
{
	my $this = shift;

	#$this->debugPrint( sprintf "'%s' logged out !\n\n", $this->userid );

	$this->isin(0);
}

1;
__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Class::Maker::Example::Auth - object for authentications

=head1 SYNOPSIS

	use Class::Maker::Example::Auth;

		Class::Maker::Example::Auth->new();

=head1 DESCRIPTION

This is just an example. Please have a look within the sourcecode of this module.

=head2 EXPORT

None by default.

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>

=head1 SEE ALSO

perl(1).

=cut

use IO::Extended ':all';

use Carp;

use vars qw($AUTOLOAD);

use strict;

use warnings;

sub debugSymbolsAll
{
	no strict 'refs';

	foreach my $pkg ( @_ )
	{
		print $pkg, "\n";

		foreach ( sort keys %{$pkg} )
		{
			if( /::$/ )
			{
				printf "\n$pkg%s (package %s)\n", $_, $_;

				debugSymbolsAll( $_ ) unless $_ eq 'main::';
			}
			else
			{
				printf "%-40s %-40s\n", $pkg.$_, $pkg->{$_};

				foreach my $key ( qw(SCALAR ARRAY HASH CODE IO GLOB) )
				{
					#printf "\t%-40s %-40s\n", $key, pkg->{$_}{$key};
				}
			}
		}
	}
}

sub class
{
	print "Ohhh shit... ", @_, "\n";
}

sub UNIVERSAL::AUTOLOAD
{
	$UNIVERSAL::AUTOLOAD =~ s/.*:://;

	no strict 'refs';

		"main::$UNIVERSAL::AUTOLOAD"->( @_ ) if *{ "main::$UNIVERSAL::AUTOLOAD" }{CODE} or die;
}

	debugSymbolsAll( 'UNIVERSAL::' );

package anywhere;

	class("world");

	and_here_my_computer_hangs( 'blabla' );

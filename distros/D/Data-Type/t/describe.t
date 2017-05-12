use Test;
BEGIN { plan tests => 1 }

use Data::Type qw(:all);
use Error qw(:try);

	foreach my $type ( URI, EMAIL, IP( 'V4' ), VARCHAR(80) )
	{
		Data::Type::println "\n" x 2, "# Describing ", $type->info;

		foreach my $entry ( Data::Type::testplan( $type ) )
		{
			Data::Type::printfln "#\texpecting it %s %s ", $entry->[1] ? 'is' : 'is NOT', Data::Type::strlimit( $entry->[0]->info() );
		}
	}

ok(1);

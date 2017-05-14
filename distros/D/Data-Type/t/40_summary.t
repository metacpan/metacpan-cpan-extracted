use Test;
BEGIN { $|=1; plan tests => 1 }

use Data::Type qw(:all +DB);

	foreach my $type ( STD::URI, STD::EMAIL, STD::IP( 'V4' ), DB::VARCHAR(80) )
	{
		Data::Type::println "\n" x 2, "# Describing ", $type->info;

#		print Data::Dumper->Dump( [ Data::Type::summary( '', $type ) ] );

		foreach my $entry ( Data::Type::summary( '', $type ) )
		{	
			Data::Type::printfln "#\texpecting it %s %s ", $entry->expected ? 'is' : 'is NOT', Data::Type::strlimit( $entry->object->info() );
		}
	}

ok(1);

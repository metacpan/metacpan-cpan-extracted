
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
use Data::Type; 
use Data::Dumper;

use IO::Extended qw(:all);

for( Data::Type::_search_pkg( 'Data::Type::Object::' ) )
{
	println $_;
	
	@_ = ( $_->def =~ m/hasFacet name="(.+?)"/sg ) if $_->can( 'def' );
	
		print <<'HERE';
	sub test : method
	{
		my $this = shift;

		$Data::Type::value = shift;

		my $args;

HERE


	my $cnt = 0;

	my $w = join ' ', @_;
	my $x = join ', ', @_;

		print <<HERE;

			\$args->{ qw($w) } = \@\$this;
			
HERE

	for( @_ )
	{
		$_ = lc $_;
		
	my $tmpl1 = <<HERE;
			Data::Type::ok( 1, Data::Type::Facet::$_( \$args->{$_} ) );
HERE
		print $tmpl1;
	}



		print <<HERE;
	}
		
	sub facets { qw($w) }

	sub doc { 'facets: $x' }
	
HERE

}

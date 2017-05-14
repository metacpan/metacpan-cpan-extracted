#!perl 

# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself

use blib;

use Benchmark qw(:all);

cmpthese( 
	-5, 
	{
		':all' => 'use Data::Type qw(:all)',
		
		':all +BIO' => 'use Data::Type qw(:all +BIO)',
		
		':all +BIO +DB' => 'use Data::Type qw(:all +BIO +DB)',
		
		':all +BIO +DB +W3C' => 'use Data::Type qw(:all +BIO +DB +W3C)',
	}
);
package main;

use 5.008;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

BEGIN {

    eval {
	require lib;
	lib->import( 'inc' );
	1;
    } or plan skip_all => 'Can not "use lib qw{ inc };"';

    eval {
	require My::Module::Meta;
	1;
    } or plan skip_all => 'Can not load My::Module::Meta';

}

my $meta = My::Module::Meta->new();

foreach my $method ( qw{ requires build_requires } ) {
    my %mod = %{ $meta->$method() };
    foreach my $module ( sort keys %mod ) {
	my @modspec = ( $module );
	$mod{$module}
	    and push @modspec, $mod{$module};
	ok eval "use @modspec (); 1", "$method @modspec"
	    or diag $@;
    }
}

done_testing;

1;

# ex: set textwidth=72 :

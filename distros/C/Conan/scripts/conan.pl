#!/usr/bin/perl

use lib 'lib';
use Conan;

# Handle the arge
my $arg_str = join( " ", @ARGV);
print "D: Parsing [$arg_str]\n";

if( $arg_str =~ /^promote image\s+(\S+)\s*$/ ){
	use Conan::Deploy;
	my $d = Conan::Deploy->new(
		srcimagebase => '/tmp/base/qa',
		targetimagebase => '/tmp/base/prod',
	);

	$d->promote_image( $1 );
	exit 0;
}

if( $arg_str =~ /^promote\s+instance\s+(\S+)\s+(?:to\s+)?(\S+)$/ ){
	eval { use Conan::Promote::Xen; };
	my $p = Conan::Promote::Xen->new;
	$p->update_image( $1 => $2 );
}

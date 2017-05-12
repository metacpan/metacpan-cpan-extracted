use strict;
use warnings;
use CGI::Session;
use File::Path qw(rmtree);

use Test::More tests => 11;


my @tmpdirs = qw(tmp1 tmp2);
for (@tmpdirs) {
	mkdir($_) || die "Couldn't make dir $_: $!\n";
}

END {
	rmtree($_) for @tmpdirs;
}

my $args = { 
	Layers => [
	   {
	     Driver    => 'file',
	     Directory => $tmpdirs[0],
	   },
	   {
	     Driver     => 'file',
	     Directory  => $tmpdirs[1],
	   }
	]
};


#
# make a few sessions
#
my %ids;
my $driver;
for (1..10) {
	my $s = CGI::Session->new("driver:layered", undef, $args);
	$ids{$s->id} = 1;
	$driver ||= $s->_driver;
}



my $count = 0;

$driver->traverse( sub {
	my ($id) = @_;

	$count++;

	$ids{$id} ? pass() : fail();
});

is($count, 10);


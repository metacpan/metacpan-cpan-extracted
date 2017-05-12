use strict;
use warnings;
use CGI::Session;
use File::Path qw(rmtree);

use Test::More tests => 1;

my @tmpdirs = qw(tmp1 tmp2);
for (@tmpdirs) {
	mkdir($_) || die "Couldn't make dir $_: $!\n";
}

END {
	rmtree($_) for @tmpdirs;
}

# CGI::Session uses class info for errors, so we'll be clever...
{
	package CGI::Session::Driver::file2;

	our @ISA = qw(CGI::Session::Driver::file);
	$INC{'CGI/Session/Driver/file2.pm'} = __FILE__;
}

my $args = { 
	Layers => [
	   {
	     Driver    => 'file',
	     Directory => $tmpdirs[0],
	   },
	   {
	     Driver     => 'file2',
	     Directory  => $tmpdirs[1],
	   }
	]
};

my $session = CGI::Session->new("driver:layered", undef, $args);



# we'll do a little white box testing in here...
my @drivers = $session->_driver->_drivers;

$drivers[0]->set_error("error 0");
$drivers[1]->set_error("error 1");

is($session->_driver->errstr, "[ error 0 ]\n[ error 1 ]");



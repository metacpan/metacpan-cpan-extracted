use strict;
use warnings;
use CGI::Session;
use File::Path qw(rmtree);

use Test::More tests => 9;

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

my $session = CGI::Session->new("driver:layered", undef, $args);


isa_ok($session, 'CGI::Session');

# we'll do a little white box testing in here...
my @drivers = $session->_driver->_drivers;
my $id      = $session->id;

isa_ok($drivers[0], 'CGI::Session::Driver::file');
isa_ok($drivers[1], 'CGI::Session::Driver::file');

ok($drivers[0] != $drivers[1]);

$session->param(test1 => $$);
$session->flush;

#
# check that each store is set up right and has the session
# 
foreach my $d (@drivers) {
	my ($serial) = (split(m/:/, $d->retrieve($id), 2))[1];
	my $data = $session->_serializer->thaw($serial);
	is($data->{test1}, $$);
}

#
# check that CGI::Session call works
#
my $session2 = CGI::Session->new("driver:layered", $id, $args);
is($session2->param('test1'), $$);

#
# do we fall back to the second driver?
#
$drivers[0]->remove($id);
$session2 = CGI::Session->new("driver:layered", $id, $args);
is($session2->param('test1'), $$);



#
# check that delete nukes everything.
#
my $session3 = CGI::Session->new("driver:layered", undef, $args);

my $dead = $session3->id;
$session3->delete();
$session3->flush() || diag(CGI::Session->errstr);



my $try = CGI::Session->load("driver:layered", $dead, $args);
ok(!defined $try->id);

if (defined $try->id) {
	diag("Deleted $dead");
	diag("Zombie ID: " . $try->id);
}

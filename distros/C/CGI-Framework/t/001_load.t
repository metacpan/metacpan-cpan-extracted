# -*- perl -*-

# $Header: /cvsroot/CGI::Framework/t/001_load.t,v 1.5 2003/04/28 22:15:43 mina Exp $

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 4;

BEGIN { use_ok( 'CGI::Framework' ); }

ok (
	open (FH, ">errors.html")
	,
	"Creating dummy errors.html"
	);
close (FH);

my $object = CGI::Framework->new (
	templatesdir		=>	'.',
	initialtemplate	=>	"enterusername"
	);
isa_ok ($object, 'CGI::Framework');

ok(
	unlink("errors.html"),
	"Deleting dummy errors.html"
);


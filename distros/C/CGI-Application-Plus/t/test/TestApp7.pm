# $Id: TestApp7.pm,v 1.1 2003/01/21 20:45:20 jesse Exp $

package TestApp7;

use strict;

use CGI::Application::Plus;
@TestApp7::ISA = qw(CGI::Application::Plus);

use CGI::Carp;


sub setup {
	my $self = shift;

	$self->run_modes(
		testcgi_mode => 'testcgi_mode'
	);
}


sub cgiapp_get_query {
	my $self = shift;

	require 'test/TestCGI.pm';
	my $q = TestCGI->new();

	return $q;
}


####  Run-Mode Methods

sub testcgi_mode {
	my $self = shift;

	my $output = "Hello World: testcgi_mode OK";

	return \$output;
}


1;


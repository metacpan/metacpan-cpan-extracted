# $Id: TestApp7.pm,v 1.1 2003/01/21 20:45:20 jesse Exp $

package TestApp7;

use strict;

; use CGI::Builder
  qw| CGI::Builder::CgiAppAPI
    |
;

use CGI::Carp;


sub setup {
	my $self = shift;

	$self->run_modes(
		testcgi_mode => 'testcgi_mode'
	);
}


sub cgiapp_get_query {
	my $self = shift;
 use TestCGI;

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


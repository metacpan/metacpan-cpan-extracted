package CGI::Session::Plugin::Redirect;
use strict;
use warnings;
our $VERSION = '1.01';
sub CGI::Session::redirect {
	my $session = shift;
	my($url,$param) = split(/\?/,shift,2);
	my $q = new CGI($param);
	$q->param($session->name => $session->id);
	return $q->redirect(-uri => "$url?".$q->query_string ,@_);
}
1;
=pod 

=head1 NAME

CGI::Session::Plugin::redirect - extended redirect method for CGI::Session

=head1 SYNOPSIS

use CGI::Session;
use CGI::Session::Plugin::Redirect;
my $session = new CGI::Session();
print $session->redirect('http://exsample.com/redirect-path/');

=head1 DESCRIPTION

redirect() method is added to CGI::Session.

=head1 AUTHOR

Shin Honda (makoto[at]cpan.org,makoto[at]cpan.jp)

=head1 copyright

Copyright (c) 2006- Shin Honda. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Session>

=cut

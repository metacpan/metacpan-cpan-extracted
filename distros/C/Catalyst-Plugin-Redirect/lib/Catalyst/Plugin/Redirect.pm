package Catalyst::Plugin::Redirect;

use strict;

our $VERSION = '0.02';

my($Revision) = '$Id: Redirect.pm,v 1.4 2006/01/07 13:44:47 Sho Exp $';



=head1 NAME

Catalyst::Plugin::Redirect - Redirect for Catalyst used easily is offered. 

=head1 SYNOPSIS

  use Catalyst 'Redirect';

  $c->get_baseurl;

  $c->redirect('redirect_url');
  $c->redirect('/redirect_url');
  $c->redirect('http://www.perl.org/');


=head1 DESCRIPTION

Redirect for Catalyst used easily is offered. 

=head1 METHODS

=over 2

=item get_baseurl

Basic URL of your application is returned.
If your application is executed by "http://myhost/myapp/"
it returns "/myapp/" .

=back

=cut

sub get_baseurl {
    my $c = shift;
    my $base = $c->req->base;
    my $host = $c->req->base->host;
    my $port = $c->req->base->port;
    $base =~ s!^https?://$host:$port!!;
    $base =~ s!^https?://$host!!;
    return $base;
}

=over 2

=item redirect

$c->redirect('redirect_url');
$c->res->redirect('redirect_url') is executed. 

$c->redirect('/redirect_url');
$c->res->redirect($c->get_baseurl.'redirect_url') is executed. 

$c->redirect('http://www.perl.org/');
$c->res->redirect('http://www.perl.org/') is executed.

=back

=cut

sub redirect {
    my $c = shift;

    if (@_) {
	my $location = shift;
	my $status   = shift || 302;
	if ($location =~ m!^https?://!) {
	    return $c->res->redirect($location,$status);
	} elsif ($location =~ m!^/!) {
	    my $base = $c->get_baseurl;
	    $location = $base . $location;
	    $location =~ s!//!/!g;
	    return $c->res->redirect($location, $status);
	} else {
	    return $c->res->redirect($location,$status);
	}
    }
}

=BUGS

When Reverse Proxy is used, get_baseurl returns the backend server's base.
For example, "/" will be returned when http://www.mydomain.com/myapp/ is a proxy for http://appserver.local.server/.

=head1 SEE ALSO

L<Catalyst>

=head1 AUTHOR

Shota Takayama, C<shot[atmark]bindstorm.jp>

=head1 COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut


1;

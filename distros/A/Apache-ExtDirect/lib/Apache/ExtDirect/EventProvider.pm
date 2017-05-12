package Apache::ExtDirect::EventProvider;

use 5.012000;
use strict;
use warnings;
no  warnings 'uninitialized';       ## no critic

use CGI;

use Apache2::Const -compile => qw(OK SERVER_ERROR DECLINED);

use RPC::ExtDirect ();
use RPC::ExtDirect::EventProvider;

### PACKAGE GLOBAL VARIABLE ###
#
# Debugging; off by default
#

our $DEBUG = 0;

sub handler {
    my ($r) = @_;

    local $RPC::ExtDirect::EventProvider::DEBUG = $DEBUG;

    # Only GET and POST methods are supported for polling
    return Apache2::Const::DECLINED
        unless $r->method =~ / \A (GET|POST) \z /xms;

    my $cgi = CGI->new($r);

    # Polling for Events is safe
    my $http_body = RPC::ExtDirect::EventProvider->poll($cgi);

    my $length = do { no warnings; use bytes; length $http_body; };

    $r->content_type('application/json');
    $r->headers_out->{'Content-Length'} = $length;

    $r->print($http_body);

    return Apache2::Const::OK;
}

1;

__END__

=pod

=head1 NAME

Apache::ExtDirect::EventProvider - Apache handler for Ext.Direct event polling

=head1 DESCRIPTION

This module is not intended to be used directly. See L<Apache::ExtDirect>
for more information.

=head1 AUTHOR

Alexander Tokarev, E<lt>tokarev@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Alexander Tokarev

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic>.

=cut


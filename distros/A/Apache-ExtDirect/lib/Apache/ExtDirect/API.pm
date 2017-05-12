package Apache::ExtDirect::API;

use 5.012000;
use strict;
use warnings;
no  warnings 'uninitialized';       ## no critic

use APR::Table;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
  
use Apache2::Const -compile => qw(OK SERVER_ERROR);

use RPC::ExtDirect ();
use RPC::ExtDirect::API;
use RPC::ExtDirect::Serialize;

### PACKAGE GLOBAL VARIABLE ###
#
# Debugging; off by default
#

our $DEBUG = 0;
  
sub handler {
    my ($r) = @_;

    local $RPC::ExtDirect::API::DEBUG     = $DEBUG;
    local $RPC::ExtDirect::API::Serialize = $DEBUG;

    # Get the API JavaScript
    my $js = eval { RPC::ExtDirect::API->get_remoting_api() };

    # If JS API call failed, return 500
    # What exactly went wrong is not too relevant here
    return Apache2::Const::SERVER_ERROR if $@;

    # If API call succeeded, return the content
    $r->content_type('application/javascript');

    # Content length should be in octets
    my $length = do { no warnings; use bytes; length $js; };
    $r->headers_out->{'Content-Length'} = $length;

    # Finally, print out the API
    $r->print($js);

    return Apache2::Const::OK;
}

1;

__END__

=pod

=head1 NAME

Apache::ExtDirect::API - Apache handler for RPC::ExtDirect API definition

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


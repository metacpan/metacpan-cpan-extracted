package TestProject::ApiCalls;
use warnings;
use strict;
use Dancer ':syntax';
use Encode;

=head2 do_uppercase

Returns the uppercased version of the argument.

=head3 XMLRPC api.uppercase

=for xmlrpc api.uppercase do_uppercase

=head3 JSONRPC: api.uppercase

=for jsonrpc api.uppercase do_uppercase

=head3 Arguments

Named, Struct:

=over

=item argument => $string

=back

=cut

sub do_uppercase {
    my ($call, $args) = @_;
    debug("[uppercase] ", $args);

    return { uppercase => uc($args->{argument}) };
}
1;

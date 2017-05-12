package Apache::Lint;

use warnings;
use strict;

=head1 NAME

Apache::Lint - Apache wrapper around HTML::Lint

=head1 SYNOPSIS

Apache::Lint passes all your mod_perl-generated code through the HTML::Lint module,
and spits out the resulting errors into.

    <Location /my/uri>
        SetHandler      perl-script
        PerlSetVar      Filter On
        PerlHandler     Your::Handler Apache::Lint
    </Location>

Your handler C<Your::Handler> must be Apache::Filter-aware.  At the top
of your handler, put this line:

    my $r = shift;
    $r = $r->filter_register

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

use mod_perl 1.21;
use Apache::Constants qw( OK HTTP_OK );
use Apache::Log;
use HTML::Lint;

=head1 FUNCTIONS

=head2 handler()

Apache::Filter-aware content handler.  Your other handlers in the chain
must also be filter-aware.

=cut

sub handler {
    my $r = shift;
    $r = $r->filter_register;

    my $log = $r->server->log;

    # Get any output from previous filters in the chain.
    (my $fh, my $handler_status) = $r->filter_input;

    return $handler_status unless $handler_status == OK;

    my $output = do { local $/ = undef; <$fh> };
    $r->print( $output );

    my $response_code = $r->status;
    my $type = $r->content_type;
    return OK unless ($r->content_type eq "text/html") && ($r->status eq HTTP_OK);

    my $lint = new HTML::Lint;
    $lint->newfile( $r->uri );
    $lint->parse( $output );
    $lint->eof;

    if ( $lint->errors ) {
        $log->warn( "Apache::Lint found errors in ", $r->the_request );
        $log->warn( $_->as_string() ) for $lint->errors;
    }

    return $handler_status;
}

1;

__END__

=head1 SEE ALSO

L<HTML::Lint>, L<Apache::Filter>

=head1 TODO

=over 4

=item * Make it work

=back

=head1 LICENSE

This code may be distributed under the same terms as Perl itself.

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=head1 AUTHOR

Andy Lester, E<lt>andy@petdance.comE<gt>

=cut

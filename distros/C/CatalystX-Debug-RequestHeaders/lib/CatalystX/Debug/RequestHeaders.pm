package CatalystX::Debug::RequestHeaders;
use Moose::Role;
use namespace::autoclean;

our $VERSION = '0.002';

requires 'log_request_headers';

around log_request_headers => sub {
    my $orig    = shift;
    my $c       = shift;
    my $headers = shift;    # an HTTP::Headers instance

    return unless $c->debug;

    $c->log_headers('request', $headers);
};

1;

=head1 NAME

CatalystX::Debug::RequestHeaders - Log the full request headers sent to a Catalyst application in debug mode

=head1 SYNOPSIS

    use Catalyst qw/
        +CatalystX::Debug::RequestHeaders
    /;

=head1 DESCRIPTION

Prints a L<Text::SimpleTable> style table containing all the headers sent from the
user's browser to the application for each request when the application is in debug mode.

=head1 METHODS

=head2 log_request_headers

This hook method in L<Catalyst> is wrapped to call the L<Catalyst/log_headers> method
for the request headers.

=head1 BUGS

None known, but there probably are some.

Patches are welcome, as are bug reports in the L<rt.cpan.org> bug tracker.

=head1 AUTHOR

Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>.

=head1 COPYRIGHT & LICENSE

Copyright 2010 the above author(s).

This sofware is free software, and is licensed under the same terms as perl itself.

=cut


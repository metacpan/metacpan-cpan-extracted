package CatalystX::Debug::ResponseHeaders;
use Moose::Role;
use namespace::autoclean;

our $VERSION = '0.002';

requires qw/
    log_response_headers
    log_response_status_line
/;

around log_response_status_line => sub {};

around log_response_headers => sub {
    my ($orig, $c, $headers) = @_;

    $c->log_headers('response', $headers);
};

1;

=head1 NAME

CatalystX::Debug::ResponseHeaders - Log the full response headers sent by your Catalyst application in debug mode

=head1 SYNOPSIS

    use Catalyst qw/
        +CatalystX::Debug::ResponseHeaders
    /;

=head1 DESCRIPTION

Prints a L<Text::SimpleTable> style table containing all the headers sent from the
user's browser to the application for each request when the application is in debug mode.

=head1 METHODS

=head2 log_response_status_line

Thie method is wrapped to stop the normal method being called. This suppresses the
normal single line response status output.

=head2 log_response_headers

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

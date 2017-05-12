package App::MultiModule::Tasks::HTTPClient;
$App::MultiModule::Tasks::HTTPClient::VERSION = '1.161230';
use 5.006;
use strict;
use warnings FATAL => 'all';
use POE qw(Component::Client::HTTP);
use HTTP::Request;
use Modern::Perl;
use Data::Dumper;
use Storable;

use parent 'App::MultiModule::Task';

=head1 NAME

App::MultiModule::Tasks::HTTPClient - Do http/httpds requests in MultiModule

=cut

=head2 message

=cut
{
sub message {
    my $self = shift;
    my $message = shift;
    my %args = @_;
    $self->debug('message', message => $message)
        if $self->{debug} > 5;
    my $url = $message->{http_url};
    my $timeout = $message->{http_timeout} || 30;
    POE::Component::Client::HTTP->spawn(
        Alias     => $url,
        Timeout   => $timeout,
    );
    my $response_handler = sub {
        my ($request_packet, $response_packet) = @_[ARG0, ARG1];
        my $request_object  = $request_packet->[0];
        my $response_object = $response_packet->[0];

        $message->{http_content} = $response_object->content;
        $message->{http_status_line} = $response_object->status_line;
        $message->{http_code} = $response_object->code;
        $message->{http_is_success} = $response_object->is_success;
        $message->{http_is_info} = $response_object->is_info;
        $message->{http_is_redirect} = $response_object->is_redirect;
        $message->{http_is_error} = $response_object->is_error;
        $message->{http_is_server_error} = $response_object->is_server_error;
        $message->{http_is_client_error} = $response_object->is_client_error;
        $message->{http_is_fresh} = $response_object->is_fresh;
        $message->{http_fresh_until} = $response_object->fresh_until;
        $self->emit($message);
    };

    POE::Session->create(
        inline_states => {
            _start => sub {
                POE::Kernel->post(
                    $url,        # posts to the 'ua' alias
                    'request',   # posts to ua's 'request' state
                    'response',  # which of our states will receive the response
                    HTTP::Request->new(GET => $message->{http_url}),# an HTTP::Request object
                );
            },
            _stop => sub {},
            response => $response_handler,
        },
    );
}
}

=head2 set_config

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config;
}


=head1 AUTHOR

Dana M. Diederich, C<< <dana@realms.org> >>

=head1 BUGS

Please report any bugs or feature requests through L<https://github.com/dana/perl-App-MultiModule-Tasks-HTTPClient/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::MultiModule::Tasks::HTTPClient


You can also look for information at:

=over 4

=item * Report bugs here:

L<https://github.com/dana/perl-App-MultiModule-Tasks-HTTPClient/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-MultiModule-Tasks-HTTPClient>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-MultiModule-Tasks-HTTPClient>

=item * Search CPAN

L<https://metacpan.org/module/App::MultiModule::Tasks::HTTPClient>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Dana M. Diederich.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of App::MultiModule::Tasks::HTTPClient

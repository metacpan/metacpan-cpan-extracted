package Dancer::Plugin::Paginate;

use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin;

=head1 NAME

Dancer::Plugin::Paginate - HTTP 1.1 Range-based Pagination for Dancer apps.

=head1 VERSION

Version 1.0.2

=cut

our $VERSION = '1.0.2';

=head1 DESCRIPTION

HTTP 1.1 Range-based Pagination for Dancer apps.

Provides a simple wrapper to provide pagination of results via the HTTP 1.1 Range headers for AJAX requests.

=head1 SYNOPSIS

To use, simply add the "paginate" keyword to any route that should support HTTP Range headers. The HTTP Request
will be processed and Dancer session variables will be populated with the items being requested.

    use Dancer::Plugin::Paginate;

    get '/data' => paginate sub { ... }
    ...

=head1 Configuration Options

=cut

my $settings = plugin_setting;

=head2 Ajax-Only

Options: I<true|false>

Default: B<true>

Determines if paginate should only operate on Ajax requests.

=cut

my $ajax_only = $settings->{'Ajax-Only'} || true;

=head2 Mode

Options: I<headers|parameters|both>

Default: B<headers>

Controls if paginate will look for the pagination in the headers, parameters, or both.

If set to both, headers will be preferred.

=head3 Headers Mode

Header mode will look for the following 2 Headers:

=over

=item Content-Range

=item Range-Unit

=back

Both are required.

You can read more about these at L<http://www.ietf.org/rfc/rfc2616.txt> and
L<http://greenbytes.de/tech/webdav/draft-ietf-httpbis-p5-range-latest.html>.

Range-Unit will be returned to your app, but is not validated in any way.

=head3 Parameters mode

Parameters mode will look the following parameters in any of Dancer's
parameter sources (query, route, or body):

=over

=item Start

=item End

=item Range-Unit

=back

Start and End are required. Range-Unit will be populated with an empty string if not
available.

=cut

my $mode = $settings->{Mode} || 'headers';

=head1 Keywords

=head2 paginate

The paginate keyword is used to add a pagination processing to a route. It will:

=over

=item Check if the request is AJAX (and stop processing if set to ajax-only).

=item Extract the data from Headers, Parameters, or Both.

=item Store these in Dancer Session Variables (defined below).

=item Run the provided coderef for the route.

=item Add proper headers and change status to 206 if coderef was successful.

=back

Vars:

=over

=item range_available - Boolean. Will return true if range was found.

=item range - An arrayref of [start, end].

=item range_unit - The Range Unit provided in the request.

=back

In your response, you an optionally provide the following Dancer Session Variables to customize response:

=over

=item total - The total count of items. Will return '*' if not provided.

=item return_range - An arrayref of provided [start, end] values in your response. Original will be reused if not provided.

=item return_range_unit - The unit of the range in your response. Original will be reused if not provided.

=back

=cut

sub paginate {
    my $coderef = shift;
    return sub {
        if ($ajax_only) {
            return $coderef->() unless request->is_ajax();
        }
        my $range;
        if ($mode =~ m/headers/i) {
            $range = _parse_headers(request->header('Range'), request->header('Range-Unit'));
            return $coderef->() unless defined $range->{Start};
        }
        elsif ($mode =~ m/parameters/i) {
            $range = _parse_parameters(request->params);
            return $coderef->() unless defined $range->{Start};
        }
        elsif ($mode =~ m/both/i) {
            $range = _parse_headers(request->header('Range'), request->header('Range-Unit'));
            unless (defined $range->{Start}) {
                my %params = request->params;
                $range = _parse_parameters(\%params);
            }
            return $coderef->() unless defined $range->{Start};
        }
        else {
            Dancer::Logger::warning("[Dancer::Plugin::Paginate] Mode set to an invalid value. Valid values: [headers|parameters|both]");
            return $coderef->();
        }
        var range => [$range->{Start}, $range->{End}];
        var range_unit => $range->{Unit};
        var range_available => true;
        my $content  = $coderef->();
        my $response = Dancer::SharedData->response;
        $response->content($content);
        unless ( $response->status == 200 ) {
            return $response;
        }
        my $total = var 'total';
        unless ($total) {
            $total = '*';
        }
        my $returned_range = var 'return_range';
        unless ($returned_range) {
            $returned_range = var 'range';
        }
        my $returned_range_string = "${$returned_range}[0]-${$returned_range}[1]";
        my $returned_range_unit = var 'return_range_unit';
        unless ($returned_range_unit) {
            $returned_range_unit = $range->{Unit};
        }
        my $content_range = "$returned_range_string/$total";
        $response->header( 'Content-Range' => $content_range );
        $response->header( 'Range-Unit'    => $returned_range_unit );
        my $accept_ranges = var 'accept_ranges';
        unless ($accept_ranges) {
            $accept_ranges = $range->{Unit};
        }
        $response->header( 'Accept-Ranges' => $accept_ranges );
        $response->status(206);
        return $response;
    };
}

register paginate => \&paginate;

sub _parse_headers {
    my ($range, $unit) = @_;

    unless (defined $unit) {
        return {}; # Unit is required
    }

    my ($start, $end) = split '-', $range;
    unless (defined $start && defined $end) {
        return {}; # If we can't parse the start and end, forget it.
    }

    my $results = {
        Start => $start,
        End => $end,
        Unit => $unit
    };
    return $results;
}

sub _parse_parameters {
    my $params = shift;
    my $start = $params->{'Start'};
    my $end = $params->{'End'};
    my $unit = $params->{'Range-Unit'} || '';
    unless (defined $start && defined $end) {
        return {};
    }
    my $results = {
        Start => $start,
        End => $end,
        Unit => $unit
    };
    return $results;
}

=head1 AUTHOR

Colin Ewen, C<< <colin at draecas.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-paginate at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Paginate>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Paginate


This is developed on GitHub - please feel free to raise issues or pull requests
against the repo at: L<https://github.com/Casao/Dancer-Plugin-Paginate>.


=head1 ACKNOWLEDGEMENTS

My thanks to David Precious, C<< <davidp at preshweb.co.uk> >> for his
Dancer::Plugin::Auth::Extensible framework, which provided the Keyword
syntax used by this module. Parts were also used for testing purposes.


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Colin Ewen.

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

register_plugin;

true;

 # End of Dancer::Plugin::Paginate

package App::Unicheck::Modules::HTTP;

use 5.10.1;
use strict;
use warnings FATAL => 'all';
use Moo;
use Getopt::Long qw(GetOptionsFromArray);
use Mojo::UserAgent;
use Try::Tiny;
use JSON;
use Time::HiRes;

=head1 NAME

App::Unicheck::Modules::HTTP - App::Unicheck module to check web urls.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

App::Unicheck::Modules::HTTP can check return status, response time and size of web resources.

    # to show available information on parameters run
    unicheck --info HTTP

=cut

sub run {
    my ($self, $action, @params) = @_;

    $self->$action(@params);
}

=head1 ACTIONS

=head2 status

Get the status code of a call to an URL.

    unicheck HTTP status --url example.com

=cut

sub status {
    my ($self, @params) = @_;

    my $url    = 'http://127.0.0.1/';
    my $redirects = 3;
    my $format = 'num';

    GetOptionsFromArray([@params],
        'url=s' => \$url,
        'redirects=i' => \$redirects,
        'format=s' => \$format,
    );

    my $ua      = Mojo::UserAgent->new->max_redirects($redirects);
    my $tx      = $ua->get($url);
    my $status  = $tx->res->code;
    my $headers = $tx->res->content->headers->{headers};

    $self->_return($status, $headers, $format);
}

=head2 size

Get the size of a web resource in bytes.

    unicheck HTTP size --url example.com

=cut

sub size {
    my ($self, @params) = @_;

    my $url    = 'http://127.0.0.1/';
    my $redirects = 3;
    my $format = 'num';

    GetOptionsFromArray([@params],
        'url=s' => \$url,
        'redirects=i' => \$redirects,
        'format=s' => \$format,
    );

    my $ua      = Mojo::UserAgent->new->max_redirects($redirects);
    my $tx      = $ua->get($url);
    my $status  = $tx->res->content->{raw_size};
    my $headers = $tx->res->content->headers->{headers};

    defined $status ? $self->_return($status, $headers, $format) : $self->_return(-1, 'Something went wrong', $format);
}

=head2 time

Get the delivery time of a web resource in milliseconds.

    unicheck HTTP time --url example.com

=cut

sub time {
    my ($self, @params) = @_;

    my $url    = 'http://127.0.0.1/';
    my $redirects = 3;
    my $format = 'num';

    GetOptionsFromArray([@params],
        'url=s' => \$url,
        'redirects=i' => \$redirects,
        'format=s' => \$format,
    );

    my $ua      = Mojo::UserAgent->new->max_redirects($redirects);
    my $start   = Time::HiRes::gettimeofday();
    my $tx      = $ua->get($url);
    my $end     = Time::HiRes::gettimeofday();
    # elapsed time in ms
    my $time    = sprintf("%.2f", ($end - $start) * 1000);

    my $status  = $tx->res->code;
    defined $status ? $self->_return($time, {start => $start, end => $end}, $format) : $self->_return(-1, 'Something went wrong', $format);
}

sub _return {
    my ($self, $status, $value, $format) = @_;

    return JSON->new->encode(
        {
            message => $value,
            status  => $status,
        }
    ) if $format eq 'json';
    # default last in case some non supported format was given
    return $status; # if $format eq 'num'
}

sub help {
    {
        description => 'Check web server and web app status',
        actions => {
            status => {
                description => 'Get status code',
                params => {
                    '--url'       => 'Default: http://127.0.0.1/',
                    '--redirects' => 'Default: 3',
                },
                formats => {
                    'num'  => 'Returns the status code',
                    'json' => 'Returns a JSON structure',
                },
                default_format => 'num',
            },
            size => {
                description => 'Get page size',
                params => {
                    '--url'       => 'Default: http://127.0.0.1/',
                    '--redirects' => 'Default: 3',
                },
                formats => {
                    'num'  => 'Returns the status code',
                    'json' => 'Returns a JSON structure',
                },
                default_format => 'num',
            },
            time => {
                description => 'Get page delivery time',
                params => {
                    '--url'       => 'Default: http://127.0.0.1/',
                    '--redirects' => 'Default: 3',
                },
                formats => {
                    'num'  => 'Returns the status code',
                    'json' => 'Returns a JSON structure',
                },
                default_format => 'num',
            },
        },
    }
}


=head1 AUTHOR

Matthias Krull, C<< <<m.krull at uninets.eu>> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-unicheck-modules-http at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Unicheck-Modules-HTTP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Unicheck::Modules::HTTP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Unicheck-Modules-HTTP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Unicheck-Modules-HTTP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Unicheck-Modules-HTTP>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Unicheck-Modules-HTTP/>

=item * Github

L<https://github.com/uninets/App-Unicheck-Modules-HTTP/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Matthias Krull.

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

1; # End of App::Unicheck::Modules::HTTP

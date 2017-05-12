package APP::REST::ParallelMyUA;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use Time::HiRes qw( time sleep );
use Exporter();
use LWP::Parallel::UserAgent qw(:CALLBACK);

use base qw(LWP::Parallel::UserAgent Exporter);
our @EXPORT = @LWP::Parallel::UserAgent::EXPORT_OK;

$|                    = 1;    #make the pipe hot
$Data::Dumper::Indent = 1;

=head1 NAME

APP::REST::ParallelMyUA - 
 provide a subclassed UserAgent to override on_connect, on_failure and
 on_return methods 

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

#Quick summary of what the module does.
#Perhaps a little code snippet.

use APP::REST::ParallelMyUA;
my $pua = APP::REST::ParallelMyUA->new();


=head1 SUBROUTINES/METHODS

=head2 new

Object Constructor

=cut

sub new {
    my ( $proto, %args ) = @_;
    my $class = ref($proto) || $proto;
    my $self;

    $self = bless $proto->SUPER::new(%args), $class;
    return $self;
}

=head2 on_connect

redefine methods: on_connect gets called whenever we're about to
make a a connection

=cut

sub on_connect {
    my ( $self, $request, $response, $entry ) = @_;

    #print time,"Connecting to ", $request->url, "\n";
    print STDERR ".";
    $entry->{tick}->{start} = time;
}

=head2 on_failure

on_failure gets called whenever a connection fails right away
(either we timed out, or failed to connect to this address before,
or it's a duplicate). Please note that non-connection based
errors, for example requests for non-existant pages, will NOT call
on_failure since the response from the server will be a well
formed HTTP response!

=cut

sub on_failure {
    my ( $self, $request, $response, $entry ) = @_;
    print "Failed to connect to ", $request->url, "\n\t", $response->code, ", ",
      $response->message, "\n"
      if $response;
}

=head2 on_return

on_return gets called whenever a connection (or its callback)
returns EOF (or any other terminating status code available for
callback functions). Please note that on_return gets called for
any successfully terminated HTTP connection! This does not imply
that the response sent from the server is a success!

=cut

sub on_return {
    my ( $self, $request, $response, $entry ) = @_;
    print ".";

    #print time,"Response got from ", $request->url, "\n";

    $entry->{tick}->{end} = time;

    if ( $response->is_success ) {

#print "\n\nWoa! Request to ",$request->url," returned code ", $response->code,
#   ": ", $response->message, "\n";
#print $response->content;
    } else {

#print "\n\nBummer! Request to ",$request->url," returned code ", $response->code,
#   ": ", $response->message, "\n";
#print $response->error_as_HTML;
    }
    return;
}

1;

=head1 AUTHOR

Mithun Radhakrishnan, C<< <rkmithun at cpan.org> >>

=head1 BUGS

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc APP::REST::ParallelMyUA


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Mithun Radhakrishnan.

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

1;    # End of APP::REST::ParallelMyUA

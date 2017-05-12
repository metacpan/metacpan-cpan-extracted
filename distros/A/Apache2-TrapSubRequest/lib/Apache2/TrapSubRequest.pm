package Apache2::TrapSubRequest;

use warnings FATAL => 'all';
use strict;

use mod_perl2 1.999023;

use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::SubRequest  ();
use Apache2::Filter      ();
use Apache2::Connection  ();
use Apache2::Log         ();

use APR::Bucket         ();
use APR::Brigade        ();

use Carp                ();

use Apache2::Const      -compile => qw(OK);
#use APR::Const          -compile => qw(:common);

=head1 NAME

Apache2::TrapSubRequest - Trap a lookup_file/lookup_uri into a scalar

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    # ...
    use Apache2::TrapSubRequest  ();

    sub handler {
        my $r = shift;
        my $subr = $r->lookup_uri('/foo');
        my $data;
        $subr->run_trapped(\$data);
        # ...
        Apache2::OK;
    }

=head1 DESCRIPTION

L<Apache2::TrapSubRequest> is a mixin to L<Apache2::SubRequest> which
enables you to collect the subrequest's response into a scalar
reference. There is only one method, L</run_trapped>, which is
demonstrated in the synopsis.

=head1 FUNCTIONS

=head2 run_trapped (\$data);

Run the output of a subrequest into a scalar reference.

=cut

sub Apache2::SubRequest::run_trapped {
    my ($r, $dataref) = @_;
    Carp::croak('Usage: $subr->run_trapped(\$data)')
        unless ref $dataref eq 'SCALAR';
    $$dataref = '' unless defined $$dataref;
    $r->pnotes(__PACKAGE__, $dataref);
    $r->add_output_filter(\&_filter);
    my $rv = $r->run;
    $rv;
}

sub _filter {
    my ($f, $bb) = @_;
    my $r = $f->r;
    my $dataref = $r->pnotes(__PACKAGE__);
    $bb->flatten(my $string);
    $bb->destroy;
    $$dataref .= $string;
    Apache2::Const::OK;
}

=head1 AUTHOR

Dorian Taylor, C<< <dorian@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache2-trapsubrequest@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License. You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0> .

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

1; # End of Apache2::TrapSubRequest

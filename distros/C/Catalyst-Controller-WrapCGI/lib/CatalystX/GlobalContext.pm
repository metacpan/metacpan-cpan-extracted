package CatalystX::GlobalContext;
our $AUTHORITY = 'cpan:RKITOVER';
$CatalystX::GlobalContext::VERSION = '0.038';
use strict;
use warnings;
use parent 'Exporter';

use Scalar::Util 'weaken';

use vars '$c';
our @EXPORT_OK = '$c';

=head1 NAME

CatalystX::GlobalContext - Export Catalyst Context

=head1 SYNOPSIS

    package MyApp::Controller::Root;

    use CatalystX::GlobalContext ();

    sub auto : Private {
        my ($self, $c) = @_;
        CatalystX::GlobalContext->set_context($c);
        1;
    }

    package Some::Other::Module;

    use CatalystX::GlobalContext '$c';

    ...
    do stuff with $c
    ...

=head1 DESCRIPTION

This module, in combination with L<Catalyst::Controller::WrapCGI> or
L<Catalyst::Controller::CGIBin> is for helping you run legacy mod_perl code in
L<Catalyst>.

You save a copy of $c somewhere at the beginning of the request cycle, and it is
then accessible through an export where you need it.

You can then rip out C<Apache::> type things, and replace them with things based on
C<$c>.

=head1 CLASS METHODS

=head2 CatalystX::GlobalContext->set_context($c)

Saves a weakened reference to the Catalyst context,
which is accessible from other modules as an export.

=cut

sub set_context {
    $c = $_[1];
    weaken $c;
}

=head1 SEE ALSO

L<Catalyst::Controller::CGIBin>, L<Catalyst::Controller::WrapCGI>,
L<Catalyst>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-controller-wrapcgi
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Controller-WrapCGI>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 AUTHOR

Rafael Kitover <rkitover@gmail.com>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2008-2015 Rafael Kitover <rkitover@gmail.com> and
L<Catalyst::Controller::WrapCGI/CONTRIBUTORS>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__PACKAGE__; # End of CatalystX::GlobalContext

# vim: expandtab shiftwidth=4 ts=4 tw=80:

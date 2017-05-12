package Catalyst::Plugin::JavaScript::Console;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Catalyst::Plugin::JavaScript::Console - The great new Catalyst::Plugin::JavaScript::Console!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Catalyst / JavaScript::Console ... /;

    ...

    sub index {
        my ( $self, $c ) = @_;
        $c->console->log( $c->stash );
        $c->console->error( "Not enough data" );
        $c->console->dir_by_id( "some_element_id" );
        ...
    }

    ...

    [% c.console.output %]

=cut

use Moose;
use MRO::Compat;
use JavaScript::Console;
use namespace::autoclean;

extends 'Catalyst::Component';

=head1 METHODS

=over

=item B<console>( $self )

Provides access to $c->console methods.

See also L<JavaScript::Console>.

=cut

sub console {
    my $self = shift;
    $self->{console} ||= JavaScript::Console->new();
    return $self->{console};
}

=item B<prepare_action>( $self, ... )

Prepare to action.

=cut

sub prepare_action {
    my $self = shift;
    $self->{console} = undef;
    return $self->maybe::next::method(@_);
}

=back

=head1 AUTHOR

Akzhan Abdulin, C<< <akzhan.abdulin at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-plugin-javascript-console at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Plugin-JavaScript-Console>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::JavaScript::Console


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-JavaScript-Console>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-JavaScript-Console>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-JavaScript-Console>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-JavaScript-Console/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Akzhan Abdulin.

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

1; # End of Catalyst::Plugin::JavaScript::Console

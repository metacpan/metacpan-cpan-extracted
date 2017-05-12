package App::Docker::Client::Exception;

use 5.16.0;
use strict;
use warnings;

=head1 NAME

App::Docker::Client::Exception - Exception class for App::Docker::Client.

=head1 VERSION

Version 0.010200

=cut

our $VERSION = '0.010200';

=head2 new

Constructor

=cut

sub new {
    my $class = shift;
    my $self  = {@_};
    bless $self, $class;
    return $self;
}

=head2 is_not_fround

=cut

sub is_not_fround   { $_[0]->{code} == 404 ? 1                           : 0 }

=head2 is_confict

=cut

sub is_confict      { $_[0]->{code} == 409 ? 1                           : 0 }

=head2 code

=cut

sub code            { $_[0]->{code} }

=head2 content

=cut

sub content         { $_[0]->{content} }

=head2 content_message

=cut

sub content_message { $_[0]->{content}     ? $_[0]->{content}->{message} : undef }

=head2 message

=cut

sub message         { $_[0]->{message} }

1;    # End of App::Docker::Client::Exception

__END__

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-docker at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Docker-Client>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Docker::Client::Exception
You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Docker-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Docker-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Docker-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Docker/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Mario Zieschang.

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

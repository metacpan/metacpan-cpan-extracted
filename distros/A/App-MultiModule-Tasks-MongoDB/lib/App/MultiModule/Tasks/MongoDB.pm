package App::MultiModule::Tasks::MongoDB;
$App::MultiModule::Tasks::MongoDB::VERSION = '1.142810';

use 5.006;
use strict;
use warnings FATAL => 'all';
use Message::MongoDB;
use Data::Dumper;
use Storable;

use parent 'App::MultiModule::Task';
=head1 NAME

App::MultiModule::Tasks::MongoDB - File following task for App::MultiModule

=cut

=head2 message

=cut

sub message {
    my $self = shift;
    my $message = shift;
    $message = Storable::dclone($message);
    delete $message->{'.ipc_transit_meta'};
    my $method = $message->{mongo_method} || 'update';
    my $mongo = $self->{mongo};
    my $mongo_write = $message;
    my %args = (
        mongo_db => $message->{mongo_db},
        mongo_collection => $message->{mongo_collection},
        mongo_method => $method,
        mongo_search => $message->{mongo_search},
        mongo_write => $message
    );
    $mongo->message(\%args);
}

=head2 set_config

=cut
sub set_config {
    my $self = shift;
    my $config = shift;
    $self->{config} = $config;
    $self->{mongo} = Message::MongoDB->new() unless $self->{mongo};
}

=head1 AUTHOR

Dana M. Diederich, C<< <dana@realms.org> >>

=head1 BUGS

Please report any bugs or feature requests through L<https://github.com/dana/App-MultiModule-Tasks-MongoDB/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.
    perldoc App::MultiModule::Tasks::MongoDB


You can also look for information at:

=over 4

=item * Report bugs here:

L<https://github.com/dana/App-MultiModule-Tasks-MongoDB/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-MultiModule-Tasks-MongoDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-MultiModule-Tasks-MongoDB>

=item * Search CPAN
L<https://metacpan.org/module/App::MultiModule::Tasks::MongoDB>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Dana M. Diederich.

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

1; # End of App::MultiModule::Tasks::MongoDB


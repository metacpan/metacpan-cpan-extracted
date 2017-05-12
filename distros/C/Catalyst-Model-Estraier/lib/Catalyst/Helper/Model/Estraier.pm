package Catalyst::Helper::Model::Estraier;

use strict;
use warnings;

sub mk_compclass {
    my($self, $helper, $url, $user, $passwd) = @_;
    $helper->{url}            = $url    || 'http://localhost:1978/node/test';
    $helper->{user}           = $user   || '';
    $helper->{passwd}         = $passwd || '';
    $helper->{croak_on_error} = 1;
    $helper->render_file('compclass', $helper->{file});
}

1;

=head1 NAME

Catalyst::Helper::Model::Estraier - Helper for Hyper Estraier models

=head1 SYNOPSIS

    $ perl script/myapp_create.pl model Search Estraier \
      http://localhost:1978/node/test admin admin

=head1 DESCRIPTION

Helper for the L<Catalyst> Estraier model.
See L<Catalyst::Model::Estraier>.

=head1 METHODS

=head2 mk_compclass

Makes the Hyper Estraier model class.

=head1 SEE ALSO

L<Catalyst::Model::Estraier>

=head1 AUTHOR

Takeru INOUE, E<lt>takeru.inoue _ gmail.comE<gt>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

__DATA__

=begin pod_to_ignore

__compclass__
package [% class %];

use strict;
use warnings;
use base qw(Catalyst::Model::Estraier);

__PACKAGE__->config(
    url            => '[% url %]',
    user           => '[% user %]',
    passwd         => '[% passwd %]',
    croak_on_error => 1,
);

=head1 NAME

[% class %] - Hyper Estraier Catalyst model component

=head1 SYNOPSIS

See L<[% app %]>.

=head1 DESCRIPTION

Hyper Estraier Catalyst model component.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

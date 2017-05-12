package Catalyst::Model::Estraier;

use warnings;
use strict;

use version; our $VERSION = qv('0.0.6');

use Search::Estraier;

use base qw(Catalyst::Model);

__PACKAGE__->mk_classdata('_node');

sub ACCEPT_CONTEXT {
    my($self) = @_;
    return $self->_node if $self->_node;
    my %args = map { defined $self->{$_} ? ($_ => $self->{$_}) : () }
                 qw(url user passwd create label debug croak_on_error);
    $self->_node( Search::Estraier::Node->new(%args) );
}

1;

__END__

=head1 NAME

Catalyst::Model::Estraier - Hyper Estraier model class for Catalyst


=head1 SYNOPSIS

    # Use the Catalyst helper
    $ perl script/myapp_create.pl model Search Estraier \
      http://localhost:1978/node/test admin admin

    # Or, in lib/MyApp/Model/Search.pm
    package MyApp::Model::Search;

    use base qw(Catalyst::Model::Estraier);

    __PACKAGE__->config(
        url            => 'http://localhost:1978/node/test',
        user           => 'admin',
        passwd         => 'admin',
        croak_on_error => 1,
    );

    1;

    # Then, in your controller
    my $node = $c->model('Search'); # Search::Estraier::Node
    my $rs = $node->search($cond, 0);

=head1 DESCRIPTION

This is the L<Search::Estraier> model class for Catalyst.  It is nothing more
than a simple wrapper for L<Search::Estraier>.

Please refer to the L<Search::Estraier> documentation for information on what
else is available.

=head1 CONFIGURATION

The following configuration parameters are supported:

=over 4

=item * C<url>

URL to a Hyper Estraier node

=item * C<user>

specify username for node server authentication

=item * C<passwd>

password for authentication

=item * C<create>

create node if it doesn't exists

=item * C<label>

optional label for new node if create is used

=item * C<debug>

dumps a lot of debugging output

=item * C<croak_on_error>

very helpful during development. It will croak on all errors instead
of silently returning -1 (which is convention of Hyper Estraier API
in other languages).

=back

=head1 METHODS

=head2 ACCEPT_CONTEXT

Create a Hyper Estraier node using the current configuration and return it.
This method is automatically called when you use e.g. C<< $c->model('Search') >>.

=head2 _node

Accessor for a Hyper Estraier node object.
This is a class method.

=head1 SEE ALSO

L<Catalyst::Helper::Model::Estraier>
L<Search::Estraier>

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

package Catalyst::Helper::Model::SWISH;

use strict;
use File::Spec;

=head1 NAME

Catalyst::Helper::Model::SWISH - Helper for Catalyst::Model::SWISH

=head1 SYNOPSIS

    script/create.pl model SWISH SWISH index

=head1 DESCRIPTION

Helper for SWISH Model.

=head2 METHODS

=over 4

=item mk_compclass

Makes a SWISH Model class for you.

=item mk_comptest

Makes tests.

=back 

=cut

sub mk_compclass {
    my ( $self, $helper, $index ) = @_;
    $helper->{index} = $index || '';
    my $file = $helper->{file};
    $helper->render_file( 'swishclass', $file );
}

sub mk_comptest {
    my ( $self, $helper ) = @_;
    my $test = $helper->{test};
    $helper->render_file( 'swishtest', $test );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Catalyst::Model::SWISH>

=head1 AUTHOR

Peter Karman <perl@peknet.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
__DATA__

=begin pod_to_ignore

__swishclass__
package [% class %];

use strict;
use base 'Catalyst::Model::SWISH';

[% IF index %]
__PACKAGE__->config(
    indexes           => [% index %]
);
[% END %]

=head1 NAME

[% class %] - Swish-e Model Class

=head1 SYNOPSIS

 # in your Controller
 sub search : Local
 {
    my ($self, $c) = @_;

    my ($pager, $results) = $c->model('SWISH')->search(
                                 $c,
                                 query     => $c->request->param('q'),
                                 page      => $c->request->param('page') || 0,
                                 page_size => $c->request->param('page_size')
                                   || $c->config->{search}->{page_size}
    );
    $c->stash->{search}->{results} = $results;
    $c->stash->{search}->{pager}   = $pager;
 }


=head1 DESCRIPTION

[% class %] provides a simple interface to Swish-e full-text search indexes.

=head1 AUTHOR

you@you.org

=head1 LICENSE

This library is free software . You may redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
__swishtest__
use Test::More tests => 2;
use_ok( Catalyst::Test, '[% app %]' );
use_ok('[% class %]');

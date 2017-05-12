package Catalyst::Helper::View::RRDGraph;
{
  $Catalyst::Helper::View::RRDGraph::VERSION = '0.10';
}

use strict;
use warnings;

=head1 NAME

Catalyst::Helper::View::RRDGraph - Helper for RRDGraph Views

=head1 SYNOPSIS

    script/create.pl view RRDGraph RRDGraph

=head1 DESCRIPTION

Helper for RRDGraph Views.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Jose Luis Martinez Torres, C<jlmartinez@capside.com>

This helper was based, to not say ripped off of Catalyst::View::TT

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::RRDGraph';

__PACKAGE__->config();

=head1 NAME

[% class %] - RRDGraph View for [% app %]

=head1 DESCRIPTION

RRDGraph View for [% app %]. 

=head1 AUTHOR

[% author %]

=head1 SEE ALSO

L<[% app %]>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

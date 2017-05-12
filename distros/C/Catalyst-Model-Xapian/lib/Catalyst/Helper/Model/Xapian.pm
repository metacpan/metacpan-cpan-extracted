package Catalyst::Helper::Model::Xapian;

use strict;
use File::Spec;

=head1 NAME

Catalyst::Helper::Model::Xapian - Helper for Xapian Model

=head1 SYNOPSIS

    script/create.pl model Xapian Xapian index

=head1 DESCRIPTION

Helper for Xapian Model.

=head2 METHODS

=over 4

=item mk_compclass

Makes a Xapian Model class for you.

=item mk_comptest

Makes tests.

=back 

=cut

sub mk_compclass {
    my ( $self, $helper, $index ) = @_;
    $helper->{index} = $index || '';
    my $file = $helper->{file};
    $helper->render_file( 'xapianclass', $file );
}

sub mk_comptest {
    my ( $self, $helper ) = @_;
    my $test = $helper->{test};
    $helper->render_file( 'xapiantest', $test );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Catalyst::Model::Xapian>

=head1 AUTHOR

Marcus Ramberg <mramberg@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
__DATA__

=begin pod_to_ignore

__xapianclass__
package [% class %];

use strict;
use base 'Catalyst::Model::Xapian';

[% IF index %]
__PACKAGE__->config(
    index           => '[% index %]'
);
[% END %]

=head1 NAME

[% class %] - Xapian Model Component

=head1 SYNOPSIS

    Very simple to use

=head1 DESCRIPTION

Very nice component.

=head1 AUTHOR

Clever guy

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
__xapiantest__
use Test::More tests => 2;
use_ok( Catalyst::Test, '[% app %]' );
use_ok('[% class %]');

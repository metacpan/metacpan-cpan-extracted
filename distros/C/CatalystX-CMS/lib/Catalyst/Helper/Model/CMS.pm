package Catalyst::Helper::Model::CMS;

use strict;
use File::Spec;

=head1 NAME

Catalyst::Helper::Model::CMS - Helper for CatalystX::CMS::Model

=head1 SYNOPSIS

 script/create.pl model CMS CMS

=head1 DESCRIPTION

Helper for CatalystX::CMS::Model.

=head2 METHODS

=over 4

=item mk_compclass

Makes a CatalystX::CMS::Model class for you.

=item mk_comptest

Makes tests.

=back 

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    $helper->render_file( 'cmsclass', $helper->{file} );
}

sub mk_comptest {
    my ( $self, $helper ) = @_;
    $helper->render_file( 'cmstest', $helper->{test} );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<CatalystX::CMS::Model>

=head1 AUTHOR

Peter Karman <karman@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
__DATA__

=begin pod_to_ignore

__cmsclass__
package [% class %];

use strict;
use base 'CatalystX::CMS::Model';

=head1 NAME

[% class %] - CMS model class

=head1 SYNOPSIS

 # see CatalystX::CMS::Model

=head1 DESCRIPTION

[% class %] provides a default CMS model.

=head1 AUTHOR

you@you.org

=head1 LICENSE

This library is free software . You may redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
__cmstest__
use Test::More tests => 2;
use_ok( Catalyst::Test, '[% app %]' );
use_ok('[% class %]');

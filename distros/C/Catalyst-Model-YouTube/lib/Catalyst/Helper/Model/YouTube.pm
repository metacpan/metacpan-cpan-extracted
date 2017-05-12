package Catalyst::Helper::Model::YouTube;

use strict;
use File::Spec;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Helper::Model::YouTube - Helper for YouTube Models

=head1 SYNOPSIS

    script/create.pl model YouTube YouTube dev_id

=head1 DESCRIPTION

Helper for YouTube Models

=head2 METHODS

=over 4

=item mk_compclass

Reads the dev_id field and makes a main model class

=item mk_comptest

Makes tests for the DBI Model.

=back 

=cut

sub mk_compclass {
    my ( $self, $helper, $dev_id ) = @_;
    $helper->{dev_id} = $dev_id  || '';
    my $file = $helper->{file};
    $helper->render_file( 'youtubeclass', $file );
    return 1;
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

J. Shirley C<jshirley@gmail.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__youtubeclass__
package [% class %];

use strict;
use base 'Catalyst::Model::YouTube';

__PACKAGE__->config(
    dev_id      => '[% dev_id %]',
    options     => {},
);

=head1 NAME

[% class %] - YouTube Model Class

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

YouTube Model Class.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

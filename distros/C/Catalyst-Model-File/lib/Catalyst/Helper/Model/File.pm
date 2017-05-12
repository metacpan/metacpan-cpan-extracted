package Catalyst::Helper::Model::File;

use strict;
use warnings;
use Carp;

=head1 NAME

Catalyst::Helper::Model::File - Helper for File based Models

=head1 SYNOPSIS

  script/create.pl model Foo File [root_storage_directory]

  Where:
    Foo is the short name for the Model class being generated
    root_storage_directory is the (full) path of where to store files

=head1 TYPICAL EXAMPLES

  script/myapp_create.pl model Foo File var/file_storage 


=head1 DESCRIPTION

Helper for the File base storage Model

=head1 METHODS

=head2 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper, $path) = @_;

    $helper->{root_dir} = $path or die "root_dir config option must be specified for this model\n";

    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

General Catalyst Stuff:

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Catalyst>,

Stuff related to this Model:

L<Catalyst::Model::File>

=head1 AUTHOR

Ash Berlin, C<ash@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__DATA__

=begin pod_to_ignore

__compclass__
package [% class %];

use strict;
use base 'Catalyst::Model::File';

__PACKAGE__->config(
    root_dir => '[% root_dir %]',
);

=head1 NAME

[% class %] - Catalyst File Model

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

L<Catalyst::Model::File> Model storing files under
L<[% directory %]>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

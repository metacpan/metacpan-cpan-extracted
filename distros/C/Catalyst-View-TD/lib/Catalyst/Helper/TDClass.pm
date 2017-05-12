package Catalyst::Helper::TDClass;

use strict;
use warnings;

our $VERSION = '0.12';

=head1 Name

Catalyst::Helper::TDClass - Helper for creating TD Template classes

=head1 Synopsis

    ./script/myapp_create.pl TDClass HTML

=head1 Description

Helper for creating TD Template classes.

=head2 Methods

=head3 mk_comptest

Creates a test script for the view class.

=cut

=head3 mk_stuff

Creates a template class.

=cut

sub mk_stuff {
    my ( $self, $helper, $name ) = @_;

    $name ||= $helper->{name};
    my $class = "$helper->{app}::Templates::$name";

    my @path = split /::/, $class;
    my $file = pop @path;
    my $path = File::Spec->catdir( $helper->{base}, 'lib', @path );
    $helper->mk_dir($path);
    $file = File::Spec->catfile( $path, "$file.pm" );
    local $helper->{file} = $file;
    $helper->render_file('tmpl_class', $file, {
        class    => $class,
        name     => $name,
        scaffold => $name !~ /::/,
    });
}

=head1 SEE ALSO

L<Catalyst::View::TD>, L<Catalyst::Helper::View::TD>

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 License

This library is free software. You can redistribute it and/or modify it under
the same terms as perl itself.

=begin comment

=cut

1;

__DATA__

__tmpl_class__
package [% class %];

use strict;
use warnings;
use parent 'Template::Declare::Catalyst';
use Template::Declare::Tags;
[% IF scaffold -%]

# See Template::Declare docs for details on creating templates, which look
# something like this.
# template hello => sub {
#     my ($self, $vars) = @_;
#     html {
#         head { title { "Hello, $vars->{user}" } };
#         body { h1    { "Hello, $vars->{user}" } };
#     };
# };
[% END -%]

=head1 NAME

[% class %] - [% name %] templates for [% app %]

=head1 DESCRIPTION

[% name %] templates for [% app %].

=head1 SEE ALSO

=over

=item L<Template::Declare>

[% IF vclass %]=item L<[% vclass %]>

[% END %]=item L<[% app %]>

=item L<Catalyst::View::TD>

=back

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

__the_end__

=end comment

=cut


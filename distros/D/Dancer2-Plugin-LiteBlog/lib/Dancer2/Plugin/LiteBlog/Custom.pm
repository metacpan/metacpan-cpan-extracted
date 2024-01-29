package Dancer2::Plugin::LiteBlog::Custom;

=head1 NAME

Dancer2::Plugin::LiteBlog::Custom - include html fragments as widgets

=head1 DESCRIPTION

This widget allows you to inject arbitrary HTML fragments in your LiteBlog homepage easily.
This way you can add any HTML/CSS/JavaScript code that you want without hacking around 
the code.

=head1 CONFIGURATION

The Widget looks for its configuration under the C<liteblog> entry of the
Dancer2 application.


    liteblog:
      ...
      widgets:
        - name: custom
          params: 
            root: directory-where-to-look-for-source
            source: path-to-some.html

=cut

use Moo;
use Carp 'croak';
use File::Slurp 'read_file';
use Cwd 'abs_path';

extends 'Dancer2::Plugin::LiteBlog::Widget';

sub has_routes { 0 }

=head1 ATTRIBUTES

=head2 root

Inherited from L<Dancer2::Plugin::LiteBlog::Widget>, it specifies the root
directory for the widget, where the C<source> HTML file will be looked for.

=head2 source

The `source` attribute specifies the path to the HTML file relative to the
`root` directory. 

=cut

has source => (
    is => 'ro',
    required => 1,
);

=head2 elements

This attribute lazily loads and returns the HTML content of the 
source file.

=cut

has elements => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;

        my $html_file = File::Spec->catfile($self->root, $self->source);
        if (! -e $html_file) {
            croak "Missing file: $html_file";
        }

        my $html = read_file(abs_path($html_file), { 
            binmode => ':encoding(UTF-8)' });

        return [$html];
    },
);

1;

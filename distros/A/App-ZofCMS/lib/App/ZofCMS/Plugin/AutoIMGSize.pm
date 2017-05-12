package App::ZofCMS::Plugin::AutoIMGSize;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use HTML::Entities;
use Image::Size (qw/html_imgsize/);

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;

    return
        unless $template->{plug_auto_img_size}
            or $config->conf->{plug_auto_img_size};

    my %conf = (
        t_prefix  => 'img_',
        xhtml   => 0,
        %{ delete $config->conf->{plug_auto_img_size} || {} },
        %{ delete $template->{plug_auto_img_size}     || {} },
    );

    if ( ref $conf{imgs} eq 'ARRAY' ) {
        $conf{imgs} = {
            map +( $_ => $_ ), @{ $conf{imgs} }
        };
    }

    keys %{ $conf{imgs} };
    while ( my ( $name, $file ) = each %{ $conf{imgs} } ) {
        my $extra = '';
        if ( ref $file eq 'HASH' ) {
            ( $file, $extra ) = %$file;
        }
        unless ( -e $file ) {
            $template->{t}{ $conf{t_prefix} . $name } = 'ERROR: File not found';
            next;
        }

        $extra = ' alt=""'
            unless length $extra;

        my $size = html_imgsize $file;
        encode_entities $file;

        $template->{t}{ $conf{t_prefix} . $name }
        = qq|<img src="/$file" $size$extra| . ( $conf{xhtml} ? '/>' : '>' );
    }

}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::AutoIMGSize - automatically get image sizes and generate appropriate <img> tags

=head1 SYNOPSIS

In your Main Config or ZofCMS Template file:

    plugins => [ qw/AutoIMGSize/ ],
    plug_auto_img_size => {
        imgs => {
            logo    => 'pics/top_logo.png'
            kitteh  => 'pics/kitteh.jpg',
            blah    => { 'somewhere/there.jpg' => ' class="foo"' },
        },
    },

In your L<HTML::Template> template:

    Logo: <tmpl_var name="img_logo">
    Kitteh: <tmpl_var name="img_kitteh">
    blah: <tmpl_var name="img_blah">

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS>. It provides means to generate HTML
C<< <img ... > >> tags with automatic image size generation, i.e. the plugin gets the size
of the image from the file. Personally, I use it in templates where the size of the
image is unknown, if the image is static and you can physically type in the address, it would
be saner to do so.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 MAIN CONFIG FILE OR ZofCMS TEMPLATE KEYS

=head2 C<plugins>

    plugins => [ qw/AutoIMGSize/ ],

You would obvisouly want to add the plugin to the list of plugins to run. Play with priorities
if you are loading image paths dynamically.

=head2 C<plug_auto_img_size>

    plug_auto_img_size => {
        xhtml       => 1,
        t_prefix    => 'img_',
        imgs => {
            logo    => 'pics/logo.png',
            kitteh  => { 'pics/kitteh.jpg' => ' class="kitteh' },
        },
    },

The C<plug_auto_img_size> first-level Main Config file or ZofCMS Template file is what
makes the plugin run. If you specify this key in both ZofCMS Template and Main Config file
then keys set in ZofCMS Template will override the ones set in Main Config file. B<Note:>
the C<imgs> key will be completely overridden.

The key takes a hashref as a value. Possible keys/values of that hashref are as follows:

=head3 C<imgs>

    imgs => [ qw/foo.jpg bar.jpg/ ],
    #same as
    imgs => {
        'foo.jpg' => 'foo.jpg',
        'bar.jpg' => 'bar.jpg',
    },

B<Mandatory>. The C<imgs> key takes either an arrayref or a hashref as a value. If the
value is an arrayref, it will be converted to a hashref where keys and values are the same.

The key in the hashref specifies the "name" of the key in C<{t}> ZofCMS Template special key to
which the C<t_prefix> (see below) will be prepended. The value specifies the image
filename relative to ZofCMS C<index.pl> file (root dir of your website, basically). The value
of each key can be either a string or a hashref. If it's a string, it will be taken as a
filename of the image. If it is a hashref it must contain only one key/value pair; the key
of that hashref will be taken as a filename of the image and the value will be taken as
extra HTML attributes to insert into C<< <img> >> tag. Note that the value, in this case,
should begin with a space as to not merge with the width/height attributes. Note 2: unless
the value is a hashref, the C<alt=""> attribute will be set to an empty string; otherwise
you must include it in "extra" html attributes. Here are a few
examples (which assume that C<t_prefix> (see below) is set to its default value: C<img_>;
and size of the image is 500px x 500px):

    # ZofCMS template:
    imgs => [ qw/foo.jpg/ ]

    # HTML::Template template:
    <tmpl_var name="img_foo.jpg">

    # Resulting HTML code:
    <img src="/foo.jpg" width="500" height="500" alt="">

B<Note:> that image C<src=""> attribute is made relative to root path of your website (i.e.
starts with a slash C</> character).

    # ZofCMS tempalte:
    imgs => { foo => 'pics/foo.jpg' },

    # HTML::Template template:
    <tmpl_var name="img_foo">

    # Resulting HTML code:
    <img src="/pics/foo.jpg" width="500" height="500" alt="">

Now with custom attributes (note the leading space before C<alt=""> attribute):

    # ZofCMS template:
    imgs => { foo => { 'pics/foo.jpg' => ' alt="foos" class="foos"' } }

    # HTML::Template template:
    <tmpl_var name="img_foo">

    # Resulting HTML code:
    <img src="/pics/foo.jpg" width="500" height="500" alt="foos" class="foos">

Note: if plugin cannot find your image file then the C<< <img> >> tag will be replaced with
C<ERROR: Not found>.

=head3 C<t_prefix>

    t_prefix => 'img_',

B<Optional>. The C<t_prefix> takes a string as a value, this string will be prepended to
the "name" of your images in C<{t}> ZofCMS Template special key. In other words, if
you set C<< t_prefix => 'img_', imgs => { foo => 'pics/bar.jpg' } >>, then in your
L<HTML::Template> template you'd insert your image with C<< <tmpl_var name="img_foo"> >>.
B<Defaults to:> C<img_> (note the underscore (C<_>) at the end)

=head3 C<xhtml>

    xhtml => 1,

B<Optional>. When set to a true value the C<< <img> >> tag will be closed with C<< /> >>.
When set to a false value the C<< <img> >> tag will be closed with C<< > >>. B<Default to:>
C<0> (false)

=head1 DEPENDENCIES

The module relies on L<Image::Size> to get image sizes.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
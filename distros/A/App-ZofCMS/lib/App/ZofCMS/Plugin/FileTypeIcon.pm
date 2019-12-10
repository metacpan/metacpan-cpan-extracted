package App::ZofCMS::Plugin::FileTypeIcon;

use warnings;
use strict;
use File::Spec;

our $VERSION = '1.001008'; # VERSION

use base 'App::ZofCMS::Plugin::Base';

sub _key { 'plug_file_type_icon' }
sub _defaults {
    return (
        resource    => 'pics/fileicons/',
        prefix      => 'fileicon_',
        as_arrayref => 0,
        only_path   => 0,
        icon_width  => 16,
        icon_height => 16,
        xhtml       => 0,
    );
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    return
        unless defined $conf->{files};

    unless ( ref $conf->{files} eq 'ARRAY' ) {
        $conf->{files} = [ $conf->{files} ];
    }

    my $counter = 0;
    my $tag_end = $conf->{xhtml} ? '/' : '';
    for ( @{ $conf->{files} } ) {
        my $key_name;
        my $file = $_;
        if ( ref eq 'CODE' ) {
            $_ = $_->( $t, $q, $config );
        }

        if ( ref eq 'HASH' ) {
            ( $file, $key_name ) = %$_;
        }
        else {
            $key_name = "$conf->{prefix}$counter";
            $counter++;
        }

        my ( $icon_file, $img_alt ) = make_icon_name($conf->{resource}, $file);

        my $value = $conf->{only_path}
        ? $icon_file
        : qq|<img class="file_type_icon" src="$icon_file" width="$conf->{icon_width}" height="$conf->{icon_height}" alt="$img_alt" title="$img_alt"$tag_end>|;

        if ( $conf->{as_arrayref} ) {
            push @{ $t->{t}{ $conf->{prefix} } }, $value;
        }
        else {
            $t->{t}{ $key_name } = $value;
        }
    }

    if ( ref $conf->{code_after} eq 'CODE' ) {
        $conf->{code_after}->( $t, $q, $config );
    }
}

sub make_icon_name {
    my ( $resource, $file ) = @_;
    my ( $ext ) = $file =~ /[.]([^.]+)$/;
    $ext = 'unknown'
        unless defined $ext;

    my $icon_file = File::Spec->catfile( $resource, $ext . '.png' );
    if ( -e $icon_file ) {
        return ( $icon_file, uc($ext) . ' file' );
    }
    else {
        $ext = 'unknown';
        $icon_file = File::Spec->catfile( $resource, $ext . '.png' );
        return ( $icon_file, 'Unknown file format' );
    }
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::FileTypeIcon - present users with pretty icons depending on file type

=head1 SYNOPSIS

# first of all, get icon images (they are also in the examples/ dir of this distro)

    wget http://zoffix.com/new/fileicons.tar.gz;tar -xvvf fileicons.tar.gz;rm fileicons.tar.gz;

In your ZofCMS Template or Main Config File:

    plug_file_type_icon => {
        files => [  # mandatory
            qw/ foo.png bar.doc beer.pdf /,
            sub {
                my ( $t, $q, $conf ) = @_;
                return 'meow.wmv';
            },
        ],
        # all the defaults for reference:
        resource    => 'pics/fileicons/',
        prefix      => 'fileicon_',
        as_arrayref => 0, # put all files into an arrayref at $t->{t}{ $prefix }
        only_path   => 0, # i.e. do not generate the <img> element
        icon_width  => 16,
        icon_height => 16,
        code_after  => sub {
            my ( $t, $q, $conf ) = @_;
            die "Weeee";
        },
        xhtml       => 0,
    },

In your L<HTML::Template> file:

    <tmpl_var name='fileicon_0'>
    <tmpl_var name='fileicon_1'>
    <tmpl_var name='fileicon_2'>
    <tmpl_var name='fileicon_3'>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides a method to show pretty little icons
that vary depending on the extension of the file (which is just a string as far as the module
is concerned).

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and
L<App::ZofCMS::Template>

=head1 GETTING THE IMAGES FOR THE ICONS

There are 69 icons plus the "unknown file" icon in an archive that is in examples/ directory
of this distribution. You can also get it from my website:

    wget http://zoffix.com/new/fileicons.tar.gz;
    tar -xvvf fileicons.tar.gz;
    rm fileicons.tar.gz;

As well as the original website from where I got them:
L<http://www.splitbrain.org/projects/file_icons>

Alternatively, you may want to draw your own icons; in that case, the filenames for the icons
are made out as C<$lowercase_filetype_extension.png>.
If you draw some icons yourself and would like to share, feel free to email them to me
at C<zoffix@cpan.org>.

These images would obviously need to be placed in web-accessible directory on your website.

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [ qw/FileTypeIcon/ ],

You obviously need to include the plugin in the list of plugins to execute. You're likely
to use this plugin with some other plugins, so make sure to get priority right.

=head2 C<plug_file_type_icon>

    plug_file_type_icon => {
        files => [  # mandatory
            qw/ foo.png bar.doc beer.pdf /,
            sub {
                my ( $t, $q, $conf ) = @_;
                return 'meow.wmv';
            },
        ],
        # all the defaults for reference:
        resource    => 'pics/fileicons/',
        prefix      => 'fileicon_',
        as_arrayref => 0, # put all files into an arrayref at $t->{t}{ $prefix }
        only_path   => 0, # i.e. do not generate the <img> element
        icon_width  => 16,
        icon_height => 16,
        code_after  => sub {
            my ( $t, $q, $conf ) = @_;
            die "Weeee";
        },
        xhtml       => 0,
    },

    # or set config via a subref
    plug_file_type_icon => sub {
        my ( $t, $q, $config ) = @_;
        return {
            files => [
                qw/ foo.png bar.doc beer.pdf /,
            ],
        };
    },

Plugin won't run if C<plug_file_type_icon> is not set or its C<files> key does not contain
any files. The C<plug_file_type_icon> first-level key takes a hashref or a subref as a value. If subref is specified,
its return value will be assigned to C<plug_file_type_icon> as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object. The
keys of this hashref can be set in either ZofCMS Template or Main Config Files; keys that are
set in both files will take their values from ZofCMS Template file. The following keys/values
are valid in C<plug_file_type_icon>:

=head3 C<files>

    files => [
        qw/ foo.png bar.doc beer.pdf /,
        { 'beer.doc' => 'doc_file' },
        sub {
            my ( $t, $q, $conf ) = @_;
            return 'meow.wmv';
        },
    ],

B<Mandatory>. The C<files> key takes either an arrayref, a subref or a hashref as a value.
If its value is B<NOT> an arrayref, then it will be converted to an arrayref with just one
element - the original value.

The elements of C<files> arrayref can be strings, hashrefs or subrefs. If the value is a
subref, the sub will be executed and its return value will replace the subref. The
C<@_> of the sub will contain C<$t, $q, $conf> (in that order) where C<$t> is ZofCMS Template
hashref, C<$q> is a hashref of query parameters and C<$conf> is L<App::ZofCMS::Config> object.

If the element is a hashref, it must contain only one key/value pair and the key will be
treated as a filename to process and the value will become the name of the key in C<t> ZofCMS
special key (see C<prefix> key below). If the element is a regular string, then it will be
treated as a filename to process.

=head3 C<resource>

    resource => 'pics/fileicons/',

B<Optional>. Specifies the path to directory with icon images. Must be relative to C<index.pl>
file and web-accessible, as this path will be used in generating path/filenames to the icons.
B<Defaults to:> C<pics/fileicons/>

=head3 C<prefix>

    prefix => 'fileicon_',

B<Optional>. When the plugin generates path to the icon or the C<< <img> >> element, it
will stick it into C<t> ZofCMS special key. The C<prefix> key takes a string as a value and
specifies the prefix to use for keys in C<t> ZofCMS special key. If C<as_arrayref> key
(see below) is set to a true value, then C<prefix> will specify the name of the key, in
C<t> ZofCMS special key where to store that arrayref. When the element of C<files> arrayref
is a hashref, the value of the only key in that hashref will become the name of the
key in C<t> special key B<WITHOUT> the C<prefix>; otherwise, the name will be constructed
by using C<prefix> and a counter; the elements of C<files> arrayref that are hashrefs do
not increase that counter. B<Defaults to:> C<fileicon_> (note that underscore at the end)

=head3 C<as_arrayref>

    as_arrayref => 0,

B<Optional>. Takes either true or false values.
When set to a true value, the plugin will create an arrayref of generated
C<< <img> >> elements (or just paths) and stick it in C<t> special key under C<prefix> (see above) key. B<Defaults to:> C<0>

=head3 C<only_path>

    only_path   => 0,

B<Optional>. Takes either true or false values. When set to a true value, the plugin will
not generate the code for C<< <img> >> elements, but instead it will only provide paths
to appropriate icon image. B<Defaults to:> C<0>

=head3 C<icon_width> and C<icon_height>

    icon_width  => 16,
    icon_height => 16,

B<Optional>. All the icon images to which I referred you above are sized 16px x 16px. If you
are creating your own icons, use C<icon_width> and C<icon_height> keys to set proper
dimensions. You cannot set different sizes for individual icons, but you can use
C<Image::Size> in the C<code_after> sub (see below). B<Defaults to:> C<16> (for both)

=head3 C<code_after>

    code_after => sub {
        my ( $t, $q, $conf ) = @_;
        die "Weeee";
    },

B<Optional>. Takes a subref as a value, this subref will be run after all filenames in
C<files> arrayref have been processed. The C<@_> will contain (in that order) C<$t, $q, $conf>
where C<$t> is ZofCMS Template hashref, C<$q> is hashref of query parameters and
C<$conf> is L<App::ZofCMS::Config> object. B<By defaults:> is not specified.

=head3 C<xhtml>

    xhtml => 0,

B<Optional>. If you wish to close C<< <img> >> elements as to when you're writing XHTML, then
set C<xhtml> argument to a true value. B<Defaults to:> C<0>

=head1 GENERATED HTML CODE

The plugin generates the following HTML code:

<img class="file_type_icon" src="pics/fileicons/png.png" width="16" height="16" alt="PNG file" title="PNG file">

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
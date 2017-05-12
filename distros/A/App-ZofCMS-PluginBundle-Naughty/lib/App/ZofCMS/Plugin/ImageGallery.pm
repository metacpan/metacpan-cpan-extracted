package App::ZofCMS::Plugin::ImageGallery;

use warnings;
use strict;

our $VERSION = '1.001002'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use HTML::Template;
use Image::Size;
use Image::Resize;
use File::Spec;
use File::Copy;
use DBI;
use HTML::Entities;

sub _key { 'plug_image_gallery' }
sub _defaults {
    return (
        # dsn             => "DBI:mysql:database=test;host=localhost",
        user            => '',
        pass            => '',
        opt             => { RaiseError => 1, AutoCommit => 1 },
        table           => 'photos',
        photo_dir       => 'photos/',
        filename        => '[:rand:]',
        thumb_dir       => 'photos/thumbs/',
        create_table    => 0,
        t_name          => 'plug_image_gallery',
        no_form         => 1,
        no_list         => 0,
        no_thumb_desc   => 0,
        allow_edit      => 0,
        thumb_size      => { 200, 200 },
        # photo_size      => [ 600, 600 ],
        has_view        => 1,
        want_lightbox   => 0,
        lightbox_rel    => 'lightbox',
        lightbox_desc   => 1,
    );
}

sub _do {
    my ( $self, $conf, $template, $query, $config ) = @_;

    return
        if $conf->{no_form}
            and $conf->{no_list};

    $self->conf( $conf );
    $self->template( $template );
    $self->query( $query );
    $self->config( $config );

    my $dbh = DBI->connect_cached(
        @$conf{ qw/dsn user pass opt/ },
    );
    $self->dbh( $dbh );

    if ( $conf->{create_table} ) {
        $dbh->do(
            "CREATE TABLE $conf->{table} (
                photo        TEXT,
                width        SMALLINT,
                height       SMALLINT,
                thumb_width  SMALLINT,
                thumb_height SMALLINT,
                description  TEXT,
                time         VARCHAR(10),
                id           TEXT
            );"
        );
    }

    if ( $conf->{filename} eq '[:rand:]' ) {
        {
            $conf->{filename} = rand() . time() . rand();
            $conf->{filename} =~ tr/.//d;
            redo
                if -e File::Spec->catfile( $conf->{photo_dir}, $conf->{filename} )
                    or -e File::Spec->catfile( $conf->{thumb_dir}, $conf->{filename} );
        }
    }

    my %t_name_for = (
        map +( $_ => $conf->{t_name} . "_$_" ),
            qw/form list/,
    );
    unless ( $conf->{no_form} ) {
        my $t = HTML::Template->new_scalar_ref( \ _form_template() );

        if ( defined $query->{plug_image_gallery_action}
            and $query->{plug_image_gallery_action} eq 'Edit'
        ) {
            my $entry = $dbh->selectall_arrayref(
                "SELECT id, description FROM $conf->{table} WHERE id = ?",
                { Slice => {} },
                $query->{plug_image_gallery_id},
            ) || [{}];

            $query->{plug_image_gallery_description} = $entry->[0]{description};
            $t->param(
                is_edit => 1,
                id      => $entry->[0]{id},
            );
        }

        if ( defined $query->{plug_image_gallery_action}
            and $query->{plug_image_gallery_action} eq 'Delete'
        ) {
            my $entry = $dbh->selectall_arrayref(
                "SELECT photo FROM $conf->{table} WHERE id = ?",
                { Slice => {} },
                $query->{plug_image_gallery_id},
            ) || [{}];

            my $file = $entry->[0]{photo};
            if ( defined $file ) {
                unlink File::Spec->catfile( $conf->{photo_dir}, $file );
                unlink File::Spec->catfile( $conf->{thumb_dir}, $file );
            }

            $dbh->do(
                "DELETE FROM $conf->{table} WHERE id = ?",
                undef,
                $query->{plug_image_gallery_id},
            );
        }

        $t->param(
            success_href => "/index.pl?page=$query->{page}&dir=$query->{dir}",
            map +( $_ => $query->{$_} ),
                qw/page dir plug_image_gallery_description/,
        );

        $self->_process_form( $t )
            if ( (
                        defined $query->{plug_image_gallery_file}
                        and length $query->{plug_image_gallery_file}
                    ) or (
                        defined $query->{plug_image_gallery_id}
                        and length $query->{plug_image_gallery_id}
                    )
                )
                and defined $query->{plug_image_gallery_submit}
                and length $query->{plug_image_gallery_submit};

        $template->{t}{ $t_name_for{form} } = $t->output;
    }

    unless ( $conf->{no_list} ) {
        my $t = HTML::Template->new_scalar_ref( \ _list_template() );

        if ( defined $query->{plug_image_gallery_photo_id}
            and length $query->{plug_image_gallery_photo_id}
        ) {
            my $image = $dbh->selectall_arrayref(
                "SELECT * FROM $conf->{table} WHERE id = ?;",
                { Slice => {} },
                $query->{plug_image_gallery_photo_id},
            ) || [{}];
            $image = $image->[0];
            $t->param(
                is_view     => 1,
                photo       => File::Spec->catfile( $conf->{photo_dir}, $image->{photo} ),
                has_description => (
                    ( defined $image->{description} and length $image->{description} )
                    ? 1 : 0,
                ),
                description => $image->{description},
                width       => $image->{width},
                height      => $image->{height},
                page        => $query->{page},
                dir         => $query->{dir},
            );
        }
        else {
            my $images = $dbh->selectall_arrayref(
                "SELECT * FROM $conf->{table};",
                { Slice => {} },
            ) || [];

            @$images = sort { $b->{time} <=> $a->{time} } @$images;

            $t->param(
                has_images  => scalar(@$images),
                images      => [
                    map +{
                        want_lightbox => $conf->{want_lightbox},
                        src     => File::Spec->catfile( $conf->{thumb_dir}, $images->[$_]{photo} ),

                        ( $conf->{want_lightbox}
                            ? (
                                lightbox_src => File::Spec->catfile(
                                    $conf->{photo_dir},
                                    $images->[$_]{photo}
                                ),
                                lightbox_rel => $conf->{lightbox_rel},
                                lightbox_desc => (
                                    defined $images->[$_]{description}
                                    ? $images->[$_]{description} : ''
                                ),
                            )
                            : ()
                        ),

                        width   => $images->[$_]{thumb_width},
                        height  => $images->[$_]{thumb_height},
                        id      => $images->[$_]{id},
                        page    => $query->{page},
                        dir     => $query->{dir},
                        edit    => $conf->{allow_edit},
                        alt     => $_%2,
                        has_view => $conf->{has_view},
                        has_description => (
                            ( defined $images->[$_]{description}
                                and length $images->[$_]{description}
                                and not $conf->{no_thumb_desc}
                            ) ? 1 : 0,
                        ),
                        description => defined $images->[$_]{description}
                                    ? _process_description( $images->[$_]{description} )
                                    : '',
                    }, 0 .. $#$images,
                ],
            );
        }
        $template->{t}{ $t_name_for{list} } = $t->output;
    }
}

sub _process_description {
    my $d = shift;
    encode_entities $d;
    $d =~ s/\r?\n\r?/<br>/g;
    return $d;
}

sub _process_form {
    my ( $self, $t ) = @_;
    my ( $conf, $query, $dbh ) = map $self->$_, qw/conf query dbh/;

    if ( defined $query->{plug_image_gallery_id}
         and length $query->{plug_image_gallery_id}
    ) {
        $dbh->do(
            "UPDATE $conf->{table} SET description = ? WHERE id = ?",
            undef,
            $query->{plug_image_gallery_description},
            $query->{plug_image_gallery_id},
        );
        $t->param( success => 1 );
        return;
    }

    my $cgi = $self->config->cgi;

    my $filename = $cgi->param('plug_image_gallery_file');

    $filename = 'foo.jpg'
        unless defined $filename;

    my ( $ext ) = $filename =~ /([.][^.]+)$/;

    $ext = '.jpg'
        unless defined $ext;

    my $photo_file = File::Spec->catfile( $conf->{photo_dir}, $conf->{filename} . $ext );
    my $thumb_file = File::Spec->catfile( $conf->{thumb_dir}, $conf->{filename} . $ext );

    my $fh = $cgi->upload('plug_image_gallery_file')
        or do {
            $t->param(
                error => 'Failed to upload file' . (
                    $cgi->cgi_error ? ': ' . $cgi->cgi_error : ''
                )
            );
            $t->param( success => 1 );
            return;
        };

    open my $fh_out, '>', $photo_file
        or do { $t->param( error => "Failed to create local file [$!]" ); return; };

    binmode $fh_out;

    {
        local $/ = \102400;
        while (<$fh>) {
            print $fh_out $_;
        }
    }
    close $fh_out;
    close $fh;

    my ( $x, $y ) = imgsize $photo_file;

    if ( ref $conf->{thumb_size} eq 'ARRAY'
        or ( ref $conf->{thumb_size} eq 'HASH'
            and ( (%{ $conf->{thumb_size} })[0] < $x
                or (%{ $conf->{thumb_size} })[1] < $y
            )
        )
    ) {
        $conf->{thumb_size} = [ %{ $conf->{thumb_size} } ]
            if ref $conf->{thumb_size} eq 'HASH';

        my $thumb = Image::Resize->new( $photo_file );
        my $gd = $thumb->resize( @{ $conf->{thumb_size} } );

        open my $fh_thumb, '>', $thumb_file
            or $t->param( error => "Failed to create thumbnail [$!]" )
                and return;

        my $img_type = substr $ext, 1;
        $img_type = 'jpeg'
            unless $img_type eq 'png' or $img_type eq 'gif';

        binmode $fh_thumb;
        print $fh_thumb $gd->$img_type();
        close $fh_thumb;
    }
    else {
        copy $photo_file, $thumb_file;
    }

    if ( ref $conf->{photo_size} eq 'ARRAY'
        or ( ref $conf->{photo_size} eq 'HASH'
            and ( (%{ $conf->{photo_size} })[0] < $x
                or (%{ $conf->{photo_size} })[1] < $y
            )
        )
    ) {
        $conf->{photo_size} = [ %{ $conf->{photo_size} } ]
            if ref $conf->{photo_size} eq 'HASH';

        my $photo = Image::Resize->new( $photo_file );
        my $gd = $photo->resize( @{ $conf->{photo_size} } );

        open my $fh_photo, '>', $photo_file
            or $t->param( error => "Failed to resize photo [$!]" )
                and return;

        my $img_type = substr $ext, 1;
        $img_type = 'jpeg'
            unless $img_type eq 'png' or $img_type eq 'gif';

        binmode $fh_photo;
        print $fh_photo $gd->$img_type();
        close $fh_photo;

        ( $x, $y ) = ( $gd->width, $gd->height );
    }
    my ( $thumb_x, $thumb_y ) = imgsize $thumb_file;

    $t->param( success => 1 );

    $dbh->do(
        "INSERT INTO $conf->{table} VALUES(?, ?, ?, ?, ?, ?, ?, ?);",
        undef,
        $conf->{filename} . $ext,
        $x,
        $y,
        $thumb_x,
        $thumb_y,
        $query->{plug_image_gallery_description},
        time(),
        do { my $id = rand() . time() . rand(); $id =~ tr/.//d; $id },
    );

    return 1;
}

sub _form_template {
    return <<'END_TEMPLATE';
<tmpl_if name='success'>
    <p>Your image has been successfully uploaded.</p>
    <p><a href="<tmpl_var escape='html' name='success_href'>">Upload another image</a></p>
<tmpl_else>
    <form action="" method="POST" id="plug_image_gallery_form" enctype="multipart/form-data">
    <div>
        <tmpl_if name='error'><p class="error"><tmpl_var escape='html' name='error'></p></tmpl_if>
        <input type="hidden" name="page" value="<tmpl_var escape='html' name='page'>">
        <input type="hidden" name="dir" value="<tmpl_var escape='html' name='dir'>">
        <tmpl_if name='is_edit'><input type="hidden" name="plug_image_gallery_id" value="<tmpl_var escape='html' name='id'>"></tmpl_if>
        <ul>
            <tmpl_unless name='is_edit'><li>
                <label for="plug_image_gallery_file">Image: </label
                ><input type="file" name="plug_image_gallery_file" id="plug_image_gallery_file">
            </li></tmpl_unless>
            <li>
                <label for="plug_image_gallery_description">Description: </label
                ><textarea name="plug_image_gallery_description" id="plug_image_gallery_description" cols="60" rows="5"><tmpl_var escape='html' name='plug_image_gallery_description'></textarea>
            </li>
        </ul>
        <input type="submit" name="plug_image_gallery_submit" value="<tmpl_if name='is_edit'>Update<tmpl_else>Upload</tmpl_if>">
    </div>
    </form>
</tmpl_if>
END_TEMPLATE
}

sub _list_template {
    return <<'END_TEMPLATE';
<tmpl_if name='is_view'>
    <a class="plug_image_gallery_return_to_image_list" href="/index.pl?page=<tmpl_var escape='html' name='page'>&amp;dir=<tmpl_var escape='html' name='dir'>">Return to image list.</a>
    <div id="plug_image_gallery_photo"><img src="/<tmpl_var escape='html' name='photo'>" width="<tmpl_var escape='html' name='width'>" height="<tmpl_var escape='html' name='height'>" alt=""><tmpl_if name='has_description'><p class="plug_image_gallery_description"><tmpl_var name='description'></p></tmpl_if></div>
<tmpl_else>
    <tmpl_if name='has_images'>
        <ul class="plug_image_gallery_list">
            <tmpl_loop name='images'>
                <li<tmpl_if name='alt'> class="alt"</tmpl_if>>
                    <tmpl_if name='has_view'><a <tmpl_if name='want_lightbox'>rel="<tmpl_var escape='html' name='lightbox_rel'>" href="/<tmpl_var escape='html' name='lightbox_src'>" title="<tmpl_var escape='html' name='lightbox_desc'>"<tmpl_else>href="/index.pl?page=<tmpl_var escape='html' name='page'>&amp;dir=<tmpl_var escape='html' name='dir'>&amp;plug_image_gallery_photo_id=<tmpl_var escape='html' name='id'>"</tmpl_if>></tmpl_if><img src="/<tmpl_var escape='html' name='src'>" width="<tmpl_var escape='html' name='width'>" height="<tmpl_var escape='html' name='height'>" alt=""><tmpl_if name='has_view'></a></tmpl_if>
                    <tmpl_if name="has_description"><p><tmpl_var name='description'></p></tmpl_if>
                    <tmpl_if name="edit">
                        <form action="" method="POST">
                        <div>
                            <input type="hidden" name="plug_image_gallery_id" value="<tmpl_var escape='html' name='id'>">
                            <input type="hidden" name="page" value="<tmpl_var escape='html' name='page'>">
                            <input type="hidden" name="dir" value="<tmpl_var escape='html' name='dir'>">
                            <input type="submit" class="input_submit" name="plug_image_gallery_action" value="Edit">
                            <input type="submit" class="input_submit" name="plug_image_gallery_action" value="Delete">
                        </div>
                        </form>
                    </tmpl_if>
                </li>
            </tmpl_loop>
        </ul>
    <tmpl_else>
        <p>Currently there are no images.</p>
    </tmpl_if>
</tmpl_if>
END_TEMPLATE
}

sub conf {
    my $self = shift;
    @_ and $self->{CONF} = shift;
    return $self->{CONF};
}

sub template {
    my $self = shift;
    @_ and $self->{TEMPLATE} = shift;
    return $self->{TEMPLATE};
}

sub query {
    my $self = shift;
    @_ and $self->{QUERY} = shift;
    return $self->{QUERY};
}

sub config {
    my $self = shift;
    @_ and $self->{CONFIG} = shift;
    return $self->{CONFIG};
}

sub dbh {
    my $self = shift;
    @_ and $self->{dbh} = shift;
    return $self->{dbh};
}

1;
__END__

=encoding utf8

=for stopwords lightbox crapolio subref

=head1 NAME

App::ZofCMS::Plugin::ImageGallery - CRUD-like plugin for managing images.

=head1 SYNOPSIS

In your Main Config File or ZofCMS Template file:

    plugins => [ qw/ImageGallery/ ],

    plug_image_gallery => {
        dsn        => "DBI:mysql:database=test;host=localhost",
        user       => 'test',
        pass       => 'test',
        no_form    => 0,
        allow_edit => 1,
    },

In your L<HTML::Template> template:

    <tmpl_var name='plug_image_gallery_form'>
    <tmpl_var name='plug_image_gallery_list'>

Viola, now you can upload photos with descriptions, delete them and edit descriptions. \o/

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that allows one to add a CRUD-like functionality
for managing photos. The plugin automatically makes thumbnails and can also resize the
actual photos if you tell it to. So far, only
C<.jpg>, C<.png> and C<.gif> images are supported; however, plugin does not check
C<Content-Type> of the uploaded image.

The image file name and description are stored in a SQL database.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 USED SQL TABLE FORMAT

When C<create_table> option is turned on (see below) the plugin will create the following
table where C<table_name> is derived from C<table> argument in C<plug_image_gallery>
(see below).

    CREATE TABLE table_name (
        photo        TEXT,
        width        SMALLINT,
        height       SMALLINT,
        thumb_width  SMALLINT,
        thumb_height SMALLINT,
        description  TEXT,
        time         VARCHAR(10),
        id           TEXT
    );

=head1 MAIN CONFIG FILE AND ZofCMS TEMPLATE FIRST-LEVEL KEYS

=head2 C<plugins>

    plugins => [ qw/ImageGallery/, ],

You obviously need to include the plugin in the list of plugins to execute.

=head2 C<plug_image_gallery>

    plug_image_gallery => {
        dsn             => "DBI:mysql:database=test;host=localhost",
        # everything below is optional
        user            => '',
        pass            => '',
        opt             => { RaiseError => 1, AutoCommit => 1 },
        table           => 'photos',
        photo_dir       => 'photos/',
        filename        => '[:rand:]',
        thumb_dir       => 'photos/thumbs/',
        create_table    => 0,
        t_name          => 'plug_image_gallery',
        no_form         => 1,
        no_list         => 0,
        no_thumb_desc   => 0,
        allow_edit      => 0,
        thumb_size      => { 200, 200 },
        # photo_size      => [ 600, 600 ],
        has_view        => 1,
        want_lightbox   => 0,
        lightbox_rel    => 'lightbox',
        lightbox_desc   => 1,
    }

    plug_image_gallery => sub {
        my ( $t, $q, $config ) = @_;
        return {
            dsn             => "DBI:mysql:database=test;host=localhost",
        };
    }

The plugin takes its configuration from C<plug_image_gallery> first-level key that takes
a hashref or a subref as a value and can be specified in either (or both) Main Config File and
ZofCMS Template file. If the same key in that hashref is specified in both, Main Config File
and ZofCMS Template file, then the value given to it in ZofCMS Template will take precedence.
If subref is specified,
its return value will be assigned to C<plug_image_gallery> as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Template hashref, query parameters hashref and
L<App::ZofCMS::Config> object.

The plugin will B<NOT> run if C<plug_image_gallery> is not set or if B<both> C<no_form>
B<and> C<no_list> arguments (see below) are set to true values.

The possible C<plug_image_gallery> hashref's keys/values are as follows:

=head3 C<dsn>

    dsn => "DBI:mysql:database=test;host=localhost",

B<Mandatory>. Takes a scalar as a value which must contain a valid
"$data_source" as explained in L<DBI>'s C<connect_cached()> method (which
plugin currently uses).

=head3 C<user>

    user => '',

B<Optional>. Takes a string as a value that specifies the user name to use when authorizing
with the database. B<Defaults to:> empty string

=head3 C<pass>

    pass => '',

B<Optional>. Takes a string as a value that specifies the password to use when authorizing
with the database. B<Defaults to:> empty string

=head3 C<opt>

    opt => { RaiseError => 1, AutoCommit => 1 },

B<Optional>. Takes a hashref as a value, this hashref contains additional L<DBI>
parameters to pass to C<connect_cached()> L<DBI>'s method. B<Defaults to:>
C<< { RaiseError => 1, AutoCommit => 1 } >>

=head3 C<table>

    table => 'photos',

B<Optional>. Takes a string as a value, specifies the name of the SQL table in which to
store information about photos. B<Defaults to:> C<photos>

=head3 C<create_table>

    create_table => 0,

B<Optional>. When set to a true value, the plugin will automatically create needed SQL table,
you can create it manually if you wish, see its format in C<USED SQL TABLE FORMAT> section
above. Generally you'd set this to a true value only once, at the start, and then you'd remove
it because there is no "IF EXISTS" checks. B<Defaults to:> C<0>

=head3 C<t_name>

    t_name => 'plug_image_gallery',

B<Optional>. Takes a string as a value. This string will be
used as a "base name" for two keys that plugin generates in C<{t}> special key.
The keys are C<plug_image_gallery_list> and C<plug_image_gallery_form>
(providing C<t_name> is set to
default) and are explained below in C<HTML::Template VARIABLES> section below. B<Defaults to:>
C<plug_image_gallery>

=head3 C<photo_dir>

    photo_dir => 'photos/',

B<Optional>. Takes a string that specifies the directory (relative to C<index.pl>) where
the plugin will store photos. B<Note:> plugin does B<not> automatically create this directory.
B<Defaults to:> C<photos/>

=head3 C<thumb_dir>

    thumb_dir => 'photos/thumbs/',

B<Optional>. Takes a string that specifies the directory (relative to C<index.pl>) where
the plugin will store thumbnails.
B<Note:> plugin does B<not> automatically create this directory. B<Note 2:> this directory
B<must NOT> be the same as C<photo_dir>.
B<Defaults to:> C<photos/thumbs/>

=head3 C<filename>

    filename => '[:rand:]',

B<Optional>. Specifies the name for the image file (and its thumbnail) without the extension
for when new image is uploaded. You'd obviously want to manipulate this value with some
other plugin (e.g. L<App::ZofCMS::Plugin::Sub>) to make sure it's not the same
as existing images. B<Special value> of C<[:rand:]> (value includes the brackets) will make
the plugin generate random filenames (along with check of whether the generated name
already exists). B<Defaults to:> C<[:rand:]>

=head3 C<thumb_size>

    thumb_size => { 200, 200 }, # resize only if larger
    thumb_size => [ 200, 200 ], # always resize

B<Optional>. Takes either an arrayref with two elements or a hashref with one key/value pair.
The plugin will generate thumbnails automatically. The C<thumb_size> specifies the dimensions
of the thumbnails. The proportions are always kept when resizing. When C<thumb_size> is set
to an I<arrayref>, the plugin will resize the image even if its smaller than the specified
size (i.e. a 50x50 image's thumb will be scaled to 200x200 when C<thumb_size> is set to
C<[200, 200]> ). The first element of the arrayref denotes the x (width) dimension and the
second element denotes the y (height) dimension. When the value for C<thumb_size> is a
I<hashref> then the key denotes the width and the value denotes the height; the image will
be resized only if one of its dimensions (width or height) is larger than the specified
values. In other words, when C<thumb_size> is set to C<{ 200, 200 }>, a 50x50 image's thumbnail
will be left at 50x50 while a 500x500 image's thumbnail will be scaled to 200x200.
B<Defaults to:> C<{ 200, 200 }>

=head3 C<photo_size>

    photo_size => { 600, 600 },
    photo_size => [ 600, 600 ],

B<Optional>. When specified takes either an arrayref or a hashref as a value. Everything is
the same (regarding values) as the values for C<thumb_size> argument described above except
that resizing is done on the original image. If C<photo_size> is not specified, no resizing
will be performed. B<Note:> the thumbnail will be generated first, thus it's possible to
have thumbnails that are larger than the original image even when hashrefs are used for
both C<photo_size> and C<thumb_size>. B<By default is not specified>

=head3 C<no_form>

    no_form => 1,

B<Optional>. Takes either true or false values. When
set to a B<false> value, the plugin will generate as well as process an HTML form that
is to be used for uploading new images or editing descriptions on existing ones.
B<Note:> even if you are making your own HTML form, the plugin will B<not> process
editing or deleting of items when C<no_form> is set to a true value. B<Defaults to:> C<1>

=head3 C<no_list>

    no_list => 0,

B<Optional>. Takes either true or false values. When set to a B<false> value, the plugin
will pull the data from the database and generate an HTML list with image thumbnails and their
descriptions (unless C<no_thumb_desc> argument described below is set to a true value).
B<Defaults to:> C<0>

=head3 C<no_thumb_desc>

    no_thumb_desc => 0,

B<Optional>. Takes either true or false values. Makes sense only when C<no_list> is set to
a false value. When C<no_thumb_desc> is set to a B<true> value, the plugin will not put
descriptions in the generated list of thumbnails. The description will be visible only when
the user clicks on the image to view it in large size (providing C<has_view> option that
is described below is set to a true value). B<Defaults to:> C<0>

=head3 C<has_view>

    has_view => 1,

B<Optional>. Takes either true or false values. Makes sense only when C<no_list> is set
to a false value. When set to a true value, plugin will generate links for each thumbnail
in the list; when user will click that link, he or she will be presented with an original
image and a link to go back to the list of thumbs. When set to a false value no link
will be generated. B<Defaults to:> C<1>

=head3 C<allow_edit>

    allow_edit => 0,

B<Optional>. Takes either true or false values. When set to a true value, B<both> C<no_list>
and B<no_form> must be set to false values.  When set to a true value, the plugin will
generate C<Edit> and C<Delete> buttons under each thumbnail in the list. Clicking "Delete" will
delete the image, thumbnail and entry in the database. Clicking "Edit" will fetch the
description into the "description" field in the form, allowing the user to edit it.
B<Defaults to:> C<0>

=head3 C<want_lightbox>

    want_lightbox => 0,

B<Optional>. The list of thumbs generated by the plugin can be generated for use with
"Lightbox" JavaScript crapolio. Takes true or false values. When set to a true value, the
thumb list will be formatted for use with "Lightbox". B<Note:> C<has_view> B<must> be set
to a true value as well. B<Defaults to:> C<0>

=head3 C<lightbox_rel>

    lightbox_rel => 'lightbox',

B<Optional>. Used only when C<want_lightbox> is set to a true value. Takes a string as a value,
this string will be used for C<rel=""> attribute on links. B<Defaults to:> C<lightbox>

=head3 C<lightbox_desc>

    lightbox_desc => 1,

B<Optional>. Takes either true or false values. When set to a true value, the plugin will
stick image descriptions into C<title=""> attribute that makes them visible in the Lightbox.
B<Defaults to:> C<1>

=head1 HTML::Template VARIABLES

The plugin generates two keys in C<{t}> ZofCMS Template special key, thus making them
available for use in your L<HTML::Template> templates. Assuming C<t_name> is left at its
default value the following are the names of those two keys:

=head2 C<plug_image_gallery_form>

    <tmpl_var name='plug_image_gallery_form'>

This variable will contain HTML form generated by the plugin, the form also includes display
of errors.

=head2 C<plug_image_gallery_list>

    <tmpl_var name='plug_image_gallery_list'>

This variable will contain the list of photos generated by the plugin.

=head1 GENERATED HTML CODE

=head2 form

    <form action="" method="POST" id="plug_image_gallery_form" enctype="multipart/form-data">
    <div>
        <input type="hidden" name="page" value="photos">
        <input type="hidden" name="dir" value="/admin/">
        <ul>
            <li>
                <label for="plug_image_gallery_file">Image: </label
                ><input type="file" name="plug_image_gallery_file" id="plug_image_gallery_file">
            </li>
            <li>
                <label for="plug_image_gallery_description">Description: </label
                ><textarea name="plug_image_gallery_description" id="plug_image_gallery_description" cols="60" rows="5"></textarea>
            </li>
        </ul>
        <input type="submit" name="plug_image_gallery_submit" value="Upload">
    </div>
    </form>

=head2 form when "Edit" was clicked

    <form action="" method="POST" id="plug_image_gallery_form" enctype="multipart/form-data">
    <div>
        <input type="hidden" name="page" value="photos">
        <input type="hidden" name="dir" value="/admin/">
        <input type="hidden" name="plug_image_gallery_id" value="07537915760568812292592510718228816144752">
        <ul>
            <li>
                <label for="plug_image_gallery_description">Description: </label
                ><textarea name="plug_image_gallery_description" id="plug_image_gallery_description" cols="60" rows="5">Teh Descripshun!</textarea>
            </li>
        </ul>
        <input type="submit" name="plug_image_gallery_submit" value="Update">
    </div>
    </form>

=head2 form when upload or update was successful

    <p>Your image has been successfully uploaded.</p>
    <p><a href="/index.pl?page=photos&amp;amp;dir=/admin/">Upload another image</a></p>

=head2 list (when both C<allow_edit> and C<has_view> is set to true values)

    <ul class="plug_image_gallery_list">
        <li>
            <a href="/index.pl?page=photos&amp;dir=/admin/&amp;plug_image_gallery_photo_id=037142535745273312292651650508033404216754"><img src="/photos/thumbs/0029243203419358812292651650444418525180907.jpg" width="191" height="200" alt=""></a>
                <form action="" method="POST">
                <div>
                    <input type="hidden" name="plug_image_gallery_id" value="037142535745273312292651650508033404216754">
                    <input type="hidden" name="page" value="photos">
                    <input type="hidden" name="dir" value="/admin/">
                    <input type="submit" name="plug_image_gallery_action" value="Edit">
                    <input type="submit" name="plug_image_gallery_action" value="Delete">
                </div>
                </form>
        </li>
        <li class="alt">
            <a href="/index.pl?page=photos&amp;dir=/admin/&amp;plug_image_gallery_photo_id=07537915760568812292592510718228816144752"><img src="/photos/thumbs/058156553244134912292592510947564500241668.png" width="200" height="125" alt=""></a>
            <p>Teh Descripshun!</p>
                <form action="" method="POST">
                <div>
                    <input type="hidden" name="plug_image_gallery_id" value="07537915760568812292592510718228816144752">
                    <input type="hidden" name="page" value="photos">
                    <input type="hidden" name="dir" value="/admin/">
                    <input type="submit" name="plug_image_gallery_action" value="Edit">
                    <input type="submit" name="plug_image_gallery_action" value="Delete">
                </div>
                </form>
        </li>
    </ul>

=head2 original image view

    <a class="plug_image_gallery_return_to_image_list" href="/index.pl?page=photos&amp;dir=/admin/">Return to image list.</a>
    <div id="plug_image_gallery_photo"><img src="/photos/0029243203419358812292651650444418525180907.jpg" width="575" height="600" alt="">
        <p class="plug_image_gallery_description">Uber hawt chick</p>
    </div>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS-PluginBundle-Naughty>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS-PluginBundle-Naughty/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS-PluginBundle-Naughty at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
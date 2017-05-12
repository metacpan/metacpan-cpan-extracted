package CGI::Uploader;

use 5.008;
use strict;
use Carp;
use Params::Validate ':all';
use File::Path;
use File::Spec;
use File::Temp 'tempfile';
use Carp::Assert;
use Image::Size;
require Exporter;

our $VERSION = '2.18';

=head1 NAME

CGI::Uploader - Manage CGI uploads using SQL database

=head1 Synopsis

 use CGI::Uploader::Transform::ImageMagick 'gen_thumb';

 my $u = CGI::Uploader->new(
    spec       => {
        # Upload one image named from the form field 'img'
        # and create one thumbnail for it.
        img_1 => {
            gen_files => {
                'img_1_thmb_1' => gen_thumb({ w => 100, h => 100 }),
              }
        },
    },

    updir_url  => 'http://localhost/uploads',
    updir_path => '/home/user/www/uploads',
        temp_dir   => '/home/user/www/uploads',

    dbh        => $dbh,
    query      => $q, # defaults to CGI->new(),
 );

 # ... now do something with $u

=head1 Description

This module is designed to help with the task of managing files uploaded
through a CGI application. The files are stored on the file system, and
the file attributes stored in a SQL database.

=head1 Introduction and Recipes

The L<CGI::Uploader::Cookbook|CGI::Uploader::Cookbook> provides
a slightly more in depth introduction and recipes for a basic BREAD web
application.  (Browse, Read, Edit, Add, Delete).

=head1 Constructor

=head2 new()

 my $u = CGI::Uploader->new(
    spec       => {
         # The first image has 2 different sized thumbnails
           img_1 => {
             gen_files => {
                     'img_1_thmb_1' => gen_thumb({ w => 100, h => 100 }),
                     'img_1_thmb_2' => gen_thumb({ w => 50, h => 50 }),
             }
           },
       },

        # Just upload it
        img_2 => {},
        # Downsize the large image to these maximum dimensions if it's larger
        img_3 => {
            # Besides generating dependent files
            # We can also transform the file itself
            # Here, we shrink the image to be wider than 380
            transform_method => \&gen_thumb,
            # demostrating the old-style param passing
            params => [{ w => 380 }],
        }
    },

    updir_url  => 'http://localhost/uploads',
    updir_path => '/home/user/www/uploads',

    dbh        => $dbh,
    query      => $q, # defaults to CGI->new(),

    up_table   => 'uploads', # defaults to "uploads"
    up_seq     => 'upload_id_seq',  # Required for Postgres
 );

=over 4

=item spec [required]

The specification described the examples above. The keys correspond to form
field names for upload fields.

The values are hash references. The simplest case is an empty hash  reference,
which means to just upload the image and apply no transformations.

#####

Each key in the hash is the corresponds to a file upload field. The values
are hash references used provide options for how to transform the file,
and possibly generate additional files based on it.

Valid keys here are:

=item transform_method

This is a subroutine reference. This routine can be used to transform the
upload before it is stored. The first argument given to the routine will be the
CGI::Uploader object. The second will be a full path to a file name containing
the upload.

Additional arguments can be passed to the subroutine using C<params>, as in the
example above. But don't do that, it's ugly. If you need a custom transform
method, write a little closure for it like this:

  sub my_transformer {
      my %args = @_;
      return sub {
          my ($self, $file) = shift;
          # do something with $file and %args here...
          return $path_to_new_file_i_made;
      }

Then in the  spec you can put:

 transform_method => my_tranformer(%args),

It must return a full path to a transformed file.

}

=item params (DEPRECATED)

B<NOTE:> Using a closure based interface provides a cleaner alternative to
using params. See L<CGI::Uploader::Transform::ImageMagick> for an example.

Used to pass additional arguments to C<transform_method>. See above.

Each method used may have additional documentation about parameters
that can be passed to it.


=item gen_files

A hash reference to describe files generated from a particular upload.
The keys are unique identifiers  for the generated files. The values
are code references (usually closures) that prove a transformation
for the file. See L<CGI::Uploader::Transform::ImageMagick> for an
an example.

An older interface for C<gen_files> is deprecated. For that, the values are
hashrefs, containing keys named C<transform_method> and C<params>, which work
as described above to generate a transformed version of the file.

=item updir_url [required]

URL to upload storage directory. Should not include a trailing slash.

=item updir_path [required]

File system path to upload storage directory. Should not include a trailing
slash.

=item temp_dir

Optional file system path to temporary directory. Default is File::Spec->tmpdir().
This temporary directory will also be used by gen_files during image transforms.

=item dbh [required]

DBI database handle. Required.

=item query

A CGI.pm-compatible object, used for the C<param> and C<upload> functions.
Defaults to CGI->new() if omitted.

=item up_table

Name of the SQL table where uploads are stored. See example syntax above or one
of the creation scripts included in the distribution. Defaults to "uploads" if
omitted.

=item up_table_map

A hash reference which defines a mapping between the column names used in your
SQL table, and those that CGI::Uploader uses. The keys are the CGI::Uploader
default names. Values are the names that are actually used in your table.

This is not required. It simply allows you to use custom column names.

  upload_id       => 'upload_id',
  mime_type       => 'mime_type',
  extension       => 'extension',
  width           => 'width',
  height          => 'height',
  gen_from_id     => 'gen_from_id',
  file_name       => 'file_name',

You may also define additional column names with a value of 'undef'. This feature
is only useful if you override the C<extract_meta()> method or pass in
C<$shared_meta> to store_uploads(). Values for these additional columns will
then be stored by C<store_meta()> and retrieved with C<fk_meta()>.

=item up_seq

For Postgres only, the name of a sequence used to generate the upload_ids.
Defaults to C<upload_id_seq> if omitted.

=item file_scheme

 file_scheme => 'md5',

C<file_scheme> controls how file files are stored on the file system. The default
is C<simple>, which stores all the files in the same directory with names like
C<123.jpg>. Depending on your environment, this may be sufficient to store
10,000 or more files.

As an alternative, you can specify C<md5>, which will create three levels
of directories based on the first three letters of the ID's md5 sum. The
result may look like this:

 2/0/2/123.jpg

This should scale well to millions of files. If you want even more control,
consider overriding the C<build_loc()> method, which is  used to return the
stored file path.

Note that specifying the file storage scheme for the file system is not related
to the C<file_name> stored in the database, which is always the original uploaded
file name.


=back

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %in = validate( @_, {
        updir_url    => { type => SCALAR },
        updir_path   => { type => SCALAR },
        dbh          => 1,
        up_table     => {
                          type => SCALAR,
                          default=> 'uploads',
        },
        temp_dir   => {
                type    => SCALAR,
                default => File::Spec->tmpdir()
        },
        up_table_map => {
                          type    => HASHREF,
                          default => {
                              upload_id       => 'upload_id',
                              mime_type       => 'mime_type',
                              extension       => 'extension',
                              width           => 'width',
                              height          => 'height',
                              gen_from_id     => 'gen_from_id',
#                              bytes      => 'bytes',
                          }
        },
        up_seq      => { default => 'upload_id_seq'},
        spec        => { type => HASHREF },
        query       => { optional => 1  } ,
        file_scheme => {
             regex   => qr/^simple|md5$/,
             default => 'simple',
        },

    });
    $in{db_driver} = $in{dbh}->{Driver}->{Name};
    # Support PostgreSQL via ODBC
    $in{db_driver} = 'Pg' if $in{dbh}->get_info(17) eq 'PostgreSQL';
    unless (($in{db_driver} eq 'mysql') or ($in{db_driver} eq 'Pg') or ($in{db_driver} eq 'SQLite')) {
        croak "only mysql, Pg and SQLite drivers are supported at this time. You are trying to use $in{db_driver}.";
    }

    unless ($in{query}) {
        require CGI;
        $in{query} = CGI->new;
    }

    # Process the spec
    for my $k (keys %{ $in{spec} }) {
        # If the spec is an arrayref, that's a shorthand for specifying some gen_files.
        if (ref $in{spec}->{$k} eq 'ARRAY') {
            $in{spec}->{$k} = {
                gen_files => $in{spec}->{$k},
            };
        }
    }

    # Fill in missing map values
    for (keys %{ $in{up_table_map} }) {
        $in{up_table_map}{$_} = $_ unless defined $in{up_table_map}{$_};
    }

    # keep pointer to input hash for easier re-use later
    $in{input} =\%in;

    my $self  = \%in;
    bless ($self, $class);
    return $self;
}

=head1 Basic Methods

These basic methods are all you need to know to make effective use of this
module.

=head2 store_uploads()

  my $entity = $u->store_uploads($form_data);

Stores uploaded files based on the definition given in C<spec>.

Specifically, it does the following:

=over

=item o

possibily transforms the original file according to C<transform_method>

=item o

possibly generates additional files based on those uploaded, according to
C<gen_files>.

=item o

stores all the files on the file system

=item o

inserts upload details into the database, including upload_id,
mime_type and extension. The columns 'width' and 'height' will be
populated if that meta data is available.

=back

As input, a hash reference of form data is expected. The simplest way
to get this is like this:

 use CGI;
 my $q = new CGI;
 $form_data = $q->Vars;

However, I recommend that you validate your data with a module with
L<Data::FormValidator|Data::FormValidator>, and use a hash reference
of validated data, instead of directly using the CGI form data.

CGI::Uploader is designed to handle uploads that are included as a part
of an add/edit form for an entity stored in a database. So, C<$form_data>
is expected to contain additional fields for this entity as well
as the file upload fields.

For this reason, the C<store_uploads> method returns a hash reference of the
valid data with some transformations.  File upload fields will be removed from
the hash, and corresponding "_id" fields will be added.

So for a file upload field named 'img_field',  the 'img_field' key
will be removed from the hash and 'img_field_id' will be added, with
the appropriate upload ID as the value.

store_uploads takes an optional second argument as well:

  my $entity = $u->store_uploads($form_data,$shared_meta);

This is a hash refeference of additional meta data that you want to store
for all of the images you storing. For example, you may wish to store
an "uploaded_user_id".

The keys should be column names that exist in your C<uploads> table. The values
should be appropriate data for the column.  Only the key names defined by the
C<up_table_map> in C<new()> will be used.  Other values in the hash will be
ignored.

=cut

sub store_uploads {
    validate_pos(@_,1,1,0);
    my $self        = shift;
    my $form_data   = shift;
    my $shared_meta = shift;
    assert($form_data, 'store_uploads: input hashref missing');

    my $uploads = $self->{spec};

    my %entity_all_extra;
    for my $file_field (keys %$uploads) {
        # If we have an uploaded file for this
        my ($tmp_filename,$uploaded_mt,$file_name) = $self->upload($file_field);
        if ($tmp_filename) {
            my $id_to_update = $form_data->{$file_field.'_id'};

            my %entity_upload_extra = $self->store_upload(
                file_field    => $file_field,
                src_file      => $tmp_filename,
                uploaded_mt   => $uploaded_mt,
                file_name     => $file_name,
                shared_meta   => $shared_meta,
                id_to_update  => $id_to_update,
            );

            %entity_all_extra = (%entity_all_extra, %entity_upload_extra);
        }
    }

    # Now add and delete as needed
    my $entity = { %$form_data, %entity_all_extra };
    map { delete $entity->{$_} } keys %{ $self->{spec} };
    # For good measure.
    delete $entity->{''};

    File::Temp::cleanup();

    return $entity;
}

=head2 delete_checked_uploads()

 my @fk_col_names = $u->delete_checked_uploads;

This method deletes all uploads and any generated files
based on form input. Both files and meta data are removed.

It looks through all the field names defined in C<spec>. For an upload named
I<img_1>, a field named I<img_1_delete> is checked to see if it has a true
value.

A list of the field names is returned, prepended with '_id', such as:

 img_1_id

The expectation is that you have foreign keys with these names defined in
another table. Having the names is format allows you to easily
set these fields to NULL in a database update:

 map { $entity->{$_} = undef } @fk_names;

B<NOTE:> This method can not currently be used to delete a generated file by itself.

=cut

sub delete_checked_uploads {
    my $self = shift;
    my $imgs = $self->{spec};

    my $q = $self->{query};
    my $map = $self->{up_table_map};

    croak "missing gen_from_id in up_table_map"  unless $map->{gen_from_id};


    my @to_delete;

    for my $file_field (keys %$imgs) {
        if ($q->param($file_field.'_delete') ) {
            my $upload_id = $q->param($file_field.'_id') ||
                croak "$file_field was selected to delete,
                    but ID was missing in '${file_field}_id' field";

            $self->delete_upload($upload_id);

            # Delete generated files  as well.
            my $gen_file_ids = $self->{dbh}->selectcol_arrayref(
                "SELECT $map->{upload_id}
                    FROM $self->{up_table}
                    WHERE $map->{gen_from_id} = ?",{},$upload_id) || [];

            for my $gen_file_id (@$gen_file_ids) {
                $self->delete_upload($gen_file_id);
            }

            push @to_delete, map {$_.'_id'} $self->spec_names($file_field) ;
        }

    }

    return @to_delete;
}


=head2 fk_meta()

 my $href = $u->fk_meta(
    table    => $table,
    where    => \%where,
    prefixes => \@prefixes,

Returns a hash reference of information about the file, useful for
passing to a templating system. Here's an example of what the contents
of C<$href> might look like:

 {
     file_1_id     => 523,
     file_1_url    => 'http://localhost/images/uploads/523.pdf',
 }

If the files happen to be images and have their width and height
defined in the database row, template variables will be made
for these as well.

This is going to fetch the file information from the upload table for using the row
where news.item_id = 23 AND news.file_1_id = uploads.upload_id.

This is going to fetch the file information from the upload table for using the row
where news.item_id = 23 AND news.file_1_id = uploads.upload_id.

The C<%where> hash mentioned here is a L<SQL::Abstract|SQL::Abstract> where clause. The
complete SQL that used to fetch the data will be built like this:

 SELECT upload_id as id,width,height,extension
    FROM uploads, $table
    WHERE (upload_id = ${prefix}_id AND (%where_clause_expanded here));

=cut

sub fk_meta {
    my $self = shift;
    my %p = validate(@_,{
        table    => { type => SCALAR },
        where    => { type => HASHREF },
        prefixes => { type => ARRAYREF },
        prevent_browser_caching => { default => 1 }
    });


    my $table = $p{table};
    my $where = $p{where};
    my @file_fields = @{ $p{prefixes} };

    my $DBH = $self->{dbh};
    my %fields;
    require SQL::Abstract;
    my $sql = SQL::Abstract->new;
    my ($stmt,@bind) = $sql->where($where);

    # We don't want the 'WHERE' word that SQL::Abstract adds
    $stmt =~ s/^\s?WHERE//;

    # XXX There is probably a more efficient way to get this data than using N selects

    # mysql uses non-standard quoting
    my $qt = ($DBH->{Driver}->{Name} eq 'mysql') ? '`' : '"';

    my $map = $self->{up_table_map};

    for my $field (@file_fields) {
        my $upload = $DBH->selectrow_hashref(qq!
            SELECT *
                FROM !.$self->{up_table}.qq!, $table AS t
                WHERE ($self->{up_table}.$map->{upload_id} = t.${qt}${field}_id${qt} and ($stmt) )!,
                {},@bind);

            my %upload_fields = $self->transform_meta(
                meta => $upload,
                prevent_browser_caching => $p{prevent_browser_caching},
                prefix => $field,
            );
           %fields = (%fields, %upload_fields);

    }

    return \%fields;
}

=head1 Class Methods

These are some handy class methods that you can use without the need to first create
an object using C<new()>.

=head2 upload()

 # As a class method
 ($tmp_filename,$uploaded_mt,$file_name) =
    CGI::Uplooader->upload('file_field',$q);

 # As an object method
 ($tmp_filename,$uploaded_mt,$file_name) =
    $u->upload('file_field');

The function is responsible for actually uploading the file.

It can be called as a class method or an object method. As a class method, it's
necessary to provide a query object as the second argument. As an object
method, the query object given the constructor is used.

Input:
 - file field name

Output:
 - temporary file name
 - Uploaded MIME Type
 - Name of uploaded file (The value of the file form field)

Currently CGI.pm, CGI::Simple and Apache::Request and are supported.

=cut

sub upload {
    my $self = shift;
    my $file_field = shift;
    my $q = shift || $self->{query};

    my $fh;
    my $mt = '';
    my $filename = $q->param($file_field);

    if ($q->isa('CGI::Simple') ) {
        local $CGI::Simple::DISABLE_UPLOADS = 0;  # Having uploads enabled is mandatory for this to work.
        $fh = $q->upload($filename);
        $mt = $q->upload_info($filename, 'mime' );

        if (!$fh && $q->cgi_error) {
            warn $q->cgi_error && return undef;
        }
    }
    elsif ( $q->isa('Apache::Request') ) {
        my $upload = $q->upload($file_field);
        $fh = $upload->fh;
        $mt = $upload->type;
    }
    # default to CGI.pm behavior
    else {
        local $CGI::DISABLE_UPLOADS = 0;  # Having uploads enabled is mandatory for this to work.
        $fh = $q->upload($file_field);
        $mt = $q->uploadInfo($fh)->{'Content-Type'} if $q->uploadInfo($fh);

        if (!$fh && $q->cgi_error) {
            warn $q->cgi_error && return undef;
        }
    }

    return undef unless ($fh && $filename);

    my ($tmp_fh, $tmp_filename) = tempfile('CGIuploaderXXXXX', UNLINK => 1, DIR => $self->{'temp_dir'} );

    binmode($fh);

    require File::Copy;
    import  File::Copy;
    copy($fh,$tmp_filename) || croak "upload: unable to create tmp file: $!";

    return ($tmp_filename,$mt,$filename);
}

=head1 Upload Methods

These methods are high level methods to manage the file and meta data parts of
an upload, as well its generated files.  If you are doing something more
complex or customized you may want to call or overide one of the below methods.

=head2 store_upload()

 my %entity_upload_extra = $u->store_upload(
    file_field    => $file_field,
    src_file      => $tmp_filename,
    uploaded_mt   => $uploaded_mt,
    file_name     => $file_name,
    shared_meta   => $shared_meta,  # optional
    id_to_update  => $id_to_update, # optional
 );

Does all the processing for a single upload, after it has been uploaded
to a temp file already.

It returns a hash of key/value pairs as described in L</store_uploads()>.

=cut

sub store_upload {
    my $self = shift;
    my %p = validate(@_, {
            file_field    => { type => SCALAR },
            src_file      => { type => SCALAR },
            uploaded_mt   => { type => SCALAR },
            file_name     => { type => SCALAR | GLOBREF },
            shared_meta   => { type => HASHREF | UNDEF,    default => {} },
            id_to_update  => { type => SCALAR | UNDEF, optional => 1 },
        });

    my (
        $file_field,
        $tmp_filename,
        $uploaded_mt,
        $file_name,
        $shared_meta,
        $id_to_update,
    ) = ($p{file_field},$p{src_file},$p{uploaded_mt},$p{file_name},$p{shared_meta},$p{id_to_update});

    # Transform file if needed
    if (my $meth = $self->{spec}{$file_field}{transform_method}) {
        $tmp_filename = $meth->( $self,
            $tmp_filename,
            $self->{spec}{$file_field}{params},
        );
    }

    # XXX The uploaded mime type may have nothing to do with
    # the current mime-type after it's transformed
    my $meta = $self->extract_meta($tmp_filename,$file_name,$uploaded_mt);

    $shared_meta ||= {};
    my $all_meta = { %$meta, %$shared_meta };

    my $id;
    # If it's an update
    if ($id = $id_to_update) {
        # delete old generated files  before we create new ones
        $self->delete_gen_files($id);

        # It's necessary to delete the old file when updating, because
        # the new one may have a new extension.
        $self->delete_file($id);
    }

    # insert or update will be performed as appropriate.
    $id = $self->store_meta(
        $file_field,
        $all_meta,
        $id );

    $self->store_file($file_field,$id,$meta->{extension},$tmp_filename);

    my %ids = ();
       %ids = $self->create_store_gen_files(
      file_field  => $file_field,
      meta        => $all_meta,
      src_file    => $tmp_filename,
      gen_from_id => $id,
    );

    return (%ids, $file_field.'_id' => $id);

}

=head2 create_store_gen_files()

 my %gen_file_ids = $u->create_store_gen_files(
        file_field      => $file_field,
        meta            => $meta_href,
        src_file        => $tmp_filename,
        gen_from_id => $gen_from_id,
    );

This method is responsible for creating and storing
any needed thumbnails.

Input:
 - file_field: file field name
 - meta: a hash ref of meta data, as C<extract_meta> would produce
 - src_file: path to temporary file of the file upload
 - gen_from_id: ID of upload that generated files  will be made from

=cut

sub create_store_gen_files {
    my $self = shift;
    my %p = validate(@_, {
            file_field       => { type => SCALAR },
            src_file         => { type => SCALAR },
            meta             => { type => HASHREF | UNDEF,    default => {} },
            gen_from_id  => { regex => qr/^\d*$/, },
        });
    my ($file_field,
        $meta,
        $tmp_filename,
        $gen_from_id) = ($p{file_field},$p{meta},$p{src_file},$p{gen_from_id});

    my $gen_fields_key = $self->{spec}{$file_field}{gen_files} || return undef;
    my @gen_files = keys %{ $gen_fields_key };

    my $gen_files = $self->{spec}{$file_field}{gen_files};
    my $q = $self->{query};
    my %out;

    my ($w,$h) = ($meta->{width},$meta->{height});
    for my $gen_file (@gen_files) {
        my $gen_tmp_filename;

        # tranform as needed
        my $gen_file_key = $self->{spec}{$file_field}{gen_files}{$gen_file};
        # Recommended code ref API
        if (ref  $gen_file_key eq 'CODE') {
            # It needed any params, they should already have been provided via closure.
            $gen_tmp_filename = $gen_file_key->($self,$tmp_filename);
        }
        # Old, yucky hashref API
        elsif (ref $gen_file_key eq 'HASH') {
            my $meth = $gen_file_key->{transform_method};
            $gen_tmp_filename = $meth->(
                $self,
                $tmp_filename,
                $gen_file_key->{params},
            );
        }
        else {
            croak "$gen_file for $file_field was not a hashref or code ref. Check spec syntax.";
        }

        # inherit mime-type and extension from parent
        # but merge in updated details for this file
        my $meta_from_gen_file = $self->extract_meta($gen_tmp_filename,$gen_file);
           $meta_from_gen_file ||= {};
        my %t_info =  (%$meta, gen_from_id => $gen_from_id, %$meta_from_gen_file);



        # Try to get image dimensions (will fail safely for non-images)
        #($t_info{width}, $t_info{height}) = imgsize($gen_tmp_filename);

        # Insert
        my $id = $self->store_meta($gen_file, \%t_info );

        # Add to output hash
        $out{$gen_file.'_id'} = $id;

        $self->store_file($gen_file,$id,$t_info{extension},$gen_tmp_filename);
    }
    return %out;
}

=head2 delete_upload()

  $u->delete_upload($upload_id);

This method is used to delete the meta data and file associated with an upload.
Usually it's more convenient to use C<delete_checked_uploads> than to call this
method directly.

This method does not delete generated files for this upload.

=cut

sub delete_upload {
    my $self = shift;
    my ($id) = @_;

    $self->delete_file($id);
    $self->delete_meta($id);

}

=head2 delete_gen_files()

 $self->delete_gen_files($id);

Delete the generated files  for a given file ID, from the file system and the database

=cut

sub delete_gen_files {
    validate_pos(@_,1,1);
    my ($self,$id) = @_;

    my $dbh = $self->{dbh};
    my $map = $self->{up_table_map};

    my $gen_file_ids_aref = $dbh->selectcol_arrayref(
        "SELECT   $map->{upload_id}
            FROM  ".$self->{up_table}. "
            WHERE $map->{gen_from_id} = ?",{},$id) || [];

    for my $gen_file_id (@$gen_file_ids_aref) {
        $self->delete_file($gen_file_id);
        $self->delete_meta($gen_file_id);
    }

}

=head1 Meta-data Methods

=head2 extract_meta()

 $meta = $self->extract_meta($tmp_filename,$file_name,$uploaded_mt);

This method extracts and returns the meta data about a file and returns it.

Input:

 - Path to file to extract meta data from
 - the name of the file (as sent through the file upload file)
 - The mime-type of the file, as supplied by the browser

Returns: a hash reference of meta data, following this example:

 {
         mime_type => 'image/gif',
         extension => '.gif',
         bytes     => 60234,
         file_name => 'happy.txt',

         # only for images
         width     => 50,
         height    => 50,
 }

=cut

sub extract_meta {
    validate_pos(@_,1,1,1,0);
    my $self = shift;
    my $tmp_filename = shift;
    my $file_name = shift;
    my $uploaded_mt = shift || '';

    #   Determine and set the appropriate file system parsing routines for the
    #   uploaded path name based upon the HTTP client header information.
    use HTTP::BrowserDetect;
    my $client_os = $^O;
    my $browser = HTTP::BrowserDetect->new;
    $client_os = 'MSWin32' if $browser->windows;
    $client_os = 'MacOS'   if $browser->mac;
    $client_os = 'Unix'    if $browser->macosx;
    require File::Basename;
    File::Basename::fileparse_set_fstype($client_os);
    $file_name = File::Basename::fileparse($file_name,[]);


   require File::MMagic;
   my $mm = File::MMagic->new;

   # If the uploaded  mime_type was not provided  calculate one from the file magic number
   # if that does not exist, fall back on the file name
   my $fm_mt = $mm->checktype_magic($tmp_filename);
      $fm_mt = $mm->checktype_filename($tmp_filename) if (not defined $fm_mt or not length $fm_mt) ;

   my $mt = ($uploaded_mt || $fm_mt);
   assert($mt,'found mime type');


   use MIME::Types;
   my $mimetypes = MIME::Types->new;
   my MIME::Type $t = $mimetypes->type($mt);
   my @mt_exts = $t ? $t->extensions : undef;

   my $ext;

   # figure out an extension
   my ($uploaded_ext) = ($file_name =~ m/\.([\w\d]*)?$/);

   # If there is at least one MIME-type found
   if ($mt_exts[0]) {
        # If the upload extension is one recognized by MIME::Type, use it.
        if ((defined $uploaded_ext)
            and (grep {/^$uploaded_ext$/} @mt_exts)) {
            $ext = $uploaded_ext;
        }
        # otherwise, use one from MIME::Type, just to be safe
        else {
            $ext = $mt_exts[0];
        }
   }
   else {
       # If is a provided extension but no MIME::Type extension, use that.
       # It's possible that there no extension uploaded or found)
       $ext = $uploaded_ext;
   }

   if ($ext) {
        $ext = ".$ext" if $ext;
   }
   else {
       croak "no extension found for file name: $file_name";
   }


   # Now get the image dimensions if it's an image
    my ($width,$height) = imgsize($tmp_filename);

    return {
        file_name => $file_name,
        mime_type => $mt,
        extension => $ext,
        bytes     => (stat ($tmp_filename))[7],

        # only for images
        width     => $width,
        height    => $height,
    };


}

=head2 store_meta()

 my $id = $self->store_meta($file_field,$meta);

This function is used to store the meta data of a file upload.

Input:

 - file field name

 - A hashref of key/value pairs to be stored. Only the key names defined by the
   C<up_table_map> in C<new()> will be used. Other values in the hash will be
   ignored.

 - Optionally, an upload ID can be passed, causing an 'Update' to happen instead of an 'Insert'

Output:
  - The id of the file stored. The id is generated by store_meta().

=cut

sub store_meta {
    validate_pos(@_,1,1,1,0);
    my $self = shift;

    # Right now we don't use the the file field name
    # It seems like a good idea to have in case you want to sub-class it, though.
    my $file_field  = shift;
    my $href = shift;
    my $id = shift;

    my $DBH = $self->{dbh};

    require SQL::Abstract;
    my $sql = SQL::Abstract->new;
    my $map = $self->{up_table_map};
    my %copy = %$href;

    my $is_update = 1 if $id;

    if (!$is_update && $self->{db_driver} eq 'Pg') {
        $id = $DBH->selectrow_array("SELECT NEXTVAL('".$self->{up_seq}."')");
    $copy{$map->{upload_id} } = $id;
    }

    my @orig_keys = keys %copy;
    for (@orig_keys) {
        if (exists $map->{$_}) {
            # We're done if the names are the same
            next if ($_ eq $map->{$_});

            # Replace each key name with the mapped name
            $copy{ $map->{$_} } = $copy{$_};

        }
        # The original field is now duplicated in the hash or unknown.
        # delete in either case.
        delete $copy{$_};
    }

    my ($stmt,@bind);
    if ($is_update) {
     ($stmt,@bind)   = $sql->update($self->{up_table},\%copy, { $map->{upload_id} => $id });
    }
    else {
     ($stmt,@bind)   = $sql->insert($self->{up_table},\%copy);
    }

    $DBH->do($stmt,{},@bind);
    if (!$is_update && $self->{db_driver} eq 'mysql') {
        $id = $DBH->{'mysql_insertid'};
    }
    if (!$is_update && $self->{db_driver} eq 'SQLite') {
      $id = $DBH->func('last_insert_rowid')
    }

    return $id;
}

=head2 delete_meta()

 my $dbi_rv = $self->delete_meta($id);

Deletes the meta data for a file and returns the DBI return value for this operation.

=cut

sub delete_meta {
    validate_pos(@_,1,1);
    my $self = shift;
    my $id = shift;

    my $DBH = $self->{dbh};
    my $map = $self->{up_table_map};

   return $DBH->do("DELETE from ".$self->{up_table}." WHERE $map->{upload_id} = $id");

}

=head2 transform_meta()

 my %meta_to_display = $u->transform_meta(
        meta   => $meta_from_db,
        prefix => 'my_field',
        prevent_browser_caching => 0,
        fields => [qw/id url width height/],
    );

Prepares meta data from the database for display.


Input:
 - meta:   A hashref, as might be returned from "SELECT * FROM uploads WHERE upload_id = ?"

 - prefix: the resulting hashref keys will be prefixed with this,
   adding an underscore as well.

 - prevent_browse_caching: If set to true, a random query string
   will be added, preventing browsings from caching the image. This is very
   useful when displaying an image an 'update' page. Defaults to true.

 - fields: An arrayef of fields to format. The values here must be
   keys in the C<up_table_map>. Two field names are special. 'C<id> is
   used to denote the upload_id. C<url> combines several fields into
   a URL to link to the upload.

Output:
 - A formatted hash.

See L</fk_meta()> for example output.

=cut

sub transform_meta  {
    my $self = shift;
    my %p = validate(@_, {
        meta   => { type => HASHREF },
        prefix => { type => SCALAR  },
        prevent_browser_caching => { default => 1 },
        fields => { type => ARRAYREF ,
                    default => [qw/id url width height/],
                },
        });
#   return undef unless (ref $p{meta} eq 'HASH');

    my $map = $self->{up_table_map};

    my %result;

    my $qs;
    if ($p{prevent_browser_caching})  {
        # a random number to defeat image caching. We may want to change this later.
        my $rand = (int rand 100);
        $qs = "?$rand";
    }

    my %fields = map { $_ => 1 } @{ $p{fields} };

    if ($fields{url}) {
        $result{$p{prefix}.'_url'} = $self->{updir_url}.'/'.
            $self->build_loc(
                $p{meta}{ $map->{upload_id} }
               ,$p{meta}{ $map->{extension} })
               .$qs ;
        delete $fields{url};
    }

    if (exists $fields{id}) {
        $result{$p{prefix}.'_id'} = $p{meta}->{ $map->{upload_id} };
        delete $fields{id};
    }

    for my $k (keys %fields) {
        my $v = $p{meta}->{ $map->{$k} };
        $result{$p{prefix}.'_'.$k} = $v if defined $v;
    }

    return %result;


}

=head2 get_meta()

 my $meta_href = $self->get_meta($id);

Returns a hashref of data stored in the uploads database table for the requested file id.

=cut

sub get_meta {
  validate_pos(@_,1,1);
  my ($self,$id) = @_;

  my $map = $self->{up_table_map};
  return  $self->{dbh}->selectrow_hashref("
            SELECT * FROM $self->{up_table}
                WHERE $map->{upload_id} = ?",{},$id);
}



=head1 File Methods

=head2 store_file()

 $self->store_file($file_field,$tmp_file,$id,$ext);

Stores an upload file or dies if there is an error.

Input:
  - file field name
  - path to tmp file for uploaded image
  - file id, as generated by C<store_meta()>
  - file extension, as discovered by L<extract_meta()>

Output: none

=cut

sub store_file {
    validate_pos(@_,1,1,1,1,1);
    my $self = shift;
    my ($file_field,$id,$ext,$tmp_file) = @_;
    assert($ext, 'have extension');
    assert($id,'have id');
    assert(-f $tmp_file,'tmp file exists');
    assert(-d $self->{updir_path},'updir_path is a directory');
    assert(-w $self->{updir_path},'updir_path is writeable');

    require File::Copy;
    import File::Copy;
    copy($tmp_file, File::Spec->catdir($self->{updir_path},$self->build_loc($id,$ext)) )
    || croak "Unexpected error occured when uploading the image: $!";

}

=head2 delete_file()

 $self->delete_file($id);

Call from within C<delete_upload>, this routine deletes the actual file.
Dont' delete the the meta data first, you may need it build the path name
of the file to delete.

=cut

sub delete_file {
    validate_pos(@_,1,1);
    my $self = shift;
    my $id   = shift;

    my $map = $self->{up_table_map};
    my $dbh = $self->{dbh};

    my $ext = $dbh->selectrow_array("
        SELECT $map->{extension}
            FROM $self->{up_table}
            WHERE $map->{upload_id} = ?",{},$id);
    $ext || croak "found no extension in meta data for ID $id. Deleting file failed.";


    my $file = $self->{updir_path}.'/'.$self->build_loc($id,$ext);

    if (-e $file) {
        unlink $file || croak "couldn't delete upload  file: $file:  $!";
    }
    else {
        warn "file to delete not found: $file";
    }

}

=head1 Utility Methods

=head2 build_loc()

 my $up_loc = $self->build_loc($id,$ext);

Builds a path to access a single upload, relative to C<updir_path>.
This is used to both file-system and URL access. Also see the C<file_scheme>
option to C<new()>, which affects it's behavior.

=cut

sub build_loc {
    validate_pos(@_,1,1,0);
    my ($self,$id,$ext) = @_;

    my $scheme = $self->{file_scheme};

    my $loc;
    if ($scheme eq 'simple') {
        $loc = "$id$ext";
    }
    elsif ($scheme eq 'md5') {
        require Digest::MD5;
        import Digest::MD5 qw/md5_hex/;
        my $md5_path = md5_hex($id);
        $md5_path =~ s|^(.)(.)(.).*|$1/$2/$3|;

        my $full_path = $self->{updir_path}.'/'.$md5_path;
        unless (-e $full_path) {
            mkpath($full_path);
        }


        $loc = File::Spec->catdir($md5_path,"$id$ext");
    }
}

=head2 upload_field_names()

 # As a class method
 (@file_field_names) = CGI::Uploader->upload_field_names($q);

 # As an object method
 (@file_field_names) = $u->upload_field_names();

Returns the names of all form fields which contain file uploads. Empty
file upload fields may be excluded.

This can be useful for auto-generating a C<spec>.

Input:
 - A query object is required as  input only when called as a class method.

Output:
 - an array of the file upload field names.

=cut

sub upload_field_names {
    my $self = shift;
    my $q = shift || $self->{query};

    my @file_field_names;
    if ( $q->isa('CGI::Simple') ) {
        my @list_of_files   = $q->upload;
        my @all_field_names = $q->param();
        for my $field (@all_field_names) {
            my $potential_file_name = $q->param($field);
            push @file_field_names, $field , if grep {m/^$potential_file_name/} @list_of_files;
        }
    }
    elsif ($q->isa('Apache::Request') ) {
        @file_field_names = map { $_->name } @{ $q->upload() };
    }
    # default to CGI.pm behavior
    else  {
        my @all_field_names = $q->param();
        for my $field (@all_field_names) {
            push @file_field_names, $field , if $q->upload($field);
        }
    }

    return @file_field_names;

}






=head2 spec_names()

 $spec_names = $u->spec_names('file_field'):

With no arguments, returns an array of all the upload names defined in the
spec, including any generated file names.

With one argument, a file field from the spec, can also be provided. It then returns
that name as well as the names of any related generated files.

=cut

sub spec_names {
    my $self = shift;
    my $spec_key = shift;

    my $all_keys = $self->{spec};

    # only use $spec_key if it was passed in
    my @primary_spec_keys_to_use  =  (defined $spec_key) ? $spec_key  : keys %$all_keys;

    my @gen_files = @primary_spec_keys_to_use,
        map { keys %{ $all_keys->{$_}{gen_files} } } @primary_spec_keys_to_use;
}

1;
__END__

=head1 Contributing

Patches, questions and feedback are welcome. I maintain CGI::Uploader using
git. The public repo is here: https://github.com/markstos/CGI--Uploader

=head1 Author

Mark Stosberg <mark@summersault.com>

=head1 Thanks

A special thanks to David Manura for his detailed and persistent feedback in
the early days, when the documentation was wild and rough.

Barbie, for the first patch.

=head1 License

This program is free software; you can redistribute it and/or modify
it under the terms as Perl itself.

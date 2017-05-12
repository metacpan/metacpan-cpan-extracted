package Data::Downloader::Config;

=head1 NAME

Data::Downloader::Config

=head1 SYNOPSIS

 # command line :
 dado config init --filename=my_config_file.txt
 dado config update --filename=my_config_file_modified.txt

Module :

 use Data::Downloader;
 Data::Downloader::Config->init( filename => "my_config_file.txt"):
 Data::Downloader::Config->init( yaml => qq[...some yaml...] );

=head1 DESCRIPTION

Configure Data::Downloader.

Data::Downloader uses sqlite to store both its configuration
and data about the files which are downloaded.  (For the location
of this sqlite file, see L<Data::Downloader::DB>.)
The configuration describes url patterns, file metadata, RSS feeds,
and how to create trees of symbolic links to various subsets of the
files that are downloaded.

DD::Config can also update the configuration by reading a new
file and determining which changes have been made.  Any changes
will _only_ affect the configuration, they will not cause changes
to any of the metadata that has been stored, or the location of
any of the files on disk.  Certain configuration changes may be
invalid, if they would cause the database to inconsistent.  In
such cases, to force a configuration change, you may need to
either remove the database file and start from scratch, or else
use SQL commands to manually update the configuration within the
database to reflect a re-organization of items on disk.

=head1 FORMAT

DD uses L<YAML|YAML::XS> to read files; please see that page for documentation
about YAML.

A configuration file is a collection of yaml "documents"; a sequence of
lines separated by lines containing only three dashes ("---').  Each of
these documents represents a Data::Downloader::Repository.  A repository
is a collection of files stored in a common root directory.  The first
few fields of a repository are :

 ---
 name: my_repo

An arbitrary name for this repository.  This name will reflect the character
of this data, e.g. "images", "videos", "web_pages", "ozone_data". (required)

 storage_root: /path/to/root/storage

The root directory for the storage of files. (required)

 file_url_template: 'http://somehost.com/<variable1>/<variable2>/<date_variable:%Y/%m/%d>

This is a String::Template style string for downloading files.  This is required if
data will be downloaded directly from urls using this template.  The variables listed
in the template will become required command-line arguments to dado, e.g.

 dado download file --variable1=foo --variable2==bar --date_variable='2001-03-04'

URLs may also come from RSS feeds (below), in which case the file_url_template is not
relevant.

 cache_strategy: LRU

The strategy for cache expiration.  Currently only LRU is supported. (required)

 cache_max_size: 1073741824

The approximate maximum size (in bytes) for the cache.  The cache size is
checked before downloading files (this may change to be less frequent). (required)

 disks:
   - root: disk1/
   - root: disk2/
   - root: disk3/

These are top level subdirectories of "storage_root" in which to
place files.  In practice, these may be located on different devices.
Currently new files will be placed in the directory whose device has
the most free space (as determined by "df").  If two partitions have the
same amount of free space, the new file will be placed on the one which
has the most free space within that directory (i.e. the sum of DD's files
is the smallest).  If those are the same, a random one will be used.

 feeds:

If there are RSS feeds that describe the locations (and/or metadata) of the
files, they may be listed in a "feeds" section.  Each feed is a Data::Downloader::Feed.
The syntax is simplest if there is only one feed, but it is possible to specify
multiple feeds (see EXAMPLES)

    name: georss

Each feed also has an arbitrary "name", used to identify it.  The name
should correspond to the source of the RSS feed.

    feed_template: 'http://example.com/some/feed/<var1>/<var2>/<var3>

This is a String::Template string (or just a string if there are no
variables) which describes the url for the RSS feed.  Variables in the
template will become required command-line arguments to dado when
refreshing the feed, e.g.

   dado feeds refresh --var1=foo --var2=bar --var3=baz

It is also possible to assign default values to some of the parameters in
the template, in which case they will be optional.  This happens like so :

    feed_parameters:
        - name: var1
          default_value: 'foo'
        - name: var2
          default_value: 'bar'

With the above defaults, var1 and var2 could be omitted from the command line :

   dado feeds refresh --var3=baz

An RSS feed contains various items in <item></item> tags.  An atom feed uses
"entry" instead of "item".
Within these tags, there may be information about the location of the files
to be downloaded, as well as various pieces of metadata that should be stored
(so that they may be used to construct symbolic links and search for files).

   file_source:
       filename_xpath: 'some_xpath_within_item'
       md5_xpath: 'another_one'
       url_path: 'yet_another_one'

These lines describe where to find the filename, md5 and url of an individual file
within the <item> (or <entry>) tags.  e.g. for the example above, the full (document-level) xpath
for the filename would be //item/some_xpath_within_item.

Note that if an RSS feed contains tags with namespaces, then (per the xpath
specification) all of the tags need namespaces.  Data::Downloader assigns tags
with no namespace to a namespace named "default".  So, e.g. if the RSS
feed contains <link> within an <item> (entry), but there are also tags like <datacasting:orbit>,
then the xpath for <link> will be //default:item/default:link.  And url_path, above,
would be "default:link".  See L<XML::LibXML::Node> for a discussion of this.

   metadata_sources:
       - name: metadata_var1
         xpath: metadata_var1s_xpath_in_an_item
       - name: metadata_var2
         xpath: nother_xpath_in_an_item

These are the xpaths within an //item for pieces of metadata to be stored for each file.
The above indicates that //item/metadata_var1s_xpath_in_an_item describes a piece of data that
should be called "metadata_var1".  Keep reading to see how to use these.

 linktrees:

This section (one per data source, not one per feed) describes a list of trees
(each is a Data::Downloader::Linktree) of symbolic links to be maintained;
the symlinks will point to data within the repository.

  - root: /some/path/where/these/symlinks/go
    condition: '{ metadata_var1 => "a value for this piece of data"}'
    path_template: some/subdir/that/uses/vars/<metadata_var1>/<metadata_var2>
  - root: /another/path/for/more/symlinks
    condition: '{ metadata_var2 => { ">=" => 42, "<=" => 99 }'
    path_template: anothersubdir/<metadata_var2>

Each linktree has a "root" (an absolute path), a condition (an SQL::Template style
clause for limiting which files get symlinks under this path.  Use "~" to get all
files"), and a "path_template" (a String::Template string for laying out the symlinks).

=cut

use Log::Log4perl qw/:easy/;
use Params::Validate qw/validate/;
use YAML::XS qw/Dump Load LoadFile/;
use Scalar::Util qw/looks_like_number/;
use Data::Dumper;

use strict;
use warnings;

=head1 METHODS

=over

=item init

Inserts information about repository and feeds
using a config file.

Parameters :

 filename: the name of a config file
 yaml: yaml content of the file (can be sent instead of file)
 update_ok: allow updates, not just initialization

=cut

sub init {
    my $self = shift;
    my $args = validate(@_, { file => 0, filename => 0, yaml => 0, update_ok => 0 } );
    my $file = $args->{file} || $args->{filename};
    DEBUG "initializing database from ".($file ? "file $file" : "yaml");

    my @repositories = $args->{yaml} ? Load($args->{yaml}) : LoadFile($file);
    DEBUG "Configuration has ".@repositories." repository(ies)";
    for my $repository_spec (@repositories) {
        TRACE "repository : ".$repository_spec->{name};
        my $repository = Data::Downloader::Repository->new(name => $repository_spec->{name});
        if ($repository->load(speculative => 1)) {
            if ($args->{update_ok}) {
                _recursive_object_update($repository,$repository_spec);
            } else {
                LOGDIE "Existing repository ".$repository->name." found. ".
                     "To re-initialize, remove ".$repository->db->database.
                     ".  To update, set update_ok to be true.";
            }
        } else {
            # XXX not bulletproof -- the new one may refer to existing feeds, etc.
            INFO "creating new repository $repository_spec->{name}";
            $repository = Data::Downloader::Repository->new(%$repository_spec);
            $repository->save or LOGDIE "Error saving repository $repository_spec->{name}: ".$repository->error;
        }
    }

    Data::Downloader::MetadataPivot->rebuild_pivot_view;
}

=item update

Update the config

=cut

sub update {
    my $self = shift;
    my %args = @_;
    $args{update_ok} = 1;
    $self->init(%args);
}

sub _p { defined($_[0]) ? "[$_[0]]" : '[undef]' };

sub _are_same {
    my ($x,$y) = @_;
    return 0 if defined($x) && !defined($y);
    return 0 if !defined($x) && defined($y);
    return 1 if !defined($x) && !defined($y);
    # ok, both are defined
    if (looks_like_number($x) && looks_like_number($y)) {
        return ($x==$y);
    }
    return ($x eq $y);
}

our %classDone; # prevent loops for one-one relationships
our %allowConfig = map { ($_ => 1) } qw/repository
        disk feed feed_parameter metadata_source file_source linktree metadata_transformation/;

sub _recursive_object_update {
    my $object = shift;
    my $spec = shift;
    # $object should have already been loaded
    # Update all attributes which are not objects.
    # Then find child objects and recursively update existing ones.
    TRACE "examining table ".$object->meta->table.($object->can('id') ? $object->id : $object);
    # one base case
    if (!defined($spec)) {
        INFO "Deleting ".$object->meta->table." ".($object->can('id') ? $object->id : $object);
        $object->delete or LOGDIE "error during delete : ".$object->error;
        return;
    }
    # other base cases
    for my $column_name (keys %$spec) {
        TRACE "column $column_name";
        my ($column) = grep { $_->accessor_method_name eq $column_name } $object->meta->columns;
        next unless $column; # not a column, must be a relationship
        next if $column->is_primary_key_member;
        next if $column_name =~ /^(root|name|order_key)$/; # primary keys, don't allow changing
        die "'$column' not defined, name is '$column_name' " unless exists($spec->{$column_name});
        TRACE "comparing ".($object->meta->table).".$column : "._p($object->$column)." vs "._p($spec->{$column_name});
        next if _are_same($object->$column,$spec->{$column_name});
        INFO "Changing ".$object->meta->table." $column_name from "._p($object->$column)." to "._p($spec->{$column_name});
        $object->$column($spec->{$column});
        $object->save or LOGDIE "error saving changes to ".$object->meta->table." : ".$object->error;
    }
    # recursive case
    for my $relationship ($object->meta->relationships) {
        my $method_name = $relationship->method_name('get_set_on_save');
        next if $classDone{$relationship->class}++;
        next unless $allowConfig{$relationship->class->meta->table};
        next unless $relationship->type eq 'one to many' || $relationship->type eq 'one to one';
        my $sub_object_spec = $spec->{$method_name};
        $sub_object_spec = [ $sub_object_spec ] if $sub_object_spec && ref($sub_object_spec) ne 'ARRAY';
        for my $sub_object ($object->$method_name) {
            TRACE "looking at $method_name";
            unless (defined($sub_object)) {
                TRACE "skipping $method_name, no objects";
                next;
            }
            $sub_object->load;
            LOGDIE "TODO delete $method_name objects" unless exists $spec->{$method_name}; # TODO
            my $sub_spec;
            if ($relationship->type eq 'one to one') {
                _recursive_object_update($sub_object,$sub_object_spec->[0]);
                @$sub_object_spec = ();
            } else {
                my $key =
                    $sub_object->can('name')      ? 'name'
                  : $sub_object->can('root')      ? 'root'
                  : $sub_object->can('order_key') ? 'order_key'
                  :                                 undef;
                ($sub_spec) = grep { $_->{$key} eq $sub_object->$key} @$sub_object_spec;
                @$sub_object_spec = grep { $_->{$key} ne $sub_object->$key } @$sub_object_spec;
                unless (defined($sub_spec)) {
                    TRACE "did not find existing ".$sub_object->meta->table." where $key = ".$sub_object->$key;
                }
                _recursive_object_update($sub_object,$sub_spec);
            }
        }
        for my $new_sub_object (@$sub_object_spec) {
            INFO "adding ".$relationship->class->meta->table;
            TRACE "new object : ".Dumper($new_sub_object);
            my $eponymous_key_name = $object->meta->table;
            my $new = $relationship->class->new(%$new_sub_object, $eponymous_key_name => $object->id);
            $new->save or LOGDIE "error saving : ".$new->error;
        }
    }
}

=item dump

Dump the config.

Parameters :

  format - the format (yaml, array)

=cut

sub dump {
    die "not implemented";
    my $self = shift;
    my $args = validate(@_, { format => qr/^(yaml|arrayref)$/ } );
    my @conf;
    for my $repository (@{ Data::Downloader::Repository::Manager->get_repositories }) {
        my %this = %{ $repository->as_hash };
        # TODO: assign to children
        push @conf, \%this;
    }
    return \@conf;
}

=back

=head1 EXAMPLES

Here's a sample configuration file :

    ---
    name: my_images
    storage_root: /some/where
    feeds: [ { name          : flickr,
               feed_template : 'http://api.flickr.com/services/feeds/photos_public.gne?tags=<tags>&lang=en-us&format=rss_200',
               file_source   : {
                    url_xpath      : 'media:content/@url',
                    filename_xpath : 'media:content/@url',
                    filename_regex : '/([^/]*)$'
               },
               metadata_sources: [
                   { name: 'date_taken', xpath: 'dc:date.Taken'  },
                   { name: 'tags',       xpath: 'media:category' } ]
             },
             { name             : smugmug,
               feed_template    : TODO,
               file_source      : TODO,
               metadata_sources : TODO
             }
           ]
    
    linktrees :
         - root: /images
           condition: ~
           path_template: '<date_taken:%Y/%m/%d>'

=head1 SEE ALSO

L<Data::Downloader>

L<Data::Downloader::DB>

=cut

1;


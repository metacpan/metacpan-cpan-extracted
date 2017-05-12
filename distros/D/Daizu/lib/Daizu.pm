package Daizu;
use warnings;
use strict;

use XML::LibXML;
use DBI;
use SVN::Ra;
use Path::Class qw( dir );
use Carp qw( croak );
use Carp::Assert qw( assert DEBUG );
use Daizu::Revision;
use Daizu::Wc;
use Daizu::Util qw(
    trim trim_with_empty_null
    validate_number validate_uri validate_mime_type
    validate_date db_datetime
    db_row_exists db_row_id db_select db_insert db_update db_delete
    wc_file_data
    guid_first_last_times
    load_class
    xml_attr xml_croak
    daizu_data_dir
);

=head1 NAME

Daizu - class for accessing Daizu CMS from Perl

=head1 INTRODUCTION

Daizu CMS is an experimental content management system.  It uses content
stored in a Subversion repository, and keeps track of it in a PostgreSQL
database.  It is an attempt to solve some of the underlying problems of
content management once and for all.  As such the development so far has
focused on the 'back end' parts of the system, and it doesn't really have
a user interface to speak of.  It's certainly not ready for less technical
users yet.  More information is available on the Daizu website:

L<http://www.daizucms.org/>

=head1 DESCRIPTION

Most access to Daizu functionality requires a Daizu object.  It provides
a database handle for access to the 'live' content data, and a L<SVN::Ra>
object for access to the Subversion repository.

Some other classes are documented as requiring a C<$cms> value as the
first argument to their constructors or methods.  This should always be
a Daizu object.

=head2 CONSTANTS

=over

=item $Daizu::VERSION

The version number of Daizu CMS (as a whole, not just this module).

=item $Daizu::DEFAULT_CONFIG_FILENAME

The full path and filename of the config file which will be read by
default, if none is specified in the constructor call or the environment.

Value: I</etc/daizu/config.xml>

=item $Daizu::CONFIG_NS

The URI used as an XML namespace for the elements in the config file.

Value: L<http://www.daizucms.org/ns/config/>

=item $Daizu::HTML_EXTENSION_NS

The URI used as an XML namespace for special elements in XHTML content.

Value: L<http://www.daizucms.org/ns/html-extension/>

=item $Daizu::HIDING_FILENAMES

A list of file and directory names which prevent any publication of
files with one of the names, or anything inside a directory so named.
Separated by '|' so that the whole string can be included in Perl
and PostgreSQL regular expressions.

Value: C<_template|_hide>

=cut

our $VERSION = '0.3';

our $DEFAULT_CONFIG_FILENAME = '/etc/daizu/config.xml';
our $CONFIG_NS = 'http://www.daizucms.org/ns/config/';
our $HTML_EXTENSION_NS = 'http://www.daizucms.org/ns/html-extension/';
our $HIDING_FILENAMES = '_template|_hide|_lib';

=item %OVERRIDABLE_PROPERTY

A hash describing which pieces of metadata can be overridden by article
loader plugins.  The keys are the names of Subversion properties, and
the values are the names of columns in the C<wc_file> table.

=cut

our %OVERRIDABLE_PROPERTY = (
    'dc:title' => 'title',
    'dc:description' => 'description',
    'daizu:short-title' => 'short_title',
);

=back

=head2 METHODS

=over

=item Daizu-E<gt>new($config_filename)

Return a Daizu object based on the information in the given configuration
file.  If C<$config_filename> is not supplied, it will fall back on any
file specified by the C<DAIZU_CONFIG> environment variable, and then
by the default config file (see C<$DEFAULT_CONFIG_FILENAME> above).

The value returned will be called C<$cms> in the documentation.

For information about the format of the configuration file, see
the documentation on the website:
L<http://www.daizucms.org/doc/config-file/>

=cut

# This ensures that @INC is only fiddled with once for each Daizu installation.
# The keys are the URIs of content repositories.  If an entry exists for a
# particular repository, then its _lib directory has already been added.
my %added_lib_path;

sub new
{
    my ($class, $filename) = @_;

    if (!defined $filename) {
        if (defined $ENV{DAIZU_CONFIG}) {
            $filename = $ENV{DAIZU_CONFIG};
        }
        elsif (-r $DEFAULT_CONFIG_FILENAME) {
            $filename = $DEFAULT_CONFIG_FILENAME;
        }
        else {
            croak "cannot find Daizu configuration file" .
                  " (set DAIZU_CONFIG environment variable)";
        }
    }

    croak "Bad config file '$filename', not a normal file\n"
        unless -f $filename;

    my $self = bless { config_filename => $filename }, $class;

    my $parser = XML::LibXML->new;
    my $doc = $parser->parse_file($filename);
    my $root = $doc->documentElement;
    xml_croak($filename, $root, "root element must be <config>")
        unless $root->localname eq 'config';
    xml_croak($filename, $root, "root element in wrong namespace")
        unless defined $root->namespaceURI && $root->namespaceURI eq $CONFIG_NS;

    # Open database connection.
    {
        my $elem = _singleton_conf_elem($filename, $root, 'database');
        my $dsn = xml_attr($filename, $elem, 'dsn');
        my $user = $elem->getAttribute('user');
        die "$filename: <database> should have 'user' attribute, not 'username'"
            if !defined $user && $elem->hasAttribute('username');
        my $password = $elem->getAttribute('password');
        $self->{db} = DBI->connect($dsn, $user, $password, {
            AutoCommit => 1,
            RaiseError => 1,
            PrintError => 0,
        });
    }

    # Open Subversion remote-access connection.
    my $svn_url;
    {
        my $elem = _singleton_conf_elem($filename, $root, 'repository');
        $svn_url = xml_attr($filename, $elem, 'url');
        my $svn_username = xml_attr($filename, $elem, 'username', '');
        my $svn_password = xml_attr($filename, $elem, 'password', '');

        my $auth_callback = sub {
            my ($creds, $realm, $default_username, $may_save, $pool) = @_;

            $creds->username($svn_username);
            $creds->password($svn_password);

            # There's no real reason to cache this stuff since we can always
            # get it from the config files, so we don't cache to avoid
            # confusion, and in case we're running as a special user with
            # a home directory we can't write to.
            $creds->may_save(0);
        };

        $self->{ra} = SVN::Ra->new(
            url => $svn_url,
            ($svn_username eq '' && $svn_password eq '' ? () : (auth => [
                SVN::Client::get_simple_prompt_provider($auth_callback, 0),
            ])),
        );
    }

    # Get live working copy ID.
    {
        my $elem = _singleton_conf_elem($filename, $root, 'live-working-copy');
        my $wc_id = xml_attr($filename, $elem, 'id');
        $self->{live_wc_id} = validate_number($wc_id);
        xml_croak($filename, $elem, "bad WC ID in <live-working-copy>")
            unless defined $self->{live_wc_id};
    }

    # Path to directory containing the default templates distributed with
    # Daizu, and possibly also to a directory where templates should be
    # loaded during testing instead of from the database.
    {
        $self->{template_default_path} = daizu_data_dir('template');
        my ($elem) = $root->getChildrenByTagNameNS($CONFIG_NS, 'template-test');
        $self->{template_test_path} = xml_attr($filename, $elem, 'path')
            if defined $elem;
    }

    # Add to @INC the '_lib' directory from the content repository, either
    # by loading files from the live working copy, or from the 'template-test'
    # path.
    unless (exists $added_lib_path{$svn_url}) {
        if (defined $self->{template_test_path}) {
            push @INC, dir($self->{template_test_path})->subdir('_lib')
                                                       ->stringify;
        }
        else {
            push @INC, sub {
                my (undef, $filename) = @_;
                my $file_id = db_row_id($self->{db}, 'wc_file',
                    wc_id => $self->{live_wc_id},
                    path => "_lib/$filename",
                );
                return undef unless defined $file_id;
                my $data = wc_file_data($self->{db}, $file_id);
                open my $fh, '<', $data
                    or die "error opening memory file for '_lib/$filename': $!";
                return $fh;
            };
        }

        $added_lib_path{$svn_url} = undef;
    }

    # How output should be published.
    for my $elem ($root->getChildrenByTagNameNS($CONFIG_NS, 'output')) {
        my $url = trim(xml_attr($filename, $elem, 'url'));
        my $path = trim(xml_attr($filename, $elem, 'path'));
        my $url_ob = validate_uri($url);
        xml_croak($filename, $elem, "<output> has invalid URL '$url'")
            unless defined $url_ob;
        xml_croak($filename, $elem, "<output> has non-HTTP URL '$url'")
            unless defined $url_ob->scheme && $url_ob->scheme =~ /^https?/i;
        $url = $url_ob->canonical;
        xml_croak($filename, $elem, "more than one <output> element for '$url'")
            if exists $self->{output}{$url};

        my $redirect_map = trim(xml_attr($filename, $elem, 'redirect-map', ''));
        my $gone_map = trim(xml_attr($filename, $elem, 'gone-map', ''));
        for ($redirect_map, $gone_map) {
            $_ = undef if $_ eq '';
            next unless defined;

            # Check for duplicate filenames.
            while (my ($other_url, $config) = each %{$self->{output}}) {
                for my $map (qw( redirect gone )) {
                    xml_croak($filename, $elem, "filename '$_' duplicates" .
                              " '$map-map' for '$other_url' config")
                        if defined $config->{"${map}_map"} &&
                           $config->{"${map}_map"} eq $_;
                }
            }
        }

        my $index_filename = trim(xml_attr($filename, $elem, 'index-filename',
                                           'index.html'));

        $self->{output}{$url} = {
            url => $url_ob,
            path => $path,
            redirect_map => $redirect_map,
            gone_map => $gone_map,
            index_filename => $index_filename,
        };
    }

    # Initialize hooks for plugins.
    $self->{property_loaders}{'*'} = [ [ $self => '_std_property_loader' ] ];
    $self->{html_dom_filters} = {};
    $self->{article_loaders} = {};

    # Read global configuration for things which can be overridden for
    # specific paths.
    $self->_read_config_for_path($filename, $root, '');
    xml_croak($filename, $root, "no default <guid-entity> element")
        unless defined $self->{default_entity};

    # Read path-specific configuration in each inner <config> element.
    for my $elem ($root->getChildrenByTagNameNS($CONFIG_NS, 'config')) {
        xml_croak($filename, $elem, "inner <config> elements must have path")
            unless $elem->hasAttribute('path');
        my $path = $elem->getAttribute('path');
        xml_croak($filename, $elem, "inner <config> element's path is empty")
            if $path eq '';
        $self->_read_config_for_path($filename, $elem, $path);
    }

    return $self;
}

sub _read_config_for_path
{
    my ($self, $filename, $config, $path) = @_;
    xml_croak($filename, $config, "<config> element has bad path '$path'")
        if $path =~ /^\// || $path =~ /\/$/;

    # Load information for minting GUID URLs.
    for my $elem ($config->getChildrenByTagNameNS($CONFIG_NS, 'guid-entity')) {
        my $entity = trim(xml_attr($filename, $elem, 'entity'));
        xml_croak($filename, $elem, "<guid-entity> has empty entity")
            if $entity eq '';

        if ($path eq '') {
            xml_croak($filename, $elem,
                      "more than one default (pathless) <guid-entity> element")
                if defined $self->{default_entity};
            $self->{default_entity} = $entity;
        }
        else {
            xml_croak($filename, $elem,
                      "more than one <guid-entity> for path '$path'")
                if exists $self->{path_entity}{$path};
            $self->{path_entity}{$path} = $entity;
        }
    }

    # Load and register plugins.
    for my $elem ($config->getChildrenByTagNameNS($CONFIG_NS, 'plugin')) {
        my $class = trim(xml_attr($filename, $elem, 'class'));
        load_class($class);
        $class->register($self, $config, $elem, $path);
    }

    # Configuration for generator classes
    for my $elem ($config->getChildrenByTagNameNS($CONFIG_NS, 'generator')) {
        my $class = trim(xml_attr($filename, $elem, 'class'));
        xml_croak($filename, $elem,
                  "only one generator config allowed for '$class' at '$path'")
            if exists $self->{generator_config}{$class}{$path};
        $self->{generator_config}{$class}{$path} = $elem;
    }
}

# Return a named element which must be a child of the specified $root element,
# and check that there is exactly one of them.
sub _singleton_conf_elem
{
    my ($filename, $root, $name) = @_;
    my ($elem, $extra) = $root->getChildrenByTagNameNS($CONFIG_NS, $name);
    xml_croak($filename, $root, "missing <$name> element")
        unless defined $elem;
    xml_croak($filename, $extra, "only one <$name> element is allowed")
        if defined $extra;
    return $elem;
}

=item $cms-E<gt>ra

Return the Subversion remote access (L<SVN::Ra>) object for accessing the
repository.

=cut

sub ra { $_[0]->{ra} }

=item $cms-E<gt>db

Return the L<DBI> database handle for accessing the Daizu database.

=cut

sub db { $_[0]->{db} }

=item $cms-E<gt>config_filename

Returns a string containing the filename from which the configuration
was loaded.  The filename may be a full (absolute) path, or may be
relative to the current directory at the time the Daizu object was
created.

=cut

sub config_filename { $_[0]->{config_filename} }

=item $cms-E<gt>live_wc

Return a L<Daizu::Wc> object representing the live working copy.

=cut

sub live_wc
{
    my ($self) = @_;
    return Daizu::Wc->new($self);
}

=item $cms-E<gt>load_revision($update_to_rev)

Load information about revisions and file paths for any new revisions,
upto C<$update_to_rev>, from the repository into the database.  If no
revision number is supplied, updates to the latest revision.

This is called automatically before any working copy updates, to ensure
that the database knows about revisions before any working copies are
updated to them.  It is idempotent.

This is a simple wrapper round the code in L<Daizu::Revision>.

=cut

sub load_revision
{
    my ($self, $update_to_rev) = @_;
    return Daizu::Revision::load_revision($self, $update_to_rev);
}

=item $cms-E<gt>add_property_loader($pattern, $object, $method)

Plugins can use this to register themselves as a 'property loader',
which will be called when a property whose name matches C<$pattern>
is updated in a working copy.

Currently it isn't possible to localize property loader plugins to
have different configuration for different paths in the repository
using the normal path configuration system.

The pattern can be either the exact property name, a wildcard match on
some prefix of the name ending in a colon, such as C<svn:*>, or just
a C<*> which will match all property names.  There isn't any generic
wildcard or regular expression matching capability.

C<$object> should be an object (probably of the plugin's class) on which
C<$method> can be called.  Since it is called as a method, the first
value passed in will be C<$object>, followed by these:

=over

=item $cms

A C<Daizu> object.

=item $id

The ID number of the file in the C<wc_file> database table for which the
new property values apply.

=item $props

A reference to a hash of the new property values.
Only properties which have been
changed during a working copy update will have entries, so the file
may have other properties which haven't been changed.

Properties which have been deleted during the update will have an
entry in this hash with a value of C<undef>.

=back

An example of a property loader method is C<_std_property_loader> in
this module.  It is always registered automatically.

=cut

sub add_property_loader
{
    my ($self, $pattern, $object, $method) = @_;
    push @{$self->{property_loaders}{$pattern}}, [ $object => $method ];
}

=item $cms-E<gt>add_article_loader($mime_type, $path, $object, $method)

Plugins can use this to register a method which will be called whenever
an article of type C<$mime_type> needs to be loaded.  The MIME type can be
fully specified, or be something like C<image/*> (to match any image format),
or just be C<*> to match any type.  These aren't generic glob or regex
patterns, so only those three levels of specificity are allowed.  The
most specific plugin available will be tried first.  Plugins of the same
specificity will be tried in the order they are registered.  The plugin
methods can return false if they can't handle a particular file for
some reason, in which case Daizu will continue to look for another suitable
plugin.

The plugin registered will only be called on for files with paths which
are the same as, or are under the directory specified by, C<$path>.
Plugins should usually just pass the C<$path> value from their C<register>
method through to this method as-is.

C<$method> (a method name) will be called on C<$object>, and will be
passed C<$cms> and a
L<Daizu::File> object representing the input file.  The method should
return a hash of values describing the article.  Alternatively it can
return false to indicate that it can't handle the file.

The hash returned can contain the following values:

=over

=item content

Required.  All the other values are optional.

This should be an XHTML DOM of the article's content, as it will be published.
It should be an L<XML::LibXML::Document> object, with a root element called
C<body> in the XHTML namespace.  It can contain extension elements to be
processed by article filter plugins.  It can contain XInclude elements,
which will be processed by the
L<expand_xinclude() function|Daizu::Util/expand_xinclude($db, $doc, $wc_id, $path)>.
Entity references should not be present.

=item title

The title to use for the article.  If this is present and not undef then
it will override the value of the C<dc:title> property.

=item short_title

The 'short title' to use for the article.  If this is present and not
undef then it will override the value of the C<daizu:short-title> property.

=item description

The description to use for the article.  If this is present and not undef then
it will override the value of the C<dc:description> property.

=item pages_url

The URL to use for the first page of the article, and which will also be
used to generate URLs for subsequent pages (if any).  This can be absolute,
or relative to the file's base URL.

=item extra_urls

A reference to an array of URL info hashes describing extra URLs generated
by the file in addition to the actual pages of the article.  These are
stored in the C<wc_article_extra_url> table.

=item extra_templates

A reference to an array of filenames of extra templates to be included in
the article's 'extras' column.  These are stored in the
C<wc_article_extra_template> table.

=back

See L<Daizu::Plugin::PodArticle> or L<Daizu::Plugin::PictureArticle> for
examples of registering and writing article loader plugins.

=cut

sub add_article_loader
{
    my ($self, $mime_type, $path, $object, $method) = @_;
    push @{$self->{article_loaders}{$mime_type}{$path}}, [ $object => $method ];
}

=item $cms-E<gt>add_html_dom_filter($path, $object, $method)

Plugins can use this to register a method which will be called whenever
an XHTML file is being published.  C<$method> (a method name) will be
called on C<$object>, and will be passed C<$cms>, a L<Daizu::File> object
for the file being filtered, and an XML DOM object
of the source, as a L<XML::LibXML::Document> object.  The plugin method
should return a reference to a hash containing a C<content> value which
is the filtered content, either a completely new copy of the DOM
or the same value it was passed (which it might have modified in place).

The returned hash can also contain an C<extra_urls> array, in the same
way as an article loader, if the filter adds additional URLs for the file.

The plugin registered will only be called on for files with paths which
are the same as, or are under the directory specified by, C<$path>.
Plugins should usually just pass the C<$path> value from their C<register>
method through to this method as-is.

See L<Daizu::Plugin::SyntaxHighlight> for an example of registering and
implementing a DOM filter method.

=cut

sub add_html_dom_filter
{
    my ($self, $path, $object, $method) = @_;
    my $filter_name = ref($object) . "->$method";   # just for a hash key
    croak "HTML DOM filter already defined for '$filter_name' at '$path'"
        if exists $self->{html_dom_filters}{$filter_name}{$path};
    $self->{html_dom_filters}{$filter_name}{$path} = [ $object => $method ];
}

sub _std_property_loader
{
    my ($self, undef, $id, $props) = @_;
    my $db = $self->{db};
    my %update;

    $update{content_type} = validate_mime_type($props->{'svn:mime-type'})
        if exists $props->{'svn:mime-type'};

    if (exists $props->{'dcterms:issued'}) {
        my $time = validate_date($props->{'dcterms:issued'});
        warn "file $id has invalid 'dcterms:issued' datetime, ignoring\n"
            if !defined $time && defined $props->{'dcterms:issued'};
        # If the custom publication datetime is removed, or isn't valid, then
        # reset it back to the default, which is the time of the file's
        # first commit.
        if (!defined $time) {
            my $guid_id = db_select($db, wc_file => $id, 'guid_id');
            ($time, undef) = guid_first_last_times($db, $guid_id);
            assert(defined $time) if DEBUG;
        }
        $update{issued_at} = db_datetime($time);
    }

    if (exists $props->{'dcterms:modified'}) {
        my $time = validate_date($props->{'dcterms:modified'});
        warn "file $id has invalid 'dcterms:modified' datetime, ignoring\n"
            if !defined $time && defined $props->{'dcterms:modified'};
        # If the custom update datetime is removed, or isn't valid, then
        # reset it back to the default, which is the time of the file's
        # most recent commit.
        if (!defined $time) {
            my $guid_id = db_select($db, wc_file => $id, 'guid_id');
            (undef, $time) = guid_first_last_times($db, $guid_id);
            assert(defined $time) if DEBUG;
        }
        $update{modified_at} = db_datetime($time);
    }

    while (my ($property, $column) = each %Daizu::OVERRIDABLE_PROPERTY) {
        $update{$column} = trim_with_empty_null($props->{$property})
            if exists $props->{$property};
    }

    if (exists $props->{'daizu:flags'}) {
        my @stat = split ' ', $props->{'daizu:flags'};
        $update{retired} = $update{no_index} = 0;
        for (@stat) {
            if ($_ eq 'retired') {
                $update{retired} = 1;
            }
            elsif ($_ eq 'no-index') {
                $update{no_index} = 1;
            }
            else {
                warn "file contains unrecognized value '$_' in 'daizu:flags'";
            }
        }
    }

    $update{custom_url} = validate_uri($props->{'daizu:url'})
        if exists $props->{'daizu:url'};

    db_update $db, wc_file => $id, %update;

    if (exists $props->{'daizu:tags'}) {
        db_delete($db, 'wc_file_tag', file_id => $id);
        if (defined $props->{'daizu:tags'}) {
            for (split /\s*[\x0A\x0D]\s*/, trim($props->{'daizu:tags'})) {
                my $original = $_;
                # There is no standard for how tags should be written and
                # what characters are allowed.  I fold them to lowercase, and
                # collapse sequences of whitespace to a single space.
                $_ = lc $_;
                s/\s+/ /g;
                db_insert($db, 'tag', tag => $_)
                    unless db_row_exists($db, 'tag', tag => $_);
                db_insert($db, 'wc_file_tag',
                    file_id => $id,
                    tag => $_,
                    original_spelling => $original,
                );
            }
        }
    }
}

=item $cms-E<gt>call_property_loaders($id, $props)

Calls the plugin methods which wish to be informed of property changes on
a file, where C<$id> is a file ID for a record in the C<wc_file> table,
and C<$props> is a reference to a hash of the format described for the
L<add_property_loader()|/$cms-E<gt>add_property_loader($pattern, $object, $method)>
method.

=cut

sub call_property_loaders
{
    my ($self, $id, $props) = @_;
    my $loaders = $self->{property_loaders};

    my %seen_loader;
    my %seen_prefix;
    for my $name (keys %$props) {
        if (exists $loaders->{$name}) {
            for my $loader (@{$loaders->{$name}}) {
                next if exists $seen_loader{"$loader"};
                my ($object, $method) = @$loader;
                $object->$method($self, $id, $props);
                undef $seen_loader{"$loader"};
            }
        }

        if ($name =~ /^([^:]+):/ && !$seen_prefix{$1} &&
            exists $loaders->{"$1:*"})
        {
            undef $seen_prefix{$1};
            for my $loader (@{$loaders->{"$1:*"}}) {
                next if exists $seen_loader{"$loader"};
                my ($object, $method) = @$loader;
                $object->$method($self, $id, $props);
                undef $seen_loader{"$loader"};
            }
        }
    }

    if (exists $loaders->{'*'}) {
        for my $loader (@{$loaders->{'*'}}) {
            next if exists $seen_loader{"$loader"};
            my ($object, $method) = @$loader;
            $object->$method($self, $id, $props);
            undef $seen_loader{"$loader"};
        }
    }
}

=item $cms-E<gt>guid_entity

Return the entity to be used for minting GUID URLs for the file at
C<$path>.  This finds the best match from the C<guid-entity> elements
in the configuration file and returns the corresponding C<entity> value.

=cut

sub guid_entity
{
    my ($self, $path) = @_;
    my $best_entity = $self->{default_entity};
    my $matched_path = '';

    while (my ($want_path, $entity) = each %{$self->{path_entity}}) {
        next if length($matched_path) > length($want_path);
        next unless $path eq $want_path ||
                    substr($path, 0, length($want_path) + 1) eq "$want_path/";
        $best_entity = $entity;
        $matched_path = $want_path;
    }

    return $best_entity;
}

=item $cms-E<gt>output_config($url)

Return information about where the published output for C<$url> (a
string or L<URI> object) should be written to.  If there is a suitable
C<output> element in the configuration file then this will return a hash
containing information from that element, followed by a list
of three strings, which will all be defined.  If you join these strings
together (by passing them to the C<file> function from L<Path::Class> for
example) to form a complete path then it will be the path to the file
(never directory) which the output should be written to.

The first value returned will be a reference to a hash containing the
following keys:

=over

=item url

The value from the C<url> attribute in the configuration file, as
a L<URI> object.

=item path

The value from the C<path> attribute.

=item index_filename

The value from the C<index-filename> attribute, or the default
value I<index.html> if one isn't set.

=item redirect_map

The value from the C<redirect-map> attribute, or undef if there isn't one.

=item gone_map

The value from the C<gone-map> attribute, or undef if there isn't one.

=back

The other three values are:

=over

=item *

The absolute path to the document root directory, which will be the value
of the C<path> attribute in the appropriate C<output> element in the
configuration file.  This is the same as the C<path> value in the hash.

=item *

The relative path from there to the directory in which the output file
should be written.  This is given separately so that you can create that
directory if it doesn't exist.  This will be the empty string if the
output file is to be stored directly in the document root directory, but
the C<file> function mentioned above will correctly elide it for you in
that case.

=item *

The filename of the output file.  This is a single name, not a path.

=back

If the configuration doesn't say where C<$url> should be published to then
this will return nothing.

TODO - this doesn't use C<file> itself, so the results aren't portable
across different platforms.

=cut

sub output_config
{
    my ($self, $out_url) = @_;
    $out_url = URI->new($out_url) unless ref $out_url;

    # Search through all the configured output URLs in reverse order to
    # find the most specific (longest) one which is a prefix of $out_url.
    # We do that by checking to see if $out_url can be expressed relative to
    # the output's base URL without going backwards with '../' at the start.
    my ($config, $path);
    for my $url (sort { length $b <=> length $a } keys %{$self->{output}}) {
        my $rel_url = $out_url->rel($url);
        next if $rel_url eq $out_url;
        $rel_url = '' if $rel_url eq './';
        next if $rel_url =~ m!^\.\.?(?:/|$)!;
        $config = $self->{output}{$url};
        $path = $rel_url;
        last;
    }

    return unless defined $config;

    my $filename = $config->{index_filename};
    $filename = $1
        if $path =~ m!(?:^|/)([^/]+)\z!;
    $path =~ s!(?:^|/)[^/]*\z!!;

    return ($config, $config->{path}, $path, $filename);
}

=back

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

1;
# vi:ts=4 sw=4 expandtab

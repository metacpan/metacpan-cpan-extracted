package App::AutoCRUD;

use 5.010;
use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
extends 'Plack::Component';

use Plack::Request;
use Plack::Util;
use Carp;
use Scalar::Does      qw/does/;
use Clone             qw/clone/;
use Try::Tiny;
use YAML::Any         qw/Dump/;
use Data::Reach       qw/reach/;

use namespace::clean -except => 'meta';


our $VERSION = '0.14';

has 'config'      => (is => 'bare', isa => 'HashRef', required => 1);
has 'dir'         => (is => 'ro',   isa => 'Str',
                      builder => '_dir',   lazy => 1);
has 'name'        => (is => 'ro',   isa => 'Str',
                      builder => '_name',  lazy => 1);
has 'title'       => (is => 'ro',   isa => 'Str',
                      builder => '_title', lazy => 1);
has 'datasources' => (is      => 'ro', 
                      isa     => 'HashRef',
                      builder => '_datasources', lazy => 1);
has 'share_paths' => (is      => 'ro', 
                      isa     => 'ArrayRef',
                      builder => '_share_paths', lazy => 1, auto_deref => 1);
has 'readonly'    => (is      => 'ro', isa => 'Bool',
                      builder => '_readonly', lazy => 1);



#======================================================================
# LAZY ATTRIBUTE CONSTRUCTORS
#======================================================================



sub _dir {
  my $self = shift;
  return $self->config('dir') || '.';
}

sub _name {
  my $self = shift;
  return $self->config(qw/app name/) || 'ANONYMOUS_AutoCRUD';
}

sub _title {
  my $self = shift;
  return $self->config(qw/app title/) || 'Welcome to the wonders of AutoCRUD';
}

sub _readonly {
  my $self = shift;
  return $self->config(qw/app readonly/);  
}

sub _datasources {
  my $self = shift;

  my $source_class   = $self->find_class('DataSource');
  my $config_sources = $self->config('datasources');
  return {map {($_ => $source_class->new(name => $_, app => $self))}
              sort keys %$config_sources};
}

sub _share_paths {
  my ($self) = @_;

  # NOTE : we don't use L<File::ShareDir> because of its lack of support for
  # a development environment. L<File::Share> doesn't help either because
  # you need to know the distname; here we only know classnames. So in the end,
  # we put share directories directly under the modules files, which works in
  # any environment.
  my @paths;
  foreach my $class ($self->meta->linearized_isa) {
    $class =~ s[::][/]g;
    my $path = $INC{$class . ".pm"};
    $path =~ s[\.pm$][/share];
    push @paths, $path if -d $path;
  }
  return \@paths;
}


sub BUILD {
  my $self = shift;
  $self->_check_config;
}


sub _check_config {
  my $self = shift;
  my $config_domain_class = $self->find_class("ConfigDomain");
  my $domain = $config_domain_class->Config;
  my $msgs   = $domain->inspect($self->{config});
  die  Dump({"ERROR IN CONFIG" => $msgs}) if $msgs;
}





#======================================================================
# METHODS
#======================================================================

sub datasource {
  my ($self, $name) = @_;
  return $self->datasources->{$name};
}


sub call { # request dispatcher (see L<Plack::Component>)
  my ($self, $env) = @_;

  try {
    $self->respond($env);
  }
    catch {
      return [500, ['Content-type' => 'text/html'], [$self->show_error($_)]];
    };
}




sub respond { # request dispatcher (see L<Plack::Component>)
  my ($self, $env) = @_;

  my $controller_name;

  # build context object
  my $request_class = $self->find_class("Request") || 'Plack::Request';
  my $req           = $request_class->new($env);
  my $context_class = $self->find_class("Context");
  my $context       = $context_class->new(app => $self, req  => $req);

  # see if a specific view was required in the URL
  $context->maybe_set_view_from_path;

  # setup datasource from initial path segment
  if (my $source_name = $context->extract_path_segments(1)) {
    if (my $datasource = $self->datasource($source_name)) {
      # integrate datasource into the context
      $datasource->prepare_for_request($req);
      $context->set_datasource($datasource);

      # setup controller from initial path segment
      $controller_name = ucfirst($context->extract_path_segments(1))
                         || 'Schema'; # default
    }
    else {
      $controller_name = ucfirst($source_name);
    }
  }
  else {
    $controller_name = 'Home';
  }

  # call controller
  my $controller_class = $self->find_class("Controller::$controller_name")
    or die "no such controller : $controller_name";
  my $controller = $controller_class->new(context => $context);
  $controller->respond;
}


sub config {
  my $self = shift;
  my $config = $self->{config};
  return reach $config, @_;
}


sub find_class {
  my ($self, $name) = @_;

  # try to find $name within namespace of current class, then within parents
  foreach my $namespace ($self->meta->linearized_isa) {
    my $class =  $self->try_load_class($name, $namespace);
    return $class if $class;
  }

  return; # not found
}


sub default {
  my ($self, @path) = @_;

  # convenience function, returns default value from config (if any)
  return $self->config(default => @path);
}


sub try_load_class {
  my ($self, $name, $namespace) = @_;

  # return classname if loaded successfully;
  # return undef if not found;
  # raise exception if found but there is a compilation error
  my $class = try {Plack::Util::load_class($name, $namespace)}
              catch {die $_ if $_ !~ /^Can't locate(?! object method)/};
  return $class;
}


sub is_class_loaded {
  my ($self, $class) = @_;

  # deactivate strict refs because we'll be looking into symbol tables
  no strict 'refs';

  # looking at %{$class."::"} is not enough (it may contain other namespaces);
  # so we consider a class loaded if it has at least an ISA or a VERSION
  return @{$class."::ISA"} || ${$class."::VERSION"};

}


sub show_error {
  my ($self, $msg) = @_;

  return <<__EOHTML__;
<!doctype html>
<html>
<head><title>500 Server Error</title></head>
<body><h1>500 Server Error</h1>
<pre>
$msg
</pre>

<!--
  512 bytes of padding to suppress Internet Explorer's "Friendly error messages"

  From: HOW TO: Turn Off the Internet Explorer 5.x and 6.x 
        "Show Friendly HTTP Error Messages" Feature on the Server Side"
        http://support.microsoft.com/kb/294807

  Several frequently-seen status codes have "friendly" error messages
  that Internet Explorer 5.x displays and that effectively mask the
  actual text message that the server sends.
  However, these "friendly" error messages are only displayed if the
  response that is sent to the client is less than or equal to a
  specified threshold.
  For example, to see the exact text of an HTTP 500 response,
  the content length must be greater than 512 bytes.
  -->
</body>
</html>
__EOHTML__
}


1; # End of App::AutoCRUD

__END__

=head1 NAME

App::AutoCRUD - A Plack application for browsing and editing databases

=head1 SYNOPSIS

=head2 Quick demo

To see the demo distributed with this application :

  cd examples/Chinook
  plackup app.psgi

Then point your browser to L<http://localhost:5000>.

=head2 General startup

Create a configuration file, for example in L<YAML> format, like this :

  app:
    name: Test AutoCRUD

  datasources :
    Source1 :
      dbh:
        connect:
            # arguments that will be passed to DBI->connect(...)
            # for example :
          - dbi:SQLite:dbname=some_file
          - "" # user
          - "" # password
          - RaiseError    : 1
            sqlite_unicode: 1

Create a file F<crud.psgi> like this :

  use App::AutoCRUD;
  use YAML qw/LoadFile/;
  my $config = LoadFile "/path/to/config.yaml";
  my $crud   = App::AutoCRUD->new(config => $config);
  my $app    = $crud->to_app;

Then run the app

  plackup crud.psgi

or mount the app in Apache

  <Location /crud>
    SetHandler perl-script
    PerlResponseHandler Plack::Handler::Apache2
    PerlSetVar psgi_app /path/to/crud.psgi
  </Location>

and use your favorite web browser to navigate through your database.


=head1 DESCRIPTION

This module embodies a web application for Creating, Retrieving,
Updating and Deleting records in relational databases (hence the
'CRUD' acronym). The 'C<Auto>' part of the name is because the
application automatically generates and immediately uses the
components needed to work with your data -- you don't have to edit
scaffolding code. The 'C<Plack>' part of the name comes from the
L<Plack middleware framework|Plack> used to implement this application.

To connect to one or several databases, just supply a configuration
file with the connnection information, and optionally some
presentation information, and then you can directly work with the
data. Optionally, the configuration file can also specify many
additional details, like table groups, column groups, data
descriptions, etc.  If more customization is needed, then you can
modify the presentation templates, or even subclass some parts of the
framework.

This application was designed to be easy to integrate with other web
resources in your organization : every table, every record, every
search form has its own URL which can be linked from other sources,
can be bookmarked, etc. This makes it a great tool for example
for adding an admin interface to an existing application : just
install AutoCRUD at a specific location within your Web server
(with appropriate access control :-).

Some distinctive features of this module, in comparison with other
CRUD applications, are :

=over

=item *

Hyperlinks between records, corresponding to foreign key
relationships in the database.

=item *

Support for update or delete of several records at once.

=item *

Support for reordering, masking, documenting tables and columns
through configuration files -- a cheap way to provide reasonable 
user experience without investing into a full-fledged custom application.

=item *

Data export in Excel, YAML, JSON, XML formats

=item *

Extensibility through inheritance

=back


This application is also meant as an example for showing the
power of "Modern Perl", assembling several advanced frameworks
such as L<Moose>, L<Plack> and L<DBIx::DataModel>.


=head1 CONFIGURATION

The bare minimum for this application to run is to
get some configuration information about how to connect
to datasources. This can be done directly in Perl, like in 
the test file F<t/00_autocrud.t> :

  my $connect_options = {
    RaiseError     => 1,
    sqlite_unicode => 1,
  };
  my $config = {
    app => {
      name => "SomeName"
    },
    datasources => {
      SomeDatabase => {
        dbh => {
          connect => [$dbi_connect_string, $user, $passwd, $connect_options],
        },
       },
     },
  };

  # instantiate the app
  my $crud = App::AutoCRUD->new(config => $config);
  my $app  = $crud->to_app;

With this minimal information, the application will just display
tables and columns in alphabetical order. However, the configuration
may also specify many details about grouping and ordering tables
and columns; in that case, it is more convenient to use an external
format like L<YAML>, L<XML> or L<AppConfig>. Here is an excerpt from the
YAML configuration for L<Chinook|http://chinookdatabase.codeplex.com>, a
sample database distributed with this application (see the complete
example under the F<examples/Chinook> directory within this distribution) :

  datasources :
    Chinook :
      dbh:
        connect:
          - "dbi:SQLite:dbname=Chinook_Sqlite_AutoIncrementPKs.sqlite"
          - ""
          - ""
          - RaiseError: 1
            sqlite_unicode: 1

      tablegroups :
        - name: Music
          descr: Tables describing music content
          node: open
          tables :
            - Artist
            - Album
            - Track

        - name: Playlist
          descr: Tables for structuring playlists
          node: open
          tables :
            - Playlist
            - PlaylistTrack
  ...
      tables:
        Track:
          colgroups:
            - name: keys
              columns:
                - name: TrackId
                  descr: Primary key
                - name: AlbumId
                  descr: foreign key to the album where this track belongs
                - name: GenreId
                  descr: foreign key to the genre of this track
                - name: MediaTypeId
                  descr: foreign key to the media type of this track
            - name: Textual information
              columns:
                - name: Name
                  descr: name of this track
                - name: Composer
                  descr: name of composer of this track
            - name: Technical details
              columns:
                - name: Bytes
                - name: Milliseconds
            - name: Commercial details
              columns:
                - name: UnitPrice

The full datastructure for configuration information is documented
in L<App::AutoCRUD::ConfigDomain>.

=head1 USAGE

=head2 Generalities

All pages are presented with a
L<Tree navigator|Alien::GvaScript::TreeNavigator>.
Tree sections can be folded/unfolded either through the mouse or
through navigation keys LEFT and RIGHT. Keys DOWN and UP navigate
to the next/previous sections. Typing the initial characters of a
section title directly jumps to that section.



=head2 Homepage

The homepage displays the application short name, title, and the list
of available datasources.

=head2 Schema

The schema page, for a given datasource, displays the list of
tables, grouped and ordered according to the configuration (if any).

Each table has an immediate hyperlink to its search form; in addition,
another link points to the I<description page> for this table.

=head2 Table description

The description page for a given table presents the list of columns,
with typing information as obtained from the database, and hyperlinks
to other tables for which this table has foreign keys.

=head2 Search form

The search form allows users to enter I<search criteria> and
I<presentation parameters>.

=head3 Search criteria

Within a column input field, one may enter a constant value,
a list of values separated by commas, a partial word with an
ending star (which will be interpreted as a SQL "LIKE" clause),
a comparison operator (ex C<< > 2013 >>), or a BETWEEN clause
(ex C<< BETWEEN 2 AND 6 >>).

The full syntax accepted for such criteria is documented
in L<SQL::Abstract::FromQuery>. That syntax is customizable,
so if you want to support additional fancy operators for your
database, you might do so by augmenting or subclassing the grammar.

=head3 Columns to display

On the right of each column input field is a checkbox to decide
if this column should be displayed in the results or not.
If the configuration specifies column groups, each column group
also has a checkbox to simultaneously check all columns in that group.
Finally, there is also a global checkbox to check/uncheck everything.
If nothing is checked (which is the default), this will be implicitly
interpreted as "SELECT *", i.e. showing everything.

=head3 Presentation parameters

Presentation parameters include :

=over

=item *

pagination information (page size / page index)

=item *

output format, which is one of :

=over

=item html

Default presentation view

=item xlsx

Export to Excel

=item yaml

L<YAML> format

=item json

L<JSON> format

=item xml

C<XML> format

=back

=item *

Flag for total page count (this is optional because it is not always
important, and on many databases it has an additional cost as 
it requires an additional call to the database to know the total
number of records).

=back

=head2 List page

The list page displays a list of records resulting from a search.
The generated SQL is shown for information.
For columns that related to other tables, there are hyperlinks
to the related lists.

Each record has a checkbox for marking this record for update or delete.

Hyperlinks to the next/previous page are provided, but navigation through
pages can also be performed with the LEFT/RIGHT arrow keys.

=head2 Single record display

The single record page is very similar to the list page, but only
displays one single record. The only difference is in the hyperlinks
to update/delete/clone operations.


=head2 Update

The update page has two modes : single-record or multiple-records

=head2 Single-record update

The form shows current values on the right, and has input fields
on the left. Only fields with some user input will be sent for update
to the database.

=head2 Multiple-records update

This form is reached from the L</List page>, when several records
were checked, or when updating the whole result set.

Input fields on the left correspond to the SQL "C<SET>" clause,
i.e. they specify values that will be updated within I<several records>
simultaneously.

Input fields on the right, labelled "where/and", specify some criteria
for the SQL "C<WHERE>" clause.

Needless to say, this is quite a powerful operation which if misused 
could easily corrupt your data.

=head2 Delete

Like updates, delete forms can be either single-record or 
multiple-records.


=head2 Insert

The insert form is very much like the single-record update form, except
that there are no "current values"

=head2 Clone

The clone form is like an insert form, but pre-filled with the data to clone,
except the primary key which is always empty.



=head1 ARCHITECTURE

[to be developed]


=head2 Classes

Modules are organized in a classical Model-View-Controller structure.

=head2 Inheritance and customization

All classes can be subclassed, and the application will automatically
discover and load appropriate modules on demand.
Presentation templates can also be overridden in sub-applications.

=head2 DataModel

This application requires a L<DBIx::DataModel::Schema> subclass
for every datasource. If none is supplied, a subclass will be 
generated and loaded on the fly; but this incurs an additional
startup cost, and does not exploit all possibilities of
L<DBIx::DataModel>; so apart from short demos and experiments,
it is better to statically generate a schema and store it in a
file.

An initial schema class can be built, either from a L<DBI> database
handle, or from an existing L<DBIx::Class> schema; see
L<DBIx::DataModel::Schema::Generator>.


=head1 ATTRIBUTES

=head2 config

A datatree of information, whose structure should comply with
L<App::AutoCRUD::ConfigDomain>.

=head2 name

The application name (displayed in most pages).
This attribute defaults to the value of the C<app/name> entry in config.

=head2 datasources

A hashref of the datasources served by this application.
Hash keys are unique identifiers for the datasources (these names will also
be used to generate URIs); hash values are instances of the
L<App::AutoCRUD::DataSource> class.

=head2 dir

The root directory where some application components could be
placed (like for example some presentation templates).

This attribute defaults to the value of the C<dir> entry in config,
or, if absent, to the current directory.

This directory is associated with the application I<instance>.
When components are not found in this directory, they are searched
in the directories associated with the application I<classes>
(see the C<share_path> attribute below).


=head2 share_paths

An arrayref to a list of directories corresponding
to the hierarchy of application classes. These directories are searched
as second resort, when components are not found in the application instance
directory.


=head2 readonly

A boolean to restrict actions available to only read from the database.
The value of readonly boolean is set in YAML configuration file.


=head1 METHODS

=head2 new

  my $crud_app = App::AutoCRUD->new(%options);

Creates a new instance of the application.
All attributes described above may be supplied as 
C<%options>.

=head2 datasource

  my $datasource = $app->datasource($name);

Returnes the the datasource registered under the given name.


=head2 call

This method implements request dispatch, as required by
the L<Plack> middleware.


=head2 config

  my $data = $app->config(@path);

Walks through the configuration tree, following node names
as specified in C<@path>, and returns whatever is found at
the end of this path ( either a subtree, or scalar data, or
C<undef> if the path leads to nothing ).


=head2 try_load_class

    my $class =  $self->try_load_class($name, $namespace);

Invokes L<Plack::Util/load_class>; returns the loaded class in case
of success, or C<undef> in case of failure.


=head2 find_class

  my $class = $app->find_class($subclass_name);

Tries to find the given C<$subclass_name> within the namespaces
of the application classes.

=head2 is_class_loaded

Checks if the given class is already loaded in memory or not.


=head1 CAVEATS

In the current implementation, the slash charater (C<'/'>) is interpreted
as a separator for primary keys over multiple columns. This means that
an embedded slash in a column name or in the value of a primary key
could yield unexpected results. This is definitely something to be
improved in a future versions, but at the moment I still don't know how
it will be solved.



=head1 ACKNOWLEDGEMENTS

Some design aspects were borrowed from

=over

=item L<Catalyst>

=item L<Catalyst::Helper::View::TTSite>

=back



=head1 AUTHOR

Laurent Dami, C<< <dami at cpan.org> >>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::AutoCRUD


You can also look for information at:

=over 4

=item * github's request tracker (report bugs here)

L<https://github.com/damil/App-AutoCRUD/issues>

=item * MetaCPAN

L<https://metacpan.org/pod/App::AutoCRUD>

=back


The source code is at
L<https://github.com/damil/App-AutoCRUD>.


=head1 SEE ALSO

L<Catalyst::Plugin::AutoCRUD>,
L<WebAPI::DBIC>,
L<Plack>,
L<http://www.codeplex.com/ChinookDatabase>.


=head1 TODO

 - column properties
    - noinsert, noupdate, nosearch, etc.

 - edit: select or autocompleter for foreign keys

 - internationalisation
    - 

 - View:
    - default view should be defined in config
    - overridable content-type & headers 

  - search form, show associations => link to join search

  - list foreign keys even if not in DBIDM schema

  - change log

  - quoting problem (FromQuery: "J&B")

  - readonly fields: tabindex -1 (can be done by CSS?)
    in fact, current values should NOT be input fields, but plain SPANs

  - NULL in updates
  - Update form, focus problem (focus in field should deactivate TreeNav)
  - add insert link in table descr

  - deal with Favicon.ico

  - declare in http://www.sqlite.org/cvstrac/wiki?p=ManagementTools

  - multicolumns : if there is an association over a multicolumns key,
     it is not displayed as a hyperlink in /list. To do so, we would need
     to add a line in the display, corresponding to the multicolumn.

=head1 LICENSE AND COPYRIGHT

Copyright 2014-2021 Laurent Dami.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>


=cut



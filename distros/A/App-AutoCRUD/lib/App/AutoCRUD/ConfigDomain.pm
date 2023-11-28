package App::AutoCRUD::ConfigDomain;
use strict;
use warnings;

use Data::Domain 1.05 qw/:all/;


sub Config {
  Struct(
     app => Struct(
       name     => String(-optional => 1),
       title    => String(-optional => 1),
       default  => Struct(-optional => 1),
       readonly => Whatever, # used as boolean
      ),
     datasources => Struct(
       -values => List(-min_size => 1,
                       -all => DataSource()),
      )
   );
}

sub DataSource {
  Struct (
    dbh => Struct(
      connect => One_of(
        List(String(-name => "connect string"),
             String(-name => "connect username"),
             String(-name => "connect password"),
             Struct(-name => "connect options", -optional => 1)),
        Whatever(-does => 'CODE', -name => "coderef for connection"),
        String(-name => "eval code for connection"),
       ),
      db_catalog => String(-optional => 1),
      db_schema  => String(-optional => 1),
     ),
    descr        => String(-optional => 1),
    require      => String(-optional => 1),
    schema_class => String(-optional => 1),
    tablegroups  => List(-all => Tablegroup(), -optional => 1),
    tables       => Struct(-values => List(-all => Table()), -optional => 1),
    filters      => Struct(-optional => 1,
                           -fields => [include => String(-optional => 1),
                                       exclude => String(-optional => 1)]),
   );
}

sub Tablegroup {
  Struct (
    name   => String,
    descr  => String(-optional => 1),
    node   => Node(-optional => 1),
    tables => List(-all => String, -min_size => 1),
   );
}



sub Table {
  Struct (
    descr => String(-optional => 1),
    colgroups => List(
      -optional => 1,
      -all => Struct(
        name  => String,
        descr => String(-optional => 1),
        node  => Node(-optional => 1),
        columns => List(-all => Struct(
          name => String,
          descr => String(-optional => 1),
         ))
     )),

   );
}

sub Node {
  Enum(-values => [qw/open closed/], @_);
}

1;

__END__

=encoding ISO-8859-1

=head1 NAME

App::AutoCRUD::ConfigDomain - checking configuration data

=head1 SYNOPSIS

=head2 Using the module

  use App::AutoCRUD::ConfigDomain;
  use YAML qw/LoadFile Dump/;
  
  my $config = LoadFile $config_file;
  my $domain = App::AutoCRUD::ConfigDomain->Config();
  my $errors = $domain->inspect($config);
  die Dump($errors) if $errors;

=head2 Configuration example


  app:
    # global settings for the application
    # maybe application name, stuff for the homepage, etc.
    name: Demo
    title: AutoCRUD demo application
    readonly: 0
    default:
        page_size : 50

  datasources :
    Chinook :
      dbh:
        connect:
          - "dbi:SQLite:dbname=Chinook_Sqlite_AutoIncrementPKs.sqlite"
          - ""
          - ""
          - RaiseError: 1
            sqlite_unicode: 1
            sqlite_open_flags: 2 # SQLITE_OPEN_READWRITE

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

        # ...

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

        Customer:
          colgroups:
            - name: keys
              columns:
                - name: CustomerId
                  descr: Primary key
                - name: SupportRepId
                  descr: foreign key to the support employee
            - name: Name
              columns:
                - name: FirstName
                - name: LastName
                - name: Company
            - name: Address
              columns:
                - name: Address
                - name: PostalCode
                - name: City
                - name: State
                - name: Country
            - name: Other coordinates
              columns:
                - name: Email
                - name: Fax
                - name: Phone

        # ...


=head1 DESCRIPTION


This package builds a L<Data::Domain> for checking configuration data.

The L<App::AutoCRUD> application uses this domain at startup time
to check if the configuration is correct.

=head1 DATASTRUCTURE

  <config> : {
    app         => <app>,
    datasources => [ <datasource>+ ]
  }

  <app> : {
    name        => <string>,
    title       => <string>,
    readonly    => <whatever>, # used as boolean
    default     => <hashref>,
  }

  <datasource> : {
    dbh => {
      connect    => ( [ <string>, <string>, <string>, <hashref>? ]
                     | <coderef> ),
      db_catalog => <string>,
      db_schema  => <string>,
    },
    descr        => <string>,
    require      => <string>,
    schema_class => <string>,
    tablegroups  => [ <tablegroup>+ ],
    tables       => [ <table>+ ],
    filters      => { [ include => <string>, ] [exclude => <string>] }
  }

  <tablegroup> : {
    name => string,
    [ descr => string, ]
    [ node  => 'open' | 'closed', ]
    tables  => <string>+

  <table> : {
    <string> => {
      [ descr => <string>, ]
      colgroups => {
        name => <string>
        [ descr => string, ]
        [ node  => 'open' | 'closed', ]
        columns => {
          name => <string>,
          [ descr => <string> ]
        }+
      }+
    }

=head1 CONFIGURATION SECTIONS

=head2 app

Basic information about the application :

=over

=item name

Short name (will be displayed in most pages).

=item title

Long name (will be displayed in home page).

=item readonly

Boolean flag; if true, data mutation operations will be forbidden
(i.e. no insert, update or delete).


=item default

Hashref of various default values that may be used by inner modules.
Currently there is only one example : C<page_size>, used by
L<App::AutoCRUD::Controller::Table> to decide how many
records per page will be displayed.

=back

=head2 datasources

  datasources :
    Chinook :
      dbh:
        connect:
          - "dbi:SQLite:dbname=/path/to/Chinook_Sqlite_AutoIncrementPKs.sqlite"
          - ""                  # username
          - ""                  # password
          - RaiseError: 1       # DBI options
            sqlite_unicode: 1


A hashref describing the various databases served by this application.
Each key in the hashref is a short name for accessing the corresponding
datasource; that name will be part of URLs. Each value is a hashref 
with the following keys :

=over

=item dbh

A hashref containing instructions for connecting to the database.

The main key is C<connect>, which contains a list of arguments
to L<DBI/connect>, i.e. a connection string, username, password,
and possibly a hashref of additional options. Alternatively, C<connect>
could also contain a coderef, or even just a string of Perl code, 
which will be C<eval>ed to get the connection.

Optional keys C<db_catalog> and C<db_schema> may specify the values to
be passed to L<DBI/table_info>, L<DBI/column_info>, etc.  This will be
necessary if your database contains several catalogs and/or schemata.

=item descr

A string for describing the database; this will be displayed on the
home page.

=item require

The name of a Perl module to load before accessing this datasource
(optional).

=item schema_class

The name of the L<DBIx::DataModel::Schema> subclass for this datasource.
This is optional, and defaults to the value of C<require>; if none is
supplied, the class will be constructed dynamically.

=item tablegroups

    tablegroups :
      - name: Music
        descr: Tables describing music content
        node: open
        tables :
          - Artist
          - Album
          - Track
      - name: Reference
        descr: Lists of codes
        node: closed
        tables :
          - MediaType
          - Genre
      ...

Datastructure for organising how database tables will be presented.
In absence of groups, the default presentation is alphabetical order,
which is good enough for small databases, but is no longer appropriate
when the number of tables becomes large. I<Tablegroups> is a list of
subsets of tables; each group may contain :

=over

=item name

Short name for this group

=item descr

Longer description for this group

=item node

Either C<open> or C<closed>, depending on how you want this group
to be presented in the home page. By default groups are C<open>, which
means that the list of tables within the group is immediately visible.
The choice C<closed> is more appropriate for tables which contain technical
information and are not immediately useful to the user.

=item tables

The ordered list of tables within this group.

=item filters

Allows to hide some tables by using inclusion and/or exclusion regexes.
These rules only apply to tables to tables NOT
explicitely defined in the configuration.

These rules are for display comfort, not for security : 
tables hidden from display remain accessible through the URL API, if the
proper URL is supplied by hand.

=over

=item include

Only tables matching this regex will be displayed.

=item exclude

Tables matching this regex will not be displayed.
Exclude takes precedence over include.

=back

=back

=back





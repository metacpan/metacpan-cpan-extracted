package Audio::DB;

# $Id: DB.pm,v 1.2 2005/02/27 16:56:25 todd Exp $

use strict 'vars';
use Carp 'croak','cluck';
use vars qw(@ISA $VERSION);
use Audio::DB::Util::Rearrange;

$|++;


$VERSION = '';

########################
##   NEW CONSTRUCTOR  ##
########################
# DB.pm is a factory for all types of objects.

# It controls the generic new and
# establishes the connection to the database


# Generic factory for Audio::DB::objects
sub new {
  my ($self,@p) = @_;
  my ($adaptor,$task,@args) = rearrange(['ADAPTOR','TASK'],@p);

  # This will create a new database Adaptor object depending on that which is passed.
  # Eventually, I should enable other DBs
  # This is how it would be done (I've redefined the $adaptor below
  # so it doesn't quite follow...)

  $adaptor ||= 'dbi::mysql';
  my $class = "Audio::DB::Adaptor::\L${adaptor}\E";
  eval "require $class" unless $class->can('new');
  
  my $this = bless {},$self;
  $this->{adaptor} = $class->new(@args);
  return $this;
}

sub adaptor { return shift->{adaptor}; }

1;

=pod

=head1 NAME

Audio::DB - Tools for generating relational databases of music files

=head1 SYNOPSIS

   use Audio::DB;
   my $mp3 = Audio::DB->new(-user    => 'user',
	         	    -pass    => 'password',
		            -host    => 'db_host',
		            -dsn     => 'music_db',
		            -adaptor => 'dbi::mysql');

   $mp3->initialize(1);

   $mp3->load_database(-dirs =>['/path/to/MP3s/'],
		       -tmp  =>'/tmp/');

=head1 DESCRIPTION

Audio::DB is a series of modules for creating relational databases of
music files directly from data stored in ID3 tags or from flatfiles of
information of track information.  Once created, Audio::DB provides
various methods for creating reports and web pages of your
collection. Although it's nutritious and delicious on its own, Audio::DB
was created for use with Apache::MP3::DB, a subclass of Apache::MP3.
This module makes it easy to make your collection web-accessible,
complete with browsing, searching, streaming, multiple users,
playlists, ratings, and more!

=head1 USAGE

There are three central modules that you will be interacting with.
Audio::DB::Build, Audio::DB::Web, and Audio::DB::Reports.  Audio::DB itself 
provides a generic factory interface for building these objects.
Audio::DB returns an appropriate object for the desired task at hand.

=head1 Creating A New MP3 Database

Creating a new database is as easy as:

    use strict;
    use Audio::DB;
    my $mp3 = Audio::DB->new(-user   =>'user',
 	                   -pass   =>'password',
	 	           -host   =>'db_host',
		           -dsn    =>'music_db',
                           -create =>1);

    $mp3->initialize(1);  # Populates the database with schema

    my $stats = $mp3->load_database(-dirs =>['/path/to/MP3s/'],
	                            -tmp  =>'/tmp/');


=head1 Appending To A Preexisting MP3 Database

Appending new mp3s to a preexisting database is as easy as:

    use strict;
    use Audio::DB::Build;
    my $mp3 = Audio::DB->new(-user   =>'user',
 	                     -pass   =>'password',
	 	             -host   =>'db_host',
		             -dsn    =>'music_db');

    $mp3->update_database(-dirs =>['/path/to/MP3s/'],
	                  -tmp  =>'/tmp/');


=head1 REQUIRES

Perl Modules:

B<MP3::Info> for reading ID3 tags, B<LWP::MediaTypes> for
distinguising types of readable files, B<DBD::SQLite> for SQLite
support; B<DBD::mysql> for interacting with MySQL databases.

MySQL must be installed if you wish to use MySQL as your RDBMS.

=head1 EXPORTS

No methods are exported.

=head1 METHODS

=head2 new
  
  Title    : new
  Usage    : Audio::DB->new(-adaptor => 'dbi::mysql',
                            -user    => 'user',
	         	    -pass    => 'password',
		            -host    => 'db_host',
		            -dsn     => 'dbi:mysql:music_db',
                            -task    => '[build|web|reports]');

  Function : create a new Audio::DB:: object
  Returns  : new Audio::DB::Build,Audio::DB:Web,or Audio::DB::Reports object
  Args     : lists of adaptors and arguments
  Status   : Public
  
  These are the arguments:

  -adaptor      Name of the adaptor module to use.  Currently only supports
                dbi:mysql. defaults to dbi:mysql if not provided.

  -dsn          The DBI data source, e.g. 'music_db'.  Can also be specified
                as -database.

  -create       Optional. If passed boolean true, the database will be created
                if it does not already exist. (Requires create privileges for the
                provided user).

The commonly used dbi-adaptor is passed the following arguments via the
new method:

  -user[name]   username for authentication
  
  -pass[word]   the password for authentication
  
  -host         where the database lives

  <other>      Any other named argument pairs are passed to
  the adaptor for processing.

The adaptor argument must correspond to a module contained within the
Audio::DB::Adaptor namespace.  For example, the
Audio::DB::Adaptor::dbi::mysql adaptor is loaded by specifying
'dbi::mysql'.  By Perl convention, the adaptors names are lower case
because they are loaded at run time.

Audio::DB currently supports dbi::mysql and dbi::sqlite.  dbi::sqlite
is a small standalone SQL server that is usually sufficient for most
Audio::DB tasks. This makes it the perfect option for including
Audio::DB in embedded applications. If you are interested in adding
other adaptors, please contact me.

=head1 SEE ALSO

Also see the documentation for Audio::DB::Build for information on building
databases, Audio::DB::Web, a module that provides a web browsable interface to
the database, and Audio::DB::Reports, for methods that generate reports
on your collection.

=head1 BUGS

This module implements a fairly complex internal data structure, which
in itself rests upon lots of things going right, like reading ID3
tags, tag naming conventions, etc. On top of that, I wrote most of
this in a Starbucks full of screaming children.

=head1 TODO

Need a resonable way of dealing with tags that can't be read

Lots of error checking needs to be added.  Support for custom data schemas,
including new data types like more extensive artist info, paths to images,
etc.

Keep track of stats for updates.
Fix update - needs to use mysql (these are the _check_artist_db routines that
all need to be implemented)

Robusticize new for different adaptor types

Add in full MP4 support
make the data dumps rely on the schema in the module
put the schema into its own module

=head1 AUTHOR

Copyright 2002-2004, Todd W. Harris <harris@cshl.org>.

This module is distributed under the same terms as Perl itself.  Feel
free to use, modify and redistribute it as long as you retain the
correct attribution.


=head1 ACKNOWLEDGEMENTS

Chris Nandor <pudge@pudge.net> wrote MP3::Info, the module responsible for
reading MP3 tags. Without, this module would be a best-selling pulp
romance novel behind the gum at the grocery store checkout. Chris has
been really helpful with issues that arose with various MP3 tags from
different taggers. Kudos, dude!

Lincoln (Dr. Leichtenstein) Stein <lstein@cshl.org> wrote much of the original 
adaptor code as part of the l<Bio::DB::GFF> module. Much of that code is 
incorporated here, albeit in a pared-down form.  The code for reading ID3 tags 
from files only with appropriate MIME-types is borrowed from his <Apache::MP3> 
module. This was a much more elegant than my lame solution of checking for .mp3!
Lincoln tolerates having me in his lab, too, even though I use a Mac.

=cut

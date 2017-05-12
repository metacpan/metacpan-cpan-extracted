package DBD::Google;

use strict;
use vars qw($VERSION $REVISION);
use vars qw($err $errstr $state $drh);

use DBI;
use DBD::Google::dr;
use DBD::Google::db;
use DBD::Google::st;
use DBD::Google::parser;

$VERSION = "0.51";
$REVISION = $VERSION;

# ----------------------------------------------------------------------
# Standard DBI globals: $DBI::err, $DBI::errstr, etc
# ----------------------------------------------------------------------
$err     = 0;
$errstr  = "";
$state   = "";
$drh     = undef;

# ----------------------------------------------------------------------
# Creates a new driver handle, which will be a singleton.
# ----------------------------------------------------------------------
sub driver {
    unless ($drh) {
        my ($class, $attr) = @_;
        my %stuff = (
            'Name'              => 'Google',
            'Version'           => $VERSION,
            'DriverRevision'    => $REVISION,
            'Err'               => \$err,
            'Errstr'            => \$errstr,
            'State'             => \$state,
            'Attribution'       => 'DBD::Google - darren chamberlain <darren@cpan.org>',
            'AutoCommit'        => 1, # to avoid errors
        );

        $class = join "::", $class, "dr";

        $drh = DBI::_new_drh($class, \%stuff);
    }

    return $drh;
}

sub DESTROY { 1 }

1;

__END__

Apparently, people like DBD::Google:

    http://www.raelity.org/archives/2003/02/13#dbd_google
    http://blog.simon-cozens.org/blosxom.cgi/2003/Feb/13#6335
    jeremy.zowodny.com

=head1 NAME

DBD::Google - Treat Google as a datasource for DBI

=head1 SYNOPSIS

  use DBI;

  my $dbh = DBI->connect("dbi:Google:", $KEY);
  my $sth = $dbh->prepare(qq[
      SELECT title, URL FROM google WHERE q = "perl"
  ]);

  while (my $r = $sth->fetchrow_hashref) {
      ...

=head1 DESCRIPTION

C<DBD::Google> allows you to use Google as a datasource; Google can be
queried using SQL I<SELECT> statements, and iterated over using
standard DBI
conventions.

WARNING:  This is still alpha-quality software.  It works for me, but
that doesn't really mean anything.

=head1 WHY?

For general queries, what better source of information is there than
Google?

=head1 BASIC USAGE

For the most part, use C<DBD::Google> like you use any other DBD,
except instead of going through the trouble of building and installing
(or buying!) database software, and employing a DBA to manage your
data, you can take advantage of Google's ability to do this for you.
Think of it as outsourcing your DBA, if you like.

=head2 Connection Information

The connection string should look like: C<dbi:Google:> (DBI requires
the trailing C<:>).

Your Google API key should be specified in the username portion (the
password is currently ignored; do whatever you want with it, but be
warned that I might put that field to use some day):

  my $dbh = DBI->connect("dbi:Google:", "my key", undef, \%opts);

Alternatively, you can specify a filename in the user portion; the
first line of that file will be treated as the key:

  my $dbh =DBI->connect("dbi:Google:", 
        File::Spec->catfile($ENV{HOME}, ".googlekey"))

In addition to the standard DBI options, the fourth argument to
connect can also include the following C<DBD::Google> specific
options, the full details of each of which can be found in
L<Net::Google>:

=over 16

=item key

The Google API key can be specified here, if desired.

=item lr

Language restrictions.  String or array reference.

=item ie

Input Encoding.  String or array reference.

=item oe

Output Encoding.  String or array reference.

=item safe

Should safe mode be on?  Boolean.

=item filter

Should results be filtered?  Boolean.

=item http_proxy

A URL for proxying HTTP requests.

=item debug

Should C<Net::Google> be put into debug mode or not?  Boolean or code ref
(see L<Net::Google>).

=back

All of these parameters are passed to the C<Net::Google> instance's
C<search> method.

=head2 Supported SQL Syntax and Random Notes Thereon

The only supported SQL statement type is the I<SELECT> statement.
Since there is no real "table" involved, I've created a hypothetical
table, called I<google>; this table has one queryable field, I<q>
(just like the public web-based interface).  The available columns are
currently dictated by the data available from the underlying
transport, which is the Google SOAP API (see
L<http://www.google.com/apis>), as implemented by Aaron Straup Cope's
C<Net::Google> module.

The basic SQL syntax supported looks like:

  SELECT @fields FROM google WHERE q = '$query'

There is also an optional LIMIT clause, the syntax of which is similar
to that of MySQL's LIMIT clause; it takes a pair: offset from 0,
number of results.  In practice, Google returns 10 results at a time
by default, so specifying a higher LIMIT clause at the beginning might
make sense for some queries.

The list of available fields in the I<google> table includes:

=over 16

=item title

Returns the title of the result, as a string.

=item URL

Returns the URL of the result, as a (non-HTML encoded!) string.

=item snippet

Returns a snippet of the result.

=item cachedSize / cached_size

Returns a string indicating the size of the cached version of the
document.

=item directoryTitle / directory_title

Returns a string.

=item summary

Returns a summary of the result.

=item hostName / host_name

Returns the hostname of the result.

=item directoryCategory / directory_category

Returns the directory category of the result.

=back

The column specifications can include aliases:

  SELECT directoryCategory as DC FROM google WHERE...

C<DBD::Google> supports functions of a few types:  native C<DBD::Google>
functions, arbitrary functions or methods in the form Package::Function
or Package->Method, and any Perl builtin that expects a single scalar and
returns a single scalar (C<uc>, C<quotemeta>, C<oct>, etc).

These functions are used like you would expect:

  SELECT title,
         Digest::MD5::md5_hex(title) as checksum,
         URL,
         html_encode(URL) as URI
    FROM google
   WHERE q = '$stuff'

The native C<DBD::Google> functions include:

=over 16

=item uri_escape

This comes from the C<URI::Escape> module.

=item html_escape

This wraps around C<HTML::Entities::encode_entities>.

=item html_strip

This removes HTML from a field.  Some fields, such as title, summary,
and snippet, have the query terms highlighted with <b> tags by Google;
this function can be used to undo that damage.

=back

C<DBD::Google>'s support for arbitrary functions is limited to fuctions
or methods specified using a fully qualified Perl package identifier:

  SELECT title                          AS Title,
         Digest::MD5::md5_hex(title)    AS Checksum,
         URI->new(URL)                  AS URI,
         LWP::Simple::get(URL)          AS content
    FROM google
   WHERE q = '$stuff'

Functions and aliases can be combined:

  SELECT html_strip(snippet) as stripped_snippet FROM google...

Unsupported SQL includes ORDER BY clauses (Google does this, and
provides no interface to modify it), HAVING clauses, JOINs of
any type (there's only 1 "table", after all), sub-SELECTS (I can't even
imagine of what use they would be here), and, actually, anything not
explicitly mentioned above.

=head2 Search Metadata

The statement handle (C<$sth>) has a number of methods that can be
called on it to return information about the query.  These methods are
proxied directly to the contained C<Net::Google::Results> instance,
and include the following:

=over 16

=item $sth->documentFiltering

Returns 0 if false, 1 if true.

=item $sth->searchComments

Returns a string.

=item $sth->estimateTotalResultsNumber

Returns an integer.

=item $sth->estimateIsExact

Returns 0 if false, 1 if true.

=item $sth->searchQuery

Returns a string.

=item $sth->startIndex

Returns an integer.

=item $sth->endIndex

Returns an integer.

=item $sth->searchTips

Returns a string.

=item $sth->searchTime

Returns a float.

=back

=head1 INSTALLATION

C<DBD::Google> is pure perl, and has a few module requirements:

=over 16

=item Net::Google

This is the heart of the module; C<DBD::Google> is basically a
DBI-compliant wrapper around C<Net::Google>.  As of C<DBD::Google>
0.06, C<Net::Google> 0.60 or higher is required.

=item HTML::Entities, URI::Escape

These two modules provide the uri_escape and html_escape functions.

=item DBI

Duh.

=back

To install:

  $ perl Makefile.PL
  $ make
  $ make test
  # make install
  $ echo 'I love your module!' | mail darren@cpan.org -s "DBD::Google"

The last step is optional; the others are not.

=head1 EXAMPLES

Here is a complete script that takes a query from the command line and
formats the results nicely:

  #!/usr/bin/perl -w

  use strict;

  use DBI;
  use Text::TabularDisplay;

  my $query = "@ARGV" || "perl";

  # Set up SQL statement -- note the multiple lines
  my $sql = qq~
    SELECT
      title, URL, hostName
    FROM
      google
    WHERE
      q = "$query"
  ~;

  # DBI/DBD options:
  my %opts = ( RaiseError => 1,  # Standard DBI options
               PrintError => 0,
               lr => [ 'en' ],   # DBD::Google options
               oe => "utf-8",
               ie => "utf-8",
             );

  # Get API key
  my $keyfile = glob "~/.googlekey";

  # Get database handle
  my $dbh = DBI->connect("dbi:Google:", $keyfile, undef, \%opts);

  # Create Text::TabularDisplay instance, and set the columns
  my $table = Text::TabularDisplay->new;
  $table->columns("Title", "URL", "Hostname");

  # Do the query
  my $sth = $dbh->prepare($sql);
  $sth->execute;
  while (my @row = $sth->fetchrow_array) {
      $table->add(@row);
  }
  $sth->finish;

  print $table->render;

=head1 CAVEATS, BUGS, IMPROVEMENTS, SUGGESTIONS, FOIBLES, ETC

I've only tested this using my free, 1000-uses-per-day API key, so I
don't know how well/if this software will work for those of you who
have purchased real licenses for unlimited usage.

Placeholders are currently unsupported.  They won't do any good, but
would be nice to have for consistency with other DBDs.  I'll get
around to it someday.

There are many Interesting Things that can be done with this module, I
think -- suggestions as to what those things might actually be are
very welcome.  Patches implementing said Interesting Things are also
welcome, of course.

More specifically, queries that the SQL parser chokes on would be very
useful, so I can refine the test suite (and the parser itself, of
course).

There are probably a few bugs, though I don't know of any.  Please
report them via the DBD::Google queue at
E<lt>http://rt.cpan.org/E<gt>.

=head1 SEE ALSO 

L<DBI>, L<DBI::DBD>, L<Net::Google>, L<URI::Escape>, L<HTML::Entities>

=head1 AUTHOR

darren chamberlain E<lt>darren@cpan.orgE<gt>

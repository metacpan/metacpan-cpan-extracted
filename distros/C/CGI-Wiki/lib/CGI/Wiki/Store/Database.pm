package CGI::Wiki::Store::Database;

use strict;

use vars qw( $VERSION $timestamp_fmt );
$timestamp_fmt = "%Y-%m-%d %H:%M:%S";

use DBI;
use Time::Piece;
use Time::Seconds;
use Carp qw( carp croak );
use Digest::MD5 qw( md5_hex );

$VERSION = '0.27';

# first, detect if Encode is available - it's not under 5.6. If we _are_
# under 5.6, give up - we'll just have to hope that nothing explodes. This
# is the current 0.54 behaviour, so that's ok.

my $CAN_USE_ENCODE;
BEGIN {
  eval " use Encode ";
  $CAN_USE_ENCODE = $@ ? 0 : 1;
}


=head1 NAME

CGI::Wiki::Store::Database - parent class for database storage backends
for CGI::Wiki

=head1 SYNOPSIS

Can't see yet why you'd want to use the backends directly, but:

  # See below for parameter details.
  my $store = CGI::Wiki::Store::MySQL->new( %config );

=head1 METHODS

=over 4

=item B<new>

  my $store = CGI::Wiki::Store::MySQL->new( dbname  => "wiki",
					    dbuser  => "wiki",
					    dbpass  => "wiki",
                                            dbhost  => "db.example.com",
                                            charset => "iso-8859-1" );
or

  my $store = CGI::Wiki::Store::MySQL->new( dbh => $dbh );

C<charset> is optional, defaults to C<iso-8859-1>, and does nothing
unless you're using perl 5.8 or newer.

If you do not provide an active database handle in C<dbh>, then
C<dbname> is mandatory. C<dbpass>, C<dbuser> and C<dbhost> are
optional, but you'll want to supply them unless your database's
authentication method doesn't require it.

If you do provide C<database> then it must have the following
parameters set; otherwise you should just provide the connection
information and let us create our own handle:

=over 4

=item *

C<RaiseError> = 1

=item *

C<PrintError> = 0

=item *

C<AutoCommit> = 1

=back

=cut

sub new {
    my ($class, @args) = @_;
    my $self = {};
    bless $self, $class;
    return $self->_init(@args);
}

sub _init {
    my ($self, %args) = @_;

    if ( $args{dbh} ) {
        $self->{_dbh} = $args{dbh};
        $self->{_external_dbh} = 1; # don't disconnect at DESTROY time
    } else {
        die "Must supply a dbname" unless defined $args{dbname};
        $self->{_dbname} = $args{dbname};
        $self->{_dbuser} = $args{dbuser} || "";
        $self->{_dbpass} = $args{dbpass} || "";
        $self->{_dbhost} = $args{dbhost} || "";
        $self->{_charset} = $args{charset} || "iso-8859-1";

        # Connect to database and store the database handle.
        my ($dbname, $dbuser, $dbpass, $dbhost) =
                               @$self{qw(_dbname _dbuser _dbpass _dbhost)};
        my $dsn = $self->_dsn($dbname, $dbhost)
            or croak "No data source string provided by class";
        $self->{_dbh} = DBI->connect( $dsn, $dbuser, $dbpass,
				      { PrintError => 0, RaiseError => 1,
				        AutoCommit => 1 } )
          or croak "Can't connect to database $dbname using $dsn: "
                   . DBI->errstr;
    }

    return $self;
}


=item B<retrieve_node>

  my $content = $store->retrieve_node($node);

  # Or get additional meta-data too.
  my %node = $store->retrieve_node("HomePage");
  print "Current Version: " . $node{version};

  # Maybe we stored some metadata too.
  my $categories = $node{metadata}{category};
  print "Categories: " . join(", ", @$categories);
  print "Postcode: $node{metadata}{postcode}[0]";

  # Or get an earlier version:
  my %node = $store->retrieve_node(name    => "HomePage",
			             version => 2 );
  print $node{content};


In scalar context, returns the current (raw Wiki language) contents of
the specified node. In list context, returns a hash containing the
contents of the node plus additional data:

=over 4

=item B<last_modified>

=item B<version>

=item B<checksum>

=item B<metadata> - a reference to a hash containing any caller-supplied
metadata sent along the last time the node was written

The node parameter is mandatory. The version parameter is optional and
defaults to the newest version. If the node hasn't been created yet,
it is considered to exist but be empty (this behaviour might change).

B<Note> on metadata - each hash value is returned as an array ref,
even if that type of metadata only has one value.

=cut

sub retrieve_node {
    my $self = shift;
    my %args = scalar @_ == 1 ? ( name => $_[0] ) : @_;
    # Note _retrieve_node_data is sensitive to calling context.
    return $self->_retrieve_node_data( %args ) unless wantarray;
    my %data = $self->_retrieve_node_data( %args );
    $data{checksum} = $self->_checksum(%data);
    return %data;
}

# Returns hash or scalar depending on calling context.
sub _retrieve_node_data {
    my ($self, %args) = @_;
    my %data = $self->_retrieve_node_content( %args );
    return $data{content} unless wantarray;

    # If we want additional data then get it.  Note that $data{version}
    # will already have been set by C<_retrieve_node_content>, if it wasn't
    # specified in the call.
    my $dbh = $self->dbh;
    my $sql = "SELECT metadata_type, metadata_value FROM metadata WHERE "
         . "node=" . $dbh->quote($self->charset_encode($args{name})) . " AND "
         . "version=" . $dbh->quote($self->charset_encode($data{version}));
    my $sth = $dbh->prepare($sql);
    $sth->execute or croak $dbh->errstr;
    my %metadata;
    while ( my ($type, $val) = $self->charset_decode( $sth->fetchrow_array ) ) {
        if ( defined $metadata{$type} ) {
	    push @{$metadata{$type}}, $val;
	} else {
            $metadata{$type} = [ $val ];
        }
    }
    $data{metadata} = \%metadata;
    return %data;
}

# $store->_retrieve_node_content( name    => $node_name,
#                                 version => $node_version );
# Params: 'name' is compulsory, 'version' is optional and defaults to latest.
# Returns a hash of data for C<retrieve_node> - content, version, last modified
sub _retrieve_node_content {
    my ($self, %args) = @_;
    croak "No valid node name supplied" unless $args{name};
    my $dbh = $self->dbh;
    my $sql;
    if ( $args{version} ) {
        $sql = "SELECT text, version, modified FROM content"
             . " WHERE  name=" . $dbh->quote($self->charset_encode($args{name}))
             . " AND version=" . $dbh->quote($self->charset_encode($args{version}));
    } else {
        $sql = "SELECT text, version, modified FROM node
                WHERE name=" . $dbh->quote($self->charset_encode($args{name}));
    }
    my @results = $self->charset_decode( $dbh->selectrow_array($sql) );
    @results = ("", 0, "") unless scalar @results;
    my %data;
    @data{ qw( content version last_modified ) } = @results;
    return %data;
}

# Expects a hash as returned by ->retrieve_node
sub _checksum {
    my ($self, %node_data) = @_;
    my $string = $node_data{content};
    my %metadata = %{ $node_data{metadata} || {} };
    foreach my $key ( sort keys %metadata ) {
        $string .= "\0\0\0" . $key . "\0\0"
                 . join("\0", sort @{$metadata{$key}} );
    }
    return md5_hex($self->charset_encode($string));
}

# Expects an array of hashes whose keys and values are scalars.
sub _checksum_hashes {
    my ($self, @hashes) = @_;
    my @strings = "";
    foreach my $hashref ( @hashes ) {
        my %hash = %$hashref;
        my $substring = "";
        foreach my $key ( sort keys %hash ) {
            $substring .= "\0\0" . $key . "\0" . $hash{$key};
        }
        push @strings, $substring;
    }
    my $string = join("\0\0\0", sort @strings);
    return md5_hex($string);
}

=item B<node_exists>

  my $ok = $store->node_exists( "Wombat Defenestration" );

  # or ignore case - optional but recommended
  my $ok = $store->node_exists(
                                name        => "monkey brains",
                                ignore_case => 1,
                              );  

Returns true if the node has ever been created (even if it is
currently empty), and false otherwise.

By default, the case-sensitivity of C<node_exists> depends on your
database.  If you supply a true value to the C<ignore_case> parameter,
then you can be sure of its being case-insensitive.  This is
recommended.

=cut

sub node_exists {
    my $self = shift;
    if ( scalar @_ == 1 ) {
        my $node = shift;
        return $self->_do_old_node_exists( $node );
    } else {
        my %args = @_;
        return $self->_do_old_node_exists( $args{name} )
          unless $args{ignore_case};
        my $sql = $self->_get_node_exists_ignore_case_sql;
        my $sth = $self->dbh->prepare( $sql );
        $sth->execute( $args{name} );
        my $found_name = $sth->fetchrow_array || "";
        return lc($found_name) eq lc($args{name}) ? 1 : 0;
    }
}

sub _do_old_node_exists {
    my ($self, $node) = @_;
    my %data = $self->retrieve_node($node) or return ();
    return $data{version}; # will be 0 if node doesn't exist, >=1 otherwise
}

=item B<verify_checksum>

  my $ok = $store->verify_checksum($node, $checksum);

Sees whether your checksum is current for the given node. Returns true
if so, false if not.

B<NOTE:> Be aware that when called directly and without locking, this
might not be accurate, since there is a small window between the
checking and the returning where the node might be changed, so
B<don't> rely on it for safe commits; use C<write_node> for that. It
can however be useful when previewing edits, for example.

=cut

sub verify_checksum {
    my ($self, $node, $checksum) = @_;
#warn $self;
    my %node_data = $self->_retrieve_node_data( name => $node );
    return ( $checksum eq $self->_checksum( %node_data ) );
}

=item B<list_backlinks>

  # List all nodes that link to the Home Page.
  my @links = $store->list_backlinks( node => "Home Page" );

=cut

sub list_backlinks {
    my ( $self, %args ) = @_;
    my $node = $args{node};
    croak "Must supply a node name" unless $node;
    my $dbh = $self->dbh;
    my $sql = "SELECT link_from FROM internal_links WHERE link_to="
            . $dbh->quote($node);
    my $sth = $dbh->prepare($sql);
    $sth->execute or croak $dbh->errstr;
    my @backlinks;
    while ( my ($backlink) = $self->charset_decode( $sth->fetchrow_array ) ) {
        push @backlinks, $backlink;
    }
    return @backlinks;
}

=item B<list_dangling_links>

  # List all nodes that have been linked to from other nodes but don't
  # yet exist.
  my @links = $store->list_dangling_links;

Each node is returned once only, regardless of how many other nodes
link to it.

=cut

sub list_dangling_links {
    my $self = shift;
    my $dbh = $self->dbh;
    my $sql = "SELECT DISTINCT internal_links.link_to
               FROM internal_links LEFT JOIN node
                                   ON node.name=internal_links.link_to
               WHERE node.version IS NULL";
    my $sth = $dbh->prepare($sql);
    $sth->execute or croak $dbh->errstr;
    my @links;
    while ( my ($link) = $self->charset_decode( $sth->fetchrow_array ) ) {
        push @links, $link;
    }
    return @links;
}

=item B<write_node_post_locking>

  $store->write_node_post_locking( node     => $node,
                                   content  => $content,
                                   links_to => \@links_to,
                                   metadata => \%metadata,
                                   plugins  => \@plugins   )
      or handle_error();

Writes the specified content into the specified node, then calls
C<post_write> on all supplied plugins, with arguments C<node>,
C<version>, C<content>, C<metadata>.

Making sure that locking/unlocking/transactions happen is left up to
you (or your chosen subclass). This method shouldn't really be used
directly as it might overwrite someone else's changes. Croaks on error
but otherwise returns true.

Supplying a ref to an array of nodes that this ones links to is
optional, but if you do supply it then this node will be returned when
calling C<list_backlinks> on the nodes in C<@links_to>. B<Note> that
if you don't supply the ref then the store will assume that this node
doesn't link to any others, and update itself accordingly.

The metadata hashref is also optional.

B<Note> on the metadata hashref: Any data in here that you wish to
access directly later must be a key-value pair in which the value is
either a scalar or a reference to an array of scalars.  For example:

  $wiki->write_node( "Calthorpe Arms", "nice pub", $checksum,
                     { category => [ "Pubs", "Bloomsbury" ],
                       postcode => "WC1X 8JR" } );

  # and later

  my @nodes = $wiki->list_nodes_by_metadata(
      metadata_type  => "category",
      metadata_value => "Pubs"             );

For more advanced usage (passing data through to registered plugins)
you may if you wish pass key-value pairs in which the value is a
hashref or an array of hashrefs. The data in the hashrefs will not be
stored as metadata; it will be checksummed and the checksum will be
stored instead (as C<__metadatatypename__checksum>). Such data can
I<only> be accessed via plugins.

=cut

sub write_node_post_locking {
    my ($self, %args) = @_;
    my ($node, $content, $links_to_ref, $metadata_ref) =
                                @args{ qw( node content links_to metadata) };
    my $dbh = $self->dbh;

    my $timestamp = $self->_get_timestamp();
    my @links_to = @{ $links_to_ref || [] }; # default to empty array
    my $version;

    # Either inserting a new page or updating an old one.
    my $sql = "SELECT count(*) FROM node WHERE name=" . $dbh->quote($node);
    my $exists = @{ $dbh->selectcol_arrayref($sql) }[0] || 0;
    if ($exists) {
        $sql = "SELECT max(version) FROM content
                WHERE name=" . $dbh->quote($node);
        $version = @{ $dbh->selectcol_arrayref($sql) }[0] || 0;
        croak "Can't get version number" unless $version;
        $version++;
        $sql = "UPDATE node SET version=" . $dbh->quote($version)
	     . ", text=" . $dbh->quote($self->charset_encode($content))
	     . ", modified=" . $dbh->quote($timestamp)
	     . " WHERE name=" . $dbh->quote($self->charset_encode($node));
	$dbh->do($sql) or croak "Error updating database: " . DBI->errstr;
    } else {
        $version = 1;
        $sql = "INSERT INTO node (name, version, text, modified)
                VALUES ("
             . join(", ", map { $dbh->quote($self->charset_encode($_)) }
		              ($node, $version, $content, $timestamp)
                   )
             . ")";
	$dbh->do($sql) or croak "Error updating database: " . DBI->errstr;
    }

    # In either case we need to add to the history.
    $sql = "INSERT INTO content (name, version, text, modified)
            VALUES ("
         . join(", ", map { $dbh->quote($self->charset_encode($_)) }
		          ($node, $version, $content, $timestamp)
               )
         . ")";
    $dbh->do($sql) or croak "Error updating database: " . DBI->errstr;

    # And to the backlinks.
    $dbh->do("DELETE FROM internal_links WHERE link_from="
             . $dbh->quote($self->charset_encode($node)) ) or croak $dbh->errstr;
    foreach my $links_to ( @links_to ) {
        $sql = "INSERT INTO internal_links (link_from, link_to) VALUES ("
             . join(", ", map { $dbh->quote($self->charset_encode($_)) } ( $node, $links_to ) ) . ")";
        # Better to drop a backlink or two than to lose the whole update.
        # Shevek wants a case-sensitive wiki, Jerakeen wants a case-insensitive
        # one, MySQL compares case-sensitively on varchars unless you add
        # the binary keyword.  Case-sensitivity to be revisited.
        eval { $dbh->do($sql); };
        carp "Couldn't index backlink: " . $dbh->errstr if $@;
    }

    # And also store any metadata.  Note that any entries already in the
    # metadata table refer to old versions, so we don't need to delete them.
    my %metadata = %{ $metadata_ref || {} }; # default to no metadata
    foreach my $type ( keys %metadata ) {
        my $val = $metadata{$type};

        # We might have one or many values; make an array now to merge cases.
        my @values = (ref $val and ref $val eq 'ARRAY') ? @$val : ( $val );

        # Find out whether all values for this type are scalars.
        my $all_scalars = 1;
        foreach my $value (@values) {
            $all_scalars = 0 if ref $value;
	}

        # If all values for this type are scalars, strip out any duplicates
        # and store the data.
        if ( $all_scalars ) {
            my %unique = map { $_ => 1 } @values;
            @values = keys %unique;

            foreach my $value ( @values ) {
                my $sql = "INSERT INTO metadata "
                    . "(node, version, metadata_type, metadata_value) VALUES ("
                    . join(", ", map { $dbh->quote($self->charset_encode($_)) }
                                 ( $node, $version, $type, $value )
                          )
                    . ")";
	        $dbh->do($sql) or croak $dbh->errstr;
	    }
	} else {
        # Otherwise grab a checksum and store that.
            my $type_to_store  = "__" . $type . "__checksum";
            my $value_to_store = $self->_checksum_hashes( @values );
            my $sql = "INSERT INTO metadata "
                    . "(node, version, metadata_type, metadata_value) VALUES ("
                    . join(", ", map { $dbh->quote($self->charset_encode($_)) }
                           ( $node, $version, $type_to_store, $value_to_store )
                          )
                    . ")";
	    $dbh->do($sql) or croak $dbh->errstr;
	}
    }

    # Finally call post_write on any plugins.
    my @plugins = @{ $args{plugins} || [ ] };
    foreach my $plugin (@plugins) {
        if ( $plugin->can( "post_write" ) ) {
            $plugin->post_write( node     => $node,
				 version  => $version,
				 content  => $content,
				 metadata => $metadata_ref );
	}
    }

    return 1;
}

# Returns the timestamp of now, unless epoch is supplied.
sub _get_timestamp {
    my $self = shift;
    # I don't care about no steenkin' timezones (yet).
    my $time = shift || localtime; # Overloaded by Time::Piece.
    unless( ref $time ) {
	$time = localtime($time); # Make it into an object for strftime
    }
    return $time->strftime($timestamp_fmt); # global
}

=item B<delete_node>

  $store->delete_node(
                       name    => $node,
                       version => $version,
                       wiki    => $wiki
                     );

C<version> is optional.  If it is supplied then only that version of
the node will be deleted.  Otherwise the node and all its history will
be completely deleted.

C<wiki> is also optional, but if you care about updating the backlinks
you want to include it.

Again, doesn't do any locking. You probably don't want to let anyone
except Wiki admins call this. You may not want to use it at all.

Croaks on error, silently does nothing if the node or version doesn't
exist, returns true if no error.

=cut

sub delete_node {
    my $self = shift;
    # Backwards compatibility.
    my %args = ( scalar @_ == 1 ) ? ( name => $_[0] ) : @_;

    my $dbh = $self->dbh;
    my ($name, $version, $wiki) = @args{ qw( name version wiki ) };

    # Trivial case - delete the whole node and all its history.
    unless ( $version ) {
        my $name = $dbh->quote($name);
        # Should start a transaction here.  FIXME.
        my $sql = "DELETE FROM node WHERE name=$name";
        $dbh->do($sql) or croak "Deletion failed: " . DBI->errstr;
        $sql = "DELETE FROM content WHERE name=$name";
        $dbh->do($sql) or croak "Deletion failed: " . DBI->errstr;
        $sql = "DELETE FROM internal_links WHERE link_from=$name";
        $dbh->do($sql) or croak $dbh->errstr;
        $sql = "DELETE FROM metadata WHERE node=$name";
        $dbh->do($sql) or croak $dbh->errstr;
        # And finish it here.
        return 1;
    }

    # Skip out early if we're trying to delete a nonexistent version.
    my %verdata = $self->retrieve_node( name => $name, version => $version );
    return 1 unless $verdata{version};

    # Reduce to trivial case if deleting the only version.
    my $sql = "SELECT COUNT(*) FROM content WHERE name=?";
    my $sth = $dbh->prepare( $sql );
    $sth->execute( $name ) or croak "Deletion failed: " . $dbh->errstr;
    my ($count) = $sth->fetchrow_array;
    return $self->delete_node( $name ) if $count == 1;

    # Check whether we're deleting the latest version.
    my %currdata = $self->retrieve_node( name => $name );
    if ( $currdata{version} == $version ) {
        # Can't just grab version ($version - 1) since it may have been
        # deleted itself.
        my $try = $version - 1;
        my %prevdata;
        until ( $prevdata{version} ) {
            %prevdata = $self->retrieve_node(
                                              name    => $name,
                                              version => $try,
                                            );
            $try--;
	}
        my $sql="UPDATE node SET version=?, text=?, modified=? WHERE name=?";
        my $sth = $dbh->prepare( $sql );
        $sth->execute( @prevdata{ qw( version content last_modified ) }, $name)
          or croak "Deletion failed: " . $dbh->errstr;
        $sql = "DELETE FROM content WHERE name=? AND version=?";
        $sth = $dbh->prepare( $sql );
        $sth->execute( $name, $version )
          or croak "Deletion failed: " . $dbh->errstr;
        $sql = "DELETE FROM internal_links WHERE link_from=?";
        $sth = $dbh->prepare( $sql );
        $sth->execute( $name )
          or croak "Deletion failed: " . $dbh->errstr;
        my @links_to;
        my $formatter = $wiki->formatter;
        if ( $formatter->can( "find_internal_links" ) ) {
            # Supply $metadata to formatter in case it's needed to alter the
            # behaviour of the formatter, eg for CGI::Wiki::Formatter::Multiple
            my @all = $formatter->find_internal_links(
                                    $prevdata{content}, $prevdata{metadata} );
            my %unique = map { $_ => 1 } @all;
            @links_to = keys %unique;
        }
        $sql = "INSERT INTO internal_links (link_from, link_to) VALUES (?,?)";
        $sth = $dbh->prepare( $sql );
        foreach my $link ( @links_to ) {
            eval { $sth->execute( $name, $link ); };
            carp "Couldn't index backlink: " . $dbh->errstr if $@;
        }
        $sql = "DELETE FROM metadata WHERE node=? and version=?";
        $sth = $dbh->prepare( $sql );
        $sth->execute( $name, $version )
          or croak "Deletion failed: " . $dbh->errstr;
        return 1;
    }

    # If we're still here, then we're deleting neither the latest
    # nor the only version.
    $sql = "DELETE FROM content WHERE name=? AND version=?";
    $sth = $dbh->prepare( $sql );
    $sth->execute( $name, $version )
      or croak "Deletion failed: " . $dbh->errstr;
    $sql = "DELETE FROM metadata WHERE node=? and version=?";
    $sth = $dbh->prepare( $sql );
    $sth->execute( $name, $version )
      or croak "Deletion failed: " . $dbh->errstr;

    return 1;
}

=item B<list_recent_changes>

  # Nodes changed in last 7 days - each node listed only once.
  my @nodes = $store->list_recent_changes( days => 7 );

  # All changes in last 7 days - nodes changed more than once will
  # be listed more than once.
  my @nodes = $store->list_recent_changes(
                                           days => 7,
                                           include_all_changes => 1,
                                         );

  # Nodes changed between 1 and 7 days ago.
  my @nodes = $store->list_recent_changes( between_days => [ 1, 7 ] );

  # Nodes changed since a given time.
  my @nodes = $store->list_recent_changes( since => 1036235131 );

  # Most recent change and its details.
  my @nodes = $store->list_recent_changes( last_n_changes => 1 );
  print "Node:          $nodes[0]{name}";
  print "Last modified: $nodes[0]{last_modified}";
  print "Comment:       $nodes[0]{metadata}{comment}";

  # Last 5 restaurant nodes edited.
  my @nodes = $store->list_recent_changes(
      last_n_changes => 5,
      metadata_is    => { category => "Restaurants" }
  );

  # Last 5 nodes edited by Kake.
  my @nodes = $store->list_recent_changes(
      last_n_changes => 5,
      metadata_was   => { username => "Kake" }
  );

  # All minor edits made by Earle in the last week.
  my @nodes = $store->list_recent_changes(
      days           => 7,
      metadata_was   => { username  => "Earle",
                          edit_type => "Minor tidying." }
  );

  # Last 10 changes that weren't minor edits.
  my @nodes = $store->list_recent_changes(
      last_n_changes => 5,
      metadata_wasnt  => { edit_type => "Minor tidying" }
  );

You I<must> supply one of the following constraints: C<days>
(integer), C<since> (epoch), C<last_n_changes> (integer).

You I<may> also supply I<either> C<metadata_is> (and optionally
C<metadata_isnt>), I<or> C<metadata_was> (and optionally
C<metadata_wasnt>). Each of these should be a ref to a hash with
scalar keys and values.  If the hash has more than one entry, then
only changes satisfying I<all> criteria will be returned when using
C<metadata_is> or C<metadata_was>, but all changes which fail to
satisfy any one of the criteria will be returned when using
C<metadata_isnt> or C<metadata_is>.

C<metadata_is> and C<metadata_isnt> look only at the metadata that the
node I<currently> has. C<metadata_was> and C<metadata_wasnt> take into
account the metadata of previous versions of a node.

Returns results as an array, in reverse chronological order.  Each
element of the array is a reference to a hash with the following entries:

=over 4

=item * B<name>: the name of the node

=item * B<version>: the latest version number

=item * B<last_modified>: the timestamp of when it was last modified

=item * B<metadata>: a ref to a hash containing any metadata attached
to the current version of the node

=back

Unless you supply C<include_all_changes>, C<metadata_was> or
C<metadata_wasnt>, each node will only be returned once regardless of
how many times it has been changed recently.

By default, the case-sensitivity of both C<metadata_type> and
C<metadata_value> depends on your database - if it will return rows
with an attribute value of "Pubs" when you asked for "pubs", or not.
If you supply a true value to the C<ignore_case> parameter, then you
can be sure of its being case-insensitive.  This is recommended.

=cut

sub list_recent_changes {
    my $self = shift;
    my %args = @_;
    if ($args{since}) {
        return $self->_find_recent_changes_by_criteria( %args );
    } elsif ($args{between_days}) {
        return $self->_find_recent_changes_by_criteria( %args );
    } elsif ( $args{days} ) {
        my $now = localtime;
	my $then = $now - ( ONE_DAY * $args{days} );
        $args{since} = $then;
        delete $args{days};
        return $self->_find_recent_changes_by_criteria( %args );
    } elsif ( $args{last_n_changes} ) {
        $args{limit} = delete $args{last_n_changes};
        return $self->_find_recent_changes_by_criteria( %args );
    } else {
	croak "Need to supply some criteria to list_recent_changes.";
    }
}

sub _find_recent_changes_by_criteria {
    my ($self, %args) = @_;
    my ($since, $limit, $between_days, $ignore_case,
        $metadata_is,  $metadata_isnt, $metadata_was, $metadata_wasnt ) =
         @args{ qw( since limit between_days ignore_case
                    metadata_is metadata_isnt metadata_was metadata_wasnt) };
    my $dbh = $self->dbh;

    my @where;
    my @metadata_joins;
    my $main_table = $args{include_all_changes} ? "content" : "node";
    if ( $metadata_is || $metadata_isnt ) {
        if ( $metadata_is ) {
            my $i = 0;
            foreach my $type ( keys %$metadata_is ) {
                $i++;
                my $value  = $metadata_is->{$type};
                croak "metadata_is must have scalar values" if ref $value;
                my $mdt = "md_is_$i";
                push @metadata_joins, "LEFT JOIN metadata AS $mdt
                                 ON $main_table.name=$mdt.node
                                 AND $main_table.version=$mdt.version\n";
                push @where, "( "
                         . $self->_get_comparison_sql(
                                          thing1      => "$mdt.metadata_type",
                                          thing2      => $dbh->quote($type),
                                          ignore_case => $ignore_case,
                                                     )
                         . " AND "
                         . $self->_get_comparison_sql(
                                          thing1      => "$mdt.metadata_value",
                                          thing2      => $dbh->quote($value),
                                          ignore_case => $ignore_case,
                                                     )
                         . " )";
	    }
	}
        if ( $metadata_isnt ) {
            foreach my $type ( keys %$metadata_isnt ) {
                my $value  = $metadata_isnt->{$type};
                croak "metadata_isnt must have scalar values" if ref $value;
	    }
            my @omits = $self->_find_recent_changes_by_criteria(
                since        => $since,
                between_days => $between_days,
                metadata_is  => $metadata_isnt,
                ignore_case  => $ignore_case,
            );
            foreach my $omit ( @omits ) {
                push @where, "( node.name != " . $dbh->quote($omit->{name})
                     . "  OR node.version != " . $dbh->quote($omit->{version})
                     . ")";
	    }
	}
    } else {
        if ( $metadata_was ) {
            $main_table = "content";
            my $i = 0;
            foreach my $type ( keys %$metadata_was ) {
                $i++;
                my $value  = $metadata_was->{$type};
                croak "metadata_was must have scalar values" if ref $value;
                my $mdt = "md_was_$i";
                push @metadata_joins, "LEFT JOIN metadata AS $mdt
                                 ON $main_table.name=$mdt.node
                                 AND $main_table.version=$mdt.version\n";
                push @where, "( "
                         . $self->_get_comparison_sql(
                                          thing1      => "$mdt.metadata_type",
                                          thing2      => $dbh->quote($type),
                                          ignore_case => $ignore_case,
                                                     )
                         . " AND "
                         . $self->_get_comparison_sql(
                                          thing1      => "$mdt.metadata_value",
                                          thing2      => $dbh->quote($value),
                                          ignore_case => $ignore_case,
                                                     )
                         . " )";
	    }
	}
        if ( $metadata_wasnt ) {
            $main_table = "content";
            foreach my $type ( keys %$metadata_wasnt ) {
                my $value  = $metadata_was->{$type};
                croak "metadata_was must have scalar values" if ref $value;
	    }
            my @omits = $self->_find_recent_changes_by_criteria(
                since        => $since,
                between_days => $between_days,
                metadata_was => $metadata_wasnt,
                ignore_case  => $ignore_case,
            );
            foreach my $omit ( @omits ) {
                push @where, "( content.name != " . $dbh->quote($omit->{name})
                 . "  OR content.version != " . $dbh->quote($omit->{version})
                 . ")";
	    }
	}
    }

    if ( $since ) {
        my $timestamp = $self->_get_timestamp( $since );
        push @where, "$main_table.modified >= " . $dbh->quote($timestamp);
    } elsif ( $between_days ) {
        my $now = localtime;
        # Start is the larger number of days ago.
        my ($start, $end) = @$between_days;
        ($start, $end) = ($end, $start) if $start < $end;
        my $ts_start = $self->_get_timestamp( $now - (ONE_DAY * $start) ); 
        my $ts_end = $self->_get_timestamp( $now - (ONE_DAY * $end) ); 
        push @where, "$main_table.modified >= " . $dbh->quote($ts_start);
        push @where, "$main_table.modified <= " . $dbh->quote($ts_end);
    }

    my $sql = "SELECT DISTINCT
                               $main_table.name,
                               $main_table.version,
                               $main_table.modified
               FROM $main_table
              "
            . join("\n", @metadata_joins)
            . (
                scalar @where
                              ? " WHERE " . join(" AND ",@where) 
                              : ""
              )
            . " ORDER BY $main_table.modified DESC";
    if ( $limit ) {
        croak "Bad argument $limit" unless $limit =~ /^\d+$/;
        $sql .= " LIMIT $limit";
    }
#print "\n\n$sql\n\n";
    my $nodesref = $dbh->selectall_arrayref($sql);
    my @finds = map { { name          => $_->[0],
			version       => $_->[1],
			last_modified => $_->[2] }
		    } @$nodesref;
    foreach my $find ( @finds ) {
        my %metadata;
        my $sth = $dbh->prepare( "SELECT metadata_type, metadata_value
                                  FROM metadata WHERE node=? AND version=?" );
        $sth->execute( $find->{name}, $find->{version} );
        while ( my ($type, $value) = $self->charset_decode( $sth->fetchrow_array ) ) {
	    if ( defined $metadata{$type} ) {
                push @{$metadata{$type}}, $value;
	    } else {
                $metadata{$type} = [ $value ];
            }
	}
        $find->{metadata} = \%metadata;
    }
    return @finds;
}

=item B<list_all_nodes>

  my @nodes = $store->list_all_nodes();

Returns a list containing the name of every existing node.  The list
won't be in any kind of order; do any sorting in your calling script.

=cut

sub list_all_nodes {
    my $self = shift;
    my $dbh = $self->dbh;
    my $sql = "SELECT name FROM node;";
    my $nodes = $dbh->selectall_arrayref($sql); 
    return ( map { $self->charset_decode( $_->[0] ) } (@$nodes) );
}

=item B<list_nodes_by_metadata>

  # All documentation nodes.
  my @nodes = $store->list_nodes_by_metadata(
      metadata_type  => "category",
      metadata_value => "documentation",
      ignore_case    => 1,   # optional but recommended (see below)
  );

  # All pubs in Hammersmith.
  my @pubs = $store->list_nodes_by_metadata(
      metadata_type  => "category",
      metadata_value => "Pub",
  );
  my @hsm  = $store->list_nodes_by_metadata(
      metadata_type  => "category",
      metadata_value  => "Hammersmith",
  );
  my @results = my_l33t_method_for_ANDing_arrays( \@pubs, \@hsm );

Returns a list containing the name of every node whose caller-supplied
metadata matches the criteria given in the parameters.

By default, the case-sensitivity of both C<metadata_type> and
C<metadata_value> depends on your database - if it will return rows
with an attribute value of "Pubs" when you asked for "pubs", or not.
If you supply a true value to the C<ignore_case> parameter, then you
can be sure of its being case-insensitive.  This is recommended.

If you don't supply any criteria then you'll get an empty list.

This is a really really really simple way of finding things; if you
want to be more complicated then you'll need to call the method
multiple times and combine the results yourself, or write a plugin.

=cut

sub list_nodes_by_metadata {
    my ($self, %args) = @_;
    my ( $type, $value ) = @args{ qw( metadata_type metadata_value ) };
    return () unless $type;

    my $dbh = $self->dbh;
    if ( $args{ignore_case} ) {
        $type  = lc( $type  );
        $value = lc( $value );
    }
    my $sql =
         $self->_get_list_by_metadata_sql( ignore_case => $args{ignore_case} );
    my $sth = $dbh->prepare( $sql );
    $sth->execute( $type, $value );
    my @nodes;
    while ( my ($node) = $sth->fetchrow_array ) {
        push @nodes, $node;
    }
    return @nodes;
}

sub _get_list_by_metadata_sql {
    # can be over-ridden by database-specific subclasses
    return "SELECT node.name FROM node, metadata"
         . " WHERE node.name=metadata.node"
         . " AND node.version=metadata.version"
         . " AND metadata.metadata_type = ? "
         . " AND metadata.metadata_value = ? ";
}

sub _get_comparison_sql {
    my ($self, %args) = @_;
    # can be over-ridden by database-specific subclasses
    return "$args{thing1} = $args{thing2}";
}

sub _get_node_exists_ignore_case_sql {
    # can be over-ridden by database-specific subclasses
    return "SELECT name FROM node WHERE name = ? ";
}

=item B<dbh>

  my $dbh = $store->dbh;

Returns the database handle belonging to this storage backend instance.

=cut

sub dbh {
    my $self = shift;
    return $self->{_dbh};
}

=item B<dbname>

  my $dbname = $store->dbname;

Returns the name of the database used for backend storage.

=cut

sub dbname {
    my $self = shift;
    return $self->{_dbname};
}

=item B<dbuser>

  my $dbuser = $store->dbuser;

Returns the username used to connect to the database used for backend storage.

=cut

sub dbuser {
    my $self = shift;
    return $self->{_dbuser};
}

=item B<dbpass>

  my $dbpass = $store->dbpass;

Returns the password used to connect to the database used for backend storage.

=cut

sub dbpass {
    my $self = shift;
    return $self->{_dbpass};
}

=item B<dbhost>

  my $dbhost = $store->dbhost;

Returns the optional host used to connect to the database used for
backend storage.

=cut

sub dbhost {
    my $self = shift;
    return $self->{_dbhost};
}

# Cleanup.
sub DESTROY {
    my $self = shift;
    return if $self->{_external_dbh};
    my $dbh = $self->dbh;
    $dbh->disconnect if $dbh;
}

# decode a string of octets into perl's internal encoding, based on the
# charset parameter we were passed. Takes a list, returns a list.
sub charset_decode {
  my $self = shift;
  my @input = @_;
  if ($CAN_USE_ENCODE) {
    my @output;
    for (@input) {
      push( @output, Encode::decode( $self->{_charset}, $_ ) );
    }
    return @output;
  }
  return @input;
}

# convert a perl string into a series of octets we can put into the database
# takes a list, returns a list
sub charset_encode {
  my $self = shift;
  my @input = @_;
  if ($CAN_USE_ENCODE) {
    my @output;
    for (@input) {
      push( @output, Encode::encode( $self->{_charset}, $_ ) );
    }
    return @output;
  }
  return @input;
}

1;

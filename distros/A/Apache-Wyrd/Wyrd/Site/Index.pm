package Apache::Wyrd::Site::Index;
use base qw(Apache::Wyrd::Services::Index);
use Apache::Wyrd::Services::SAK qw(:file);
use HTTP::Request::Common;
use BerkeleyDB;
our $VERSION = '0.98';
use strict;

=pod

=head1 NAME

Apache::Wyrd::Site::Index - Wrapper Index for the Apache::Wyrd::Site classes

=head1 SYNOPSIS

  use base qw(Apache::Wyrd::Site::Index);

  sub new {
    my ($class) = @_;
    my $init = {
      file => '/var/www/data/pageindex.db',
      debug => 0,
      reversemaps => 1,
      bigfile => 1,
      attributes => [qw(doctype meta)],
      maps => [qw(meta)]
    };
    return &Apache::Wyrd::Site::Index::new($class, $init);
  }
  
  sub ua {
    return BASENAME::UA->new;
  }
  
  sub skip_file {
    my ($self, $file) = @_;
    return 1 if ($file eq 'test.html');
    return;
  }

=head1 DESCRIPTION

C<Apache::Wyrd::Site::Index> provides an extended version of the
C<Apache::Wyrd::Services::Index> object for use in the C<Apache::Wyrd::Site>
hierarchy.

Although it does not extend the parent class to include useful indexable
attributes beyond the default ones (attributes: reverse, timestamp, digest,
data, word, wordcount, title, keywords, description; maps: word), there are
several that are used by Pull Wyrds in the hierarchy that need to be passed
to the initialization hash (see SYNOPSIS for an example) to utilize them. 
These are: attributes doctype, section, parent, shorttitle, published, auth,
orderdate, eventdate, tags, children and maps tags, children.  See
C<Apache::Wyrd::Site::Page>

=head2 METHODS

Note: This class extends the Apach::Wyrd::Services::Index class, so check
the documentation of that module for most methods.  It provides an index of
Apache::Wyrd::Site::Page objects.

I<(format: (returns) name (arguments after self))>

=over

=item (arrayref of hashrefs) C<get_children> (scalar, hashref)

Given an pagename (See Page in this subclass), the method returns the
entries of all children of that page in the navigation hierarchy.  The
arrayref is in the order determined by the Index object (see
Apache::Wyrd::Services::Index), and returns that data which is limited
optionally by the parameters specified in the hashref which is handed
directly to the get_entry method (see the get_entry method of the
Apache::Wyrd::Services::Index class).

=cut

sub get_children {
	my ($self, $parent, $params) = @_;
	my (@children) = ();
	my $index = $self->read_db;
	my $result = $index->db_get($self->make_key('children', $parent), my $packed_children);
	#warn $self->translate_packed($packed_children);
	my %children = unpack("n*", $packed_children);
	foreach my $key (keys %children) {
		my $child = $self->get_entry($key, $params);#turn id into hashref of contents
		#warn "child - $child->{id}";
		$child->{'rank'} = $children{$child->{id}};
		push @children, $child;
	}
	return \@children;
}

=pod

=item (scalar) C<index_site> (Apache req handle, scalar)

This method is an obsolete way of running through the files of a site and
committing them to index.  Please use the much newer and fault-tolerant
Apache::Wyrd::Site::IndexBot.

That being said, the method takes the current Apache request object handle,
and a scalar which indicates whether it should perform a complete index or
only update since the last time this flag was non-null, and returns the text
output of the update process.

=cut

sub index_site {
	my ($self, $req, $fastindex) = @_;
	die ("index site requires an Apache request object, not a: " . ref($req)) unless (ref($req) eq 'Apache');
	my $lastindex = undef;
	my $hostname = $req->server->server_hostname;
	my $root = $req->document_root;
	my $out = $self->purge_missing($req);
	my $ua = $self->ua;
	$ua->timeout(60);
	local $| = 1;
	open (FILES, '-|', "/usr/bin/find $root -name \*.html");
	my $counter = 0;
	$lastindex = ${slurp_file($root. "/var/lastindex.db")};
	my $newest = $lastindex;
	while (<FILES>) {
		chomp;
		my @stats = stat($_);
		#warn "Document status/lastindex/current newest:" . join('/', $stats[9], $lastindex, $newest);
		$newest = $stats[9] if ($stats[9] > $newest);
		$counter++;
		next if ($fastindex and ($stats[9] < $lastindex));
		s/$root//;
		next if $self->skip_file($_);
		my $url = "http://$hostname$_";
		my $response = $ua->request(GET $url);
		my $status = $response->status_line;
		$out .= "<br>$_: OK" if ($status =~ /200|OK/);
		$out .= ("<br>Problem with $_: $status") unless ($status =~ /200|OK/);
	}
	$out = "<b><p>$counter files indexed:</p></b>" . $out;
	spit_file($root . '/var/lastindex.db', $newest);
	return $out;
}

=pod

=item (hashref) C<lookup> (scalar)

or

=item (scalar) C<lookup> (scalar, scalar)

Look up and return data from the index.  In both forms, the first argument
is a scalar representation of the page.  This can be the page name, which
means the path after document root or the page's internal index ID (an
integer).

If the specific attribute is not given, the method returns a hashref of the
full data for the page.  If the attribute is given, only the value of that
attribute is given.

=cut

sub lookup {
	#universal lookup mechanism.  Use attribute as well as page path to get a scalar.
	my ($self, $name, $attribute) = @_;
	my $index = $self->read_db;
	#warn("looking up $attribute for $name");
	my ($id, $new) = $self->get_id($name);
	#warn("found id '$id' new: $new");
	return {} if ($new and not($attribute));
	return undef if ($new);
	if ($attribute) {
		my $key = $self->make_key($attribute, $id);
		my $failed = $index->db_get($key, my $out);
		#warn "failed" if $failed;
		return undef if ($failed);
		return $out;
	} else {
		return $self->get_entry($id);
	}
}

=pod

=item (scalar) C<purge_missing> (Apache request handle)

like index_site, this is an obsolete method of removing deleted documents
from an index.  Please use the more fault-tolerant
Apache::Wyrd::Site::IndexBot object.

It takes the Apache req object as an argument, and returns a scalar of the
text of the output from that purge.

=cut

sub purge_missing {
	my ($self, $req) = @_;
	die ("index site requires an Apache request object, not a: " . ref($req)) unless (ref($req) eq 'Apache');
	my $root = $req->document_root;
	my $result = "<P>First checking for deleted documents:";
	my $index = $self->write_db;
	my $cursor = $index->db_cursor;
	my %exists = ();
	$cursor->c_get(my $id, my $document, DB_FIRST);
	do {
		$exists{$id}=1 if ($id =~ /^\d\d/);
	} until ($cursor->c_get($id, $document, DB_NEXT));
	$cursor->c_get($id, $document, DB_FIRST);
	do {
		my ($current_id) = $id =~ /^[\x00-\xff]%(\d+)/;
		if ($id =~ /^\d\d/) {
			if (-f "$root$document") {
				$result .= "<BR>keeping $root$document" 
			} else {
				$result .= "<BR>destroying $root$document: " . $self->purge_entry($id);
			}
		} elsif (not($exists{$current_id})) {
			my $error = $index->db_del($id);
			$result .= "<br>warning: purged corrupt data for nonexistent id $current_id: ". ($error ? 'failed!' : 'succeeded.');
		}
	} until ($cursor->c_get($id, $document, DB_NEXT));
	$cursor->c_close;
	$self->close_db;
	return "$result</p>";
}

=pod

=item (scalar) C<skip_file> (scalar)

Simple filter for removing files from consideration by the index.  Intended
as an over-loadable handle.  Returns 0 if the file should be indexed. 
Defaults to 0.

=cut

sub skip_file {
	my ($self, $file) = @_;
	return 0;
}

=pod

=item (objectref) C<ua> (hashref)

Another over-loadable handle.  Should return a handle to a LWP useragent
object (See LWP::UserAgent) appropriate for navigating the site, which is to
say it should have some way of handling access and authentication
appropriate to the site's construction.  There is no default ua; the
webmaster will need to define it in order to use this object.

Note that this method is required by Apache::Wyrd::Services::IndexBot.

=cut

sub ua {
	my ($self) = @_;
	$self->_raise_exception('You need to privide a ua method appropriate to your web site.');
}

=pod

=back

=head1 BUGS/CAVEATS

An obsolete appendix to an obsolete mechanism.  Reserves the new method,
which it passes unaltered to Apache::Wyrd::Services::Index.  index_site,
skip_file, and purge_missing are obsolete and may be dropped in future
versions.  See Apache::Wyrd::Services::Index for other bugs/warnings.

=cut

sub new {
	return &Apache::Wyrd::Services::Index::new(@_);
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Services::Index

General-purpose search engine index object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;

package Apache::Wyrd::Site::IndexBot;
use strict;
use base qw(Apache::Wyrd::Bot);
use Apache::Wyrd::Services::SAK qw(:file);
use HTTP::Request::Common;
use BerkeleyDB;
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Site::IndexBot - Sample 'bot for forcing index builds

=head1 SYNOPSIS

Sample Implementation:

  package BASENAME::IndexBot;
  use strict;
  use base qw(Apache::Wyrd::Site::MySQLIndexBot BASENAME::Wyrd);
  use BASENAME::Index;
  
  sub params {
    my ($self) = @_;
    my $params = {
      basefile => $self->dbl->req->document_root . '/var/indexbot',
      server_hostname => $self->dbl->req->server->server_hostname,
      document_root => $self->dbl->req->document_root,
      fastindex => $self->_flags->fastindex || 0,
      purge => $self->_flags->purge || 0,
      realclean => $self->_flags->realclean || 0,
    };
    return $params;
  }
  
  sub _work {
    my ($self) = @_;
    my $index = BASENAME::Index->new;
    $index->delete_index if ($self->{'purge'});
    $self->index_site($index);
  }

Sample Usage:

  <BASENAME::IndexBot refresh="20" expire="40" flags="reverse, purge">
  <BASENAME::Template name="meta">$:meta</BASENAME::Attribute>
  <H1>Rebuilding the Index</H1>
  <H2>$:status</H2>
  $:view
  </BASENAME::Page>
  </BASENAME::IndexBot>

=head1 DESCRIPTION

The IndexBot is an C<Apache::Wyrd::Bot> object which performs the action of
causing a site to be completely indexed, and any remaining deleted documents
purged from the index.  It does so by reading the name of existing files from
the document root down, purging files that are no longer found in that file-
tree, and generating HTTP requests for all the pages which are found.

As these pages are "Indexable Pages", they update their own index pages when
loaded by the server in answer to the HTTP request.

It should be used in a webmaster-protected section of the site for two
reasons: 1. providing public access to the indexing bot is inviting a denial-
of-service attack, since indexing is very resource-intensive and 2. The
C<Apache:Wyrd::Site::IndexBot> "borrows" the webmaster's authorization cookie
in order to be granted full access to the site.

=head2 HTML ATTRIBUTES

=over

=item refresh/timeout

Per C<Apache::Wyrd::Bot>.

=item basefile

Per C<Apache::Wyrd::Bot>, but now required.

=back

=head2 FLAGS

=over

=item purge

Clear the entire index beforehand.  When a first-time or major change has been
made to a site, this tends to speed up the process by eliminating the need to
detect and purge stale data.

=item fastindex

Only purge missing documents and index documents that have changed or have been
added since the last build.

=item reverse

Per C<Apache::Wyrd::Bot>.  Show the bot output log in reverse, with newest
events at the top.

=back

=head2 PERL METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (void) C<_work> (void)

Per C<Apache::Wyrd::Bot>.  Each site must provide a _work method to the Bot
in which the index is given as a reference and pass that index as the
argument to the index_site method.

=item (void) C<index_site> (Index Object Ref)

Performs the indexing.

=cut

##Provide your own.

=pod

=back

=head1 BUGS/CAVEATS

Other bugs/caveats per C<Apache::Wyrd::Bot>.  Also reserves the methods
index_site and purge_missing.

=cut

sub index_site {
	my ($self, $index) = @_;
	my $lastindex = undef;
	my $hostname = $self->{'server_hostname'};
	my $root = $self->{'document_root'};
	my $lastfile = $root . '/var/lastindex.db';
	if ($self->{'basefile'}) {
		$lastfile = $self->{'basefile'} . '.last';
	}

	#purge_missing returns a list of existing files for which there is no
	#database entry and/or the entry has been deleted.
	my @no_skip = $self->purge_missing($index);
	my %no_skip = map {$_ , 1} @no_skip;
	if ($self->{'realclean'}) {
		print "Expired data purge complete.";
	}

	#create a user-agent to trigger the updates to the index with
	my $ua = $index->ua;
	$ua->timeout(60);
	local $| = 1;

	#go through the files in the document root that match ".html",
	#and read in the file that shows when the last update was done
	open (FILES, '-|', "/usr/bin/find $root -name \*.html");
	$lastindex = ${slurp_file($lastfile)};
	my $newest = $lastindex;
	my @files = ();
	while (<FILES>) {
		chomp;
		push @files, $_;
	}
	print "<P>" . scalar(@files) . " files to index.</p>";

	#For each file, try to navigate to it with the User-agent.  Use the auth
	#cookie of the viewer of this Wyrd.
	my $counter = 0;
	while ($_ = shift @files) {
		my @stats = stat($_);
		#warn "Document status/lastindex/current newest:" . join('/', $stats[9], $lastindex, $newest);
		$newest = $stats[9] if ($stats[9] > $newest);
		$counter++;
		s/$root//;
		unless ($no_skip{$_}) {
			next if ($self->{'fastindex'} and ($stats[9] <= $lastindex));
			next if $index->skip_file($_);
		}
		my $url = "http://$hostname$_";
		my $response = '';
		my $auth_cookie = $self->{'auth_cookie'};
		if ($auth_cookie) {
			$response = $ua->get($url, Cookie => $auth_cookie);
		} else {
			$response = $ua->get($url);
		}
		my $status = $response->status_line;
		if ($status =~ /200|OK/) {
			print "$counter. $_: OK";
		} else {
			print "$counter. $_: <span class=\"error\">$status</span>";
			system "touch $_" if (-f $_);
		}
	}
	print "<b><p>$counter files indexed</p></b>";

	#Save the date to the lastindex file.
	spit_file($lastfile, $newest);
	return;
}

sub purge_missing {
	my ($self, $instance) = @_;
	my @no_skip = ();
	my $root = $self->{'document_root'};
	print "<P>First checking for deleted documents and corrupt data";
	my $index = $instance->write_db;
	my %ismap = ();
	foreach my $value (keys %{$instance->maps}) {
		$value = $instance->attributes->{$value};
		$ismap{$value} = 1;
	}
	my %exists = ();
	my %reverse = ();
	my %force_purge = ();
	my $cursor = $index->db_cursor;
	$cursor->c_get(my $id, my $document, DB_FIRST);
	do {
		my ($first, $second, $identifier) = unpack('aaa*', $id);
		if ($second ne '%') {
			#if the metachar is not there, this is a primary filename map.
			$exists{$id} = $document || 'error: unnamed entry';
		} elsif ($first eq "\0") {
			#if the metachar is 0, this is a reversemap
			$reverse{$document} = $identifier;
		}
	} until ($cursor->c_get($id, $document, DB_NEXT));
	undef $cursor;
	foreach my $id (keys %exists) {
		my $document = $exists{$id};
		if ($reverse{$id} ne $exists{$id}) {
			print "Entry $id for $exists{$id} seems to be a duplicate entry.  Deleting it prior to purge...";
			my $result = $index->db_del($id);
			$force_purge{$id} = 1;
			if ($result) {
				print "Failed to delete dangling entry $id.  Manual repair may be necessary...";
			}
		} elsif (-f ($root . $document)) {
			#document exists as a file
			print"keeping $root$document";
		} else {
			my $entry = $instance->get_entry($id);
			my $file = $entry->{'file'};
			if (-f ($root . $file)) {
				push @no_skip, $entry;
				if ($document =~ /^\//) {
					print "purging $document, since it's been deleted, but <span class=\"error\">you need to delete the proxy page $file</span>: ". $instance->purge_entry($id);
				} else {
					print "keeping $document, since it's off-site but the proxy ($file) exists";
				}
			} elsif ($document eq '<DELETED>') {
				if ($self->{'realclean'}) {
					print"purging dirty reference to an updated document: ". $instance->purge_entry($id);
				} else {
					print"skipping dirty reference to a previously deleted document";
				}
			} elsif ($document =~ /^\//) {
				print "purging proxy reference to deleted document $root$document: ". $instance->purge_entry($id);
			} else {
				print "purging reference to a dropped proxy to $document ($file): ". $instance->purge_entry($id);
			}
		}
	}
	#re-invoke an instance of cursor since db may have changed (just in case)
	$cursor = $index->db_cursor;
	$cursor->c_get(my $id, my $document, DB_FIRST);
	do {
		my ($attribute, $separator, $current_id) = unpack('aaa*', $id);
		if ($separator ne '%') {
			#do nothing with primary data
		} elsif ($ismap{$attribute}) {
			my $do_update = 0;
			my $value = '';
			my @ids = ();
			my(%entries) = unpack("n*", $document);
			foreach my $item (keys %entries) {
				if (not($exists{$item}) or $force_purge{$item}) {
					$do_update = 1;
					push @ids, $item;
					next;
				}
				$value .= pack "n", $item;
				$value .= pack "n", $entries{$item};
			}
			if ($do_update) {
				my $ids = join ', ', @ids;
				my $error = $index->db_put($id, $value);
				my $ord = unpack "C", $id;
				print "WARNING: purged corrupt map data for nonexistent ids $ids &#151; " . ($instance->attribute_list->[$ord] || "Unknown attribute [$ord]") . " (id# $current_id): " . ($error ? 'failed!' : 'succeeded.');
			}
		} elsif (($attribute eq "\x00") and not(-f ($root . $current_id))) {
			if ($current_id !~ m#^https?://#) {
				my $error = $index->db_del($id);
				my $ord = unpack "C", $id;
				print "WARNING: purged reverse filemap for nonexistent file $current_id &#151; " . ($instance->attribute_list->[$ord] || "Unknown attribute [$ord]") . " (id# $current_id): ". ($error ? 'failed!' : 'succeeded.');
			};
		} elsif ($attribute eq "\xff") {
			#do nothing to global metadata
		} elsif (not($current_id)) {
			print "Strange null entry under attribute " . $instance->attribute_list->[unpack "C", $id] . "... Your guess is as good ad mine...";
		} elsif ($force_purge{$current_id} or (not(($attribute eq "\x00")) and not($exists{$current_id}))) {
			my $error = $index->db_del($id);
			my $ord = unpack "C", $id;
			print "WARNING: purged corrupt data for nonexistent id $current_id &#151; " . ($instance->attribute_list->[$ord] || "Unknown attribute [$ord]") . " (id# $current_id): ". ($error ? 'failed!' : 'succeeded.');
		}
	} until ($cursor->c_get($id, $document, DB_NEXT));
	$cursor->c_close;
	$instance->close_db;
	print "</p>";
	return @no_skip;
}


=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Bot

Server-launched, monitored processes.

=item Apache::Wyrd::Page

Construct and track a page of an integrated site

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;
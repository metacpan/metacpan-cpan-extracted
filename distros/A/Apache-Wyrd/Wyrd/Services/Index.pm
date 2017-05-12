package Apache::Wyrd::Services::Index;
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);
our $VERSION = '0.98';
use Apache::Wyrd::Services::SAK qw(token_parse strip_html utf8_force utf8_to_entities);
use Apache::Wyrd::Services::SearchParser;
use BerkeleyDB;
use BerkeleyDB::Btree;
use Digest::SHA qw(sha1_hex);
use Carp;

=pod

=head1 NAME

Apache::Wyrd::Services::Index - Metadata index for word/data search engines

=head1 SYNOPSIS

    my $init = {
      file => '/var/lib/Wyrd/pageindex.db',
      strict => 1,
      attributes => [qw(author text subjects)],
      maps => [qw(subjects)]
    };
    my $index = Apache::Wyrd::Services::Index->new($init);

    my @subject_is_foobar = $index->word_search('foobar', 'subjects');

    my @pages =
      $index->word_search('+musthaveword -mustnothaveword
        other words to search for and add to results');
    foreach my $page (@pages) {
      print "title: $$page{title}, author: $$page{author};
    }
    
    my @pages = $index->parsed_search('(this AND that) OR "the other"');
    foreach my $page (@pages) {
      print "title: $$page{title}, author: $$page{author};
    }


=head1 DESCRIPTION

General purpose Index object for retrieving a variety of information on a
class of objects.  The objects can have any type, but must implement at a
minimum the C<Apache::Wyrd::Interfaces::Indexable> interface.

The information stored is broken down into attributes.  The main builtin
(and not override-able) attributes are B<data>, B<word>, B<title>, and
B<description>, as well as four internal attributes of B<reverse>,
B<timestamp>, B<digest> and B<count>.  Additional attributes are specified
via the hashref argument to the C<new> method (see below).  There can be
only 254 total attributes, unless reversemaps are turned on, in which case
all map attributes count as two attributes.

Attributes are of two types, either regular or map, and these relate to the
main index, B<id>.  A regular attribute stores information on a
one-id-to-one-attribute basis, such as B<title> or B<description>.  A map
attribute provides a reverse lookup, such as words in a document, or
subjects covered by documents, such as documents with the word "foo" in them
or items classified as "bar".  One builtin map exists, B<word> which
reverse-indexes every word of the attribute B<data>.

The Index is meant to be used as a storage for meta-data about web pages,
and in this capacity, B<data> and B<word> provide the exact match and
word-search capacity respectively.

The internal attributes of B<digest> and B<timestamp> are also used to
determine whether the information for the item is fresh.  It is assumed that
testing a timestamp is faster than producing a digest, and that a digest is
faster to produce than re-indexing a document, so a check to these two
criteria is made before updating an entry for a given item. See
C<update_entry>.  The B<count> attribute keeps the total word-count for an
indexed item, for use in balancing the relative value of returned results
from a word-search.

The information in the Index is stored in a Berkeley DB, using the
C<BerkeleyDB::Btree> perl module.  Because of concurrence of usage between
different Apache demons in a pool of servers, it is important that this be a
reasonably current version of BerkeleyDB which supports locking and
read-during-update.  This module was developed using Berkeley DB v. 3.3-4.1
on Darwin and Linux.  Your results may vary.

When used with Berkeley DB versions above 4, Index will invoke concurrency
and not locking.

Use with vast amounts of large documents is not recommended, but a
reasonably large (hundreds of 1000-word pages) web site can be indexed and
searched reasonably quickly(TM) on most cheap servers as of this writing. 
All hail Moore's Law.

=head1 METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (Apache::Wyrd::Services::Index) C<new> (hashref)

Create a new Index object, creating the associated DB file if necessary.  The
index is configured via a hashref argument.  Important keys for this hashref:

=over

=item file

Absolute path and filename for the DB file.  Must be writable by the Apache
process.

=item strict

Die on errors.  Default 1 (yes).

=item quiet

If not strict, be quiet in the error log about problems.  Use at your
own risk.

=item concurrency

Use the underlying Concurrent Data Store application via BerkeleyDB when
using Sleepycat Berkeley DB version 4 or higher.  Default 0 (no).

=item transactions

Use the underlying transaction support via BerkeleyDB when using Sleepycat
Berkeley DB version 4 or higher.  Default 0 (no).

Note that concurrency and transactions are mutually exclusive options. If
neither is specified, locking is used instead, to prevent separate Apache
processes from trouncing each others' updates.

=item bigfile

By default (0), the data attribute is stored in the same DB file as the rest
of the data.  If the argument to this option is 1, the data attribute of the
indexed objects is stored in a separate DB file. This may allow some lookups
to be performed faster.  The name of this file is based on the file
attribute, above, by adding "_big" at the end of the filename, but before
the ".db" extension, if present.

=item reversemaps

By default (0), when an indexed item is changed, it's mapped elements
(like the words) are purged from every word entry.  This is usually very
CPU-intensive.  This option tracks a reverse index on the map so that
this purge can be done as quickly as possible.  However, it doubles the
space used to store mapped attributes, causing an overall, but usually
smaller, speed decrease.

=item dirty

This is another potential speed increase, off (0) by default.  When a
purge is required, the data is not removed from the mapped attributes. 
Rather, a new reference is made for the entry and the previous
references are removed.  If, however, map data in the Index object is
accessed directly via the C<db> method and not through
C<search>/C<word_search>, erroneous data will result unless "nameless"
data is removed from the results.  Therefore, reversemaps is the
preferred method, if not the fastest.

=item attributes

Arrayref of attributes other than the default to use.  For every attribute
B<foo>, an C<index_foo> method should be implemented by the object being
indexed.  The value returned by this method will be stored under the attribute
B<foo>.

=item maps

Arrayref of which attributes to treat as maps.  Any attribute that is a
map must also be included in the list of attributes.

=back

=cut

sub new {
	my ($class, $init) = @_;
	die ('Must specify index file') unless($$init{'file'});
	die ('Must specify an absolute path for the index file') unless ($$init{'file'} =~ /^\//);
	my ($directory) = ($$init{'file'} =~ /(.+)\//);
	die ('Must specify a valid, writable directory location.  Directory given: ' . $directory) unless (-d $directory && -w _);
	my $bigfilename = $$init{'file'};
	$bigfilename =~ s/(.+[^.\/]+)(\.[^.]+)$/$1\_big$2/i;
	#Die on errors by default
	$$init{'debug'} = 0 unless exists($$init{'debug'});
	$$init{'strict'} = 1 unless exists($$init{'strict'});
	$$init{'quiet'} = 0 unless exists($$init{'quiet'});

	$$init{'dirty'} = 0 unless exists($$init{'dirty'});
	$$init{'transactions'} = 0 unless exists($$init{'transactions'});
	$$init{'allow_recovery'} = $$init{'transactions'};
	$$init{'concurrency'} = 0 unless exists($$init{'concurrency'});
	if ($$init{'transactions'} and $$init{'concurrency'}) {
		warn "Both transactions and concurrency specified in Index creation.  Falling back to CDB." unless ($$init{'quiet'});
	}
	$$init{'transactions_wanted'} = $$init{'transactions'};
	$$init{'concurrency_wanted'} = $$init{'concurrency'};
	$$init{'reversemaps'} = 0 unless exists($$init{'reversemaps'});
	$$init{'bigfile'} = 0 unless exists($$init{'bigfile'});
	$$init{'wordmin'} = 3 unless exists($$init{'wordmin'});
	if ($$init{'dirty'} and $$init{'reversemaps'}) {
		$$init{'dirty'} = 0;
		$$init{'debug'} && warn('Turning off dirty option since reversemaps is on');
	}
	my @attributes = qw(reverse timestamp digest data word wordcount title keywords description);
	my @check_reserved = ();
	foreach my $reserved (@attributes, 'id', 'score') {
		push @check_reserved, $reserved if (grep {$reserved eq $_} @{$$init{'attributes'}});
		push @check_reserved, $reserved if ($$init{'reversemaps'} and $reserved =~ /^_/);
	}
	my $s = '';
	$s = 's' if (@check_reserved > 1);
	die ("Reserved/Illegal attribute$s specified.  Use different name$s: " . join(', ', @check_reserved)) if (@check_reserved);
	my @maps = qw(word);
	my (%attributes, %maps) = ();
	@maps = (@maps, @{$init->{'maps'}}) if (ref($init->{'maps'}) eq 'ARRAY');
	foreach my $map (@maps) {
		$maps{$map} = 1;
	}
	@attributes = (@attributes, @{$init->{'attributes'}}) if (ref($init->{'attributes'}) eq 'ARRAY');
	my $attr_index = 0;
	#key values \xff%<foo> are reserved for index metadata, so value 255 is reserved
	my $max_attrs = 254;
	$max_attrs -= @maps if ($$init{'reversemaps'});
	foreach my $attribute (@attributes) {
		if ($attr_index > $max_attrs) {
			$$init{'debug'} && warn "Too many attributes initialized in the Index.  Stopping at $attribute.  The rest will not be used";
			last;
		}
		$attributes{$attribute} = chr($attr_index);
		$attr_index++;
	}
	my @attribute_map = @attributes;
	if ($$init{'reversemaps'}) {
		foreach my $attribute (@maps) {
			$attributes{"_$attribute"} = chr($attr_index);
			push @attribute_map, "_$attribute";
			$attr_index++;
		}
	}
	my $data = {
		file			=>	$$init{'file'},
		directory		=>	$directory,
		db				=>	undef,
		env				=>	undef,
		status			=>	undef,
		debug			=>	$$init{'debug'},
		strict			=>	$$init{'strict'},
		transactions	=>	$$init{'transactions'},
		allow_recovery	=>	$$init{'allow_recovery'},
		concurrency		=>	$$init{'concurrency'},
		transactions_wanted	=>	$$init{'transactions_wanted'},
		concurrency_wanted		=>	$$init{'concurrency_wanted'},
		dirty			=>	$$init{'dirty'},
		reversemaps		=>	$$init{'reversemaps'},
		bigfile			=>	$$init{'bigfile'},
		bigfilename		=>	$bigfilename,
		quiet			=>	$$init{'quiet'},
		error			=>	[],
		attributes		=>	\%attributes,
		attribute_list	=>	\@attributes,
		attribute_map	=>	\@attribute_map,
		maps			=>	\%maps,
		map_list		=>	\@maps,
		extended		=>	((scalar(keys %attributes) > 8) ? 8 : 0),
		wordmin			=>	$$init{'wordmin'}
	};
	bless $data, $class;
	my $env = $data->env;
	if (not($env) and $data->allow_recovery) {
		$data->recover_db;
		$env = $data->env;
		if (not($env)) {
			$data->{'status'} = 'X';
			warn "Environment is persistently failing to initialize even after recovery.  Manual repair needed.  Going into read-only mode.";
		}
	}
	#It IS necessary to open the files if they don't exist, since a read will fail otherwise.
	if ( not(-e $$init{'file'}) or ($$init{'bigfile'} and not(-e $bigfilename))) {
			$data->write_db;
	}
	return $data;
}

sub db {
	my ($self) = @_;
	return $self->{'db'};
}

sub db_big {
	my ($self) = @_;
	return $self->{'db_big'};
}

sub env {
	my ($self) = @_;
	return $self->{'env'} if ($self->{'env'});
	my $env = undef;
	if ($BerkeleyDB::db_version >= 4) {
		my $flags = DB_INIT_LOCK | DB_INIT_MPOOL | DB_CREATE;
		if ($self->{'concurrency_wanted'}) {
			$flags = DB_INIT_MPOOL | DB_INIT_CDB | DB_CREATE;
		} elsif ($self->{'transactions_wanted'}) {
			$flags = DB_INIT_LOCK | DB_INIT_MPOOL | DB_INIT_LOG | DB_INIT_TXN | DB_CREATE;
		}
		$env = BerkeleyDB::Env->new(
			-Home			=> $self->directory,
			-Flags			=> $flags,
			-ErrFile		=> *STDERR,
			-Verbose		=> 1,
		);
		if ($env) {
			#environment initialized safely.  set transactions/concurrency if wanted
			$self->{'concurrency'} = $self->{'concurrency_wanted'};
			$self->{'transactions'} = $self->{'transactions_wanted'};
		}
	} else {
		$env = BerkeleyDB::Env->new(
			-Home			=> $self->directory,
			-Flags			=> DB_INIT_LOCK | DB_INIT_MPOOL | DB_CREATE,
			-LockDetect		=> DB_LOCK_OLDEST,
			-ErrFile		=> *STDERR,
			-Verbose		=> 1,
		);
	}
	unless ($env) {
		die "Grr.";
		warn "BerkeleyDB::Env fails to initialize.  Falling back to default environment on this platform.";
		$self->{'transactions'} = 0;
		$self->{'concurrency'} = 0;
	}
	$self->{'env'} = $env;
	return $env;
}

sub extended {
	my ($self) = @_;
	return $self->{'extended'};
}

sub attributes {
	my ($self) = @_;
	return $self->{'attributes'};
}

sub maps {
	my ($self) = @_;
	return $self->{'maps'};
}

sub attribute_list {
	my ($self) = @_;
	return $self->{'attribute_list'};
}

sub attribute_map {
	my ($self) = @_;
	return $self->{'attribute_map'};
}

sub map_list {
	my ($self) = @_;
	return $self->{'map_list'};
}

sub status {
	my ($self) = @_;
	return $self->{'status'};
}

sub debug {
	my ($self) = @_;
	return $self->{'debug'};
}

sub strict {
	my ($self) = @_;
	return $self->{'strict'};
}

sub dirty {
	my ($self) = @_;
	return $self->{'dirty'};
}

sub transactions {
	my ($self) = @_;
	return $self->{'transactions'};
}

sub allow_recovery {
	my ($self) = @_;
	return $self->{'allow_recovery'};
}

sub concurrency {
	my ($self) = @_;
	return $self->{'concurrency'};
}

sub wordmin {
	my ($self) = @_;
	return $self->{'wordmin'};
}

sub reversemaps {
	my ($self) = @_;
	return $self->{'reversemaps'};
}

sub quiet {
	my ($self) = @_;
	return $self->{'quiet'};
}

sub file {
	my ($self) = @_;
	return $self->{'file'};
}

sub bigfile {
	my ($self) = @_;
	return $self->{'bigfile'};
}

sub bigfilename {
	my ($self) = @_;
	return $self->{'bigfilename'};
}

sub directory {
	my ($self) = @_;
	return $self->{'directory'};
}

sub error {
	my ($self) = @_;
	return @{$self->{'error'}};
}

sub set_error {
	my ($self, $error) = @_;
	$self->{'error'} = [@{$self->{'error'}}, $error];
	return;
}

sub current_transaction {
	my ($self) = @_;
	return $self->{'current_transaction'};
}

=pod

=item (void) C<delete_index> (void)

Zero all data in the index and open a new one.

=cut

sub delete_index {
	my ($self) = @_;
	$self->write_db;
	$self->db->truncate(my $count);
	$self->db_big->truncate(my $bcount) if ($self->bigfile);
	if ($self->bigfile) {
		$self->db_big->truncate(my $bcount);
	}
	$self->close_db;
	return;
}

sub newstatus {
	my ($self, $status) = @_;
	return undef if ($self->status eq 'X');#Once it's bad, it stays there.
	$self->{'status'} = $status;
	return;
}

sub check_error {
	my ($self) = @_;
	if ($self->transactions) {
		if ($self->error) {
			warn "transactions are enabled and errors occurred:";
			carp (join("\n", $self->error));
		}
	} elsif ($self->strict) {
		if ($self->error) {
			croak (join("\n", $self->error));
		}
	} else {
		if ($self->error) {
			$self->{'status'} = 'X';
		}
		return undef if ($self->quiet);
		carp (join("\n", $self->error));
	}
	return;
}

sub read_db {
	my ($self) = @_;
	if ($self->status eq 'R') {
		return $self->db;
	} elsif ($self->status eq 'RW') {
		$self->close_db;
	}
	my %index = ();
	my $index = tie %index, 'BerkeleyDB::Btree', -Filename => $self->file, -Flags => DB_RDONLY, -Env => $self->env, -Mode => 0660;
	$self->set_error ("Can't open the index for reading.") unless ($index);
	$self->check_error;
	$self->{'db'} = $index;
	if ($self->bigfile) {
		my %bindex = ();
		my $bindex = tie %bindex, 'BerkeleyDB::Btree', -Filename => $self->bigfilename, -Flags => DB_RDONLY, -Env => $self->env, -Mode => 0660;
		$self->set_error("Can't open the wholetext index for reading.") unless ($bindex);
		$self->check_error;
		$self->{'db_big'} = $bindex;
	}
	$self->newstatus('R');
	return $index;
}

sub write_db {
	my ($self) = @_;
	if ($self->status eq 'RW') {
		return $self->db;
 	} elsif ($self->status eq 'R') {
		$self->close_db;
	}
	my %index = ();
	my $index = tie (%index, 'BerkeleyDB::Btree', -Filename => $self->file, -Flags => DB_CREATE, -Env => $self->env, -Mode => 0660);
	$self->set_error ("Can't open/create the index for writing.") unless ($index);
	$self->check_error;
	$self->{'db'} = $index;
	if ($self->bigfile) {
		my %bindex = ();
		my $bindex = tie %bindex, 'BerkeleyDB::Btree', -Filename => $self->bigfilename, -Flags => DB_CREATE, -Env => $self->env, -Mode => 0660;
		$self->{'db_big'} = $bindex;
		$self->set_error("Can't open/create the wholetext index for writing.") unless ($bindex);
		$self->check_error;
	}
	my $fingerprint = int(rand(100000));
	$index->db_put("\xff%fingerprint", $fingerprint);
	$index->db_get("\xff%fingerprint", my $challenge);
	$self->set_error("open returned an unwriteable DB on write_db() -- '$challenge' should be '$fingerprint'") unless ($fingerprint == $challenge);
	$self->check_error;
	$self->newstatus('RW');
	return $index;
}

sub recover_db {
	my ($self) = @_;
	if ($self->status =~ /^RW?$/) {
		$self->close_db;
	}
	if ($self->current_transaction) {
		warn "aborting current transaction..." unless ($self->quiet);
		my $result = $self->current_transaction->txn_abort;
		warn $result if ($result);
		$self->{'current_transaction'} = undef;
	}
	my $error = 0;
	if ($self->allow_recovery) {
		warn 'attempting recovery using DB_RECOVER environment flag';
		my $env = BerkeleyDB::Env->new(
			-Home			=> $self->directory,
			-Flags			=> DB_INIT_LOCK | DB_INIT_MPOOL | DB_INIT_LOG | DB_INIT_TXN | DB_RECOVER | DB_CREATE,
			-ErrFile		=> *STDERR,
			-Verbose		=> 1,
		);
		my %index = ();
		my $errors = '';
		my $index = tie (%index, 'BerkeleyDB::Btree', -Filename => $self->file, -Flags => DB_CREATE, -Env => $env, -Mode => 0660);
		$error = 1 unless ($index);
		$errors .= $env->status . "\n" if ($error and $env);
		$index->db_close if ($index);
		$index = undef;
		%index = ();
		if ($self->bigfile) {
			my %bindex = ();
			my $bindex = tie %bindex, 'BerkeleyDB::Btree', -Filename => $self->bigfilename, -Flags => DB_CREATE, -Env => $env, -Mode => 0660;
			$self->{'db_big'} = $bindex;
			$error = 1 unless ($bindex);
			$errors .= $env->status . "\n" if ($error and $env);
			$bindex->db_close if ($bindex);
			$bindex = undef;
			%bindex = ();
		}
		if ($error) {
			warn 'attempting recovery using DB_RECOVER_FATAL environment flag';
			$error = 0;
			my $env = BerkeleyDB::Env->new(
				-Home			=> $self->directory,
				-Flags			=> DB_INIT_LOCK | DB_INIT_MPOOL | DB_INIT_LOG | DB_INIT_TXN | DB_RECOVER_FATAL | DB_CREATE,
				-ErrFile		=> *STDERR,
				-Verbose		=> 1,
			);
			die "could not init fatal recovery environment" unless ($env);
			my $index = tie (%index, 'BerkeleyDB::Btree', -Filename => $self->file, -Flags => DB_CREATE, -Env => $env, -Mode => 0660);
			$error = 1 unless($index);
			$errors .= $env->status . "\n" if ($error);
			$index->db_close if ($index);
			$index = undef;
			%index = ();
			if ($self->bigfile) {
				my %bindex = ();
				my $bindex = tie %bindex, 'BerkeleyDB::Btree', -Filename => $self->bigfilename, -Flags => DB_CREATE, -Env => $env, -Mode => 0660;
				$self->{'db_big'} = $bindex;
				$error = 1 unless ($bindex);
				$errors .= $env->status . "\n" if ($error);
				$bindex->db_close if ($bindex);
				$bindex = undef;
				%bindex = ();
			}
			die ("recovery of database failed for both DB_RECOVER and DB_RECOVER_FATAL: $errors") if ($error);
			$self->check_error;
		}
	}
}

sub close_db {
	my ($self) = @_;
	my $index = $self->{'db'};
	if (ref($index) and UNIVERSAL::isa($index, 'Apache::Wyrd::Services::Index')) {
		$index->db_close;
		untie %{$self->{'db'}};
		$self->{'db'} = undef;
		delete ($self->{'status'}); #close the DB ref
		$self->{'status'} = undef;
	}
	$index = $self->{'db_big'};
	if (ref($index) and UNIVERSAL::isa($index, 'Apache::Wyrd::Services::Index')) {
		$index->db_close;
		untie %{$self->{'db_big'}};
		$self->{'db_big'} = undef;
		delete ($self->{'status'}); #close the DB ref
		$self->{'status'} = undef;
	}
	my $env = $self->{'env'};
	if (ref($env) and UNIVERSAL::isa($env, 'BerkeleyDB::Env')) {
		$self->{'env'} = undef;
	}
	undef $index;
	undef $env;
	return;
}

=pod

=item (scalar) C<update_entry> (Apache::Wyrd::Interfaces::Indexable ref)

Called by an indexable object, passing itself as the argument, in order to
update it's entry in the index.  This method calls C<index_foo> for every
attribute B<foo> in the index, storing that value under the attribute entry for
that object.  The function always returns a message about the process.

update_entry will always check index_timestamp and index_digest.  If the stored
value and the returned value agree on either attribute, the index will not be
updated.  This behavior can be overridden by returning a true value from method
C<force_update>.

Index will also check for an C<index_runtime_flags> method and call it to
determine if the indexed object is attempting to modify the behavior of the
update during the process of updating for debugging purposes.  Currently, it
recognizes the following flags:

=over

=item debug/nodebug

Turn on debugging messages for the course of this update, even if debug is
not specified in the arguments to C<new>.

=item nodata

Avoid processing, word-mapping, and storing the data attribute.

=back

=cut

#attributes - integer=name (self_path), 0=reverse, 1=timestamp, 2=digest, 3=data, 4=word, 5=count, 6=title, 7=keywords, 8=description
sub update_entry {
	my ($self, $entry) = @_;
	$self->set_error = "Index entries must be objects " unless (ref($entry));
	#localize debug value so that the entry can modify it.
	my $debug = $self->debug;
	$self->{'runtime_flags'} = {};
	if (UNIVERSAL::can($entry, 'index_runtime_flags')) {
		map {$self->{'runtime_flags'}->{$_} => 1} token_parse($entry->index_runtime_flags);
		$debug = 1 if ($self->{'runtime_flags'}->{'debug'});
		$debug = 0 if ($self->{'runtime_flags'}->{'nodebug'});
	}
	foreach my $function (qw/no_index index_name index_timestamp index_digest index_data/) {
		$self->set_error("Index entries must implement the method $function\(\)") unless ($entry->can($function));
	}
	my $name = $entry->index_name;
	$self->set_error("Index entries must return non-null for method index_name()") unless ($name);
	$self->check_error;
	$self->set_error("<DELETED> is an invalid name for index entries ") if ($name eq '<DELETED>');
	$self->set_error($name . " is an invalid name for index entries ") if ($name =~ /^.%/s);
	$self->check_error;
	my $index = $self->read_db;
	my $null = undef;#used for DB checks where no value needs be returned
	if ($entry->no_index) {
		if ($index->db_get("\x00%" . $name, $null)) {
			#if key is not found
			return "yes to no_index and not indexed.";
		}
		$index = $self->write_db;
		my $result = $self->purge_entry($name);
		$self->close_db;
		return $result;
	}
	my ($id, $id_is_new) = $self->get_id($name);
	$debug && warn $name . " is new" if ($id_is_new);
	unless ($entry->force_update) {
		$index->db_get("\x01\%$id", my $timestamp);
		$debug && warn "Comparing timestamps: $timestamp <-> " . $entry->index_timestamp . " for " . $name;
		if ($timestamp eq $entry->index_timestamp) {
			$debug && warn "No update needed.  Timestamp is $timestamp." ;
			return "No update needed.  Timestamp is $timestamp." ;
		}
		if ($timestamp) {
			#Timestamp was found and is different, so calculate an sha1 fingerprint and see if there really
			#has been a change.
			$index->db_get("\x02\%$id", my $digest);
			$debug && warn "Comparing digests: $digest <-> " . $entry->index_digest . " for " . $name;
			if ($digest eq $entry->index_digest) {
				$index = $self->write_db;
				$self->update_key("\x01\%$id", $entry->index_timestamp);
				$self->close_db;
				$debug && warn "Updated timestamp only, since digest was identical.";
				return "Updated timestamp only, since digest was identical.";
			}
		#} else {
		#	warn "skipping digest check and updating index, since no timestamp was found."
		}
	}
	$index = $self->write_db;

	#scope out a transaction handle whether you need it or not.
	my $txn = undef;
	if ($self->transactions and $self->env) {
		$txn = $self->env->txn_begin;
		$self->{'current_transaction'} = $txn;
	}

	if ($self->dirty) {
		unless ($id_is_new) {
			#allow a major speedup by not purging bad entries, only rendering them invalid.
			#USE ONLY WITH WEBSITES WITH INFREQUENT CHANGES-- DB File will grow continuously
			$debug && warn "dirty purging $id";
			$self->db->db_del($id); #Get rid of the chance of finding by ID
			$self->db->db_get("\x00\%". $name, my $tempid);
			if ($tempid == $id) {
				$self->db->db_del("\x00\%" . $name);
			}
			my ($newid, $id_is_new) = $self->get_id($name);
			unless ($id_is_new and ($tempid == $id)) {
				$self->set_error("Could not get rid of old ID.  Database is likely corrupt." . ($self->strict ? "" : "  Will attempt a regular purge."));
				$self->check_error;
			} else {
				$id = $newid;
			}
		}
	}
	$self->purge_entry($id) unless ($id_is_new); #necessary to clear out words which will not match
	$self->update_key("\x01\%$id", $entry->index_timestamp);
	$self->update_key("\x02\%$id", $entry->index_digest);
	$self->process_html($id, $entry->index_data);
	$self->update_key("\x06\%$id", $entry->index_title) if ($entry->can('index_title'));
	$self->update_key("\x07\%$id", $entry->index_keywords) if ($entry->can('index_keywords'));
	$self->update_key("\x08\%$id", $entry->index_description) if ($entry->can('index_description'));
	if ($self->extended) {
		my @attributes = @{$self->attribute_list};
		splice(@attributes, 0, 8);
		foreach my $attribute (@attributes) {
			my $value = undef;
			if ($entry->can("index_$attribute")) {
				eval('$value = $entry->index_' . $attribute);
				$self->set_error($@) if ($@);
				$self->check_error;
			} elsif (exists($entry->{$attribute})) {
				$value = $entry->{$attribute};
			}
			if ($entry->can("handle_$attribute")) {
				eval('$entry->handle_' . $attribute . '($id, $value)');
				$self->set_error($@) if ($@);
				$self->check_error;
			} else {
				if ($self->maps->{$attribute}) {
					$self->index_map($attribute, $id, [token_parse(lc($value))]);
				} else {
					$self->update_key($self->attributes->{$attribute} . "\%$id", $value);
				}
			}
		}
	}
	$self->update_key($id, $name);
	$self->update_key("\x00%" . $name, $id);
	my $result = 0;
	$self->db->db_get("\xff%greatest_id", my $greatest_id);
	$self->update_key("\xff%greatest_id", $id) if ($id > $greatest_id);
	if ($result) {
		$self->set_error("Failed to store greatest ID: $id");
		$self->check_error;
	}

	if ($self->current_transaction) {
		if ($self->error) {
			unless ($self->quiet) {
				warn join ("\n", "Errors occurred in update of $name => $id:", $self->error, "Aborting transaction...");
			}
			$self->current_transaction->txn_abort;
		} else {
			$self->current_transaction->txn_commit;
		}
		$self->{'current_transaction'} = undef;
	}

	$self->close_db;

	return "Update of entry $id " . ($self->error ? "unsuccessful." : "successful.");
}

sub purge_entry {
	my ($self, $entry) = @_;
	my $id = undef;
	my $found_entry = undef;
	my $not_entry = $self->db->db_get("\x00%$entry", $found_entry);
	if ($not_entry) {
		$id = $entry;
		$self->db->db_get($entry, $found_entry);
		$entry = $found_entry;
	} else {
		$id = $found_entry;
	}
	#warn "$id and $entry";
	unless ($id and $entry) {
		return "Entry not found to purge: $entry";
		return 1;
	}
	$self->set_error("purge_entry called without write access") unless ($self->status eq 'RW');
	foreach my $attribute (@{$self->attribute_list}) {
		next if ($attribute eq 'reverse');
		#warn "purging $attribute";
		if ($self->maps->{$attribute}) {
			$self->purge_map($attribute, $id) unless ($self->dirty) && $self->set_error("failed to purge map $attribute");
		} else {
			$self->delete_key($self->attributes->{$attribute} . "%$id") && $self->set_error("failed to purge key $attribute");
		}
	}
	$self->db->db_del($id) && $self->set_error("failed to purge ID $id");
	$self->db->db_del("\x00%$entry") && $self->set_error("failed to purge entry $entry");
	my $errors = $self->error;
	return "Entry (BerkeleyDB ID# $id) successfully purged" unless ($errors);
	return "Entry (BerkeleyDB ID# $id) failed to be purged: " . join("\n", $self->error) . "\n";
}

=pod

=item (hashref) C<entry_by_name> (scalar)

Given the value of an B<name> attribute, returns a hashref of all the regular
attributes stored for a given entry.

=cut

sub entry_by_name {
	my ($self, $name) = @_;
	my $id = $self->get_id($name);
	return $self->get_entry($id);
}

sub get_entry {
	#note - Call get_entry with an ID ONLY.  No names
	my ($self, $id, $params) = @_;
	$params = {} unless (ref($params) eq 'HASH');
	my $failed = $self->db->db_get($id, my $name);
	return {} if ($failed);
	my %entry = (id => $id, name => $name);
	my @attributes = @{$self->attribute_list};
	my %skip = map {$_ => 1} (@{$params->{'skip'} || []}, @{$self->map_list}, 'name', 'id');
	@attributes = grep {!$skip{$_}} @attributes;
	if ($params->{'limit'}) {
		my %limit = map {$_ => 1} @{$params->{'limit'}};
		@attributes = grep {$limit{$_}} @attributes;
	}
	if ($params->{'require'}) {
		my %unique = ();
		@attributes = grep {$unique{$_}++ == 0} (@attributes, @{$params->{'require'}});
	}
	foreach my $attribute (@attributes) {
		$self->db->db_get($self->attributes->{$attribute} . '%' . $id, $entry{$attribute});
		if ($self->bigfile and $entry{$attribute} =~ s/^\x00://) {
			my $key = $entry{$attribute};
			$self->db_big->db_get($key, $entry{$attribute});
		}
	}
	return \%entry;
}

sub get_id {
	my ($self, $name) = @_;
	my $result = $self->db->db_get("\x00%$name", my $id);
	return $id unless ($result);
	$result = $self->db->db_get("\xff%greatest_id", $id);
	$id ||= 0;#make ID numerical
	#warn ("Did not find $name.  Higest ID found by metadata: " . ($result || $id));
	#warn $self->_error("Index metadata failed to find a highest ID, scanning instead...") if ($result);
	$id++;
	while (not($self->db->db_get($id, my $null))) {
		#make sure this really is a key, and if the metadata fails, we're scanning anyway
		$id++;
	}
	return ($id, 1);#new id + flag
}

sub get_value {
	my ($self, $key) = @_;
	my $result = $self->db->db_get($key, my $value);
	return undef if (($result eq 'DB_NOTFOUND') or !$result);
	$self->recover_db;
	$self->read_db;
	$result = $self->db->db_get($key, $value);
	return undef if (($result eq 'DB_NOTFOUND') or !$result);
	$self->set_error("Could not get key: " . $result);
	$self->check_error;
	return;
}

sub update_key {
	my ($self, $key, $value) = @_;
	my $result = $self->db->db_put($key, $value);
	return undef unless ($result);
	$self->recover_db;
	$self->write_db;
	$result = $self->db->db_put($key, $value);
	return undef unless ($result);
	$self->set_error("Could not set key: " . $result);
	$self->check_error;
	return;
}

sub delete_key {
	my ($self, $key) = @_;
	my $result = $self->db->db_del($key);
	return undef if (($result == DB_NOTFOUND) or !$result);
	$self->recover_db;
	$self->write_db;
	$result = $self->db->db_del($key);
	return undef if (($result == DB_NOTFOUND) or !$result);
	$self->set_error("Could not delete key: " . $result);
	$self->check_error;
}

sub process_html {
	my ($self, $id, $data) = @_;

	return undef if ($self->{'runtime_flags'}->{'no_data'});

	#Remove all punctuation noise from the data and turn all control characters
	#and unicode into entities
	$data = $self->clean_html($data);

	#if we're doing bigfiles, we get a chance to override the re-indexing
	#of large swaths of data if there has been no change to the html of the
	#indexed object
	if ($self->bigfile and length($data) >= 2048) {
		$self->db->db_get("\x03\%$id", my $old_key);
		$old_key =~ s/^\x00://;
		my $current_key = sha1_hex($data);
		if ($current_key ne $old_key) {
			$self->db_big->db_put($current_key, $data);
			my $wordcount = $self->index_words($id, $data);
			$self->update_key("\x03\%$id", "\x00:$current_key");
			$self->update_key("\x05\%$id", $wordcount);
		}
		return;
	}

	$self->update_key("\x03\%$id", $data);
	my $wordcount = $self->index_words($id, $data);
	$self->update_key("\x05\%$id", $wordcount);
	#warn "\x03\%$id updated to $data";
	return;
}

sub extract_html {
	my ($self, $id) = @_;
	$self->db->db_get("\x03\%$id", my $data);
	if ($data =~ s/^\x00:(.+)//) {
		$self->db_big->db_get($1, $data);
	}
	return $data;
}

sub index_map {
	my ($self, $attribute_name, $id, $data) = @_;

	use Encode qw(_utf8_off);
	_utf8_off($data);
	#warn "mapping $id - $attribute : " . join (':', @$data);
	my $attribute = $self->attributes->{$attribute_name};
	my (%unique, $item, @items) = (); # for unique-ifying word list
	#remove duplicates if necessary
	if (ref($data) eq 'ARRAY') {
		@items = grep { $unique{$_}++ == 0 } @$data;
	} elsif (ref($data) eq 'HASH') {
		%unique = %$data;
		@items = keys(%unique);
	} else {
		#not sure why you'd want to do this, but hey.
		@items = ($data);
	}
	if ($attribute_name eq 'word') {
		@items = grep {length($_) >= $self->wordmin} @items;
	}
	# For each item, add id to map
	foreach my $item (sort @items) {

		#This actually does happen, strangely enough.
		unless ($item or ($item =~ /^0+$/o)) {
			warn 'null item here';
			warn 'but defined' if (defined($item));
		}
		my $value = undef;
		my $not_found = $self->db->db_get("$attribute\%$item", my $data);
		my(%entries) = ();
		%entries = unpack("n*", $data) unless ($not_found);
		$entries{$id} = $unique{$item};
		foreach my $item (keys %entries) {
			$value .= pack "n", $item;
			$value .= pack "n", $entries{$item};
		}
		#warn($self->translate_packed($attribute) . "\%$item: " . $self->translate_packed($value));
		$self->update_key("$attribute\%$item", $value);
	}
	if ($self->reversemaps) {
		my $rev_attribute = $self->attributes->{"_$attribute_name"};
		$self->update_key("$rev_attribute\%$id", join("\x00", @items));
	}
	return;
}

sub purge_map {
	my ($self, $attribute_name, $id) = @_;
	my $debug = $self->debug;
	$debug = 1 if ($self->{'runtime_flags'}->{'debug'});
	my $attribute = $self->attributes->{$attribute_name};
	my $rev_attribute = $self->attributes->{"_$attribute_name"};
	my $reverse_index = '';
	my $reversemap_notfound = 1;#by default, don't search for a reversemap unless it's supposed to have one.
	$reversemap_notfound = $self->db->db_get("$rev_attribute\%$id", $reverse_index) if ($self->reversemaps);
	my @updates = ();
	if (not($reversemap_notfound)) {
		$debug && warn ("Found reverse index for map $attribute_name.  Will purge based on that value.");
		foreach my $entry (split "\x00", $reverse_index) {
			#warn "purging $id from $entry";
			my $result = $self->db->db_get("$attribute\%$entry", my $current);
			if ($result) {
				$debug && warn "Reverse index for $attribute_name has a corrupt entry: $entry.  Will do a complete purge.";
				$reversemap_notfound = 1;
				$reversemap_notfound = 0 if ($attribute_name) eq 'word';
				last;
			}
			my(%entries) = unpack("n*", $current);
			#warn "$entry has " . scalar(keys(%entries)) . " documents";
			my $value = undef;
			foreach my $item (keys %entries) {
				#warn "$entry has doc $item";
				next if ($item eq $id);
				$value .= pack "n", $item;
				$value .= pack "n", $entries{$item};
			}
			push (@updates, "$attribute\%$entry", $value);
		}
		$self->db->db_del("$rev_attribute\%$id")  && $self->set_error("Could not remove reversemap for $attribute_name on id $id");
	}
	if ($reversemap_notfound) {
		$debug && $self->reversemaps && warn ("No reverse index for map $attribute_name.  Doing a full purge of $id from the map.");
		my ($key, $current, $removed) = ();
		my $cursor = $self->db->db_cursor;
		unless ($cursor) {
			$self->read_db;
			$cursor = $self->db->db_cursor;
			unless ($cursor) {
				warn 'Failed to obtain DB Cursor.  Aborting purge_map()';
				return 1;
			}
		}
		$cursor->c_get($key, $current, DB_FIRST);
		do {
			if (unpack("C", $key) == ord($attribute)) {
				my $value = undef;
				my $do_update = 0;
				use Apache::Wyrd::Services::SAK qw(spit_file);
				my @test = unpack("n*", $current);
				if (@test % 2) {
					warn 'broken at ' . ord($attribute);
					spit_file('/Users/barry/Desktop/dump', $current);
					die;
				}
				my(%entries) = unpack("n*", $current);
				
				foreach my $item (keys %entries) {
					if ($item eq $id) {
						$do_update = 1;
						next;
					}
					$value .= pack "n", $item;
					$value .= pack "n", $entries{$item};
				}
				push (@updates, $key, $value) if ($do_update);
			}
		} until ($cursor->c_get($key, $current, DB_NEXT));
		$cursor->c_close;
	}
	#cursors have fallen out of scope.  Time to perform the updates.
	while (@updates) {
		my $value = pop @updates;
		my $key = pop @updates;
		$self->update_key($key, $value);
	}
	return scalar($self->error);
}

sub index_words {
	my ($self, $id, $data) = @_;
	# Split text into Array of words
	my (@words) = split(/\s+/, $data);
	$self->index_map('word', $id, \@words);
	return scalar(@words);
}

=pod

=item (scalar) C<clean_html> (scalar)

Given a string of HTML, this method strips out all tags, comments, etc., and
returns only clean lowercase text for breaking down into tokens.

=cut

sub clean_html {
	my ($self, $data) = @_;
	$data = strip_html($data);
	$data = utf8_force($data);
	$data = lc($data);
	$data =~ s/\p{IsM}/ /gs; # Strip M_arks
	$data =~ s/\p{IsP}/ /gs; # Strip P_unct
	$data =~ s/\p{IsZ}/ /gs; # Strip S(Z_)eparators
	$data =~ s/\p{IsC}+/ /sg; # Flatten all whitespace & C_ontrol characters
	$data =~ s/^[\p{IsC} ]+//s; #Remove leading whitespace
	$data =~ s/[\p{IsC} ]+$//s; #Remove trailing whitespace
	$data =~ s/\+//g;
	$data = utf8_to_entities($data); #Encode all multibyte sequences to entities
	$data =~ s/([\x00-\x08\x0B\x0C\x0E-\x1F\x80-\xFF])/'&#x' . sprintf('%X', ord($1)) . ';'/gexs; #Encode all single-byte "unusual" characters
	return $data;
}

sub clean_searchstring {
	goto &clean_html;
}

=pod

=item (array) C<word_search> (scalar, [scalar])

return entries matching tokens in a string within a given map attribute.  As map
attributes store one token, such as a word, against which all entries are
indexed, the string is broken into tokens before processing, with commas and
whitespaces delimiting the tokens unless they are enclosed in double quotes.

If a token begins with a plus sign (+), results must have the word, with a minus
sign, (-) they must not.  These signs can also be placed left of phrases
enclosed by double quotes.

Results are returned in an array of hashrefs ranked by "score".  The attribute
"score" is added to the hash, meaning number of matches for that given entry. 
All other regular attributes of the indexable object are values of the keys of
each hash returned.

The default map to use for this method is 'word'.  If the optional second
argument is given, that map will be used.

=cut

sub word_search { #accepts a search string, returns an arrayref of entry matches
	my ($self, $string, $attribute, $params) = @_;
	if ($attribute) {
		$self->_raise_exception("You cannot perform a word search on the attribute $attribute; It doesn't exist")
			unless ($self->maps->{$attribute});
		$attribute = $self->{'attributes'}->{$attribute};
	} else {
		$attribute = "\x04";
	}
	my $index = $self->read_db;
	my (@out, %match, %must, %mustnot, @match, @add, @remove, $restrict, @entries)=();
	$string =~ s/(\+|\-)\s+/$1/g;
	if ($string =~ /"/) {#first deal with exact word matches
		while ($string =~ m/(([\+-]?)"([^"]+?)")/) { #whole=1, modifier=2, phrase=3
			my $phrase = $self->clean_searchstring($3);
			my $modifier = $2;
			my $substring = $1;
			#escape out phrase and substring since they will be used in regexps
			#later in this subroutine.
			$substring =~ s/([\\\+\?\:\\*\&\@\$\!])/\\$1/g;
			$phrase =~ s/([\\\+\?\:\\*\&\@\$\!])/\\$1/g;
			$string =~ s/$substring//; #remove the phrase from the string;
			if ($modifier eq '+') {
				push (@add, "_$phrase");
				$restrict = 1;
			} elsif ($modifier eq '-') {
				push (@remove, "_$phrase");
			} else {
				push (@match, "_$phrase");
			}
		}
	}
	my @word=split(/\s+/, $string); #then deal with single words
	foreach my $word (@word){
		my ($modifier) = $word =~ /^([\+\-])/;
		$word = $self->clean_searchstring($word);
		if ($modifier eq '+') {
			push (@add, $word);
			$restrict = 1;
		} elsif ($modifier eq '-') {
			push (@remove, $word);
		} else {
			push (@match, $word);
		}
	}
	#warn "searching for:";
	#warn map {"\nmatch - $_"} @match;
	#warn map {"\nadd - $_"} @add;
	#warn map {"\nremove - $_"} @remove;
	#if this is a 100% negative search, all entries match
	unless (scalar(@match) or scalar(@add)) {
		@entries = $self->get_all_entries;
		foreach my $key (@entries) {
			$match{$key}=1;
		}
	}
	foreach my $word (@match){
		if ($word =~ s/^_//) {
			foreach my $entry ($self->get_all_entries) {
				my $data = $self->extract_html($entry);
				my @count = $data =~ m/($word)/g;
				my $count = @count;
				$match{$entry} += $count;
			}
		} else {
			#warn ord($attribute) . "\%$word";
			$index->db_get("$attribute\%$word", my $keys);
			#warn Dumper($keys);
			#warn "match - '" . translate_packed($keys) . "'";
			my (@keys) = unpack("n*",$keys);
			while (@keys) {
				my $entry = shift @keys;
				my $count = shift @keys;
				#warn "entry: $entry, $count: $count";
				$match{$entry} += $count;
			}
		}
	}
	foreach my $word (@add){
		if ($word =~ s/^_//) {
			foreach my $entry ($self->get_all_entries) {
				my $data = $self->extract_html($entry);
				my @count = $data =~ m/($word)/g;
				my $count = @count;
				$match{$entry} += $count;
				$must{$entry.$word}=$count;
				#warn ($entry.$word . " is $count") if ($must{$entry.$word});
			}
		} else {
			$index->db_get("$attribute\%$word", my $keys);
			#warn "add - '" . translate_packed($keys) . "'";
			my (@keys) = unpack("n*",$keys);
			while (@keys) {
				my $entry = shift @keys;
				my $count = shift @keys;
				$match{$entry} += $count;
				$must{$entry.$word}=1;
			}
		}
	}
	foreach my $word (@remove){
		if ($word =~ s/^_//) {
			foreach my $entry ($self->get_all_entries) {
				my $data = $self->extract_html($entry);
				$mustnot{$entry}=$word if ($data =~ m/$word/);
			}
		} else {
			$index->db_get("$attribute\%$word", my $keys);
			my (@keys) = unpack("n*",$keys);
			while (@keys) {
				my $entry = shift @keys;
				shift @keys;
				$mustnot{$entry}=1;
			}
		}
	}
	if ($restrict) {
		foreach my $add (@add) {
			foreach my $key (keys(%match)) {
				#warn "tossing out $index->{$key} ($key) because $add isn't in it." unless $must{$key.$add};
				delete($match{$key}) unless $must{$key.$add};
			}
		}
	}
	foreach my $key (keys(%match)) {
		#warn "tossing out $index->{$key} ($key) because $mustnot{$key} is in it." if ($mustnot{$key});
		delete($match{$key}) if($mustnot{$key});
	}
	my %output=();
	#map actual names to matches
	foreach my $key (keys(%match)) {
		$output{$key}=$self->get_entry($key, $params);
		$output{$key}->{'score'} = $match{$key};
	}
	$self->close_db;
	my %matches=();
	foreach my $id (keys(%output)) {
		$matches{$output{$id}->{'score'}}=1;
	}
	#put matches in order of highest relevance down to lowest by mapping known
	#counts of words against the pages that are known to match that word.
	foreach my $relevance (sort {$b <=> $a} keys %matches){
		next unless $relevance;
		foreach my $id (sort keys(%output)) {
			if ($output{$id}->{'score'} == $relevance){
				push (@out, $output{$id});
			}
		}
	}
	if ($self->dirty) {#Dirt has no name, so drop it if the database is dirty
		@out = grep {$_->{'name'}} @out;
	}
	return @out;
}

=pod

=item (array) C<search> (scalar, [scalar])

Alias for word_search.  Required by C<Apache::Wyrd::Services::SearchParser>.

=cut

sub search {
	my $self = shift;
	return $self->word_search(@_);
}

=pod

=item (array) C<parsed_search> (scalar, [scalar])

Same as word_search, but with the logical qualifiers AND, OR, NOT and
DIFF. More complex searches can be accomplished, at a cost of reduced
speed proportional to the complexity of the logical phrase.  See
C<Apache::Wyrd::Services::SearchParser> for a description of this type
of search.

=cut

sub parsed_search {
	my $self = shift;
	my $parser = Apache::Wyrd::Services::SearchParser->new($self);
	return $parser->parse(@_);
}

sub get_all_entries {
	my $self=shift;
	my @entries = ();
	my $cursor = $self->db->db_cursor;
	$cursor->c_get(my $id, my $entry, DB_FIRST);
	do {
		push @entries, $entry if ($id =~ /^\x00%/);
	} until ($cursor->c_get($id, $entry, DB_NEXT));
	$cursor->c_close;
	return @entries;
}

sub make_key {
	my ($self, $attribute, $id) = @_;
	return $self->attributes->{$attribute} . '%' . $id;
}

sub translate_packed {
	return join('',  map {(($_ + 0) < 33 or ($_ + 0) > 122) ? '{' . $_ . '}' : chr($_)} unpack('c*', $_[1]) );
}

=pod

=back

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Interfaces::Indexable

Methods to be implemented by any item that wants to be indexed.

=item Apache::Wyrd::Services::SearchParser

Parser for handling logical searches (AND/OR/NOT/DIFF).

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut


1;

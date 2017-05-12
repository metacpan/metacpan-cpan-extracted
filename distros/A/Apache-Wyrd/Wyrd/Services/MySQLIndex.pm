package Apache::Wyrd::Services::MySQLIndex;
use base qw(Apache::Wyrd::Services::Index);
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);
our $VERSION = '0.98';
use Apache::Wyrd::Services::SAK qw(token_parse strip_html);
use Apache::Wyrd::Services::SearchParser;
use Digest::SHA qw(sha1_hex);
use Data::Dumper;

=pod

=head1 NAME

Apache::Wyrd::Services::MySQLIndex - MySQL version of Index

=head1 SYNOPSIS

  sub new {
    my ($class) = @_;
    my $dbh = DBI->connect('DBI:mysql:dbname', 'username', 'password');
    my $init = {
      dbh => $dbh,
      debug => 0,
      attributes => [qw(doctype section parent)],
      maps => [qw(tags children)],
    };
    return &Apache::Wyrd::Site::MySQLIndex::new($class, $init);
  }

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

This is a MySQL-backed version of C<Apache::Wyrd::Services::Index>, and in most
ways behaves exactly the same way, using the same methods.  Consequently, only
the differences are documented here.

=head1 METHODS

I<(format: (returns) name (arguments after self))>

=over

=item (Apache::Wyrd::Services::Index) C<new> (hashref)

Create a new MySQLIndex object.  Unlike the BDB-backed version, MySQLIndex is not (yet) capable of auto-creating the database backend.  In this backend, tables for each indexed object must be made as well as a separate table for every reverse index, including the default "word" map which stores the data for the word search.  An example table creation script for the instance under synopsis is as follows:

  drop table if exists _wyrd_index;
  create table _wyrd_index (
  id integer not null auto_increment primary key,
  name varchar(255) unique,
  timestamp long,
  digest char(40),
  data blob,
  wordcount integer,
  title text,
  keywords text,
  description text,
  
  doctype text,
  section text,
  parent text,
  ) ENGINE=MyISAM;
  
  drop table if exists _wyrd_index_word;
  create table _wyrd_index_word (
  item varchar(255) not null,
  id integer,
  tally integer
  ) ENGINE=MyISAM;
  create index id on _wyrd_index_data (id);
  create index item on _wyrd_index_data (item);
  
  drop table if exists _wyrd_index_tags;
  create table _wyrd_index_tags like _wyrd_index_data;
  
  drop table if exists _wyrd_index_children;
  create table _wyrd_index_children like _wyrd_index_data;

Like the BDB version, the C<new> method is initialized with a hashref.  Important keys for this hashref:

=over

=item dbd

A DBI::mysql object reference connected to the database where the 

=item strict

Die on errors.  Default 1 (yes).

=item quiet

If not strict, be quiet in the error log about problems.  Use at your
own risk.

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
	die ('Must provide a database handle') unless($$init{'dbh'});
	$$init{'debug'} = 0 unless exists($$init{'debug'});
	$$init{'strict'} = 1 unless exists($$init{'strict'});
	$$init{'quiet'} = 0 unless exists($$init{'quiet'});

	$$init{'transactions'} = 0 unless exists($$init{'transactions'});
	$$init{'transactions_wanted'} = $$init{'transactions'};
	$$init{'wordmin'} = 3 unless exists($$init{'wordmin'});
	my @attributes = qw(name timestamp digest data wordcount title keywords description);
	my @check_reserved = ();
	foreach my $reserved (@attributes, 'id', 'score', 'db_metadata', 'blob') {
		push @check_reserved, $reserved if (grep {$reserved eq $_} @{$$init{'attributes'}});
		push @check_reserved, $reserved if ($$init{'reversemaps'} and $reserved =~ /^_rev/);
	}
	my $s = '';
	$s = 's' if (@check_reserved > 1);
	die ("Reserved/Illegal attribute$s specified.  Use different name$s: " . join(', ', @check_reserved)) if (@check_reserved);
	my @maps = qw(data);
	my (%attributes, %maps) = ();
	@maps = (@maps, @{$init->{'maps'}}) if (ref($init->{'maps'}) eq 'ARRAY');
	foreach my $map (@maps) {
		$maps{$map} = 1;
	}
	@attributes = (@attributes, @{$init->{'attributes'}}) if (ref($init->{'attributes'}) eq 'ARRAY');
	my $attr_index = 0;

	my @tables = ('_wyrd_index', (map {"_wyrd_index_$_"} @maps));

	my @attribute_map = @attributes;
	my $data = {
		dbh				=>	$$init{'dbh'},
		status			=>	undef,
		debug			=>	$$init{'debug'},
		strict			=>	$$init{'strict'},
		transactions	=>	$$init{'transactions'},
		transactions_wanted	=>	$$init{'transactions_wanted'},
		quiet			=>	$$init{'quiet'},
		error			=>	[],
		attribute_list	=>	\@attributes,
		maps			=>	\%maps,
		map_list		=>	\@maps,
		tables			=>	\@tables,
		extended		=>	((scalar(@attributes) > 8) ? 8 : 0),
		wordmin			=>	$$init{'wordmin'}
	};
	bless $data, $class;
	return $data;
}

sub obsolete {
	my @caller = caller(1);
	my @source = caller(2);
	die "$source[3]() called obsolete method $caller[3]()";
}

sub dbh {
	my ($self) = @_;
	return $self->{'dbh'};
}

sub db {
	my ($self) = @_;
	return $self->{'db'};
}

sub db_big {
	&obsolete;
}

sub env {
	&obsolete;
}

sub extended {
	my ($self) = @_;
	return $self->{'extended'};
}

sub attributes {
	&obsolete;
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
	&obsolete;
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
	&obsolete;
}

sub transactions {
	my ($self) = @_;
	return $self->{'transactions'};
}

sub allow_recovery {
	&obsolete;
}

sub concurrency {
	&obsolete;
}

sub wordmin {
	my ($self) = @_;
	return $self->{'wordmin'};
}

sub reversemaps {
	&obsolete;
}

sub quiet {
	my ($self) = @_;
	return $self->{'quiet'};
}

sub file {
	&obsolete;
}

sub bigfile {
	&obsolete;
}

sub bigfilename {
	&obsolete;
}

sub directory {
	&obsolete;
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
	&obsolete;
}
sub delete_index {
	my ($self) = @_;
	$self->write_db;
	foreach my $table (@{$self->tables}) {
		my $sh = $self->db->prepare("delete from $table");
		$sh->execute;
		if ($sh->err) {
			$self->set_error($sh->errstr);
		}
	}
	$self->close_db;
	return;
}

sub newstatus {
	my ($self, $status) = @_;
	$self->{'status'} = $status;
	return;
}

sub tables {
	my ($self) = @_;
	return $self->{'tables'};
};

sub check_error {
	my ($self) = @_;
	if ($self->strict) {
		if ($self->error) {
			die (join("\n", $self->error));
		}
	} else {
		if ($self->error) {
			$self->{'status'} = 'X';
		}
		return undef if ($self->quiet);
		warn (join("\n", $self->error));
	}
	return;
}

sub read_db {
	my ($self) = @_;
	if ($self->status eq 'R') {
		return $self->db;
	} elsif ($self->status eq 'W') {
		$self->close_db;
	}
	my $db = $self->dbh;
# 	my @tables = map {"$_ read"} @{$self->tables};
# 	my $clause = join ', ', @tables;
# 	my $sh = $db->prepare('lock tables ' . $clause);
# 	$sh->execute;
# 	if ($sh->err) {
# 		$self->set_error($sh->errstr);
# 	} else {
		$self->{'db'} = $db;
		$self->newstatus('R');
#	}
	return;
}

sub write_db {
	my ($self) = @_;
	if ($self->status eq 'W') {
		return $self->db;
 	} elsif ($self->status eq 'R') {
		$self->close_db;
	}
	my $db = $self->dbh;
# 	my @tables = map {"$_ write"} @{$self->tables};
# 	my $clause = join ', ', @tables;
# 	my $sh = $db->prepare('lock tables ' . $clause);
# 	$sh->execute;
# 	if ($sh->err) {
# 		$self->set_error($sh->errstr);
# 	} else {
		$self->{'db'} = $db;
		$self->newstatus('W');
# 	}
	return;
}

sub recover_db {
	&obsolete;
}

sub close_db {
	my ($self) = @_;
	return if ($self->{'status'} eq 'C');
# 	if ($self->{'status'} eq 'W') {
# 		my $db = $self->{'db'};
# 		my $sh = $db->prepare('unlock tables');
# 		$sh->execute;
# 		if ($sh->err) {
# 			$self->set_error($sh->errstr);
# 		}
# 	}
	$self->{'db'} = undef;
	$self->{'status'} = 'C';
	return;
}

sub update_entry {
	my ($self, $entry) = @_;

	#Make sure the object being sent to this update is a valid one.
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

	#check that the name is OK
	my $name = $entry->index_name;
	$self->set_error("Index entries must return non-null for method index_name()") unless ($name);
	$self->check_error;
	$self->set_error("<DELETED> is an invalid name for index entries ") if ($name eq '<DELETED>');
	$self->set_error($name . " is an invalid name for index entries ") if ($name =~ /^.%/s);
	$self->check_error;

	#everything OK?  Start the DB handle and check that it is supposed to be indexed.
	$self->read_db;
	my ($id, $not_found_flag) = $self->get_id($name);

	#If this entry has been set not to index, make sure it is not in the index and return.
	if ($entry->no_index) {
		if ($not_found_flag) {
			#if key is not found
			return "yes to no_index and not indexed.";
		}
		$self->write_db;
		my $result = $self->purge_entry($id);
		$self->close_db;
		return $result;
	}

	$debug && warn $name . " is new" if ($not_found_flag);
	my $current_timestamp = undef; #lexically scoped to reduce multiple timestamp calculations
	my $current_digest = undef; #lexically scoped to reduce multiple digest calculations
	unless ($entry->force_update) {
		my $sh = $self->db->prepare("select id, timestamp, digest from _wyrd_index where name=?");
		$sh->execute($name);
		my ($id, $timestamp, $digest) = @{$sh->fetchrow_arrayref || []};
		$current_timestamp = $entry->index_timestamp;
		$debug && warn "Comparing timestamps: $timestamp <-> " . $current_timestamp . " for " . $name;
		if ($timestamp eq $current_timestamp) {
			$debug && warn "No update needed.  Timestamp is $timestamp." ;
			return "No update needed.  Timestamp is $timestamp." ;
		}
		if ($timestamp) {
			#Timestamp was found and is different, so calculate an sha1 fingerprint and see if there really
			#has been a change.
			$current_digest = $entry->index_digest;
			$debug && warn "Comparing digests: $digest <-> " . $current_digest . " for " . $name;
			if ($digest eq $current_digest) {
				$self->write_db;
				$self->update_key($id, 'timestamp', $current_timestamp);
				$self->close_db;
				$debug && warn "Updated timestamp only, since digest was identical.";
				return "Updated timestamp only, since digest was identical.";
			}
		}
	}

	#We are sure the object's entry is out-of-date, so it's time to update.
	$self->write_db;

	#TODO: Add a new way of handling transactions

	my %entry = ();
	$self->purge_entry($id) unless ($not_found_flag); #necessary to clear out words which will not match
	$entry{'name'} = $name;
	$entry{'timestamp'} = $current_timestamp;
	$entry{'digest'} = $current_digest || $entry->index_digest;
	$entry{'title'} = $entry->index_title if ($entry->can('index_title'));
	$entry{'keywords'} = $entry->index_keywords if ($entry->can('index_keywords'));
	$entry{'description'} = $entry->index_description if ($entry->can('index_description'));

	my $field_clause = '(' . join(', ', keys %entry) . ')';
	my $value_clause = 	'('
						. join(
								', ',
									(
										map {$self->db->quote($_)} values %entry
									)
						)
						. ')';

	my $sh = $self->db->prepare("insert into _wyrd_index $field_clause values $value_clause");
	$sh->execute;
	$id = $sh->{'mysql_insertid'};

	if ($sh->err) {
		$self->set_error($sh->errstr);
	} else {

		$self->process_html($id, $entry->index_data);

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
						if (defined($value)) {
							$self->index_map($attribute, $id, [token_parse(lc($value))]);
						}
					}
						if (defined($value)) {
							$self->update_key($id, $attribute, $value);
						}
				}
			}
		}
	}


	#TODO: Deal with failed update transactions here.

	$self->close_db;

	return "Update of entry $id " . ($self->error ? "unsuccessful." : "successful.");
}

sub purge_entry {
	my ($self, $entry) = @_;
	my $id = undef;
	if ($entry =~ /[^\d]/) {
		$id = $self->get_id($entry);
	} else {
		$id = $entry;
	}
	if ($id) {
		$self->write_db;
		foreach my $table (@{$self->tables}) {
			my $sh = $self->db->prepare("delete from $table where id=?");
			$sh->execute($id);
			if ($sh->err) {
				$self->set_error($sh->errstr);
			}
		}
		$self->read_db;
	} else {
		$self->set_error("Entry not found to purge: $entry");
	}

	if ($self->error) {
		return "Entry ($entry : $id) failed to be purged: " . join("\n", $self->error) . "\n";
	}
	return "Entry ($entry : $id) successfully purged";
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
	my $debug = $self->debug;
	my $in_clause = '';
	if (ref($id) eq 'ARRAY') {
		unless (scalar(@$id)) {
			$debug && warn "get_entry() was passed an empty array, aborting.";
			return;
		}
		$in_clause = join ', ', @$id;
		$in_clause = qq{in ($in_clause)};
	} else {
		unless (defined($id) and not(ref($id))) {
			if (ref($id)) {
				$debug && warn "get_entry was passed an invalid reference, aborting.";
			} else {
				$debug && warn "get_entry was passed an undefined value, aborting.";
			}
			return;
		}
		$in_clause = qq{='$id'};
	}
	$params = {} unless (ref($params) eq 'HASH');

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

	my $attributes = join (", ", @attributes);
	$self->read_db;
	my $sh = $self->db->prepare("select id, name, $attributes from _wyrd_index where id $in_clause");
	$sh->execute;
	if ($sh->err) {
		$self->set_error($sh->errstr);
	}
	my @entries = ();
	while(my $data_ref = $sh->fetchrow_hashref) {
		#copy off the data to a hash
		my %entry = %$data_ref;
		push @entries, \%entry;
	}
	$self->close_db;
	if (wantarray) {
		return @entries;
	} else {
		return $entries[0];
	}
}

sub get_id {
	my ($self, $name) = @_;
	my $sh = $self->db->prepare('select id from _wyrd_index where name=?');
	$sh->execute($name);
	if ($sh->err) {
		$self->set_error($sh->errstr);
	}
	my $not_found = undef;
	my $data_ref = $sh->fetchrow_arrayref;
	my $id = $data_ref->[0];
	unless ($id) {
		$not_found = 1;
	}
	if (wantarray) {
		return ($id, $not_found);
	}
	return $id;
}

sub get_value {
	my ($self, $id, $attribute) = @_;
	my $sh = $self->db->prepare("select $attribute from _wyrd_index where id=?");
	$sh->execute($id);
	if ($sh->err) {
		$self->set_error($sh->errstr);
	}
	my $data_ref = $sh->fetchrow_arrayref;
	my $value = $data_ref->[0];
	return $value;
}

sub update_key {
	my ($self, $id, $attribute, $value) = @_;
	my $sh = $self->db->prepare("update _wyrd_index set $attribute=? where id=?");
	$sh->execute($value, $id);
	if ($sh->err) {
		$self->set_error($sh->errstr);
	}
	return;
}

sub delete_key {
	&obsolete;
}

sub process_html {
	my ($self, $id, $data) = @_;

	return if ($self->{'runtime_flags'}->{'no_data'});

	#Remove all punctuation noise from the data
	$data = $self->clean_html($data);

	$self->update_key($id, 'data', $data);
	my $wordcount = $self->index_words($id, $data);
	$self->update_key($id, 'wordcount', $wordcount);

	return;
}

sub extract_html {
	&obsolete;
}

sub index_words {
	my ($self, $id, $data) = @_;
	# Split text into Array of words
	my (@words) = split(/\s+/, $data);
	$self->index_map('data', $id, \@words);
	return scalar(@words);
}

sub index_map {
	my ($self, $attribute_name, $id, $data) = @_;

	my $debug = $self->debug;
	$debug = 1 if ($self->{'runtime_flags'}->{'debug'});

	my $table = '_wyrd_index_' . $attribute_name;
	$debug && warn "mapping $id - $attribute_name : " . Dumper($data);

	my (%unique, $item, @items) = (); # for unique-ifying word list

	#remove duplicates if necessary
	if (ref($data) eq 'ARRAY') {
		@items = grep { $unique{$_}++ == 0 } @$data;
	} elsif (ref($data) eq 'HASH') {
		#IMPORTANT: %unique is lexically scoped out of this point in order to
		#use it to hold data counts below.
		%unique = %$data;
		@items = keys(%unique);
	} else {
		#not sure why you'd want to do this, but hey.
		@items = ($data);
	}
	if ($attribute_name eq 'data') {
		@items = grep {length($_) >= $self->wordmin} @items;
	}

	#make an array of data items to be assembled into an efficient insert query.
	my @entries = ();
	# For each item, add id to map
	foreach my $item (@items) {
		#N.B. Do not skip over undefined here.
		my $count = $unique{$item} || 1;
		push @entries, "('$item', $id, $count)";
	}
	if (@entries) {
		my $query = "insert into $table (item, id, tally) values " . join(", ", @entries);
		my $sh = $self->db->prepare($query);
		$sh->execute;
		if ($sh->err) {
			$self->set_error($sh->errstr);
		}
	}
	return;
}

sub purge_map {
	my ($self, $attribute_name, $id) = @_;

	my $debug = $self->debug;
	$debug = 1 if ($self->{'runtime_flags'}->{'debug'});

	my $table = '_wyrd_index_' . $attribute_name;

	my $sh = $self->db->prepare("delete from $table where id=?");
	$sh->execute($id);
	if ($sh->err) {
		$self->set_error($sh->errstr);
	}
	return;
}

sub word_search { #accepts a search string, returns an arrayref of entry matches
	my ($self, $string, $attribute, $params) = @_;
	if ($attribute) {
		$self->_raise_exception("You cannot perform a word search on the attribute $attribute; It doesn't exist or isn't a map")
			unless ($self->maps->{$attribute});
	} else {
		$attribute = 'data';
	}
	my $table = '_wyrd_index_' . $attribute;
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
			my $sh = $self->db->prepare(qq{select id, $attribute from _wyrd_index where $attribute like '\%$word\%'});
			$sh->execute;
			if ($sh->err) {
				$self->set_error($sh->errstr);
			}
			while (my $data_ref = $sh->fetchrow_arrayref) {
				my $entry = $data_ref->[0];
				my $data = $data_ref->[1];
				my @count = $data =~ m/$word/g;
				my $count = @count;
				$match{$entry} += $count;
			}
		} else {
			my $sh = $self->db->prepare(qq{select id, tally from $table where item=?});
			$sh->execute($word);
			if ($sh->err) {
				$self->set_error($sh->errstr);
			}
			while (my $data_ref = $sh->fetchrow_arrayref) {
				my $entry = $data_ref->[0];
				my $count = $data_ref->[1];
				$match{$entry} += $count;
			}
		}
	}
	foreach my $word (@add){
		if ($word =~ s/^_//) {
			my $sh = $self->db->prepare(qq{select id, $attribute from _wyrd_index where $attribute like \%$word\%});
			$sh->execute;
			if ($sh->err) {
				$self->set_error($sh->errstr);
			}
			while (my $data_ref = $sh->fetchrow_arrayref) {
				my $entry = $data_ref->[0];
				my $data = $data_ref->[1];
				my @count = $data =~ m/$word/g;
				my $count = @count;
				$match{$entry} += $count;
				$must{$entry.$word}=$count;
			}
		} else {
			my $sh = $self->db->prepare(qq{select id, tally from $table where item=?});
			$sh->execute($word);
			if ($sh->err) {
				$self->set_error($sh->errstr);
			}
			while (my $data_ref = $sh->fetchrow_arrayref) {
				my $entry = $data_ref->[0];
				my $count = $data_ref->[1];
				$match{$entry} += $count;
				$must{$entry.$word}=$count;
			}
		}
	}
	foreach my $word (@remove){
		if ($word =~ s/^_//) {
			my $sh = $self->db->prepare(qq{select id, $attribute from _wyrd_index where $attribute like \%$word\%});
			$sh->execute;
			if ($sh->err) {
				$self->set_error($sh->errstr);
			}
			while (my $data_ref = $sh->fetchrow_arrayref) {
				my $entry = $data_ref->[0];
				$mustnot{$entry}=1;
			}
		} else {
			my $sh = $self->db->prepare(qq{select id, tally from $table where item=?});
			$sh->execute($word);
			if ($sh->err) {
				$self->set_error($sh->errstr);
			}
			while (my $data_ref = $sh->fetchrow_arrayref) {
				my $entry = $data_ref->[0];
				$mustnot{$entry}=1;
			}
		}
	}
	if ($restrict) {
		foreach my $add (@add) {
			foreach my $key (keys(%match)) {
				delete($match{$key}) unless $must{$key.$add};
			}
		}
	}
	foreach my $key (keys(%match)) {
		delete($match{$key}) if($mustnot{$key});
	}
	my %output=();
	#map actual names to matches
	foreach my $entry ($self->get_entry([keys %match], $params)) {
		my $key = $entry->{'id'};
		$output{$key}=$entry;
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

sub get_all_entries {
	my $self=shift;
	my @entries = ();
	my $sh = $self->dbh->prepare("select id from _wyrd_index");
	$sh->execute;
	if ($sh->err) {
		$self->set_error($sh->errstr);
	}
	while (my $entry = $sh->fetchrow_arrayref) {
		my $id = $entry->[0];
		push @entries, $id;
	}
	return @entries;
}

sub make_key {
	&obsolete;
}

sub translate_packed {
	&obsolete;
}

=pod

=back

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Services::Index

BDB-backed base class to this class

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


=head1 NAME

XBase::SDBM - SDBM index support for dbf

=head1 DESCRIPTION

When developing the XBase.pm/DBD::XBase module, I was trying to
support as many existing variants of file formats as possible. The
module thus accepts wide range of dbf files and their versions from
various producers. But with index files, the task is much, much
harder. First, there is little or no documentation of index files
formats, so the development is based on reverse engineering.

None if the index formats support is finalized. That made it hard to
integrate them into one consistent API. That is why I decided to write
my own index support, and as I wanted to avoid inventing yet another
way of storing records in pages and similar things, I used SDBM. It
comes with Perl, so you already have it, and it's proven and it
works.

Now, SDBM is a module that aims at other task than to do supporting
indexes for a dbf. But equality tests are fast with it and I have
creted a structure in each index file to enable "walk" though the
index file.

=head1 VERSION

1.02

=head1 AVAILABLE FROM

http://www.adelton.com/perl/DBD-XBase/

=head1 AUTHOR

(c) 2001--2011 Jan Pazdziora.

All rights reserved. This package is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

package XBase::SDBM;
use SDBM_File;
use Fcntl;

sub fetch {
	my $self = shift;
	my $current = $self->{'current'};	# current pointer
	return unless defined $current;
	my $hash = $self->{'sdbmhash'};
	my $value = $hash->{$current};

	if (not defined $value) {
		delete $self->{'current'};
		return;
	}
	my ($key, $num) = ($current =~ /^(.*):(\d+)$/s);
	$num++;
	if (defined $hash->{"$key:$num"}) {	# next record for the same key
		$self->{'current'} = "$key:$num";
	} else {
		my $newkey = $hash->{"$key:next"};	# next key
		if (defined $newkey) {
			$self->{'current'} = "$newkey:1";
		} else {
			delete $self->{'current'};
		}
	}
	return ($key, $value);
}
sub fetch_current {
	my $self = shift;
	my $current = $self->{'current'};
	return unless defined $current;
	my $value = $self->{'sdbmhash'}{$current};
	return unless defined $value;
	my ($key) = ($current =~ /^(.*):\d+$/s);
	return ($key, $value);
}
sub tags {
	my $self = shift;
	return map { if (s/:file$//) { ( $_ ) } else { () } }
		keys %{$self->{'definition'}};
}

sub prepare_select {
	my $self = shift;
	$self->{'current'} = $self->{'sdbmhash'}{':first'};
	$self->{'current'} .= ':1' if defined $self->{'current'};
	1;
}
sub prepare_select_eq {
	my ($self, $eq, $recno) = @_;
	delete $self->{'current'};
	my $hash = $self->{'sdbmhash'};
	my $start = $eq;
	my $value = $hash->{"$start:1"};

	if (not defined $value) {
		# not exact match
		$start = $hash->{':first'};
		if (not defined $start) {
			# no records, jsut return
			return 1;
		}
		# move throught the chain
		while (defined $start and $start lt $eq) {
			$start = $hash->{"$start:next"};	
		}
		if (not defined $start) {
			return 1;
		}
		if ($start gt $eq) {
			$self->{'current'} = "$start:1";
			return 1;
		}
		# we shouldn't have never got here, but nevermind
		$value = $hash->{"$start:1"};
	}

	# here we've found exact match of the key
	if (not defined $recno) {
		# if not requested exact match of the recno, return
		$self->{'current'} = "$start:1";
		return 1;
	}

	my $num = 1;
	while (defined $value and $value != $recno) {
		$num++;
		$value = $hash->{"$start:$num"};
	}

	if (defined $value) {
		$self->{'current'} = "$start:$num";
	} else {
		$start = $hash->{"$start:next"};
		$self->{'current'} = "$start:1" if defined $start;
	}
	1;
}


# method new (open) will open the named SDBM index for given dbf
sub new {
	my ($class, $filename, %opts) = @_;
	my $dbf = $opts{'dbf'};
	my $tag = $opts{'tag'};
	
	# return immediatelly if the index file was already opened
	return $dbf->{'sdbm_definition'}{'tags'}{$tag}
		if defined $dbf->{'sdbm_definition'}
			and defined $dbf->{'sdbm_definition'}{'tags'}{$tag};

	my $dbffile = $dbf->{'filename'};
	my $file = $dbffile;
	$file =~ s/\.dbf$/.sdbmd/i;

	# some of the SDBM indexes were already touched
	# the definitionhash is a SDBM that lists the content of the
	# actual SDBM index files
	my $definitionhash = {};
	if (defined $dbf->{'sdbm_definition'}) {
		$definitionhash = $dbf->{'sdbm_definition'}{'definitionhash'};
	}
	else {
		# if it wasn't opened yet, open the definition file
		if (not tie(%$definitionhash, 'SDBM_File',
				$file, O_RDWR, 0666)) {
			die "SDBM index definition file `$file' not found for `$dbffile': $!.";
		}
		$dbf->{'sdbm_definition'} = { 'filename' => $file,
					'definitionhash' => $definitionhash };
	}

	# check the definition file for tag requested
	my $sdbmfile = $definitionhash->{"$tag:file"};
	if (not defined $sdbmfile) {
		# no such SDBM index exists, the definition SDBM says
		die "SDBM index `$tag' not known for `$dbffile'.";
	}

	# open the SDBM index file
	my $sdbmhash = {};
	unless (tie(%$sdbmhash, 'SDBM_File', $sdbmfile, O_RDWR, 0666)) {
		die "SDBM index file `$sdbmfile' not found for `$dbffile': $!.";
	}

	my $self = bless { 'dbf' => $dbf,
		'tag' => $tag, 'sdbmhash' => $sdbmhash,
		'definition' => $definitionhash }, $class;
	$dbf->{'sdbm_definition'}{'tags'}{$tag} = $self;
	return $self;
}
*open = \&new;

# method create will create SDBM index with given name and expression
# for the dbf table
sub create {
	my ($class, $dbf, $tag, $expression) = @_;
	my $dbffile = $dbf->{'filename'};
	my $file;

	my $definitionhash;
	if (defined $dbf->{'sdbm_definition'}) {
		# the definition SDBM was already opened
		$definitionhash = $dbf->{'sdbm_definition'}{'definitionhash'};
	} else {
		$file = $dbffile;
		$file =~ s/\.dbf$/.sdbmd/i;

		$definitionhash = {};
		# open or create the definition SDBM file
		if (not tie(%$definitionhash, 'SDBM_File',
				$file, O_RDWR|O_CREAT, 0666)) {
			die "SDBM index definition file `$file' not found/created for `$dbffile': $!.";
		}
		$dbf->{'sdbm_definition'} = { 'filename' => $file,
			'definitionhash' => $definitionhash };
	}

	if (defined $definitionhash->{"$tag:file"}) {
		die "SDBM index `$tag' already exists for `$dbfffile'.";
	}

	my $maxindexnumber = ++$definitionhash->{'tagnumber'};

	my $sdbmfile = $dbffile;
	$sdbmfile =~ s/\.dbf$/.sdbm$maxindexnumber/i;

	my $sdbmhash = {};
	if (not tie(%$sdbmhash, 'SDBM_File', $sdbmfile, O_CREAT|O_EXCL|O_RDWR, 0666)) {
		die "SDBM index file `$sdbmfile' couldn't be created for `$dbffile': $!."
	}

	my $self = bless { 'dbf' => $dbf, 'tag' => $tag,
		'sdbmhash' => $sdbmhash,
		'definition' => $definitionhash}, $class;
	$dbf->{'sdbm_definition'}{'tags'}{$tag} = $self;
	$definitionhash->{"$tag:file"} = $sdbmfile;

	if (defined $dbf->field_type(uc $expression)) {
		$expression = uc $expression;
	}
	if (not defined $dbf->field_type($expression)) {
		$self->drop;
		die "SDBM index `$expression' couldn't be created for `$dbffile': no such column name.";
	}
	$definitionhash->{"$tag:expression"} = $expression;

	my $i = 0;
	while ($i <= $dbf->last_record) {
		my ($deleted, $value) = $dbf->get_record($i);
		if (not $deleted) {
			$self->insert($value, $i + 1);		
		}
		$i++;
	}

	return $self;
}

# method drop will drop the SDBM index
sub drop {
	my ($self) = @_;
	my $tag = $self->{'tag'};
	my $definitionhash = $self->{'definition'};
	my $sdbmfile = $definitionhash->{"$tag:file"};
	delete $definitionhash->{"$tag:file"};
	delete $definitionhash->{"$tag:definition"};
	delete $self->{'dbf'}{'sdbm_definition'}{'tags'}{$tag};
	unlink "$sdbmfile.pag", "$sdbmfile.dir";
}

sub insert {
	my ($self, $key, $value) = @_;
	### print "Adding $key $value\n";
	my $hash = $self->{'sdbmhash'};
	my $key_maxid = $hash->{"$key:0"};
	$key_maxid++;

	$hash->{"$key:$key_maxid"} = $value;
	$hash->{"$key:0"} = $key_maxid;
	return 1 if $key_maxid > 1;	# no need to change the chain
	
	my $prev = undef;
	my $prev_next = ':first';
	my $next;
	while (defined($next = $hash->{$prev_next}) and $key gt $next) {
		$prev = $next;
		$prev_next = "$prev:next";
		$next = undef;
	}

	if (not defined $next) {
		$hash->{':last'} = $key;	# we reached the last record
	} else {
		$hash->{"$key:next"} = $next;
		$hash->{"$next:prev"} = $key;
	}
	if (not defined $prev) {
		$hash->{':first'} = $key;
	} else {
		$hash->{"$prev:next"} = $key;
		$hash->{"$key:prev"} = $prev;
	}
	return 1;
}

sub delete {
	my ($self, $key, $value) = @_;
	### print "Deleting $key $value\n";
	my $hash = $self->{'sdbmhash'};
	my $key_maxid = $hash->{"$key:0"};

	my $number = 1;
	while ($number <= $key_maxid) {
		if ($hash->{"$key:$number"} == $value) {
			last;
		}
		$number++;
	}
	if ($number > $key_maxid) {
		# such a record was not found
		return 0;
	}

	if ($key_maxid > 1) {
		$hash->{"$key:$number"} = $hash->{"$key:$key_maxid"}
			if $number != $key_maxid;
		delete $hash->{"$key:$key_maxid"};
		$hash->{"$key:0"} = $key_maxid - 1;
	} else {
		my $next = $hash->{"$key:next"};
		my $prev = $hash->{"$key:prev"};
		if (defined $next) {
			if (not defined $prev) {
				$hash->{':first'} = $next;
				delete $hash->{"$next:prev"};
			} else {
				$hash->{"$prev:next"} = $next;
				$hash->{"$next:prev"} = $prev;
				delete $hash->{"$key:prev"};
			}
			delete $hash->{"$key:next"};
		} else {
			if (not defined $prev) {
				delete $hash->{':first'};
				delete $hash->{':last'};
			} else {
				$hash->{':last'} = $prev;
				delete $hash->{"$prev:next"};
				delete $hash->{"$key:prev"};
			}
		}
		delete $hash->{"$key:0"};
		delete $hash->{"$key:1"};
	}
	return 1;
}
sub delete_current {
	my $self = shift;
	my ($key, $value) = $self->fetch_current;
	if (defined $value) {
		$self->delete($key, $value);
	}
}
sub insert_before_current {
	die "SDBM index doesn't support backward rolling yet.\n";
}

sub dump {
	my $self = shift;
	my $hash = $self->{'sdbmhash'};

	for (sort keys %$hash) {
		print "$_ $hash->{$_}\n";
	}
}

1;


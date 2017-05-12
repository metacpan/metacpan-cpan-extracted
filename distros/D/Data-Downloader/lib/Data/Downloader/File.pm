=head1 NAME

Data::Downloader::File

=head1 DESCRIPTION

Represents a file managed by Data::Downloader.  Files
are represented in the database as rows in the file table.
Each row corresponds to a single file on disk.  There may
be multiple symbolic links to this file, but the uniqueness
of this row reflects the different ways in
in which files and their contents may be considered unique.
In addition the unique numeric integer id for this file, there
are three types of uniqueness : content, filename, and resource.

=over

=item content

If a file appears in a feed which has the same MD5 sum as an existing file,
it will not be downloaded multiple times.  However, multiple symlink links
may be created for it (based on the metadata in the feed).

=item filename

Filenames are considered unique; if an existing filename appears again,
it will be treated as an update, rather than an insert, to the metadata
database.  (However, if the MD5 differs, it will be re-downlaoded).

=item resource

If a urn_xpath is given in the L<configuration|Data::Downloader::Config>, this
will be treated a unique identifier for the content.  If the same value
appears again, an update, rather than an insert, will occur.  If the filename
is different, this will be changed.  if the content is different, new
content will be downloaded and the old content will be removed.

=back


=head1 METHODS

=over

=cut

package Data::Downloader::File;
use Data::Downloader::Utils qw/ERRORDIE WARNDIE/;
use Log::Log4perl qw/:easy/;
use String::Template qw/expand_string missing_values/;
use Params::Validate qw/validate/;
use File::Temp;
use File::Path qw/mkpath/;
use File::stat qw/stat/;
use File::Basename qw/basename dirname/;
use Digest::MD5::File;
use Time::HiRes qw/gettimeofday/;
use File::Spec;
use List::MoreUtils qw/uniq/;
use strict;
use warnings;

=item storage_path

Returns the storage path for this file.  This is calculated
using the md5, the disk, and the storage root of the repository
associated with this file.

=cut

sub storage_path {
    my $self = shift;
    unless (defined($self->md5)) {
        TRACE "can't compute storage path without md5";
        return;
    }
    return join '/', $self->repository_obj->storage_root,
      ( $self->disk ? $self->disk_obj->root : () ),
      ( grep length, split /(..)/, $self->md5 ), $self->filename;
}

sub _storage_path { shift->storage_path } # backwards compatibility

sub _check_hash {
    my $self = shift;
    my $filename = shift || $self->storage_path;
    my $md5 = Digest::MD5::File->new();
    $md5->addpath($filename);
    return $md5->hexdigest eq $self->md5;
}

sub _store_hash {
    my $self = shift;
    my $filename = shift || $self->storage_path;
    my $md5 = Digest::MD5::File->new();
    $md5->addpath($filename);
    $self->md5($md5->hexdigest);
}

sub _store_url {
    my $self = shift;
    my %args = @_;
    my $template = $self->repository_obj->file_url_template;
    for my $c ($self->meta->columns) {
        $args{$c} = $self->$c unless exists $args{$c};
    }
    if (my @missing = missing_values($template, \%args) ) {
        LOGDIE "Can't compute download url, missing @missing";
    }
    $self->url(expand_string($template, \%args));
}

sub _already_downloaded {
    my $self = shift;
    TRACE "checking for already downloadedness";
    return ( $self->md5
          && $self->filename
          && -e $self->storage_path
          ) ? 1 : 0;
}

# Get the element(s) which produce the min value of a subroutine.
sub _minmap(&@) {
    my $sub = shift;
    return unless @_;
    my @min = (shift);
    my $min = $sub->($min[0]);
    for (@_) {
        my $val = $sub->($_);
        if    ( $val < $min  ) { ( $min, @min ) = ( $val, $_ ); }
        elsif ( $val == $min ) { push @min, $_;                 }
    }
    return @min;
}
# Ditto for max
sub _maxmap(&@) {
    my $sub = shift;
    return _minmap(sub { -$sub->(shift) }, @_);
}

# Choose the disk (if the repository has multiple disks).
sub _choose_disk {
    my $self = shift;

    # Disk already set?
    if ($self->disk) {
	TRACE "disk already defined: ".$self->disk_obj->root;
	return $self->disk;
    }

    # Possible disks
    my @disks = @{ $self->repository_obj->disks || [] };
    return unless @disks > 0;
    TRACE "Possible disks : ".join ',',(map $_->root, @disks);
    my $pick;

    # Easy case : all disks have different amounts of space.
    my @chosen = _maxmap { shift->blocks_available(block_size => '1024') } @disks;
    if (@chosen==1) {
	$pick = $chosen[0];
        DEBUG "Chose disk ".$pick->root." using disk usages";
    }

    # Choose the one from which we've taken the least (using the db).
    unless ($pick) {
	@chosen = _minmap { shift->bytes_taken } @chosen;
	if (@chosen==1) {
	    $pick = $chosen[0];
	    DEBUG "Chose disk ".$pick->root." using min we have used";
	}
    }

    # Still more than one?  Choose a random disk.
    unless ($pick) {
	@chosen = ( $chosen[ int rand @chosen] );
	$pick = $chosen[0];
	DEBUG "Chose disk ".$pick->root." randomly";
    }

    # Update
    LOGDIE "could not choose disk" unless (defined $pick);
    $self->disk($pick->id);
    $self->disk_obj($pick);
    LOGDIE "could not choose disk" unless ($self->disk_obj->id==$pick->id);
    return $self->disk;
}

=item download

Download a file.  This may be called as either
a class method or an instance method.  In the
former case, it acts as a constructor, saving the
object to the database.

Compute the URL if necessary.  The URL may come
from either an RSS feed (i.e. this file is already
in the database) or may be computed using the
url template.

Examples :

    # make a new file, download it, store it, update symlinks
    my $file = Data::Downloader::File->download(
        md5        => "a46cee6a6d8df570b0ca977b9e8c3097",
        filename   => "OMI-Aura_L2-OMTO3_2007m0220t0052-o13831_v002-2007m0220t221310.he5",
        repository => "local_repo",
    );

    # equivalent
    my $file = Data::Downloader::File->new(
        md5        => "a46cee6a6d8df570b0ca977b9e8c3097",
        filename   => "OMI-Aura_L2-OMTO3_2007m0220t0052-o13831_v002-2007m0220t221310.he5",
        repository => Data::Downloader::Repository->new( name => "local_repo" )->load->id,
    );
    $file->download or die $file->error;

    # download all files for a certain feed
    $_->download for $feed->files;

Parameters :
 repository - a repository name
 fake       - fake the download?
 skip_links - Skip making symlinks?
 <name>     - value : value for the variable
              "<name>" in the url_template.

Returns :

 true (1)   - the file was downloaded or cached
 false (0)  - there was an error (look in $obj->error for a message)

=cut

sub download {
    my $self = shift;
    my %args = @_;
    my $repository_obj;

    if (my $repository_name = $args{repository}) {
        INFO "downloading into repository $repository_name";
        $repository_obj = Data::Downloader::Repository->new(name => $args{repository});
        $repository_obj->load or LOGDIE $repository_obj->error;
    }

    my $loaded;
    unless (ref $self) { # make a new object
        my %constructor_args = %args;
        $constructor_args{repository} = $repository_obj->id if $repository_obj;
        delete $constructor_args{fake};
        LOGDIE "no support for urns in new files yet" if $constructor_args{urn};
        $self = __PACKAGE__->new(%constructor_args);
        my $loaded = $self->load(speculative => 1);
        DEBUG $loaded ? "Found file in db" : "File not yet in db";
    }

    # Compute the URL.
    defined($self->url) or $self->_store_url(%args); # may die
    DEBUG "downloading url is ".$self->url;

    my $request_time = DateTime->now();
    if ( $self->_already_downloaded ) {
        DEBUG "File has already been downloaded";
        $self->add_log_entries({
                requested_at => $request_time,
                cache_hit    => 1,
                completed_at => $request_time,
                prog         => $0,
                pid          => $$,
                uid          => $<,
                note         => $ENV{DATA_DOWNLOADER_LOG_NOTE},
            }) if $ENV{DATA_DOWNLOADER_GATHER_STATS};
        return $self;
    }
    if ($self->storage_path && -e $self->storage_path) {
        # something changed, e.g. check_hash failed (previous
        # fake download?  Corrupt disk?)  Remove the file that's
        # stored.
        INFO "removing invalid file ".$self->storage_path;
        unlink $self->storage_path or do {
	    ERROR "Failed to remove file : $@";
	    return;
	};
        $self->on_disk(0);
    }

    # TODO only sometimes?
    $self->repository_obj->cache->purge;

    my $root = $self->repository_obj->storage_root;
    -d $root or mkpath $root or do {
	ERROR "couldn't mkdir $root : $!";
	return;
    };

    # First make a temp file on the same filesystem.
    $self->_choose_disk;
    if ($self->disk && ! -d $self->disk_obj->abs_path) {
        mkpath $self->disk_obj->abs_path;
    }
    my $tmpfile = File::Temp->new(
        UNLINK   => 0,
        DIR      => ($self->disk ? $self->disk_obj->abs_path : $root),
        TEMPLATE => "download.tmp.XXXXXXX"
    );

    # Download it before computing the storage path, since storing uses the hash.
    if ($args{fake}) {
        DEBUG "faking the download";
        print $tmpfile "This is a test file from ".$self->url."\n";
        print $tmpfile "MD5: ".($self->md5 || "unknown before download")."\n";
        print $tmpfile "Some random stuff : ".rand."\n";
        $tmpfile->flush;
    } else {
        INFO "downloading from ".$self->url;
        my $max_time = $ENV{DATA_DOWNLOADER_TIMEOUT} || $ENV{DADO_MAX_TIME_PER_FILE} || 300;
        system(qw/curl -L --fail --silent --insecure --compressed --max-time/,$max_time,"-o","$tmpfile",$self->url)==0
            or do {
                my $info = "$?";
                $info .= "${^CHILD_ERROR_NATIVE}" if defined(${^CHILD_ERROR_NATIVE});
                $self->error("failed to get file: $info");
                ERROR "failed to get file (error code: $info)";
                unlink $tmpfile;
                return;
            };
    }

    # Compute or check the hash.
    if (defined($self->md5)) {
       unless ($args{fake}) {
           $self->_check_hash($tmpfile) or do {
               my $error = "bad md5 for ".$self->filename." ($tmpfile)";
               ERROR $error;
               $self->error($error);
               unlink $tmpfile;
               return;
           };
       }
    } else {
       $self->_store_hash($tmpfile);
    }

    # Now put it in place
    my $destination = $self->storage_path;
    my $destdir = dirname($destination);
    unless (-d $destdir) {
	mkpath($destdir) or do {
	    ERROR "couldn't make directory $destdir: $!";
	    unlink $tmpfile;
	    return;
	};
    }
    rename $tmpfile, $destination or do {
	ERROR "rename to $destination failed: $!";
	unlink $tmpfile;
	return;
    };
    chmod 0644, $destination or do {
	ERROR "chmod failed: $!";
	unlink $tmpfile;
	return;
    };
    TRACE "downloaded to $destination";

    $self->on_disk(1);
    $self->add_log_entries( {
                requested_at => $request_time,
                cache_hit    => 1,
                completed_at => DateTime->now(),
                prog         => $0,
                pid          => $$,
                uid          => $<,
                note         => $ENV{DATA_DOWNLOADER_LOG_NOTE},
            }) if $ENV{DATA_DOWNLOADER_GATHER_STATS};
    my $stat = stat($destination);
    $self->size( $stat->size );
    $self->atime( DateTime->from_epoch(epoch => $stat->atime) );
    $self->db->do_transaction(
        sub {
            $self->save( changes_only => 1 ) or die $self->error;
        }
    ) or do {
        WARN "errors saving file : ".$self->db->error;
        return;
    };
    return $self if $args{skip_links};
    $self->makelinks or WARN "Failed to make symlinks for file";
    return $self;
}

=item decorate_tree

Put the links for a file within a single linktree.
A tree may contain multiple symlinks for a file if
there are metadata_transformations defined for this
repository which transform a set of metadata into mutltiple
sets of template parameters.

Parameters :

 tree -- A DD::Linktree object

=cut

sub decorate_tree {
    my $self = shift;
    my $args = validate( @_, { tree => 1 } );
    my $tree = $args->{tree};

    $tree->load unless $tree->repository && $tree->repository_obj;

    unless ($self->on_disk) {
	LOGWARN "not making broken symlinks for ".$self->filename;
	return;
    }
    # Start with a hash of template vars, but this may be transformed into multiple sets of
    # template vars using metadata_transformations.
    my @template_vars = ( +{ map { ( $_->name => $_->value ) } $self->metadata });
    for my $t ( sort { ($a->order_key || 0) <=> ($b->order_key || 0) }
        @{ $tree->repository_obj->metadata_transformations } ) {
        TRACE "Calling transformation ".$t->function_name." order is ".($t->order_key || 0);
        @template_vars = map $t->apply($_), @template_vars;
    }

    for my $template_vars (@template_vars) {
        if (my @missing = missing_values($tree->path_template,$template_vars)) {
            # This may happen if a file is downloaded without using the rss feed,
            # (i.e. we have no metadata).
            DEBUG "missing values for @missing, cannot make link for ".$self->filename;
            return;
        }
    }

    # Calculate the symlink paths
    my @linknames = uniq map {
        join '/', $tree->root, expand_string( $tree->path_template, $_ ),
          $self->filename
    } @template_vars;

    for my $linkname (@linknames) {
    }

    # Are there already links for this linktree + file?
    my $existing = Data::Downloader::Symlink::Manager->get_symlinks(
        query => [
            file => $self->id,
            linktree => $tree->id
        ]);
    if ($existing && @$existing) {
        for my $e (@$existing) {
            next if grep { $e->linkname eq $_ } @linknames;
            TRACE "removing old symlink in tree ".$tree->id.": ".$e->linkname;
            if (-e $e->linkname) {
                unlink $e->linkname or WARN "could not unlink ".$e->linkname;
            }
            $e->delete;
        }
    }

    # Make new links and insert them into the database.
  LINK:
    for my $linkname (@linknames) {

        if ($linkname =~ / /) {
	    ERROR "Encountered symlink containing a space : $linkname\n"
		. "Please define metadata transformations";
	    return;
        }

	# Link there already?
	my $link_exists = 0;
        if (-l $linkname) {
            my $target = readlink $linkname;
            if (-e $target && File::Spec->rel2abs( $target ) eq
                  File::Spec->rel2abs( $self->storage_path )) {
                # looks good, continue on
		TRACE "found existing symlink $linkname";
		$link_exists = 1;
            } elsif (! -e $target) {
                # broken link?
                DEBUG "removing broken symlink $linkname";
                unlink $linkname;
            } else {
                # link to some place else, clean it up with a message
                INFO "removing existing symlink $linkname";
                # unlink $target or LOGDIE "Error removing $target : $@"; # TODO preserve is something points to it
                unlink $linkname or do {
		    ERROR "Error removing $linkname : $@";
		    next LINK;
		};
            }
        }

	# Make link
	unless ($link_exists) {
	    DEBUG "Adding symlink $linkname";
	    -d dirname($linkname)
		or mkpath dirname($linkname)
		or do {
		    ERROR "couldn't make path for $linkname: $!";
		    next LINK;
		};
	    symlink $self->storage_path, $linkname 
		or do {
		    ERROR "couldn't make symlink ".$self->filename." to $linkname : $!";
		    next LINK;
		};
	}

        # Add symlink to the database?
        next if grep { $_->linkname eq $linkname } @$existing; # already there
	TRACE "Saving symlink $linkname";
        my $new_symlink = Data::Downloader::Symlink->new( file => $self->id, linkname => $linkname, linktree => $tree->id );
        $new_symlink->save or do {    # poor man's rollback
            unlink $linkname
              or WARN "Couldn't unlink $linkname : $!, please run fsck";
	    ERROR "Failed to save symlink : " . $self->error;
	    next LINK;
	};

    }
}

=item makelinks

Make all the symlinks for a file by iterating
through the linktrees and checking which satisfy
the condition for the tree.

=cut

sub makelinks {
    my $self = shift;

    unless ($self->on_disk) {
        WARN "File ".$self->filename." is not on disk, not making links; download it first";
        return;
    }
    TRACE "updating links for file ".$self->filename;

    # for each linktree, if this file matches that condition, create a symlink

    for my $tree ($self->repository_obj->linktrees) {
        # Does the file match this tree's condition?
        my %condition = defined($tree->condition) ? %{ eval $tree->condition } : ();
	if ($@) {
	    ERROR "error parsing condition '@{[ $tree->condition ]}' : $@";
	    return;
	}
        next unless @{ Data::Downloader::File::Manager->get_files(
                query        => [ %condition, id => $self->id ],
                with_objects => ["file_metadata"]) };

        TRACE "linking under ".$tree->root;
        $self->decorate_tree(tree => $tree);
    }
    return 1;
}

=item load_file

 loads the representation of a file in the database.

Arguments :

 filename -- filename to be pruned

Returns :
 reference to self on success

=cut

sub load_file {
    my $self = shift;
    my %args = @_;
    my $repository_obj;

    if (my $repository_name = $args{repository}) {
        INFO "downloading into repository $repository_name";
        $repository_obj = Data::Downloader::Repository->new(name => $args{repository});
        $repository_obj->load or LOGDIE $repository_obj->error;
    }

    my $loaded;
    unless (ref $self) { # make a new object
        my %constructor_args = %args;
        $constructor_args{repository} = $repository_obj->id if $repository_obj;
        delete $constructor_args{fake};
        LOGDIE "no support for urns in new files yet" if $constructor_args{urn};
        $self = __PACKAGE__->new(%constructor_args);
        my $loaded = $self->load(speculative => 1);
        DEBUG $loaded ? "Found file in db" : "File not yet in db";
    }

    # Compute the URL.
    defined($self->url) or $self->_store_url(%args); # may die
    DEBUG "downloading url is ".$self->url;

    my $request_time = DateTime->now();
    if ( $self->_already_downloaded ) {
        DEBUG "File has already been downloaded";
        $self->add_log_entries({
                requested_at => $request_time,
                cache_hit    => 1,
                completed_at => $request_time,
                prog         => $0,
                pid          => $$,
                uid          => $<,
                note         => $ENV{DATA_DOWNLOADER_LOG_NOTE},
            }) if $ENV{DATA_DOWNLOADER_GATHER_STATS};
        return $self;
    }
    return $self;
}

=item listlinks

List all the symlinks for a file

=cut

sub listlinks {
    my $self = shift;
    return unless($self->symlinks);
    for my $e (@{$self->symlinks}) {
		 print $e->linkname,"\n";
    }
  
}

=item remove

Remove this file from the disk, set "on_disk" to false
and remove any symlinks too.

=cut

sub remove {
    my $self = shift;
    my $args = validate( @_, { purge => 0 } );
    my $tries = 0;
    my $success;
    my $errors;

    # For SQLite:
    # Force an exclusive transaction.  This is necessary when doing WAL
    # journaling.  Without this, the first statement, which is a select
    # on symlinks will force a SHARED lock.  When it then tries to DELETE
    # the symlinks it will not be able to upgrade to an EXCLUSIVE lock
    # if another process already has an EXCLUSIVE lock, so it will fail
    # without doing the busy timeout.
    local $self->db->dbh->{sqlite_use_immediate_transaction} = 1;

    while (!$success && $tries++ < 10) {
        $success = $self->db->do_transaction(sub {
            if ($self->on_disk) {
                for my $symlink ($self->symlinks) {
                    DEBUG "removing symlink ".$symlink->linkname;
                    -l $symlink->linkname and do {
                        unlink $symlink->linkname
			    or WARNDIE "failed to remove symlink ".$symlink->linkname." : $!";
                    };
                    $symlink->delete
			or WARNDIE "failed to remove symlink from db : ".$symlink->error;
                }
                -e $self->storage_path and do {
                    unlink $self->storage_path
			or WARNDIE "failed to unlink ".$self->storage_path." : $!";
                };
            }
            if ($args->{purge}) {
                DEBUG "purging file ".$self->id;
                $self->delete(cascade => 1)
		    or WARNDIE "failed to purge file: ".$self->error;
            } else {
                DEBUG "removing file ".$self->id;
                $self->on_disk(0);
                $self->disk(undef);
                $self->disk_obj(undef);
                $self->save(changes_only => 1) 
		    or WARNDIE "failed to save changes ".$self->error;
            }
        });
        if (!$success) {
            $errors = $self->db->error;
            TRACE "remove file failed : $errors, attempt number $tries/10";
        }
        sleep $tries if $tries > 1;
    }
    if (!$success) {
	ERROR "failed to remove file ".$self->id." : $errors";
	return;
    }
    return 1;
}

=item purge

Remove this file and any information stored about it.

=cut

sub purge {
    my $self = shift;
    $self->remove(purge => 1);
}

=item check

Check a file and its symlinks and ensure that the database
information represents what is stored on disk.

Arguments :

 checksum -- if true, also compute the checksum
 fix      -- if true, also attempt to fix anything broken

Returns :

 nothing, just produces warnings and errors

=cut

sub check {
    my $self = shift;
    my $args = validate(@_, { checksum => 0, fix => 0 });
    my $filename = $self->filename;
    my $id = $self->id;
    my $storage_path = $self->storage_path;
    my $ok = 1;
    TRACE "checking file $filename ($id)";
    TRACE $storage_path;
    if ($self->on_disk) {
        -e $storage_path or do {
            $ok = 0;
            WARN "$filename ($id) : not found";
            $self->on_disk(0) if $args->{fix};
        };
    } else {
        # not on_disk
        -e $storage_path and do {
            $ok = 0;
            WARN "$filename ($id) : file unexpectedly exists";
            $self->on_disk(1) if $args->{fix};
        };
    }
    for my $symlink ($self->symlinks) {
        my $link = "symlink (".$symlink->id.") ".$symlink->linkname;
        TRACE "checking $link";
        -l $symlink->linkname or do {
            $ok = 0;
            WARN "$filename ($id) : $link not found";
            $symlink->delete if $args->{fix};
            next;
        };
        my $target = readlink $symlink->linkname;
        -e $target or do {
            WARN "$filename ($id) : $link is broken";
            $ok = 0;
            $symlink->delete if $args->{fix};
        };
        File::Spec->rel2abs($target) eq File::Spec->rel2abs($storage_path)
          or do {
          $ok = 0;
          WARN "$filename ($id) : $link does not point to target";
          $symlink->delete if $args->{fix};
        };
    }
    $self->makelinks if $args->{fix} && $self->on_disk;

    $self->save;
    return $ok unless $args->{checksum};
    TRACE "computing checksum";
    $self->_check_hash or ERROR "$filename ($id) : md5 sum in db does not match computed md5";
}

=item prune_links

Remove all the symlinks for a file matching a particular
regular expression.

Arguments :

 regex -- a regex to match against.

Returns :

 false if a link could not be removed
 true if all links matching regex could be removed.

=cut

sub prune_links {
    my $self  = shift;
    my $regex = shift;
    for my $s ( @{ $self->symlinks } ) {
        if ( $s->linkname =~ /$regex/ ) {
            if ( unlink $s->linkname ) {
                $s->delete() or return undef;
            } else {
                WARN "Failed to remove ".$s->linkname." : $!";
            }
        }
    }
    return 1;
}

=item load_from_urn

Load this object using the urn stored for it.

=cut

sub load_from_urn {
    my $self = $_[0]; # don't shift see Rose::DB::Object
    return unless $self->urn;
    my $key;
    for ( $self->meta->unique_keys ) {
        my @columns = $_->columns;
        $key = $_->name if @columns==1 and $columns[0] eq 'urn';
    }
    unless (defined($key)) {
        TRACE "Adding unique key for urn";
        # Rose::DB::SQLite doesn't parse "create index" statements
        $self->meta->add_unique_key('urn');
        my ($new) = grep { @{ $_->columns }==1 && $_->columns->[0] eq 'urn' } $self->meta->unique_keys;
        $key = $new->name;
    }
    shift->load(use_key => $key, @_ );
}

=item list

List the names of files matching the given criteria.

The list is printed to STDOUT.

Arguments:

 filename -- show the file name in the list? (default: True)
 md5      -- show the file MD5 in the list? (default: False)
 id       -- show the file ID in the list? (default: False)
 url      -- show the file URL in the list? (default: False)
 urn      -- show the file URN in the list? (default: False)
 size     -- show the file size in the list? (default: False)
 on_disk  -- show the file status in the list? (default: False)
 disk     -- show the file location in the list? (default: False)
 atime    -- show the file ingest time in the list? (default: False)

Returns :

 nothing

=cut

sub list {
    my $self = shift;
    my %spec = map {
	$_ => ($_ eq 'filename') ? { default => 1 } : { default => 0 }
    } $self->meta->columns;
    my %args = validate(@_, \%spec);
    my @fields;
    if (exists $args{filename} && $args{filename}) {
	delete $args{filename};
	push(@fields, $self->filename);
    }
    push(@fields,
	 map { my $value = $self->$_;
	       $value = $value->iso8601 if (ref($value) eq 'DateTime');
	       $args{$_} ? $value : ();
	     } keys(%args)
	 );
    unless (@fields) { @fields = ($self->filename); }
    print join('  ', @fields), "\n";
}

=back

=head2 SEE ALSO

L<Rose::DB::Object>

L<Data::Downloader/SCHEMA>

=cut

1;


package SVN::Dump::Replayer;
BEGIN {
  $SVN::Dump::Replayer::VERSION = '1.000';
}

# Replay a Subversion dump.  Must be subclassed with something classy.

use Moose;
extends qw(SVN::Dump::Walker);

use File::Copy;
use File::Path;
use Cwd;
use Carp qw(confess);
use Digest::MD5 qw(md5_hex);

use SVN::Dump::Arborist;

has verbose => ( is => 'ro', isa => 'Bool', default => 0 );

# Replays go somewhere.  Optional because we might replay somewhere
# dissociated from a filesystem.
has replay_base => (
	is        => 'ro',
	isa       => 'Str',
);

has copy_source_depot => (
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);

has directory_stack => (
	is      => 'rw',
	isa     => 'ArrayRef[Str]',
	default => sub { [] },
);

has include_regexp => (
	is	=> 'ro',
	isa	=> 'Maybe[RegexpRef]',
);

has db_file_name => ( is => 'rw', isa => 'Str' );

has arborist => (
	is => 'ro',
	isa => 'SVN::Dump::Arborist',
	lazy  => 1,
	default => sub {
		my $self = shift;
		return SVN::Dump::Arborist->new(
			verbose           => $self->verbose(),
			db_file_name      => $self->db_file_name(),
			svn_dump_filename => $self->svn_dump_filename(),
		);
	},
);

#######################
### Low-level tracking.

sub on_walk_begin {
	my $self = shift;

	# Initialize the copy source depot.
	$self->do_rmdir($self->copy_source_depot()) if -e $self->copy_source_depot();
	$self->do_mkdir($self->copy_source_depot());
}

sub on_revision_done {
	my ($self, $revision_id) = @_;

	# Finalize the revision object, and return it.
	my $revision = $self->arborist()->finalize_revision();

	# Apply all the changes it represents.
	CHANGE: foreach my $change (@{$revision->changes()}) {
		my $operation    = $change->operation();
		my $dst_analysis = $change->analysis();

		$self->log("REP) doing: $operation ", $change->path());
		$self->log(
			"REP) entity: ", $dst_analysis->ent_type(),
			" ", $dst_analysis->ent_name()
		);
		$self->log(
			"REP) status: ", ($dst_analysis->is_entity() ? "is" : "is not"),
			" entity"
		);

		# Change is an entity.  Perhaps something is tagged or branched?
		if ($change->is_entity()) {
			my $entity_type = $dst_analysis->ent_type();

			if ($entity_type eq "branch") {
				$operation = "branch_$operation";
			}
			elsif ($entity_type eq "tag") {
				$operation = "tag_$operation";
			}
			elsif ($entity_type eq "meta") {
				# TODO - Do nothing?
			}
			else {
				confess "unexpected entity type: $entity_type";
			}
		}

		# Change to a non-container is easy.
		my $method = "on_$operation";
		$self->log("REP) calling method $method");
		$self->$method($change, $revision);
	}
}

sub on_revision {
	my ($self, $revision, $author, $date, $log_message) = @_;

	$self->log("r$revision by $author at $date");

	$log_message = "(none)" unless (
		defined($log_message) and length($log_message)
	);
	chomp $log_message;

	$self->arborist()->start_revision($revision, $author, $date, $log_message);

	undef;
}

sub on_node_add {
	my ($self, $revision, $path, $kind, $data) = @_;
	$self->arborist()->add_new_node($revision, $path, $kind, $data);
	undef;
}

sub on_node_change {
	my ($self, $revision, $path, $kind, $data) = @_;
	$self->arborist()->touch_node($revision, $path, $kind, $data);
}

# According to the Red Bean Subersion book, "replacement" happens when
# a node is scheduled for deletion and addition in the same commit.
# As of svn 1.6.6 I'm not sure how to do this for a directory.  Maybe
# older versions permitted it?
# TODO - We may need a special "replace" operation if having deletion
# and addition in the same revision is confusing.
sub on_node_replace {
	my ($self, $revision, $path, $kind, $data) = @_;
	$self->on_node_delete($revision, $path);
	goto &on_node_add;
}

sub on_node_delete {
	my ($self, $revision, $path) = @_;

	$self->arborist()->delete_node($path, $revision);

	# TODO - Push the deletion onto the branch?

	undef;
}

sub on_node_copy {
	my ($self, $revision, $path, $kind, $from_rev, $from_path, $data) = @_;

	# TODO - Complex.  See walk-svn.pl for starters.
	$self->arborist()->copy_node(
		$from_rev, $from_path, $revision, $path, $kind, $data
	);

	undef;
}

### Helper methods.  TODO - Might belong in subclasses.

# Depot info is based on nonambiguous full path and revision.
sub get_copy_depot_info {
	my ($self, $change) = @_;
	return $self->calculate_depot_info($change->src_path(), $change->src_rev());
}

# Depot info is based on nonambiguous full path and revision.
sub calculate_depot_info {
	my ($self, $path, $revision) = @_;

	my $copy_depot_descriptor = "$path $revision";

	my $full_depot_path = (
		$self->copy_source_depot() . "/" .
		md5_hex($copy_depot_descriptor)
	);

	$full_depot_path =~ s!//+!/!g;

	return($copy_depot_descriptor, $full_depot_path);
}

### Action stuff.

sub do_or_die {
  my $self = shift;
	$self->log("RUN) @_");
  system @_ and confess "system(@_) = ", ($? >> 8);
  return;
}

sub pipe_into_or_die {
	my ($self, $data, $cmd) = @_;
	$self->log("PIN) $cmd");
	open my $fh, "|-", $cmd or confess $!;
	print $fh $data or confess $!;
	close $fh or confess $!;
	return;
}

sub pipe_out_of_or_die {
	my ($self, $cmd) = @_;
	$self->log("POU) $cmd");
	open my $fh, "-|", $cmd or confess $!;
	local $/;
	my $data = <$fh>;
	close $fh or confiess $!;
	return $data;
}

# Returns true if success.
sub do_sans_die {
  my $self = shift;
	$self->log("RUN) @_");
  return !(system @_);
}

sub do_mkdir {
	my ($self, $directory) = @_;
	$self->log("RUN) mkdir $directory");
	mkdir $directory or confess "mkdir $directory failed: $!";
	return;
}

sub do_rmdir {
	my ($self, $directory) = @_;
	$self->log("RUN) rmtree $directory");
	rmtree $directory or confess "rmtree $directory failed: $!";
	return;
}

sub push_dir {
  my ($self, $new_dir) = @_;

  push @{$self->directory_stack()}, cwd();
	$self->log("pushdir $new_dir");
  chdir($new_dir) or confess "chdir $new_dir failed: $!";

  return;
}

sub pop_dir {
  my $self = shift;
  my $old_dir = pop @{$self->directory_stack()};
	$self->log("popdir $old_dir");
  chdir($old_dir) or confess "popdir failed: $!";
  return;
}

sub copy_file_or_die {
	my ($self, $src, $dst) = @_;
	$self->log("copy $src $dst");
	copy($src, $dst) or confess "cp $src $dst failed: $!";
}

sub log {
	my $self = shift;
	return unless $self->verbose();
	print time() - $^T, " ", join("", @_), "\n";
}

sub rewrite_file {
	my ($self, $change, $full_path) = @_;

	confess "edit $full_path failed: file doesn't exist" unless -e $full_path;
	confess "edit $full_path failed: path is not a file" unless -f $full_path;

  # File may not actually be changing.  The subversion change may only
  # be to properties, which we don't care about here.  Only bother
	# checking if the file sizes are equal; saves a lot of I/O that way.

	if ((-s $full_path) == do { use bytes; length($change->content()) }) {
    open my $fh, "<", $full_path or confess $!;
    local $/;
    my $current_text = <$fh>;
    if ($current_text eq $change->content()) {
			$self->log("skipping rewrite - file didn't change");
			return;
    }
  }

	$self->log("changing file $full_path");
	$self->write_change_data($change, $full_path);

	return 1;
}

sub write_new_file {
	my ($self, $change, $full_path) = @_;

	confess "create $full_path failed: file already exists" if -e $full_path;

	$self->log("creating file $full_path");

	$self->write_change_data($change, $full_path);
}

sub write_change_data {
	my ($self, $change, $full_path) = @_;
	open my $fh, ">", $full_path or confess "create $full_path failed: $!";
	if (defined $change->content()) {
		print $fh $change->content() or confess $!;
	}
	close $fh or confess $!;
}

sub do_file_deletion {
	my ($self, $full_path) = @_;

	confess "delete $full_path failed: file doesn't exist" unless -e $full_path;
	confess "delete $full_path failed: path not to a file" unless -f $full_path;

	$self->log("RUN) rm $full_path");

	unlink $full_path or confess "unlink $full_path failed: $!";
}

sub do_rmdir_safely {
	my ($self, $full_path) = @_;
	confess "rmtree $full_path failed: directory doesn't exist" unless (
		-e $full_path
	);
	confess "rmtree $full_path failed: path not to a directory" unless (
		-d $full_path
	);
	$self->do_rmdir($full_path);
}

sub do_rename {
	my ($self, $change) = @_;

	my $full_src_path = $self->calculate_path($change->src_path());
	my $full_dst_path = $self->calculate_path($change->path());

	rename $full_src_path, $full_dst_path or confess(
		"rename $full_src_path $full_dst_path failed: $!"
	);
}

sub decrement_copy_source {
	my ($self, $change, $revision, $copy_depot_path) = @_;
return;
	my $copy_source = $self->arborist()->get_copy_source_for_path(
		$change->src_rev(),
		$change->src_path(),
	);

	confess "what's going on" unless defined $copy_source;

	$self->do_file_deletion($copy_depot_path) unless (
		$copy_source->delete_ref($revision->id(), $change->path())
	);
}

### Virtual methods to override.

sub on_branch_directory_copy { confess "must override method"; }
sub on_branch_directory_creation { confess "must override method"; }
sub on_branch_directory_deletion { confess "must override method"; }
sub on_branch_rename { confess "must override method"; }

sub on_directory_copy { confess "must override method"; }
sub on_directory_creation { confess "must override method"; }
sub on_directory_deletion { confess "must override method"; }
sub on_directory_rename { confess "must override method"; }

sub on_file_change { confess "must override method"; }
sub on_file_copy { confess "must override method"; }
sub on_file_creation { confess "must override method"; }
sub on_file_deletion { confess "must override method"; }
sub on_file_rename { confess "must override method"; }

sub on_tag_directory_copy { confess "must override method"; }
sub on_tag_directory_deletion { confess "must override method"; }
sub on_tag_rename { confess "must override method"; }

sub on_rename { confess "must override method"; }

1;

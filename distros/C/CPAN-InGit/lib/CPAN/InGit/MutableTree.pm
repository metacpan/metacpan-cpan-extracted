package CPAN::InGit::MutableTree;
# ABSTRACT: Utility object that represents a Git Tree and pending changes
our $VERSION = '0.007'; # VERSION


use Carp;
use Moo;
use Git::Raw::Index;
use Scalar::Util 'blessed';
use v5.36;


has parent            => ( is => 'ro', required => 1 );
has tree              => ( is => 'rw' );
has branch            => ( is => 'rw' );
has _changes          => ( is => 'rw' );
has has_changes       => ( is => 'rw' );
has use_workdir       => ( is => 'rw' );
sub git_repo             { shift->parent->git_repo }

sub BUILD($self, $args, @) {
   # branch supplied by name? look it up
   if (defined $self->{branch} && !ref $self->{branch}) {
      my $b= Git::Raw::Branch->lookup($self->git_repo, $self->{branch}, 1)
         or croak "No local branch named '$self->{branch}'";
      $self->{branch}= $b;
   }
   # If branch supplied and tree was not, look up the tree
   if ($self->{branch} && !$self->{tree}) {
      $self->{tree}= $self->{branch}->peel('tree');
   }
}


# Key of a node in the _changes tree marking a directory which replaces (rather than merges
# with) the directory of the same name in ->tree.  Git forbids NUL in names so it can't collide.
my $REPLACE= "\0replace";

sub get_path($self, $path) {
   $path =~ s{\A/+|/+\z}{}g;
   if (!length $path) {
      my $root= $self->_effective_tree;
      return $root? [ $root, 0040000 ] : undef;
   }
   if ($self->use_workdir) {
      my $index= $self->git_repo->index;
      my $ent= $index->find($path);
      return [ $ent->blob, $ent->mode ] if $ent;
      # Not a file in the index, but it could be a directory.
      my $root= $self->_effective_tree or return undef;
      my $dirent= $root->entry_bypath($path) or return undef;
      return $dirent->file_mode == 0040000? [ $dirent->object, 0040000 ] : undef;
   }
   my $base= $self->tree;
   if ($self->_changes && keys $self->_changes->%*) {
      my $node= $self->_changes;
      my @parts= split m{/+}, $path;
      while (@parts) {
         my $name= shift @parts;
         undef $base if $node->{$REPLACE};
         if (!exists $node->{$name}) {
            # No pending change at or beneath this name; the base tree (if any) has the answer
            unshift @parts, $name;
            last;
         }
         $node= $node->{$name};
         return undef unless defined $node; # pending deletion
         if (ref $node eq 'ARRAY') {
            return $node unless @parts;
            # pending change is a whole Git tree; continue the lookup inside of it
            return undef unless $node->[0]->is_tree;
            my $dirent= $node->[0]->entry_bypath(join '/', @parts) or return undef;
            return [ $dirent->object, $dirent->file_mode ];
         }
         # else a directory of pending changes.  Step the base tree into the same directory.
         if ($base) {
            my $dirent= $base->entry_bypath($name);
            $base= $dirent && $dirent->file_mode == 0040000? $dirent->object : undef;
         }
         return [ _assemble_tree($self->git_repo, ($node->{$REPLACE}? undef : $base), $node), 0040000 ]
            unless @parts;
      }
      $path= join '/', @parts;
   }
   if ($base) {
      my $dirent= $base->entry_bypath($path)
         or return undef;
      return [ $dirent->object, $dirent->file_mode ];
   }
   return undef;
}

# The tree as it would be written by update_tree, without changing any attributes
sub _effective_tree($self) {
   return scalar eval { $self->git_repo->index->write_tree }
      if $self->use_workdir;
   return _assemble_tree($self->git_repo, $self->tree, $self->_changes)
      if $self->_changes && keys $self->_changes->%*;
   return $self->tree;
}


sub list_dir($self, $path='') {
   my $ent= $self->get_path($path);
   return undef unless $ent && $ent->[0]->is_tree;
   return { map +($_->name => [ $_->object, $_->file_mode ]), $ent->[0]->entries };
}


sub set_path($self, $path, $data, %opts) {
   # Two modes: we can be writing to the working directory and index, or be building a new tree
   # (which may or may not be connected to a branch)
   my $repo= $self->git_repo;
   $path =~ s{\A/+|/+\z}{}g;
   my @path= split m{/+}, $path;
   my $basename= pop @path;
   defined $basename or croak "Can't set the root of the tree";
   my $is_dir= ref $data eq 'HASH' || (blessed($data) && $data->isa('Git::Raw::Tree'));
   my $mode= $is_dir? 0040000 : $opts{mode} // 0100644;
   # A directory is given as (or converted to) a flat list of  path => [ $content, $mode ]
   my $files= $is_dir? _flatten_dir($data) : undef;
   if ($self->use_workdir) {
      my $index= $repo->index;
      my $workdir= $repo->workdir =~ s{/\z}{}r;
      if (!defined $data || $is_dir) {
         # Remove a file of this name, or everything beneath a directory of this name
         for (grep $_ eq $path || index($_, "$path/") == 0, map $_->path, $index->entries) {
            unlink "$workdir/$_";
            $index->remove($_);
         }
         # git doesn't track directories, so clean up any that are now empty
         _rmdir_empty("$workdir/$path") if -d "$workdir/$path";
      }
      if ($is_dir) {
         _workdir_add($index, $workdir, "$path/$_", $files->{$_}->@*)
            for sort keys %$files;
      } elsif (defined $data) {
         _workdir_add($index, $workdir, $path, $data, $mode);
      }
      # Index mutations are in memory until written.  Persist them even when the
      # caller leaves committing to the user (as cpangit-add does on HEAD).
      $index->write;
   }
   else {
      my $node= ($self->{_changes} //= {});
      for (@path) {
         $node->{$_}= _explode_tree($node->{$_})
            if ref $node->{$_} eq 'ARRAY' && $node->{$_}[0]->is_tree;
         $node= ($node->{$_} //= {});
         ref $node eq 'HASH' or die "Can't set '$path'; '$_' is not a directory";
      }
      if ($is_dir) {
         my $dir= $node->{$basename}= { $REPLACE => 1 };
         for my $rel (keys %$files) {
            my ($content, $fmode)= $files->{$rel}->@*;
            my @rel= split m{/}, $rel;
            my $name= pop @rel;
            my $sub= $dir;
            $sub= ($sub->{$_} //= {}) for @rel;
            $content= Git::Raw::Blob->create($repo, $$content) if ref $content eq 'SCALAR';
            $sub->{$name}= [ $content, $fmode ];
         }
      } else {
         # Content may either be a Blob object or a scalar-ref of bytes
         $data= Git::Raw::Blob->create($repo, $$data) if ref $data eq 'SCALAR';
         $node->{$basename}= defined $data? [ $data, $mode ] : undef;
      }
   }
   $self->has_changes(1);
   $self->{_changes} //= {};
   $self;
}

# Convert a nested directory spec (see set_path) into a flat { $relative_path => [ $content, $mode ] }
# where content is a scalar ref or Blob.
sub _flatten_dir($data, $prefix='', $out={}) {
   if (blessed($data) && $data->isa('Git::Raw::Tree')) {
      for my $ent ($data->entries) {
         if ($ent->file_mode == 0040000) {
            _flatten_dir($ent->object, $prefix.$ent->name.'/', $out);
         } else {
            $out->{$prefix.$ent->name}= [ $ent->object, $ent->file_mode ];
         }
      }
      return $out;
   }
   for my $name (keys %$data) {
      my $val= $data->{$name};
      (my $rel= $prefix.$name) =~ s{/+}{/}g;
      croak "Invalid path '$rel' in directory"
         if $rel =~ m{\A/|/\z} || grep { $_ eq '.' || $_ eq '..' } split m{/}, $rel;
      if (ref $val eq 'HASH' || (blessed($val) && $val->isa('Git::Raw::Tree'))) {
         _flatten_dir($val, "$rel/", $out);
      } else {
         my ($content, $mode)= ref $val eq 'ARRAY'? @$val : ($val);
         ref $content eq 'SCALAR' || (blessed($content) && $content->isa('Git::Raw::Blob'))
            or croak "Content of '$rel' must be a scalar ref or Git::Raw::Blob";
         croak "Conflicting entries for '$rel'" if exists $out->{$rel};
         $out->{$rel}= [ $content, $mode // 0100644 ];
      }
   }
   # A file can't also be a directory
   for my $rel (keys %$out) {
      my $parent= $rel;
      while ($parent =~ s{/[^/]+\z}{}) {
         croak "Conflicting entries '$parent' and '$rel'" if exists $out->{$parent};
      }
   }
   return $out;
}

# Convert a pending [ $tree, $mode ] change into the equivalent hash of pending changes
sub _explode_tree($change) {
   return { $REPLACE => 1, map +($_->name => [ $_->object, $_->file_mode ]), $change->[0]->entries };
}

sub _workdir_add($index, $workdir, $path, $data, $mode) {
   my $fullpath= $workdir;
   my @path= split m{/}, $path;
   my $basename= pop @path;
   # create missing directories
   for (@path) {
      $fullpath .= '/'.$_;
      -d $fullpath or mkdir $fullpath or die "mkdir($fullpath): $!";
   }
   $fullpath .= '/'.$basename;
   # a shame there's no way to add the blob directly...
   $data= \$data->content if blessed($data) && $data->isa('Git::Raw::Blob');
   unlink $fullpath if -l $fullpath || $mode == 0120000;
   _mkfile($fullpath, $data, $mode);
   $index->add_frombuffer($path, $data, $mode);
}

sub _rmdir_empty($dir) {
   opendir my $dh, $dir or return;
   my @children= grep $_ ne '.' && $_ ne '..', readdir $dh;
   closedir $dh;
   -d "$dir/$_" && !-l "$dir/$_" && _rmdir_empty("$dir/$_") for @children;
   rmdir $dir;
}

sub _mkfile($path, $scalarref, $mode) {
   if ($mode == 0120000) {
      symlink $$scalarref, $path or die "symlink($path): $!";
      return;
   }
   open my $fh, '>:raw', $path or die "open($path): $!";
   $fh->print($$scalarref) or die "write($path): $!";
   $fh->close or die "close($path): $!";
   chmod($mode & 0777, $path) || die "chmod($path, $mode): $!"
      if defined $mode && $mode != 0100644;
}


sub check_new_paths($self, @paths) {
   my %existing;
   if ($self->use_workdir) {
      for my $entry ($self->git_repo->index->entries) {
         my $path= $entry->path;
         $existing{$path}= $entry->mode;
         $existing{$path} //= 0040000 while $path =~ s{/[^/]+\z}{};
      }
   }
   for my $path (@paths) {
      my $prefix= '';
      my @parts= split '/', $path;
      for my $part (@parts) {
         $prefix .= length($prefix)? "/$part" : $part;
         my $mode= $self->use_workdir? $existing{$prefix}
                  : (get_path($self, $prefix) // [])->[1];
         if ($self->use_workdir) {
            my $fullpath= $self->git_repo->workdir.'/'.$prefix;
            my @st= lstat $fullpath;
            croak "Cannot add $path; $prefix already exists in the working directory"
               if @st && ($prefix eq $path || ($st[2] & 0170000) != 0040000);
         }
         croak "Cannot add $path; $prefix already exists"
            if defined $mode && ($prefix eq $path || $mode != 0040000);
      }
   }
}


my %_diff_file_mode= ( blob => 0100644, blob_executable => 0100755, link => 0120000, commit => 0160000, tree => 0040000 );
sub diff($self, $other, %opts) {
   my $repo= $opts{repo} // $self->git_repo;
   my ($old, $new)= map {
      my $t= blessed($_) && $_->can('_effective_tree')? $_->_effective_tree : $_;
      # Look up both trees via the same repo, so that it works for trees coming from
      # repositories that are linked as 'alternates'.
      $t? Git::Raw::Tree->lookup($repo, ref $t? $t->id : $t) // croak "Tree ".(ref $t? $t->id : $t)." not found in repo"
        : Git::Raw::Tree::Builder->new($repo)->write;
   } $self, $other;
   my $diff= $old->diff({
      tree => $new,
      context_lines => $opts{context_lines} // 3,
      ($opts{paths} && @{$opts{paths}}? ( paths => [ @{$opts{paths}} ] ) : ()),
   });
   $diff->find_similar({ flags => { renames => 1 } }) if $opts{renames} // 1;
   my @deltas;
   for my $patch ($diff->patches) {
      my $delta= $patch->delta;
      my ($old_file, $new_file)= ($delta->old_file, $delta->new_file);
      my $status= $delta->status;
      my $stats= $patch->line_stats;
      my %d= (
         path      => $status eq 'deleted'? $old_file->path : $new_file->path,
         status    => $status,
         old_id    => $status eq 'added'?   undef : $old_file->id,
         new_id    => $status eq 'deleted'? undef : $new_file->id,
         old_mode  => $status eq 'added'?   undef : $_diff_file_mode{$old_file->mode},
         new_mode  => $status eq 'deleted'? undef : $_diff_file_mode{$new_file->mode},
         additions => $stats->{additions},
         deletions => $stats->{deletions},
         binary    => (grep($_ eq 'binary', @{ $delta->flags // [] })? 1 : 0),
      );
      $d{old_path}= $old_file->path if $status eq 'renamed' || $status eq 'copied';
      $d{patch}= $patch->buffer if $opts{patch};
      push @deltas, \%d;
   }
   return \@deltas;
}


sub update_tree($self) {
   # If using the Index, the index can write the new tree
   if ($self->use_workdir) {
      $self->tree($self->git_repo->index->write_tree);
   } else {
      $self->tree(_assemble_tree($self->git_repo, $self->tree, $self->_changes));
      $self->_changes({}); # reset the changes hash
   }
   # don't reset has_changes until it has been committed
}

# merge a hashref of changes into the previous Tree, and return the new Tree
# Changes look like:
#  {
#     "removed"  => undef,
#     "dirname"  => [ $tree, 0040000 ],
#     "replaced" => { "\0replace" => 1, ... },  # ignores this directory of the previous Tree
#     "path1" => {
#        "filename" => [ $blob, $mode ],
#        "fname2"   => [ $blob, $mode ],
#     }
#  }
sub _assemble_tree($repo, $tree, $changes) {
   undef $tree if $changes->{$REPLACE};
   my $treebuilder= Git::Raw::Tree::Builder->new($repo, ($tree? ($tree) : ()));
   for my $name (keys %$changes) {
      next if $name eq $REPLACE;
      my $ent= $changes->{$name};
      if (!defined $ent) {
         # removing a name that doesn't exist is an error for the builder
         $treebuilder->remove($name) if $treebuilder->get($name);
      }
      else {
         if (ref $ent eq 'HASH') { # a subdirectory
            my $dirent= $treebuilder->get($name);
            my $subdir= $dirent && $dirent->type == Git::Raw::Object::TREE()
               ? Git::Raw::Tree->lookup($repo, $dirent->id) : undef;
            $ent= [ _assemble_tree($repo, $subdir, $ent), 0040000 ];
         }
         $treebuilder->insert($name, @$ent);
      }
   }
   return $treebuilder->write; # returns Git::Raw::Tree
}


sub commit($self, $message, %opts) {
   croak "No changes added" unless $self->has_changes;
   my $repo= $self->git_repo;
   $self->update_tree;
   my $branch= $self->branch;
   my $cur_sig= $self->parent->new_signature;
   my $author= $opts{author} // $cur_sig;
   my $update_head= $self->use_workdir // $opts{update_head};
   my $committer= $opts{committer} // $cur_sig;
   my $parents= $self->use_workdir? (
                  # dies on new repo if HEAD doesn't exist yet, in which case no parents
                  eval { [ $self->git_repo->head->target ] } || []
                )
              : $branch? [ $self->branch->peel('commit') ]
              : length $opts{create_branch}? [] # fresh branch, no parent commit
              : croak "Can't commit without a branch or use_workdir or option create_branch";
   # undef final param means don't update HEAD
   my $commit= Git::Raw::Commit->create($repo, $message, $author, $committer, $parents, $self->tree, undef)
      or croak "commit failed";
   if ($opts{create_branch}) {
      $branch= $repo->branch($opts{create_branch}, $commit);
      $self->branch($branch);
   } elsif ($branch) {
      # Update the branch
      $branch->target($commit);
   }
   $repo->head($branch) if $branch && $update_head;
   # persist the index state to disk, which clears the staged changes and brings the index
   #  in sync with the commit
   $repo->index->write if $self->use_workdir;
   $self->has_changes(0);
   return $commit;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::InGit::MutableTree - Utility object that represents a Git Tree and pending changes

=head1 SYNOPSIS

  my $t= CPAN::InGit::MutableTree->new(
    parent   => $cpan_repo,
    tree     => $git_tree_obj,
    branch   => $name,
  );
  
  $t->set_path('path/to/file',  \$file_data);
  $t->set_path('path/to/file2', \$file_data);
  $t->set_path('other/path' => \$path, ( symlink => 1 ));
  $t->commit("Message");

=head1 DESCRIPTION

This object wraps a L<Git::Raw::Tree>, optionally tied to a L<Git::Raw::Branch>.
It can store changes to the tree which have not been committed yet, but which
are seen when querying the paths of the tree.  The changes can be serialized in
e.g. a web framework's session, and then you can commit them when ready.

If C<use_workdir> is set, this will instead write changes to the working
directory and add them to the Git index, where the user can commit them.

=head1 ATTRIBUTES

=head2 parent

An instance of L<CPAN::InGit>

=head2 tree

An instance of L<Git::Raw::Tree> which is the starting state for this MutableTree instance.
This attribute gets updated to point to the new tree by calls to L</update_tree> or L</commit>.

=head2 branch

An instance of L<Git::Raw::Branch>, which may be coerced from a branch name to the constructor.
This may be C<undef> if the tree is not the head of any branch.

=head2 has_changes

True if any L</set_path> calls caused a change that needs written back to the tree, and hasn't
been written yet.

=head2 use_workdir

True if changes written to this MutableTree should use the Git index (working directory) instead
of directly updating the branch in Git's storage.

=head2 git_repo

Convenient accessor for C<< ->parent->git_repo >>.

=head1 METHODS

=head2 get_path

  my ($git_obj, $mode)= @{ $tree->get_path($path) };

Return the Git object and mode at C<$path>, or C<undef> if nothing exists there.  The result
reflects pending L</set_path> changes (or the Git index, with L</use_workdir>).  Directories
are returned as a L<Git::Raw::Tree> with mode C<0040000>.  The empty path refers to the root.

=head2 list_dir

  my $entries= $tree->list_dir($path);
  # { $name => [ $git_obj, $mode ], ... }

Return the entries of the directory at C<$path> (default: the root) in the same form as
L</get_path>, or C<undef> if C<$path> is not a directory.

=head2 set_path

  $tree->set_path('path/within/repo', undef); # remove file or directory
  $tree->set_path('path/within/repo', \$bytes, %opts);
  $tree->set_path('path/within/repo', $blob, %opts);
  $tree->set_path('path/within/repo', \%directory);
  $tree->set_path('path/within/repo', $git_tree);

Add, replace, or remove the file or directory at a path within the tree.

File content can be a scalar-ref of bytes or a L<Git::Raw::Blob>.  The only option is C<mode>,
which defaults to C<0100644>.  Use C<0100755> for executables and C<0120000> for a symlink
(whose content is the link target).

A hashref or L<Git::Raw::Tree> creates a directory, B<replacing> any directory already at
that path.  Each key of the hashref is a relative name (which may contain C</> to reach into
subdirectories) and each value is file content as above, C<< [ $content, $mode ] >>, or
another hashref or Tree for a subdirectory.

=head2 check_new_paths

  $tree->check_new_paths(@repo_paths);

Check that paths can be added without replacing existing entries. Directories used
as parents must be real directories. Checks the index and working directory when
using the checked-out branch.

=head2 diff

  my $deltas= $tree->diff($other_tree, %options);
  # [
  #   { path => 'lib/Foo.pm', status => 'modified',
  #     old_id => $blob_id, new_id => $blob_id, old_mode => 0100644, new_mode => 0100644,
  #     additions => 3, deletions => 1, binary => 0, patch => "diff --git ...",
  #   },
  #   ...
  # ]

Compare this tree (including pending changes) to another MutableTree or L<Git::Raw::Tree>,
describing what it takes to get from this tree to C<$other_tree>.  C<undef> means an empty
tree.  Each delta has a C<status> of C<added>, C<deleted>, C<modified>, C<renamed>, or
C<type_change>.  Renames also have an C<old_path>.  The id and mode of a side where the file
does not exist are C<undef>.

Options:

=over

=item paths

Arrayref of paths (or git pathspecs) to limit the comparison

=item patch

Boolean, whether to include the unified diff text of each file as C<patch>

=item context_lines

Number of unchanged lines around each change in C<patch> (default 3)

=item renames

Boolean, whether to detect renamed files (default true)

=item repo

A L<Git::Raw::Repository> able to read the objects of both trees.  Defaults to L</git_repo>.

=back

=head2 update_tree

  $tree->update_tree;

Store any pending changes from L</set_path> into Git object storage and update the L</tree>
attribute to point to the new Git::Raw::Tree.  This does not commit the tree to a branch.

=head2 commit

  $commit= $tree->commit($message, %options);

  # Options:
  #   author        => Git::Raw::Signature
  #   committer     => Git::Raw::Signature,
  #   create_branch => $branch_name

Commit any pending changes from L</set_path> and write a commit message for the change.
IN order to make a commit, you must either be on a L</branch>, using the HEAD in the working
directory, or specify the C<'create_branch'> option.

If this tree is using the working directory, it updates the index and HEAD as if a user had
run 'git commit' in the working directory.

If you specify 'create_branch', it creates a new branch and updates the L</branch> attribute to
refer to it.

=head1 VERSION

version 0.007

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad, and IntelliTree Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

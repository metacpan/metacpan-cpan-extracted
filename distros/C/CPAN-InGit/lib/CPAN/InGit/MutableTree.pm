package CPAN::InGit::MutableTree;
# ABSTRACT: Utility object that represents a Git Tree and pending changes
our $VERSION = '0.001'; # VERSION


use Carp;
use Moo;
use Git::Raw::Index;
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


sub get_path($self, $path) {
   if ($self->has_changes) {
      if (keys $self->_changes->%*) {
         my $node= $self->_changes;
         my @path= split '/', $path;
         my $basename= pop @path;
         for (@path) {
            $node= $node->{$_} if defined $node;
         }
         return $node->{$basename} if ref $node eq 'HASH' && $node->{$basename};
      }
      if ($self->use_workdir) {
         my $ent= $self->git_repo->index->find($path);
         return [ $ent->blob, $ent->mode ]
            if $ent;
      }
   }
   if ($self->tree) {
      my $dirent= $self->tree->entry_bypath($path)
         or return undef;
      return [ $dirent->object, $dirent->file_mode ];
   }      
   return undef;
}


sub set_path($self, $path, $data, %opts) {
   # Two modes: we can be writing to the working directory and index, or be building a new tree
   # (which may or may not be connected to a branch)
   my $repo= $self->git_repo;
   my $mode= $opts{mode} // 0100644;
   my @path= split m{/+}, $path;
   my $basename= pop @path;
   if ($self->use_workdir) {
      my $fullpath= $self->git_repo->workdir;
      # create missing directories
      for (@path) {
         $fullpath .= '/'.$_;
         mkdir $fullpath || die "mkdir($fullpath): $!"
            unless -d $fullpath;
      }
      $fullpath .= '/'.$basename;
      if (!defined $data) {
         unlink($fullpath);
         $self->git_repo->index->remove($path);
      } else {
         # a shame there's no way to add the blob directly...
         $data= \$data->content if ref($data)->isa('Git::Raw::Blob');
         # Write file
         _mkfile($fullpath, $data, $mode);
         # Add to the index
         $self->git_repo->index->add_frombuffer($path, $data, $mode);
      }
   }
   else {
      my $node= ($self->{_changes} //= {});
      for (@path) {
         $node= ($node->{$_} //= {});
         ref $node eq 'HASH' or die "Can't set '$path'; '$_' is not a directory";
      }
      # Content may either be a Blob object or a scalar-ref of bytes
      if (ref $data eq 'SCALAR') {
         $data= Git::Raw::Blob->create($repo, $$data);
      }
      $node->{$basename}= defined $data? [ $data, $mode ] : undef;
   }
   $self->has_changes(1);
   $self->{_changes} //= {};
   $self;
}

sub _mkfile($path, $scalarref, $mode) {
   open my $fh, '>', $path or die "open($path): $!";
   $fh->print($$scalarref) or die "write($path): $!";
   $fh->close or die "close($path): $!";
   chmod($path, $mode) || die "chmod($path, $mode): $!"
      if defined $mode && $mode != 0100644;
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
#     "path1" => {
#        "filename" => [ $blob, $mode ],
#        "fname2"   => [ $blob, $mode ],
#     }
#  }
sub _assemble_tree($repo, $tree, $changes) {
   my $treebuilder= Git::Raw::Tree::Builder->new($repo, ($tree? ($tree) : ()));
   for my $name (keys %$changes) {
      my $ent= $changes->{$name};
      if (!defined $ent) {
         $treebuilder->remove($name);
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

If C<workdir_path> is set, this will instead write changes to the working
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

=head2 set_path

  $tree->set_path('path/within/repo', undef); # remove file
  $tree->set_path('path/within/repo', \$bytes, %opts);
  $tree->set_path('path/within/repo', $blob, %opts);

Add (or remove) a blob at a path within the tree.

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

version 0.001

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad, and IntelliTree Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package CPAN::InGit;

our $VERSION = '0.001'; # VERSION
# ABSTRACT: Manage custom CPAN trees to pin versions for your projects

use Git::Raw::Repository;
use Archive::Tar;
use Archive::Tar::Constant; # for constants to be avilable at compile time
use Scalar::Util 'blessed';
use CPAN::InGit::MirrorTree;
use CPAN::Meta 2.150010;
use Module::Metadata;
use Fcntl qw( S_ISREG S_ISLNK S_IFMT S_ISDIR );
use Carp;
use Moo;
use v5.36;


sub BUILDARGS($class, @list) {
   unshift @list, 'git_repo' if @list == 1;
   my $args= $class->next::method(@list);
   $args->{git_repo}= delete $args->{repo} if defined $args->{repo};
   $args;
}

has git_repo                  => ( is => 'ro', required => 1, coerce => \&_open_repo );
has git_author_name           => ( is => 'rw', default => 'CPAN::InGit' );
has git_author_email          => ( is => 'rw', default => 'CPAN::InGit@localhost' );

has workdir_branch_name       => ( is => 'lazy' );
sub _build_workdir_branch_name($self) {
   return undef if $self->git_repo->is_bare || $self->git_repo->is_head_detached;
   return $self->git_repo->head->shorthand;
}

has useragent                 => ( is => 'lazy' );
sub _build_useragent($self) {
   require Mojo::UserAgent;
   return Mojo::UserAgent->new;
}

sub _open_repo($thing) {
   return $thing if blessed($thing) && $thing->isa('Git::Raw::Repository');
   return Git::Raw::Repository->open("$thing");
}


sub get_archive_tree($self, $branch_or_tag_or_id) {
   my ($tree, $origin)= $self->lookup_tree($branch_or_tag_or_id);
   return undef unless $tree;

   my $branch= $origin && ref($origin)->isa('Git::Raw::Branch')? $origin : undef;

   # If HEAD requested or using the branch pointed to by HEAD, and if it has a work directory,
   # then apply any changes to the workdir.
   my $use_workdir= !$self->git_repo->is_bare && (($branch && $branch->is_head) || $branch_or_tag_or_id eq 'HEAD');

   # Does it look like an ArchiveTree?
   my $config_blob;
   if ($use_workdir) {
      my $ent= $self->git_repo->index->find('cpan_ingit.json');
      return undef unless $ent;
      $config_blob= $ent->blob;
   } else {
      my $ent= $tree->entry_bypath('cpan_ingit.json');
      return undef unless $ent;
      $config_blob= $ent->object;
   }
   my $cfg= JSON::PP->new->relaxed->decode($config_blob->content);
   my $class= $cfg->{upstream_url}? 'CPAN::InGit::MirrorTree' : 'CPAN::InGit::ArchiveTree';
   return $class->new(
      parent => $self,
      tree => $tree,
      use_workdir => $use_workdir,
      (branch => $branch)x!!$branch,
   );
}


sub create_archive_tree($self, $name, %params) {
   croak "Branch '$name' already exists"
      if Git::Raw::Branch->lookup($self->git_repo, $name, 1);
   croak "Branch '$name' already exists upstream"
      if Git::Raw::Branch->lookup($self->git_repo, $name, 0);
   my $t;
   if ($params{upstream_url}) {
      $t= CPAN::InGit::MirrorTree->new(%params, parent => $self);
      $t->add_upstream_package_details;
   } else {
      $t= CPAN::InGit::ArchiveTree->new(%params, parent => $self);
      $t->write_package_details;
   }
   # It won't exist until we create a commit and create a branch.
   $t->write_config;
   $t->commit("Called create_archive_tree", create_branch => $name);
   return $t;
}


sub lookup_tree($self, $branch_or_tag_or_id) {
   my ($tree, $origin);
   defined $branch_or_tag_or_id or croak "missing argument";
   my $repo= $self->git_repo;
   if (blessed($branch_or_tag_or_id) && (
         $branch_or_tag_or_id->isa('Git::Raw::Branch')
      || $branch_or_tag_or_id->isa('Git::Raw::Tag')
   )) {
      $origin= $branch_or_tag_or_id;
      $tree= $origin->peel('tree');
   } elsif ($branch_or_tag_or_id eq 'HEAD') {
      $tree= $repo->head->target->peel('tree');
      $origin= $repo->is_head_detached? undef
             : $repo->head;
   } elsif ($origin= eval { Git::Raw::Branch->lookup($repo, $branch_or_tag_or_id, 1) }) {
      $tree= $origin->peel('tree');
   } elsif ($origin= eval { Git::Raw::Tag->lookup($repo, $branch_or_tag_or_id) }) {
      $tree= $origin->peel('tree');
   } elsif (my $obj= eval { $repo->lookup($branch_or_tag_or_id) }) {
      if ($obj->type == Git::Raw::Object::COMMIT()) {
         $origin= Git::Raw::Commit->lookup($repo, $obj->id);
         $tree= $origin->tree;
      } elsif ($obj->type == Git::Raw::Object::TREE()) {
         $tree= Git::Raw::Tree->lookup($repo, $obj->id);
      } elsif ($obj->type == Git::Raw::Object::TAG()) {
         $origin= Git::Raw::Tag->lookup($repo, $obj->id);
         $tree= $origin->target;
      }
   }
   return wantarray? ($tree, $origin) : $tree;
}


sub add_git_tree_to_tar($self, $tar, $path, $tree) {
   unless ($tree->can('entries')) {
      my $id= $tree;
      $tree = Git::Raw::Tree->lookup($self->repo, $id)
         or die "Can't find TREE $id referenced by '$path'";
   }
   $self->add_git_dirent_to_tar($tar, "$path/".$_->name, $_)
      for $tree->entries;
}

sub add_git_dirent_to_tar($self, $tar, $path, $dirent) {
   if ($dirent->type == Git::Raw::Object::BLOB()) {
      my $mode = $dirent->file_mode;
      my $blob = Git::Raw::Blob->lookup($self->repo, $dirent->id)
         or die "Can't find BLOB ".$dirent->id." referenced by '$path'";
      # Check if it's a symlink (mode 0120000 or 40960 decimal)
      if (($mode & 0170000) == 0120000) {
         # Symlink: content is the target path
         $tar->add_data($path, $blob->content, { 
            mode => $mode,
            type => Archive::Tar::Constant::SYMLINK,
            linkname => $blob->content
         });
      }
      else {
         # Regular file
         $tar->add_data($path, $blob->content, { mode => $mode });
      }
   }
   elsif ($dirent->type == Git::Raw::Object::TREE()) {
      $self->add_git_tree_to_tar($tar, $path, $dirent->id);
   }
   else {
      warn "Omitting $path from TAR, not a BLOB or TREE";
   }
}


sub new_signature($self) {
   Git::Raw::Signature->now($self->git_author_name, $self->git_author_email);
}


sub lookup_versions($self, $module_name) {
   for my $up ($self->upstream_mirrors->@*) {
      ...;
   }
}


sub process_distfile($self, %opts) {
   my ($tree, $file_path, $file_data, $extract)= @opts{'tree','file_path','file_data','extract'};
   # Decompress tar in memory.  The decompression gets complicated since it can be bz2 or gz
   # so write to a temp file and then parse that with the auto-detection of "compress".
   if ($file_path =~ /\.(tar\.gz|tar\.bz2|tgz)\z/) {
      my $path_without_extension= substr($file_path, 0, $-[0]);
      my $tmp= File::Temp->new;
      $tmp->print($$file_data) or die "write: $!";
      $tmp->flush;

      # Iterate across the files in the tar archive
      my $tar= Archive::Tar->new("$tmp", 1);
      my @files= $tar->get_files;
      if (!@files) {
         croak "Failed to extract any files from archive $file_path";
      }
      # Remove prefix directory if every file in archive starts with the same directory
      (my $prefix= $files[0]->name) =~ s,/.*,,;
      $prefix .= '/';
      for (@files) {
         if (substr($_->name,0,length $prefix) ne $prefix) {
            $prefix= '';
            last;
         }
      }
      # Build by-name hash of files
      my %files= map +( substr($_->name, length $prefix) => $_ ), @files;
      my $meta;
      # Look for a META.json
      if (my $meta_json= $files{'META.json'}) {
         eval {
            my $cm= CPAN::Meta->load_json_string($meta_json->get_content);
            $meta= $cm->as_struct({ version => 2 });
         } or warn "Failed to load $file_path/${prefix}META.json: $@";
      }
      # else look for META.yml
      if (!$meta && (my $meta_yml= $files{'META.yml'})) {
         eval {
            my $cm= CPAN::Meta->load_yaml_string($meta_yml->get_content);
            $meta= $cm->as_struct({ version => 2 });
         } or warn "Failed to load $file_path/${prefix}META.yml: $@";
      }
      # TODO: add some fall-back that guesses at prereqs.
      $meta //= {};
      # If the meta didn't contain "provides", add that using Module::Metadata
      if (!$meta->{provides}) {
         my $provides= $meta->{provides}= {};
         for my $pm_fname (grep /\.pm\z/ && !m{^(t|xt|inc|script|bin)/}, keys %files) {
            eval {
               open my $pm_fh, '<', $files{$pm_fname}->get_content_by_ref or die;
               my $mm= Module::Metadata->new_from_handle($pm_fh, $pm_fname);
               for my $pkg (grep $_ ne 'main', $mm->name, $mm->packages_inside) {
                  $provides->{$pkg}{file}= $pm_fname;
                  $provides->{$pkg}{version} //= $mm->version($pkg);
               }
               1;
            } or warn "Failed to parse packages in $file_path/${prefix}$pm_fname: $@";
         }
      }
      # If caller requests 'extract', add the tar's files and symlinks to the tree
      if ($extract) {
         for (keys %files) {
            my $mode= $files{$_}->mode;
            if (S_ISREG($mode)) {
               # normalize to 644 or 755
               $mode= S_IFMT($mode) | (($mode & 1)? 0755 : 0644);
               $tree->set_path("$path_without_extension/$_", $files{$_}->get_content_by_ref, $mode);
            } elsif (S_ISLNK($mode)) {
               $tree->set_path("$path_without_extension/$_", \$files{$_}->linkname, S_IFMT($mode));
            } elsif (!S_ISDIR($mode)) {
               warn "Skipping tar entry for '$path_without_extension/$_' (mode=$mode)\n";
            }
         }
      } else {
         $tree->set_path($file_path, $file_data);
      }
      # Now serialzie the meta and write it to the tree alongside the TAR
      my $json= CPAN::Meta->new($meta)->as_string({ version => 2 });
      $tree->set_path($path_without_extension . '.json', \$json);
   }
   else {
      warn "$file_path does not appear to be a TAR file.  Skipping metadata processing.";
      $tree->set_path($file_path, $file_data);
   }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::InGit - Manage custom CPAN trees to pin versions for your projects

=head1 SYNOPSIS

Using the module:

  my $git_repo= Git::Raw::Repository->discover($repo_path // getcwd);
  my $cpan_repo= CPAN::InGit->new(git_repo => $git_repo);
  
  # Create a mirror of public CPAN
  # Setting "upstream_url" creates a partial mirror which advertises all
  # current public CPAN versions of modules, and fetches dists on demand
  # and commits them to that branch, as a cache.
  $cpan_repo->create_archive_tree('www_cpan_org', upstream_url => 'https://www.cpan.org');
  
  # Create a branch to be the per-application tree of modules.  Configure
  # it to "import_modules" from branch "www_cpan_org".
  $cpan_repo->create_archive_tree('my_app',
    default_import_sources => ['www_cpan_org'],
    corelist_perl_version => '5.026003',
  );
  
  # This pulls modules Catalyst and DBIx::Class from the www_cpan_org branch
  # (which fetches and commits on demand) and then adds them to the package
  # index of branch 'my_app'.
  my $app_pan= $cpan_repo->get_archive_tree('my_app');
  $app_pan->import_modules({
    'Catalyst' => 0,
    'DBIx::Class' => 0,
  });
  
  # Commit the changes to branch 'my_app'
  $app_pan->commit("Added Catalyst and DBIx::Class");
  
  # This only pulls Log::Any, because the versions of Catalyst and DBIx::Class
  # are already satisfied, even if new versions of DBIx::Class were available,
  # and even if those new versions were in branch 'www_cpan_org'.
  # The versions are pinned until you request a newer version.
  $app_pan->import_modules({
    'Catalyst' => 0,
    'DBIx::Class' => 0,
    'Log::Any' => 1,
  });

Using the command line to do the same as above:

  mkdir localpan && cd localpan && git init
  cpangit-create --upstream_url=https://www.cpan.org www_cpan_org
  cpangit-create --from=www_cpan_org --corelist=v5.26 my_app
  cpangit-add --branch=my_app Catalyst DBIx::Class
  cpangit-add --branch=my_app Catalyst DBIx::Class Log::Any
  cpangit-server -l http://localhost:3000 &
  cpanm -M http://localhost:3000/my_app/ Catalyst DBIx::Class

=head1 DESCRIPTION

B<WARNING> This module is in an early state of development, and the API is not final.

C<CPAN::InGit> is a concept that instead of using Carton and a cpanfile.spanshot to request
an exact list of modules for your project, you store the exact list in a Git repo and then serve
that as a CPAN mirror to your CPAN client as if these are the only versions of modules that
exist.  You can then use any CPAN client you like without fussing with where it will install the
modules or how it will decide when to upgrade versions of dependencies.

Eventually, I plan to have functionality to help "curate" a collection of CPAN modules, such as
applying patches for known issues in modules, ensuring application branches upgrade to those
patched versions, upgrading back to the public CPAN verison when the fix gets picked up by the
primary author, or identifying when dependencies have CVEs that require an upgrade.

=head3 Features

=over

=item *

It's your own private CPAN (DarkPAN) with all the benefits that entails.
(such as private distributions or patching public distributions)

=item *

By hosting CPAN modules on your own infrastructure, you can avoid hammering public CPAN with
your CI/CD builds every time you push a commit.

=item *

The data is stored in Git, so it's version controlled and compressed.
You can revert to a previous environment for your application with a simple "git revert".

=item *

The server serves each B<branch> as its own mirror URL, so it's actually like an unlimited
number of DarkPANs hosted on the same server.  You can reference the server sub-path with
your project's Dockerfile like C<< cpanm -M http://ingit-server.local/my_app_branch/ >>.

=item *

This module reads directly from the Git repo storage without needing a checkout.
You can point the server at the same repository being hosted by
L<Gitea|https://about.gitea.com/products/gitea/>.

=item *

Removes the need for cpanfile.snapshot or Carton, because now the DarkPAN mirror is versioning
your environment for each application.

=back

=head1 ATTRIBUTES

=head2 git_repo

An instance of L<Git::Raw::Repository> (which wraps libgit2.so) for accessing the git structures.
You can pass this attribute to the constructor as a simple directory path which gets inflated
to a Repository object.

=head2 git_author_name

Name used for commits generated by this library.  Defaults to 'CPAN::InGit'

=head2 git_author_email

Email used for commits generated by this library.  Defaults to 'CPAN::InGit@localhost'

=head2 useragent

The L<Mojo::UserAgent> object used when downloading files from the real CPAN.

=head1 METHODS

=head2 get_archive_tree

  $mirror= $cpan_repo->get_archive_tree($branch_or_tag_or_id);

Return a L<ArchiveTree object|CPAN::InGit::ArchiveTree> for the given
branch name, git tag, or commit hash.  This branch must look like an archive
(having C<< /cpan_ingit.json >>) or it will return C<undef>.

=head2 create_archive_tree

  $mirror= $cpan_repo->create_archive_tree($branch_name, %params);

Create a new mirror branch.  The branch must not already exist.

=head2 lookup_tree

  $tree= $cpan_repo->lookup_tree($branch_or_tag_or_commit);
  ($tree, $origin)= $cpan_repo->lookup_tree($branch_or_tag_or_commit);

Return the L<Git::Raw::Tree> object for the given branch name, git tag, or commit hash.
Returns C<undef> if not found.  In list context, it returns both the tree and the origin object
(commit, branch, or tag) for that tree.

=head2 add_git_tree_to_tar

  $mirrorInGit->add_git_tree_to_tar($tar, $path, $tree);

This utility function adds L<Git trees|Git::Raw::Tree> to a L<tar archve|Archive::Tar>,
calling L</add_git_dirent_to_tar> for each entry.  C<$path> provides the name for the root
of the tree within the archive.  C<undef> or empty string means the tree I<will be> the root of
the archive.

=head2 add_git_dirent_to_tar

  $mirrorInGit->add_git_dirent_to_tar($tar, $path, $dirent);

This utility function adds L<Git directory entries|Git::Raw::Tree::Entry> to a
L<tar archve|Archive::Tar>.  It recurses subdirectories and handles symlinks.
The C<$path> is used for the destination name instead of C<< $dirent->name >>.

=head2 new_signature

Returns a L<Git::Raw::Signature> that will be used for commits authored by this module.
Signatures contain a timestamp, so the library generates new signatures frequently during
operation.

=head2 lookup_versions

  $version_list= $cpan_repo->lookup_versions($module_name);

This returns a list of all versions of that module which are already cached in any Mirror of
this repo, and also any version which is available from any of the upstream mirrors listed in
L</upstream_mirrors>.

=head2 process_distfile

  my $index= $darkpan->process_distfile(
    tree      => $mirror_tree,
    file_path => $path,
    file_data => \$bytes,
    untar     => $bool,   # whether to extract tar file into the tree
  );

=head1 VERSION

version 0.001

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad, and IntelliTree Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package CPAN::InGit;

our $VERSION = '0.007'; # VERSION
# ABSTRACT: Manage custom CPAN trees to pin versions for your projects

use Git::Raw::Repository;
use Archive::Tar;
use Archive::Tar::Constant; # for constants to be avilable at compile time
use Scalar::Util 'blessed';
use CPAN::InGit::MirrorTree;
use Fcntl 'LOCK_EX';
use File::Temp;
use POSIX ();
use Log::Any '$log';
use CPAN::Meta 2.150010;
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

has cve_feed_url              => ( is => 'rw', default => 'https://cpan-security.github.io/cpansa-feed/cpansa.json' );
has cve_feed_path             => ( is => 'rw', lazy => 1, builder => 1 );
has cve_feed_max_age          => ( is => 'rw', default => 12*60*60 );
sub _build_cve_feed_path($self) {
   return $self->git_repo->path . 'cpan-ingit-cpansa.json';
}


sub load_advisories($self, %options) {
   require CPAN::InGit::Advisories;
   my $path= $options{path} // $self->cve_feed_path;
   my $refresh= $options{refresh};
   my $mtime= (stat $path)[9];
   my $bytes;
   my $want_fetch= defined $refresh? $refresh : !defined $mtime || $mtime < time - $self->cve_feed_max_age;
   if (!$want_fetch) {
      defined $mtime or croak "No copy of the CVE list at '$path', and not allowed to download it";
   }
   else {
      my $error;
      eval {
         require Mojo::Date;
         my $url= $self->cve_feed_url;
         my $tx= $self->useragent->get($url,
            defined $mtime? { 'If-Modified-Since' => Mojo::Date->new($mtime)->to_string } : ());
         my $res= $tx->result;
         $log->debugf(" GET %s -> %s %s", $url, $res->code, $res->message);
         if (defined $mtime && $res->code == 304) {
            utime undef, undef, $path;
         }
         elsif ($res->is_success) {
            $bytes= $res->body;
            # Refuse to replace a good copy with something which isn't a feed
            CPAN::InGit::Advisories->new_from_json($bytes);
            my $tmp= File::Temp->new(TEMPLATE => "$path.XXXXXX");
            binmode $tmp;
            $tmp->print($bytes) && $tmp->close or die "write($tmp): $!\n";
            chmod 0666 & ~umask, "$tmp";
            rename "$tmp", $path or die "rename($tmp, $path): $!\n";
            $tmp->unlink_on_destroy(0);
         }
         else {
            die $res->code.' '.$res->message."\n";
         }
         $mtime= (stat $path)[9];
         1;
      } or do {
         chomp($error= $@);
         $error =~ s{ at \S+ line \d+\.\z}{};
         undef $bytes;
         defined $mtime or croak "Can't download the CVE list: $error";
         $log->warnf("Can't refresh the CVE list (%s); using the copy from %s",
            $error, POSIX::strftime('%Y-%m-%d %H:%M:%S UTC', gmtime $mtime));
      };
   }
   unless (defined $bytes) {
      open my $fh, '<:raw', $path or croak "open($path): $!";
      local $/;
      $bytes= <$fh>;
   }
   return CPAN::InGit::Advisories->new_from_json($bytes, source_path => $path, fetched => $mtime);
}

has dist_cache_path           => ( is => 'lazy' );
sub _build_dist_cache_path($self) {
   return $self->git_repo->path . 'cpan-ingit-cache.git';
}

has dist_cache_repo           => ( is => 'lazy' );
sub _build_dist_cache_repo($self) {
   my $path= $self->dist_cache_path;
   my $repo= eval {
      -d $path or Git::Raw::Repository->init($path, 1);
      -w "$path/refs" or die "not writable\n";
      $self->_link_dist_cache($path);
   };
   unless ($repo) {
      $self->{_dist_cache_tmpdir}= File::Temp->newdir('cpan-ingit-cache-XXXXXXXX', TMPDIR => 1);
      $path= $self->{_dist_cache_tmpdir}->dirname;
      Git::Raw::Repository->init($path, 1);
      $repo= $self->_link_dist_cache($path);
   }
   return $repo;
}

# Make the objects of the main repo readable from the cache repo, and return the cache repo
sub _link_dist_cache($self, $path) {
   my $git_dir= Git::Raw::Repository->open($path)->path;
   my $alternates= $self->git_repo->path . "objects\n";
   my $fname= $git_dir . 'objects/info/alternates';
   my $current= '';
   if (open my $in, '<:raw', $fname) { local $/; $current= <$in> // ''; }
   if ($current ne $alternates) {
      mkdir $git_dir . 'objects/info';
      open my $out, '>:raw', $fname or die "open($fname): $!\n";
      $out->print($alternates) && $out->close or die "write($fname): $!\n";
   }
   return Git::Raw::Repository->open($path);
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
      name => $branch? $branch->shorthand : "$branch_or_tag_or_id",
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
   if (blessed($branch_or_tag_or_id) && $branch_or_tag_or_id->isa('Git::Raw::Reference')) {
      $origin= $branch_or_tag_or_id;
      $tree= $origin->peel('tree');
   } elsif (blessed($branch_or_tag_or_id) && $branch_or_tag_or_id->isa('Git::Raw::Commit')) {
      $origin= $branch_or_tag_or_id;
      $tree= $origin->tree;
   } elsif (blessed($branch_or_tag_or_id) && $branch_or_tag_or_id->isa('Git::Raw::Tag')) {
      $origin= $branch_or_tag_or_id;
      $origin= $origin->target while $origin->isa('Git::Raw::Tag');
      $tree= $origin->isa('Git::Raw::Commit')? $origin->tree : $origin;
   } elsif ($branch_or_tag_or_id eq 'HEAD') {
      $tree= $repo->head->target->tree;
      $origin= $repo->is_head_detached? undef
             : $repo->head;
   } elsif ($origin= eval { Git::Raw::Branch->lookup($repo, $branch_or_tag_or_id, 1) }) {
      $tree= $origin->peel('tree');
   } elsif ($origin= eval { Git::Raw::Tag->lookup($repo, $branch_or_tag_or_id) }) {
      $tree= $origin->peel('tree');
   } elsif (my $obj= eval { $repo->lookup($branch_or_tag_or_id) }) {
      if ($obj->isa('Git::Raw::Commit')) {
         $origin= Git::Raw::Commit->lookup($repo, $obj->id);
         $tree= $origin->tree;
      } elsif ($obj->isa('Git::Raw::Tree')) {
         $tree= Git::Raw::Tree->lookup($repo, $obj->id);
      } elsif ($obj->isa('Git::Raw::Tag')) {
         $origin= Git::Raw::Tag->lookup($repo, $obj->id);
         $tree= $origin->target;
      }
   }
   return wantarray? ($tree, $origin) : $tree;
}


sub add_git_tree_to_tar($self, $tar, $path, $tree) {
   unless ($tree->can('entries')) {
      my $id= $tree;
      $tree = Git::Raw::Tree->lookup($self->git_repo, $id)
         or die "Can't find TREE $id referenced by '$path'";
   }
   $self->add_git_dirent_to_tar($tar, "$path/".$_->name, $_)
      for $tree->entries;
}

sub add_git_dirent_to_tar($self, $tar, $path, $dirent) {
   if ($dirent->type == Git::Raw::Object::BLOB()) {
      my $mode = $dirent->file_mode;
      my $blob = Git::Raw::Blob->lookup($self->git_repo, $dirent->id)
         or die "Can't find BLOB ".$dirent->id." referenced by '$path'";
      # Check if it's a symlink (mode 0120000 or 40960 decimal)
      if (($mode & 0170000) == 0120000) {
         # Symlink: content is the target path
         $tar->add_data($path, $blob->content, { 
            mode => $mode,
            mtime => 0,
            type => Archive::Tar::Constant::SYMLINK,
            linkname => $blob->content
         });
      }
      else {
         # Regular file
         $tar->add_data($path, $blob->content, { mode => $mode, mtime => 0 });
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


sub cached_dist_tree($self, $key, $builder=undef) {
   my $repo= $self->dist_cache_repo;
   # v1 is the version of the unpacking rules (such as removal of the wrapper directory)
   $key =~ m{\A[a-z]+/[0-9a-f]+\z} or croak "Invalid dist cache key '$key'";
   my $refname= "refs/dists/v1/$key";
   my $ref= Git::Raw::Reference->lookup($refname, $repo);
   return $ref->target if $ref;
   return undef unless $builder;

   # Publish only completed trees.  Recheck after locking in case another process built it.
   open my $lock, '>>', $repo->path.'dist-cache.lock' or croak "Open dist cache lock: $!";
   flock $lock, LOCK_EX or croak "Lock dist cache: $!";
   $ref= Git::Raw::Reference->lookup($refname, $repo);
   return $ref->target if $ref;
   my $tree= $builder->() // return undef;
   Git::Raw::Reference->create($refname, $repo, $tree);
   return $tree;
}

#=method parse_cpanfile_snapshot
#
#  $distribution_spec= $cpan_repo->parse_cpanfile_snapshot($file_contents);
#
#Given a scalar with the content of a cpanfile.snapshot from L<Carton>, this returns the data of
#that file as a hierarchial structure:
#
#  {
#    "Distribution-Name-1.002003" => {
#      "pathname" => "A/AU/AUTHOR/Distribution-Name-1.002003.tar.gz",
#      "provides" => {
#        "Distribution::Name" => '1.002003',
#        ...
#      },
#      "requirements" => {
#        "Dependency" => "2.05",
#        ...
#      }
#    }
#  }
#
#=cut

sub _context {
   my $context= substr($_, pos($_), $_[0]);
   $context =~ s/\r/\\r/g;
   $context =~ s/\n/\\n/g;
   return $context;
}
sub _parse_cpanfile_snapshot($self, $text) {
   # TODO: use official module if available, else fall back to this:
   my %distributions;
   local $_= $text;
   unless (eval {
      /^# carton snapshot format: version 1.0\r?\n/mgc
         or die "Unsupported cpanfile.snapshot version\n";
      /\GDISTRIBUTIONS\r?\n/gc
         or die "expected DISTRIBUTIONS\n";
      while (length > pos) {
         my ($dist_name)= /\G  (\S+)\r?\n/gc
            or die "expected dist name\n";
         my $dist= $distributions{$dist_name}= {};
         while (/\G    (\w[^\r\n:]*): *(.*?)\r?\n/gc) {
            my ($attr, $val)= ($1, $2);
            if (length $val) {
               $dist->{$attr}= $val;
            } else {
               while (/\G      (.*)\r?\n/gc) {
                  push @{ $dist->{$attr} }, $1;
               }
            }
            die "Unexpected sub-element of $dist_name $attr\n"
               if /\G      /gc;
         }
         die "Unexpected sub-element of $dist_name\n"
            if /\G    /gc;
         # convert 'provides' and 'requirements' to hashrefs of versions
         for (qw( provides requirements )) {
            if (ref $dist->{$_} eq 'ARRAY') {
               $dist->{$_}= { map +((split ' ')[0,1]), @{$dist->{$_}} };
            }
         }
      }
      1;
   }) {
      chomp $@;
      my $context= _context(20);
      croak "syntax error: $@, near \"$context\"";
   }
   \%distributions;
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
  
  # Create a branch to be the per-application tree of modules.
  # Configure it to "import_modules" from branch "www_cpan_org".
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
  
  # This only pulls Log::Any because the versions of Catalyst and DBIx::Class
  # are already satisfied, even if a new version of DBIx::Class is available,
  # and even if a new version is indexed in branch 'www_cpan_org'.
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

=head2 dist_cache_path

Path of the Git repository used for L</dist_cache_repo>.  The default is a directory named
C<cpan-ingit-cache.git> inside of the Git directory of L</git_repo>.

=head2 dist_cache_repo

A bare L<Git::Raw::Repository> holding the unpacked contents of distribution archives, so
that they can be browsed and compared as Git trees.  (see L<CPAN::InGit::DistTree>)
It is created on demand.  It has the object store of L</git_repo> as an "alternate", so it
can read every object of the main repository, but everything written to it stays out of your
main repository.  It only holds data that can be re-created, and can be deleted at any time.

If L</dist_cache_path> can't be created or written, a temporary directory is used instead
and removed when this object is destroyed.

=head2 cve_feed_url

URL of the CPAN Security Advisory feed.  This is the same file the web interface uses.

=head2 cve_feed_path

Path of the file holding the latest downloaded copy of the feed.  The default is a file named
C<cpan-ingit-cpansa.json> inside of the Git directory of L</git_repo>.  There is only ever
one copy; it is replaced when a newer one is downloaded, and can be deleted at any time.

=head2 cve_feed_max_age

Number of seconds for which the downloaded feed is used without asking the server whether
there is a newer one.  Defaults to 12 hours.

=head1 METHODS

=head2 load_advisories

  my $advisories= $cpan_repo->load_advisories(%options);

Return a L<CPAN::InGit::Advisories> object for the CPAN Security Advisory feed, downloading
it to L</cve_feed_path> when there is no copy or the copy is older than
L</cve_feed_max_age>.  The download is conditional, so an unchanged feed is not transferred
again.  If the download fails and there is an older copy, a warning is logged and the older
copy is used.  If there is no copy at all, this dies.

Options:

=over

=item path

Use this file instead of L</cve_feed_path>

=item refresh

True to ask the server for a newer feed regardless of the age of the copy.  False (but
defined) to never use the network, and die if there is no copy.

=back

=head2 get_archive_tree

  $mirror= $cpan_repo->get_archive_tree($branch_or_tag_or_id);

Return a L<ArchiveTree object|CPAN::InGit::ArchiveTree> for the given
branch name, git tag, or commit hash. A Git::Raw::Reference, Git::Raw::Tag,
or Git::Raw::Commit object can also select a tree without resolving a name.
This tree must look like an archive
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

=head2 cached_dist_tree

  $git_tree= $cpan_repo->cached_dist_tree($key);
  $git_tree= $cpan_repo->cached_dist_tree($key, sub { ...; return $git_tree });

Look up a L<Git::Raw::Tree> of an unpacked distribution in the L</dist_cache_repo> by a
key (any string, by convention prefixed with the kind of key such as C<"blob/$blob_id">).
If it isn't cached and you supply a coderef, the coderef is called to build the tree in
L</dist_cache_repo> and the result is cached.  Builders are serialized by a lock file so
that concurrent processes don't unpack the same archive twice.  The coderef may return
C<undef> to cache nothing.

=head1 SEE ALSO

=over

=item L<App::opan>

App::opan is quite similar in spirit, and stores the mirror as files that can be simply checked
into version control.  It manages a list of pre-defined "PANs" like "upstream", "pinset",
"custom"... each of which plays a role in managing modules for one app.
There doesn't appear to be any concept for managing multiple apps or letting the server serve
branches or an older snapshot of the combined 'PANs.

=item L<CPAN::Mini::Inject>

This builds on L<CPAN::Mini> to inject custom files into a local tree that is mirroring
public CPAN.

=item L<Pinto>

Pinto is the same idea (with larger scope) but implemented on a SQL Database.
This necessitates a custom system of push/pull, user accounts, permissions, and so on.
It's also fairly heavy on dependencies (Moose, DBIx::Class)

=item L<Carton>

Carton is a system for installing perl modules and tracking all their versions and dependencies
and storing that in a C<cpanfile.snapshot> so that the exact same modules can be installed on
future runs.  Carton requires that all modules get installed into the local-lib directory (so it
can't utilize system-installed perl libraries) and doesn't provide any way to patch CPAN modules
before installing them.

=back

=head1 VERSION

version 0.007

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad, and IntelliTree Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

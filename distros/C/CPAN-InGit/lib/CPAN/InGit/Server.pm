package CPAN::InGit::Server;
our $VERSION = '0.002'; # VERSION
# ABSTRACT: A Mojolicious::Controller that serves the ArchiveTrees from a git repo


use Carp;
use Scalar::Util 'refaddr', 'blessed';
use JSON::PP;
use Time::Piece;
use Log::Any '$log';
use Archive::Tar;
use IO::Compress::Gzip qw( gzip $GzipError );
use CPAN::InGit;
use Mojo::Base 'Mojolicious::Controller';
use v5.36;


sub cpan_repo($c) { $c->stash('cpan_repo') }

sub archive_tree($c) {
   $c->stash->{archive_tree} //= do {
      my $branch_name= $c->branch_name;
      my $cache= $c->branch_cache;
      my $atree= $cache->{$branch_name};
      if ($atree) {
         # check whether branch has updated since cached
         my $current_tree= $c->cpan_repo->lookup_tree($branch_name);
         unless (defined $current_tree and $atree->tree->id eq $current_tree->id) {
            delete $cache->{$branch_name};
            $atree= undef;
         }
      }
      if (!$atree && ($atree= $c->cpan_repo->get_archive_tree($branch_name))) {
         if ($c->branch_head_only && !defined $atree->branch) {
            $c->log->debug("Branch '$branch_name' is not a branch HEAD");
            $atree= undef;
         } else {
            $cache->{$branch_name}= $atree;
         }
      }
      $atree;
   };
}

sub branch_name($c) { $c->stash('branch_name') }

sub branch_cache($c) {
   $c->stash->{branch_cache} //= do {
      warn "no branch_cache, creating temporary";
      $c->_new_cache
   }
}

sub branch_head_only($c) { $c->stash('branch_head_only') }

sub _new_cache {
   # the 'recent_limit' feature was added in 0.20
   state $have_tree_rb_xs= eval 'use Tree::RB::XS 0.20';
   my %hash;
   tie %hash, 'Tree::RB::XS', track_recent => 1, recent_limit => 20
      if $have_tree_rb_xs;
   \%hash;
}


sub mount($class, $base_route, $cpan_repo, %options) {
   my $atree= $options{archive_tree};
   if ($atree) {
      croak "Not an ArchiveTree"
         unless blessed($atree) && $atree->can('get_path');
   } else {
      # Ensure there is a cache if serving all branches
      $options{branch_cache} //= $class->_new_cache;
   }
   $base_route= $base_route->to(namespace => '', controller => $class, cpan_repo => $cpan_repo, %options);
   my $tree_route= $atree? $base_route
      : $base_route->any('/:branch_name');
   $tree_route->get('/modules/02packages.details', [ format => ['txt','txt.gz'] ])
      ->to(action => 'serve_package_details');
   $tree_route->get('/authors/id/*author_path')->to(action => 'serve_author_file');
}


sub check_branch_exists($c) {
   unless ($c->archive_tree) {
      $c->render(text => 'Git branch does not exist', status => 404);
      return undef;
   }
   return 1;
}


sub serve_package_details($c) {
   return undef unless $c->check_branch_exists;
   my $blob= $c->archive_tree->package_details_blob;
   $c->respond_to(
      txt      => sub { $c->render(text => $blob->content) },
      'txt.gz' => sub { $c->render_gzipped($blob->content, '02packages.details.txt.gz') },
   );
}


sub serve_author_file($c) {
   return undef unless $c->check_branch_exists;
   my $path= 'authors/id/'.$c->stash->{author_path};
   # cpanm adds extra '/' when the path name doesn't match the expected A/AU/AUTHOR format
   $path =~ s,//+,/,g;
   my ($basename)= ($path =~ m,([^/]+)\z,);
   # Does the exact file exist?
   my $ent= $c->archive_tree->get_path($path);
   $c->log->debug("Path $path is ".($ent? ($ent->[0]->is_blob? 'blob ':'tree ').$ent->[0]->id : '<undef>'));
   if ($ent) {
      if ($ent->[0]->is_blob) {
         $c->res->headers->content_disposition(qq{attachment; filename="$basename"});
         $c->render(data => $ent->[0]->content);
      } else {
         $c->render(status => 403, text => 'not a file');
      }
   }
   elsif ($path =~ /(.*?)\.gz\z/
      && ($ent= $c->archive_tree->get_path($1)) && $ent->[0]->is_blob
   ) {
      $c->log->debug("Path $1 is ".$ent->[0]->id.', will gzip it');
      $c->render_gzipped($ent->[0]->content, $basename);
   }
   elsif ($path =~ /(.*?)\.tar\.gz\z/
      # Don't auto-tar trees that don't look like distributions
      && ($ent= $c->archive_tree->get_path("$1.meta")) && $ent->[0]->is_blob
      && ($ent= $c->archive_tree->get_path($1)) && $ent->[0]->is_tree
   ) {
      $c->log->debug("Path $1 is ".$ent->[0]->id.', will tar+gzip it');
      my $tar= Archive::Tar->new;
      $c->cpan_repo->add_git_tree_to_tar($tar, substr($basename, 0, -7), $ent->[0]);
      $c->render_gzipped($tar->write, $basename);
   }
   else {
      $c->render(status => 404, text => 'No such path in branch');
   }
}


sub render_gzipped($c, $data, $filename='') {
   my $gzipped;
   gzip \$data => \$gzipped
     or return $c->reply->exception("gzip failed: $GzipError");
   $c->res->headers->content_type('application/gzip');
   $c->res->headers->content_disposition(qq{attachment; filename="$filename"})
      if length $filename;
   return $c->render(data => $gzipped);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::InGit::Server - A Mojolicious::Controller that serves the ArchiveTrees from a git repo

=head1 DESCRIPTION

This controller serves paths that can be used directly as a CPAN Mirror by tools like 'cpanm'.
By default, it serves all branches, but you can also configure it to serve only a single branch.
It serves content directly from the Git repo and does not need a working directory checked out.

=head1 ATTRIBUTES

=head2 cpan_repo

Reference to the CPAN::InGit object from which files will be served

=head2 archive_tree

Reference to an L<ArchvieTree|CPAN::InGit::ArchvieTree> object.  If set, the controller
will serve only the tree of this branch from whatever path it was rooted at.  If not set,
this attribute will be lazy-built from attribute C<branch_name> and cached in C<branch_cache>.
The lazy-building of this attribute may return C<undef>, and should be checked I<before>
dispatching to an action.

=head2 branch_name

Name of branch to be lazy-loaded by the C<archive_tree> accessor.

=head2 branch_cache

A hashref or L<Tree::RB::XS> object storing a cache of ArchiveTree objects.  This needs to be
supplied in the stash if you are loading branches by name at runtime, or else it will be
creating an ArchiveTree object on every request.

=head2 branch_head_only

If true, this prevents serving files from a Git::Raw tree which is not the HEAD of a branch.
By default, any Git sha-1, tag, or branch name may be used so long as it references a tree that
meets the requirements for an ArchiveTree.

=head1 METHODS

=head2 check_branch_exists

This checks that the L</branch_name> could be successfully resolved to a L</archive_tree>.
It returns true, or sets a 404 error and returns undef, and can be used as C<< ->under(\&check_branch_exists) >>.

=head2 serve_package_details

Serve C<< modules/02packages.details.txt[.gz] >>.

=head2 serve_author_file

Serve all files under C<< authors/id/... >>.  (All files in that path of the git branch are considered public)
This performs automatic creation of .tar.gz files if a directory and matching .meta file exist,
allowing distributions to be unpacked within the git repo, but served as .tar.gz files.

=head2 render_gzipped

Serve content after gzipping it and setting the content type to C<< application/gzip >>.

=head1 ROUTES

=head2 Cpan Mirror Paths

A functioning CPAN mirror requires a file C<< /modules/02packages.details.txt.gz >> which lists
the full contents of the latest version of every module.  That file also lists the author paths
for each module, which are relative to C<< /authors/id/ >>

In CPAN::InGit, C<< /modules/02packages.details.txt >> is stored uncompressed, and
gzipped as it is served.  Each author dist is stored as a .tar.gz file and a metadata file with
extension .meta and may also optionally be unpacked at a directory of the same name minus the
.tar.gz extension.  A special author "local" is used for custom overrides of upstream packages.

Summary:

  /:branch/modules/02packages.details.txt                 # index of the mirror
  /:branch/authors/id/D/DP/DPARIS/Crypt-DES-2.07.tar.gz   # copy of upstream
  /:branch/authors/id/D/DP/DPARIS/Crypt-DES-2.07.meta     # extracted metadata
  /:branch/authors/id/local/Crypt-DES-2.07_01/...         # untarred customized dist
  /:branch/authors/id/local/Crypt-DES-2.07_01.meta        # untarred customized dist's metadata

=head2 mount

  my $route= app->routes->any('/pan');
  my $repo= CPAN::InGit->new(git_repo => '/path/to/.git');
  CPAN::InGit::Server->mount($route, $repo, %options);
  # %options:
  #   archive_tree => $ArchiveTree_obj,
  #   branch_cache => $branch_cache,

This class method sets up the routes for serving the mirror under a provided route.
C<$route> is the route under which you want to serve the 'PAN.

If you specify 'branch', that branch will be directly mounted at the route without the '/:branch'
selector portion of the paths.

=head1 VERSION

version 0.002

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Michael Conrad, and IntelliTree Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

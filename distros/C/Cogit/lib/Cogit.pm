package Cogit;
$Cogit::VERSION = '0.001001';
# ABSTRACT: A truly Pure Perl interface to Git repositories

use Moo;
use Carp 'confess';
use Check::ISA;
use MooX::Types::MooseLike::Base qw( InstanceOf ArrayRef Str );
use Data::Stream::Bulk::Array;
use Data::Stream::Bulk::Path::Class;
use File::Find::Rule;
use Cogit::Config;
use Cogit::Loose;
use Cogit::Object::Blob;
use Cogit::Object::Commit;
use Cogit::Object::Tag;
use Cogit::Object::Tree;
use Cogit::Pack::WithIndex;
use Cogit::Pack::WithoutIndex;
use Cogit::Protocol;
use Path::Class;
use namespace::clean;

has directory => (
   is     => 'ro',
   isa    => InstanceOf ['Path::Class::Dir'],
   coerce => sub { return dir($_[0]); },
);

has gitdir => (
   is       => 'ro',
   isa      => InstanceOf ['Path::Class::Dir'],
   coerce   => sub { return dir($_[0]); },
   required => 1,
);

has loose => (
   is      => 'rw',
   isa     => InstanceOf ['Cogit::Loose'],
   lazy    => 1,
   builder => '_build_loose',
);

has packs => (
   is      => 'rw',
   isa     => ArrayRef [InstanceOf ['Cogit::Pack']],
   lazy    => 1,
   builder => '_build_packs',
);

has description => (
   is      => 'rw',
   isa     => Str,
   lazy    => 1,
   default => sub {
      my $self = shift;
      file($self->gitdir, 'description')->slurp(chomp => 1);
   });

has config => (
   is      => 'ro',
   isa     => InstanceOf ['Cogit::Config'],
   lazy    => 1,
   default => sub {
      my $self = shift;
      Cogit::Config->new(git => $self);
   });

sub BUILDARGS {
   my $class  = shift;
   my $params = $class->SUPER::BUILDARGS(@_);

   $params->{'gitdir'} ||= dir($params->{'directory'}, '.git');
   return $params;
}

sub BUILD {
   my $self = shift;

   unless (-d $self->gitdir) {
      confess $self->gitdir . ' is not a directory';
   }
   unless (not defined $self->directory or -d $self->directory) {
      confess $self->directory . ' is not a directory';
   }
}

sub _build_loose {
   my $self = shift;
   my $loose_dir = dir($self->gitdir, 'objects');
   return Cogit::Loose->new(directory => $loose_dir);
}

sub _build_packs {
   my $self = shift;
   my $pack_dir = dir($self->gitdir, 'objects', 'pack');
   my @packs;
   for my $filename ($pack_dir->children) {
      next unless $filename =~ /\.pack$/;
      push @packs, Cogit::Pack::WithIndex->new(filename => $filename);
   }
   return \@packs;
}

sub _ref_names_recursive {
   my ($dir, $base, $names) = @_;

   for my $file ($dir->children) {
      if (-d $file) {
         my $reldir  = $file->relative($dir);
         my $subbase = $base . $reldir . "/";
         _ref_names_recursive($file, $subbase, $names);
      } else {
         push @$names, $base . $file->basename;
      }
   }
}

sub ref_names {
   my $self = shift;
   my @names;
   for my $type (qw(heads remotes tags)) {
      my $dir = dir($self->gitdir, 'refs', $type);
      next unless -d $dir;
      my $base = "refs/$type/";
      _ref_names_recursive($dir, $base, \@names);
   }
   my $packed_refs = file($self->gitdir, 'packed-refs');
   if (-f $packed_refs) {
      for my $line ($packed_refs->slurp(chomp => 1)) {
         next if $line =~ /^#/;
         next if $line =~ /^\^/;
         my ($sha1, $name) = split ' ', $line;
         push @names, $name;
      }
   }
   return @names;
}

sub refs_sha1 {
   my $self = shift;
   return map { $self->ref_sha1($_) } $self->ref_names;
}

sub refs {
   my $self = shift;
   return map { $self->ref($_) } $self->ref_names;
}

sub ref_sha1 {
   my ($self, $wantref) = @_;
   my $dir = dir($self->gitdir, 'refs');
   return unless -d $dir;

   if ($wantref eq "HEAD") {
      my $file = file($self->gitdir, 'HEAD');
      my $sha1 = file($file)->slurp
        || confess("Error reading $file: $!");
      chomp $sha1;
      return _ensure_sha1_is_sha1($self, $sha1);
   }

   for my $file (File::Find::Rule->new->file->in($dir)) {
      my $ref = 'refs/' . file($file)->relative($dir)->as_foreign('Unix');
      if ($ref eq $wantref) {
         my $sha1 = file($file)->slurp
           || confess("Error reading $file: $!");
         chomp $sha1;
         return _ensure_sha1_is_sha1($self, $sha1);
      }
   }

   my $packed_refs = file($self->gitdir, 'packed-refs');
   if (-f $packed_refs) {
      my $last_name;
      my $last_sha1;
      for my $line ($packed_refs->slurp(chomp => 1)) {
         next if $line =~ /^#/;
         my ($sha1, $name) = split ' ', $line;
         $sha1 =~ s/^\^//;
         $name ||= $last_name;

         return _ensure_sha1_is_sha1($self, $last_sha1)
           if $last_name
           and $last_name eq $wantref
           and $name ne $wantref;

         $last_name = $name;
         $last_sha1 = $sha1;
      }
      return _ensure_sha1_is_sha1($self, $last_sha1) if $last_name eq $wantref;
   }
   return undef;
}

sub _ensure_sha1_is_sha1 {
   my ($self, $sha1) = @_;
   return $self->ref_sha1($1) if $sha1 =~ /^ref: (.*)/;
   return $sha1;
}

sub ref {
   my ($self, $wantref) = @_;
   return $self->get_object($self->ref_sha1($wantref));
}

sub master_sha1 {
   my $self = shift;
   return $self->ref_sha1('refs/heads/master');
}

sub master {
   my $self = shift;
   return $self->ref('refs/heads/master');
}

sub head_sha1 {
   my $self = shift;
   return $self->ref_sha1('HEAD');
}

sub head {
   my $self = shift;
   return $self->ref('HEAD');
}

sub get_object {
   my ($self, $sha1) = @_;
   return unless $sha1;
   return $self->get_object_packed($sha1) || $self->get_object_loose($sha1);
}

sub get_objects {
   my ($self, @sha1s) = @_;
   return map { $self->get_object($_) } @sha1s;
}

sub get_object_packed {
   my ($self, $sha1) = @_;

   for my $pack (@{$self->packs}) {
      my ($kind, $size, $content) = $pack->get_object($sha1);
      if (defined($kind) && defined($size) && defined($content)) {
         return $self->create_object($sha1, $kind, $size, $content);
      }
   }
}

sub get_object_loose {
   my ($self, $sha1) = @_;

   my ($kind, $size, $content) = $self->loose->get_object($sha1);
   if (defined($kind) && defined($size) && defined($content)) {
      return $self->create_object($sha1, $kind, $size, $content);
   }
}

sub create_object {
   my ($self, $sha1, $kind, $size, $content) = @_;
   if ($kind eq 'commit') {
      return Cogit::Object::Commit->new(
         sha1    => $sha1,
         kind    => $kind,
         size    => $size,
         content => $content,
         git     => $self,
      );
   } elsif ($kind eq 'tree') {
      return Cogit::Object::Tree->new(
         sha1    => $sha1,
         kind    => $kind,
         size    => $size,
         content => $content,
         git     => $self,
      );
   } elsif ($kind eq 'blob') {
      return Cogit::Object::Blob->new(
         sha1    => $sha1,
         kind    => $kind,
         size    => $size,
         content => $content,
         git     => $self,
      );
   } elsif ($kind eq 'tag') {
      return Cogit::Object::Tag->new(
         sha1    => $sha1,
         kind    => $kind,
         size    => $size,
         content => $content,
         git     => $self,
      );
   } else {
      confess "unknown kind $kind: $content";
   }
}

sub all_sha1s {
   my $self = shift;
   my $dir = dir($self->gitdir, 'objects');

   my @streams;
   push @streams, $self->loose->all_sha1s;

   for my $pack (@{$self->packs}) {
      push @streams, $pack->all_sha1s;
   }

   return Data::Stream::Bulk::Cat->new(streams => \@streams);
}

sub all_objects {
   my $self   = shift;
   my $stream = $self->all_sha1s;
   return Data::Stream::Bulk::Filter->new(
      filter => sub { return [$self->get_objects(@$_)] },
      stream => $stream,
   );
}

sub put_object {
   my ($self, $object, $ref) = @_;
   $self->loose->put_object($object);

   if ($object->kind eq 'commit') {
      $ref = 'master' unless $ref;
      $self->update_ref($ref, $object->sha1);
   }
}

sub update_ref {
   my ($self, $refname, $sha1) = @_;
   my $ref = file($self->gitdir, 'refs', 'heads', $refname);
   $ref->parent->mkpath;
   my $ref_fh = $ref->openw;
   $ref_fh->print($sha1) || die "Error writing to $ref";

   # FIXME is this always what we want?
   my $head = file($self->gitdir, 'HEAD');
   my $head_fh = $head->openw;
   $head_fh->print("ref: refs/heads/$refname")
     || die "Error writing to $head";
}

sub init {
   my ($class, %arguments) = @_;

   my $directory = $arguments{directory};
   my $git_dir;

   unless (defined $directory) {
      $git_dir = $arguments{gitdir}
        || confess "init() needs either a 'directory' or a 'gitdir' argument";
   } else {
      if (not defined $arguments{gitdir}) {
         $git_dir = $arguments{gitdir} = dir($directory, '.git');
      }
      dir($directory)->mkpath;
   }

   dir($git_dir)->mkpath;
   dir($git_dir, 'refs',    'tags')->mkpath;
   dir($git_dir, 'objects', 'info')->mkpath;
   dir($git_dir, 'objects', 'pack')->mkpath;
   dir($git_dir, 'branches')->mkpath;
   dir($git_dir, 'hooks')->mkpath;

   my $bare = defined($directory) ? 'false' : 'true';
   $class->_add_file(
      file($git_dir, 'config'),
      "[core]\n\trepositoryformatversion = 0\n\tfilemode = true\n\tbare = $bare\n\tlogallrefupdates = true\n"
   );
   $class->_add_file(file($git_dir, 'description'),
      "Unnamed repository; edit this file to name it for gitweb.\n");
   $class->_add_file(file($git_dir, 'hooks', 'applypatch-msg'),
      "# add shell script and make executable to enable\n");
   $class->_add_file(file($git_dir, 'hooks', 'post-commit'),
      "# add shell script and make executable to enable\n");
   $class->_add_file(file($git_dir, 'hooks', 'post-receive'),
      "# add shell script and make executable to enable\n");
   $class->_add_file(file($git_dir, 'hooks', 'post-update'),
      "# add shell script and make executable to enable\n");
   $class->_add_file(file($git_dir, 'hooks', 'pre-applypatch'),
      "# add shell script and make executable to enable\n");
   $class->_add_file(file($git_dir, 'hooks', 'pre-commit'),
      "# add shell script and make executable to enable\n");
   $class->_add_file(file($git_dir, 'hooks', 'pre-rebase'),
      "# add shell script and make executable to enable\n");
   $class->_add_file(file($git_dir, 'hooks', 'update'),
      "# add shell script and make executable to enable\n");

   dir($git_dir, 'info')->mkpath;
   $class->_add_file(file($git_dir, 'info', 'exclude'), "# *.[oa]\n# *~\n");

   return $class->new(%arguments);
}

sub checkout {
   my ($self, $directory, $tree) = @_;
   $directory ||= $self->directory;
   $tree ||= $self->master->tree;
   confess("Missing tree") unless $tree;
   for my $directory_entry (@{$tree->directory_entries}) {
      my $filename = file($directory, $directory_entry->filename);
      my $sha1     = $directory_entry->sha1;
      my $mode     = $directory_entry->mode;
      my $object   = $self->get_object($sha1);
      if ($object->kind eq 'blob') {
         $self->_add_file($filename, $object->content);
         chmod(oct('0' . $mode), $filename)
           || die "Error chmoding $filename to $mode: $!";
      } elsif ($object->kind eq 'tree') {
         dir($filename)->mkpath;
         $self->checkout($filename, $object);
      } else {
         die $object->kind;
      }
   }
}

sub clone {
   my $self = shift;

   my $remote;
   if (@_ == 2) {

      # For backwards compatibility
      $remote = "git://$_[0]";
      $remote .= "/" unless $_[1] =~ m{^/};
      $remote .= $_[1];
   } else {
      $remote = shift;
   }

   my $protocol = Cogit::Protocol->new(remote => $remote)->connect;

   my $sha1s = $protocol->fetch;
   my $head  = $sha1s->{HEAD};
   my $data  = $protocol->fetch_pack($head);

   my $filename =
     file($self->gitdir, 'objects', 'pack', 'pack-' . $head . '.pack');
   $self->_add_file($filename, $data);

   my $pack = Cogit::Pack::WithoutIndex->new(filename => $filename);
   $pack->create_index();

   $self->update_ref(master => $head);
}

sub _add_file {
   my ($class, $filename, $contents) = @_;
   my $fh = $filename->openw || confess "Error opening to $filename: $!";
   binmode($fh);    #important for Win32
   $fh->print($contents) || confess "Error writing to $filename: $!";
   $fh->close || confess "Error closing $filename: $!";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cogit - A truly Pure Perl interface to Git repositories

=head1 VERSION

version 0.001001

=head1 SYNOPSIS

    my $git = Cogit->new(
        directory => '/path/to/git/'
    );
    $git->master->committer;
    $git->master->comment;
    $git->get_object($git->master->tree);

=head1 DESCRIPTION

This module is a Pure Perl interface to Git repositories.

It was mostly based on Grit L<http://grit.rubyforge.org/>.

=head1 HERE BE DRAGONS

This module's API is not yet battle tested.  Feel free to try it out, but don't
depend on it for serious stuff yet.  Comments regarding the API very welcome.

=head1 METHODS

=over 4

=item master

=item get_object

=item get_object_packed

=item get_object_loose

=item create_object

=item all_sha1s

=back

=head1 FORK

This module was forked from L<Git::PurePerl> for a couple reasons.  First and
foremost, C<Git::PurePerl> is based on L<Moose>, which is not pure perl.
Secondarily the API was very weird, with differentiations made based on whether
or not an object was in the repo or not.

=head1 CONTRIBUTORS

=over 4

=item Alex Vandiver

=item Chris Reinhardt

=item Dagfinn Ilmari MannsE<aring>ker

=item Dan (broquaint) Brook

=item Leon Brocard

=item Tomas (t0m) Doran

=back

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <cogit@afoolishmanifesto.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

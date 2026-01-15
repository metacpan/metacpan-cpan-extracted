package CPAN::InGit::MirrorTree;
our $VERSION = '0.003'; # VERSION
# ABSTRACT: Subclass of ArchiveTree which automatically mirrors files from upstream


use Carp;
use Scalar::Util 'refaddr', 'blessed';
use POSIX 'strftime';
use IO::Uncompress::Gunzip qw( gunzip $GunzipError );
use JSON::PP;
use Time::Piece;
use Log::Any '$log';
use Moo;
use v5.36;

extends 'CPAN::InGit::ArchiveTree';


has upstream_url            => ( is => 'rw', coerce => \&_add_trailing_slash );
has upstream_backup_url     => ( is => 'rw', lazy => 1, builder => 1, coerce => \&_add_trailing_slash );
has autofetch               => ( is => 'rw', default => 1 );
has package_details_max_age => ( is => 'rw', default => 86400 );

sub _build_upstream_backup_url($self) {
   ($self->upstream_url||'') =~ m{^(https?)://www\.cpan\.org}
      ? "$1://backpan.perl.org/"
      : undef;
}

sub _add_trailing_slash {
   my $x= shift;
   defined $x? $x =~ s{/?\z}{/}r : $x
}

sub _pack_config($self, $config) {
   $config->{upstream_url}= $self->upstream_url;
   $config->{upstream_backup_url}= $self->upstream_backup_url;
   $config->{autofetch}= $self->autofetch;
   $config->{package_details_max_age}= $self->package_details_max_age;
   $self->next::method($config);
}
sub _unpack_config($self, $config) {
   $self->next::method($config);
   $self->upstream_url($config->{upstream_url});
   $self->upstream_backup_url($config->{upstream_backup_url})
      if exists $config->{upstream_backup_url};
   $self->autofetch($config->{autofetch});
   $self->package_details_max_age($config->{package_details_max_age});
}

sub get_path($self, $path) {
   my $ent= $self->next::method($path);
   if ($self->autofetch) {
      # Special case for 02packages.details.txt, load it if missing or if cache is stale
      if ($path eq 'modules/02packages.details.txt') {
         if ($ent) {
            my $blob_last_update= $self->{_blob_last_update}{$ent->[0]->id} // do {
               # parse it out of the file
               my $head= substr($ent->[0]->content, 0, 10000);
               $head =~ /^Last-Updated:\s*(.*)$/m or die "Can't parse 02packages.details.txt";
               (my $date= $1) =~ s/\s+\z//;
               $log->debug("Date in modules/02packages.details.txt is '$date'");
               Time::Piece->strptime($date, "%a, %d %b %Y %H:%M:%S GMT")->epoch
            };
            if ($blob_last_update >= time - $self->package_details_max_age) {
               $log->trace(' 02package.details.txt cache is current');
            } else {
               $log->trace(' 02package.details.txt cache expired');
               $ent= undef;
            }
         }
         unless ($ent) {
            $log->debug(" mirror autofetch $path");
            my $blob= $self->add_upstream_package_details;
            $self->clear_package_details; # will lazily rebuild
            $ent= [ $blob, 0100644 ];
         }
      }
      elsif ($path =~ m{^authors/id/(.*)} and !$ent) {
         $log->debug(" mirror autofetch $path");
         my $author_path= $1;
         my $blob= $self->add_upstream_author_file($author_path, undef_if_404 => 1);
         $ent= [ $blob, 0100644 ] if $blob;
      }
   }
   return $ent;
}


sub fetch_upstream_file($self, $path, %options) {
   croak "No upstream URL for this tree"
      unless defined $self->upstream_url;
   my $url= $self->upstream_url . $path;
   my $tx= $self->parent->useragent->get($url);
   $log->debugf(" GET %s -> %s %s", $url, $tx->result->code, $tx->result->message);
   unless ($tx->result->is_success) {
      if ($self->upstream_backup_url && $path =~ m{^authors/id/}) {
         my $url2= $self->upstream_backup_url . $path;
         my $tx2= $self->parent->useragent->get($url2);
         $log->debugf(" GET %s -> %s %s", $url2, $tx2->result->code, $tx2->result->message);
         return \$tx2->result->body
            if $tx2->result->is_success;
      }
      return undef if $options{undef_if_404} && $tx->result->code == 404;
      croak "Failed to find file upstream: ".$tx->result->message;
   }
   return \$tx->result->body;
}


sub add_upstream_package_details($self, %options) {
   my $content_ref= $self->fetch_upstream_file('modules/02packages.details.txt.gz', %options)
      or return undef;
   # Unzip the file and store uncompressed, so that 'git diff' works nicely on it.
   my $txt;
   gunzip $content_ref => \$txt
      or croak "gunzip failed: $GunzipError";
   my $blob= Git::Raw::Blob->create($self->git_repo, $txt);
   $self->set_path('modules/02packages.details.txt', $blob);
   $self->{_blob_last_update}{$blob->id}= time;
   return $blob;
}


sub add_upstream_author_file($self, $author_path, %options) {
   my $path= "authors/id/$author_path";
   my $content_ref= $self->fetch_upstream_file($path, %options)
      or return undef;
   my $blob= Git::Raw::Blob->create($self->git_repo, $$content_ref);
   $self->set_path($path, $blob);
   return $blob;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::InGit::MirrorTree - Subclass of ArchiveTree which automatically mirrors files from upstream

=head1 DESCRIPTION

This is a subclass of L<CPAN::InGit::ArchiveTree> which behaves as a pure mirror of an
upstream CPAN or DarkPAN.  The attribute L</autofetch> allows it to import files from the public
CPAN on demand.

=head1 ATTRIBUTES

=head2 upstream_url

This is the base URL from which files will be fetched.

=head2 upstream_backup_url

This is a fallback URL for if the primary URL lacks a distribution file.  The backup url is
presumed to have the exact same distribution files as the primary URL, but a longer history of
them.  The package index of the backup URL is never used.

If the primary URL is C<< http://www.cpan.org >> then this will default to
C<< https://backpan.perl.org >>.

=head2 autofetch

If enabled, attempts to access author files which exist on the L</upstream_url> and not locally
will immediately go download the file and return it as if it had existed all along.  These
changes are not automatically committed.  Use C<has_changes> to see if anything needs committed.

=head2 package_details_max_age

Number of seconds to cache the package_details file before attempting to re-fetch it.
Defaults to one day (86400).  This only has an effect when C<autofetch> is enabled.

=head1 METHODS

=head2 fetch_upstream_file

  $content= $mirror->fetch_upstream_file($path, %options);
  
  # %options:
  #   undef_if_404 - boolean, return undef instead of croaking on a 404 error

=head2 add_upstream_package_details

  $blob= $mirror->add_upstream_package_details;

Fetches C<modules/02packages.details.txt.gz> from upstream, unzips it, adds it to the tree,
and returns the C<Git::Raw::BLOB>.

=head2 add_upstream_author_file

  $blob= $mirror->add_upstream_author_file($author_path, %options);

Fetch the file (relative to C<authors/id/>) from upstream and add it to this tree.
Also return the C<Git::Raw::BLOB>.

=head1 VERSION

version 0.003

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Michael Conrad, and IntelliTree Solutions.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package CPAN::Faker;
{
  $CPAN::Faker::VERSION = '0.010';
}
use 5.008;
use Moose;
# ABSTRACT: build a bogus CPAN instance for testing

use CPAN::Checksums ();
use Compress::Zlib ();
use Cwd ();
use Data::Section -setup;
use File::Find ();
use File::Next ();
use File::Path ();
use File::Spec ();
use IO::Compress::Gzip qw(gzip $GzipError);
use Module::Faker::Dist 0.015; # ->packages
use Sort::Versions qw(versioncmp);
use Text::Template;


has dest   => (is => 'ro', isa => 'Str', required => 1);
has source => (is => 'ro', isa => 'Str', required => 1);

has dist_class => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
  default  => sub { 'Module::Faker::Dist' },
);

has url => (
  is      => 'ro',
  isa     => 'Str',
  default => sub {
    my ($self) = @_;
    my $url = "file://" . File::Spec->rel2abs($self->dest);
    $url =~ s{(?<!/)$}{/};
    return $url;
  },
);

has dist_dest => (
  is   => 'ro',
  lazy => 1,
  init_arg => undef,
  default  => sub { File::Spec->catdir($_[0]->dest, qw(authors id)) },
);

BEGIN {
  # These attributes are used to keep track of the indexes we'll write when we
  # finish adding content to the CPAN::Faker. -- rjbs, 2008-05-07
  for (qw(pkg_index author_index author_dir)) {
    has "_$_" => (
      is  => 'ro',
      isa => 'HashRef',
      default  => sub { {} },
      init_arg => undef,
    );
  }
}

sub __dor { defined $_[0] ? $_[0] : $_[1] }


sub make_cpan {
  my ($self) = @_;

  for ($self->source) {
    Carp::croak "source directory does not exist"     unless -e;
    Carp::croak "source directory is not a directory" unless -d;
  }

  for ($self->dest) {
    if (-e) {
      Carp::croak "destination directory is not a directory" unless -d;

      opendir my $dir, $self->dest;
      my @files = grep { $_ ne '.' and $_ ne '..' } readdir $dir;
      Carp::croak "destination directory is not empty" if @files;
    } else {
      my $error;
      # actually *using* $error is annoying; will sort it out later..?
      # -- rjbs, 2011-04-18
      Carp::croak "couldn't create destination"
        unless File::Path::make_path($self->dest, { error => \$error });
    }
  }

  my $iter = File::Next::files($self->source);

  while (my $file = $iter->()) {
    my $dist = $self->dist_class->from_file($file);
    $self->add_dist($dist);
  }

  $self->_update_author_checksums;

  $self->write_package_index;
  $self->write_author_index;
  $self->write_modlist_index;
  $self->write_perms_index;
  $self->write_perms_gz_index;
}


sub add_dist {
  my ($self, $dist) = @_;

  my $archive = $dist->make_archive({
    dir           => $self->dist_dest,
    author_prefix => 1,
  });

  $self->_learn_author_of($dist);
  $self->_maybe_index($dist);

  my ($author_dir) =
    $dist->archive_filename({ author_prefix => 1 }) =~ m{\A(.+)/};

  $self->_author_dir->{ $author_dir } = 1;
}

sub _update_author_checksums {
  my ($self) = @_;

  my $dist_dest = File::Spec->catdir($self->dest, qw(authors id));

  for my $dir (keys %{ $self->_author_dir }) {
    $dir = File::Spec->catdir($dist_dest, $dir);
    CPAN::Checksums::updatedir($dir);
  }
}


sub add_author {
  my ($self, $pauseid, $info) = @_;
  $self->_author_index->{$pauseid} = $info->{mailbox};
}

sub _learn_author_of {
  my ($self, $dist) = @_;

  my ($author) = $dist->authors;
  my $pauseid = $dist->cpan_author;

  return unless $author and $pauseid;

  $self->add_author($pauseid => { mailbox => $author });
}


sub index_package {
  my ($self, $package_name, $info) = @_;

  unless ($info->{dist_filename}) {
    Carp::croak "invalid package entry: missing dist_filename";
  }

  $self->_pkg_index->{$package_name} = {
    version       => $info->{version},
    dist_filename => $info->{dist_filename},
    dist_version  => $info->{dist_version},
    dist_author   => $info->{dist_author},
  };
}

sub _index_pkg_obj {
  my ($self, $pkg, $dist) = @_;
  $self->index_package(
    $pkg->name => {
      version       => $pkg->version,
      dist_filename => $dist->archive_filename({ author_prefix => 1 }),
      dist_version  => $dist->version,
      dist_author   => $dist->cpan_author,
    },
  );
}

sub _maybe_index {
  my ($self, $dist) = @_;

  my $index = $self->_pkg_index;

  PACKAGE: for my $package ($dist->packages) {
    if (my $e = $index->{ $package->name }) {
      if (defined $package->version and not defined $e->{version}) {
        $self->_index_pkg_obj($package, $dist);
        next PACKAGE;
      } elsif (not defined $package->version and defined $e->{version}) {
        next PACKAGE;
      } else {
        my $pkg_cmp = versioncmp($package->version, $e->{version});

        if ($pkg_cmp == 1) {
          $self->_index_pkg_obj($package, $dist);
          next PACKAGE;
        } elsif ($pkg_cmp == 0) {
          if (versioncmp($dist->version, $e->{dist_version}) == 1) {
            $self->_index_pkg_obj($package, $dist);
            next PACKAGE;
          }
        }

        next PACKAGE;
      }
    } else {
      $self->_index_pkg_obj($package, $dist);
    }
  }
}


sub write_author_index {
  my ($self) = @_;

  my $index = $self->_author_index;

  my $index_dir = File::Spec->catdir($self->dest, 'authors');
  File::Path::mkpath($index_dir);

  my $index_filename = File::Spec->catfile(
    $index_dir,
    '01mailrc.txt.gz',
  );

  my $gz = Compress::Zlib::gzopen($index_filename, 'wb');

  for my $pauseid (sort keys %$index) {
    $gz->gzwrite(qq[alias $pauseid "$index->{$pauseid}"\n])
      or die "error writing to $index_filename"
  }

  $gz->gzclose and die "error closing $index_filename";
}

sub write_package_index {
  my ($self) = @_;

  my $index = $self->_pkg_index;

  my @lines;
  for my $name (sort keys %$index) {
    my $info = $index->{ $name };

    push @lines, sprintf "%-34s %5s  %s\n",
      $name,
      __dor($info->{version}, 'undef'),
      $info->{dist_filename};
  }

  my $front = $self->_02pkg_front_matter({ lines => scalar @lines });

  my $index_dir = File::Spec->catdir($self->dest, 'modules');
  File::Path::mkpath($index_dir);

  my $index_filename = File::Spec->catfile(
    $index_dir,
    '02packages.details.txt.gz',
  );

  my $gz = Compress::Zlib::gzopen($index_filename, 'wb');
  $gz->gzwrite("$front\n");
  $gz->gzwrite($_) || die "error writing to $index_filename" for @lines;
  $gz->gzclose and die "error closing $index_filename";
}

sub write_modlist_index {
  my ($self) = @_;

  my $index_dir = File::Spec->catdir($self->dest, 'modules');

  my $index_filename = File::Spec->catfile(
    $index_dir,
    '03modlist.data.gz',
  );

  my $gz = Compress::Zlib::gzopen($index_filename, 'wb');
  $gz->gzwrite(${ $self->section_data('modlist') });
  $gz->gzclose and die "error closing $index_filename";
}

sub _perms_index_filename {
  my ($self) = @_;
  my $index_dir = File::Spec->catdir($self->dest, 'modules');

  return File::Spec->catfile(
    $index_dir,
    '06perms.txt',
  );
}

sub write_perms_index {
  my ($self) = @_;

  my $index_filename = $self->_perms_index_filename;

  my $template = $self->section_data('packages');

  my $index = $self->_pkg_index;
  my $lines = keys %$index;

  my $text = Text::Template->fill_this_in(
    $$template,
    DELIMITERS => [ '{{', '}}' ],
    HASH       => {
      lines => \$lines,
      self  => \$self,
    },
  );

  open my $fh, '>', $index_filename
    or die "can't open $index_filename for writing: $!";

  print {$fh} $text, "\n";

  for my $pkg (sort keys %$index) {
    my $author = $index->{$pkg}{dist_author};

    printf {$fh} "%s,%s,%s\n", $pkg, $author, 'f';
  }

  close $fh or die "error closing $index_filename after writing: $!";
}

sub write_perms_gz_index {
  my ($self) = @_;

  my $index_filename = $self->_perms_index_filename;
  my $index_gz_fname = "$index_filename.gz";
  gzip($index_filename, $index_gz_fname)
    or confess "gzip failed: $GzipError"
}

sub _02pkg_front_matter {
  my ($self, $arg) = @_;

  my $template = $self->section_data('packages');

  my $text = Text::Template->fill_this_in(
    $$template,
    DELIMITERS => [ '{{', '}}' ],
    HASH       => {
      self => \$self,
      (map {; $_ => \($arg->{$_}) } keys %$arg),
    },
  );

  return $text;
}

no Moose;
1;

=pod

=encoding UTF-8

=head1 NAME

CPAN::Faker - build a bogus CPAN instance for testing

=head1 VERSION

version 0.010

=head1 SYNOPSIS

  use CPAN::Faker;

  my $cpan = CPAN::Faker->new({
    source => './eg',
    dest   => './will-contain-fakepan',
  });

  $cpan->make_cpan;

=head1 DESCRIPTION

First things first: this is a pretty special-needs module.  It's for people who
are writing tools that will operate against a copy of the CPAN (or something
just like it), and who need data to test those tools against.

Because the real CPAN is constantly changing, and a mirror of the CPAN is a
pretty big chunk of data to deal with, CPAN::Faker lets you build a fake
CPAN-like directory tree out of simple descriptions of the distributions that
should be in your fake CPAN.

=head1 METHODS

=head2 new

  my $faker = CPAN::Faker->new(\%arg);

This create the new CPAN::Faker.  All arguments may be accessed later by
methods of the same name.  Valid arguments are:

  source - the directory in which to find source files
  dest   - the directory in which to construct the CPAN instance; required
  url    - the base URL for the CPAN; a file:// URL is generated by default

  dist_class - the class used to fake dists; default: Module::Faker::Dist

=head2 make_cpan

  $faker->make_cpan;

This method makes the CPAN::Faker do its job.  It iterates through all the
files in the source directory and builds a distribution object.  Distribution
archives are written out into the author's directory, distribution contents are
(potentially) added to the index, CHECKSUMS files are created, and the indices
are then written out.

=head2 add_author

  $faker->add_author($pause_id => \%info);

Low-level method for populating C<01mailrc>.  Only likely to be useful if you
are not calling C<make_cpan>.  If the author is already known, the info on file
is replaced.

The C<%info> hash is expected to contain the following data:

  mailbox - a string like: Ricardo Signes <rjbs@cpan.org>

=head2 index_package

  $faker->index_package($package_name => \%info);

This is a low-level method for populating the structure that will used to
produce the C<02packages> index.

This method is only likely to be useful if you are not calling C<make_cpan>.

C<%entry> is expected to contain the following entries:

  version       - the version of the package (defaults to undef)
  dist_version  - the version of the dist (defaults to undef)
  dist_filename - the file containing the package, like R/RJ/RJBS/...tar.gz
  dist_author   - the PAUSE id of the uploader of the dist

=head2 write_author_index

=head2 write_package_index

=head2 write_modlist_index

=head2 write_perms_index

=head2 write_perms_gz_index

All these are automatically called by C<make_cpan>; you probably do not need to
call them yourself.

Write C<01mailrc.txt.gz>, C<02packages.details.txt.gz>, C<03modlist.data.gz>,
C<06perms.txt>, and C<06perms.txt.gz> respectively.

=head1 THE CPAN INTERFACE

A CPAN instance is just a set of files in known locations.  At present,
CPAN::Faker will create the following files:

  ./authors/01mailrc.txt.gz            - the list of authors (PAUSE ids)
  ./modules/02packages.details.txt.gz  - the master index of current modules
  ./modules/03modlist.txt.gz           - the "registered" list; has no data
  ./authors/id/X/Y/XYZZY/Dist-1.tar.gz - each distribution in the archive
  ./authors/id/X/Y/XYZZY/CHECKSUMS     - a CPAN checksums file for the dir

Note that while the 03modlist file is created, for the sake of the CPAN client, 
the file contains no data about registered modules.  This may be addressed in
future versions.

Other files that are not currently created, but may be in the future are:

  ./indices/find-ls.gz
  ./indices/ls-lR.gz
  ./modules/by-category/...
  ./modules/by-module/...

If there are other files that you'd like to see created (or if you want to ask
to get the creation of one of the above implemented soon), please contact the
current maintainer (see below).

=head2 add_dist

  $faker->add_dist($dist);

This method expects a L<Module::Faker::Dist> object, for which it will
construct an archive, index the author and (maybe) the contents.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__[packages]__
File:         02packages.details.txt
URL:          {{ $self->url }}modules/02packages.details.txt.gz
Description:  Package names found in directory $CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   CPAN::Faker version {{ $CPAN::Faker::VERSION }}
Line-Count:   {{ $lines }}
Last-Updated: {{ scalar gmtime }} GMT
__[perms]__
File:        06perms.txt
Description: CSV file of upload permission to the CPAN per namespace
    best-permission is one of "m" for "modulelist", "f" for
    "first-come", "c" for "co-maint"
Columns:     package,userid,best-permission
Line-Count:  {{ $lines }}
Written-By:  Id
Date:        {{ scalar gmtime }} GMT
__[modlist]__
File:        03modlist.data
Description: CPAN::Faker does not provide modlist data.
Modcount:    0
Written-By:  CPAN::Faker version {{ $CPAN::Faker::VERSION }}
Date:        {{ scalar localtime }}

package CPAN::Modulelist;
# Usage: print Data::Dumper->new([CPAN::Modulelist->data])->Dump or similar
# cannot 'use strict', because we normally run under Safe
# use strict;
sub data {
my $result = {};
my $primary = "modid";
for (@$CPAN::Modulelist::data){
my %hash;
@hash{@$CPAN::Modulelist::cols} = @$_;
$result->{$hash{$primary}} = \%hash;
}
$result;
}
$CPAN::Modulelist::cols = [
'modid',
'statd',
'stats',
'statl',
'stati',
'statp',
'description',
'userid',
'chapterid'
];
$CPAN::Modulelist::data = [];

package CPAN::Metadata::RDF;
use strict;
use warnings;
use DateTime;
use DBI;
use Digest::MD5;
use File::Find::Rule;
use File::stat;
use File::Type;
use Path::Class qw(file dir);
use RDF::Simple::Serialiser;
use vars qw($VERSION);
$VERSION = "1.11";

my $CPANNS = "http://downlode.org/rdf/cpan/0.1";

sub new {
  my $class = shift;
  my $self = {};

  bless $self, $class;
}

sub directory {
  my($self, $dir) = @_;
  if (defined $dir) {
    $self->{DIR} = $dir;

    my $db = file($dir, "meta.db");
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db","","", { AutoCommit => 0});
    $self->{DBH} = $dbh;

  } else {
    return $self->{DIR};
  }
}

sub backpan {
  my($self, $dir) = @_;
  if (defined $dir) {
    $self->{BACKPAN} = $dir;
  } else {
    return $self->{BACKPAN};
  }
}

sub cpan {
  my($self, $dir) = @_;
  if (defined $dir) {
    $self->{CPAN} = $dir;
  } else {
    return $self->{CPAN};
  }
}

sub dbh {
  my($self) = @_;
  return $self->{DBH};
}

sub create_db {
  my $self = shift;
  my $dbh = $self->dbh;
  $dbh->do("CREATE TABLE meta (
 id INTEGER, subject INTEGER, predicate INTEGER, object INTEGER,
 primary key (id),
 unique (subject, predicate, object)
)");

  $dbh->do("CREATE TABLE dictionary (
 id INTEGER, word,
 primary key (id)
)");

  $dbh->do("CREATE INDEX subject_idx on meta (subject)");
  $dbh->do("CREATE INDEX predicate_idx on meta (predicate)");
  $dbh->do("CREATE INDEX object_idx on meta (object)");
  $dbh->do("CREATE INDEX word_idx on dictionary (word)");
  $dbh->commit;
}

sub generate {
  my($self) = @_;
  my $dbh = $self->dbh;

  my %mirrored;
  my $cpan = $self->cpan;
  my $dir = dir($cpan, "authors", "id");
  foreach my $path (sort File::Find::Rule->new->file->in($dir)) {
    my $suffix = $path;
    $suffix =~ s/^$cpan//;
    $mirrored{$suffix}++;
  }

  my $backpan = $self->backpan;
  $dir = dir($backpan, "authors", "id");

  foreach my $path (sort File::Find::Rule->new->file->in($dir)) {
    my($cpanid, $file);
    if (($cpanid, $file) = $path =~ m{
/BACKPAN/
authors/
id/
(?:.)/    # eg L
(?:..)/   # eg LB
([^/]+)/  # cpanid: LBROCARD
(?:.+/)?  # optionally author subdirectory
([^/]+?)$ # file
}x) {

      next unless ($file =~ s/\.(tar.gz|tgz|zip)$//);

      open(FILE, $path) or die "Can't open '$path': $!";
      binmode(FILE);
      my $distmd5 = Digest::MD5->new->addfile(*FILE)->hexdigest;
      close(FILE);

      my $suffix = $path;
      $suffix =~ s/^$backpan//;

      my $distversion = $file;
      $distversion =~ s{^.+/}{};

      my $t = File::Type->new;
      my $format = $t->mime_type($path);

      my ($dist, $version) = $self->extract_name_version($distversion);

      my $stat = stat($path);
      my $datetime = DateTime->from_epoch(epoch =>$stat->mtime)->datetime;
      my $filesize = $stat->size;

      my $mirrored = "0";
      $mirrored = "1" if exists $mirrored{$suffix};

      my $beta = $self->is_beta($path) ? "developer" : "public";

      my $identifier = "http://search.cpan.org/dist/$distversion/";

#      print "$cpanid: $file / $distversion / $dist / $version / $suffix / $datetime / $format / $filesize / $identifier\n";
#      print "$cpanid: $file\n";

# More meta:
# http://downlode.org/rdf/cpan/0.1/
# Title : main module name
# Creator: author name / email address
# Subject: the thing in the =name
# Description: synopsis
# Contributor: co-maintainers
# Source: ?
# Language: can we guess language?
# Relation:
# Coverage:
# Rights: license from meta.yml?

      $self->insert($identifier, "$CPANNS/suffix", $suffix);
      $self->insert($identifier, "$CPANNS/dist_version", $distversion);
      $self->insert($identifier, "$CPANNS/dist", $dist);
      $self->insert($identifier, "$CPANNS/release_status", $beta);
      $self->insert($identifier, "$CPANNS/version", $version);
      $self->insert($identifier, "$CPANNS/pause_id", $cpanid);
      $self->insert($identifier, "$CPANNS/dist_md5", $distmd5);
      $self->insert($identifier, "$CPANNS/mimetype", $format);
      $self->insert($identifier, "$CPANNS/file_size", $filesize);
      $self->insert($identifier, "$CPANNS/mirrored", $mirrored);
      $self->insert($identifier, "http://purl.org/dc/elements/1.1/date", $datetime);
      $self->insert($identifier, "http://purl.org/dc/elements/1.1/type", "http://purl.org/dc/dcmitype/Software");
      $self->insert($identifier, "http://purl.org/dc/elements/1.1/publisher", "http://www.cpan.org/");
      $self->insert($identifier, "http://purl.org/dc/elements/1.1/format", $format);
      $self->insert($identifier, "http://purl.org/dc/elements/1.1/identifier", $identifier);
      $dbh->commit;
    } else {
      die "Failed to parse path $path\n";
    }
  }
  $dbh->disconnect;
}

sub insert {
  my($self, $subject, $predicate, $object) = @_;
  my $dbh = $self->dbh;

  my $subject_id = $self->dictionary($subject);
  my $predicate_id = $self->dictionary($predicate);
  my $object_id = $self->dictionary($object);

  my $sth = $dbh->prepare("REPLACE INTO meta (subject, predicate, object) VALUES (?, ?, ?)");
  $sth->execute($subject_id, $predicate_id, $object_id);
}

sub dictionary {
  my($self, $word) = @_;
  my $dbh = $self->dbh;
  my $word_id;

  my $sth = $dbh->prepare("SELECT id from dictionary where word = ?");
  $sth->execute($word);
  $sth->bind_columns(\$word_id);
  $sth->fetch;

  return $word_id if defined $word_id;

  $sth = $dbh->prepare("INSERT into dictionary (word) VALUES (?)");
  $sth->execute($word);

  return $dbh->func('last_insert_rowid');
}

sub output {
  my $self = shift;
  my $dbh = $self->dbh;
  my $ser = RDF::Simple::Serialiser->new;
  $ser->addns(cpan => 'http://www.cpan.org/');
  $ser->addns(misc => 'urn:empty');
  $ser->addns(dc => 'http://purl.org/dc/elements/1.1/');

  my(@triples, $subject, $predicate, $object);

  my $sth = $dbh->prepare("SELECT d1.word, d2.word, d3.word FROM meta, dictionary AS d1, dictionary AS d2, dictionary AS d3 WHERE subject=d1.id AND predicate=d2.id AND object=d3.id");
  $sth->execute();
  $sth->bind_columns(\$subject, \$predicate, \$object);

#my $count;
  while ($sth->fetch) {
    push @triples, [$subject, $predicate, $object];
#    last if $count++ > 500;
  }

  my $rdf = $ser->serialise(@triples);
  $rdf =~ s{$CPANNS/}{cpan:}g;
  $dbh->disconnect;
  return $rdf;
}

# This isn't really working well
sub output_redland {
  my $self = shift;
  my $dbh = $self->dbh;

#  use RDF::Redland;
  my $storage = RDF::Redland::Storage->new(
    "hashes",
    "test",
    "new='yes',hash-type='memory',dir='.'"
) || die;

  my $model = RDF::Redland::Model->new($storage, "") || die;

  my($subject, $predicate, $object);

  my $sth = $dbh->prepare("SELECT d1.word, d2.word, d3.word FROM meta, dictionary AS d1, dictionary AS d2, dictionary AS d3 WHERE subject=d1.id AND predicate=d2.id AND object=d3.id");
  $sth->execute();
  $sth->bind_columns(\$subject, \$predicate, \$object);

#my $count;
  while ($sth->fetch) {
#last;
#    push @triples, [$subject, $predicate, $object];
    my $statement = RDF::Redland::Statement->new(
      RDF::Redland::Node->new_from_uri($subject),
      RDF::Redland::Node->new_from_uri($predicate),
      RDF::Redland::Node->new($object));
    $model->add_statement($statement);
#    last if $count++ > 500;
  }

  # Use any rdf/xml parser that is available
  my $serializer=new RDF::Redland::Serializer("rdfxml");
  die "Failed to find serializer\n" if !$serializer;
  my $uri = new RDF::Redland::URI("file:foo.txt");
  $serializer->serialize_model_to_file("test-out.rdf", $uri, $model);

  $sth->finish;
  $dbh->disconnect;
}


# from TUCS, coded by gbarr
sub extract_name_version {
  my($self, $file) = @_;

  my ($dist, $version) = $file =~ /^
    ((?:[-+.]*(?:[A-Za-z0-9]+|(?<=\D)_|_(?=\D))*
      (?:
   [A-Za-z](?=[^A-Za-z]|$)
   |
   \d(?=-)
     )(?<![._-][vV])
    )+)(.*)
  $/xs or return ($file);

  $version = $1
    if !length $version and $dist =~ s/-(\d+\w)$//;

  $version = $1 . $version
    if $version =~ /^\d+$/ and $dist =~ s/-(\w+)$//;

     if ($version =~ /\d\.\d/) {
    $version =~ s/^[-_.]+//;
  }
  else {
    $version =~ s/^[-_]+//;
  }
  return ($dist, $version);
}

# from TUCS, coded by gbarr
sub is_beta {
  my($self, $distfile) = @_;
  my %info = ( beta => "0" );

  $distfile =~ s,//+,/,g;

  (my $path = $distfile) =~ s,^(((.*?/)?authors/)?id/)?./../,,;

  if ($path =~ s,^((([^/])[^/])[^/]*)/,,) {
    @info{qw(cpanid dir filename)} = ($1, "$3/$2/$1", $path);
  }
  else {
    die("Cannot determine author from '$distfile'");
    return;
  }

  ($info{distvname}) = $distfile =~ m,^.*/(.*)\.(?:tar\.gz|zip|tgz)$,i
    or die("Cannot determine distvname from '$distfile'"), return;

  @info{qw(dist version)} = $self->extract_name_version($info{distvname});

  if ($info{distvname} =~ /^perl-?\d+\.(\d+)(?:\D(\d+))?(-(?:TRIAL|RC)\d+)?$/) {
    $info{beta} = "1" if (($1 > 6 and $1 & 1) or ($2 and $2 >= 50)) or $3;
  }
  elsif (($info{version} || '') =~ /\d\D\d+_\d/) {
    $info{beta} = "1";
  }

  return $info{beta};
}


__END__

=head1 NAME

CPAN::Metadata::RDF - Generate metadata about CPAN in RDF

=head1 SYNOPSIS

  use strict;
  use CPAN::Metadata::RDF;

  # To generate metadata
  my $m = CPAN::Metadata::RDF->new();
  $m->backpan("/home/acme/backpan/BACKPAN/");
  $m->cpan("/home/acme/cpan/CPAN/");
  $m->directory(".");
  $m->create_db; # once
  $m->generate;

  # To output metadata
  my $m = CPAN::Metadata::RDF->new();
  $m->directory(".");
  print $m->output; # RDF

  # Methods to parse and query RDF soon...

=head1 DESCRIPTION

This module generates metadata about CPAN modules (and BACKPAN)
modules in RDF format.

It requires a local CPAN mirror (for example, mirrored using
"/usr/bin/rsync -av --delete ftp.nic.funet.fi::CPAN
/path/to/local/cpan/") as well as a local BACKPAN mirror (for example,
mirrored using "/usr/bin/rsync -av --delete pause.perl.org::backpan
/path/to/local/backpan/").

It currently uses an SQLite database as a temporary datastore. It
takes about two hours to generate the RDF file from scratch. I don't
expect many people to run this module. I run it occasionally, and you
should be able to fetch the latest version from:
http://www.cpan.org/authors/id/L/LB/LBROCARD/cpan.rdf.gz

=head1 AUTHOR

Leon Brocard <leon@astray.com>

=head1 LICENSE

This code is distributed under the same license as Perl.

